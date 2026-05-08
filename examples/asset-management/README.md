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

## Quick start

### 1. Create the Dataverse schema

```powershell
.\automation\CreateSchema.ps1 `
    -Schema examples\asset-management\dataverse\schema.yaml `
    -Environment dev
```

### 2. Seed sample data (optional)

```powershell
.\automation\Seed-Data.ps1 `
    -Schema examples\asset-management\dataverse\schema.yaml `
    -Environment dev
```

### 3. Open the canvas app

1. Open Power Apps Studio (make.powerapps.com) → New Canvas App (phone)
2. Enable coauthoring: **Settings → Updates → Coauthoring**
3. Add the data source: **Data → + Add data → "Assets"** (also Asset Categories)
4. From VS Code, run **Compile canvas app to Power Apps Studio**

### 4. Run the API locally

```powershell
cd examples\asset-management\api\AssetApi
dotnet run
# Open https://localhost:5001/openapi/v1.json
```

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
