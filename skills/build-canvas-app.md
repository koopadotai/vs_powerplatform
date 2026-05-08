---
description: Build a complete enterprise Power Apps Canvas App from a natural-language description. USE WHEN the user wants to create, build, or generate a new Canvas App.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build Canvas App Skill

You are building a new enterprise Canvas App in the Power Platform Toolkit.

## Step 1 — Read standards (always)

Before generating any YAML, read these memory files:

- `memory/powerapps-canvas-standards.md`
- `memory/powerapps-naming.md`
- `memory/dataverse-schema-standards.md` (if the app uses Dataverse)

## Step 2 — Ask one clarifying question (max)

Pick the single most important unknown:
- Form factor? (phone vs tablet)
- Data source? (Dataverse / SharePoint / SQL / standalone collections)
- Authentication required? (default: yes)

## Step 3 — Scaffold from template

1. Create folder: `examples/<app-name>/`
2. Copy from `templates/powerapps/canvas-starter/`
3. Customize:
   - `App.pa.yaml` — set `AppVersion`, app-specific `Formulas:`
   - `<Screen>.pa.yaml` — generate per-screen layouts
   - `README.md` — describe what the app does

## Step 4 — Apply standards

Every generated app must:

- Use named formulas for all colors and spacing (no hardcoded RGBA in screens)
- Include a visible `lblVersion` label per `powerapps-canvas-standards.md`
- Follow naming conventions (`btn`, `lbl`, `gal`, etc.)
- Wrap data writes in `IfError` with `Notify`
- Be sized correctly for the chosen form factor

## Step 5 — Confirm before destructive operations

If the user is overwriting an existing app, confirm first.

## Step 6 — Document

Update:
- `examples/<app-name>/README.md` — what the app does, screens, dependencies
- `examples/<app-name>/docs/screens.md` — screen-by-screen breakdown
- `examples/<app-name>/docs/data-model.md` (if using Dataverse)

## Step 7 — Report

Summarize in your response:
- Files created
- How to deploy: "Open Power Apps Studio → enable coauthoring → run Compile task"
- Any TODOs the user must complete (e.g. add data source, upload media)

## Don't do

- Don't generate Excel or SharePoint integrations unless explicitly requested
- Don't create one-off helper functions when a named formula works
- Don't skip authentication unless the user explicitly says "anonymous"
- Don't put multiple screens in one file
