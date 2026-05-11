# PAC CLI — Dynamic Staged Deployment Runbook

A step-by-step checklist for deploying a Dataverse + Canvas solution using **PAC CLI exclusively, with stage-zips built dynamically at deploy time** based on the user's env + publisher inputs. This is the **primary path** for corporate tenants where Dataverse MCP is blocked.

> **Why "dynamic" matters:** Pre-built stage zips would bake in a hardcoded publisher + prefix (e.g. `WeeSiongDev` / `ws_`). Every teammate would then either inherit that foreign publisher or need a separate personalization step. Building each stage's zip at runtime — from the publisher-agnostic source `AssetManagement.zip` + the user's chosen prefix — sidesteps that entirely.

For the alternate path (Dataverse MCP staged build, when MCP IS available), see [`dataverse-mcp-staged-deployment.md`](dataverse-mcp-staged-deployment.md).

---

## Prerequisites checklist

- [ ] PAC CLI installed and authenticated: `pac org who` succeeds
- [ ] User has **System Customizer** or **System Administrator** role in the target env
- [ ] Source template exists: `examples/<app>/dataverse/AssetManagement.zip` (publisher-agnostic, prefix `ws_`)
- [ ] No conflicting solution in target env: `pac solution list | Select-String <SolutionName>`

---

## Stage 0 — Collect personalization inputs (one-time)

Before any stage runs, the AI asks (if values aren't already in session memory):

| Input | Validation | Example |
|---|---|---|
| Publisher unique name | alphanumeric, starts with letter, 2–64 chars | `ContosoCorp` |
| Publisher display name | any string with spaces allowed | `Contoso Corporation` |
| Prefix | 2–8 lowercase letters, starts with letter | `ctso` |
| Option-value prefix | 5-digit number 10000–99999 | `10000` |
| Solution unique name | alphanumeric, no spaces | `AssetManagement` |

**Refuse** `ws` / `WeeSiongDev` as inputs — those are the source template's placeholder values; using them would leave the foreign publisher unchanged.

**Working directory** for this deployment becomes: `dist/<app>-<prefix>/`

---

## The core rules

### Rule 1 — Dynamic build per stage
Each stage builds its `.zip` fresh from the source template by:
1. Unpacking `examples/<app>/dataverse/AssetManagement.zip` to a working folder
2. Applying prefix substitution `ws_` → `<user-prefix>_` in `customizations.xml`
3. Applying publisher rewrites in `solution.xml`
4. Stripping components that don't belong in this stage
5. Bumping `<Version>` per stage (1.0.0 → 1.0.1 → 1.0.2)
6. Repacking via PowerShell zip (preserving `[Content_Types].xml`)

### Rule 2 — Gate after every stage
After every `pac solution import`, the AI must:
1. Verify success via PAC CLI (`pac solution list`, `pac org list-tables --filter <prefix>_`)
2. Tell the user what's now in their env
3. Direct user to validate in maker portal
4. **STOP and wait for explicit "approved"** before proceeding

### Rule 3 — Don't combine stages
Each stage is a separate import. Combining stages into one zip defeats the wizard pattern's validation purpose.

### Rule 4 — Source template is read-only
**Never** overwrite `examples/<app>/dataverse/AssetManagement.zip`. That's the template every future user's dynamic build starts from. The user's snapshot goes to `dist/<app>-<prefix>/<SolutionName>-complete.zip`.

---

## The 6 stages

### Stage 1 — Solution shell

**AI builds `dist/<app>-<prefix>/staged/stage1-shell.zip`:**

1. Unpack source `AssetManagement.zip` to `dist/<app>-<prefix>/build/stage1/`
2. In `customizations.xml`: replace `<Entities>...</Entities>` block with empty `<Entities />`; replace `<EntityRelationships>...</EntityRelationships>` block with empty `<EntityRelationships />`
3. In `solution.xml`:
   - `<UniqueName>` → user's solution unique name
   - `<Publisher><UniqueName>` → user's publisher unique name
   - `<Publisher><LocalizedName>` → user's publisher display name
   - `<CustomizationPrefix>` → user's prefix
   - `<CustomizationOptionValuePrefix>` → user's option-value prefix
   - `<Version>` → `1.0.0.0`
   - `<RootComponents>` → empty
4. Repack as `dist/<app>-<prefix>/staged/stage1-shell.zip`

**Import:**
```powershell
pac solution import `
  --path "dist\<app>-<prefix>\staged\stage1-shell.zip" `
  --publish-changes
```

**Verify:**
```powershell
pac solution list | Select-String <SolutionUniqueName>
```

**User validates in maker portal:** Solutions → `<Display Name>` appears with publisher `<Publisher Display>`. Solution is empty.

**Gate → wait for "approved".**

---

### Stage 2 — Base tables (with simple columns, choice set, alternate key)

**AI builds `dist/<app>-<prefix>/staged/stage2-tables.zip`:**

1. Unpack source `AssetManagement.zip` to `dist/<app>-<prefix>/build/stage2/`
2. In `customizations.xml`:
   - Replace every `ws_` → `<prefix>_` (preserves all entity schemas, attribute names, choice optionset names, alternate key names)
   - Strip `<EntityRelationships>...</EntityRelationships>` content (empty out for this stage)
3. In `solution.xml`:
   - Apply prefix + publisher rewrites (same fields as Stage 1)
   - `<Version>` → `1.0.1.0`
   - Strip relationship `<RootComponent>` entries; keep only entity root components
4. Repack as `dist/<app>-<prefix>/staged/stage2-tables.zip`

**Import:**
```powershell
pac solution import `
  --path "dist\<app>-<prefix>\staged\stage2-tables.zip" `
  --publish-changes
```

**Verify:**
```powershell
pac org list-tables --filter <prefix>_           # expect 3 tables
pac solution list | Select-String <SolutionName>  # expect version 1.0.1
```

**User validates in maker portal:**
- All 3 tables present under `<SolutionName>` → Tables
- `<prefix>_asset` → Columns: Asset Name, Serial Number, Status (Choice), Purchase Date, Purchase Cost, Warranty End, Notes
- `<prefix>_asset` → Keys: "Serial Number (Unique)" alternate key visible

**Gate → wait for "approved".**

---

### Stage 3 — Relationships

**AI builds `dist/<app>-<prefix>/staged/stage3-relationships.zip`:**

1. Unpack source `AssetManagement.zip` to `dist/<app>-<prefix>/build/stage3/`
2. In `customizations.xml`: apply `ws_` → `<prefix>_` substitution (everywhere — entities AND relationships)
3. In `solution.xml`: apply prefix + publisher rewrites, `<Version>` → `1.0.2.0`
4. Repack

**Import:**
```powershell
pac solution import `
  --path "dist\<app>-<prefix>\staged\stage3-relationships.zip" `
  --publish-changes
```

**Verify:**
```powershell
pac solution list | Select-String <SolutionName>   # expect version 1.0.2
```

**User validates in maker portal:**
- `<prefix>_asset` → Relationships: shows 1:N (Asset Category → Asset) + N:1 (Asset → User)
- `<prefix>_assetassignment` → Relationships: shows 1:N (Asset → Assignment) + N:1 (Assignment → User)
- `Category` column on Asset is a Lookup type (not Text)

**Gate → wait for "approved".**

---

### Stage 4 — Views/forms (manual in maker portal, then export to capture)

PAC CLI has no "create view" command. This stage is **manual but supervised**:

**The AI tells the user:**
> "In maker portal, add the 5 public views from `schema.yaml` lines 112-148 (substituting your prefix for `ws_`):
>
> On `<prefix>_asset`:
>   1. **Available Assets** — filter `<prefix>_status eq 100000000`
>   2. **My Assigned Assets** — filter `<prefix>_assignedto eq {currentUser} and <prefix>_status eq 100000001`
>   3. **Out of Warranty** — filter `<prefix>_warrantyend lt {today}`
>   4. **Recently Assigned** — filter `<prefix>_assigneddate gt {today-30d}`
>
> On `<prefix>_assetassignment`:
>   5. **Active Assignments** — filter `<prefix>_assignedto_dt eq null`"

**After user adds them, capture into a personalized snapshot:**
```powershell
pac solution export `
  --name <SolutionName> `
  --path "dist\<app>-<prefix>\<SolutionName>-with-views.zip" `
  --managed false --overwrite
```

> The export goes into `dist/`, NOT into `examples/`. The source template stays publisher-agnostic.

**User validates:** all 5 views visible across the two tables.

**Gate → wait for "approved".**

---

### Stage 5 — Canvas App (inside the same solution)

**Critical:** The Canvas App must live INSIDE the solution.

**The AI tells the user:**
> "In maker portal:
>  1. Solutions → `<SolutionDisplayName>` (NOT top-level Apps)
>  2. **+ New** → **App** → **Canvas app** → Phone form factor → name 'Asset Management'
>  3. Click **Create** — this places the app inside the solution
>  4. Studio opens: **Settings** (gear) → **Updates** → toggle **Coauthoring** ON
>  5. Copy the URL (must contain `appid=...`) and paste it here"

**After URL provided, AI dynamically builds the canvas source:**
1. Copy `examples/<app>/canvas/` to `dist/<app>-<prefix>/canvas/`
2. Apply `ws_` → `<prefix>_` substitution across all .pa.yaml files
3. Configure canvas-authoring MCP for the Studio URL (via `canvas-apps:configure-canvas-mcp`)
4. Call `mcp__canvas-authoring__compile_canvas` with `sources: dist/<app>-<prefix>/canvas/`

**User validates:**
- App opens in Studio with all 5 screens
- Add data sources: Data → + Add data → `<prefix>_asset`, `<prefix>_assetcategory`
- App functions (KPI counts populate, search works)

**Gate → wait for "approved".**

---

### Stage 6 — Flows (placeholder for future work)

> When flows are added, this stage will:
> 1. Render flow definitions from `examples/<app>/flows/*.json` templates with substituted connection refs + prefix
> 2. Build `dist/<app>-<prefix>/staged/stage6-flows.zip` containing the flows
> 3. `pac solution import` the stage6 zip
>
> For now, the AI marks Stage 6 as "not yet implemented" and proceeds to the final report.

**Gate → wait for "approved" → final report.**

---

### Final — Capture the user's complete personalized solution

```powershell
pac solution export `
  --name <SolutionName> `
  --path "dist\<app>-<prefix>\<SolutionName>-complete.zip" `
  --managed false --overwrite
```

This is the user's **personalized** portable artifact (for redeployment to their test/staging/prod within the same tenant).

**Reminder: do NOT overwrite the source `examples/<app>/dataverse/AssetManagement.zip`** — that file is the publisher-agnostic template every future user's dynamic build starts from.

---

## What to do if a stage fails

| Symptom | Fix |
|---|---|
| `Solution '<X>' was not found` on stage 2+ | Stage 1 didn't complete. Re-run Stage 1 first. |
| `Must specify valid information for parsing in the string` | Version not bumped correctly. Check `<Version>` in solution.xml is higher than what's in env. |
| Stage 3 reports "lookup target table not found" | Stage 2 metadata not yet propagated. Wait 30 sec and retry import. |
| Imported tables appear in **Default Solution** instead of yours | Source customizations.xml was corrupted during prefix substitution. Rebuild the stage zip from a fresh source unpack. |
| Canvas App created OUTSIDE the solution | User missed the "Solutions → <Name> → + New → App" path. Delete the app and recreate through solution. |

---

## Don't do

- ❌ Don't pre-build stage zips and commit them to the repo
- ❌ Don't combine stages into one zip
- ❌ Don't skip approval gates even if PAC import succeeds
- ❌ Don't overwrite `examples/<app>/dataverse/AssetManagement.zip` with personalized content
- ❌ Don't try to re-import an unbumped-version zip (parsing error)
- ❌ Don't create the Canvas App outside the solution (Solutions → `<Name>` → +New is the ONLY correct path)

---

## Cross-references

- Source schema: [`examples/asset-management/dataverse/schema.yaml`](../examples/asset-management/dataverse/schema.yaml)
- Source template: `examples/asset-management/dataverse/AssetManagement.zip` (publisher-agnostic)
- Standards: [`memory/dataverse-schema-standards.md`](../memory/dataverse-schema-standards.md) → Path A
- Asset Management skill: [`skills/asset-management.md`](../skills/asset-management.md) → Path 3-PAC
- General schema work skill: [`skills/build-dataverse-schema.md`](../skills/build-dataverse-schema.md)
- Personalization script (for one-shot Path 3-FAST): `automation/Personalize-AssetManagement.ps1`
