# Asset Management — Copilot Prompts (for maker portal "Start with Copilot")

Ready-to-paste prompts for building the Asset Management Dataverse schema using **Copilot inside Power Apps maker portal**. This is the most reliable path in corporate tenants where PAC CLI / Dataverse MCP have auth issues — Copilot runs natively inside maker portal you can already access.

> **Two flows in this file:**
> - **Flow A — One-shot combined prompt** (fast, single Copilot interaction creates everything)
> - **Flow B — Staged per-table prompts** (one prompt per table with approval between, safer for first-time use)
>
> If you have a non-`ws` prefix, replace `ws_` with your prefix (e.g. `acme_`) and `ws` with your prefix (e.g. `acme`) everywhere in the prompts before pasting. Copilot uses whatever prefix is in your text — it does NOT auto-detect the solution's publisher prefix.

---

## Stage 1 — Create the solution (manual, not Copilot)

Copilot creates tables, not solutions. Manually create the empty solution first:

1. Open https://make.powerapps.com
2. Left rail → **Solutions** → **+ New solution**
3. Fill in:
   - Display name: `Asset Management`
   - Name: `AssetManagement` (no spaces)
   - Publisher: pick existing OR **+ New publisher** with your display name + prefix
4. Click **Create**

You should land inside your solution's view. All subsequent prompts run from within this solution.

**Reply "approved" when done.**

---

## Stage 2 — Create the schema

Pick Flow A (faster) or Flow B (safer, with per-table validation).

### Flow A — One-shot combined prompt (RECOMMENDED for experienced users)

From inside your solution: **+ New** → **Table** → **Start with Copilot**. Paste this single prompt:

```
Create Dataverse tables with prefix ws_, Ownership=Organization, Auditing=On.

Table 1: Asset Category
Schema: ws_assetcategory
Primary: ws_categoryname
Columns:
ws_categoryname Text 80 Required
ws_icon Text 4
ws_description Memo 500

Table 2: Asset
Schema: ws_asset
Primary: ws_assetname
Columns:
ws_assetname Text 100 Required
ws_serialnumber Text 50 Required
ws_categoryid Lookup to ws_assetcategory Required
ws_status Choice ws_assetstatus Required
ws_purchasedate DateOnly
ws_purchasecost Currency
ws_warrantyend DateOnly
ws_assignedto Lookup to systemuser
ws_assigneddate DateTime
ws_notes Memo 2000

Table 3: Asset Assignment
Schema: ws_assetassignment
Primary: ws_assignmentname
Columns:
ws_assignmentname Text 50 Required
ws_assetid Lookup to ws_asset Required
ws_assignedto Lookup to systemuser Required
ws_assignedfrom DateTime Required
ws_assignedto_dt DateTime
ws_notes Memo 1000

Add alternate key on ws_asset:
ws_asset_serialnumber_key on ws_serialnumber.
Display name: Serial Number (Unique).

Choice set:
ws_assetstatus / Asset Status:
100000000 Available
100000001 Assigned
100000002 In Repair
100000003 Retired
100000004 Lost
```

Wait for Copilot to create everything. Validate in maker portal:
- 3 tables in your solution
- Each table has the right columns and types
- Lookups point to the right tables
- ws_status is a Choice with 5 options
- ws_asset → Keys shows "Serial Number (Unique)" as Active (~30 sec)

**Reply "approved" when done. Proceed to Stage 3.**

---

### Flow B — Staged per-table prompts (safer for first-time use)

Use these prompts in order with an approval gate between each — later tables reference earlier ones via lookups.

#### Stage 2a — Asset Category

From inside your solution: **+ New** → **Table** → **Start with Copilot**:

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

Validate: table created with 3 columns.

**Reply "approved" before Stage 2b.**

---

#### Stage 2b — Asset (with lookups, choice, alternate key)

From inside your solution: **+ New** → **Table** → **Start with Copilot**:

```
Create Dataverse table with prefix ws_, Ownership=Organization, Auditing=On.

Schema: ws_asset
Display: Asset
Primary: ws_assetname
Columns:
ws_assetname Text 100 Required
ws_serialnumber Text 50 Required
ws_categoryid Lookup to ws_assetcategory Required
ws_status Choice ws_assetstatus Required
ws_purchasedate DateOnly
ws_purchasecost Currency
ws_warrantyend DateOnly
ws_assignedto Lookup to systemuser
ws_assigneddate DateTime
ws_notes Memo 2000

Add alternate key: ws_asset_serialnumber_key on ws_serialnumber.
Display name: Serial Number (Unique).

Choice set ws_assetstatus / Asset Status:
100000000 Available
100000001 Assigned
100000002 In Repair
100000003 Retired
100000004 Lost
```

Validate: all 10 columns present, Status is Choice with 5 options, Category is lookup to Asset Category, Assigned To is lookup to User, Serial Number alternate key in Asset → Keys (Active after ~30 sec).

**Reply "approved" before Stage 2c.**

---

#### Stage 2c — Asset Assignment

From inside your solution: **+ New** → **Table** → **Start with Copilot**:

```
Create Dataverse table with prefix ws_, Ownership=Organization, Auditing=On.

Schema: ws_assetassignment
Display: Asset Assignment
Primary: ws_assignmentname
Columns:
ws_assignmentname Text 50 Required
ws_assetid Lookup to ws_asset Required
ws_assignedto Lookup to systemuser Required
ws_assignedfrom DateTime Required
ws_assignedto_dt DateTime
ws_notes Memo 1000
```

Validate: lookups point to Asset table and User table.

**Reply "approved" before Stage 3.**

---

## Stage 3 — Verify alternate key

If Flow A or Stage 2b was used, the Serial Number alternate key was requested. Verify:

1. Solution → Tables → **ws_asset** → **Keys**
2. Confirm **Serial Number (Unique)** key is listed with status **Active** (not Pending)

If missing or Pending after 1 minute, add manually:
1. + New key → Display name `Serial Number (Unique)` → Columns: Serial Number → Save
2. Wait for status to become Active

**Reply "approved" before Stage 4.**

---

## Stage 4 — Create public views

Copilot may or may not handle views well. If it does, paste each prompt below. Otherwise, build manually in maker portal: Tables → ws_asset → Views → + New view.

```
Create 5 public views in this solution:

View 1 (on ws_asset): "Available Assets"
Filter: ws_status equals 100000000 (Available)
Sort: ws_assetname ascending
Columns: ws_assetname, ws_serialnumber, ws_categoryid, ws_purchasedate, ws_warrantyend

View 2 (on ws_asset): "My Assigned Assets"
Filter: ws_assignedto equals current user AND ws_status equals 100000001 (Assigned)
Sort: ws_assigneddate descending
Columns: ws_assetname, ws_serialnumber, ws_categoryid, ws_assigneddate

View 3 (on ws_asset): "Out of Warranty"
Filter: ws_warrantyend less than today
Sort: ws_warrantyend ascending
Columns: ws_assetname, ws_serialnumber, ws_categoryid, ws_status, ws_warrantyend

View 4 (on ws_asset): "Recently Assigned"
Filter: ws_assigneddate greater than 30 days ago
Sort: ws_assigneddate descending
Columns: ws_assetname, ws_serialnumber, ws_assignedto, ws_assigneddate, ws_status

View 5 (on ws_assetassignment): "Active Assignments"
Filter: ws_assignedto_dt is empty
Sort: ws_assignedfrom descending
Columns: ws_assignmentname, ws_assetid, ws_assignedto, ws_assignedfrom
```

**Reply "approved" before Stage 5.**

---

## Stage 5 — Create the Canvas App (inside the solution)

**Critical:** Canvas App must be created INSIDE the solution.

1. Solutions → your solution → **+ New** → **App** → **Canvas app** → Phone form factor → name `Asset Management`
2. Click **Create**
3. Studio opens: **Settings** (gear) → **Updates** → toggle **Coauthoring** ON
4. Copy the Studio URL (must contain `appid=...`) and paste to Claude

Claude will then:
- Configure canvas-authoring MCP for the Studio URL
- Compile the 5 screens from `examples/asset-management/canvas/` into Studio
- Verify all screens loaded

After compile:
- Refresh Studio → Data → + Add data → add ws_asset and ws_assetcategory
- Play the app

**Reply "approved" when the app works.**

---

## Stage 6 — Export the complete solution as a portable .zip

```powershell
pac solution export `
  --name <YourSolutionUniqueName> `
  --path "dist\asset-management-<yourprefix>\<YourSolutionUniqueName>-complete.zip" `
  --managed false --overwrite
```

This is **your** personalized portable artifact for redeployment to test/staging/prod.

**Do NOT overwrite** `examples/asset-management/dataverse/AssetManagement.zip` — that file is the source template for future users.

---

## Troubleshooting Copilot prompts

| Problem | Fix |
|---|---|
| Copilot creates wrong type (e.g. text instead of choice) | Re-paste with explicit phrasing: "ws_status must be Choice with these 5 options" |
| Copilot ignores the alternate key | Add manually: Table → Keys → + New key → pick ws_serialnumber |
| Tables go to Default Solution instead of yours | You weren't INSIDE your solution. Delete orphan tables and redo from Solutions → AssetManagement → +New |
| Lookup points to wrong table | Follow-up prompt: "Change ws_categoryid to be a lookup to ws_assetcategory" |
| Choice option values are wrong | Edit manually: Tables → ws_asset → ws_status → adjust options |
| Custom prefix needed (not ws) | Search/replace `ws_` → `<yourprefix>_` and `ws ` → `<yourprefix> ` in the prompt before pasting |

---

## Why this path beats PAC CLI / MCP for corporate tenants

| Approach | Auth | Works in stlogs.com? |
|---|---|---|
| Dataverse MCP | Requires tenant admin consent for app `0c412cc3-...` | ❌ Blocked by Conditional Access |
| PAC solution import (re-importing exported zips) | Browser auth via PAC | ⚠️ Fails on same-env re-imports |
| Maker portal Copilot | Native browser session (same as Power Apps login) | ✅ Works — same auth that already works for you |

User stays in control — sees Copilot's output in real time and can correct before moving on, rather than getting opaque errors from CLI tools.
