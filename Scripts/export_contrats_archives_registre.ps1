<#
  Exporte en PDF les contrats d'archives référencés dans registre_archives.md.

  Par défaut :
  - lit Contrats_et_Livres\Archives\registre_archives.md ;
  - exporte les références qui ont un fichier .md correspondant dans Archives ;
  - exclut les PAR-I, déjà exportés avec leur script dédié ;
  - ignore les contrats qui ont déjà un PDF dont le nom commence par la référence.

  Exemple :
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts/export_contrats_archives_registre.ps1"
#>

[CmdletBinding()]
param(
  [string] $ArchivesDir = "Contrats_et_Livres\Archives",

  [string] $RegistrePath = "Contrats_et_Livres\Archives\registre_archives.md",

  [string[]] $ExcludeReferencePrefixes = @('PAR-I-'),

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = "",

  [switch] $Force,

  [switch] $WhatIfOnly
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$archivePath = Resolve-Path -LiteralPath (Join-Path $repoRoot $ArchivesDir)
$registreAbs = Resolve-Path -LiteralPath (Join-Path $repoRoot $RegistrePath)
$exportScript = Join-Path $PSScriptRoot 'export_avis_archives.ps1'

if (-not (Test-Path -LiteralPath $exportScript)) {
  Write-Error "Script d'export introuvable : $exportScript"
}

$registre = Get-Content -LiteralPath $registreAbs.Path -Raw -Encoding UTF8
$referenceMatches = [regex]::Matches($registre, '\|\s*(?<ref>[A-Z]{2,3}-[IV]+-\d{3}-\d{3})\s*\|')
$references = [System.Collections.Generic.List[string]]::new()
$seen = @{}

foreach ($match in $referenceMatches) {
  $ref = $match.Groups['ref'].Value
  if ($seen.ContainsKey($ref)) { continue }
  $seen[$ref] = $true

  $excluded = $false
  foreach ($prefix in $ExcludeReferencePrefixes) {
    if ($ref.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
      $excluded = $true
      break
    }
  }
  if (-not $excluded) {
    [void]$references.Add($ref)
  }
}

$toExport = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$missingMarkdown = [System.Collections.Generic.List[string]]::new()
$skippedPdf = 0

foreach ($ref in $references) {
  $mdPath = Join-Path $archivePath.Path ($ref + '.md')
  if (-not (Test-Path -LiteralPath $mdPath)) {
    [void]$missingMarkdown.Add($ref)
    continue
  }

  $existingPdf = Get-ChildItem -LiteralPath $archivePath.Path -Filter ($ref + '*.pdf') -ErrorAction SilentlyContinue
  if ($existingPdf.Count -gt 0 -and -not $Force) {
    $skippedPdf++
    continue
  }

  [void]$toExport.Add((Get-Item -LiteralPath $mdPath))
}

Write-Host "Références registre retenues : $($references.Count)"
Write-Host "Markdown manquants : $($missingMarkdown.Count)"
Write-Host "PDF déjà présents ignorés : $skippedPdf"
Write-Host "Exports à lancer : $($toExport.Count)"

if ($missingMarkdown.Count -gt 0) {
  Write-Warning ("Références sans Markdown : " + (($missingMarkdown | Select-Object -First 20) -join ', '))
}

if ($WhatIfOnly) {
  $toExport | ForEach-Object { Write-Host $_.Name }
  return
}

$done = 0
foreach ($contract in $toExport) {
  $done++
  Write-Host "[$done/$($toExport.Count)] Export : $($contract.Name)"

  $exportArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $exportScript,
    '-MarkdownPath', $contract.FullName,
    '-Browser', $Browser
  )
  if (-not [string]::IsNullOrWhiteSpace($ChromePath)) {
    $exportArgs += @('-ChromePath', $ChromePath)
  }
  if (-not [string]::IsNullOrWhiteSpace($PandocPath)) {
    $exportArgs += @('-PandocPath', $PandocPath)
  }

  & powershell @exportArgs
}

Write-Host "Exports terminés : $done"
