# Enterprise Power Platform Developer Toolkit

A reusable, GitHub-ready development framework for rapidly building enterprise-grade Microsoft Power Platform solutions with Claude AI Agent integration in Visual Studio Code.

> Clone → run setup → build apps with AI assistance.

---

## What This Toolkit Provides

| Capability | Description |
|---|---|
| **AI-Assisted Development** | Pre-loaded Claude AI memory and skills for Power Apps, Dataverse, .NET, and integration patterns |
| **One-Command Setup** | Automated PowerShell scripts that install every dependency and validate your environment |
| **Reusable Templates** | Canvas Apps, Model-Driven Apps, .NET APIs, Azure Functions, Dataverse schemas |
| **Enterprise Standards** | Naming conventions, ALM, security, observability, CI/CD, governance |
| **Sample Application** | Asset Management reference app demonstrating end-to-end patterns |
| **CI/CD Pipelines** | GitHub Actions workflows for build, test, and deploy |

---

## Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Power Apps (Canvas + Model-Driven), Fluent UI |
| Backend | .NET 10, ASP.NET Core, Azure Functions, Minimal APIs |
| Data | Dataverse, SQL Server, PostgreSQL |
| DevOps | GitHub Actions, Docker, Azure DevOps (optional) |
| AI | Claude AI Agent (Opus 4.7), MCP Architecture |

---

## Quick Start (Windows)

### 1. Prerequisites
- Windows 10/11
- Administrator access
- A Microsoft Power Platform license + environment
- A GitHub account

### 2. Clone & Setup

```powershell
git clone https://github.com/koopadotai/vs_powerplatform.git
cd vs_powerplatform

# Idempotent — only installs what's missing. Skips already-installed tools.
.\scripts\windows\Install-All.ps1

# Optional flags:
#   -Update         Force upgrade tools that are already present
#   -IncludeAzure   Also install Azure CLI (Phase 3 deploys only)
#   -SkipVSCode     Skip VS Code (already have it)
#   -SkipWizard     Skip the post-install "what to build?" prompt

# Validate your environment
.\scripts\windows\Test-Environment.ps1
```

### 3. Connect to Power Platform

```powershell
.\scripts\windows\Connect-PowerPlatform.ps1
```

### 4. Open in VS Code

```powershell
code .
```

VS Code will load the workspace with Claude Code pre-configured.

### 5. Start Building

**Recommended first build — the Calculator POC.** Smallest possible app that exercises the full toolkit pipeline (hand-authored YAML → MCP → live in Studio). No data sources, no schema. Two screens.

```
/new-project canvas-app CalculatorPOC
```

Or browse [`examples/calculator-poc/`](examples/calculator-poc/) for the ready-made version.

**Other starting points:**

```
/build-canvas-app "Asset management for IT equipment"
/build-dataverse-schema "IT asset tracking with categories and assignments"
/build-dotnet-api AssetApi
```

For the end-to-end enterprise reference, browse [`examples/asset-management/`](examples/asset-management/) — Canvas + Dataverse + .NET API + ALM.

---

## Repository Layout

```
vs_powerapp/
├── docs/                                       # Architecture, onboarding, deployment, troubleshooting
│   ├── architecture.md
│   ├── deployment.md
│   ├── onboarding.md
│   ├── setup.md
│   └── troubleshooting.md
│
├── scripts/windows/                            # PowerShell setup + post-install wizard
│   ├── Install-All.ps1                         #   One-click installer (winget)
│   ├── Test-Environment.ps1                    #   Validation report
│   ├── Connect-PowerPlatform.ps1               #   PAC CLI auth wizard
│   └── Start-Toolkit.ps1                       #   Post-install "what to build?" wizard
│
├── memory/                                     # Claude AI memory (loaded as context)
│   ├── powerapps-naming.md
│   ├── powerapps-canvas-standards.md
│   ├── dataverse-schema-standards.md
│   ├── powerplatform-mcp-framework.md          #   canvas-authoring + Dataverse MCPs
│   ├── dotnet-api-standards.md
│   ├── security-standards.md
│   ├── alm-standards.md
│   └── ai-integration-standards.md
│
├── skills/                                     # Claude AI slash commands
│   ├── configure-dataverse-mcp.md              #   Register @microsoft/dataverse MCP
│   ├── build-canvas-app.md
│   ├── build-dataverse-schema.md               #   Uses Dataverse MCP when available
│   ├── build-dotnet-api.md
│   ├── new-project.md
│   ├── validate-app.md
│   └── deploy-solution.md
│
├── templates/                                  # Reusable starter projects
│   ├── powerapps/
│   │   ├── canvas-starter/                     #   Phone-form-factor Canvas App
│   │   │   ├── App.pa.yaml
│   │   │   ├── HomeScreen.pa.yaml
│   │   │   ├── ListScreen.pa.yaml
│   │   │   └── ProfileScreen.pa.yaml
│   │   └── dataverse/                          #   Schema YAML manifests
│   │       └── sample-schema/
│   ├── dotnet/
│   │   └── api-starter/                        #   ASP.NET Core 10 Minimal API
│   │       ├── src/__SERVICE_NAME__/           #     Token-replaced on scaffold
│   │       └── tests/__SERVICE_NAME__.Tests/
│   └── uiux/
│       └── themes/                             #   theme-modern, theme-corporate, theme-dark
│
├── examples/                                   # Reference applications
│   ├── calculator-poc/                         #   Minimal POC — no data, 2 screens
│   │   ├── canvas/
│   │   │   ├── App.pa.yaml
│   │   │   ├── MainScreen.pa.yaml              #     4-function calculator
│   │   │   └── CopyrightScreen.pa.yaml         #     User welcome + copyright
│   │   └── README.md
│   └── asset-management/                       #   End-to-end: Canvas + Dataverse + .NET API
│       ├── canvas/
│       ├── dataverse/schema.yaml
│       └── docs/
│
├── automation/                                 # Scaffolding + validation scripts
│   ├── New-Project.ps1                         #   Scaffold from any template
│   ├── Test-AppStandards.ps1                   #   Lint Canvas Apps + .NET services
│   └── Pack-Canvas.ps1                         #   PAC CLI canvas pack wrapper
│
├── devops/                                     # CI/CD + container assets
│   └── (github-workflows, docker)              # (Phase 3)
│
├── standards/                                  # Enterprise engineering standards
│   ├── architecture-principles.md
│   └── git-branching.md
│
├── .github/
│   ├── workflows/                              # CI + Release pipelines
│   └── PULL_REQUEST_TEMPLATE.md
│
├── .claude/settings.json                       # Project-scoped permissions
├── CLAUDE.md                                   # Repo-wide AI instructions
├── .gitignore
└── README.md
```

---

## Available Claude AI Commands

These slash commands are available in Claude Code once the toolkit is loaded:

| Command | Purpose |
|---|---|
| `/configure-dataverse-mcp` | Register Microsoft's Dataverse MCP server with Claude Code (one-time per env) |
| `/build-canvas-app <description>` | Generate a complete Canvas App from a natural-language description |
| `/build-dataverse-schema <domain>` | Design a Dataverse table schema (uses Dataverse MCP to create tables when available) |
| `/build-dotnet-api <name>` | Scaffold an ASP.NET Core Web API project |
| `/build-azure-function <name>` | Scaffold an Azure Function project |
| `/connect-data-source <connector>` | Wizard to add a data source to a Canvas App |
| `/deploy-solution <env>` | Export and deploy a Power Platform solution to a target environment |
| `/validate-app` | Run lint, security, and standards checks |
| `/new-project <type> <name>` | Create a new project from a template |

See `skills/` for the full list and source.

---

## Documentation

| Document | Purpose |
|---|---|
| [Onboarding Guide](docs/onboarding.md) | First-day setup for new developers |
| [Architecture Overview](docs/architecture.md) | High-level architecture and design decisions |
| [Setup Guide](docs/setup.md) | Detailed installation steps |
| [Deployment Guide](docs/deployment.md) | ALM, environments, release process |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and fixes |
| [Standards Index](standards/README.md) | All enterprise standards in one place |

---

## Contributing

This toolkit is maintained internally. To propose changes:

1. Create a feature branch: `git checkout -b feature/your-change`
2. Commit your work
3. Open a pull request — CI/CD will validate templates and standards
4. Request review from a Power Platform Architect

---

## Roadmap

- **Phase 1 (current)** — Core scaffolding, memory files, Windows setup, foundational standards
- **Phase 2** — Full template library, sample apps, .NET API templates
- **Phase 3** — CI/CD, Docker, deployment automation
- **Phase 4** — Advanced AI prompts, governance dashboards, multi-environment ALM

---

## License

Internal use only. © 2026 stlogsaiteam.
