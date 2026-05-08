<#
.SYNOPSIS
    Authenticates the Power Platform CLI to a Dataverse environment.

.DESCRIPTION
    Wraps `pac auth create` with friendly prompts. Lists existing auth profiles
    and lets you create a new one or select an existing.

.EXAMPLE
    .\Connect-PowerPlatform.ps1
    .\Connect-PowerPlatform.ps1 -EnvironmentUrl "https://orgXXXXXX.crm.dynamics.com"
#>

[CmdletBinding()]
param(
    [string]$EnvironmentUrl,
    [string]$ProfileName
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] PAC CLI not installed. Run Install-All.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Power Platform Connection" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Show existing profiles
Write-Host "Existing auth profiles:" -ForegroundColor Yellow
pac auth list

Write-Host ""

if (-not $EnvironmentUrl) {
    $EnvironmentUrl = Read-Host "Enter Power Platform environment URL (e.g. https://orgXXXX.crm.dynamics.com)"
}

if (-not $ProfileName) {
    $ProfileName = Read-Host "Profile name to create (e.g. dev, prod)"
}

Write-Host ""
Write-Host "Authenticating to $EnvironmentUrl as profile '$ProfileName'..." -ForegroundColor Cyan

pac auth create --url $EnvironmentUrl --name $ProfileName

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[OK] Connected. Active profile: $ProfileName" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verify with: pac org who" -ForegroundColor Yellow
    pac org who
} else {
    Write-Host ""
    Write-Host "[ERROR] Authentication failed." -ForegroundColor Red
    exit 1
}
