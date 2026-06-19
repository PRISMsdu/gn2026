<#
  Exporte en PDF les contrats courants references dans registre_UBI_Contrats_courant.md.

  Par defaut :
  - lit Groupes\Banquiers - UBI\3- Compta & registres\registre_UBI_Contrats_courant.md ;
  - exporte les references qui ont un fichier .md dans Contrats_et_Livres (hors Archives) ;
  - ignore les contrats qui ont deja un PDF {ref}_avis_*.pdf ou {ref}_doc_*.pdf ;
  - statut cloture -> export_avis_archives.ps1 (sceaux + tampon) ;
  - contrats ouverts -> export_avis_noncloture.ps1 (sceaux, sans tampon) ;
  - correspondances / fragments sans signatures -> export_doc.ps1 + lettre_manuscrite_print.css.

  Exemple :
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts/export_contrats_courant_registre.ps1"
#>

[CmdletBinding()]
param(
  [string] $ContratsDir = "Contrats_et_Livres",

  [string] $RegistrePath = "Groupes\Banquiers - UBI\3- Compta & registres\registre_UBI_Contrats_courant.md",

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = "",

  [switch] $Force,

  [switch] $WhatIfOnly
)

$ErrorActionPreference = 'Stop'

$ClosedStatuses = @(
  'Exécuté, soldé, classé',
  'Exécuté, remboursé, classé'
)

$LetterRefs = @(
  'CP-III-543-001',
  'CP-III-546-002',
  'CC-III-544-002',
  'CC-II-545-004',
  'FL-III-545-002',
  'RD-III-543-004'
)

function Test-StatutCloture {
  param([string] $Statut)
  if ([string]::IsNullOrWhiteSpace($Statut)) { return $false }
  if ($ClosedStatuses -contains $Statut) { return $true }
  return ($Statut -match 'Ex.cut., (sold|rembours)., class')
}

function Get-RegistreStatuts {
  param([string] $RegistreFile)
  $statuts = @{}
  $lines = Get-Content -LiteralPath $RegistreFile -Encoding UTF8
  foreach ($line in $lines) {
    if ($line -notmatch '^\|\s*(?<ref>[A-Z]{2,3}-[IV]+-\d{3}-\d{3})\s*\|') { continue }
    $parts = ($line -split '\|') | ForEach-Object { $_.Trim() }
    if ($parts.Count -ge 9) {
      $statuts[$parts[1]] = $parts[8]
    }
  }
  return $statuts
}

function Get-ExportKind {
  param(
    [string] $Reference,
    [bool] $Cloture
  )
  if ($LetterRefs -contains $Reference) { return 'lettre' }
  if ($Cloture) { return 'archives' }
  return 'non-cloture'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$contratsPath = Resolve-Path -LiteralPath (Join-Path $repoRoot $ContratsDir)
$registreAbs = Resolve-Path -LiteralPath (Join-Path $repoRoot $RegistrePath)
$exportArchives = Join-Path $PSScriptRoot 'export_avis_archives.ps1'
$exportNonCloture = (Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'export_avis_nonclotur*.ps1' |
  Select-Object -First 1).FullName
$exportDoc = Join-Path $PSScriptRoot 'export_doc.ps1'
$lettreCss = Join-Path $PSScriptRoot 'lettre_manuscrite_print.css'

foreach ($script in @($exportArchives, $exportNonCloture, $exportDoc)) {
  if (-not (Test-Path -LiteralPath $script)) {
    Write-Error "Script d'export introuvable : $script"
  }
}

$statuts = Get-RegistreStatuts -RegistreFile $registreAbs.Path
$registre = Get-Content -LiteralPath $registreAbs.Path -Raw -Encoding UTF8
$referenceMatches = [regex]::Matches($registre, '\|\s*(?<ref>[A-Z]{2,3}-[IV]+-\d{3}-\d{3})\s*\|')
$references = [System.Collections.Generic.List[string]]::new()
$seen = @{}

foreach ($match in $referenceMatches) {
  $ref = $match.Groups['ref'].Value
  if ($seen.ContainsKey($ref)) { continue }
  $seen[$ref] = $true
  [void]$references.Add($ref)
}

$toExport = [System.Collections.Generic.List[object]]::new()
$missingMarkdown = [System.Collections.Generic.List[string]]::new()
$skippedPdf = 0

foreach ($ref in $references) {
  $mdPath = Join-Path $contratsPath.Path ($ref + '.md')
  if (-not (Test-Path -LiteralPath $mdPath)) {
    [void]$missingMarkdown.Add($ref)
    continue
  }

  $existingAvis = Get-ChildItem -LiteralPath $contratsPath.Path -Filter ($ref + '_avis_*.pdf') -ErrorAction SilentlyContinue
  $existingDoc = Get-ChildItem -LiteralPath $contratsPath.Path -Filter ($ref + '_doc_*.pdf') -ErrorAction SilentlyContinue
  if (($existingAvis.Count -gt 0 -or $existingDoc.Count -gt 0) -and -not $Force) {
    $skippedPdf++
    continue
  }

  $statut = $statuts[$ref]
  $cloture = Test-StatutCloture -Statut $statut
  $kind = Get-ExportKind -Reference $ref -Cloture $cloture
  [void]$toExport.Add([pscustomobject]@{
      Reference = $ref
      Markdown  = (Get-Item -LiteralPath $mdPath)
      Statut    = $statut
      Cloture   = $cloture
      Kind      = $kind
    })
}

Write-Host "References registre retenues : $($references.Count)"
Write-Host "Markdown manquants : $($missingMarkdown.Count)"
Write-Host "PDF deja presents ignores : $skippedPdf"
Write-Host "Exports a lancer : $($toExport.Count)"
Write-Host "  archives (clotures) : $(@($toExport | Where-Object Kind -eq 'archives').Count)"
Write-Host "  non-cloture : $(@($toExport | Where-Object Kind -eq 'non-cloture').Count)"
Write-Host "  lettres : $(@($toExport | Where-Object Kind -eq 'lettre').Count)"

if ($missingMarkdown.Count -gt 0) {
  Write-Warning ("References sans Markdown : " + (($missingMarkdown | Select-Object -First 20) -join ', '))
}

if ($WhatIfOnly) {
  $toExport | ForEach-Object {
    Write-Host ("{0} [{1}] {2}" -f $_.Reference, $_.Kind, $_.Statut)
  }
  return
}

$done = 0
foreach ($job in $toExport) {
  $done++
  Write-Host "[$done/$($toExport.Count)] Export ($($job.Kind)) : $($job.Reference) - $($job.Statut)"

  if ($job.Kind -eq 'lettre') {
    $exportScript = $exportDoc
    $exportArgs = @(
      '-NoProfile', '-ExecutionPolicy', 'Bypass',
      '-File', $exportScript,
      '-MarkdownPath', $job.Markdown.FullName,
      '-Browser', $Browser,
      '-ExtraCssPath', $lettreCss
    )
  } else {
    $exportScript = if ($job.Kind -eq 'archives') { $exportArchives } else { $exportNonCloture }
    $exportArgs = @(
      '-NoProfile', '-ExecutionPolicy', 'Bypass',
      '-File', $exportScript,
      '-MarkdownPath', $job.Markdown.FullName,
      '-Browser', $Browser
    )
  }

  if (-not [string]::IsNullOrWhiteSpace($ChromePath)) {
    $exportArgs += @('-ChromePath', $ChromePath)
  }
  if (-not [string]::IsNullOrWhiteSpace($PandocPath)) {
    $exportArgs += @('-PandocPath', $PandocPath)
  }

  & powershell @exportArgs
}

Write-Host "Exports termines : $done"
