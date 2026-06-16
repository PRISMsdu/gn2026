<#
  Variante archives de export_avis.ps1.
  Elle utilise le meme export A4 que les avis, avec des signatures reduites de 50%.
#>

[CmdletBinding()]
param(
  [string] $MarkdownPath,
  [string] $AvisFileName,
  [string] $AvisDirectory,
  [string] $OutputHtmlPath = "",
  [string] $InstitutionNom = "Union Bancaire d'Il-Irion",
  [ValidateSet('A4', 'A3')]
  [string] $Format = 'A4',
  [switch] $SkipPdf,
  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',
  [string] $ChromePath = "",
  [string] $PandocPath = "",
  [switch] $ForceSignatures
)

$ErrorActionPreference = "Stop"

$previousCssPath = $env:GN_AVIS_CSS_PATH
$previousBlasonPath = $env:GN_AVIS_BLASON_PATH
$previousSignatureSeals = $env:GN_AVIS_SIGNATURE_SEALS
$previousArchiveStampText = $env:GN_AVIS_ARCHIVE_STAMP_TEXT
$env:GN_AVIS_CSS_PATH = "avis_archives_print.css"
$env:GN_AVIS_BLASON_PATH = "Groupes\Banquiers - UBI\1 - Back de groupe\Blason_UBI.png"
$env:GN_AVIS_SIGNATURE_SEALS = "archives"
$env:GN_AVIS_ARCHIVE_STAMP_TEXT = "Acte execute et clos."

try {
  $paramsForExport = @{}
  if (-not [string]::IsNullOrWhiteSpace($MarkdownPath)) {
    $paramsForExport.MarkdownPath = $MarkdownPath
  } else {
    $paramsForExport.AvisFileName = $AvisFileName
    $paramsForExport.AvisDirectory = $AvisDirectory
  }
  if (-not [string]::IsNullOrWhiteSpace($OutputHtmlPath)) { $paramsForExport.OutputHtmlPath = $OutputHtmlPath }
  $paramsForExport.InstitutionNom = $InstitutionNom
  $paramsForExport.Format = $Format
  $paramsForExport.Browser = $Browser
  if ($SkipPdf) { $paramsForExport.SkipPdf = $true }
  if (-not [string]::IsNullOrWhiteSpace($ChromePath)) { $paramsForExport.ChromePath = $ChromePath }
  if (-not [string]::IsNullOrWhiteSpace($PandocPath)) { $paramsForExport.PandocPath = $PandocPath }
  if ($ForceSignatures) { $paramsForExport.ForceSignatures = $true }

  & (Join-Path $PSScriptRoot "export_avis.ps1") @paramsForExport
} finally {
  if ($null -eq $previousCssPath) {
    Remove-Item Env:\GN_AVIS_CSS_PATH -ErrorAction SilentlyContinue
  } else {
    $env:GN_AVIS_CSS_PATH = $previousCssPath
  }
  if ($null -eq $previousBlasonPath) {
    Remove-Item Env:\GN_AVIS_BLASON_PATH -ErrorAction SilentlyContinue
  } else {
    $env:GN_AVIS_BLASON_PATH = $previousBlasonPath
  }
  if ($null -eq $previousSignatureSeals) {
    Remove-Item Env:\GN_AVIS_SIGNATURE_SEALS -ErrorAction SilentlyContinue
  } else {
    $env:GN_AVIS_SIGNATURE_SEALS = $previousSignatureSeals
  }
  if ($null -eq $previousArchiveStampText) {
    Remove-Item Env:\GN_AVIS_ARCHIVE_STAMP_TEXT -ErrorAction SilentlyContinue
  } else {
    $env:GN_AVIS_ARCHIVE_STAMP_TEXT = $previousArchiveStampText
  }
}
