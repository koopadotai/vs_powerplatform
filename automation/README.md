# Automation Scripts

PowerShell scripts for project scaffolding, validation, and deployment.

| Script | Purpose | Status |
|---|---|---|
| `New-Project.ps1` | Create a new project from a template | Phase 2 |
| `Test-AppStandards.ps1` | Validate a Canvas App or .NET service against standards | Phase 2 |
| `Export-Solution.ps1` | Export a Power Platform solution from an environment | Phase 2 |
| `Import-Solution.ps1` | Import a managed solution to an environment | Phase 2 |
| `Deploy-Solution.ps1` | Full deploy: export from source, import to target | Phase 3 |
| `Deploy-DotNet.ps1` | Build + deploy a .NET service | Phase 3 |
| `Rollback-Solution.ps1` | Roll back a solution to a previous version | Phase 3 |
| `CreateSchema.ps1` | Create Dataverse tables from a schema YAML | Phase 2 |

All scripts:
- Use approved PowerShell verbs (PascalCase `Verb-Noun.ps1`)
- Include comment-based help (`<# .SYNOPSIS ... #>`)
- Use `$ErrorActionPreference = 'Stop'`
- Write structured output (success/warning/error)
- Authenticate via service principals in CI
