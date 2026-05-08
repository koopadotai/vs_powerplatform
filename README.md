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
git clone https://github.com/koopadotai/vs_powerapp.git
cd vs_powerapp

# Run the one-click installer (installs everything)
.\scripts\windows\Install-All.ps1

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

In Claude Code, type:

```
/build-canvas-app "Asset management for IT equipment"
```

Or browse `examples/asset-management/` for the reference implementation.

---

## Repository Layout

```
vs_powerapp/
├── docs/                       # Architecture, onboarding, deployment guides
├── scripts/windows/            # PowerShell setup + automation
├── templates/                  # Reusable starter projects
│   ├── powerapps/              #   Canvas Apps, Model-Driven, Dataverse
│   ├── dotnet/                 #   ASP.NET Core APIs, Azure Functions
│   └── uiux/                   #   Mobile, tablet, dashboard layouts
├── memory/                     # Claude AI memory files (.md)
├── skills/                     # Claude AI slash-command skills
├── examples/                   # Reference applications
│   └── asset-management/       #   End-to-end sample
├── automation/                 # Project scaffolding + deployment scripts
├── devops/                     # CI/CD + Docker
│   ├── github-workflows/
│   └── docker/
├── standards/                  # Enterprise engineering standards
├── .claude/                    # Project-scoped Claude config
├── CLAUDE.md                   # Repo-wide AI instructions
└── README.md                   # This file
```

---

## Available Claude AI Commands

These slash commands are available in Claude Code once the toolkit is loaded:

| Command | Purpose |
|---|---|
| `/build-canvas-app <description>` | Generate a complete Canvas App from a natural-language description |
| `/build-dataverse-schema <domain>` | Design a Dataverse table schema for the given domain |
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
