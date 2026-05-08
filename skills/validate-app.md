---
description: Run lint, security, and standards checks on a Canvas App or .NET service. USE WHEN the user asks to validate, check, lint, or audit an app or service.
allowed-tools: Read, Glob, Grep, Bash, PowerShell
---

# Validate App Skill

## Step 1 — Identify the target

Based on the user's request, identify the project to validate:
- Canvas App: `examples/<name>/*.pa.yaml`
- .NET service: `src/<name>/`

## Step 2 — Run the validation script

```powershell
.\automation\Test-AppStandards.ps1 -Path <path>
```

This runs:

### For Canvas Apps
- pa.yaml syntax validation (PAC CLI)
- Naming convention check (controls follow `<prefix><Name>`)
- Required formulas check (`AppVersion`, color palette)
- No hardcoded RGBA in screen files
- No bare `Console.WriteLine`-style anti-patterns
- Visible version label exists
- All Patch operations include required fields

### For .NET services
- `dotnet build` — must succeed
- `dotnet test` — must pass with ≥ 80% coverage on Application + Domain
- `dotnet list package --vulnerable` — no high-severity vulnerabilities
- `dotnet format --verify-no-changes` — code is formatted
- OpenAPI generation succeeds
- Required endpoints exist (`/health`, `/ready`, `/version`)
- No secrets in committed files
- Auth applied to all endpoints (or explicit `[AllowAnonymous]`)

## Step 3 — Report

Output a clear PASS/FAIL summary:

```
Canvas App Validation: examples/asset-management/

[PASS] pa.yaml syntax
[PASS] Naming conventions (24 controls)
[PASS] Required formulas (AppVersion, ColorPrimary, ...)
[FAIL] Hardcoded RGBA in 2 files:
       - HomeScreen.pa.yaml line 42: Fill: =RGBA(255, 0, 0, 1)
       - HomeScreen.pa.yaml line 78: Color: =RGBA(0, 0, 0, 1)

3 of 4 checks passed. Fix the failures and re-run.
```

## Step 4 — Suggest fixes

For each failure, suggest the specific fix or offer to apply it.

## Don't do

- Don't auto-fix without confirmation
- Don't skip checks because they're inconvenient
