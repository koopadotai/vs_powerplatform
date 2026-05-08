# Example Applications

Reference implementations demonstrating end-to-end patterns.

| Example | What it shows | Data |
|---|---|---|
| [`calculator-poc/`](calculator-poc/) | Minimal POC — Power Apps Canvas with two screens. The simplest possible end-to-end test of the toolkit's MCP build pipeline. | None (in-memory state only) |
| [`asset-management/`](asset-management/) | Full enterprise sample — Canvas + Dataverse + .NET API + ALM. Demonstrates the Power Platform MCP framework end-to-end (canvas-authoring + Dataverse MCPs). | 3 Dataverse tables + 1 choice set + 2 relationships |

## What each example includes

| Asset | Calculator POC | Asset Management |
|---|---|---|
| `App.pa.yaml` (named formulas, theme, AppVersion) | ✅ | ✅ |
| Canvas screens | 2 (Main + Copyright) | 4 (Home, List, Detail, Edit) |
| Dataverse schema YAML | — | ✅ |
| .NET API project | — | ✅ (skeleton; `examples/asset-management/api/`) |
| Power Automate flows | — | (planned) |
| Schema docs (ER diagram + table reference) | — | ✅ |
| Screen-by-screen docs | — | ✅ |

## How they're built

Both examples follow the toolkit's hand-authored YAML approach with deployment via the **canvas-authoring MCP server** (recommended) or manual import. The asset-management example additionally uses the **Dataverse MCP server** to create the schema directly from `dataverse/schema.yaml`.

See [`memory/powerplatform-mcp-framework.md`](../memory/powerplatform-mcp-framework.md) for how the two MCPs work together.

## When to use each

- **Calculator POC** — first time using the toolkit; verify your MCP setup; sandbox experiments
- **Asset Management** — reference for any real enterprise build (CRUD + lookups + status workflow + multi-screen navigation + role-based security)

## Adding a new example

1. Decide if it should live in `examples/` (reference) or `templates/` (reusable starter)
2. Create the folder with `canvas/`, optional `dataverse/`, optional `api/`, and `docs/`
3. Apply toolkit standards (naming, theming, AppVersion label, IfError on writes)
4. Run `.\automation\Test-AppStandards.ps1 -Path examples\<your-example>\canvas`
5. Add a row to the table at the top of this README
