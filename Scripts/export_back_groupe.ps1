<#
  Export HTML + PDF stylés pour un back de groupe à partir d’un fichier .md (contenu seul).

  Prérequis :
    - Pandoc dans le PATH (https://pandoc.org)
    - Google Chrome ou Microsoft Edge (impression PDF headless) — Chrome est essayé en premier.

  Navigateur : par défaut Chrome puis Edge. Pour forcer : -Browser Chrome | Edge, ou -ChromePath "C:\...\chrome.exe"

  Exemples (depuis la racine du dépôt) :
    .\Scripts\export_back_groupe.ps1 -MarkdownPath "Groupes\MiVI\1 - Back de groupe\Back_groupe_MiVI.md"
    .\Scripts\export_back_groupe.ps1 -BackGroupeFileName "Back_groupe_MiVI.md" -BackGroupeDirectory "Groupes\MiVI\1 - Back de groupe"

  Sorties dans le même répertoire que le .md :
    - <nom>_yyyyMMdd_HHmmss.pdf (nouveau fichier à chaque exécution, évite le verrouillage du PDF ouvert)
    - <nom>_print.html uniquement si -SkipPdf (sinon HTML temporaire pour Chrome, supprimé après PDF)

  Cartouche : titre fixe GN Celtiana (voir $CartoucheTitre dans le script) + logo + bandeau. Le premier # du .md reste dans le corps.
#>

[CmdletBinding(DefaultParameterSetName = 'ByPath')]
param(
  [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 0)]
  [string] $MarkdownPath,

  [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
  [string] $BackGroupeFileName,

  [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
  [string] $BackGroupeDirectory,

  [string] $OutputHtmlPath = "",

  [switch] $SkipPdf,

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = "",

  [string] $CartoucheTitre = "GN Celtiana 2026 Krondaar - Ulghart : six morts"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Export-ImageForPrint.ps1')
$exportImageCacheDir = Get-ExportImageCacheDir -ScriptsRoot $PSScriptRoot

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
    if (-not $e) { Write-Error "Edge demandé mais introuvable (Program Files\Microsoft\Edge\Application\msedge.exe)." }
    return $e
  }
  if ($Mode -eq 'Chrome') {
    $c = Get-ChromeExecutable
    if (-not $c) {
      Write-Error "Chrome demandé mais introuvable. Installez Chrome, ajoutez-le au PATH, ou passez -ChromePath `"chemin\vers\chrome.exe`"."
    }
    return $c
  }
  $c = Get-ChromeExecutable
  if ($c) { return $c }
  $e = Get-EdgeExecutable
  if ($e) { return $e }
  Write-Error "Aucun navigateur trouve pour l'export PDF. Chrome : PATH, registre App Paths, ou dossiers Google\Chrome. Edge : Microsoft\Edge\Application\msedge.exe. Utilisez -ChromePath si Chrome est ailleurs."
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

  $args = @(
    '--headless=new'
    '--disable-gpu'
    '--no-first-run'
    '--no-default-browser-check'
    '--no-pdf-header-footer'
    $pdfArg
    $htmlUri
  )

  $p = Start-Process -FilePath $BrowserExe -ArgumentList $args -Wait -PassThru -NoNewWindow
  $code = $p.ExitCode
  if ($null -eq $code) { $code = 0 }

  if (-not (Test-Path -LiteralPath $PdfAbsolutePath)) {
    if ($code -ne 0) {
      Write-Error "Echec de l'export PDF (code $code). Navigateur : $BrowserExe"
    }
    Write-Error "Le fichier PDF n'a pas ete cree : $PdfAbsolutePath (navigateur : $BrowserExe). Verifiez les droits du dossier ou essayez -ChromePath avec le chemin complet vers chrome.exe."
  }
  if ($code -ne 0) {
    Write-Warning "Le navigateur a retourné le code $code, mais le PDF existe : $PdfAbsolutePath"
  }
}

# --- Résolution du chemin .md ---
if ($PSCmdlet.ParameterSetName -eq 'ByName') {
  $name = $BackGroupeFileName.Trim()
  if ($name -notmatch '\.md$') {
    $name = "$name.md"
  }
  $dir = [System.IO.Path]::GetFullPath($BackGroupeDirectory)
  $MarkdownPath = Join-Path $dir $name
}

$md = Resolve-Path -LiteralPath $MarkdownPath
$mdDir = Split-Path -Parent $md
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($md.Path)

if (-not $OutputHtmlPath) {
  $OutputHtmlPath = Join-Path $mdDir "${baseName}_print.html"
}

$outFile = [System.IO.Path]::GetFullPath($OutputHtmlPath)
$outDir = Split-Path -Parent $outFile

$pdfStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$pdfFile = Join-Path $mdDir "${baseName}_${pdfStamp}.pdf"
$pdfFile = [System.IO.Path]::GetFullPath($pdfFile)

if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$pandocExe = Get-PandocExecutable -ExplicitPath $PandocPath
if (-not $pandocExe) {
  Write-Error "Pandoc introuvable. Ajoutez Pandoc au PATH, ou passez -PandocPath `"C:\Program Files\Pandoc\pandoc.exe`"."
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

# Titre cartouche : libellé fixe GN Celtiana (paramètre -CartoucheTitre)
$cartoucheTitreHtml = [System.Net.WebUtility]::HtmlEncode($CartoucheTitre)

# <title> du document : premier # du Markdown (sans retirer le h1 du corps)
$docTitlePlain = $baseName
$rxH1 = [regex]'(?s)<h1[^>]*>(?<t>[\s\S]*?)</h1>'
$mH1 = $rxH1.Match($bodyInner)
if ($mH1.Success) {
  $docTitlePlain = [regex]::Replace($mH1.Groups['t'].Value, '<[^>]+>', '').Trim()
  if ([string]::IsNullOrWhiteSpace($docTitlePlain)) {
    $docTitlePlain = $baseName
  }
}

$shellPath = Join-Path $PSScriptRoot "back_groupe_shell.html"
$cssPath = Join-Path $PSScriptRoot "back_groupe_print.css"
$bandeauPath = Join-Path $PSScriptRoot "Images\Bandeau.png"
$logoPath = Join-Path $PSScriptRoot "Images\LogoCeltiana.jpg"

$cssResolved = (Resolve-Path -LiteralPath $cssPath).Path
$bandeauResolved = (Resolve-Path -LiteralPath $bandeauPath).Path
$logoResolved = (Resolve-Path -LiteralPath $logoPath).Path

$cssHref = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $cssResolved
$bandeauSrc = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $bandeauResolved
$logoSrc = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $logoResolved

# Blason de groupe : chercher Blason_*.png|jpg|jpeg|webp dans le même répertoire que le .md
$blasonPath = $null
foreach ($ext in @('png', 'jpg', 'jpeg', 'webp')) {
  $found = Get-ChildItem -Path $mdDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^[Bb]lason_.*\.' + $ext + '$' } |
    Select-Object -First 1
  if ($found) { $blasonPath = $found.FullName; break }
}

if ($blasonPath -and ([regex]'(?s)<h1[^>]*>').IsMatch($bodyInner)) {
  $blasonPrint = Optimize-ExportImageForPrint -SourcePath $blasonPath -MaxEdgePx 192 -CacheDir $exportImageCacheDir
  $blasonSrc = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $blasonPrint
  $blasonImg = "<img src=""$blasonSrc"" class=""blason-titre"" alt=""Blason du groupe"" />"
  # Injection immédiatement après la balise ouvrante <h1> (première occurrence seulement)
  $bodyInner = [regex]::Replace($bodyInner, '(<h1[^>]*>)', "`$1$blasonImg", 1)
}

$shell = Get-Content -Path $shellPath -Raw -Encoding UTF8
$html = $shell.
  Replace('__CSS_HREF__', $cssHref).
  Replace('__BANDEAU_SRC__', $bandeauSrc).
  Replace('__LOGO_SRC__', $logoSrc).
  Replace('__CARTOUCHE_TITRE__', $cartoucheTitreHtml).
  Replace('__MARKDOWN_BODY__', $bodyInner)

$html = $html.Replace(
  '<title>Back de groupe</title>',
  ('<title>{0}</title>' -f [System.Net.WebUtility]::HtmlEncode($docTitlePlain))
)

[System.IO.File]::WriteAllText($outFile, $html, [System.Text.UTF8Encoding]::new($false))

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
