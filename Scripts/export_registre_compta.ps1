<#
  Export PDF "registre comptable manuscrit" pour les comptes du Tripot.

  Rendu : papier vergé, écriture manuelle (Caveat / Patrick Hand), tableaux
  sans bordures cellule par cellule (filets très tenus, lignes réglées).
  Par défaut : saut de page sur chaque <hr /> du markdown (typiquement une
  page par mois). Pour enchaîner les sections sans saut de page au changement
  de mois, d'année ou de titre : -nochangepage (ou -SkipHrPageBreak).

  Prérequis :
    - Pandoc dans le PATH (https://pandoc.org)
    - Google Chrome ou Microsoft Edge (impression PDF headless)
    - Accès internet au moment de la génération (Google Fonts)

  Exemples (depuis la racine du dépôt) :
    .\Scripts\export_registre_compta.ps1 -MarkdownPath "Groupes\Tripot\3 - Comptabilite\Registre_Tripot_UBI.md"
    .\Scripts\export_registre_compta.ps1 -MarkdownPath "Groupes\Tripot\3 - Comptabilite\Registre_VIP_Edorian.md"
    .\Scripts\export_registre_compta.ps1 -MarkdownPath "Groupes\Tripot\3 - Comptabilite\Registre_Matelas_Marda.md"
    .\Scripts\export_registre_compta.ps1 -MarkdownPath "Groupes\Tripot\3 - Comptabilite\Registre_Matelas_540.md" -nochangepage

  Sortie : PDF horodaté dans le même dossier que le .md.
#>

[CmdletBinding(DefaultParameterSetName = 'ByPath')]
param(
  [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 0)]
  [string] $MarkdownPath,

  [string] $OutputHtmlPath = "",

  [ValidateSet('A4', 'A3')]
  [string] $Format = 'A4',

  [switch] $SkipPdf,

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = "",

  [Alias('nochangepage')]
  [switch] $SkipHrPageBreak
)

$ErrorActionPreference = "Stop"

function ConvertTo-HtmlUriPath {
  param([string] $Path)
  return ($Path -replace '\\', '/')
}

function Get-RelativeUriPath {
  param(
    [string] $FromAbsoluteFile,
    [string] $ToAbsoluteFile
  )
  $fromDir = Split-Path -Parent $FromAbsoluteFile
  if (-not $fromDir.EndsWith('\')) { $fromDir += '\' }
  $fromUri = New-Object System.Uri $fromDir
  $toUri = New-Object System.Uri $ToAbsoluteFile
  $rel = $fromUri.MakeRelativeUri($toUri).ToString()
  return (ConvertTo-HtmlUriPath $rel)
}

function Get-PandocExecutable {
  param([string] $ExplicitPath)
  if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
    if (-not (Test-Path -LiteralPath $ExplicitPath)) {
      Write-Error "PandocPath introuvable : $ExplicitPath"
    }
    return (Resolve-Path -LiteralPath $ExplicitPath).Path
  }
  $cmd = Get-Command pandoc.exe -ErrorAction SilentlyContinue
  if (-not $cmd) { $cmd = Get-Command pandoc -ErrorAction SilentlyContinue }
  if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) {
    return $cmd.Source
  }
  foreach ($c in @(
      (Join-Path $env:ProgramFiles "Pandoc\pandoc.exe")
      (Join-Path ${env:ProgramFiles(x86)} "Pandoc\pandoc.exe")
    )) {
    if (Test-Path -LiteralPath $c) { return $c }
  }
  return $null
}

function Get-EdgeExecutable {
  $candidates = @(
    (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe")
    (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe")
  )
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { return $c }
  }
  return $null
}

function Get-ChromeFromRegistry {
  foreach ($key in @(
      'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'
      'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'
    )) {
    if (-not (Test-Path -LiteralPath $key)) { continue }
    try {
      $def = (Get-ItemProperty -LiteralPath $key -ErrorAction Stop).'(default)'
      if ([string]::IsNullOrWhiteSpace($def)) { continue }
      if (Test-Path -LiteralPath $def) { return $def }
    } catch { }
  }
  return $null
}

function Get-ChromeExecutable {
  if (-not [string]::IsNullOrWhiteSpace($script:ChromePathParam)) {
    $p = $script:ChromePathParam.Trim()
    if (-not (Test-Path -LiteralPath $p)) {
      Write-Error "ChromePath introuvable : $p"
    }
    return (Resolve-Path -LiteralPath $p).Path
  }

  foreach ($cmdName in @('chrome.exe', 'chrome')) {
    $fromPath = Get-Command $cmdName -ErrorAction SilentlyContinue
    if ($fromPath -and $fromPath.Source -and (Test-Path -LiteralPath $fromPath.Source)) {
      return $fromPath.Source
    }
  }

  $reg = Get-ChromeFromRegistry
  if ($reg) { return $reg }

  $candidates = @(
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\Application\chrome.exe")
    (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe")
    (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe")
    (Join-Path $env:ProgramFiles "Google\Chrome Dev\Application\chrome.exe")
  )
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { return $c }
  }
  return $null
}

function Resolve-BrowserForPdf {
  param(
    [string] $Mode
  )
  if ($Mode -eq 'Edge') {
    $e = Get-EdgeExecutable
    if (-not $e) { Write-Error "Edge demande mais introuvable." }
    return $e
  }
  if ($Mode -eq 'Chrome') {
    $c = Get-ChromeExecutable
    if (-not $c) { Write-Error "Chrome demande mais introuvable." }
    return $c
  }
  $c = Get-ChromeExecutable
  if ($c) { return $c }
  $e = Get-EdgeExecutable
  if ($e) { return $e }
  Write-Error "Aucun navigateur trouve pour l'export PDF."
}

function Export-HtmlFileToPdf {
  param(
    [string] $HtmlAbsolutePath,
    [string] $PdfAbsolutePath,
    [string] $BrowserExe
  )

  $htmlResolved = (Resolve-Path -LiteralPath $HtmlAbsolutePath).Path
  $htmlUri = ([System.Uri]$htmlResolved).AbsoluteUri
  $pdfArg = '--print-to-pdf="' + $PdfAbsolutePath + '"'

  $arguments = @(
    '--headless=new'
    '--disable-gpu'
    '--no-first-run'
    '--no-default-browser-check'
    '--no-pdf-header-footer'
    $pdfArg
    $htmlUri
  )

  $p = Start-Process -FilePath $BrowserExe -ArgumentList $arguments -Wait -PassThru -NoNewWindow
  $code = $p.ExitCode
  if ($null -eq $code) { $code = 0 }

  if (-not (Test-Path -LiteralPath $PdfAbsolutePath)) {
    Write-Error "Le fichier PDF n'a pas ete cree : $PdfAbsolutePath (navigateur : $BrowserExe)"
  }
  if ($code -ne 0) {
    Write-Warning "Le navigateur a retourne le code $code, mais le PDF existe : $PdfAbsolutePath"
  }
}

# --- Resolution du chemin .md ---

$md = Resolve-Path -LiteralPath $MarkdownPath
$mdDir = Split-Path -Parent $md
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($md.Path)

if (-not $OutputHtmlPath) {
  $OutputHtmlPath = Join-Path $mdDir "${baseName}_registre_print.html"
}

$outFile = [System.IO.Path]::GetFullPath($OutputHtmlPath)
$outDir = Split-Path -Parent $outFile

$pdfStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$pdfFile = Join-Path $mdDir "${baseName}_${pdfStamp}.pdf"
$pdfFile = [System.IO.Path]::GetFullPath($pdfFile)

if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# --- Pandoc : Markdown -> corps HTML ---

$pandocExe = Get-PandocExecutable -ExplicitPath $PandocPath
if (-not $pandocExe) {
  Write-Error "Pandoc introuvable. Ajoutez Pandoc au PATH ou passez -PandocPath."
}

$tempBody = [System.IO.Path]::GetTempFileName() + ".html"
try {
  & $pandocExe $md.Path -f markdown -t html5 --standalone=false -o $tempBody
  $bodyInner = Get-Content -Path $tempBody -Raw -Encoding UTF8
  if ($bodyInner -match '(?s)<body[^>]*>(.*)</body>') {
    $bodyInner = $Matches[1].Trim()
  }
} finally {
  Remove-Item -Force -LiteralPath $tempBody -ErrorAction SilentlyContinue
}

# --- Format de page : surcharge CSS ---

if ($Format -eq 'A3') {
  $pageOverride = '@page { size: A3; margin: 22mm 20mm; }'
} else {
  $pageOverride = ''
}

# --- Titre du document (h1) ---

$titlePlain = $baseName
$rxH1 = [regex]'(?s)<h1[^>]*>(?<t>[\s\S]*?)</h1>'
$mH1 = $rxH1.Match($bodyInner)
if ($mH1.Success) {
  $titlePlain = [regex]::Replace($mH1.Groups['t'].Value, '<[^>]+>', '').Trim()
  if ([string]::IsNullOrWhiteSpace($titlePlain)) { $titlePlain = $baseName }
}
$titleEncoded = [System.Net.WebUtility]::HtmlEncode($titlePlain)

# --- Assemblage HTML ---

$shellPath = Join-Path $PSScriptRoot "registre_shell.html"
$cssPath = Join-Path $PSScriptRoot "registre_print.css"

$cssResolved = (Resolve-Path -LiteralPath $cssPath).Path
$cssHref = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $cssResolved

$bodyClass = ""
if ($baseName -match 'VIP') {
  $bodyClass = "registre-vip"
} elseif ($baseName -match 'Matelas') {
  $bodyClass = "registre-matelas"
} elseif ($baseName -match 'UBI') {
  $bodyClass = "registre-ubi"
}
if ($SkipHrPageBreak) {
  if ($bodyClass) { $bodyClass += " registre-continuous" }
  else { $bodyClass = "registre-continuous" }
}

$shell = Get-Content -Path $shellPath -Raw -Encoding UTF8
$html = $shell.
  Replace('__CSS_HREF__', $cssHref).
  Replace('__PAGE_OVERRIDE__', $pageOverride).
  Replace('__TITLE__', $titleEncoded).
  Replace('__BODY_CLASS__', $bodyClass).
  Replace('__MARKDOWN_BODY__', $bodyInner)

[System.IO.File]::WriteAllText($outFile, $html, [System.Text.UTF8Encoding]::new($false))

# --- Export PDF ---

if ($SkipPdf) {
  Write-Host "HTML : $outFile"
} else {
  $script:ChromePathParam = $ChromePath
  $browserExe = Resolve-BrowserForPdf -Mode $Browser
  Write-Host "PDF : navigateur - $browserExe"
  Export-HtmlFileToPdf -HtmlAbsolutePath $outFile -PdfAbsolutePath $pdfFile -BrowserExe $browserExe
  Remove-Item -LiteralPath $outFile -Force -ErrorAction Stop
  Write-Host "PDF  : $pdfFile"
}
