---
description: Create a new project from a template (Canvas App, Model-Driven, .NET API, Azure Function, MCP Server). USE WHEN the user wants to start a new project, scaffold a new app, or create from a template.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell
---

# New Project Skill

This is the entry point for scaffolding any new project. Picks the right template and delegates to the specific skill.

## Step 1 — Identify project type

Available templates:

| Type | Skill | When |
|---|---|---|
| `canvas-app` | `build-canvas-app` | Power Apps Canvas — phone or tablet |
| `model-driven-app` | `build-model-driven-app` | Power Apps Model-Driven |
| `dataverse-schema` | `build-dataverse-schema` | Dataverse table design |
| `power-automate` | `build-power-automate` | Power Automate flow |
| `dotnet-api` | `build-dotnet-api` | ASP.NET Core Web API |
| `azure-function` | `build-azure-function` | Azure Functions service |
| `mcp-server` | `build-mcp-server` | Model Context Protocol server |
| `ai-middleware` | `build-ai-middleware` | AI orchestration .NET service |

If the user's request maps to one of these, delegate to that skill.

## Step 2 — Scaffold

Run:

```powershell
.\automation\New-Project.ps1 -Type <type> -Name <name>
```

This:
1. Copies the template
2. Tokenizes names (replaces `__PROJECT_NAME__` placeholders)
3. Initializes Git submodule or subdirectory
4. Adds the project to the workspace

## Step 3 — Apply standards

The target skill (`build-canvas-app`, etc.) takes over and applies its specific standards.

## Step 4 — Document

Add an entry to `examples/README.md` (if it's an example) or `src/README.md` (if it's a service).

## Don't do

- Don't create projects outside `templates/`, `examples/`, or `src/`
- Don't skip the standards in the target skill
