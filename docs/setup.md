# Setup Guide

Detailed installation instructions. For the quick-start path, see [Onboarding](onboarding.md).

---

## Recommended — One-click installer

The toolkit ships an idempotent installer that pre-checks each tool and only installs what's missing:

```powershell
# Default install (Git + Node.js LTS + .NET 10 SDK + PAC CLI + VS Code)
.\scripts\windows\Install-All.ps1

# Re-run on a configured machine: prints SKIP for each tool, no-op
.\scripts\windows\Install-All.ps1

# Force upgrade everything
.\scripts\windows\Install-All.ps1 -Update

# Also install Azure CLI (only needed for Phase 3 deploy scripts)
.\scripts\windows\Install-All.ps1 -IncludeAzure
```

The installer uses `Get-Command` to check whether each tool is on PATH before invoking winget. Existing tools print `[SKIP]` with the version; missing tools print `[INSTALL]`.

---

## Manual Installation (if Install-All.ps1 fails)

### 1. Git (required)
```powershell
winget install --id Git.Git -e
```
Verify: `git --version`

### 2. Node.js LTS (required — for Dataverse MCP via npx)
```powershell
winget install --id OpenJS.NodeJS.LTS -e
```
Verify: `node --version` and `npm --version`

### 3. .NET 10 SDK (required — for canvas-authoring MCP and .NET API templates)
```powershell
winget install --id Microsoft.DotNet.SDK.10 -e
```
Verify: `dotnet --version`

### 4. Power Platform CLI (required)
```powershell
winget install --id Microsoft.PowerPlatformCLI -e
```
Or via dotnet tool:
```powershell
dotnet tool install --global Microsoft.PowerApps.CLI.Tool
```
Verify: `pac --version`

### 5. Visual Studio Code (required)
```powershell
winget install --id Microsoft.VisualStudioCode -e
```
After install, install extensions:
```powershell
code --install-extension anthropic.claude-code
code --install-extension ms-dotnettools.csharp
code --install-extension ms-azuretools.vscode-azurefunctions
code --install-extension redhat.vscode-yaml
```

### 6. Azure CLI (optional — only for Phase 3 deploy scripts)

Skip this for now unless you're working on Container Apps / App Service / ACR deployments.

```powershell
winget install --id Microsoft.AzureCLI -e
```
Verify: `az --version`

---

## Power Platform Setup

### Connect PAC CLI

```powershell
pac auth create --url https://orgXXXXX.crm.dynamics.com --name dev
```

Verify:
```powershell
pac auth list
pac org who
```

### Switch environments

```powershell
pac auth list                # Lists all profiles
pac auth select --index 0    # Activate profile 0
```

---

## Claude Code Setup

1. Open VS Code
2. Open the Claude Code panel (left sidebar icon)
3. Sign in with your Anthropic account
4. Confirm the project loads `CLAUDE.md` (you'll see "Loaded CLAUDE.md" in the welcome message)

### Configure the canvas-authoring MCP server

Required for editing Canvas Apps via Claude Code:

```powershell
# In Claude Code, type:
/configure-canvas-mcp
```

Provide your Power Apps Studio URL when prompted.

---

## GitHub Setup

### SSH key (recommended)

```powershell
ssh-keygen -t ed25519 -C "your.email@stlogs.com"
# Add the public key (~/.ssh/id_ed25519.pub) to GitHub: Settings → SSH and GPG keys
```

### Sign your commits (recommended)

```powershell
gpg --full-generate-key
# Use ed25519, no expiration

git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true
```

Add the public GPG key to GitHub: Settings → SSH and GPG keys → New GPG key.

---

## Local Configuration

Create `.claude/settings.local.json` for personal overrides (not committed):

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(git *)",
      "Bash(pac *)",
      "Bash(dotnet *)",
      "PowerShell(*)"
    ]
  }
}
```

---

## Validation

```powershell
.\scripts\windows\Test-Environment.ps1
```

Required checks (Git, Node.js, npm, .NET SDK, PAC CLI, VS Code) must `[PASS]`.
Azure CLI shows `[SKIP]` if not installed — that's expected unless you've opted in with `-IncludeAzure`. To require it:

```powershell
.\scripts\windows\Test-Environment.ps1 -IncludeAzure
```

If any required check fails, see [Troubleshooting](troubleshooting.md).
