# Memory Files

These markdown files are loaded by Claude AI as context when generating code or answering questions in this repo.

| File | Purpose |
|---|---|
| `powerapps-naming.md` | Naming conventions for all Power Platform artifacts |
| `powerapps-canvas-standards.md` | Canvas App layout, theming, formula, validation rules |
| `dataverse-schema-standards.md` | Dataverse table design, choices, lookups, security |
| `dotnet-api-standards.md` | ASP.NET Core API structure, auth, validation, observability |
| `security-standards.md` | OWASP-aligned security rules across all layers |
| `alm-standards.md` | Branching, environments, releases, deployment |
| `ai-integration-standards.md` | Claude API usage, prompt engineering, MCP servers |

## How memory is used

When the user makes a request, Claude reads the relevant memory files first (per the routing table in `CLAUDE.md`), then generates code that follows those standards.

## How to add a new memory file

1. Create `<topic>-standards.md` in this folder
2. Update the routing table in `CLAUDE.md` so Claude knows when to read it
3. Update this README

Memory files should be:
- Specific (not generic Power Apps tutorials — that's what the docs are for)
- Decisive (this is *the way*, not "consider also...")
- Actionable (give code patterns, not abstract advice)
- Referenced (link related memory files)
