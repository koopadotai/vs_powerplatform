# DevOps

CI/CD pipelines, container definitions, and deployment automation.

## Available now

GitHub Actions workflows are at the repo root in [`.github/workflows/`](../.github/workflows/):

| Workflow | Trigger | Purpose |
|---|---|---|
| [`ci.yml`](../.github/workflows/ci.yml) | PR + push to `main`/`develop` | YAML lint, .NET build + test, vulnerability scan, secret scan, markdown lint |
| [`release.yml`](../.github/workflows/release.yml) | Push of `v*.*.*` tag | Build artifacts, package solutions, create GitHub Release |

A reference Dockerfile ships with the .NET API template at [`templates/dotnet/api-starter/src/__SERVICE_NAME__/Dockerfile`](../templates/dotnet/api-starter/src/__SERVICE_NAME__/Dockerfile) — multi-stage, runs as non-root.

## Planned (Phase 3)

```
devops/
├── github-workflows/        # Reusable workflows imported by .github/workflows/
│   ├── deploy-canvas.yml    #   Promote Canvas App via solution import
│   ├── deploy-dotnet.yml    #   Build + push to ACR + deploy to Container Apps
│   └── deploy-dataverse.yml #   Apply schema changes via solution import
└── docker/
    ├── Dockerfile.dotnet-api    # Reusable template (currently lives with each service)
    └── compose.dev.yml          # Local docker-compose for full stack
```

| Workflow | Trigger | Purpose |
|---|---|---|
| `deploy-test.yml` | Tag push | Auto-promote to TEST environment |
| `deploy-staging.yml` | Manual approval | Promote to STAGING |
| `deploy-prod.yml` | Manual approval + change ticket | Promote to PROD |

## Standards

- Workflows pin actions to specific SHAs (or major version tags from trusted publishers)
- Secrets stored in GitHub Actions secrets / environments — never in committed files
- Production deploys require approval + audit trail (change ticket)
- See [`memory/alm-standards.md`](../memory/alm-standards.md) for the full ALM model
