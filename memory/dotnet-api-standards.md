# .NET 10 API Standards

These standards apply to all ASP.NET Core APIs and Azure Functions in this toolkit.

---

## Project Structure

```
src/<ServiceName>/
├── Api/                       # Endpoints (Minimal API or Controllers)
├── Application/               # Use cases, application services
│   ├── Commands/              # Write operations
│   ├── Queries/               # Read operations
│   └── DTOs/                  # Data transfer objects
├── Domain/                    # Entities, aggregates, domain events
├── Infrastructure/            # EF Core, external integrations, Dataverse SDK
└── <ServiceName>.csproj

tests/<ServiceName>.Tests/
├── Unit/
├── Integration/
└── <ServiceName>.Tests.csproj
```

Follows **Clean Architecture** — dependencies point inward (Api → Application → Domain ← Infrastructure).

---

## API Style: Minimal API by Default

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opts => builder.Configuration.Bind("Jwt", opts));
builder.Services.AddAuthorization();
builder.Services.AddOpenApi();

builder.Services.AddScoped<IAssetService, AssetService>();

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/assets/{id:guid}", async (Guid id, IAssetService svc) =>
{
    var asset = await svc.GetAsync(id);
    return asset is null ? Results.NotFound() : Results.Ok(asset);
})
.RequireAuthorization()
.WithName("GetAsset")
.WithOpenApi();

app.Run();
```

Use Controllers only when you need:
- Heavy filter pipelines
- Action filters
- Model binding from forms
- A team that's already on Controllers

---

## Required Endpoints on Every Service

| Path | Purpose |
|---|---|
| `GET /health` | Liveness probe — returns 200 if process is up |
| `GET /ready` | Readiness probe — returns 200 if dependencies are reachable |
| `GET /version` | Returns `{ name, version, commit, builtAt }` |
| `GET /openapi/v1.json` | OpenAPI document |

---

## Configuration

- `appsettings.json` — defaults (committed)
- `appsettings.{Environment}.json` — per-environment (committed if non-secret)
- `appsettings.Local.json` — developer overrides (gitignored)
- **Secrets** — Azure Key Vault via `Microsoft.Extensions.Configuration.AzureKeyVault`

Never put connection strings, tokens, or keys in committed files.

---

## Authentication & Authorization

- JWT Bearer via Microsoft Entra ID (Azure AD)
- All endpoints require auth by default — explicit `.AllowAnonymous()` for exceptions
- Authorization via policies, not roles directly:

```csharp
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("CanReadAssets", p => p.RequireClaim("scope", "assets.read"));
    options.AddPolicy("CanWriteAssets", p => p.RequireClaim("scope", "assets.write"));
});

app.MapPost("/assets", CreateAsset).RequireAuthorization("CanWriteAssets");
```

---

## Error Handling

Use `ProblemDetails` (RFC 7807) for all error responses:

```csharp
builder.Services.AddProblemDetails();

app.UseExceptionHandler();
app.UseStatusCodePages();
```

Custom error responses:

```csharp
return Results.Problem(
    title: "Asset not found",
    detail: $"No asset with id {id}",
    statusCode: StatusCodes.Status404NotFound,
    type: "https://api.example.com/errors/asset-not-found"
);
```

---

## Validation

Use `MinimalApis.Extensions` or `FluentValidation` at the API boundary:

```csharp
public sealed record CreateAssetRequest(string Name, string SerialNumber);

public sealed class CreateAssetValidator : AbstractValidator<CreateAssetRequest>
{
    public CreateAssetValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.SerialNumber).NotEmpty().Matches(@"^[A-Z0-9-]+$");
    }
}
```

---

## Logging

- Use `ILogger<T>` — never `Console.WriteLine`
- Structured logging — pass values as parameters, not string-interpolated:

```csharp
// Good
_logger.LogInformation("Asset {AssetId} created by {UserId}", asset.Id, userId);

// Bad
_logger.LogInformation($"Asset {asset.Id} created by {userId}");
```

- Log levels:
  - `Trace` / `Debug` — dev only
  - `Information` — significant events (created, deleted, signed in)
  - `Warning` — recoverable problem
  - `Error` — exception or failure
  - `Critical` — service is degraded or down

- **Never log**: passwords, tokens, full credit cards, full SSNs, or PII without redaction

---

## Observability

- **OpenTelemetry** for traces and metrics (Azure Monitor exporter)
- **Application Insights** for production
- All HTTP requests automatically traced
- Custom metrics for business KPIs (e.g. `assets.created.count`)

---

## Async All The Way

- All I/O is async — use `async`/`await`
- Never `.Result` or `.Wait()` on a Task
- Use `CancellationToken` from controllers/endpoints down to repositories

---

## Dependency Injection

- Use built-in `IServiceCollection` — no third-party DI containers unless required
- Lifetimes:
  - **Singleton** — stateless services, configuration
  - **Scoped** — per-request services (DbContext, request-scoped state)
  - **Transient** — lightweight, stateless, frequently created

---

## Database (EF Core)

- One `DbContext` per bounded context
- Migrations live in `Infrastructure/Migrations/`
- Use `IDbContextFactory<T>` for background services
- All queries are async
- Use compiled queries for hot paths

---

## Dataverse Integration

For .NET services calling Dataverse, use the official SDK:

```csharp
builder.Services.AddSingleton<ServiceClient>(sp =>
{
    var connStr = builder.Configuration.GetConnectionString("Dataverse");
    return new ServiceClient(connStr);
});
```

Wrap calls in a repository so business logic doesn't depend on the SDK.

---

## Testing

- **Unit tests** — pure logic, no I/O — `xUnit` + `FluentAssertions`
- **Integration tests** — `WebApplicationFactory<TProgram>` + `Testcontainers` for DB
- Coverage target: **80%** on Application + Domain layers

---

## Versioning

- Semantic versioning on the package
- API versioning via URL prefix: `/v1/assets`, `/v2/assets`
- Use `Asp.Versioning` package
- Deprecate old versions with `Sunset` and `Deprecation` headers per RFC 8594

---

## Containerization

Every service ships with a `Dockerfile`:

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app/publish --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "ServiceName.dll"]
```

See `devops/docker/` for the full template.
