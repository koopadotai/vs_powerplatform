# Asset Management — Reference Implementation

End-to-end example of an enterprise Power Platform + .NET solution built with this toolkit.

## What it includes

- **Canvas App** — Phone-form-factor app for assigning and tracking IT equipment
- **Dataverse Schema** — `ws_asset`, `ws_assetcategory`, `ws_assetassignment`
- **.NET API** — REST API for reporting and integrations
- **Power Automate Flows** — Notification on assignment, monthly audit
- **CI/CD** — GitHub Actions for build, test, deploy

## Status

> **Phase 2** — This example is implemented in Phase 2 of the toolkit.
> Currently this folder is a placeholder; the structure and docs are committed
> so future Claude sessions know where to scaffold.

## Planned structure

```
asset-management/
├── canvas/
│   ├── App.pa.yaml
│   ├── HomeScreen.pa.yaml
│   ├── AssetListScreen.pa.yaml
│   └── AssetDetailScreen.pa.yaml
├── dataverse/
│   └── schema.yaml
├── flows/
│   ├── notify-on-assignment.json
│   └── monthly-audit.json
├── api/
│   └── AssetApi/
│       ├── src/
│       └── tests/
├── docs/
│   ├── schema.md          # ER diagram, table descriptions
│   ├── screens.md         # Screen-by-screen breakdown
│   └── deployment.md
└── README.md
```
