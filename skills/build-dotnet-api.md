---
description: Scaffold a new ASP.NET Core Web API project using the toolkit's standards. USE WHEN the user asks to build, create, or scaffold a .NET API, Web API, Minimal API, or backend service.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell
---

# Build .NET API Skill

## Step 1 — Read standards

- `memory/dotnet-api-standards.md`
- `memory/security-standards.md`
- `memory/alm-standards.md`
- `memory/ai-integration-standards.md` (if AI features involved)

## Step 2 — Clarify

Ask one question max:
- API style? (Minimal API by default; Controllers if complex)
- Auth provider? (Microsoft Entra ID by default)
- Persistence? (EF Core + SQL Server / Dataverse SDK / both)

## Step 3 — Scaffold from template

```powershell
# From the repo root
.\automation\New-Project.ps1 `
    -Type dotnet-api `
    -Name <ServiceName> `
    -Output src/<ServiceName>
```

This copies `templates/dotnet/api-starter/` and applies tokenization (service name, namespace).

## Step 4 — Generate the file structure

```
src/<ServiceName>/
├── Api/
│   ├── Endpoints/
│   │   └── <Domain>Endpoints.cs
│   └── Program.cs
├── Application/
│   ├── Commands/
│   ├── Queries/
│   └── DTOs/
├── Domain/
│   └── <Domain>.cs
├── Infrastructure/
│   ├── Persistence/
│   │   ├── AppDbContext.cs
│   │   └── Migrations/
│   └── Integrations/
├── appsettings.json
├── appsettings.Development.json
├── Dockerfile
└── <ServiceName>.csproj

tests/<ServiceName>.Tests/
├── Unit/
├── Integration/
└── <ServiceName>.Tests.csproj
```

## Step 5 — Required endpoints

Every API includes:
- `GET /health` — liveness
- `GET /ready` — readiness (checks DB + dependencies)
- `GET /version` — `{ name, version, commit, builtAt }`
- `GET /openapi/v1.json` — OpenAPI doc

## Step 6 — Required NuGet packages

Add via `dotnet add package`:

| Package | Purpose |
|---|---|
| `Microsoft.AspNetCore.Authentication.JwtBearer` | JWT auth |
| `Microsoft.AspNetCore.OpenApi` | OpenAPI generation |
| `Microsoft.EntityFrameworkCore.SqlServer` | EF Core provider |
| `FluentValidation.AspNetCore` | Input validation |
| `Serilog.AspNetCore` | Structured logging |
| `OpenTelemetry.Extensions.Hosting` | Observability |
| `Asp.Versioning.Http` | API versioning |

## Step 7 — Generate sample test

`tests/<ServiceName>.Tests/Unit/Domain/<Domain>Tests.cs` with at least one passing test using xUnit + FluentAssertions.

## Step 8 — Wire CI

Generate `.github/workflows/build-<service>.yml` for build + test on PR.

## Step 9 — Document

`src/<ServiceName>/README.md` — what it does, how to run locally, env vars required.

## Step 10 — Validate

```powershell
dotnet build
dotnet test
dotnet list package --vulnerable
```

All must pass before reporting done.

## Don't do

- Don't expose endpoints without auth
- Don't use `Console.WriteLine` for logging
- Don't add a third-party DI container
- Don't skip the health/ready/version endpoints
- Don't put secrets in `appsettings.json`
