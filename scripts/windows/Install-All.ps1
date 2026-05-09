<#
.SYNOPSIS
    One-click installer for the Enterprise Power Platform Developer Toolkit.

.DESCRIPTION
    Idempotent installer - checks each dependency first, skips what's already
    installed, only fetches what's missing. Re-running on a configured machine
    is fast and obviously a no-op.

    Default install set:
      - Git
      - Node.js LTS
      - .NET 10 SDK
      - Power Platform CLI (PAC)
      - VS Code + recommended extensions
      - Claude Code CLI               (npm install -g @anthropic-ai/claude-code)
      - canvas-apps@power-platform-skills plugin
        (provides /configure-canvas-mcp, /generate-canvas-app, etc.)

    Optional (opt-in):
      - Azure CLI                     (-IncludeAzure)

.PARAMETER Update
    Force re-install / upgrade tools that are already present.

.PARAMETER IncludeAzure
    Also install Azure CLI. Only needed for Phase 3 deploy scripts
    (az containerapp, az acr, etc.).

.PARAMETER SkipVSCode
    Skip Visual Studio Code installation.

.PARAMETER SkipWizard
    Skip launching Start-Toolkit.ps1 at the end.

.NOTES
    Requires Administrator privileges.
    Uses winget for native packages, npm for Claude Code, and
    `claude plugin` commands for the canvas-apps marketplace plugin.

.EXAMPLE
    .\Install-All.ps1
    .\Install-All.ps1 -Update
    .\Install-All.ps1 -IncludeAzure
    .\Install-All.ps1 -SkipVSCode -SkipWizard
#>

[CmdletBinding()]
param(
    [switch]$Update,
    [switch]$IncludeAzure,
    [switch]$SkipVSCode,
    [switch]$SkipWizard
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --- Helpers --------------------------------------------------------------

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Skip    { param([string]$m) Write-Host "    [SKIP]    $m" -ForegroundColor DarkGray }
function Write-Install { param([string]$m) Write-Host "    [INSTALL] $m" -ForegroundColor Yellow }
function Write-Update  { param([string]$m) Write-Host "    [UPDATE]  $m" -ForegroundColor Magenta }
function Write-Success { param([string]$m) Write-Host "    [OK]      $m" -ForegroundColor Green }
function Write-Err     { param([string]$m) Write-Host "    [ERROR]   $m" -ForegroundColor Red }

function Test-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-CommandVersion {
    param(
        [string]$Name,
        [string]$VersionArg = '--version'
    )
    try {
        $output = & $Name $VersionArg 2>&1 | Select-Object -First 1
        return ($output -as [string])
    } catch {
        return $null
    }
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

function Ensure-WingetPackage {
    param(
        [Parameter(Mandatory)] [string]$Id,
        [Parameter(Mandatory)] [string]$DisplayName,
        [Parameter(Mandatory)] [string]$TestCommand,
        [string]$VersionArg = '--version'
    )

    Write-Step $DisplayName

    $isInstalled = Test-Command $TestCommand

    if ($isInstalled -and -not $Update) {
        $version = Get-CommandVersion -Name $TestCommand -VersionArg $VersionArg
        Write-Skip "$DisplayName already installed$(if ($version) { " ($version)" })"
        return
    }

    if ($isInstalled -and $Update) {
        Write-Update "Upgrading $DisplayName..."
        try {
            winget upgrade --id $Id --accept-source-agreements --accept-package-agreements --silent --exact 2>&1 | Out-Null
            Write-Success "$DisplayName upgraded"
        } catch {
            Write-Err "Upgrade failed for $DisplayName : $_"
        }
        return
    }

    Write-Install "Installing $DisplayName..."
    try {
        winget install --id $Id --accept-source-agreements --accept-package-agreements --silent --exact 2>&1 | Out-Null
        Write-Success "$DisplayName installed"
    } catch {
        Write-Err "Install failed for $DisplayName : $_"
    }
}

function Ensure-NpmGlobalPackage {
    param(
        [Parameter(Mandatory)] [string]$PackageName,
        [Parameter(Mandatory)] [string]$DisplayName,
        [Parameter(Mandatory)] [string]$TestCommand,
        [string]$VersionArg = '--version'
    )

    Write-Step $DisplayName

    if (-not (Test-Command 'npm')) {
        Write-Err "npm not found - install Node.js LTS first"
        return
    }

    $isInstalled = Test-Command $TestCommand

    if ($isInstalled -and -not $Update) {
        $version = Get-CommandVersion -Name $TestCommand -VersionArg $VersionArg
        Write-Skip "$DisplayName already installed$(if ($version) { " ($version)" })"
        return
    }

    if ($isInstalled -and $Update) {
        Write-Update "Upgrading $DisplayName via npm..."
        $output = npm install -g $PackageName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Err "Upgrade failed (exit $LASTEXITCODE): $output"
        } else {
            Write-Success "$DisplayName upgraded"
        }
        return
    }

    Write-Install "Installing $DisplayName via npm..."
    $output = npm install -g $PackageName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Install failed (exit $LASTEXITCODE): $output"
    } else {
        Write-Success "$DisplayName installed"
    }
}

function Ensure-ClaudePlugin {
    <#
        Idempotent install of a Claude Code marketplace plugin.

        Steps:
          1. Add the marketplace if not already added
          2. Install the plugin if not already installed
    #>
    param(
        [Parameter(Mandatory)] [string]$Marketplace,   # e.g. microsoft/power-platform-skills
        [Parameter(Mandatory)] [string]$PluginRef,     # e.g. canvas-apps@power-platform-skills
        [Parameter(Mandatory)] [string]$DisplayName    # human-readable
    )

    Write-Step $DisplayName

    if (-not (Test-Command 'claude')) {
        Write-Err "Claude Code CLI not found - install it first"
        return
    }

    # Check if plugin is already installed
    try {
        $pluginList = & claude plugin list 2>&1 | Out-String
    } catch {
        $pluginList = ''
    }

    $pluginShort = ($PluginRef -split '@')[0]
    $isInstalled = ($pluginList -match [regex]::Escape($pluginShort))

    if ($isInstalled -and -not $Update) {
        Write-Skip "$DisplayName already installed"
        return
    }

    # Add marketplace (idempotent - re-adding is safe)
    Write-Install "Adding marketplace $Marketplace..."
    try {
        & claude plugin marketplace add $Marketplace 2>&1 | Out-Null
    } catch {
        # If already added, this errors silently - that's fine
    }

    # Install the plugin
    Write-Install "Installing plugin $PluginRef..."
    try {
        & claude plugin install $PluginRef 2>&1 | Out-Null
        Write-Success "$DisplayName installed"
    } catch {
        Write-Err "Plugin install failed: $_"
    }
}

# --- Pre-flight checks ----------------------------------------------------

if (-not (Test-Admin)) {
    Write-Err "This script must run as Administrator."
    Write-Host "Right-click PowerShell -> 'Run as Administrator', then re-run this script."
    exit 1
}

if (-not (Test-Command 'winget')) {
    Write-Err "winget not found. Install 'App Installer' from the Microsoft Store and retry."
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host " Enterprise Power Platform Developer Toolkit - Installer" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
if ($Update)       { Write-Host " Mode: UPDATE - will upgrade installed tools" -ForegroundColor Yellow }
if ($IncludeAzure) { Write-Host " Including: Azure CLI" -ForegroundColor Yellow }

# --- Stage 1: Native packages via winget ---------------------------------

Ensure-WingetPackage -Id 'Git.Git'                    -DisplayName 'Git'                -TestCommand 'git'
Ensure-WingetPackage -Id 'OpenJS.NodeJS.LTS'          -DisplayName 'Node.js LTS'        -TestCommand 'node'
Ensure-WingetPackage -Id 'Microsoft.DotNet.SDK.10'    -DisplayName '.NET 10 SDK'        -TestCommand 'dotnet'
Ensure-WingetPackage -Id 'Microsoft.PowerPlatformCLI' -DisplayName 'Power Platform CLI' -TestCommand 'pac'

if (-not $SkipVSCode) {
    Ensure-WingetPackage -Id 'Microsoft.VisualStudioCode' -DisplayName 'Visual Studio Code' -TestCommand 'code'
}

if ($IncludeAzure) {
    Ensure-WingetPackage -Id 'Microsoft.AzureCLI' -DisplayName 'Azure CLI' -TestCommand 'az'
}

# --- Refresh PATH so npm + claude are findable ---------------------------

Refresh-Path

# --- Stage 2: Node-based tools (depends on Stage 1 Node.js) --------------

Ensure-NpmGlobalPackage `
    -PackageName '@anthropic-ai/claude-code' `
    -DisplayName 'Claude Code CLI' `
    -TestCommand 'claude'

Refresh-Path

# --- Stage 3: Claude Code plugins (depends on Stage 2 claude CLI) --------

Ensure-ClaudePlugin `
    -Marketplace 'microsoft/power-platform-skills' `
    -PluginRef   'canvas-apps@power-platform-skills' `
    -DisplayName 'canvas-apps plugin (Microsoft)'

# --- Stage 4: VS Code extensions (idempotent - re-running is safe) -------

if (-not $SkipVSCode -and (Test-Command 'code')) {
    Write-Step "VS Code extensions"
    $extensions = @(
        'anthropic.claude-code',
        'ms-dotnettools.csharp',
        'ms-azuretools.vscode-azurefunctions',
        'github.vscode-pull-request-github',
        'redhat.vscode-yaml',
        'editorconfig.editorconfig'
    )

    $installedExts = @(code --list-extensions 2>&1)

    foreach ($ext in $extensions) {
        if ($installedExts -contains $ext -and -not $Update) {
            Write-Skip $ext
        } else {
            code --install-extension $ext --force 2>&1 | Out-Null
            Write-Success $ext
        }
    }
}

# --- Final Validation -----------------------------------------------------

Write-Step "Validating installation"

$checks = @(
    @{ Name = 'git';          Cmd = 'git --version'                       },
    @{ Name = 'node';         Cmd = 'node --version'                      },
    @{ Name = 'npm';          Cmd = 'npm --version'                       },
    @{ Name = 'dotnet';       Cmd = 'dotnet --version'                    },
    @{ Name = 'pac';          Cmd = 'pac --version'                       },
    @{ Name = 'claude';       Cmd = 'claude --version'                    }
)

if ($IncludeAzure) {
    $checks += @{ Name = 'az'; Cmd = 'az --version' }
}

$failures = 0
foreach ($check in $checks) {
    try {
        $output = Invoke-Expression $check.Cmd 2>&1 | Select-Object -First 1
        Write-Success ("{0,-10} {1}" -f $check.Name, $output)
    } catch {
        Write-Err "$($check.Name) not found in PATH"
        $failures++
    }
}

# Plugin verification (best effort)
try {
    $plugins = & claude plugin list 2>&1 | Out-String
    if ($plugins -match 'canvas-apps') {
        Write-Success "canvas-apps plugin registered"
    } else {
        Write-Err "canvas-apps plugin not detected in 'claude plugin list'"
        $failures++
    }
} catch {
    Write-Err "Could not verify Claude plugins"
    $failures++
}

Write-Host ""
if ($failures -eq 0) {
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host " All tools ready!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
} else {
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host " $failures issue(s)." -ForegroundColor Yellow
    Write-Host " Restart your terminal and re-run Test-Environment.ps1" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
}

# --- Launch the wizard -----------------------------------------------------

if ($SkipWizard -or $failures -gt 0) {
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Restart your terminal (so PATH updates apply)"
    Write-Host "  2. Run: .\scripts\windows\Connect-PowerPlatform.ps1"
    Write-Host "  3. Run: .\scripts\windows\Start-Toolkit.ps1"
    Write-Host "  4. Open VS Code in this folder: code ."
    return
}

Write-Host ""
Write-Host "Launching Start-Toolkit wizard..." -ForegroundColor Cyan
Write-Host ""

$wizard = Join-Path $PSScriptRoot 'Start-Toolkit.ps1'
if (Test-Path $wizard) {
    & $wizard
} else {
    Write-Host "[WARN] Start-Toolkit.ps1 not found at $wizard" -ForegroundColor Yellow
    Write-Host "Run it later with: .\scripts\windows\Start-Toolkit.ps1"
}
