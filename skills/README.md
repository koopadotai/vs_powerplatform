# Claude AI Skills

Slash-command skills loaded by Claude Code in this repo.

| Skill | Trigger | Purpose |
|---|---|---|
| `configure-dataverse-mcp` | `/configure-dataverse-mcp` | Register Microsoft's `@microsoft/dataverse` MCP server with Claude Code so Claude can read/create Dataverse schema |
| `build-canvas-app` | `/build-canvas-app <description>` | Generate a Canvas App from a description |
| `build-dataverse-schema` | `/build-dataverse-schema <domain>` | Design a Dataverse schema (uses Dataverse MCP if configured, falls back to YAML manifest) |
| `build-dotnet-api` | `/build-dotnet-api <name>` | Scaffold an ASP.NET Core API |
| `new-project` | `/new-project <type> <name>` | Pick the right template and scaffold |
| `validate-app` | `/validate-app` | Run lint, security, standards checks |
| `deploy-solution` | `/deploy-solution <env>` | Export + deploy a solution |

## How a skill is structured

Each `.md` file has YAML frontmatter:

```markdown
---
description: Short description of what the skill does and when it triggers
allowed-tools: Read, Write, Edit, Bash, ...
---

# Skill Name

[Step-by-step instructions for Claude]
```

Claude Code surfaces these as slash commands. When invoked, the skill's body becomes Claude's instructions.

## Writing good skills

- Reference relevant `memory/` files at the top
- Define clear steps Claude should follow
- Specify "Don't do" guardrails
- Include code patterns or templates
- Keep skills focused — one job per skill

## Adding a new skill

1. Create `<skill-name>.md` in this folder with proper frontmatter
2. Reference it from `CLAUDE.md` if applicable
3. Update this README
