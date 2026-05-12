# Dataverse Schema Design Standards

---

## Three Deployment Paths — Pick By Context

| Path | Use when... | Trade-offs |
|---|---|---|
| **A. Maker portal Copilot (PRIMARY for corporate tenants)** | Default. Always works — Copilot runs in user's existing browser session. AI prepares terse structured prompts; user pastes into maker portal's "Start with Copilot"; Copilot creates the artifacts; user validates; AI gives next prompt with approval gate between each. | User must paste prompts manually. Some artifact types (alternate keys, complex views) may need fallback to manual maker portal steps. |
| **B. Dataverse MCP (staged build)** | User has tenant admin consent + preview MCP enabled. Personal dev tenants. | AI agent does the work conversationally. **Blocked by most corporate tenants** (incl. stlogs.com) because the MCP CLI app needs admin consent. |
| **C. PAC CLI solution import** | Distributing existing `.zip` artifacts. ALM scenarios. Fast deploy of the example to a clean env. | Re-importing same-env exports fails ("Must specify valid information for parsing"). Best for one-shot fresh deploys via `Personalize-AssetManagement.ps1` + `pac solution import`. |

For both, the schema spec lives in `examples/<app>/dataverse/schema.yaml` as the source of truth.

---

## Path A — Maker Portal Copilot (PRIMARY for corporate tenants)

**The AI agent prepares terse structured Copilot prompts; the user pastes them into maker portal's "Start with Copilot" feature.** Copilot creates the artifacts natively in the user's existing browser session — no API auth, no CLI auth, no MCP auth.

Why this is the primary path:
- Runs in the same browser session that already works for `make.powerapps.com` — no Conditional Access friction
- Publisher prefix is part of the prompt text (literal, e.g. `ws_`), so it's explicit and visible
- User stays in control — sees Copilot's output and can correct before moving on
- No XML hand-crafting, no zip building, no version bumping
- Works for tables + columns + lookups + choices + alternate keys all in one prompt per table

The 6-stage wizard:

0. **Collect inputs** — publisher unique name, display name, prefix, solution name. The AI uses these to customize the prompt text (substitutes `ws_` if user's prefix is different).
1. **Solution shell** (manual in maker portal — Copilot doesn't create solutions) — user creates empty solution + publisher → AI verifies via `pac solution list` → user approves
2. **Tables + schema** (Copilot prompts) — either:
   - **Flow A:** One combined prompt creates all 3 tables + lookups + choice + alt key
   - **Flow B:** Three sequential prompts (Asset Category → Asset → Asset Assignment) with approval gate between each
3. **Verify relationships + alternate key** (visual check in maker portal; relationships were created in Stage 2)
4. **Views** — one Copilot prompt covers all 5 public views (or fall back to manual)
5. **Canvas App** (inside the solution) — user creates empty app in maker portal, AI compiles via canvas-authoring MCP
6. **Flows** — placeholder (future work)
7. **Final** — `pac solution export` to `dist/<app>-<prefix>/<SolutionName>-complete.zip` (the user's personalized portable artifact)

**The prompt format is intentionally terse:**

```
Create Dataverse table with prefix ws_, Ownership=Organization, Auditing=On.

Schema: ws_assetcategory
Display: Asset Category
Primary: ws_categoryname
Columns:
ws_categoryname Text 80 Required
ws_icon Text 4
ws_description Memo 500
```

This format is easier for Copilot to parse than verbose paragraphs, and easier for the user to scan/edit before pasting.

**Full prompts for the asset-management example** live in `examples/asset-management/dataverse/copilot-prompts.md`.

---

## Path B/C — fallback paths

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
