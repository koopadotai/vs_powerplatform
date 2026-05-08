---
description: Configure the Microsoft Dataverse MCP server for Claude Code so Claude can read and write Dataverse schema directly. USE WHEN the user asks to set up Dataverse MCP, configure Dataverse for Claude, enable Dataverse access in Claude, or connect Claude to Dataverse.
allowed-tools: Read, Write, Edit, Bash, PowerShell
---

# Configure Dataverse MCP Skill

This skill registers Microsoft's official Dataverse MCP server (`@microsoft/dataverse`) with Claude Code so Claude can list/describe/create Dataverse tables, columns, choice sets, and relationships directly.

Reference: [Microsoft Learn — Connect to Dataverse with MCP in non-Microsoft clients](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/data-platform-mcp-other-clients)

---

## Step 1 — Read the framework memory

Always start by reading `memory/powerplatform-mcp-framework.md` for the broader context of how Dataverse MCP fits with canvas-authoring MCP.

## Step 2 — Confirm prerequisites with the user

Before running any commands, confirm with the user:

| Prereq | If missing |
|---|---|
| Tenant admin consent for Dataverse CLI app `0c412cc3-0dd6-449b-987f-05b053db9457` | Direct user to: `https://login.microsoftonline.com/{tenant-id}/adminconsent?client_id=0c412cc3-0dd6-449b-987f-05b053db9457` (one-time per tenant; tenant admin must visit) |
| **Dataverse CLI** client enabled in Power Platform Admin Center → Environment → Settings → Product → Features → **Dataverse Model Context Protocol** → Advanced Settings | Walk user through Power Platform Admin Center steps |
| Node.js 18+ installed (`node --version`) | Run `winget install OpenJS.NodeJS.LTS` or use the toolkit's `Install-All.ps1` |
| Dataverse environment URL (e.g. `https://orgXXXXX.crm5.dynamics.com`) | Get via `pac auth list` if the user is signed in via PAC CLI |

If the user wants **schema-write capability** (create tables/columns/relationships), they ALSO need:

| Prereq | How |
|---|---|
| Preview features enabled in their environment | Power Platform Admin Center → Environment → Settings → Product → Features → **Dataverse Model Context Protocol** → enable **Allow MCP clients to interact with Dataverse MCP server (Preview version)** |
| Use `--preview` flag when adding the MCP server | Skill handles this when user passes `-Preview` switch |

## Step 3 — Detect their environment URL

```bash
pac auth list
```

The "Environment Url" column shows the URL. Confirm with the user before using.

## Step 4 — Register the MCP server

### GA endpoint (read tools only)

```bash
claude mcp add dataverse -t stdio -- npx -y @microsoft/dataverse mcp <env-url>
```

### Preview endpoint (read + schema-write tools)

```bash
claude mcp add dataverse -t stdio -- npx -y @microsoft/dataverse mcp <env-url> --preview
```

Replace `<env-url>` with the Dataverse environment URL from Step 3.

> Note: the user must restart Claude Code after running this command for the new MCP server to be picked up. The first time it runs, they'll be prompted in a browser to sign in to Dataverse.

## Step 5 — Verify

After the user restarts Claude Code, ask them to test with:

> "List the tables in Dataverse"

Or:

> "Describe the account table"

If the response includes real table names from their environment, the MCP is wired up correctly.

## Step 6 — Document the setup

Write the configuration to:

```
.claude/settings.local.json   (per-developer, gitignored)
```

So that any teammate running this skill on the same machine doesn't have to redo the registration. Format:

```json
{
  "mcpServers": {
    "dataverse": {
      "command": "npx",
      "args": ["-y", "@microsoft/dataverse", "mcp", "<env-url>"]
    }
  }
}
```

(Add `"--preview"` to the args array if preview was enabled.)

## Step 7 — Hand off

Tell the user:

1. The MCP is registered as **`dataverse`**
2. Available tools depend on GA vs preview:
   - **GA**: list tables, describe tables, query data
   - **Preview**: + create tables, columns, choice sets, relationships
3. To create Dataverse tables for a project, see `skills/build-dataverse-schema.md` — that skill now uses Dataverse MCP automatically when available

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `npm` or `npx` not found | Install Node.js 18+ |
| Authentication browser flow doesn't open | Verify tenant admin consent (Step 2 prereq #1) |
| "Client not allowed" error | Enable the Dataverse CLI client in Power Platform Admin Center (Step 2 prereq #2) |
| Tools list empty after restart | Ensure user restarted Claude Code after `claude mcp add`; also check `claude mcp list` shows `dataverse` |
| Schema-write tools missing | Either preview wasn't enabled in env settings, OR `--preview` was omitted from the registration |

---

## Don't do

- Don't skip the tenant admin consent step — without it, every developer's auth flow will fail silently
- Don't run `claude mcp add` with the wrong URL — environment URLs differ between regions (`crm.dynamics.com` vs `crm5.dynamics.com` vs `crm4.dynamics.com`)
- Don't overwrite an existing `dataverse` MCP entry without confirming — the user may have a different env configured
- Don't commit Studio URLs or env URLs to a public repo if they reveal tenant IDs the org wants kept private
