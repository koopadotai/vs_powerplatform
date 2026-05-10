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

## Quick start — for any team member, any environment

After cloning this repo and running `.\scripts\windows\Install-All.ps1`, a teammate can deploy this entire example in their own Power Platform environment. The AI agent (Claude Code) handles the personalization automatically — they will **NOT** inherit the source publisher (`WeeSiongDev`) or prefix (`ws_`). They get their own publisher and prefix in their own tenant.

### Prerequisites (one-time)

```powershell
# 1. Tools (does Git, Node, .NET, PAC CLI, VS Code, Claude Code CLI, etc.)
.\scripts\windows\Install-All.ps1

# 2. Sign in to your Power Platform environment
.\scripts\windows\Connect-PowerPlatform.ps1
```

### Deploy the example

```powershell
# 3. Open Claude Code (the AI agent)
claude code

# 4. In the Claude Code session, type:
deploy asset-management
```

The AI agent will then walk you through 4 things:

1. **Personalize** — asks for your publisher unique name, display name, and prefix (e.g. "Contoso", "Contoso Ltd", "ctso")
2. **Auto-deploy Dataverse** — runs `Personalize-AssetManagement.ps1` and `pac solution import` (the .zip in `dataverse/AssetManagement.zip` is the deployable artifact)
3. **Prompts you** — to create an empty Canvas App **inside the imported solution** in maker portal (this step requires the browser; Microsoft does not expose an API for it)
4. **Auto-compile Canvas YAML** — pushes the personalized screens (rewritten with your prefix) into the Studio session

After that: refresh Studio, add the Dataverse tables as data sources, and the app is live.

### Critical: Canvas App must live INSIDE the solution

When the AI prompts you to create the Canvas App, follow these steps **exactly** so the app becomes part of the solution (not a standalone app):

1. https://make.powerapps.com → **Solutions** (left rail)
2. Click your imported solution (e.g. "Asset Management")
3. **+ New** → **App** → **Canvas app** → Phone form factor, name "Asset Management"
4. Click **Create** — this places the app inside the solution

> **Why this matters:** Power Platform allows Canvas Apps as standalone OR as solution components. Standalone apps are NOT included in `pac solution export`. By creating inside the solution, your one solution `.zip` contains both the Dataverse schema AND the Canvas App — a single deployable unit.

### Result — one solution, complete and portable

After deployment, in maker portal → Solutions → your solution, you'll see:
- 3 tables (`<prefix>_assetcategory`, `<prefix>_asset`, `<prefix>_assetassignment`)
- 1 choice column with 5 options (`<prefix>_status`)
- 4 relationships
- 1 Canvas App ("Asset Management")
- 1 alternate key on serial number

To redeploy this entire stack to another env (test, prod, another tenant):

```powershell
# Export the complete solution (Dataverse + Canvas in one zip)
pac solution export --name AssetManagement --path AssetManagement-prod.zip --managed false

# Import to the other env
pac auth select --index <other-env-profile>
pac solution import --path AssetManagement-prod.zip --publish-changes
```

### Re-deploying the original ws-prefixed `.zip` (for quick demo)

If you just want to see the example running quickly without your own publisher, you can directly import `dataverse/AssetManagement.zip` — but this will create the publisher **"Wee Siong Dev"** in your env (foreign publisher). For real use, always go through the AI agent personalization flow above.

### (Optional) Run the .NET reporting API locally

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
