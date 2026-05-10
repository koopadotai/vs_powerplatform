---
description: Deploy the complete Asset Management solution — Dataverse schema, seed data, and Canvas App — to a Power Apps environment. USE WHEN the user says "deploy asset management", "set up asset management", "run asset management", "use the asset management example", or wants the end-to-end asset tracking app running in their environment.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell
---

# Asset Management Skill

End-to-end deployment of the Asset Management reference implementation:
Dataverse schema → seed data → Canvas App in Studio.

Source: `examples/asset-management/`

---

## Inputs the user must provide

| Input | Where to find it / How to choose |
|---|---|
| **Dataverse environment URL** | `pac org who` shows the active env, OR make.powerapps.com → gear → Session details → Instance url |
| **Studio URL** (for Canvas App) | Open a blank Canvas App in Studio → copy browser URL (must contain `appid=...`) |
| **Publisher unique name** | Their org's publisher (e.g. `Contoso`, `AcmeCorp`). No spaces, alphanumeric only. If they don't have one, suggest one based on their org name. |
| **Publisher display name** | Friendly name (e.g. "Contoso Ltd"). Spaces allowed. |
| **Prefix** | 2–8 lowercase letters, their org's standard customization prefix (e.g. `acme`, `ctso`). All tables/columns/choices will use this prefix. |

If any of these are missing, ask once. Do not guess publisher info — different orgs have different naming standards. **Never deploy with the source `WeeSiongDev` / `ws` defaults to a team member's env** — it would pollute their tenant with a foreign publisher.

---

## Step 1 — Read standards (always)

Before doing anything:

- `memory/dataverse-schema-standards.md`
- `memory/powerapps-canvas-standards.md`
- `memory/powerapps-naming.md`
- `memory/powerplatform-mcp-framework.md`

---

## Step 2 — Verify prerequisites

| Check | If missing |
|---|---|
| PAC CLI installed (`pac --version`) | Tell user to run `.\scripts\windows\Install-All.ps1` |
| PAC CLI authenticated (`pac org who`) | Tell user to run `.\scripts\windows\Connect-PowerPlatform.ps1` |
| `examples/asset-management/dataverse/schema.yaml` exists | Stop — source files are missing; check the repo |
| `examples/asset-management/canvas/App.pa.yaml` exists | Stop — Canvas source is missing; check the repo |
| `automation/CreateSchema.ps1` exists | Stop — deployment script is missing |

If PAC CLI is not authenticated, guide the user:

```powershell
.\scripts\windows\Connect-PowerPlatform.ps1
```

---

## Step 3 — Deploy Dataverse schema

**This step MUST run before Step 5 (Canvas App).** The Canvas App references Dataverse tables by exact name; deploying canvas first will produce broken bindings.

Two deploy paths — **pick based on what's available in the user's env:**

| Path | Use when |
|---|---|
| **3-MCP** — Dataverse MCP (staged build) | User has Dataverse MCP set up + tenant admin consent + preview enabled. Best for fresh dev envs. See `skills/build-dataverse-schema.md` Path A. |
| **3-ZIP** — Personalize the .zip + `pac solution import` | Default. Works in corporate tenants where MCP is blocked. Reproducible across envs. |

Detect via:
```powershell
claude mcp list                          # Is dataverse listed AND connected?
pac org who                              # Confirm correct env
```

If `dataverse` shows ✓ Connected and `Create Table` is listed in its tools → 3-MCP available. Otherwise use 3-ZIP.

---

### Path 3-MCP — Staged build via Dataverse MCP (preferred when available)

The example ships with `examples/asset-management/dataverse/schema.yaml` as the source spec. Drive the MCP from this spec using the **6-stage pattern** in `skills/build-dataverse-schema.md` Path A. **Critical rules:**

- ✅ One artifact type per prompt (table, OR columns, OR choice, OR relationship)
- ✅ One table per prompt in stage 2
- ✅ 5–10 columns max per prompt in stage 4
- ✅ **ALWAYS prefix every prompt with: `Inside solution: AssetManagement` + `Use publisher prefix: <prefix>`**
- ✅ After every step: verify with `list_tables` / `describe_table`, wait ~5–10 sec for metadata propagation, then continue
- ❌ NEVER create tables + columns + lookups + choices in a single prompt — preview MCP is unstable for long chains
- ❌ NEVER omit "Inside solution: AssetManagement" — without it, MCP may create the table in **Default Solution** (especially preview mode)

**Recommended order for asset-management:**
1. Solution shell only (no tables)
2. Tables (one prompt each): Asset Category → Asset → Asset Assignment
3. Verify all 3 tables exist
4. Simple columns per table (one prompt per table — text/date/memo/currency)
5. Choice set `ws_assetstatus` (separate prompt)
6. Relationships LAST (one prompt per lookup):
   - ws_assetcategory → ws_asset (required, Restrict)
   - ws_asset → ws_assetassignment (required, RemoveLink)
   - SystemUser → ws_asset (optional, NoCascade)
   - SystemUser → ws_assetassignment (required, NoCascade)
7. Alternate key on `ws_asset.ws_serialnumber`

After all stages: `pac solution export --name AssetManagement --path AssetManagement.zip --managed false` to capture the portable artifact.

---

### Path 3-ZIP — Personalize and import the .zip

The example ships with a placeholder publisher (`WeeSiongDev`, prefix `ws`). Before importing into a team member's env, the AI agent **personalizes** the solution to use their publisher + prefix — so they don't inherit a foreign publisher and the tables match their org's naming standards. This is automatic — the team member never edits XML.

### 3A — Detect the active environment

```powershell
pac org who
```

Show output. Confirm the active env matches what the user expects. If wrong, run `pac auth select --index <n>` after `pac auth list`.

### 3B — Gather personalization inputs

Ask the user (only the values you don't already have):

```
I'll deploy the asset-management example to your env. To match your org's
naming standards, I need three things:

1. Publisher unique name (no spaces, alphanumeric, e.g. "ContosoCorp")
2. Publisher display name (friendly, e.g. "Contoso Corp")
3. Prefix (2-8 lowercase, e.g. "ctso") - this becomes the prefix on every
   table/column/choice (e.g. ctso_asset, ctso_assetname)

Suggested defaults based on your org domain (<orgname from pac org who>):
   - Publisher unique name: <Suggested>
   - Display name:          <Suggested>
   - Prefix:                <suggested>
```

Validate before proceeding:
- PublisherUniqueName: alphanumeric, starts with letter, 2-64 chars
- Prefix: 2-8 lowercase alphanumeric, starts with letter
- Reject `ws` and `WeeSiongDev` as values — those are the source defaults and would still leave the foreign publisher

### 3C — Personalize the solution + canvas

Run the personalization script with the gathered values:

```powershell
.\automation\Personalize-AssetManagement.ps1 `
    -PublisherUniqueName <unique-name> `
    -PublisherDisplayName "<display name>" `
    -Prefix <prefix>
```

This produces:
- `dist\asset-management-<prefix>\<SolutionName>.zip` — personalized Dataverse package
- `dist\asset-management-<prefix>\canvas\` — personalized Canvas App YAML files (table refs rewritten)

The original `examples/asset-management/` files are NEVER modified — they remain the publisher-agnostic source of truth.

### 3D — Check for conflicts in target env

```powershell
pac solution list | Select-String "AssetManagement"
```

If a same-named solution exists, ask the user if they want to overwrite (re-import is an upgrade, not destructive replace). If unsure, `pac solution delete --solution-name <name>` first.

### 3E — Import the personalized solution

```powershell
pac solution import --path "dist\asset-management-<prefix>\<SolutionName>.zip" --publish-changes
```

**Why this path (instead of CreateSchema.ps1):** Solution import uses PAC CLI's existing browser-based auth — works in any env where `pac auth list` shows an active connection. CreateSchema.ps1 needs a bearer token, has no working PAC token method in PAC 2.7.4, and falls back to device-code auth which is blocked by Conditional Access in many corporate tenants.

**Success criteria:** Output ends with `Solution Imported successfully.` and `Published All Customizations.`

### 3F — Verify the tables

```powershell
pac org list-tables --filter <prefix>_
```

Expect 3 tables: `<prefix>_assetcategory`, `<prefix>_asset`, `<prefix>_assetassignment` — using the prefix the user chose, not `ws`.

---

## Step 4 — Import seed data (optional)

Ask the user:

> "Do you want to import sample assets for testing? (10 realistic records covering all statuses)"

If yes:

```powershell
.\automation\Import-SeedData.ps1 -Environment <env-url>
```

**Success criteria:** All categories (5) and assets (10) show ✓ or "upserted".

---

## Step 5 — Deploy Canvas App

### 5A — Confirm human-only steps

The Canvas App MUST be created **inside the personalized solution** so everything ships as a single deployable unit. If created outside the solution, `pac solution export` won't include it and team-to-team handoff breaks.

Ask the user to confirm before proceeding:

- [ ] Empty Canvas App created **inside the personalized solution** (e.g. `AssetManagement` if they used default name) — phone form factor, name "Asset Management"
- [ ] **Coauthoring is ON** — Studio → Settings → Updates → Coauthoring
- [ ] Studio URL copied (must contain `appid=...`)

If not done, give this exact checklist (substitute `<SolutionDisplayName>` with the name from Step 3, e.g. "Asset Management"):

```
1. Open https://make.powerapps.com
2. Solutions (left rail) → click "<SolutionDisplayName>" (the one we just imported)
3. Click "+ New" → "App" → "Canvas app"
4. Choose: Phone form factor, name "Asset Management"
5. Click "Create" — this places the app INSIDE the solution (vs creating
   it standalone outside the solution, which would break the export)
6. Once Studio opens: Settings (gear) → Updates → toggle Coauthoring ON
7. Copy the URL from your browser tab — must contain appid=...
8. Paste it here
```

> **Why "inside the solution" matters:** Power Platform allows Canvas Apps to live as standalone components OR as members of a solution. Standalone apps are NOT exported when you run `pac solution export`. By creating the app inside the solution from the start, you guarantee that one `pac solution export` command produces a `.zip` containing both the Dataverse schema AND the Canvas App — a single deployable unit.

> **How to verify it's inside the solution:** After creating, in maker portal go to Solutions → AssetManagement → Objects → Apps. The new Canvas App should be listed there. If it's NOT listed and only appears under "Apps" (top-level), you created it outside the solution — delete it and redo from step 2.

### 5B — Configure canvas-authoring MCP

Use `canvas-apps:configure-canvas-mcp` with the Studio URL. If MCP is already pointed at a different app, warn before overwriting.

### 5C — Compile to Studio

Call `mcp__canvas-authoring__compile_canvas` with the **personalized** canvas folder from Step 3C — NOT the original source:

```
sources: dist/asset-management-<prefix>/canvas/
```

The personalized folder has table references rewritten to match the prefix used in Step 3 (e.g. `<prefix>_asset` instead of `ws_asset`). Compiling from `examples/asset-management/canvas/` would push references to `ws_asset` which doesn't exist in the user's env.

Wait for the response. Surface any errors clearly — do not claim success if errors are returned.

### 5D — Verify screens

After compile, confirm these screens are present:

- `HomeScreen` — KPI dashboard
- `AssetListScreen` — browse and search
- `AssetDetailScreen` — view single asset
- `AssetEditScreen` — add / edit form

---

## Step 6 — Connect data source in Studio

The Canvas App references Dataverse tables. After the user refreshes Studio:

Tell them:

> "The app is compiled. You now need to connect it to the Dataverse tables (using the prefix you chose in Step 3, shown here as `<prefix>`):
> 1. In Studio, go to **Data** (left rail) → **+ Add data**
> 2. Search for `Assets` → select the `Assets` table (`<prefix>_asset`)
> 3. Repeat for `Asset Categories` (`<prefix>_assetcategory`)
> 4. Save and republish the app"

If Dataverse MCP is available, you can call `mcp__canvas-authoring__list_data_sources` to check what's already connected.

---

## Step 7 — Report

Substitute `<prefix>` with the actual prefix the user chose in Step 3 (e.g. `ctso`):

```
✓ Dataverse schema deployed (publisher: <PublisherDisplayName>, prefix: <prefix>)
  - Tables       : <prefix>_assetcategory, <prefix>_asset, <prefix>_assetassignment
  - Choices      : <prefix>_status (5 options)
  - Relationships: 4
  - Alternate key: <prefix>_serialnumber (unique)

✓ Seed data imported (if requested)
  - Categories : 5
  - Assets     : 10 (all statuses covered)

✓ Canvas App compiled to Studio (INSIDE the <SolutionDisplayName> solution)
  - Screens : HomeScreen, AssetListScreen, AssetDetailScreen, AssetEditScreen

Everything is in ONE solution — to redeploy elsewhere or back up:
  pac solution export --name <SolutionUniqueName> --path <SolutionUniqueName>.zip --managed false

Next steps:
  1. Refresh Studio in your browser
  2. Add data sources: <prefix>_asset + <prefix>_assetcategory (Data → + Add data)
  3. Play the app
  4. Assign security roles in Power Platform Admin Center
```

---

## Partial deployments

If the user only wants part of the solution, handle these sub-intents:

| User says... | Do... |
|---|---|
| "Just create the Dataverse tables" | Steps 2, 3 only |
| "Just import the seed data" | Steps 2, 4 only |
| "Just deploy the app" | Steps 2, 5, 6 |
| "Re-run the schema" (fix a failure) | Step 3 only (idempotent — safe to re-run) |
| "Reset seed data" | Step 4 only (upsert — safe to re-run) |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `No access token found` | Run `.\scripts\windows\Connect-PowerPlatform.ps1` |
| Column create fails with 80044331 | Column already exists — this is a skip, not an error |
| Relationship already exists | Safe to ignore — script handles this |
| Canvas compile error: missing data source | Connect the Dataverse tables in Studio (Step 6) |
| App shows blank screens | Coauthoring may be off — verify in Studio Settings |
| Seed import fails on category upsert | The alternate key on `ws_categoryname` may not be set up — verify in Dataverse |

---

## Don't do

- Don't deploy the Canvas App before the Dataverse schema — the canvas references `ws_asset` and `ws_assetcategory` and will fail to bind data sources
- Don't use `CreateSchema.ps1` as the primary path — it requires a Dataverse bearer token and falls through to device-code auth, which corporate tenants commonly block. Prefer `pac solution import` with the `.zip`.
- Don't try to hand-craft Dataverse `customizations.xml` from scratch — the format has dozens of nested required elements (DisplayMask, IntroducedVersion=1.0.0.0, EntityRelationshipRoles with NavigationPropertyName + RelationshipRoleType, optionset with ExternalValue/IsHidden, EntityKeys with proper structure, etc.) and missing any one produces a vague error revealing only the next missing piece. If the `.zip` is lost, regenerate via the recipe below — never write the XML by hand.
- Don't claim Canvas App is "deployed" if compile_canvas returned errors
- Don't attempt to create the blank Canvas App programmatically — it requires browser interaction
- Don't run seed import before schema creation — the tables won't exist yet
- Don't modify `examples/asset-management/` source files during deployment — they are the source of truth

---

## Regenerating the AssetManagement.zip

If the `.zip` is missing or out of sync with `schema.yaml`, regenerate it via the **scaffold-then-export** recipe (NOT hand-crafted XML):

1. **User creates an empty solution + publisher in maker portal** (~30 sec):
   - make.powerapps.com → Solutions → New solution → Display name "Asset Management Scaffold", Name `AssetManagementScaffold`
   - New publisher: Display "Wee Siong Dev", Name `WeeSiongDev`, Prefix `ws`, Option-value prefix `10000`
   - Save (the empty solution exists)
2. **Hand-craft a minimal customizations.xml** with only text/datetime/memo/currency columns (no lookups, no picklists, no relationships, no alt keys) for the 3 tables — these simple types work fine in hand-crafted XML
3. **Pack and import** the minimal solution:
   ```powershell
   pac solution pack --zipfile AssetManagement.zip --folder ./src --packagetype Unmanaged
   pac solution import --path AssetManagement.zip --publish-changes
   ```
4. **User adds the complex parts in maker portal** (~5 min):
   - Choice column `Status` on Asset (Available, Assigned, In Repair, Retired, Lost — values 100,000,000–100,000,004, Business required, local choice)
   - Lookup columns: `Category` on Asset → Asset Category (required), `Assigned To` on Asset → User (optional), `Asset` on Asset Assignment → Asset (required), `Assigned To` on Asset Assignment → User (required)
   - Alternate key on Asset: Display name "Serial Number", column = Serial Number
5. **Export the completed solution** as the portable artifact:
   ```powershell
   pac solution export --name AssetManagement --path AssetManagement.zip --managed false --overwrite
   ```
6. **Commit** the new `.zip` to `examples/asset-management/dataverse/AssetManagement.zip`

**Why this hybrid:** Hand-crafting Dataverse customizations.xml for lookups/picklists/relationships/alt keys takes hours of error-iteration; maker portal handles each in 30 seconds. The exported result is portable and re-importable forever.
