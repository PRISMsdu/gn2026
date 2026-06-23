<#
  Regenere les PDF anciens listes dans Groupes/suivides envois.md,
  prepare les brouillons Outlook avec les nouvelles versions, supprime les anciens
  PDF remplaces, puis met a jour le suivi avec la date de preparation email.

  Usage depuis la racine du depot :
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts\regenerer_pdfs_anciens_et_preparer_mails.ps1"

  Options utiles :
    -Mode Display   Ouvre les mails au lieu de creer des brouillons.
    -DryRun         Affiche les roles concernes sans exporter, envoyer ni supprimer.
#>

[CmdletBinding()]
param(
  [ValidateSet('Draft', 'Display')]
  [string] $Mode = 'Draft',

  [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$groupesRoot = Join-Path $repoRoot 'Groupes'
$trackingScript = Join-Path $repoRoot 'Groupes\suivi_envois.py'
$trackingFile = Join-Path $repoRoot 'Groupes\suivides envois.md'
$regenerateJsonFile = Join-Path $repoRoot 'Groupes\suivi_a_regenerer.json'
$emailLogFile = Join-Path $repoRoot 'Groupes\suivi_envois_emails.json'
$exportScript = Join-Path $repoRoot 'Scripts\export_back_groupe.ps1'
$mailScript = Join-Path $repoRoot 'Scripts\preparer_mails_roles.ps1'

function Split-MarkdownTableRow {
  param([string] $Line)

  $trimmed = $Line.Trim()
  if ($trimmed.StartsWith('|')) {
    $trimmed = $trimmed.Substring(1)
  }
  if ($trimmed.EndsWith('|')) {
    $trimmed = $trimmed.Substring(0, $trimmed.Length - 1)
  }

  return @($trimmed -split '\s*\|\s*' | ForEach-Object { $_.Trim() })
}

function Get-RepositoryRelativePath {
  param([string] $AbsolutePath)

  $rootWithSeparator = $repoRoot
  if (-not $rootWithSeparator.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $rootWithSeparator += [System.IO.Path]::DirectorySeparatorChar
  }

  $rootUri = New-Object System.Uri $rootWithSeparator
  $pathUri = New-Object System.Uri $AbsolutePath
  $relative = [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString())
  return ($relative -replace '\\', '/')
}

function Get-NormalizedStem {
  param([System.IO.FileInfo] $File)

  return ($File.BaseName -replace '_[0-9]{8}_[0-9]{6}$', '').ToLowerInvariant()
}

function Get-LatestRolePdf {
  param([System.IO.FileInfo] $MarkdownFile)

  $mdStem = $MarkdownFile.BaseName.ToLowerInvariant()
  Get-ChildItem -LiteralPath $MarkdownFile.DirectoryName -File -Filter "$($MarkdownFile.BaseName)*.pdf" |
    Where-Object { (Get-NormalizedStem -File $_) -eq $mdStem } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Read-EmailLog {
  if (-not (Test-Path -LiteralPath $emailLogFile)) {
    return @{}
  }

  $raw = Get-Content -LiteralPath $emailLogFile -Raw -Encoding UTF8
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return @{}
  }

  $parsed = $raw | ConvertFrom-Json
  if ($null -eq $parsed) {
    return @{}
  }

  $log = @{}
  foreach ($property in $parsed.PSObject.Properties) {
    $log[$property.Name] = $property.Value
  }

  return $log
}

function Write-EmailLog {
  param([hashtable] $Log)

  $Log |
    ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath $emailLogFile -Encoding UTF8
}

function Get-RowsToRegenerate {
  if (-not (Test-Path -LiteralPath $regenerateJsonFile)) {
    Write-Error "Fichier JSON introuvable : $regenerateJsonFile (executer d'abord Groupes/suivi_envois.py)"
  }

  $raw = Get-Content -LiteralPath $regenerateJsonFile -Raw -Encoding UTF8
  $parsed = $raw | ConvertFrom-Json
  if ($null -eq $parsed) {
    return @()
  }

  $rows = @()
  foreach ($entry in @($parsed)) {
    $rows += [pscustomobject]@{
      Status = $entry.status
      MarkdownPath = $entry.markdown_path
      OldPdfPath = if ($entry.old_pdf_path) { $entry.old_pdf_path } else { '-' }
    }
  }

  return $rows
}

Push-Location $repoRoot
try {
  python $trackingScript
  $outdatedRows = @(Get-RowsToRegenerate)

  if ($outdatedRows.Count -eq 0) {
    Write-Host "Aucun role a regenerer dans le suivi."
    return
  }

  Write-Host "Roles a regenerer : $($outdatedRows.Count)"
  foreach ($row in $outdatedRows) {
    Write-Host "- [$($row.Status)] $($row.MarkdownPath)"
  }

  if ($DryRun) {
    Write-Host "DryRun actif : aucun export, mail ou suppression."
    return
  }

  $emailLog = Read-EmailLog

  foreach ($row in $outdatedRows) {
    $mdAbsolute = Join-Path $groupesRoot ($row.MarkdownPath -replace '/', '\')
    $oldPdfAbsolute = Join-Path $groupesRoot ($row.OldPdfPath -replace '/', '\')

    if (-not (Test-Path -LiteralPath $mdAbsolute)) {
      Write-Warning "MD introuvable, ignore : $($row.MarkdownPath)"
      continue
    }

    $mdFile = Get-Item -LiteralPath $mdAbsolute
    $oldPdf = if (Test-Path -LiteralPath $oldPdfAbsolute) { Get-Item -LiteralPath $oldPdfAbsolute } else { $null }

    Write-Host "Export PDF : $($row.MarkdownPath)"
    $exportMarkdownPath = Join-Path 'Groupes' ($row.MarkdownPath -replace '/', '\')
    powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript -MarkdownPath $exportMarkdownPath

    $newPdf = Get-LatestRolePdf -MarkdownFile $mdFile
    if ($null -eq $newPdf) {
      Write-Error "Aucun nouveau PDF trouve pour $($row.MarkdownPath)"
    }
    if ($newPdf.LastWriteTime -lt $mdFile.LastWriteTime) {
      Write-Error "Le PDF le plus recent reste ancien pour $($row.MarkdownPath) : $($newPdf.FullName)"
    }

    Write-Host "Preparation mail ($Mode) : $($row.MarkdownPath)"
    powershell -NoProfile -ExecutionPolicy Bypass -File $mailScript -RolePath $exportMarkdownPath -Mode $Mode
    $preparedAt = Get-Date

    if ($null -ne $oldPdf -and $oldPdf.FullName -ne $newPdf.FullName -and (Test-Path -LiteralPath $oldPdf.FullName)) {
      Remove-Item -LiteralPath $oldPdf.FullName -Force
      Write-Host "Ancien PDF supprime : $(Get-RepositoryRelativePath -AbsolutePath $oldPdf.FullName)"
    }

    $mdRelative = $row.MarkdownPath
    $emailLog[$mdRelative] = @{
      prepared_at = $preparedAt.ToString('yyyy-MM-dd HH:mm:ss')
      pdf_path = Get-RepositoryRelativePath -AbsolutePath $newPdf.FullName
      pdf_date = $newPdf.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    }
  }

  Write-EmailLog -Log $emailLog
  python $trackingScript
  Write-Host "Suivi mis a jour : Groupes/suivides envois.md"
}
finally {
  Pop-Location
}
