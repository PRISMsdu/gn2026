<#
  Imprime des contrats d'archives UBI par lots, avec suivi dans registre_impressions.md.

  Par défaut :
  - lit les références dans Groupes\Banquiers - UBI\3- Compta & registres\registre_UBI_Contrats_archives.md ;
  - cherche le PDF le plus récent {ref}_avis_*.pdf dans Archives ;
  - ignore les références déjà notées dans registre_impressions.md ;
  - envoie un lot de 10, 20 ou 30 contrats à l'imprimante.

  Exemples :
    # Premier test — une référence et un PDF précis
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts/imprimer_contrats_archives.ps1" `
      -Reference AL-IV-525-005 `
      -PdfPath "Contrats_et_Livres\Archives\AL-IV-525-005_avis_20260610_001231.pdf"

    # Lot de 10 prochains contrats non imprimés
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts/imprimer_contrats_archives.ps1" -LotSize 10

    # Aperçu sans impression ni mise à jour du registre
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts/imprimer_contrats_archives.ps1" -LotSize 20 -WhatIfOnly

    # Lister les contrats en attente d'impression
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts/imprimer_contrats_archives.ps1" -ListeEnAttente
#>

[CmdletBinding()]
param(
  [ValidateRange(1, 500)]
  [int] $LotSize = 10,

  [string] $ArchivesDir = "Contrats_et_Livres\Archives",

  [string] $RegistrePath = "Groupes\Banquiers - UBI\3- Compta & registres\registre_UBI_Contrats_archives.md",

  [string] $RegistreImpressionsPath = "Groupes\Banquiers - UBI\3- Compta & registres\registre_impressions.md",

  [string[]] $Reference = @(),

  [string] $PdfPath = "",

  [string] $Printer = "",

  [switch] $Force,

  [switch] $WhatIfOnly,

  [switch] $ListeEnAttente,

  [int] $DelaiSpouleurSecondes = 5
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

function Get-LatestArchivePdf {
  param(
    [string] $ArchiveDir,
    [string] $Reference
  )
  $pdfs = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
  foreach ($pattern in @(
      ($Reference + '_avis_*.pdf')
      ($Reference + '_doc_*.pdf')
      ($Reference + '.pdf')
    )) {
    Get-ChildItem -LiteralPath $ArchiveDir -Filter $pattern -File -ErrorAction SilentlyContinue |
      ForEach-Object { [void]$pdfs.Add($_) }
  }
  if ($pdfs.Count -eq 0) { return $null }
  return ($pdfs | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
}

function Get-SumatraPdfPath {
  $candidates = @(
    (Join-Path $env:ProgramFiles 'SumatraPDF\SumatraPDF.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'SumatraPDF\SumatraPDF.exe'),
    (Join-Path $env:LOCALAPPDATA 'SumatraPDF\SumatraPDF.exe')
  )
  foreach ($path in $candidates) {
    if (Test-Path -LiteralPath $path) { return $path }
  }
  return $null
}

function Get-AcrobatReaderPath {
  $candidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Adobe\Acrobat Reader DC\Reader\AcroRd32.exe'),
    (Join-Path $env:ProgramFiles 'Adobe\Acrobat Reader DC\Reader\AcroRd32.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Adobe\Acrobat Reader\Reader\AcroRd32.exe'),
    (Join-Path $env:ProgramFiles 'Adobe\Acrobat Reader\Reader\AcroRd32.exe')
  )
  foreach ($path in $candidates) {
    if (Test-Path -LiteralPath $path) { return $path }
  }
  return $null
}

function Send-PdfToPrinter {
  param(
    [string] $PdfAbsolutePath,
    [string] $PrinterName = "",
    [int] $DelaiSpouleurSecondes = 5
  )

  $sumatra = Get-SumatraPdfPath
  if ($sumatra) {
    $args = @('-silent')
    if (-not [string]::IsNullOrWhiteSpace($PrinterName)) {
      $args += @('-print-to', $PrinterName)
    } else {
      $args += '-print-to-default'
    }
    $args += $PdfAbsolutePath
    & $sumatra @args
    if ($LASTEXITCODE -ne 0) {
      throw "SumatraPDF a renvoyé le code $LASTEXITCODE pour $PdfAbsolutePath"
    }
    return 'SumatraPDF'
  }

  $acrobat = Get-AcrobatReaderPath
  if ($acrobat) {
    $args = @('/h', '/t', $PdfAbsolutePath)
    if (-not [string]::IsNullOrWhiteSpace($PrinterName)) {
      $args += $PrinterName
    }
    Start-Process -FilePath $acrobat -ArgumentList $args -WindowStyle Hidden | Out-Null
    Start-Sleep -Seconds $DelaiSpouleurSecondes
    return 'Adobe Reader'
  }

  if (-not [string]::IsNullOrWhiteSpace($PrinterName)) {
    throw "Imprimante nommée « $PrinterName » demandée mais SumatraPDF est absent. Installez SumatraPDF ou retirez -Printer."
  }

  Start-Process -FilePath $PdfAbsolutePath -Verb Print | Out-Null
  Start-Sleep -Seconds $DelaiSpouleurSecondes
  return 'Application par défaut'
}

function New-LotId {
  param([string] $ImpressionsFile)
  $today = Get-Date -Format 'yyyyMMdd'
  $count = 0
  if (Test-Path -LiteralPath $ImpressionsFile) {
    $content = Get-Content -LiteralPath $ImpressionsFile -Raw -Encoding UTF8
    $count = ([regex]::Matches($content, "\|\s*lot-$today-\d{3}\s*\|")).Count
  }
  return ('lot-{0}-{1:D3}' -f $today, ($count + 1))
}

function Add-ImpressionRecord {
  param(
    [string] $ImpressionsFile,
    [string] $Reference,
    [string] $PdfFileName,
    [string] $LotId
  )

  $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
  $line = "| $Reference | $PdfFileName | $stamp | $LotId |"
  $content = Get-Content -LiteralPath $ImpressionsFile -Raw -Encoding UTF8

  if ($content -notlike '*Fichier PDF*') {
    throw "Format inattendu dans $ImpressionsFile"
  }

  $newContent = $content.TrimEnd() + "`n" + $line + "`n"
  [System.IO.File]::WriteAllText($ImpressionsFile, $newContent, [System.Text.UTF8Encoding]::new($false))
}

$repoRoot = Get-RepoRoot -ScriptsDir $PSScriptRoot
$archiveAbs = (Resolve-Path -LiteralPath (Join-Path $repoRoot $ArchivesDir)).Path
$registreAbs = (Resolve-Path -LiteralPath (Join-Path $repoRoot $RegistrePath)).Path
$impressionsAbs = Join-Path $repoRoot $RegistreImpressionsPath

if (-not (Test-Path -LiteralPath $impressionsAbs)) {
  throw "Registre d'impressions introuvable : $impressionsAbs"
}

$allRefs = Get-RegistreReferences -RegistreFile $registreAbs
$printed = Get-PrintedReferences -ImpressionsFile $impressionsAbs

$jobs = [System.Collections.Generic.List[object]]::new()

if ($Reference.Count -gt 0) {
  foreach ($ref in $Reference) {
    if ($printed.ContainsKey($ref) -and -not $Force) {
      Write-Warning "Déjà imprimé (ignoré) : $ref. Utilisez -Force pour réimprimer."
      continue
    }

    $pdfItem = $null
    if (-not [string]::IsNullOrWhiteSpace($PdfPath) -and $Reference.Count -eq 1) {
      $pdfCandidate = if ([System.IO.Path]::IsPathRooted($PdfPath)) { $PdfPath } else { Join-Path $repoRoot $PdfPath }
      if (-not (Test-Path -LiteralPath $pdfCandidate)) {
        throw "PDF introuvable : $pdfCandidate"
      }
      $pdfItem = Get-Item -LiteralPath $pdfCandidate
      if (-not $pdfItem.Name.StartsWith($ref, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Warning "Le PDF $($pdfItem.Name) ne commence pas par la référence $ref."
      }
    } else {
      $pdfItem = Get-LatestArchivePdf -ArchiveDir $archiveAbs -Reference $ref
      if (-not $pdfItem) {
        Write-Warning "Aucun PDF pour $ref"
        continue
      }
    }

    [void]$jobs.Add([pscustomobject]@{
        Reference = $ref
        Pdf       = $pdfItem
      })
  }
} else {
  foreach ($ref in $allRefs) {
    if ($printed.ContainsKey($ref) -and -not $Force) { continue }
    $pdfItem = Get-LatestArchivePdf -ArchiveDir $archiveAbs -Reference $ref
    if (-not $pdfItem) { continue }
    [void]$jobs.Add([pscustomobject]@{
        Reference = $ref
        Pdf       = $pdfItem
      })
    if ($jobs.Count -ge $LotSize) { break }
  }
}

if ($ListeEnAttente) {
  $pending = [System.Collections.Generic.List[object]]::new()
  foreach ($ref in $allRefs) {
    if ($printed.ContainsKey($ref)) { continue }
    $pdfItem = Get-LatestArchivePdf -ArchiveDir $archiveAbs -Reference $ref
    if (-not $pdfItem) { continue }
    [void]$pending.Add([pscustomobject]@{
        Reference = $ref
        Pdf       = $pdfItem.Name
      })
  }
  Write-Host "Contrats en attente d'impression : $($pending.Count)"
  $pending | ForEach-Object { Write-Host ("  {0} -> {1}" -f $_.Reference, $_.Pdf) }
  return
}

if ($jobs.Count -eq 0) {
  Write-Host "Aucun contrat à imprimer."
  return
}

$lotId = New-LotId -ImpressionsFile $impressionsAbs
Write-Host "Lot : $lotId"
Write-Host "Contrats retenus : $($jobs.Count)"

foreach ($job in $jobs) {
  Write-Host ("  {0} -> {1}" -f $job.Reference, $job.Pdf.Name)
}

if ($WhatIfOnly) {
  Write-Host "WhatIf : aucune impression, registre inchangé."
  return
}

$method = $null
$done = 0
foreach ($job in $jobs) {
  $done++
  Write-Host "[$done/$($jobs.Count)] Impression : $($job.Reference)"
  $method = Send-PdfToPrinter -PdfAbsolutePath $job.Pdf.FullName -PrinterName $Printer -DelaiSpouleurSecondes $DelaiSpouleurSecondes
  Add-ImpressionRecord -ImpressionsFile $impressionsAbs -Reference $job.Reference -PdfFileName $job.Pdf.Name -LotId $lotId
}

Write-Host "Impression terminée : $done contrat(s) via $method"
Write-Host "Registre mis à jour : $impressionsAbs"
