<#
  Export PDF des dossiers clandestins VIP.

  Base technique : export_doc.ps1.
  Contraintes :
    - aucun blason en en-tete ;
    - aucune ligne d'institution ;
    - aucune reference bancaire ajoutee par le script ;
    - export unitaire via -MarkdownPath ou export complet via -All.

  Exemples :
    .\Scripts\export_contrats_vip.ps1 -MarkdownPath "Groupes\Tripot\Contrats_VIP\DC-IV-542-001.md"
    .\Scripts\export_contrats_vip.ps1 -All
#>

[CmdletBinding(DefaultParameterSetName = 'ByPath')]
param(
  [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 0)]
  [string] $MarkdownPath,

  [Parameter(ParameterSetName = 'All', Mandatory = $true)]
  [switch] $All,

  [ValidateSet('A4', 'A3')]
  [string] $Format = 'A4',

  [switch] $SkipPdf,

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = "",

  [switch] $ForceSignatures
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$vipDir = Join-Path $root 'Groupes\Tripot\Contrats_VIP'
$exportDoc = Join-Path $PSScriptRoot 'export_doc.ps1'
$vipCss = Join-Path $PSScriptRoot 'contrats_vip_print.css'

if (-not (Test-Path -LiteralPath $exportDoc)) {
  Write-Error "Script introuvable : $exportDoc"
}
if (-not (Test-Path -LiteralPath $vipCss)) {
  Write-Error "CSS introuvable : $vipCss"
}

function Get-VipMarkdownFiles {
  if ($All) {
    return Get-ChildItem -LiteralPath $vipDir -Filter 'DC-IV-*.md' -File | Sort-Object Name
  }

  $resolved = Resolve-Path -LiteralPath $MarkdownPath
  $file = Get-Item -LiteralPath $resolved.Path
  if ($file.Name -notmatch '^DC-IV-.*\.md$') {
    Write-Error "Le fichier n'est pas un dossier clandestin DC-IV : $($file.FullName)"
  }
  return @($file)
}

$files = Get-VipMarkdownFiles
if (-not $files -or $files.Count -eq 0) {
  Write-Error "Aucun dossier DC-IV a exporter dans $vipDir"
}

foreach ($file in $files) {
  Write-Host "Export dossier clandestin VIP : $($file.FullName)"

  $params = @{
    MarkdownPath = $file.FullName
    Format = $Format
    Browser = $Browser
    InstitutionLigne = ''
    SkipH2PageBreak = $true
    Landscape = $true
    ExtraCssPath = $vipCss
    SignatureMaxEdgePx = 110
  }
  if ($SkipPdf) { $params.SkipPdf = $true }
  if (-not [string]::IsNullOrWhiteSpace($ChromePath)) { $params.ChromePath = $ChromePath }
  if (-not [string]::IsNullOrWhiteSpace($PandocPath)) { $params.PandocPath = $PandocPath }
  if ($ForceSignatures) { $params.ForceSignatures = $true }

  & $exportDoc @params
}
