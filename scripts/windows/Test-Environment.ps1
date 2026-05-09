<#
.SYNOPSIS
    Validates that all required toolkit dependencies are installed and accessible.

.DESCRIPTION
    Prints a clear PASS/FAIL/SKIP report for each dependency.
    Exits non-zero only if a REQUIRED dependency fails.
    Optional tools (Azure CLI) report SKIP if missing without failing the run.

.PARAMETER IncludeAzure
    Treat Azure CLI as a required dependency. By default it's optional and
    reports SKIP if missing.

.EXAMPLE
    .\Test-Environment.ps1
    .\Test-Environment.ps1 -IncludeAzure
#>

[CmdletBinding()]
param(
    [switch]$IncludeAzure
)

$ErrorActionPreference = 'Continue'

function Test-Tool {
    param(
        [string]$Name,
        [string]$Command,
        [switch]$Optional
    )

    try {
        $output = Invoke-Expression $Command 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -ne 0 -and $output -match 'not recognized') {
            if ($Optional) {
                Write-Host ("[SKIP] {0,-20} not installed (optional)" -f $Name) -ForegroundColor DarkGray
                return @{ Result = 'skip' }
            }
            Write-Host ("[FAIL] {0,-20} not installed" -f $Name) -ForegroundColor Red
            return @{ Result = 'fail' }
        }
        Write-Host ("[PASS] {0,-20} {1}" -f $Name, $output) -ForegroundColor Green
        return @{ Result = 'pass' }
    } catch {
        if ($Optional) {
            Write-Host ("[SKIP] {0,-20} not installed (optional)" -f $Name) -ForegroundColor DarkGray
            return @{ Result = 'skip' }
        }
        Write-Host ("[FAIL] {0,-20} {1}" -f $Name, $_.Exception.Message) -ForegroundColor Red
        return @{ Result = 'fail' }
    }
}

Write-Host ""
Write-Host "Environment Validation Report" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$results = @()
$results += (Test-Tool -Name 'Git'      -Command 'git --version')
$results += (Test-Tool -Name 'Node.js'  -Command 'node --version')
$results += (Test-Tool -Name 'npm'      -Command 'npm --version')
$results += (Test-Tool -Name '.NET SDK' -Command 'dotnet --version')
$results += (Test-Tool -Name 'PAC CLI'  -Command 'pac --version')
$results += (Test-Tool -Name 'VS Code'  -Command 'code --version')

if ($IncludeAzure) {
    $results += (Test-Tool -Name 'Azure CLI' -Command 'az --version')
} else {
    $results += (Test-Tool -Name 'Azure CLI' -Command 'az --version' -Optional)
}

Write-Host ""
$passed = ($results | Where-Object { $_.Result -eq 'pass' }).Count
$failed = ($results | Where-Object { $_.Result -eq 'fail' }).Count
$skipped = ($results | Where-Object { $_.Result -eq 'skip' }).Count
$total  = $results.Count

if ($failed -eq 0) {
    if ($skipped -gt 0) {
        Write-Host "$passed/$total checks passed ($skipped optional skipped)." -ForegroundColor Green
    } else {
        Write-Host "All $total checks passed." -ForegroundColor Green
    }
    exit 0
} else {
    Write-Host "$passed/$total checks passed ($failed failed, $skipped skipped)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To fix: re-run .\Install-All.ps1 as Administrator" -ForegroundColor Yellow
    exit 1
}
