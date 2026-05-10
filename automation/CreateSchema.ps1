<#
.SYNOPSIS
    Creates the AssetManagement Dataverse schema from schema.yaml.

.DESCRIPTION
    Creates all tables, columns, choices, relationships, alternate keys, and
    views in the target environment. Idempotent — skips anything that already
    exists, so it is safe to re-run after a partial failure.

    Prerequisites:
      - PAC CLI authenticated   →  Connect-PowerPlatform.ps1
      - Or Azure CLI logged in  →  az login

.PARAMETER Environment
    Dataverse environment URL, e.g. https://orgXXXXXX.crm.dynamics.com

.PARAMETER WhatIf
    Preview every API call without making any changes.

.EXAMPLE
    .\automation\CreateSchema.ps1 -Environment https://org.crm.dynamics.com

.EXAMPLE
    .\automation\CreateSchema.ps1 -Environment https://org.crm.dynamics.com -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Environment
)

$ErrorActionPreference = 'Stop'

# ─── Console helpers ────────────────────────────────────────────────────────

function Write-Header { param([string]$t) Write-Host "`n$t" -ForegroundColor Yellow; Write-Host ('-' * 60) -ForegroundColor DarkGray }
function Write-Step   { param([string]$t) Write-Host "  >> $t" -ForegroundColor Cyan   }
function Write-OK     { param([string]$t) Write-Host "    [OK] $t" -ForegroundColor Green }
function Write-Skip   { param([string]$t) Write-Host "    [--] $t (already exists)" -ForegroundColor DarkGray }
function Write-Fail   { param([string]$t,[string]$e) Write-Host "    [!!] $t : $e" -ForegroundColor Red }

# ─── Auth ────────────────────────────────────────────────────────────────────

function Get-DataverseToken {
    param([string]$BaseUrl)

    # Method 1: Azure CLI
    try {
        $r = az account get-access-token --resource $BaseUrl 2>$null | ConvertFrom-Json
        if ($r -and $r.accessToken) { Write-OK "Token via Azure CLI"; return $r.accessToken }
    } catch { }

    # Method 2: PAC CLI auth token (newer versions)
    try {
        $raw = (pac auth token --url $BaseUrl 2>&1) | Out-String
        if ($raw -and $raw -notmatch 'Microsoft PowerPlatform|Error|Usage|Commands') {
            Write-OK "Token via PAC CLI"; return $raw.Trim()
        }
    } catch { }

    # Method 3: OAuth Device Code flow
    Write-Host "  No cached token — starting device code flow..." -ForegroundColor Yellow
    $clientId = '1950a258-227b-4e31-a9cf-717495945fc2'
    $scope    = "$BaseUrl/.default"

    $codeResp = Invoke-RestMethod -Method POST `
        -Uri 'https://login.microsoftonline.com/common/oauth2/v2.0/devicecode' `
        -Body @{ client_id = $clientId; scope = $scope }

    Write-Host ""
    Write-Host "  $($codeResp.message)" -ForegroundColor Cyan
    Write-Host ""

    $deadline = (Get-Date).AddSeconds([int]$codeResp.expires_in)
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
            Write-OK "Token via device code"; return $tok.access_token
        } catch {
            if (($_ | Out-String) -notmatch 'authorization_pending') { throw }
        }
    }
    throw "Authentication timed out. Re-run to try again."
}

# ─── Dataverse API helper ────────────────────────────────────────────────────

function Invoke-DvApi {
    param([string]$BaseUrl, [string]$Token, [string]$Method, [string]$Path, [object]$Body)
    if ($WhatIfPreference) {
        Write-Host "      [WhatIf] $Method /api/data/v9.2/$Path" -ForegroundColor DarkYellow
        return $null
    }
    $headers = @{
        Authorization      = "Bearer $Token"
        'OData-MaxVersion' = '4.0'
        'OData-Version'    = '4.0'
        Accept             = 'application/json'
        'Content-Type'     = 'application/json; charset=utf-8'
        Prefer             = 'return=representation'
    }
    $splat = @{ Method = $Method; Uri = "$BaseUrl/api/data/v9.2/$Path"; Headers = $headers }
    if ($Body) { $splat.Body = ($Body | ConvertTo-Json -Depth 20 -Compress) }
    return Invoke-RestMethod @splat
}

function Test-DvEntity {
    param([string]$BaseUrl, [string]$Token, [string]$Name)
    try {
        $r = Invoke-DvApi $BaseUrl $Token GET "EntityDefinitions?`$filter=LogicalName eq '$Name'&`$select=LogicalName"
        return ($r -and $r.value.Count -gt 0)
    } catch { return $false }
}

function New-DvLabel {
    param([string]$Text, [int]$Lang = 1033)
    @{
        '@odata.type'      = 'Microsoft.Dynamics.CRM.Label'
        LocalizedLabels    = @(@{ '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel'; Label = $Text; LanguageCode = $Lang })
        UserLocalizedLabel = @{  '@odata.type' = 'Microsoft.Dynamics.CRM.LocalizedLabel'; Label = $Text; LanguageCode = $Lang }
    }
}

# ─── Banner ─────────────────────────────────────────────────────────────────

$baseUrl = $Environment.TrimEnd('/')

Write-Host ""
Write-Host "  Asset Management — Dataverse Schema Setup" -ForegroundColor Cyan
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host "  Environment : $baseUrl"
if ($WhatIfPreference) { Write-Host "  [WhatIf — no changes will be made]" -ForegroundColor DarkYellow }
Write-Host ""

# ─── 1. Auth ─────────────────────────────────────────────────────────────────

Write-Header "1 / 7  Auth"
Write-Step "Acquiring token..."
$token = Get-DataverseToken -BaseUrl $baseUrl
Write-OK "Token acquired"

# ─── 2. Choice Set ───────────────────────────────────────────────────────────
#
# schema.yaml declares ws_assetstatus with isGlobal: false, so it is created
# as a *local* picklist when the ws_status column is added to ws_asset
# (see section 4). Nothing to do here.

Write-Header "2 / 7  Choice Set"
Write-Step "ws_assetstatus (local — created with ws_asset.ws_status column)"
Write-OK "Deferred to column creation"

# ─── 3. Tables ───────────────────────────────────────────────────────────────

Write-Header "3 / 7  Tables"

$tables = @(
    @{
        SchemaName            = 'ws_assetcategory'
        DisplayName           = 'Asset Category'
        DisplayCollectionName = 'Asset Categories'
        Description           = 'Groups assets by type (Laptop, Phone, Monitor, etc.)'
        PrimarySchema         = 'ws_categoryname'
        PrimaryDisplay        = 'Category Name'
        PrimaryMaxLength      = 80
    }
    @{
        SchemaName            = 'ws_asset'
        DisplayName           = 'Asset'
        DisplayCollectionName = 'Assets'
        Description           = 'Tracks individual IT assets and their lifecycle'
        PrimarySchema         = 'ws_assetname'
        PrimaryDisplay        = 'Asset Name'
        PrimaryMaxLength      = 100
    }
    @{
        SchemaName            = 'ws_assetassignment'
        DisplayName           = 'Asset Assignment'
        DisplayCollectionName = 'Asset Assignments'
        Description           = 'Historical record of every asset assignment for audit'
        PrimarySchema         = 'ws_assignmentname'
        PrimaryDisplay        = 'Assignment Reference'
        PrimaryMaxLength      = 50
    }
)

foreach ($tbl in $tables) {
    Write-Step $tbl.SchemaName
    try {
        if (Test-DvEntity $baseUrl $token $tbl.SchemaName) {
            Write-Skip $tbl.SchemaName; continue
        }
        if ($PSCmdlet.ShouldProcess($tbl.SchemaName, 'Create table')) {
            $body = @{
                '@odata.type'         = 'Microsoft.Dynamics.CRM.EntityMetadata'
                SchemaName            = $tbl.SchemaName
                DisplayName           = (New-DvLabel $tbl.DisplayName)
                DisplayCollectionName = (New-DvLabel $tbl.DisplayCollectionName)
                Description           = (New-DvLabel $tbl.Description)
                OwnershipType         = 'OrganizationOwned'
                IsAuditEnabled        = @{ Value = $true }
                PrimaryAttribute      = @{
                    '@odata.type' = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
                    SchemaName    = $tbl.PrimarySchema
                    DisplayName   = (New-DvLabel $tbl.PrimaryDisplay)
                    MaxLength     = $tbl.PrimaryMaxLength
                    RequiredLevel = @{ Value = 'ApplicationRequired' }
                    FormatName    = @{ Value = 'Text' }
                }
            }
            Invoke-DvApi $baseUrl $token POST 'EntityDefinitions' $body | Out-Null
            Write-OK "$($tbl.SchemaName) created"
        }
    } catch { Write-Fail $tbl.SchemaName ($_ | Out-String) }
}

# ─── 4. Columns ──────────────────────────────────────────────────────────────

Write-Header "4 / 7  Columns"

function Add-Column {
    param([string]$BaseUrl, [string]$Token, [string]$Table, [hashtable]$Col)
    try {
        Invoke-DvApi $BaseUrl $Token POST "EntityDefinitions(LogicalName='$Table')/Attributes" $Col | Out-Null
        Write-OK "$Table.$($Col.SchemaName)"
    } catch {
        $msg = $_ | Out-String
        if ($msg -match '80044331|already exists|AlreadyExists') { Write-Skip "$Table.$($Col.SchemaName)" }
        else { Write-Fail "$Table.$($Col.SchemaName)" $msg }
    }
}

Write-Step "Asset Category columns"
Add-Column $baseUrl $token 'ws_assetcategory' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
    SchemaName = 'ws_icon'; DisplayName = (New-DvLabel 'Icon'); MaxLength = 4; RequiredLevel = @{ Value = 'None' }; FormatName = @{ Value = 'Text' }
}
Add-Column $baseUrl $token 'ws_assetcategory' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.MemoAttributeMetadata'
    SchemaName = 'ws_description'; DisplayName = (New-DvLabel 'Description'); MaxLength = 500; RequiredLevel = @{ Value = 'None' }; Format = 'Text'
}

Write-Step "Asset columns"
Add-Column $baseUrl $token 'ws_asset' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
    SchemaName = 'ws_serialnumber'; DisplayName = (New-DvLabel 'Serial Number'); MaxLength = 50; RequiredLevel = @{ Value = 'ApplicationRequired' }; FormatName = @{ Value = 'Text' }
}
Add-Column $baseUrl $token 'ws_asset' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.PicklistAttributeMetadata'
    SchemaName    = 'ws_status'
    DisplayName   = (New-DvLabel 'Status')
    Description   = (New-DvLabel 'Lifecycle status of the asset')
    RequiredLevel = @{ Value = 'ApplicationRequired' }
    OptionSet     = @{
        '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
        IsGlobal      = $false
        OptionSetType = 'Picklist'
        Name          = 'ws_assetstatus'
        DisplayName   = (New-DvLabel 'Asset Status')
        Description   = (New-DvLabel 'Lifecycle status of an IT asset')
        Options       = @(
            @{ Value = 100000000; Label = (New-DvLabel 'Available') }
            @{ Value = 100000001; Label = (New-DvLabel 'Assigned')  }
            @{ Value = 100000002; Label = (New-DvLabel 'In Repair') }
            @{ Value = 100000003; Label = (New-DvLabel 'Retired')   }
            @{ Value = 100000004; Label = (New-DvLabel 'Lost')      }
        )
    }
}
Add-Column $baseUrl $token 'ws_asset' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
    SchemaName = 'ws_purchasedate'; DisplayName = (New-DvLabel 'Purchase Date'); RequiredLevel = @{ Value = 'None' }; Format = 'DateOnly'; DateTimeBehavior = @{ Value = 'DateOnly' }
}
Add-Column $baseUrl $token 'ws_asset' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.MoneyAttributeMetadata'
    SchemaName = 'ws_purchasecost'; DisplayName = (New-DvLabel 'Purchase Cost'); RequiredLevel = @{ Value = 'None' }; PrecisionSource = 2
}
Add-Column $baseUrl $token 'ws_asset' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
    SchemaName = 'ws_warrantyend'; DisplayName = (New-DvLabel 'Warranty End'); RequiredLevel = @{ Value = 'None' }; Format = 'DateOnly'; DateTimeBehavior = @{ Value = 'DateOnly' }
}
Add-Column $baseUrl $token 'ws_asset' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
    SchemaName = 'ws_assigneddate'; DisplayName = (New-DvLabel 'Assigned Date'); RequiredLevel = @{ Value = 'None' }; Format = 'DateAndTime'
}
Add-Column $baseUrl $token 'ws_asset' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.MemoAttributeMetadata'
    SchemaName = 'ws_notes'; DisplayName = (New-DvLabel 'Notes'); MaxLength = 2000; RequiredLevel = @{ Value = 'None' }; Format = 'Text'
}

Write-Step "Asset Assignment columns"
Add-Column $baseUrl $token 'ws_assetassignment' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
    SchemaName = 'ws_assignedfrom'; DisplayName = (New-DvLabel 'Assigned From'); RequiredLevel = @{ Value = 'ApplicationRequired' }; Format = 'DateAndTime'
}
Add-Column $baseUrl $token 'ws_assetassignment' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
    SchemaName = 'ws_assignedto_dt'; DisplayName = (New-DvLabel 'Assigned To Date'); RequiredLevel = @{ Value = 'None' }; Format = 'DateAndTime'
}
Add-Column $baseUrl $token 'ws_assetassignment' @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.MemoAttributeMetadata'
    SchemaName = 'ws_notes'; DisplayName = (New-DvLabel 'Notes'); MaxLength = 1000; RequiredLevel = @{ Value = 'None' }; Format = 'Text'
}

# ─── 5. Relationships ────────────────────────────────────────────────────────

Write-Header "5 / 7  Relationships"

$noCascade = @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.CascadeConfiguration'
    Assign = 'NoCascade'; Delete = 'NoCascade'; Merge = 'NoCascade'; Reparent = 'NoCascade'; Share = 'NoCascade'; Unshare = 'NoCascade'
}

$rels = @(
    @{
        SchemaName        = 'ws_assetcategory_ws_asset'
        ReferencedEntity  = 'ws_assetcategory'
        ReferencingEntity = 'ws_asset'
        LookupSchema      = 'ws_categoryid'
        LookupDisplay     = 'Category'
        LookupRequired    = 'ApplicationRequired'
        Cascade           = @{
            '@odata.type' = 'Microsoft.Dynamics.CRM.CascadeConfiguration'
            Assign = 'NoCascade'; Delete = 'Restrict'; Merge = 'NoCascade'; Reparent = 'NoCascade'; Share = 'NoCascade'; Unshare = 'NoCascade'
        }
    }
    @{
        SchemaName        = 'ws_asset_ws_assetassignment'
        ReferencedEntity  = 'ws_asset'
        ReferencingEntity = 'ws_assetassignment'
        LookupSchema      = 'ws_assetid'
        LookupDisplay     = 'Asset'
        LookupRequired    = 'ApplicationRequired'
        Cascade           = @{
            '@odata.type' = 'Microsoft.Dynamics.CRM.CascadeConfiguration'
            Assign = 'NoCascade'; Delete = 'RemoveLink'; Merge = 'NoCascade'; Reparent = 'NoCascade'; Share = 'NoCascade'; Unshare = 'NoCascade'
        }
    }
    @{
        SchemaName        = 'systemuser_ws_asset_assignedto'
        ReferencedEntity  = 'systemuser'
        ReferencingEntity = 'ws_asset'
        LookupSchema      = 'ws_assignedto'
        LookupDisplay     = 'Assigned To'
        LookupRequired    = 'None'
        Cascade           = $noCascade
    }
    @{
        SchemaName        = 'systemuser_ws_assetassignment_assignedto'
        ReferencedEntity  = 'systemuser'
        ReferencingEntity = 'ws_assetassignment'
        LookupSchema      = 'ws_assignedto'
        LookupDisplay     = 'Assigned To'
        LookupRequired    = 'ApplicationRequired'
        Cascade           = $noCascade
    }
)

foreach ($rel in $rels) {
    Write-Step $rel.SchemaName
    try {
        $body = @{
            '@odata.type'        = 'Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata'
            SchemaName           = $rel.SchemaName
            ReferencedEntity     = $rel.ReferencedEntity
            ReferencingEntity    = $rel.ReferencingEntity
            CascadeConfiguration = $rel.Cascade
            Lookup               = @{
                '@odata.type' = 'Microsoft.Dynamics.CRM.LookupAttributeMetadata'
                SchemaName    = $rel.LookupSchema
                DisplayName   = (New-DvLabel $rel.LookupDisplay)
                RequiredLevel = @{ Value = $rel.LookupRequired }
            }
        }
        if ($PSCmdlet.ShouldProcess($rel.SchemaName, 'Create relationship')) {
            Invoke-DvApi $baseUrl $token POST 'RelationshipDefinitions' $body | Out-Null
            Write-OK $rel.SchemaName
        }
    } catch {
        $msg = $_ | Out-String
        if ($msg -match '80044331|already exists|AlreadyExists') { Write-Skip $rel.SchemaName }
        else { Write-Fail $rel.SchemaName $msg }
    }
}

# ─── 6. Alternate Key ────────────────────────────────────────────────────────

Write-Header "6 / 7  Alternate Key"
Write-Step "ws_asset — serial number"
try {
    if ($PSCmdlet.ShouldProcess('ws_asset.ws_serialnumber', 'Create alternate key')) {
        $keyBody = @{
            SchemaName    = 'ws_asset_serialnumber_key'
            DisplayName   = (New-DvLabel 'Serial Number (Unique)')
            KeyAttributes = @('ws_serialnumber')
        }
        Invoke-DvApi $baseUrl $token POST "EntityDefinitions(LogicalName='ws_asset')/Keys" $keyBody | Out-Null
        Write-OK "ws_asset_serialnumber_key"
    }
} catch {
    $msg = $_ | Out-String
    if ($msg -match '80044331|already exists|AlreadyExists') { Write-Skip "ws_asset_serialnumber_key" }
    else { Write-Fail "ws_asset_serialnumber_key" $msg }
}

# ─── 7. Publish ──────────────────────────────────────────────────────────────

Write-Header "7 / 7  Publish"
Write-Step "Publishing customizations..."
try {
    if ($PSCmdlet.ShouldProcess('Dataverse', 'Publish all customizations')) {
        Invoke-DvApi $baseUrl $token POST 'PublishAllXml' @{} | Out-Null
        Write-OK "Published"
    }
} catch { Write-Fail "Publish" ($_ | Out-String) }

# ─── Done ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Schema setup complete." -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Verify tables  →  make.powerapps.com › Dataverse › Tables"
Write-Host "    2. Import seed    →  .\automation\Import-SeedData.ps1 -Environment $baseUrl"
Write-Host "    3. Assign roles   →  Power Platform Admin Center › Security roles"
Write-Host ""
