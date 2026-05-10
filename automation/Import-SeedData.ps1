<#
.SYNOPSIS
    Imports seed data into the AssetManagement Dataverse tables.

.DESCRIPTION
    Reads seed-data.yaml and upserts Asset Categories and Assets via the
    Dataverse Web API. Uses serial number as the alternate key so re-runs
    are idempotent. Does not create assignment history rows — those are
    created by the app as assets are assigned.

    Prerequisites:
      - CreateSchema.ps1 must have been run first
      - PAC CLI or Azure CLI authenticated to the target environment

.PARAMETER Environment
    Dataverse environment URL, e.g. https://orgXXXXXX.crm.dynamics.com

.PARAMETER SeedFile
    Path to seed-data.yaml (defaults to the asset-management example)

.EXAMPLE
    .\automation\Import-SeedData.ps1 -Environment https://org.crm.dynamics.com
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [string]$SeedFile = "$PSScriptRoot\..\examples\asset-management\dataverse\seed-data.yaml"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ─── Helpers ────────────────────────────────────────────────────────────────

function Write-Header { param([string]$t) Write-Host "`n$t" -ForegroundColor Yellow; Write-Host ('─' * 60) -ForegroundColor DarkGray }
function Write-Step   { param([string]$t) Write-Host "  ► $t" -ForegroundColor Cyan   }
function Write-OK     { param([string]$t) Write-Host "    ✓ $t" -ForegroundColor Green }
function Write-Skip   { param([string]$t) Write-Host "    ~ $t (upserted)" -ForegroundColor DarkGray }
function Write-Fail   { param([string]$t) Write-Host "    ✗ $t" -ForegroundColor Red   }

function Get-DataverseToken {
    param([string]$OrgUrl)
    $resource = $OrgUrl.TrimEnd('/')

    try {
        $r = (az account get-access-token --resource $resource 2>$null) | ConvertFrom-Json
        if ($r.accessToken) { return $r.accessToken }
    } catch {}
    try {
        $t = (& pac auth token --url $resource 2>$null) -join ''
        if ($t -and $t -notmatch 'Microsoft PowerPlatform|Error|Usage') { return $t.Trim() }
    } catch {}

    Write-Host "  Starting device code authentication..." -ForegroundColor Yellow
    $clientId = '1950a258-227b-4e31-a9cf-717495945fc2'
    $scope    = "$resource/.default"
    $codeResp = Invoke-RestMethod -Method POST `
        -Uri 'https://login.microsoftonline.com/common/oauth2/v2.0/devicecode' `
        -Body @{ client_id = $clientId; scope = $scope }
    Write-Host "  $($codeResp.message)" -ForegroundColor Cyan
    $deadline = (Get-Date).AddSeconds($codeResp.expires_in)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds ([int]$codeResp.interval)
        try {
            $tok = Invoke-RestMethod -Method POST `
                -Uri 'https://login.microsoftonline.com/common/oauth2/v2.0/token' `
                -Body @{
                    grant_type  = 'urn:ietf:params:oauth:grant-type:device_code'
                    client_id   = $clientId
                    device_code = $codeResp.device_code
                }
            return $tok.access_token
        } catch {
            if (($_ | Out-String) -notmatch 'authorization_pending') { throw }
        }
    }
    throw "Authentication timed out."
}

$script:Base  = $Environment.TrimEnd('/')
$script:Token = $null

function Invoke-DvApi {
    param([string]$Method, [string]$Path, [object]$Body, [hashtable]$ExtraHeaders = @{})
    $headers = @{
        Authorization      = "Bearer $script:Token"
        'OData-MaxVersion' = '4.0'
        'OData-Version'    = '4.0'
        Accept             = 'application/json'
        'Content-Type'     = 'application/json; charset=utf-8'
    } + $ExtraHeaders

    if ($WhatIfPreference) {
        Write-Host "      [WhatIf] $Method /api/data/v9.2/$Path" -ForegroundColor DarkYellow
        return $null
    }
    $splat = @{ Method = $Method; Uri = "$script:Base/api/data/v9.2/$Path"; Headers = $headers }
    if ($Body) { $splat.Body = ($Body | ConvertTo-Json -Depth 10 -Compress) }
    return Invoke-RestMethod @splat
}

# ─── Minimal YAML parser (key: value and list items only) ───────────────────

function ConvertFrom-SimpleYaml {
    param([string]$Content)
    $lines   = $Content -split "`n"
    $result  = @{}
    $current = $null    # current top-level list name
    $item    = $null    # current list item hashtable

    $flush = { if ($item -and $current) { if (-not $result[$current]) { $result[$current] = @() }; $result[$current] += $item } }

    foreach ($raw in $lines) {
        $line = $raw -replace '\s*#.*$', ''   # strip comments
        if (-not $line.Trim()) { continue }

        # Top-level key:  (no indent, ends with colon or has value)
        if ($line -match '^(\w[\w_]+):\s*(.*)$') {
            $key = $Matches[1]; $val = $Matches[2].Trim()
            if ($val -eq '') {
                & $flush
                $current = $key; $item = $null
                $result[$key] = @()
            } else {
                $result[$key] = $val
            }
            continue
        }
        # List item start:  - key: value
        if ($line -match '^  - (\w[\w_]+):\s*(.*)$') {
            & $flush
            $item = @{ $Matches[1] = $Matches[2].Trim('"') }
            continue
        }
        # List item continuation:    key: value
        if ($line -match '^    (\w[\w_]+):\s*(.*)$' -and $item) {
            $item[$Matches[1]] = $Matches[2].Trim('"')
            continue
        }
    }
    & $flush
    return $result
}

# ─── Banner ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Asset Management — Seed Data Import" -ForegroundColor Cyan
Write-Host "  =====================================" -ForegroundColor Cyan
Write-Host "  Environment : $script:Base"
Write-Host "  Seed file   : $SeedFile"
if ($WhatIfPreference) { Write-Host "  [WhatIf — no changes will be made]" -ForegroundColor DarkYellow }
Write-Host ""

if (-not (Test-Path $SeedFile)) { throw "Seed file not found: $SeedFile" }

# ─── Auth ────────────────────────────────────────────────────────────────────

Write-Header "1 / 3  Auth"
Write-Step "Acquiring token..."
$script:Token = Get-DataverseToken -Url $script:Base
Write-OK "Token acquired"

# ─── Parse seed data ─────────────────────────────────────────────────────────

$seed         = ConvertFrom-SimpleYaml -Content (Get-Content $SeedFile -Raw)
$statusValues = @{
    Available  = 100000000; Assigned  = 100000001
    'In Repair' = 100000002; Retired  = 100000003; Lost = 100000004
}

# ─── Asset Categories ────────────────────────────────────────────────────────

Write-Header "2 / 3  Asset Categories"

$categoryIds = @{}   # name → guid, for use in asset upsert

foreach ($cat in $seed.assetCategories) {
    Write-Step $cat.ws_categoryname
    try {
        $body = @{ ws_categoryname = $cat.ws_categoryname }
        if ($cat.ws_description) { $body.ws_description = $cat.ws_description }

        if ($PSCmdlet.ShouldProcess($cat.ws_categoryname, 'Upsert asset category')) {
            $headers = @{ 'If-Match' = '*'; Prefer = 'return=representation' }
            $escaped  = [Uri]::EscapeDataString($cat.ws_categoryname)
            $result   = Invoke-DvApi PATCH "ws_assetcategories(ws_categoryname='$escaped')" $body $headers
            if ($result) { $categoryIds[$cat.ws_categoryname] = $result.ws_assetcategoryid }
            Write-OK $cat.ws_categoryname
        }
    } catch { Write-Fail "$($cat.ws_categoryname): $_" }
}

# ─── Assets ──────────────────────────────────────────────────────────────────

Write-Header "3 / 3  Assets"

foreach ($asset in $seed.assets) {
    Write-Step "$($asset.ws_assetname) [$($asset.ws_serialnumber)]"
    try {
        $statusVal = $statusValues[$asset.ws_status]
        if (-not $statusVal) { throw "Unknown status: $($asset.ws_status)" }

        $body = @{
            ws_assetname    = $asset.ws_assetname
            ws_serialnumber = $asset.ws_serialnumber
            ws_status       = $statusVal
        }

        if ($asset.ws_purchasedate) { $body.ws_purchasedate = $asset.ws_purchasedate }
        if ($asset.ws_purchasecost) { $body.ws_purchasecost = [decimal]$asset.ws_purchasecost }
        if ($asset.ws_warrantyend)  { $body.ws_warrantyend  = $asset.ws_warrantyend }
        if ($asset.ws_notes)        { $body.ws_notes        = $asset.ws_notes }

        if ($asset.ws_categoryname -and $categoryIds[$asset.ws_categoryname]) {
            $body['ws_categoryid@odata.bind'] = "/ws_assetcategories($($categoryIds[$asset.ws_categoryname]))"
        }

        if ($PSCmdlet.ShouldProcess($asset.ws_serialnumber, 'Upsert asset')) {
            $headers = @{ 'If-Match' = '*'; Prefer = 'return=representation' }
            Invoke-DvApi PATCH "ws_assets(ws_serialnumber='$($asset.ws_serialnumber)')" $body $headers | Out-Null
            Write-OK "$($asset.ws_assetname) [$($asset.ws_serialnumber)]"
        }
    } catch { Write-Fail "$($asset.ws_serialnumber): $_" }
}

# ─── Done ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Seed data import complete." -ForegroundColor Green
Write-Host ""
Write-Host "  Verify at: $script:Base/main.aspx#/list/ws_asset" -ForegroundColor Yellow
Write-Host ""
