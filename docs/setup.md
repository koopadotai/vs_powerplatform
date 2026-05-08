# Setup Guide

Detailed installation instructions. For the quick-start path, see [Onboarding](onboarding.md).

---

## Manual Installation (if Install-All.ps1 fails)

### 1. Git
```powershell
winget install --id Git.Git -e
```
Verify: `git --version`

### 2. Node.js LTS
```powershell
winget install --id OpenJS.NodeJS.LTS -e
```
Verify: `node --version` and `npm --version`

### 3. .NET 10 SDK
```powershell
winget install --id Microsoft.DotNet.SDK.10 -e
```
Verify: `dotnet --version`

### 4. Power Platform CLI
```powershell
winget install --id Microsoft.PowerPlatformCLI -e
```
Or via dotnet tool:
```powershell
dotnet tool install --global Microsoft.PowerApps.CLI.Tool
```
Verify: `pac --version`

### 5. Azure CLI
```powershell
winget install --id Microsoft.AzureCLI -e
```
Verify: `az --version`

### 6. Docker Desktop (optional)
```powershell
winget install --id Docker.DockerDesktop -e
```
After install: launch Docker Desktop, accept the license, sign in.

### 7. Visual Studio Code
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

All checks must pass. If any fail, see [Troubleshooting](troubleshooting.md).
