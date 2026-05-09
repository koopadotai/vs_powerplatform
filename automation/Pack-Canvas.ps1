<#
.SYNOPSIS
    Pack a folder of .pa.yaml files into a .msapp bundle (round-trip workflow).

.DESCRIPTION
    Wraps `pac canvas pack --layout SourceCode`.

    IMPORTANT - pa.yaml SourceCode pack only works when the YAML was originally
    UNPACKED from a real .msapp (i.e. round-trip workflow). It cannot pack
    hand-authored YAML written from scratch.

    For hand-authored YAML in this toolkit, the deployment path is:
        canvas-authoring MCP server -> compile_canvas
    (which writes the YAML directly into a Studio session).

    Use this script when:
      - You unpacked an existing app with `pac canvas unpack`
      - You modified the YAML
      - You want to repack to .msapp for deployment

.PARAMETER Source
    Folder containing the .pa.yaml files (must include App.pa.yaml + at least one screen).

.PARAMETER Output
    Output path for the .msapp file. Defaults to <SourceParent>\<SourceFolder>.msapp.

.PARAMETER Force
    Overwrite the output file if it exists.

.EXAMPLE
    .\Pack-Canvas.ps1 -Source .\my-app\Src -Output .\my-app\MyApp.msapp -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [string]$Output,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# --- Validate PAC CLI ----------------------------------------------------
if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] PAC CLI not found. Run .\scripts\windows\Install-All.ps1 first." -ForegroundColor Red
    exit 1
}

# --- Validate source -----------------------------------------------------
$Source = (Resolve-Path $Source).Path
if (-not (Test-Path $Source)) {
    Write-Host "[ERROR] Source folder not found: $Source" -ForegroundColor Red
    exit 1
}

$appYaml = Join-Path $Source 'App.pa.yaml'
if (-not (Test-Path $appYaml)) {
    Write-Host "[ERROR] App.pa.yaml not found in $Source" -ForegroundColor Red
    exit 1
}

$screens = Get-ChildItem -Path $Source -Filter '*.pa.yaml' | Where-Object { $_.Name -ne 'App.pa.yaml' }
if (-not $screens) {
    Write-Host "[ERROR] No screen .pa.yaml files found in $Source" -ForegroundColor Red
    exit 1
}

# --- Resolve output ------------------------------------------------------
if (-not $Output) {
    $folderName = (Get-Item $Source).Name
    $Output = Join-Path (Split-Path $Source -Parent) "$folderName.msapp"
}

if ((Test-Path $Output) -and -not $Force) {
    Write-Host "[ERROR] Output exists: $Output (use -Force to overwrite)" -ForegroundColor Red
    exit 1
}

if (Test-Path $Output) {
    Remove-Item $Output -Force
}

$outputDir = Split-Path $Output -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# --- Pack ----------------------------------------------------------------
Write-Host ""
Write-Host "Packing canvas app (SourceCode layout)..." -ForegroundColor Cyan
Write-Host "    Source : $Source"
Write-Host "    Screens: $($screens.Count) ($((($screens | ForEach-Object { $_.BaseName -replace '\.pa$','' }) -join ', ')))"
Write-Host "    Output : $Output"
Write-Host ""

$packArgs = @(
    'canvas', 'pack',
    '--sources', $Source,
    '--msapp',  $Output,
    '--layout', 'SourceCode'
)

if ($Force) {
    $packArgs += '--overwrite'
}

& pac @packArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] pac canvas pack failed (exit $LASTEXITCODE)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common cause: hand-authored YAML can't be packed directly." -ForegroundColor Yellow
    Write-Host "PAC CLI pack only works on YAML that was previously unpacked from a real .msapp." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "For hand-authored YAML, deploy via the canvas-authoring MCP server:" -ForegroundColor Yellow
    Write-Host "  1. Create an empty Canvas App in Power Apps Studio"
    Write-Host "  2. /configure-canvas-mcp <studio-url>"
    Write-Host "  3. Ask Claude: 'compile <source-folder> to Studio'"
    exit $LASTEXITCODE
}

# --- Done ----------------------------------------------------------------
$size = (Get-Item $Output).Length
$sizeKB = [math]::Round($size / 1KB, 1)

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " Packed successfully: $Output ($sizeKB KB)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Deploy:" -ForegroundColor Yellow
Write-Host "  1. https://make.powerapps.com -> Apps -> Import canvas app -> select the .msapp"
Write-Host ""
