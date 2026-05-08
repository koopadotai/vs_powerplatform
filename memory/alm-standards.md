# ALM (Application Lifecycle Management) Standards

How we promote code from dev → test → staging → prod across Power Platform and .NET services.

---

## Environment Topology

| Environment | Purpose | Access |
|---|---|---|
| **DEV** | Developers' sandbox; rapid iteration | All developers, write access |
| **TEST** | Integration testing; QA validation | QA + developers, read on Dataverse |
| **STAGING** | Pre-production rehearsal; UAT | Stakeholders, read on Dataverse |
| **PROD** | Live system | Service principals only for deploys |

Each environment is a separate Power Platform environment + Azure resource group.

---

## Source of Truth

**Git is the source of truth — not Studio, not the Dataverse environment.**

- Canvas App `.pa.yaml` files are checked in
- Dataverse schema is exported as a solution and checked in (`solutions/<name>/`)
- Power Automate flow JSON is checked in
- .NET service code is checked in

When DEV diverges from Git, **Git wins** — re-import to DEV from the latest commit.

---

## Branch Strategy

```
main           ← protected; only PRs from develop
develop        ← integration branch
feature/*      ← short-lived feature branches
hotfix/*       ← emergency fixes branched from main
```

- Feature branches merge into `develop` via PR with reviewer + green CI
- `develop` merges into `main` for releases (tag = release version)
- Hotfixes branch from `main`, merge back to both `main` and `develop`

---

## Solution Strategy (Power Platform)

| Solution Type | Purpose |
|---|---|
| **Unmanaged** | DEV environment only — for editing |
| **Managed** | TEST, STAGING, PROD — read-only, supports clean rollback |

Solutions are exported from DEV as **unmanaged** (for backup) and **managed** (for promotion).

### Solution structure

```
solutions/
└── AssetManagement/
    ├── solution.xml
    ├── unmanaged/
    │   └── AssetManagement_1_0_0.zip
    └── managed/
        └── AssetManagement_1_0_0_managed.zip
```

---

## Versioning

Use **Semantic Versioning** (`MAJOR.MINOR.PATCH`):

| Bump | When |
|---|---|
| MAJOR | Breaking change — schema changes that aren't backward-compatible |
| MINOR | New feature — backward-compatible |
| PATCH | Bugfix — no behavior change for callers |

Tag every release in Git: `v1.2.3`.

The Canvas App `AppVersion` formula matches the Git tag.

---

## CI/CD Pipeline (GitHub Actions)

```
.github/workflows/
├── ci.yml             # PR validation
├── release.yml        # main branch → managed solution + .NET package
├── deploy-test.yml    # tag → TEST environment
├── deploy-staging.yml # manual approval → STAGING
└── deploy-prod.yml    # manual approval + change ticket → PROD
```

### CI on every PR
- Lint pa.yaml files
- Validate naming conventions
- Build .NET projects
- Run unit tests
- Generate solution package (don't import)

### Release on merge to main
- Tag the release
- Generate managed solution
- Build .NET container images
- Publish artifacts

### Deployment promotion
- Auto-deploy to TEST on tag
- Manual approval gate to STAGING
- Manual approval + change ticket to PROD

---

## Deployment Automation

PowerShell scripts in `automation/`:

| Script | Purpose |
|---|---|
| `Export-Solution.ps1` | Export DEV → Git |
| `Import-Solution.ps1 -Env <env>` | Import managed solution to target env |
| `Deploy-DotNet.ps1 -Env <env>` | Build + deploy .NET service |
| `Rollback-Solution.ps1 -Env <env> -Version <v>` | Roll back to a previous version |

All scripts authenticate via service principals (managed identity in CI).

---

## Environment Configuration

Per-environment settings via:

- **Power Platform** — Environment Variables (in solutions)
- **.NET** — `appsettings.{Environment}.json` + Key Vault references
- **Power Automate** — Connection References (env-specific)

No hardcoded URLs, IDs, or env names in code or Canvas Apps.

---

## Database Migrations

### Dataverse
- Schema changes go through solution import
- Backward-compatible additions (new optional columns) — deploy schema first, then code
- Breaking changes (column removals) — plan a multi-step migration:
  1. Stop writing to the old column
  2. Backfill new column
  3. Update code to read from new column
  4. Remove old column

### .NET (EF Core)
- Migrations checked in to `Infrastructure/Migrations/`
- Apply via `dotnet ef database update` in deploy script
- For Production: review migration SQL before applying; have a rollback plan

---

## Rollback Strategy

Every deploy must be rollback-capable:

- **Power Platform**: keep the previous managed solution version installed but not used; revert via solution layer
- **.NET**: keep the previous container image tagged; redeploy on rollback
- **Database**: never destroy data on rollback — feature-flag instead

---

## Release Communication

For each PROD release:

- Pre-release: post in `#deployments` Slack channel with PR list
- Post-release: confirm version label in app matches the deployed version
- Post-release: monitor Application Insights for errors for 1 hour

---

## Audit Trail

- Every deploy is logged in:
  - GitHub Actions run history
  - Application Insights deployment annotations
  - Power Platform audit logs
- Tagged with the change ticket number for compliance
