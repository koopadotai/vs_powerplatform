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
Write-Host "Asset Management " -NoNewline -ForegroundColor White
Write-Host "(end-to-end reference)" -ForegroundColor Yellow
Write-Host "      Complete enterprise sample: Dataverse schema + Canvas App"
Write-Host "      packaged in ONE solution. Auto-personalized for your env"
Write-Host "      (your publisher, your prefix). 5 screens, 3 tables, choice"
Write-Host "      set, 4 relationships, alternate key."
Write-Host ""
Write-Host "  [3] " -NoNewline -ForegroundColor Cyan
Write-Host "Custom project" -ForegroundColor White
Write-Host "      Pick a template: canvas-app | dotnet-api | dataverse-schema"
Write-Host ""
Write-Host "  [4] " -NoNewline -ForegroundColor Cyan
Write-Host "Skip" -ForegroundColor White
Write-Host "      I'll start manually later"
Write-Host ""

$choice = Read-Host "Choose (1/2/3/4)"

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
        Write-Host "Asset Management - end-to-end deployment" -ForegroundColor Cyan
        Write-Host ""
        $amPath = Join-Path $RepoRoot 'examples\asset-management'
        if (-not (Test-Path $amPath)) {
            Write-Host "[ERROR] Asset Management source not found at $amPath" -ForegroundColor Red
            exit 1
        }

        Write-Host "Source: $amPath\"
        Write-Host "  - dataverse\AssetManagement.zip  (portable solution package)"
        Write-Host "  - canvas\*.pa.yaml                (5 Canvas App screens)"
        Write-Host "  - automation\Personalize-AssetManagement.ps1  (auto-personalizer)"
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host " Ready to deploy Asset Management to your environment!" -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  1. Authenticate to your Dataverse env (one-time):"
        Write-Host "     .\scripts\windows\Connect-PowerPlatform.ps1"
        Write-Host ""
        Write-Host "  2. Open Claude Code:"
        Write-Host "     claude code"
        Write-Host ""
        Write-Host "  3. In the Claude Code session, type:"
        Write-Host "     deploy asset-management"
        Write-Host ""
        Write-Host "The AI agent will then:"
        Write-Host "  - Ask for your publisher info + prefix (e.g. ContosoCorp / ctso)"
        Write-Host "  - Personalize the .zip and Canvas YAML files for your env"
        Write-Host "  - Import the Dataverse schema (3 tables + relationships + key)"
        Write-Host "  - Prompt you to create an empty Canvas App INSIDE the solution"
        Write-Host "  - Compile the personalized canvas screens to that app"
        Write-Host ""
        Write-Host "Result: ONE solution containing both Dataverse + Canvas App."
        Write-Host "Re-deploy elsewhere with:  pac solution export --name <Name>" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Full instructions: examples\asset-management\README.md" -ForegroundColor Cyan
    }

    '3' {
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

    '4' {
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
