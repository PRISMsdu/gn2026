<#
  Liste les contrats UBI en attente d'impression physique (sans imprimer).

  Par défaut : archives + courant.

  Exemples (depuis la racine du dépôt) :
    .\Scripts\lister_contrats_a_imprimer.ps1
    .\Scripts\lister_contrats_a_imprimer.ps1 -ArchivesOnly
    .\Scripts\lister_contrats_a_imprimer.ps1 -CourantOnly
#>

[CmdletBinding(DefaultParameterSetName = 'All')]
param(
  [Parameter(ParameterSetName = 'Archives')]
  [switch] $ArchivesOnly,

  [Parameter(ParameterSetName = 'Courant')]
  [switch] $CourantOnly
)

$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
  param([string] $ScriptsDir)
  Split-Path -Parent $ScriptsDir
}

function Get-RegistreReferences {
  param([string] $RegistreFile)
  $content = Get-Content -LiteralPath $RegistreFile -Raw -Encoding UTF8
  $matches = [regex]::Matches($content, '\|\s*(?<ref>[A-Z]{2,3}-[IV]+-\d{3}-\d{3})\s*\|')
  $refs = [System.Collections.Generic.List[string]]::new()
  $seen = @{}
  foreach ($m in $matches) {
    $ref = $m.Groups['ref'].Value
    if ($seen.ContainsKey($ref)) { continue }
    $seen[$ref] = $true
    [void]$refs.Add($ref)
  }
  return $refs
}

function Get-PrintedReferences {
  param([string] $ImpressionsFile)
  if (-not (Test-Path -LiteralPath $ImpressionsFile)) {
    return @{}
  }
  $content = Get-Content -LiteralPath $ImpressionsFile -Raw -Encoding UTF8
  $printed = @{}
  foreach ($m in [regex]::Matches($content, '\|\s*(?<ref>[A-Z]{2,3}-[IV]+-\d{3}-\d{3})\s*\|')) {
    $printed[$m.Groups['ref'].Value] = $true
  }
  return $printed
}

function Get-LatestContractPdf {
  param(
    [string] $SearchDir,
    [string] $Reference
  )
  $pdfs = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
  foreach ($pattern in @(
      ($Reference + '_avis_*.pdf')
      ($Reference + '_doc_*.pdf')
      ($Reference + '.pdf')
    )) {
    Get-ChildItem -LiteralPath $SearchDir -Filter $pattern -File -ErrorAction SilentlyContinue |
      ForEach-Object { [void]$pdfs.Add($_) }
  }
  if ($pdfs.Count -eq 0) { return $null }
  return ($pdfs | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
}

function Get-PrintQueue {
  param(
    [string] $Label,
    [string] $PdfDir,
    [string] $RegistrePath,
    [string] $RegistreImpressionsPath
  )

  $registreAbs = (Resolve-Path -LiteralPath $RegistrePath).Path
  $pdfDirAbs = (Resolve-Path -LiteralPath $PdfDir).Path
  $impressionsAbs = if ([System.IO.Path]::IsPathRooted($RegistreImpressionsPath)) {
    $RegistreImpressionsPath
  } else {
    Join-Path (Get-RepoRoot -ScriptsDir $PSScriptRoot) $RegistreImpressionsPath
  }

  $allRefs = Get-RegistreReferences -RegistreFile $registreAbs
  $printed = Get-PrintedReferences -ImpressionsFile $impressionsAbs

  $pending = [System.Collections.Generic.List[object]]::new()
  $missingPdf = [System.Collections.Generic.List[string]]::new()

  foreach ($ref in $allRefs) {
    if ($printed.ContainsKey($ref)) { continue }

    $pdfItem = Get-LatestContractPdf -SearchDir $pdfDirAbs -Reference $ref
    if (-not $pdfItem) {
      [void]$missingPdf.Add($ref)
      continue
    }

    [void]$pending.Add([pscustomobject]@{
        Reference = $ref
        Pdf       = $pdfItem.Name
      })
  }

  return [pscustomobject]@{
    Label         = $Label
    Registre      = $registreAbs
    Impressions   = $impressionsAbs
    PdfDir        = $pdfDirAbs
    Total         = $allRefs.Count
    DejaImprime   = $printed.Count
    EnAttente     = $pending.Count
    SansPdf       = $missingPdf.Count
    Pending       = $pending
    MissingPdf    = $missingPdf
  }
}

function Write-PrintQueueReport {
  param([object] $Queue)

  Write-Host ""
  Write-Host ("=== {0} ===" -f $Queue.Label)
  Write-Host ("Registre      : {0}" -f $Queue.Registre)
  Write-Host ("Suivi impress.: {0}" -f $Queue.Impressions)
  Write-Host ("Dossier PDF   : {0}" -f $Queue.PdfDir)
  Write-Host ("Total registre: {0}" -f $Queue.Total)
  Write-Host ("Déjà imprimé  : {0}" -f $Queue.DejaImprime)
  Write-Host ("En attente    : {0}" -f $Queue.EnAttente)
  Write-Host ("Sans PDF      : {0}" -f $Queue.SansPdf)

  if ($Queue.EnAttente -gt 0) {
    Write-Host ""
    Write-Host "Contrats à imprimer :"
    $Queue.Pending | ForEach-Object { Write-Host ("  {0} -> {1}" -f $_.Reference, $_.Pdf) }
  }

  if ($Queue.SansPdf -gt 0) {
    Write-Host ""
    Write-Host "Références sans PDF (export requis avant impression) :"
    $Queue.MissingPdf | ForEach-Object { Write-Host ("  {0}" -f $_) }
  }
}

$repoRoot = Get-RepoRoot -ScriptsDir $PSScriptRoot

$configs = @()

if ($PSCmdlet.ParameterSetName -in @('All', 'Archives')) {
  $configs += @{
    Label                   = 'Archives UBI'
    PdfDir                  = Join-Path $repoRoot 'Contrats_et_Livres\Archives'
    RegistrePath            = Join-Path $repoRoot 'Groupes\Banquiers - UBI\3- Compta & registres\registre_UBI_Contrats_archives.md'
    RegistreImpressionsPath = Join-Path $repoRoot 'Groupes\Banquiers - UBI\3- Compta & registres\registre_impressions.md'
  }
}

if ($PSCmdlet.ParameterSetName -in @('All', 'Courant')) {
  $configs += @{
    Label                   = 'Contrats courants UBI'
    PdfDir                  = Join-Path $repoRoot 'Contrats_et_Livres'
    RegistrePath            = Join-Path $repoRoot 'Groupes\Banquiers - UBI\3- Compta & registres\registre_UBI_Contrats_courant.md'
    RegistreImpressionsPath = Join-Path $repoRoot 'Groupes\Banquiers - UBI\3- Compta & registres\registre_impressions_courant.md'
  }
}

$queues = foreach ($cfg in $configs) {
  Get-PrintQueue @cfg
}

foreach ($queue in $queues) {
  Write-PrintQueueReport -Queue $queue
}

$totalPending = ($queues | Measure-Object -Property EnAttente -Sum).Sum
$totalMissing = ($queues | Measure-Object -Property SansPdf -Sum).Sum

Write-Host ""
Write-Host "=== Synthèse ==="
Write-Host ("À imprimer (total) : {0}" -f $totalPending)
Write-Host ("Sans PDF (total)   : {0}" -f $totalMissing)
Write-Host ""
Write-Host "Pour imprimer : Scripts\imprimer_contrats_archives.ps1"
