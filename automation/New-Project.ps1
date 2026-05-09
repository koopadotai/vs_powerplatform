<#
.SYNOPSIS
    Scaffold a new project from a toolkit template.

.DESCRIPTION
    Copies a template (canvas-app, dotnet-api, dataverse-schema) into the
    target location and replaces tokens (__SERVICE_NAME__, __APP_TITLE__, etc.)
    with the values you provide.

.PARAMETER Type
    Project type. One of: canvas-app, dotnet-api, dataverse-schema.

.PARAMETER Name
    Project name in PascalCase (e.g. AssetApi, VehicleInspection).

.PARAMETER Title
    (canvas-app only) Display title shown in the app header.

.PARAMETER Tagline
    (canvas-app only) Subtitle/welcome text.

.PARAMETER OutputRoot
    Where to create the project. Defaults to the right place per type:
        canvas-app       -> examples/<Name>/canvas/
        dotnet-api       -> src/<Name>/
        dataverse-schema -> templates/powerapps/dataverse/<Name>/

.EXAMPLE
    .\New-Project.ps1 -Type canvas-app -Name VehicleInspection -Title "Vehicle Inspection" -Tagline "Daily safety checks"

.EXAMPLE
    .\New-Project.ps1 -Type dotnet-api -Name AssetApi
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('canvas-app', 'dotnet-api', 'dataverse-schema')]
    [string]$Type,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [string]$Title,
    [string]$Tagline,
    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# --- Resolve repo root ----------------------------------------------------
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot 'CLAUDE.md'))) {
    Write-Error "This script must run from the toolkit repo (CLAUDE.md not found in $RepoRoot)"
    exit 1
}

# --- Resolve template + output paths --------------------------------------
$BuildDate = Get-Date -Format 'yyyy-MM-dd'

switch ($Type) {
    'canvas-app' {
        $TemplatePath = Join-Path $RepoRoot 'templates\powerapps\canvas-starter'
        if (-not $OutputRoot) { $OutputRoot = Join-Path $RepoRoot "examples\$Name\canvas" }
        if (-not $Title)      { $Title = $Name }
        if (-not $Tagline)    { $Tagline = "Built with the Enterprise Power Platform Toolkit." }
    }
    'dotnet-api' {
        $TemplatePath = Join-Path $RepoRoot 'templates\dotnet\api-starter'
        if (-not $OutputRoot) { $OutputRoot = Join-Path $RepoRoot "src\$Name" }
    }
    'dataverse-schema' {
        $TemplatePath = Join-Path $RepoRoot 'templates\powerapps\dataverse\sample-schema'
        if (-not $OutputRoot) { $OutputRoot = Join-Path $RepoRoot "examples\$Name\dataverse" }
    }
}

if (-not (Test-Path $TemplatePath)) {
    Write-Error "Template not found: $TemplatePath"
    exit 1
}

if (Test-Path $OutputRoot) {
    $existing = Get-ChildItem $OutputRoot -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "[WARN] Output path exists and is not empty: $OutputRoot" -ForegroundColor Yellow
        $response = Read-Host "Overwrite? (yes/no)"
        if ($response -ne 'yes') {
            Write-Host "Aborted." -ForegroundColor Red
            exit 1
        }
    }
}

# --- Copy template ---------------------------------------------------------
Write-Host "Copying $TemplatePath -> $OutputRoot" -ForegroundColor Cyan
New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
Copy-Item -Path "$TemplatePath\*" -Destination $OutputRoot -Recurse -Force

# --- Token replacement -----------------------------------------------------
$tokens = @{
    '__SERVICE_NAME__' = $Name
    '__APP_TITLE__'    = $Title
    '__APP_TAGLINE__'  = $Tagline
    '__BUILD_DATE__'   = $BuildDate
}

Write-Host "Applying tokens:" -ForegroundColor Cyan
foreach ($key in $tokens.Keys) {
    if ($tokens[$key]) {
        Write-Host "    $key -> $($tokens[$key])"
    }
}

# Rename folders that contain tokens
Get-ChildItem -Path $OutputRoot -Recurse -Directory |
    Sort-Object -Property FullName -Descending |
    ForEach-Object {
        $newName = $_.Name
        foreach ($key in $tokens.Keys) {
            if ($tokens[$key]) {
                $newName = $newName.Replace($key, $tokens[$key])
            }
        }
        if ($newName -ne $_.Name) {
            Rename-Item -Path $_.FullName -NewName $newName
        }
    }

# Rename files that contain tokens
Get-ChildItem -Path $OutputRoot -Recurse -File |
    ForEach-Object {
        $newName = $_.Name
        foreach ($key in $tokens.Keys) {
            if ($tokens[$key]) {
                $newName = $newName.Replace($key, $tokens[$key])
            }
        }
        if ($newName -ne $_.Name) {
            Rename-Item -Path $_.FullName -NewName $newName
        }
    }

# Replace tokens inside files (text files only)
$textExtensions = @('.cs', '.csproj', '.json', '.yaml', '.yml', '.md', '.ps1', '.cmd', '.sh', '.dockerfile', '.editorconfig', '.gitignore', '.txt', '.xml', '.config', '.props', '.targets')

Get-ChildItem -Path $OutputRoot -Recurse -File |
    Where-Object { $textExtensions -contains $_.Extension.ToLower() -or $_.Name -like 'Dockerfile*' } |
    ForEach-Object {
        $content = Get-Content -Path $_.FullName -Raw
        $original = $content
        foreach ($key in $tokens.Keys) {
            if ($tokens[$key]) {
                $content = $content.Replace($key, $tokens[$key])
            }
        }
        if ($content -ne $original) {
            Set-Content -Path $_.FullName -Value $content -NoNewline
        }
    }

# --- Done -----------------------------------------------------------------
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " Project created: $Name" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Location: $OutputRoot"
Write-Host ""

switch ($Type) {
    'canvas-app' {
        Write-Host "Next steps:"
        Write-Host "  1. Open Power Apps Studio (make.powerapps.com)"
        Write-Host "  2. Create a new Canvas App (phone form factor)"
        Write-Host "  3. Enable coauthoring: Settings -> Updates -> Coauthoring"
        Write-Host "  4. Add data sources via 'Data -> + Add data'"
        Write-Host "  5. From VS Code, run 'Compile canvas app to Power Apps Studio'"
    }
    'dotnet-api' {
        Write-Host "Next steps:"
        Write-Host "  cd $OutputRoot"
        Write-Host "  dotnet restore && dotnet build"
        Write-Host "  dotnet test"
        Write-Host "  dotnet run"
    }
    'dataverse-schema' {
        Write-Host "Next steps:"
        Write-Host "  Edit $OutputRoot to define your tables"
        Write-Host "  Run: .\automation\CreateSchema.ps1 -Schema $OutputRoot\schema.yaml -Environment dev"
    }
}
