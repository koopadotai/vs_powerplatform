# Asset Management — Reference Implementation

End-to-end enterprise sample showing **Canvas App + Dataverse + .NET API** working together, following every toolkit standard.

## What's here

```
asset-management/
├── canvas/                    # Canvas App (phone form factor)
│   ├── App.pa.yaml
│   ├── HomeScreen.pa.yaml
│   ├── AssetListScreen.pa.yaml
│   ├── AssetDetailScreen.pa.yaml
│   └── AssetEditScreen.pa.yaml
├── dataverse/
│   └── schema.yaml            # 3 tables, 1 choice set, 3 security roles
├── api/                       # (Phase 2: scaffolded; flesh out as needed)
│   └── AssetApi/              # ASP.NET Core 10 API for reporting
└── docs/
    ├── schema.md              # ER diagram + table reference
    └── screens.md             # Screen-by-screen breakdown
```

## What it does

- **Track assets** — devices with serial numbers, categories, purchase dates, warranty
- **Assign / unassign** — link assets to employees with a date stamp
- **Search + filter** — find by name or serial
- **Status workflow** — Available → Assigned → In Repair → Retired / Lost
- **Reporting** — KPI cards on the home screen (total + assigned counts)

## Tech stack

| Layer | Tech |
|---|---|
| UI | Power Apps Canvas (phone) |
| Data | Dataverse (`ws_asset`, `ws_assetcategory`, `ws_assetassignment`) |
| Backend | ASP.NET Core 10 (for reporting/integrations) |
| Auth | Microsoft Entra ID |

## Quick start (recommended path)

The toolkit uses **two MCP servers** (canvas-authoring + Dataverse) so Claude can build the entire app — schema and screens — by reading `schema.yaml` and the `.pa.yaml` files. See [`memory/powerplatform-mcp-framework.md`](../../memory/powerplatform-mcp-framework.md) for the full framework overview.

### 1. Configure Dataverse MCP (one-time per dev/env)

In Claude Code:

```
/configure-dataverse-mcp
```

This registers the `@microsoft/dataverse` MCP server with your environment, with the `--preview` flag so Claude can create schema (tables/columns/choices/relationships).

### 2. Auto-create the Dataverse schema

In Claude Code, ask:

> Read `examples/asset-management/dataverse/schema.yaml` and create the tables in Dataverse.

Claude calls the Dataverse MCP create tools and produces:
- `ws_assetcategory` (table + 3 columns)
- `ws_asset` (table + 9 columns + lookup to category + lookup to systemuser)
- `ws_assetassignment` (table + 6 columns)
- `ws_assetstatus` (choice set, 5 options)
- 2 relationships (1:N: category→assets, 1:N: asset→assignments)

It will report which were created and any failures.

### 3. Configure canvas-authoring MCP for the new app

1. https://make.powerapps.com → New Canvas App (phone) → name it "Asset Management"
2. Settings → Updates → Coauthoring → ON
3. Copy the Studio URL
4. In Claude Code: `/configure-canvas-mcp` (paste URL when prompted)

### 4. Push the canvas app

In Claude Code:

> Compile `examples/asset-management/canvas/` to Studio.

Claude invokes `mcp__canvas-authoring__compile_canvas`. Within seconds, the home screen, asset list, detail, and edit screens appear in your Studio session.

### 5. Add the data sources to the app

In Power Apps Studio → **Data → + Add data**:
- Search "Assets" → Add
- Search "Asset Categories" → Add

The app immediately becomes functional — KPI counts populate, search works, you can add/edit/delete assets.

### 6. (Optional) Run the .NET reporting API locally

```powershell
cd examples\asset-management\api\AssetApi
dotnet run
# Open https://localhost:5001/openapi/v1.json
```

## Alternative — manual path (no MCP)

If you don't want to set up the MCP servers:

1. **Schema**: Open Power Platform maker portal → create the tables manually following [`docs/schema.md`](docs/schema.md), or use `pac solution import` if you have an existing solution package.
2. **Canvas**: Pack the YAML with `.\automation\Pack-Canvas.ps1` (only works if YAML was originally unpacked from a real .msapp; for hand-authored, use the maker portal to create the app shell, then add controls manually).

## Design Decisions

| Decision | Why |
|---|---|
| Status as a Choice (not a separate table) | Bounded, simple, reusable across views |
| Assignment as a separate table | Append-only audit history; supports multi-year reporting |
| Cascade delete = Restrict on Category | Prevent accidental loss of category data |
| `ws_serialnumber` as alternate key | Real-world assets have unique serials |
| Phone form factor | Most asset interactions happen on a phone (in the warehouse, at a desk) |

## Standards Compliance Checklist

- ✅ All controls follow toolkit naming
- ✅ Colors / spacing via named formulas
- ✅ `AppVersion` label on every screen
- ✅ All `Patch` calls wrapped in `IfError` with `Notify`
- ✅ Required fields enforced server-side (Dataverse) AND client-side (Save disabled)
- ✅ Three security roles (Reader, Manager, Administrator) with least-privilege
- ✅ Auditing enabled on all tables
- ✅ Documentation: schema.md + screens.md

## Customizing

To turn this into your own asset domain:

1. Rename schema (`ws_asset` → `ws_<yourthing>`)
2. Adjust columns (drop `ws_warrantyend` if not relevant; add `ws_location` if needed)
3. Adjust status choices in the YAML
4. Update screen labels and KPI formulas
5. Bump `AppVersion`

## Reference

- Schema: [`docs/schema.md`](docs/schema.md)
- Screens: [`docs/screens.md`](docs/screens.md)
- Standards followed:
  - [`memory/powerapps-canvas-standards.md`](../../memory/powerapps-canvas-standards.md)
  - [`memory/dataverse-schema-standards.md`](../../memory/dataverse-schema-standards.md)
  - [`memory/dotnet-api-standards.md`](../../memory/dotnet-api-standards.md)
