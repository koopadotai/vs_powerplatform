# .NET API Starter

ASP.NET Core 10 Minimal API following toolkit standards.

## What's included

- Minimal API with `/v1/items` CRUD endpoints
- JWT Bearer authentication (Microsoft Entra ID)
- Authorization policies (`CanRead`, `CanWrite`)
- Required endpoints: `/health`, `/ready`, `/version`, `/openapi/v1.json`
- EF Core 10 + SQL Server
- FluentValidation at the API boundary
- MediatR (CQRS pattern: Commands + Queries)
- Serilog structured logging
- OpenTelemetry tracing
- API versioning (`Asp.Versioning`)
- xUnit + FluentAssertions test project
- Dockerfile (multi-stage, non-root)
- Azure Key Vault integration for production secrets

## Layout

```
src/__SERVICE_NAME__/
├── Api/
│   ├── Endpoints/
│   │   └── ItemsEndpoints.cs          ← /v1/items handlers
│   └── Program.cs                      ← App composition
├── Application/
│   ├── Commands/CreateItemCommand.cs
│   ├── Queries/GetItemsQuery.cs
│   ├── DTOs/CreateItemRequest.cs       ← + Validator
│   └── DependencyInjection.cs
├── Domain/
│   └── Item.cs                         ← Aggregate root
├── Infrastructure/
│   ├── Persistence/AppDbContext.cs
│   └── DependencyInjection.cs
├── appsettings.json
├── appsettings.Development.json
├── Dockerfile
└── __SERVICE_NAME__.csproj

tests/__SERVICE_NAME__.Tests/
└── Unit/ItemTests.cs
```

## Tokens

When scaffolded by `New-Project.ps1`, these are replaced everywhere:

| Token | Replaced with |
|---|---|
| `__SERVICE_NAME__` | The service name in PascalCase (e.g. `AssetApi`) |

## How to use

### Via Claude Code

```
/build-dotnet-api AssetApi
```

### Via the script

```powershell
.\automation\New-Project.ps1 -Type dotnet-api -Name AssetApi
```

### Manually

1. Copy this folder to `src/<YourServiceName>/`
2. Find-and-replace `__SERVICE_NAME__` with the actual name
3. Update `Jwt:Audience` in `appsettings.json` to your Entra app registration
4. Run `dotnet restore && dotnet build && dotnet test`

## Running locally

```powershell
cd src\<YourServiceName>
dotnet run
# Open https://localhost:5001/openapi/v1.json
```

For local SQL: ensure LocalDB is installed (ships with VS), or update the `Default` connection string.

## Standards followed

- Clean Architecture: Api → Application → Domain ← Infrastructure
- All endpoints async + cancellation token
- All endpoints require auth (or explicit `.AllowAnonymous()`)
- ProblemDetails (RFC 7807) for errors
- Structured logging with parameters (never string-interpolated)
- Required `/health`, `/ready`, `/version` endpoints
- Container runs as non-root (`USER $APP_UID`)

See [`memory/dotnet-api-standards.md`](../../../memory/dotnet-api-standards.md) for the full ruleset.

## Adding a new endpoint group

1. Create `src/__SERVICE_NAME__/Api/Endpoints/<Domain>Endpoints.cs`
2. Add a static `Map<Domain>Endpoints` extension method
3. Wire it in `Program.cs`: `app.Map<Domain>Endpoints();`
4. Create matching Command / Query / DTO files in `Application/`
5. Add a test in `tests/Unit/<Domain>Tests.cs`

## Deployment

- Containerized: see `Dockerfile`
- Push to ACR: `az acr build`
- Deploy: `az containerapp update`

Or use the GitHub Actions release workflow.
