---
description: Deploy a ready-made example from examples/ to a Power Apps Studio session in ONE command. USE WHEN the user says "deploy", "use", "run", "push", "compile", "install" or otherwise wants to take an existing example (calculator-poc, asset-management) and get it running in their Studio session.
allowed-tools: Read, Glob, Grep, Bash
---

# Deploy Example Skill

The single-command deploy. A team member runs this and Claude does everything except the unavoidable browser actions.

Use case: a team member just cloned the repo, opened Claude Code, and wants the calculator-poc (or any other example) running in their Power Apps Studio. They should not have to run multiple slash commands and restart Claude. One prompt, one result.

---

## Inputs the user must provide

The skill takes two pieces of information from the user's prompt:

1. **Example name** — `calculator-poc`, `asset-management`, etc.
2. **Studio URL** — the Power Apps Studio URL with `appid=...` and `environment-id=...` query params

If either is missing from the user's prompt, ask once. Examples of valid invocations:

> Deploy calculator-poc to https://make.powerapps.com/...?appid=ABC&environment-id=XYZ
>
> Use the calculator-poc example. Studio URL: https://...
>
> /deploy-example calculator-poc https://...

---

## Step 1 — Verify prerequisites are in place

Before doing anything irreversible, check:

| Check | If missing |
|---|---|
| `examples/<name>/canvas/` exists | Stop. List available examples: `ls examples/` |
| `examples/<name>/canvas/App.pa.yaml` exists | Stop. Tell the user the example is missing required files. |
| Studio URL contains `appid=` | Stop. Ask user for a complete Studio URL (the one with appid + environment-id). |
| `canvas-apps@power-platform-skills` plugin available | If not, tell user: "Run `.\scripts\windows\Install-All.ps1` to install the canvas-apps plugin first." |

## Step 2 — Confirm the human-only steps are done

Ask the user to confirm (don't proceed without):

- [ ] Empty Canvas App created in Studio (any name; will be overwritten with the example's screens)
- [ ] **Coauthoring is ON** in Studio (Settings → Updates → Coauthoring)

If they're not done yet, give the user a checklist:

```
1. Open https://make.powerapps.com
2. Click "+ New app" → Canvas → choose phone (or tablet) form factor
3. Save the app (give it any name)
4. Click the gear icon → Settings → Updates → toggle Coauthoring ON
5. Copy the URL from your browser tab — it should contain appid=...
6. Re-run me with that URL
```

## Step 3 — Configure canvas-authoring MCP for this Studio URL

If MCP isn't already pointed at the same `appid`:

Use the `canvas-apps:configure-canvas-mcp` skill (from the `canvas-apps@power-platform-skills` plugin) — pass the Studio URL. This registers the MCP server in `.mcp.json` (project scope) so subsequent compile_canvas calls hit the right app.

**If the user has a different MCP config already pointed elsewhere (e.g. another app), warn them before overwriting:**

> "Heads up — your canvas-authoring MCP is currently pointed at app `<name/id>`. Reconfiguring will switch it to `<new app>`. Continue? (yes/no)"

## Step 4 — Compile the example to Studio

Call `mcp__canvas-authoring__compile_canvas` with the source path:

```
sources: examples/<name>/canvas/
```

Wait for the response. If it reports errors, surface them clearly to the user (don't continue silently).

## Step 5 — Verify

After successful compile:

1. Use `mcp__canvas-authoring__list_data_sources` to see what's connected — for the calculator-poc, expect zero data sources (it's pure in-memory).
2. Tell the user to refresh Studio in their browser.
3. List the screens that should now exist (read from the example's `canvas/` folder filenames).

## Step 6 — Report

Final response to the user:

```
✓ Deployed <example-name> to <studio-url>
✓ Screens pushed: <list of *.pa.yaml file basenames>
✓ Compile errors fixed: <N> (auto-corrected by canvas-authoring MCP)
ⓘ Refresh Studio in your browser — your app is ready

Next steps:
  - Open the app in Studio and play it
  - To deploy a different example: ask me "deploy <other-example>"
  - To edit: open the .pa.yaml files in examples/<name>/canvas/ and re-run me
```

---

## Important constraints (be explicit when relevant)

These cannot be automated — surface them to the user gracefully:

- **Cannot create the empty Canvas App.** Microsoft hasn't shipped an API for this; the user must do it in the browser.
- **Cannot toggle Coauthoring.** Same reason.
- **Cannot read the user's mind.** If the Studio URL is missing `appid=`, ask for it; don't guess.
- **Cannot deploy to multiple apps simultaneously.** Each deploy targets one app via the configured MCP.

---

## Don't do

- Don't run `compile_canvas` without first verifying the MCP is configured for the user's URL — it would push to the wrong app
- Don't proceed if `examples/<name>/canvas/App.pa.yaml` is missing — fail loud instead
- Don't silently overwrite an existing MCP config pointed elsewhere — warn the user first
- Don't claim "deployed" if compile_canvas returned errors — surface them
- Don't ask the user to manually rebuild the example's screens if compile fails — the YAML files in the example are the source of truth; if the YAML is broken, fix the YAML, not the runtime
