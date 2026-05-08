# DevOps

CI/CD pipelines, container definitions, and deployment automation.

```
devops/
├── github-workflows/    # Reusable workflows referenced from .github/workflows/
└── docker/              # Dockerfile templates and compose files
```

## GitHub Actions

Workflows live in `.github/workflows/` at the repo root. Reusable workflows live in `devops/github-workflows/`.

Standard workflows:
- `ci.yml` — runs on every PR (build, test, lint)
- `release.yml` — runs on tag push (build artifacts)
- `deploy-test.yml` — promotes to TEST after release
- `deploy-staging.yml` — manual approval to STAGING
- `deploy-prod.yml` — manual approval + change ticket to PROD

## Docker

Containerization templates for .NET services. See `docker/Dockerfile.dotnet-api` for the standard pattern.

> Phase 1 ships starter CI workflow only. Full deploy workflows + Docker templates added in Phase 3.
