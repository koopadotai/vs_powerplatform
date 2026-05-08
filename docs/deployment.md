# Deployment Guide

How to promote code from DEV → TEST → STAGING → PROD.

---

## TL;DR

| Action | How |
|---|---|
| Deploy to TEST | Tag a release on `main` — auto-deploys |
| Deploy to STAGING | Manual approval in GitHub Actions |
| Deploy to PROD | Manual approval + change ticket in GitHub Actions |

Full ALM details: [`memory/alm-standards.md`](../memory/alm-standards.md).

---

## Pre-deploy Checklist

- [ ] All tests pass on the commit being deployed
- [ ] CI status is green
- [ ] No uncommitted changes
- [ ] You have authentication to the target environment (`pac auth list`)
- [ ] For PROD: change ticket created and approved

---

## Power Platform Solution Deploy

### From the toolkit

```powershell
.\automation\Deploy-Solution.ps1 `
    -Solution AssetManagement `
    -Environment dev `
    -Version 1.2.0
```

### Manually via PAC CLI

```powershell
# Switch to target env
pac auth select --name <profile>

# Import managed solution
pac solution import --path .\solutions\AssetManagement\managed\AssetManagement_1_2_0_managed.zip

# Verify
pac solution list
```

---

## .NET Service Deploy

### Via GitHub Actions (preferred)

1. Tag a release: `git tag v1.2.0 && git push --tags`
2. The release workflow builds a container image and pushes to ACR
3. Deploy workflow promotes through environments with manual approvals

### Manually via Azure CLI

```powershell
.\automation\Deploy-DotNet.ps1 `
    -Service AssetApi `
    -Environment dev `
    -Version 1.2.0

# Or directly:
az containerapp update `
    --name asset-api `
    --resource-group rg-vsapp-dev `
    --image acrvsapp.azurecr.io/asset-api:1.2.0
```

---

## Post-deploy Verification

### Canvas App
- Open the app
- Confirm `AppVersion` label shows the new version
- Smoke test critical flows

### .NET Service
- `curl https://<service>.azurewebsites.net/version` — confirms the deployed version
- `curl https://<service>.azurewebsites.net/health` — must return 200
- Application Insights: no error spikes in last 5 minutes

---

## Rollback

### Power Platform
```powershell
.\automation\Rollback-Solution.ps1 `
    -Solution AssetManagement `
    -Environment <env> `
    -Version 1.1.0
```

This re-imports the previous managed solution.

### .NET Service
```powershell
# Re-deploy the previous tag
az containerapp update `
    --name asset-api `
    --resource-group rg-vsapp-prod `
    --image acrvsapp.azurecr.io/asset-api:1.1.0
```

---

## Communication

For STAGING and PROD deploys, post in `#deployments`:

```
Deploying <solution>/<service> v<version> to <env>
PR: <link>
Change ticket: <id> (PROD only)
ETA: <minutes>
```

After verification:

```
Deploy complete. Verified: AppVersion shows v<version>. Monitoring for 1 hour.
```

---

## Emergency Rollback Decision

If you see in PROD within 15 minutes of deploy:
- 5xx error rate > 5%
- Critical user flow broken
- Data corruption suspected

**Roll back immediately**, then investigate. Don't try to forward-fix in production.
