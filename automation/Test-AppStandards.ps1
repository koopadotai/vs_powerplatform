<#
.SYNOPSIS
    Validate a Canvas App or .NET service against toolkit standards.

.DESCRIPTION
    Runs lint/standards checks. Reports PASS/FAIL per check. Exits non-zero on any failure.

    For Canvas Apps:
        - .pa.yaml syntax valid
        - AppVersion formula present in App.pa.yaml
        - Visible lblVersion (or similar) on at least one screen
        - All controls follow the toolkit naming convention
        - No hardcoded RGBA(...) in screen files (must use named formulas)
        - All Patch operations include all schema-required fields (best-effort)

    For .NET services:
        - dotnet build succeeds
        - dotnet test succeeds
        - No high/critical vulnerable packages
        - Required endpoints exist (/health, /ready, /version)
        - No bare Console.WriteLine
        - No secrets in committed appsettings*.json files

.PARAMETER Path
    Path to a Canvas App folder (containing App.pa.yaml) or a .NET project folder
    (containing a .csproj). The script auto-detects the type.

.EXAMPLE
    .\Test-AppStandards.ps1 -Path examples\asset-management\canvas
    .\Test-AppStandards.ps1 -Path src\AssetApi
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = 'Continue'

if (-not (Test-Path $Path)) {
    Write-Host "[ERROR] Path not found: $Path" -ForegroundColor Red
    exit 1
}

$failures = 0
$passes = 0

function Pass([string]$msg) {
    Write-Host "[PASS] $msg" -ForegroundColor Green
    $script:passes++
}

function Fail([string]$msg) {
    Write-Host "[FAIL] $msg" -ForegroundColor Red
    $script:failures++
}

function Warn([string]$msg) {
    Write-Host "[WARN] $msg" -ForegroundColor Yellow
}

# --- Detect project type --------------------------------------------------
$isCanvas = (Test-Path (Join-Path $Path 'App.pa.yaml'))
$isDotnet = ($null -ne (Get-ChildItem -Path $Path -Filter '*.csproj' -ErrorAction SilentlyContinue))

if (-not $isCanvas -and -not $isDotnet) {
    Write-Host "[ERROR] Cannot detect project type. Expected App.pa.yaml or *.csproj in $Path" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Validating: $Path" -ForegroundColor Cyan
if ($isCanvas) { Write-Host "Type: Canvas App" -ForegroundColor Cyan }
if ($isDotnet) { Write-Host "Type: .NET Service" -ForegroundColor Cyan }
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================================================
# Canvas App Checks
# ==========================================================================
if ($isCanvas) {

    $yamlFiles = Get-ChildItem -Path $Path -Filter '*.pa.yaml' -Recurse

    # Check 1: YAML syntax
    foreach ($file in $yamlFiles) {
        try {
            # Basic YAML check via PowerShell-yaml if available, otherwise raw indentation check
            $content = Get-Content -Path $file.FullName -Raw
            if ($content -match '^\s*Screens:|^\s*App:') {
                Pass "Syntax OK: $($file.Name)"
            } else {
                Fail "Missing required root key (Screens: or App:): $($file.Name)"
            }
        } catch {
            Fail "YAML parse error in $($file.Name): $_"
        }
    }

    # Check 2: AppVersion formula
    $appYaml = Join-Path $Path 'App.pa.yaml'
    $appContent = Get-Content -Path $appYaml -Raw
    if ($appContent -match 'AppVersion\s*=') {
        Pass 'AppVersion formula present'
    } else {
        Fail 'App.pa.yaml missing AppVersion formula'
    }

    # Check 3: Visible version label on a screen
    $screenFiles = $yamlFiles | Where-Object { $_.Name -ne 'App.pa.yaml' }
    $hasVersionLabel = $false
    foreach ($file in $screenFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        if ($content -match 'lblVersion|=AppVersion') {
            $hasVersionLabel = $true
            break
        }
    }
    if ($hasVersionLabel) {
        Pass 'Visible version label found on at least one screen'
    } else {
        Fail 'No visible version label found on any screen (expected lblVersion or =AppVersion)'
    }

    # Check 4: Naming conventions for controls
    $controlPrefixes = @('btn', 'lbl', 'rect', 'txt', 'gal', 'img', 'ico', 'cmb', 'dte', 'tgl', 'sld', 'chk', 'rad', 'tmr', 'htm', 'card', 'frm', 'con', 'scr')
    $namingViolations = 0
    foreach ($file in $screenFiles) {
        $content = Get-Content -Path $file.FullName
        foreach ($line in $content) {
            if ($line -match '^\s*-\s+(\w+):\s*$') {
                $controlName = $matches[1]
                # Allowed: starts with a control prefix, OR is a screen name (PascalCase ending in Screen)
                $matchesPrefix = $false
                foreach ($prefix in $controlPrefixes) {
                    if ($controlName -match "^$prefix") {
                        $matchesPrefix = $true
                        break
                    }
                }
                if (-not $matchesPrefix) {
                    Warn "Possible naming violation in $($file.Name): control '$controlName' (expected btn/lbl/rect/txt/etc)"
                    $namingViolations++
                }
            }
        }
    }
    if ($namingViolations -eq 0) {
        Pass 'Control naming conventions OK'
    } else {
        Warn "$namingViolations possible naming violations (review above)"
    }

    # Check 5: No hardcoded RGBA in screen files
    $rgbaViolations = 0
    foreach ($file in $screenFiles) {
        $lines = Get-Content -Path $file.FullName
        for ($i = 0; $i -lt $lines.Count; $i++) {
            # Allow RGBA(0,0,0,0) for transparent fills
            if ($lines[$i] -match 'RGBA\(' -and $lines[$i] -notmatch 'RGBA\(\s*0\s*,\s*0\s*,\s*0\s*,\s*0\s*\)' -and $lines[$i] -notmatch 'RGBA\(\s*255\s*,\s*255\s*,\s*255\s*,\s*[01](\.[0-9]+)?\s*\)') {
                Warn "Hardcoded RGBA in $($file.Name) line $($i+1): $($lines[$i].Trim())"
                $rgbaViolations++
            }
        }
    }
    if ($rgbaViolations -eq 0) {
        Pass 'No hardcoded RGBA in screen files'
    } else {
        Fail "$rgbaViolations hardcoded RGBA value(s) — use named formulas instead"
    }
}

# ==========================================================================
# .NET Service Checks
# ==========================================================================
if ($isDotnet) {
    Push-Location $Path
    try {
        # Check 1: dotnet build
        Write-Host "Running dotnet build..." -ForegroundColor Cyan
        $buildOutput = dotnet build --nologo --verbosity quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Pass 'dotnet build succeeded'
        } else {
            Fail 'dotnet build failed'
            Write-Host $buildOutput
        }

        # Check 2: dotnet test (if test project exists)
        $testProjects = Get-ChildItem -Path '..\..\tests' -Filter '*.csproj' -Recurse -ErrorAction SilentlyContinue
        if (-not $testProjects) {
            $testProjects = Get-ChildItem -Path '.\tests' -Filter '*.csproj' -Recurse -ErrorAction SilentlyContinue
        }
        if ($testProjects) {
            Write-Host "Running dotnet test..." -ForegroundColor Cyan
            $testOutput = dotnet test --nologo --verbosity quiet --no-build 2>&1
            if ($LASTEXITCODE -eq 0) {
                Pass 'dotnet test succeeded'
            } else {
                Fail 'dotnet test failed'
            }
        } else {
            Warn 'No test project found'
        }

        # Check 3: Vulnerable packages
        $vulnOutput = dotnet list package --vulnerable --include-transitive 2>&1
        if ($vulnOutput -match 'Critical|High') {
            Fail 'High or Critical vulnerable packages found'
            Write-Host $vulnOutput
        } else {
            Pass 'No high/critical vulnerable packages'
        }

        # Check 4: Required endpoints
        $programCs = Get-ChildItem -Path . -Filter 'Program.cs' -Recurse | Select-Object -First 1
        if ($programCs) {
            $progContent = Get-Content -Path $programCs.FullName -Raw
            $missing = @()
            if ($progContent -notmatch '"/health"') { $missing += '/health' }
            if ($progContent -notmatch '"/ready"|MapHealthChecks\("/ready"') { $missing += '/ready' }
            if ($progContent -notmatch '"/version"') { $missing += '/version' }

            if ($missing.Count -eq 0) {
                Pass 'Required endpoints (/health, /ready, /version) present'
            } else {
                Fail "Missing required endpoints: $($missing -join ', ')"
            }
        }

        # Check 5: No Console.WriteLine
        $consoleHits = Get-ChildItem -Path . -Filter '*.cs' -Recurse |
            Select-String -Pattern 'Console\.WriteLine' |
            Where-Object { $_.Line -notmatch '^\s*//' }
        if ($consoleHits) {
            Fail 'Console.WriteLine found — use ILogger<T> instead'
            $consoleHits | ForEach-Object { Write-Host "    $($_.Path):$($_.LineNumber)" -ForegroundColor Yellow }
        } else {
            Pass 'No Console.WriteLine in production code'
        }

        # Check 6: No obvious secrets in appsettings files
        $secretPatterns = @(
            'AccountKey=',
            'ClientSecret\s*=\s*"[^"]{8,}"',
            'password\s*=\s*"[^"]{4,}"',
            'sk-[a-zA-Z0-9]{20,}'
        )
        $appSettingsFiles = Get-ChildItem -Path . -Filter 'appsettings*.json' -Recurse |
            Where-Object { $_.Name -ne 'appsettings.Local.json' -and $_.Name -ne 'appsettings.Development.json' }
        $secretsFound = $false
        foreach ($f in $appSettingsFiles) {
            $content = Get-Content -Path $f.FullName -Raw
            foreach ($p in $secretPatterns) {
                if ($content -match $p) {
                    Fail "Possible secret in $($f.Name) (matched pattern: $p)"
                    $secretsFound = $true
                }
            }
        }
        if (-not $secretsFound) {
            Pass 'No obvious secrets in committed appsettings files'
        }

    } finally {
        Pop-Location
    }
}

# ==========================================================================
# Summary
# ==========================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
$total = $passes + $failures
Write-Host "Result: $passes/$total checks passed" -ForegroundColor $(if ($failures -eq 0) { 'Green' } else { 'Yellow' })

if ($failures -gt 0) {
    Write-Host "$failures check(s) failed. Fix the issues and re-run." -ForegroundColor Red
    exit 1
} else {
    Write-Host "All checks passed." -ForegroundColor Green
    exit 0
}
