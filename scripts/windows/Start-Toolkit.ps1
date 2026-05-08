<#
.SYNOPSIS
    Post-install wizard for the Enterprise Power Platform Developer Toolkit.

.DESCRIPTION
    Guides the user through their first project. Suggests a Calculator POC
    as the recommended first build. Auto-launches at the end of Install-All.ps1
    or can be invoked directly.

.EXAMPLE
    .\Start-Toolkit.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Resolve repo root
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path (Join-Path $RepoRoot 'CLAUDE.md'))) {
    Write-Host "[ERROR] Could not find toolkit root (CLAUDE.md not found in $RepoRoot)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host " Welcome to the Enterprise Power Platform Developer Toolkit" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "What would you like to build today?"
Write-Host ""
Write-Host "  [1] " -NoNewline -ForegroundColor Cyan
Write-Host "Calculator POC " -NoNewline -ForegroundColor White
Write-Host "(recommended for first time)" -ForegroundColor Yellow
Write-Host "      Simple Power Apps Canvas calculator. No data, no schema."
Write-Host "      2 screens (calculator + copyright). Perfect for trying"
Write-Host "      the PAC CLI -> MCP build pipeline end-to-end."
Write-Host ""
Write-Host "  [2] " -NoNewline -ForegroundColor Cyan
Write-Host "Custom project" -ForegroundColor White
Write-Host "      Pick a template: canvas-app | dotnet-api | dataverse-schema"
Write-Host ""
Write-Host "  [3] " -NoNewline -ForegroundColor Cyan
Write-Host "Skip" -ForegroundColor White
Write-Host "      I'll start manually later"
Write-Host ""

$choice = Read-Host "Choose (1/2/3)"

switch ($choice) {
    '1' {
        Write-Host ""
        Write-Host "Building Calculator POC..." -ForegroundColor Cyan

        $calcPath = Join-Path $RepoRoot 'examples\calculator-poc'
        if (-not (Test-Path $calcPath)) {
            Write-Host "[ERROR] Calculator POC source not found at $calcPath" -ForegroundColor Red
            Write-Host "Make sure you're running this from a fresh toolkit clone." -ForegroundColor Yellow
            exit 1
        }

        Write-Host ""
        Write-Host "Calculator POC source: $calcPath\canvas\"
        Write-Host "Files:"
        Write-Host "    App.pa.yaml"
        Write-Host "    MainScreen.pa.yaml"
        Write-Host "    CopyrightScreen.pa.yaml"
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host " Calculator POC source ready!" -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Deploy via canvas-authoring MCP (recommended):" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  1. Open https://make.powerapps.com"
        Write-Host "  2. Create a new Canvas App (phone) named 'Calculator POC'"
        Write-Host "  3. Settings -> Updates -> Coauthoring (toggle ON)"
        Write-Host "  4. Copy the Studio URL from your browser"
        Write-Host "  5. In Claude Code: /configure-canvas-mcp"
        Write-Host "     (paste the Studio URL when prompted)"
        Write-Host "  6. Ask Claude: 'compile examples/calculator-poc/canvas to Studio'"
        Write-Host ""
        Write-Host "Note: PAC CLI 'canvas pack' only works on YAML round-tripped from a"
        Write-Host "real .msapp. For hand-authored YAML, use the MCP path above." -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Full instructions: examples\calculator-poc\README.md" -ForegroundColor Cyan
    }

    '2' {
        Write-Host ""
        Write-Host "Custom project" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Available types:"
        Write-Host "  canvas-app       - Phone-form-factor Power Apps Canvas"
        Write-Host "  dotnet-api       - ASP.NET Core 10 Minimal API"
        Write-Host "  dataverse-schema - Dataverse table schema YAML"
        Write-Host ""
        $type = Read-Host "Type"
        $name = Read-Host "Name (PascalCase)"

        if ($type -and $name) {
            $newProj = Join-Path $RepoRoot 'automation\New-Project.ps1'
            & $newProj -Type $type -Name $name
        } else {
            Write-Host "Cancelled." -ForegroundColor Yellow
        }
    }

    '3' {
        Write-Host ""
        Write-Host "Skipped. To start later, run:" -ForegroundColor Yellow
        Write-Host "  .\scripts\windows\Start-Toolkit.ps1"
        Write-Host "Or pick a template directly:" -ForegroundColor Yellow
        Write-Host "  .\automation\New-Project.ps1 -Type canvas-app -Name MyApp"
    }

    default {
        Write-Host ""
        Write-Host "Invalid choice. Run Start-Toolkit.ps1 again to retry." -ForegroundColor Red
    }
}

Write-Host ""
