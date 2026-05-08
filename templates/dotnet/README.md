# .NET Templates

Reusable starter projects for .NET 10.

## Available now

| Template | Purpose |
|---|---|
| [`api-starter/`](api-starter/) | ASP.NET Core 10 Minimal API — JWT auth, MediatR (CQRS), EF Core, FluentValidation, Serilog, OpenTelemetry, xUnit tests, Dockerfile, Azure Key Vault integration |

## Planned

| Template | Purpose |
|---|---|
| `function-starter/` | Azure Functions isolated worker model |
| `ai-middleware-starter/` | AI orchestration service using Anthropic SDK with prompt caching |
| `mcp-server-starter/` | Model Context Protocol server scaffold |
| `dataverse-plugin-starter/` | Dataverse plugin (server-side custom logic) |

## How to use

### Via Claude Code

```
/build-dotnet-api <ServiceName>
```

### Via the script

```powershell
.\automation\New-Project.ps1 -Type dotnet-api -Name <ServiceName>
```

This copies `api-starter/` and replaces every `__SERVICE_NAME__` token with the actual service name.

## Standards

Every .NET template follows:
- [`memory/dotnet-api-standards.md`](../../memory/dotnet-api-standards.md) — Clean Architecture, async, DI, ProblemDetails
- [`memory/security-standards.md`](../../memory/security-standards.md) — auth, secrets, input validation
- [`memory/ai-integration-standards.md`](../../memory/ai-integration-standards.md) — for AI middleware services
