# Automation Scripts

PowerShell scripts for project scaffolding, validation, and packaging.

## Available now

| Script | Purpose |
|---|---|
| [`New-Project.ps1`](New-Project.ps1) | Scaffold a new project from any template (canvas-app, dotnet-api, dataverse-schema). Token-replaces `__SERVICE_NAME__`, `__APP_TITLE__`, `__BUILD_DATE__`. |
| [`Test-AppStandards.ps1`](Test-AppStandards.ps1) | Lint a Canvas App or .NET service against toolkit standards (naming, version label, hardcoded RGBA, required endpoints, vulnerable packages, secrets). |
| [`Pack-Canvas.ps1`](Pack-Canvas.ps1) | Wrap `pac canvas pack --layout SourceCode` to bundle YAML → `.msapp` (round-trip workflow only). |

## Planned (later phases)

| Script | Purpose | Phase |
|---|---|---|
| `CreateSchema.ps1` | Apply a Dataverse schema YAML to an environment (alternative to using Dataverse MCP) | 3 |
| `Export-Solution.ps1` | Export a Power Platform solution from an environment | 3 |
| `Import-Solution.ps1` | Import a managed solution to a target environment | 3 |
| `Deploy-Solution.ps1` | Full deploy: export from source, import to target | 3 |
| `Deploy-DotNet.ps1` | Build + deploy a .NET service to Container Apps | 3 |
| `Rollback-Solution.ps1` | Roll back a solution to a previous version | 3 |

## Conventions

All automation scripts follow:

- **Approved PowerShell verbs** — `Verb-Noun.ps1` (PascalCase). See `Get-Verb`.
- **Comment-based help** — `<# .SYNOPSIS / .DESCRIPTION / .EXAMPLE #>` at the top of every script.
- **Strict error handling** — `$ErrorActionPreference = 'Stop'` so failures surface immediately.
- **Structured output** — color-coded `[OK]` / `[WARN]` / `[FAIL]` with summary at the end.
- **Service principal auth in CI** — never personal accounts for unattended runs.
- **Idempotent where possible** — scripts can be re-run without side effects.

## Quick examples

```powershell
# Scaffold a new Canvas App
.\New-Project.ps1 -Type canvas-app -Name VehicleInspection `
                  -Title "Vehicle Inspection" -Tagline "Daily safety checks"

# Scaffold a new .NET API
.\New-Project.ps1 -Type dotnet-api -Name AssetApi

# Validate a project against standards
.\Test-AppStandards.ps1 -Path ..\examples\asset-management\canvas

# Pack a round-tripped Canvas App into .msapp
.\Pack-Canvas.ps1 -Source .\my-app-src -Output .\my-app.msapp -Force
```
