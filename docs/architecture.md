# Architecture Overview

---

## High-level diagram

```
                  ┌────────────────────────────────────┐
                  │       Claude AI (Opus 4.7)         │
                  │   - VS Code Claude Code extension  │
                  │   - Memory + skills loaded         │
                  └─────────────┬──────────────────────┘
                                │
                  ┌─────────────▼──────────────────────┐
                  │     Enterprise Toolkit (this)      │
                  │     - templates/                   │
                  │     - memory/                      │
                  │     - skills/                      │
                  │     - standards/                   │
                  └─────────────┬──────────────────────┘
                                │ generates
                ┌───────────────┴───────────────┐
                ▼                               ▼
     ┌──────────────────────┐         ┌──────────────────────┐
     │   Power Platform     │         │   .NET Services      │
     │                      │         │                      │
     │ - Canvas Apps        │         │ - ASP.NET Core APIs  │
     │ - Model-Driven Apps  │         │ - Azure Functions    │
     │ - Power Automate     │ ◀──────▶│ - AI Middleware      │
     │ - Dataverse          │   API   │ - MCP Servers        │
     └──────────┬───────────┘         └──────────┬───────────┘
                │                                │
                └────────────────┬───────────────┘
                                 ▼
                    ┌──────────────────────────┐
                    │   Microsoft Entra ID     │
                    │   Azure Key Vault        │
                    │   Application Insights   │
                    └──────────────────────────┘
```

---

## Layers

### Layer 1 — AI-Assisted Development
Claude Code in VS Code with the toolkit's `memory/` and `skills/` loaded. Developers describe what they want in natural language; Claude generates code that follows the standards.

### Layer 2 — Toolkit (this repo)
The "instruction set" for Claude:
- **Memory** (`memory/`) — standards Claude reads before generating
- **Skills** (`skills/`) — slash commands like `/build-canvas-app`
- **Templates** (`templates/`) — starter projects to copy
- **Standards** (`standards/`) — enterprise engineering rules
- **Automation** (`automation/`) — scripts for scaffolding, validation, deployment

### Layer 3 — Generated Solutions
- **Power Platform**: Canvas Apps, Model-Driven Apps, Power Automate flows, Dataverse tables
- **.NET Services**: APIs, Functions, AI middleware, MCP servers

### Layer 4 — Platform Services
- Microsoft Entra ID for auth
- Azure Key Vault for secrets
- Application Insights for observability
- Azure Container Apps / App Service for hosting

---

## Solution Lifecycle

```
Developer ─▶ Claude Code ─▶ Generated Code ─▶ Local validation
                                                    │
                                                    ▼
                                              Git commit + PR
                                                    │
                                                    ▼
                                              CI/CD (validate)
                                                    │
                                                    ▼
                                              Merge to main
                                                    │
                                                    ▼
                                       Tag release ─▶ Auto-deploy TEST
                                                            │
                                                            ▼
                                                Manual approval ─▶ STAGING
                                                            │
                                                            ▼
                                                Manual approval ─▶ PROD
```

See [`alm-standards.md`](../memory/alm-standards.md) for full ALM details.

---

## Key Decisions

| Decision | Rationale |
|---|---|
| Git is source of truth (not Studio) | Auditable, reviewable, branchable, rollback-able |
| .pa.yaml format for Canvas Apps | Mergeable, diff-able, generatable from natural language |
| Minimal API for new .NET services | Less ceremony, faster cold start, easier to read |
| Claude Opus 4.7 as primary AI model | Best reasoning for complex generation tasks |
| MCP for tool integration | Standardized, reusable across agents |
| GitHub Actions for CI/CD | Native GitHub integration; lower friction than Azure DevOps |
| Dataverse for primary data | Enterprise security, ALM, integration with Power Platform |

---

## Trust Boundaries

```
[ Browser/Device ] ──HTTPS──▶ [ Power App / Canvas ]
                                       │
                                       │ Entra ID JWT
                                       ▼
[ App ] ──HTTPS──▶ [ .NET API / Dataverse ]
                          │
                          ├──▶ [ Key Vault (secrets) ]
                          ├──▶ [ Anthropic Claude API ]
                          └──▶ [ Application Insights ]
```

- All API calls authenticated and authorized
- Secrets only in Key Vault
- AI calls go through middleware (auth, redaction, rate limit)
- Logs structured, redacted, retained per data classification

---

## Scaling Considerations

| Concern | Approach |
|---|---|
| Canvas App latency | Delegation-friendly queries; OnStart prefetch |
| API throughput | Stateless services; horizontal scaling on Container Apps |
| Dataverse limits | Solution-level archiving; index review for large tables |
| AI cost | Prompt caching; Haiku for first-pass; quotas per tenant |
| Cold starts | Always-on for critical services; warmup pings for Functions |

---

## Future Direction

- Phase 2 — Full template library
- Phase 3 — CI/CD automation, multi-env ALM
- Phase 4 — Governance dashboard (which apps exist, who owns them, when last deployed)
- Phase 5 — Self-service portal for non-developers
