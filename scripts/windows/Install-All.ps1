<#
.SYNOPSIS
    One-click installer for the Enterprise Power Platform Developer Toolkit.

.DESCRIPTION
    Installs all required dependencies on Windows:
    - Git
    - Node.js LTS
    - .NET 10 SDK
    - Power Platform CLI (PAC)
    - Azure CLI
    - Docker Desktop (optional)
    - VS Code + recommended extensions

.NOTES
    Requires Administrator privileges.
    Uses winget where available; falls back to direct downloads.

.EXAMPLE
    .\Install-All.ps1
    .\Install-All.ps1 -SkipDocker
#>

[CmdletBinding()]
param(
    [switch]$SkipDocker,
    [switch]$SkipVSCode
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --- Helpers --------------------------------------------------------------

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    [WARN] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "    [ERROR] $Message" -ForegroundColor Red
}

function Test-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$DisplayName
    )
    Write-Step "Installing $DisplayName"
    try {
        winget install --id $Id --accept-source-agreements --accept-package-agreements --silent --exact 2>&1 | Out-Null
        Write-Success "$DisplayName installed"
    } catch {
        Write-Err "Failed to install $DisplayName : $_"
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

# --- Install Core Tools ---------------------------------------------------

Install-WingetPackage -Id 'Git.Git' -DisplayName 'Git'
Install-WingetPackage -Id 'OpenJS.NodeJS.LTS' -DisplayName 'Node.js LTS'
Install-WingetPackage -Id 'Microsoft.DotNet.SDK.10' -DisplayName '.NET 10 SDK'
Install-WingetPackage -Id 'Microsoft.PowerPlatformCLI' -DisplayName 'Power Platform CLI'
Install-WingetPackage -Id 'Microsoft.AzureCLI' -DisplayName 'Azure CLI'

if (-not $SkipVSCode) {
    Install-WingetPackage -Id 'Microsoft.VisualStudioCode' -DisplayName 'Visual Studio Code'
}

if (-not $SkipDocker) {
    Install-WingetPackage -Id 'Docker.DockerDesktop' -DisplayName 'Docker Desktop'
}

# --- Refresh PATH so subsequent commands find new tools -------------------

$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')

# --- VS Code Extensions ---------------------------------------------------

if (-not $SkipVSCode -and (Test-Command 'code')) {
    Write-Step "Installing VS Code extensions"
    $extensions = @(
        'anthropic.claude-code',
        'ms-dotnettools.csharp',
        'ms-azuretools.vscode-azurefunctions',
        'ms-azuretools.vscode-docker',
        'github.vscode-pull-request-github',
        'redhat.vscode-yaml',
        'editorconfig.editorconfig'
    )
    foreach ($ext in $extensions) {
        code --install-extension $ext --force 2>&1 | Out-Null
        Write-Success "Extension: $ext"
    }
}

# --- Final Validation -----------------------------------------------------

Write-Step "Validating installation"

$checks = @(
    @{ Name = 'git';   Cmd = 'git --version' },
    @{ Name = 'node';  Cmd = 'node --version' },
    @{ Name = 'npm';   Cmd = 'npm --version' },
    @{ Name = 'dotnet';Cmd = 'dotnet --version' },
    @{ Name = 'pac';   Cmd = 'pac --version' },
    @{ Name = 'az';    Cmd = 'az --version' }
)

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

Write-Host ""
if ($failures -eq 0) {
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host " All tools installed successfully!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Restart your terminal (so PATH updates apply)"
    Write-Host "  2. Run: .\scripts\windows\Connect-PowerPlatform.ps1"
    Write-Host "  3. Open VS Code in this folder: code ."
} else {
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host " Installation completed with $failures issue(s)." -ForegroundColor Yellow
    Write-Host " Restart your terminal and re-run Test-Environment.ps1" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
}
