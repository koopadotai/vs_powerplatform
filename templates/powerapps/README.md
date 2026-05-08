# Power Apps Templates

Reusable starter projects for Power Platform.

## Available now

| Template | Purpose |
|---|---|
| [`canvas-starter/`](canvas-starter/) | Phone-form-factor Canvas App skeleton with full theme system (named formulas), Home / List / Profile screens, 3-tab nav, version label |
| [`dataverse/sample-schema/`](dataverse/sample-schema/) | Schema YAML manifest format + asset-management sample (3 tables, 1 choice set, 3 security roles) |

## Planned

| Template | Purpose |
|---|---|
| `canvas-tablet-starter/` | Tablet form factor (1024 × 768) with split-view layouts |
| `model-driven-starter/` | Model-Driven App skeleton |
| `power-automate/` | Common flow patterns (approval, notification, scheduled) |

## How to use

### Via Claude Code (recommended)

```
/build-canvas-app "<description>"
/build-dataverse-schema "<domain>"
```

### Via the script

```powershell
.\automation\New-Project.ps1 -Type canvas-app -Name <YourAppName>
```

This copies `canvas-starter/` and replaces tokens (`__APP_TITLE__`, `__APP_TAGLINE__`, `__BUILD_DATE__`).

## Standards

Every Power Apps template follows:
- [`memory/powerapps-naming.md`](../../memory/powerapps-naming.md) — control naming (`btn`, `lbl`, `gal`, etc.)
- [`memory/powerapps-canvas-standards.md`](../../memory/powerapps-canvas-standards.md) — layout, theming, error handling
- [`memory/dataverse-schema-standards.md`](../../memory/dataverse-schema-standards.md) — table design rules
