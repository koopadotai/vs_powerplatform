# Power Platform MCP Framework

The toolkit relies on **two complementary MCP servers** to give Claude Code direct, programmatic access to Power Platform. Together they form the "Power Platform MCP Framework" — Claude reads/writes both Canvas Apps and Dataverse without manual export/import cycles.

---

## The Two MCP Servers

| Server | Provider | Purpose | Where to use |
|---|---|---|---|
| **canvas-authoring** | Microsoft (Power Apps team) | Read/write Canvas App `.pa.yaml` files in a live Studio session | Build, edit, sync Canvas Apps |
| **dataverse** | Microsoft (`@microsoft/dataverse` npm) | Read/write Dataverse schema and data in a live environment | Create tables/columns/relationships, query data |

Both are configured per-developer (in `.claude/settings.local.json`, which is gitignored). The toolkit ships skills that handle the registration:

- `/configure-canvas-mcp` — registers canvas-authoring for a specific Canvas App's Studio URL
- `/configure-dataverse-mcp` — registers dataverse for a specific Dataverse environment URL

---

## Server 1 — canvas-authoring MCP

### What it provides

| Tool | Purpose |
|---|---|
| `compile_canvas` | Push local `.pa.yaml` → live Canvas App in Studio |
| `sync_canvas` | Pull live Canvas App from Studio → local `.pa.yaml` |
| `list_controls` / `describe_control` | Inspect available control types |
| `list_apis` / `describe_api` | Inspect available connectors |
| `list_data_sources` / `get_data_source_schema` | Inspect data sources connected to the app |

### When to use

Any Canvas App work — building from natural language, editing screens, syncing changes back to Git.

### Setup
Plugin: `canvas-apps@power-platform-skills` (already installed)
Skill: `/configure-canvas-mcp`
Config target: a specific Canvas App via Studio URL (with `appid=...` and `environment-id=...`)

---

## Server 2 — Dataverse MCP

### What it provides

**GA tools** (`/api/mcp` endpoint — default):
- List tables
- Describe a table (columns, relationships, choice sets)
- Query data ("how many accounts do I have", row counts, sample reads)

**Preview tools** (`/api/mcp_preview` endpoint — opt-in via `--preview`):
- Create / update / delete tables
- Create / update / delete columns
- Create / update / delete choice sets (option sets)
- Create / update / delete relationships
- Schema migration capabilities

> Preview tools require **Allow MCP clients to interact with Dataverse MCP server (Preview version)** to be enabled in the environment's Power Platform Admin Center settings.

### When to use

| Scenario | Tool |
|---|---|
| "Show me what tables exist" | GA — list tables |
| "What columns does X have?" | GA — describe table |
| "How many rows in Y?" | GA — query |
| "Create the schema for Asset Management" | Preview — create tables/columns/relationships |
| "Add a `priority` column to `ws_asset`" | Preview — create column |

### Setup

Skill: `/configure-dataverse-mcp`

Tenant prerequisites (one-time per tenant):
- Tenant admin consent for app `0c412cc3-0dd6-449b-987f-05b053db9457`
- Dataverse CLI client enabled in the environment via Power Platform Admin Center

Per-developer configuration:
```json
{
  "mcpServers": {
    "dataverse": {
      "command": "npx",
      "args": ["-y", "@microsoft/dataverse", "mcp", "https://orgXXXXX.crm.dynamics.com"]
    }
  }
}
```

For schema-write capability, append `"--preview"` to the args array.

---

## How They Work Together

A complete app build with the framework:

```
Developer prompt: "Build the Asset Management app"
   │
   ▼
Claude reads memory + skills
   │
   ▼
┌──────────────────────────┐    ┌───────────────────────────────┐
│  Dataverse MCP           │    │  canvas-authoring MCP         │
│                          │    │                               │
│  /build-dataverse-schema │    │  /build-canvas-app            │
│  - Read schema.yaml      │    │  - Read App.pa.yaml + screens │
│  - Create tables         │    │  - compile_canvas             │
│  - Create columns        │    │  - Verify in Studio           │
│  - Create choice sets    │    │                               │
│  - Create relationships  │    │                               │
└──────────────────────────┘    └───────────────────────────────┘
   │                              │
   └──────────────┬───────────────┘
                  ▼
       Live, working app + data model
```

The Asset Management example uses BOTH servers end-to-end. See `examples/asset-management/README.md`.

---

## Routing — Which MCP for Which Task

| User says... | Use which MCP? |
|---|---|
| "Build / edit / fix the Canvas App" | canvas-authoring → `compile_canvas` |
| "What controls are available?" | canvas-authoring → `list_controls` |
| "Sync the live app back to YAML" | canvas-authoring → `sync_canvas` |
| "Create the tables in Dataverse" | Dataverse MCP (preview) → create-table tool |
| "List all tables" | Dataverse MCP (GA) |
| "Add a column to ws_asset" | Dataverse MCP (preview) |
| "How many assets do I have?" | Dataverse MCP (GA) |

If a request needs both (e.g. "Build asset-management — schema + canvas"), Claude should call them in order: **Dataverse MCP first** (so the data source exists when the canvas references it), then **canvas-authoring**.

---

## Authentication

Both servers use **Microsoft Entra ID** with the developer's signed-in user account. First time each MCP runs, it triggers a browser flow for sign-in, then caches the token.

For unattended scenarios (CI), use service principals — these need separate setup and aren't covered by the per-developer skills. See `memory/security-standards.md`.

---

## Rate Limits & Quotas

- Dataverse MCP inherits the calling user's Dataverse API limits (per-user-per-environment quota)
- canvas-authoring MCP shares the Studio coauthoring channel with the user's Studio session — heavy concurrent edits can cause merge conflicts
- For bulk operations (e.g. creating 50 tables), prefer:
  - Solution import via PAC CLI for Dataverse
  - Pre-built `.msapp` import for Canvas Apps

The MCP servers are best for incremental, exploratory, AI-driven changes — not bulk migrations.

---

## Failure Modes

| Symptom | Likely cause |
|---|---|
| MCP not in `claude mcp list` | Skipped registration, or Claude Code wasn't restarted |
| "Authorization failed" on first use | Tenant admin consent not granted for `0c412cc3-...` |
| "Client not allowed" | Dataverse CLI client not enabled in Power Platform Admin Center |
| Schema-write tools absent | Preview not enabled in env, or `--preview` missing from `claude mcp add` |
| Stale `Studio URL` for canvas-authoring | App was deleted/recreated; re-run `/configure-canvas-mcp` with fresh URL |

---

## Related Memory & Skills

- Memory: `memory/dataverse-schema-standards.md` — the rules Claude follows when creating tables (naming, security, choice sets)
- Memory: `memory/powerapps-canvas-standards.md` — Canvas App patterns
- Memory: `memory/security-standards.md` — auth and secret handling for service-principal scenarios
- Skill: `/configure-canvas-mcp` — register canvas-authoring
- Skill: `/configure-dataverse-mcp` — register Dataverse MCP
- Skill: `/build-canvas-app` — uses canvas-authoring
- Skill: `/build-dataverse-schema` — uses Dataverse MCP when available, falls back to YAML manifest
