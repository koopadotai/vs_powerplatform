# Onboarding Guide

Welcome. This guide gets you from a fresh laptop to building Power Apps + .NET solutions with Claude AI in under an hour.

---

## Day 1 — 60 minutes

### 1. Prerequisites (10 min)
- Windows 10/11
- Admin access on the machine
- A Microsoft 365 / Power Platform account
- A GitHub account with access to this repo

### 2. Install everything (20 min)

```powershell
# Open PowerShell as Administrator
git clone https://github.com/koopadotai/vs_powerapp.git
cd vs_powerapp
.\scripts\windows\Install-All.ps1
```

The installer takes ~15 minutes. Grab coffee.

### 3. Validate (2 min)

```powershell
.\scripts\windows\Test-Environment.ps1
```

Expect 8 PASSes. If any fail, see [Troubleshooting](troubleshooting.md).

### 4. Connect to Power Platform (5 min)

```powershell
.\scripts\windows\Connect-PowerPlatform.ps1
```

Provide your environment URL (ask a teammate if unknown). Sign in via the browser popup.

### 5. Open VS Code (2 min)

```powershell
code .
```

When prompted, install recommended extensions (already pre-selected).

### 6. Sign in to Claude Code (5 min)

In VS Code, open the Claude Code panel (left sidebar). Sign in with your Anthropic credentials.

### 7. Read the orientation files (15 min)

In order:
- `README.md` — what this toolkit is
- `CLAUDE.md` — how Claude AI works in this repo
- `memory/powerapps-naming.md` — naming conventions
- `standards/architecture-principles.md` — non-negotiable rules

### 8. Build your first thing (10 min)

In Claude Code, type:

```
/build-canvas-app "Hello world phone app with a button that shows the current time"
```

Claude will scaffold a complete Canvas App following the toolkit standards. Review what was created — that's how everything works in this repo.

---

## Day 2-5 — Build something real

Pick a project from `examples/` or start a new one:

```
/new-project canvas-app "Vehicle inspection app for our drivers"
```

Lean on:
- Memory files in `memory/` for standards
- Templates in `templates/` for starting points
- The `asset-management` example as a reference implementation

---

## Where to ask for help

| Question | Where |
|---|---|
| "How do I do X?" | Ask Claude Code first — it has all the standards loaded |
| Tooling broken | `docs/troubleshooting.md` |
| Power Platform issue | `#powerplatform` Slack channel |
| Standards interpretation | `#architects` Slack channel |
| Bug in this toolkit | Open an issue on GitHub |

---

## What's expected of you

| When | Expectation |
|---|---|
| First week | Read all `memory/` files; build a sandbox app |
| First month | Contribute one improvement (template, doc, fix) back to the toolkit |
| Ongoing | Follow standards; flag deviations in PR descriptions |

---

## Useful commands

```powershell
# Validate any project
.\automation\Test-AppStandards.ps1 -Path examples\asset-management\

# Pull latest from a Power Platform environment
pac canvas download --name "App Name" --extract-to .\

# List your auth profiles
pac auth list

# Switch active environment
pac auth select --index <n>
```
