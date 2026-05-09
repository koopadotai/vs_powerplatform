<#
.SYNOPSIS
    Personalizes the asset-management example for a target environment by
    rewriting publisher info + prefix in the Dataverse solution .zip AND
    in the Canvas App YAML files.

.DESCRIPTION
    The example ships with publisher "Wee Siong Dev" (prefix `ws`). To deploy
    to a different env without inheriting that publisher, this script produces
    a personalized copy under dist/asset-management-<prefix>/ containing:
      - <Solution>.zip with the new publisher + prefix
      - canvas/ folder with all .pa.yaml files rewritten to use the new prefix

    The original example files under examples/asset-management/ are NEVER modified.

.PARAMETER PublisherUniqueName
    The publisher's unique name in Dataverse. No spaces, alphanumeric only.
    Example: "AcmeCorp"

.PARAMETER PublisherDisplayName
    The publisher's friendly display name. Spaces allowed.
    Example: "Acme Corporation"

.PARAMETER Prefix
    The customization prefix. 2-8 lowercase letters/digits. This becomes the
    leading prefix of every table, column, choice etc. (e.g. ws_asset, acme_asset).
    Example: "acme"

.PARAMETER SolutionUniqueName
    The solution's unique name in the target env. Default "AssetManagement".

.PARAMETER OptionValuePrefix
    The publisher's option value prefix (5 digits). Default 10000.
    Becomes the prefix of choice values (e.g. 100000000 for prefix 10000).

.PARAMETER OutputDirectory
    Where to write the personalized package. Default: dist\asset-management-<prefix>

.EXAMPLE
    .\automation\Personalize-AssetManagement.ps1 `
        -PublisherUniqueName "AcmeCorp" `
        -PublisherDisplayName "Acme Corporation" `
        -Prefix "acme"

.EXAMPLE
    .\automation\Personalize-AssetManagement.ps1 `
        -PublisherUniqueName "Contoso" `
        -PublisherDisplayName "Contoso Ltd" `
        -Prefix "ctso" `
        -SolutionUniqueName "ContosoAssets" `
        -OptionValuePrefix 20000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$PublisherUniqueName,
    [Parameter(Mandatory = $true)] [string]$PublisherDisplayName,
    [Parameter(Mandatory = $true)] [string]$Prefix,
    [string]$SolutionUniqueName = 'AssetManagement',
    [int]$OptionValuePrefix = 10000,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

# ---- Validation -----------------------------------------------------------

if ($PublisherUniqueName -notmatch '^[A-Za-z][A-Za-z0-9]{1,63}$') {
    throw "PublisherUniqueName must start with a letter, be alphanumeric only, 2-64 chars. Got: '$PublisherUniqueName'"
}

if ($Prefix -notmatch '^[a-z][a-z0-9]{1,7}$') {
    throw "Prefix must be 2-8 lowercase alphanumeric chars starting with a letter. Got: '$Prefix'"
}

if ($OptionValuePrefix -lt 10000 -or $OptionValuePrefix -gt 99999) {
    throw "OptionValuePrefix must be a 5-digit number (10000-99999). Got: $OptionValuePrefix"
}

# ---- Resolve paths --------------------------------------------------------

$repoRoot   = Split-Path -Parent $PSScriptRoot
$sourceZip  = Join-Path $repoRoot 'examples\asset-management\dataverse\AssetManagement.zip'
$sourceCanvas = Join-Path $repoRoot 'examples\asset-management\canvas'

if (-not (Test-Path $sourceZip)) {
    throw "Source .zip not found at $sourceZip. Cannot personalize. Regenerate it first (see skills/asset-management.md → 'Regenerating the .zip')."
}
if (-not (Test-Path $sourceCanvas)) {
    throw "Source canvas folder not found at $sourceCanvas."
}

if (-not $OutputDirectory) {
    # default: <repo>/dist/asset-management-<prefix>
    $OutputDirectory = Join-Path (Split-Path -Parent $repoRoot) "dist\asset-management-$Prefix"
}

$outZip       = Join-Path $OutputDirectory "$SolutionUniqueName.zip"
$outCanvasDir = Join-Path $OutputDirectory 'canvas'
$tempUnpack   = Join-Path $env:TEMP "personalize-$Prefix-$([guid]::NewGuid().ToString('N').Substring(0,8))"

# ---- Banner ---------------------------------------------------------------

Write-Host ''
Write-Host '  Personalize Asset Management for Target Environment' -ForegroundColor Cyan
Write-Host '  ===================================================' -ForegroundColor Cyan
Write-Host "    Publisher unique name : $PublisherUniqueName"
Write-Host "    Publisher display name: $PublisherDisplayName"
Write-Host "    Prefix                : $Prefix"
Write-Host "    Solution name         : $SolutionUniqueName"
Write-Host "    Option value prefix   : $OptionValuePrefix"
Write-Host "    Output                : $OutputDirectory"
Write-Host ''

# ---- Stage 1: Unpack source .zip -----------------------------------------

Write-Host '==> Unpacking source AssetManagement.zip' -ForegroundColor Yellow

if (Test-Path $tempUnpack) { Remove-Item -Recurse -Force $tempUnpack }
New-Item -ItemType Directory -Path $tempUnpack | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($sourceZip, $tempUnpack)

Write-Host '    [OK] Unpacked to temp' -ForegroundColor Green

# ---- Stage 2: Rewrite solution.xml ---------------------------------------

Write-Host '==> Rewriting solution.xml (publisher info)' -ForegroundColor Yellow

$solutionXmlPath = Join-Path $tempUnpack 'solution.xml'
$solutionXml = Get-Content $solutionXmlPath -Raw

# Replace solution unique name
$solutionXml = $solutionXml -replace '<UniqueName>AssetManagement</UniqueName>', "<UniqueName>$SolutionUniqueName</UniqueName>"
$solutionXml = $solutionXml -replace '<LocalizedName description="Asset Management" languagecode="1033" />', "<LocalizedName description=`"$SolutionUniqueName`" languagecode=`"1033`" />"

# Replace publisher info
$solutionXml = $solutionXml -replace '<UniqueName>WeeSiongDev</UniqueName>', "<UniqueName>$PublisherUniqueName</UniqueName>"
$solutionXml = $solutionXml -replace '<LocalizedName description="Wee Siong Dev" languagecode="1033" />', "<LocalizedName description=`"$PublisherDisplayName`" languagecode=`"1033`" />"
$solutionXml = $solutionXml -replace '<Description description="Wee Siong Dev publisher" languagecode="1033" />', "<Description description=`"$PublisherDisplayName publisher`" languagecode=`"1033`" />"

# Replace prefix
$solutionXml = $solutionXml -replace '<CustomizationPrefix>ws</CustomizationPrefix>', "<CustomizationPrefix>$Prefix</CustomizationPrefix>"
$solutionXml = $solutionXml -replace '<CustomizationOptionValuePrefix>10000</CustomizationOptionValuePrefix>', "<CustomizationOptionValuePrefix>$OptionValuePrefix</CustomizationOptionValuePrefix>"

# Replace ws_ schema names in RootComponents
$solutionXml = $solutionXml -replace 'schemaName="ws_', "schemaName=`"${Prefix}_"

Set-Content -Path $solutionXmlPath -Value $solutionXml -Encoding UTF8 -NoNewline
Write-Host '    [OK] solution.xml rewritten' -ForegroundColor Green

# ---- Stage 3: Rewrite customizations.xml ---------------------------------

Write-Host '==> Rewriting customizations.xml (table names + columns + relationships + choice values)' -ForegroundColor Yellow

$customizationsXmlPath = Join-Path $tempUnpack 'customizations.xml'
$customizationsXml = Get-Content $customizationsXmlPath -Raw

# Replace prefix in all schema/logical/relationship/key names
# Match: ws_ at word boundary OR after = / > / "
$customizationsXml = $customizationsXml -replace '\bws_', "${Prefix}_"

# Replace choice values: 100000000-100000004 → <newprefix>0000000-<newprefix>0000004
# Choice values are exactly 9 digits: 5-digit prefix + 4-digit local value
$oldOptionValueBase = 100000000  # 10000 prefix * 10000 + 0
$newOptionValueBase = $OptionValuePrefix * 10000

for ($i = 4; $i -ge 0; $i--) {
    $oldVal = $oldOptionValueBase + $i
    $newVal = $newOptionValueBase + $i
    $customizationsXml = $customizationsXml -replace "value=`"$oldVal`"", "value=`"$newVal`""
    $customizationsXml = $customizationsXml -replace "<AppDefaultValue>$oldVal</AppDefaultValue>", "<AppDefaultValue>$newVal</AppDefaultValue>"
}

Set-Content -Path $customizationsXmlPath -Value $customizationsXml -Encoding UTF8 -NoNewline
Write-Host '    [OK] customizations.xml rewritten' -ForegroundColor Green

# ---- Stage 4: Repack into output .zip ------------------------------------

Write-Host '==> Repacking into personalized .zip' -ForegroundColor Yellow

if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}
if (Test-Path $outZip) { Remove-Item -Force $outZip }

[System.IO.Compression.ZipFile]::CreateFromDirectory($tempUnpack, $outZip)
Write-Host "    [OK] Wrote $outZip ($([math]::Round((Get-Item $outZip).Length / 1KB, 1)) KB)" -ForegroundColor Green

# ---- Stage 5: Personalize Canvas App YAML files --------------------------

Write-Host '==> Personalizing Canvas App YAML files' -ForegroundColor Yellow

if (Test-Path $outCanvasDir) { Remove-Item -Recurse -Force $outCanvasDir }
New-Item -ItemType Directory -Path $outCanvasDir -Force | Out-Null

Get-ChildItem -Path $sourceCanvas -Filter '*.yaml' -File | ForEach-Object {
    $destFile = Join-Path $outCanvasDir $_.Name
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace '\bws_', "${Prefix}_"
    Set-Content -Path $destFile -Value $content -Encoding UTF8 -NoNewline
    Write-Host "    [OK] $($_.Name)" -ForegroundColor Green
}

# ---- Stage 6: Cleanup ----------------------------------------------------

Remove-Item -Recurse -Force $tempUnpack

# ---- Summary -------------------------------------------------------------

Write-Host ''
Write-Host '  Personalization complete.' -ForegroundColor Green
Write-Host ''
Write-Host '  Output:' -ForegroundColor Cyan
Write-Host "    Solution .zip : $outZip"
Write-Host "    Canvas YAMLs  : $outCanvasDir"
Write-Host ''
Write-Host '  Next steps:' -ForegroundColor Yellow
Write-Host "    1. Import the solution:"
Write-Host "       pac solution import --path `"$outZip`" --publish-changes"
Write-Host ''
Write-Host '    2. Deploy the canvas (after import succeeds):'
Write-Host "       Compile from $outCanvasDir to your Studio session"
Write-Host ''
