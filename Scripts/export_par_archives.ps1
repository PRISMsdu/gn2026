<#
  Exporte en PDF tous les contrats PAR-I des archives.

  Le script s'appuie sur export_doc_compact_signatures.ps1, qui réutilise la
  charte officielle et force l'option -nochangepage pour éviter les sauts de
  page à chaque titre. Les PDF sont déposés dans le même répertoire que les
  Markdown, sous forme stable : PAR-I-YYY-NNN.pdf.

  Exemple :
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts/export_par_archives.ps1"
#>

[CmdletBinding()]
param(
  [string] $ArchivesDir = "Contrats_et_Livres\Archives",

  [string] $InstitutionLigne = "Confédération des cités libres du Levant",

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = "",

  [switch] $Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$archivePath = Resolve-Path -LiteralPath (Join-Path $repoRoot $ArchivesDir)
$exportScript = Join-Path $PSScriptRoot 'export_doc_compact_signatures.ps1'

if (-not (Test-Path -LiteralPath $exportScript)) {
  Write-Error "Script d'export introuvable : $exportScript"
}

$contracts = Get-ChildItem -LiteralPath $archivePath.Path -Filter 'PAR-I-*.md' |
  Sort-Object Name

if ($contracts.Count -eq 0) {
  Write-Error "Aucun contrat PAR-I trouvé dans $($archivePath.Path)"
}

foreach ($contract in $contracts) {
  $stablePdf = Join-Path $contract.DirectoryName ($contract.BaseName + '.pdf')
  if ((Test-Path -LiteralPath $stablePdf) -and -not $Force) {
    Write-Host "PDF déjà présent, ignoré : $stablePdf"
    continue
  }

  $before = @{}
  Get-ChildItem -LiteralPath $contract.DirectoryName -Filter ($contract.BaseName + '_doc_compact_*.pdf') |
    ForEach-Object { $before[$_.FullName] = $true }

  $exportArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', $exportScript,
    '-MarkdownPath', $contract.FullName,
    '-InstitutionLigne', $InstitutionLigne,
    '-Browser', $Browser
  )
  if (-not [string]::IsNullOrWhiteSpace($ChromePath)) {
    $exportArgs += @('-ChromePath', $ChromePath)
  }
  if (-not [string]::IsNullOrWhiteSpace($PandocPath)) {
    $exportArgs += @('-PandocPath', $PandocPath)
  }

  Write-Host "Export : $($contract.Name)"
  & powershell @exportArgs

  $generated = Get-ChildItem -LiteralPath $contract.DirectoryName -Filter ($contract.BaseName + '_doc_compact_*.pdf') |
    Where-Object { -not $before.ContainsKey($_.FullName) } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if (-not $generated) {
    Write-Error "PDF généré introuvable pour $($contract.Name)"
  }

  Move-Item -LiteralPath $generated.FullName -Destination $stablePdf -Force
  Write-Host "PDF : $stablePdf"
}
