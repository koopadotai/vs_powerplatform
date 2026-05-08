---
description: Deploy a Power Platform solution or .NET service to a target environment. USE WHEN the user asks to deploy, ship, release, or promote a solution or service.
allowed-tools: Read, Glob, Bash, PowerShell
---

# Deploy Solution Skill

## Step 1 — Confirm target environment

Ask for the target if not provided:
- DEV / TEST / STAGING / PROD

For PROD, also ask for the change ticket number — required for compliance.

## Step 2 — Read ALM standards

`memory/alm-standards.md`

## Step 3 — Pre-flight checks

Before running the deploy:

- [ ] Current branch matches the expected source for this environment
  - DEV: any feature branch
  - TEST: `develop` or a tag
  - STAGING: a release tag
  - PROD: a release tag with manual approval
- [ ] CI is green for the commit being deployed
- [ ] No uncommitted local changes (unless deploying to DEV from local)
- [ ] User is authenticated to the target environment (`pac auth list`)

## Step 4 — Run the deploy

### Power Platform solution

```powershell
.\automation\Deploy-Solution.ps1 `
    -Solution AssetManagement `
    -Environment <env> `
    -Version <semver>
```

This:
1. Exports the solution from source (managed)
2. Imports to target environment
3. Updates environment variables for that environment
4. Activates flows
5. Verifies the import succeeded

### .NET service

```powershell
.\automation\Deploy-DotNet.ps1 `
    -Service <ServiceName> `
    -Environment <env> `
    -Version <semver>
```

This:
1. Builds and tags the container image
2. Pushes to the container registry
3. Deploys to Azure App Service / Container Apps
4. Runs DB migrations (if any)
5. Verifies the `/health` endpoint

## Step 5 — Post-deploy verification

- Open the app/service and confirm `AppVersion` (Canvas) or `/version` (.NET) shows the new version
- Check Application Insights for errors in the last 5 minutes
- Smoke-test the critical user flows

## Step 6 — Communicate

For STAGING / PROD, post in `#deployments`:

```
Deployed AssetManagement v1.2.3 to PROD
Ticket: CHG-12345
Commit: abc1234
Verified by: <user>
```

## Don't do

- Don't deploy from a dirty working tree
- Don't skip the pre-flight checks
- Don't deploy directly to PROD without the staging rehearsal
- Don't deploy on Friday after 3pm (unless it's a hotfix)
