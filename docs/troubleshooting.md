# Troubleshooting

Common issues and fixes.

---

## Installation

### `winget` is not recognized

**Cause:** App Installer not installed.
**Fix:** Install "App Installer" from the Microsoft Store, then restart PowerShell.

### `pac` is not recognized after install

**Cause:** PATH wasn't refreshed.
**Fix:**
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')
```
Or close and reopen PowerShell.

### .NET 10 install fails

**Cause:** Older Visual Studio installer holding the lock.
**Fix:** Close all VS instances, reboot, retry. As a fallback:
```powershell
# Direct install
Invoke-WebRequest 'https://aka.ms/dotnet-install-script' -OutFile install.ps1
.\install.ps1 -Channel 10.0
```

---

## Power Platform / PAC CLI

### `pac auth create` opens the browser but never completes

**Cause:** Conditional Access policy blocking the device.
**Fix:** Sign in to Power Apps in a regular browser first; accept the device prompt; retry `pac auth create`.

### "Insufficient privileges" on import

**Cause:** Your account lacks System Customizer or System Administrator on the target environment.
**Fix:** Have an admin grant the role. For PROD imports, use a service principal.

### Canvas App changes not appearing in Studio

**Cause:** Compile didn't run, or coauthoring is off.
**Fix:**
1. Confirm coauthoring is ON in Studio: **Settings → Updates → Coauthoring**
2. Run **"Compile canvas app to Power Apps Studio"** in the VS Code terminal
3. Refresh Studio (browser reload)

If still not showing, run `/configure-canvas-mcp` to re-register the MCP server with a fresh URL.

### "Field 'X' is required" error on Patch

**Cause:** The Dataverse table has a required column not included in your `Patch` formula.
**Fix:** Add the column to the Patch:
```powerpps
Patch('Table', Defaults('Table'), {
    existing_field: value,
    missing_required_field: <calculated value>
})
```

For choice columns, use the option set syntax:
```powerapps
ws_status: 'Status (Table)'.Active
```

---

## .NET / Build

### `dotnet build` fails with "Cannot find project SDK 'Microsoft.NET.Sdk' version '10.0.x'"

**Cause:** .NET 10 SDK not installed or not on PATH.
**Fix:** `dotnet --list-sdks` — confirm 10.x is listed. If not, reinstall.

### Tests pass locally but fail in CI

**Cause:** Locale, timezone, or culture differences.
**Fix:** Set the test culture explicitly in `TestContext`:
```csharp
CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
```

### `dotnet ef` not found

**Cause:** Tool not installed.
**Fix:**
```powershell
dotnet tool install --global dotnet-ef
```

---

## Claude Code

### Claude doesn't see the standards

**Cause:** `CLAUDE.md` not loaded or not in the workspace root.
**Fix:** Open the workspace root folder in VS Code (not a subfolder). `CLAUDE.md` must be in the same folder VS Code opens.

### MCP server "canvas-authoring" not available

**Cause:** Either not configured, or `.NET 10 SDK` not installed.
**Fix:**
```powershell
dotnet --version    # Must be 10.0+
# In Claude Code:
/configure-canvas-mcp
```

### Slash commands don't appear

**Cause:** Skills aren't picked up because the workspace path is wrong, or skill files have malformed YAML frontmatter.
**Fix:**
1. Confirm workspace root contains `skills/`
2. Check each skill file has valid frontmatter (starts with `---`, ends with `---`, has `description:` and `allowed-tools:`)

---

## Git / GitHub

### "Permission denied (publickey)" when pushing

**Cause:** SSH key not added to GitHub or not loaded by SSH agent.
**Fix:**
```powershell
# Start the agent
Start-Service ssh-agent
ssh-add ~/.ssh/id_ed25519
# Test
ssh -T git@github.com
```

### Pre-commit hook fails

**Cause:** Linter or test failures.
**Fix:** Read the hook output. Fix the underlying issue. Re-stage and commit. Never use `--no-verify`.

---

## VS Code

### Recommended extensions don't install

**Cause:** Behind a corporate proxy.
**Fix:** Configure proxy in VS Code: **Settings → Application: Proxy → http://your-proxy:port**

---

## Still stuck?

1. Check [GitHub Issues](https://github.com/koopadotai/vs_powerapp/issues)
2. Ask in `#powerplatform` Slack
3. Open a new issue with:
   - What you tried
   - What you expected
   - What happened (logs, screenshots)
   - Environment info (`pac --version`, `dotnet --version`, OS)
