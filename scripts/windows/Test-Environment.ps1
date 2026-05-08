<#
.SYNOPSIS
    Validates that all required toolkit dependencies are installed and accessible.

.DESCRIPTION
    Prints a clear PASS/FAIL report for each dependency. Exits non-zero if any check fails.

.EXAMPLE
    .\Test-Environment.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

function Test-Tool {
    param(
        [string]$Name,
        [string]$Command,
        [string]$MinVersion = $null
    )

    try {
        $output = Invoke-Expression $Command 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -ne 0 -and $output -match 'not recognized') {
            Write-Host ("[FAIL] {0,-20} not installed" -f $Name) -ForegroundColor Red
            return $false
        }
        Write-Host ("[PASS] {0,-20} {1}" -f $Name, $output) -ForegroundColor Green
        return $true
    } catch {
        Write-Host ("[FAIL] {0,-20} {1}" -f $Name, $_.Exception.Message) -ForegroundColor Red
        return $false
    }
}

Write-Host ""
Write-Host "Environment Validation Report" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$results = @(
    (Test-Tool -Name 'Git'              -Command 'git --version'),
    (Test-Tool -Name 'Node.js'          -Command 'node --version'),
    (Test-Tool -Name 'npm'              -Command 'npm --version'),
    (Test-Tool -Name '.NET SDK'         -Command 'dotnet --version'),
    (Test-Tool -Name 'PAC CLI'          -Command 'pac --version'),
    (Test-Tool -Name 'Azure CLI'        -Command 'az --version'),
    (Test-Tool -Name 'VS Code'          -Command 'code --version'),
    (Test-Tool -Name 'Docker'           -Command 'docker --version')
)

Write-Host ""
$passed = ($results | Where-Object { $_ }).Count
$total  = $results.Count

if ($passed -eq $total) {
    Write-Host "All $total checks passed." -ForegroundColor Green
    exit 0
} else {
    $failed = $total - $passed
    Write-Host "$passed/$total checks passed ($failed failed)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To fix: re-run .\Install-All.ps1 as Administrator" -ForegroundColor Yellow
    exit 1
}
