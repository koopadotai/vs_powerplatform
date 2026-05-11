# Dataverse Schema Design Standards

---

## Two Deployment Paths — Pick By Context

| Path | Use when... | Trade-offs |
|---|---|---|
| **A. PAC CLI staged build (RECOMMENDED for corporate tenants)** | Default for any env. Always works under Conditional Access. Each stage = `pac solution import` of a pre-built stage zip with user approval gates between. | Requires the staged zips (`stage1-shell.zip` / `stage2-tables.zip` / `stage3-relationships.zip`) to be pre-built and shipped with the project. |
| **B. Dataverse MCP (staged build)** | User has tenant admin consent + preview MCP enabled. Personal dev tenants. | AI agent does the work conversationally. **Blocked by most corporate tenants** (incl. stlogs.com) because the MCP CLI app needs admin consent. |
| **C. One-shot `.zip` import (FAST, no wizard)** | Quick deploy when user trusts the example as-is. AI personalizes the complete `.zip` for their publisher/prefix, then one `pac solution import`. | No staged validation gates; user discovers issues only after full deploy. |

For both, the schema spec lives in `examples/<app>/dataverse/schema.yaml` as the source of truth.

---

## Path A — PAC CLI Dynamic Staged Build (default — works in corporate tenants)

**The AI agent builds each stage's solution `.zip` dynamically at runtime.** No pre-built stage zips ship in the repo. The source `examples/<app>/dataverse/AssetManagement.zip` is a publisher-agnostic template; each user's deployment generates fresh stage zips under `dist/<app>-<prefix>/staged/` using their own publisher name + prefix.

Why dynamic:
- Avoids inheriting a foreign publisher (the source's `WeeSiongDev` / `ws_` placeholder)
- Each user gets clean naming native to their org standards
- The repo stays portable across teammates with different naming conventions
- Hardcoded artifacts would break in any env that uses a different prefix

The 6-stage wizard (Stage 0 collects user inputs first):

0. **Collect inputs** — env URL, publisher unique name, publisher display name, prefix, option-value prefix, solution unique name. Stage 0 happens once before any imports.
1. **Solution shell** — AI generates `dist/<app>-<prefix>/staged/stage1-shell.zip` (empty solution with user's publisher) → `pac solution import` → user approves
2. **Base tables** (with simple columns + choice + alternate key) — AI generates `stage2-tables.zip` with `<prefix>_*` schema names, no relationships → import → user approves
3. **Relationships** — AI generates `stage3-relationships.zip` (full solution incl. lookups) → import → user approves
4. **Views/forms** — manual in maker portal, then `pac solution export` to capture into `dist/` → user approves
5. **Canvas App** (inside the solution) — user creates empty app in maker portal, AI compiles via canvas-authoring MCP → user approves
6. **Flows** — placeholder (future work) → final report
7. **Final** — `pac solution export` to `dist/<app>-<prefix>/<SolutionName>-complete.zip` (the user's personalized portable artifact)

**The dynamic build per stage** (steps 1–3): AI unpacks the source `AssetManagement.zip` template, applies prefix substitution (`ws_` → user's prefix) + publisher rewrites in `customizations.xml` + `solution.xml`, strips the components that don't belong in this stage, bumps the version, repacks. Each stage is a fresh build from the same source template — never modifies the template itself.

**Critical rules:**
- ✅ User approval gate between every stage (verify in maker portal first)
- ✅ Each stage uses ONE `pac solution import` call — no bundling
- ✅ Solution version bumps each stage (1.0.0 → 1.0.1 → 1.0.2)
- ❌ Don't skip gates even if import succeeds
- ❌ Don't bundle multiple stages into one zip

See `docs/pac-cli-staged-deployment.md` for the full runbook with verify commands per stage.

---

## Path B — Dataverse MCP, Staged Build (when MCP is available)

**Don't ask the AI to create a full enterprise schema in one prompt.** Dataverse MCP (preview) is unstable for long orchestration chains. Failure modes: context overflow, metadata propagation race conditions, hallucinated type enums, choice/lookup/relationship dependency timing.

**Required pattern — 6 staged steps:**

1. **Create solution only** (no tables yet)
2. **Create base tables** (table names + primary column only — NO lookups, choices, relationships)
3. **Wait + verify** all tables exist before continuing (call `list_tables`)
4. **Add simple columns** (text / date / number / memo) per table — one prompt per table
5. **Add choice sets** separately — one prompt per choice set
6. **Add lookup relationships LAST** — one prompt per relationship

**Per-prompt limits:**
- 1 table per prompt
- 5–10 columns max per prompt
- Relationships in their own prompt
- Choice sets in their own prompt

**ALWAYS include in every MCP-mediated prompt:**

```
Inside solution: <SolutionName>
Use publisher prefix: <prefix>
```

Without `Inside solution:`, Dataverse MCP sometimes creates the table in the **Default Solution** (especially in preview mode). Without the prefix, the AI may generate a random one.

**After EACH MCP step, the agent must:**
1. Verify success (`list_tables` / `describe_table`)
2. Wait for metadata propagation (~5–10 sec)
3. Re-read the schema state
4. Continue only if successful

---

## Path B — Solution `.zip` + `pac solution import`

Dataverse schema is deployed as a **solution package (`.zip`)** imported via `pac solution import`. This is the only reliable path that works across:
- Corporate tenants with Conditional Access policies (which often block device-code auth + third-party MCP apps)
- Local dev (uses PAC CLI's existing browser auth)
- CI/CD (uses service principal auth)

**Never hand-craft `customizations.xml`** — the format has dozens of nested required elements (DisplayMask, IntroducedVersion in 4-part form, EntityRelationshipRoles with NavigationPropertyName + RelationshipRoleType, optionset options with `ExternalValue=""` + `IsHidden="0"`, EntityKeys with `<EntityKeyAttributes><AttributeName>` structure, etc.) that aren't documented end-to-end anywhere reachable.

**The recipe to build a new solution package:**

1. Have user create empty solution + publisher in maker portal (`make.powerapps.com`)
2. Hand-craft a minimal `customizations.xml` with text/datetime/memo/currency columns only (these simple types work) — pack and import for the table shells
3. Add lookups, picklists, alternate keys via maker portal (5 min UI work — each takes 30 seconds)
4. Export the completed solution: `pac solution export --name <X> --path <X>.zip --managed false`
5. Commit the `.zip` as the portable artifact under `examples/<solution>/dataverse/`

The `.zip` is the source of truth for redeployment to any environment.

---

## Hand-craft format gotchas (only for the table-shell smoke test)

If you must write `customizations.xml` by hand for the minimal smoke-test step:

- `RequiredLevel` is lowercase: `required`, `none`, `recommended` (NOT `SystemRequired`/`None`)
- Primary name attribute needs `<DisplayMask>PrimaryName</DisplayMask>` — without it, Dataverse rejects the entity if multiple `nvarchar`+required attributes exist
- DateTime fields: omit `<Format>` entirely; use only `<DateTimeBehavior>DateOnly</DateTimeBehavior>` or `UserLocal`. `Format=dateonly` is invalid.
- `IntroducedVersion` should be `1.0.0.0` (4 parts) not `1.0`
- Lookup attribute physical name is CamelCase (`ws_Category`), logical name is lowercase (`ws_category`); relationship name follows pattern `<referencingEntity>_<lookupName>_<referencedEntity>`
- Picklist optionset name pattern: `<entity>_<attribute>` (e.g. `ws_asset_ws_status`)
- EntityRelationship requires `<EntityRelationshipRoles>` with two `<EntityRelationshipRole>` children — type 1 (referenced side) has nav-pane settings, type 0 (referencing side) just has NavigationPropertyName
- `<CascadeArchive>` is required (in addition to other cascade properties)
- Solution.xml `<RootComponents>` lists only entities (type=1) — relationships are not separate root components

---

## Table Design Principles

1. **One concept per table** — A table represents a single business entity (Asset, Customer, Order)
2. **Normalize where it makes sense** — Don't denormalize for performance until profiling proves the need
3. **Use lookups, not text references** — Foreign keys via lookup columns, not free text
4. **Audit columns are free** — Created On, Modified On, Owner are automatic; use them
5. **Required at schema, validated at app** — Make critical fields required at the table level

---

## Required Columns Per Table

Every custom table should have at minimum:

| Column | Schema Name | Type | Required | Notes |
|---|---|---|---|---|
| Primary | `<prefix>_name` | Text | Yes | The "label" you'd show in a dropdown |
| Status | `<prefix>_status` | Choice | Yes | Active / Inactive / Archived |
| Description | `<prefix>_description` | Multi-line text | No | Free-form notes |

Plus the system columns: CreatedOn, ModifiedOn, OwnerId, OwningBusinessUnit.

---

## Choice Columns vs Text

| Use Choice when... | Use Text when... |
|---|---|
| Values are bounded and known up-front | Values are user-generated |
| You'll filter/group by the value | Field is purely descriptive |
| Reusable across tables | Specific to one table only |

**Global option sets** for choices used in 2+ tables. **Local option sets** for table-specific.

---

## Lookups & Relationships

### 1:N (Parent → Children)

Example: Asset Category → Assets

- Lookup column on the child: `ws_assetcategoryid` on `ws_asset`
- Relationship name: `ws_assetcategory_ws_asset`
- Cascade behavior: typically **Restrict** (don't auto-delete children)

### N:N (Many-to-Many)

Use sparingly — Dataverse N:N relationships have limited extensibility. If you need attributes on the relationship itself, create an intersect table.

---

## Naming

| Asset | Convention | Example |
|---|---|---|
| Table schema | `<prefix>_<lowercase>` | `ws_asset` |
| Table display | Singular Title Case | `Asset` |
| Column schema | `<prefix>_<lowercase>` | `ws_serialnumber` |
| Column display | Title Case With Spaces | `Serial Number` |
| Lookup column | `<prefix>_<targettable>id` | `ws_categoryid` |
| Choice column | `<prefix>_<conceptname>` | `ws_status` |

See `memory/powerapps-naming.md` for the full reference.

---

## Security Roles

For each table, define at minimum:

| Role | Read | Create | Write | Delete | Append | Append To |
|---|---|---|---|---|---|---|
| App User | User | User | User | None | None | None |
| App Manager | BU | BU | BU | BU | BU | BU |
| App Admin | Org | Org | Org | Org | Org | Org |

Apply principle of least privilege.

---

## Auditing

Enable auditing on tables that:
- Hold financial or contractual data
- Are subject to compliance review (GDPR, SOX, HIPAA)
- Have multiple write paths (app + flows + API)

Disable auditing on:
- High-volume operational data with no compliance need (saves storage)

---

## Indexing & Performance

- Add an alternate key on any column used as a natural key (e.g. employee number, serial number)
- For tables expected to exceed 100k rows, review default indexes
- Use **virtual tables** for data that lives in an external system

---

## Solution Strategy

- One solution per business domain (e.g. `AssetManagement`, `LicenseTracker`)
- Add the table, all its columns, all its choice columns, all its relationships, all its security roles, and any related flows to the solution
- Never modify default Dataverse tables (Account, Contact) unless absolutely required — extend them, don't override

---

## Schema Generation Workflow

When the user asks "design a schema for X":

1. **Identify the entities** — list each as a table
2. **Identify relationships** — 1:N, N:N
3. **Identify lookups, choice sets, key fields**
4. **Generate the table-create script** in `templates/powerapps/dataverse/`
5. **Generate a sample seed-data script** for testing
6. **Document** the schema in `examples/<app>/docs/schema.md`

Use `pac data` and `pac solution` to operate on Dataverse from the CLI.
