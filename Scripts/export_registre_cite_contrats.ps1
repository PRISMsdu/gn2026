<#
  Export PDF des registres contrats courants des cités (markdown joueur).

  Format : registre manuscrit paysage, blason de la cité à gauche du titre (h1).

  Exemples (depuis la racine du dépôt) :
    .\Scripts\export_registre_cite_contrats.ps1 -City Arthas
    .\Scripts\export_registre_cite_contrats.ps1 -MarkdownPath "Groupes\Arthas\1 - Back de groupe\registre_Arthas_contrats_courant.md"
    .\Scripts\export_registre_cite_contrats.ps1 -City Palyr -SkipPdf

  Prérequis : Pandoc, Chrome ou Edge.
#>

[CmdletBinding(DefaultParameterSetName = 'ByCity')]
param(
  [Parameter(ParameterSetName = 'ByCity', Mandatory = $true, Position = 0)]
  [ValidateSet('Arthas', 'Il-Irion', 'Palyr', 'Sfaal', 'Ther-Félis')]
  [string] $City,

  [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 0)]
  [string] $MarkdownPath,

  [string] $BlasonPath = "",

  [string] $OutputHtmlPath = "",

  [ValidateSet('A4', 'A3')]
  [string] $Format = 'A4',

  [switch] $SkipPdf,

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = ""
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Export-ImageForPrint.ps1')
. (Join-Path $PSScriptRoot 'Resolve-ExportBlasonPath.ps1')

$exportImageCacheDir = Get-ExportImageCacheDir -ScriptsRoot $PSScriptRoot

$CiteDefaults = @{
  'Arthas'     = 'Groupes\Arthas\1 - Back de groupe\registre_Arthas_contrats_courant.md'
  'Il-Irion'   = 'Groupes\Il-Irion\1 - Back de groupe\registre_Il-Irion_contrats_courant.md'
  'Palyr'      = 'Groupes\Palyr\1 - Back de groupe\registre_Palyr_contrats_courant.md'
  'Sfaal'      = 'Groupes\Sfaal\Back de groupe\registre_Sfaal_contrats_courant.md'
  'Ther-Félis' = 'Groupes\Ther-Félis\1 - Back de groupe\registre_Ther-Félis_contrats_courant.md'
}

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
      (Join-Path $env:ProgramFiles 'Pandoc\pandoc.exe')
      (Join-Path ${env:ProgramFiles(x86)} 'Pandoc\pandoc.exe')
    )) {
    if (Test-Path -LiteralPath $c) { return $c }
  }
  return $null
}

function Get-EdgeExecutable {
  $candidates = @(
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe')
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe')
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
  foreach ($c in @(
      (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
      (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe')
      (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
    )) {
    if (Test-Path -LiteralPath $c) { return $c }
  }
  return $null
}

function Resolve-BrowserForPdf {
  param([string] $Mode)
  if ($Mode -eq 'Edge') {
    $e = Get-EdgeExecutable
    if (-not $e) { Write-Error 'Edge demande mais introuvable.' }
    return $e
  }
  if ($Mode -eq 'Chrome') {
    $c = Get-ChromeExecutable
    if (-not $c) { Write-Error 'Chrome demande mais introuvable.' }
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
  if (-not (Test-Path -LiteralPath $PdfAbsolutePath)) {
    Write-Error "Le fichier PDF n'a pas ete cree : $PdfAbsolutePath"
  }
}

function Add-RegistreCiteBlasonToH1 {
  param(
    [string] $BodyInner,
    [string] $BlasonSrc
  )
  if ([string]::IsNullOrWhiteSpace($BlasonSrc)) { return $BodyInner }
  if (-not ([regex]'(?s)<h1[^>]*>').IsMatch($BodyInner)) { return $BodyInner }

  $blasonHtml = '<img src="' + $BlasonSrc + '" class="registre-cite-blason" alt="Blason de la cité" />'
  $rxOpenH1 = [regex]'(?s)(<h1[^>]*>)([\s\S]*?)(</h1>)'
  return $rxOpenH1.Replace($BodyInner, {
      param($m)
      $inner = [regex]::Replace($m.Groups[2].Value, '<[^>]+>', '').Trim()
      $titleSpan = '<span class="registre-cite-titre-texte">' + [System.Net.WebUtility]::HtmlEncode($inner) + '</span>'
      return $m.Groups[1].Value + $blasonHtml + $titleSpan + $m.Groups[3].Value
    }, 1)
}

# --- Résolution chemin markdown ---

$repoRoot = Split-Path -Parent $PSScriptRoot
if ($PSCmdlet.ParameterSetName -eq 'ByCity') {
  if (-not $CiteDefaults.ContainsKey($City)) {
    Write-Error "Cite inconnue : $City"
  }
  $MarkdownPath = Join-Path $repoRoot $CiteDefaults[$City]
  $citeSlug = $City
} else {
  $MarkdownPath = if ([System.IO.Path]::IsPathRooted($MarkdownPath)) {
    $MarkdownPath
  } else {
    Join-Path $repoRoot $MarkdownPath
  }
  $citeSlug = $null
  foreach ($key in $CiteDefaults.Keys) {
    if ($MarkdownPath -match [regex]::Escape($key)) {
      $citeSlug = $key
      break
    }
  }
  if (-not $citeSlug) { $citeSlug = 'Arthas' }
}

$md = Resolve-Path -LiteralPath $MarkdownPath
$mdDir = Split-Path -Parent $md.Path
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($md.Path)
$markdownRaw = Get-Content -LiteralPath $md.Path -Raw -Encoding UTF8

if (-not $OutputHtmlPath) {
  $OutputHtmlPath = Join-Path $mdDir "${baseName}_registre_print.html"
}

$outFile = [System.IO.Path]::GetFullPath($OutputHtmlPath)
$outDir = Split-Path -Parent $outFile
$pdfStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$pdfFile = [System.IO.Path]::GetFullPath((Join-Path $mdDir "${baseName}_${pdfStamp}.pdf"))

if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$pandocExe = Get-PandocExecutable -ExplicitPath $PandocPath
if (-not $pandocExe) {
  Write-Error 'Pandoc introuvable. Ajoutez Pandoc au PATH ou passez -PandocPath.'
}

$tempBody = [System.IO.Path]::GetTempFileName() + '.html'
try {
  & $pandocExe $md.Path -f markdown -t html5 --standalone=false -o $tempBody
  $bodyInner = Get-Content -Path $tempBody -Raw -Encoding UTF8
  if ($bodyInner -match '(?s)<body[^>]*>(.*)</body>') {
    $bodyInner = $Matches[1].Trim()
  }
} finally {
  Remove-Item -Force -LiteralPath $tempBody -ErrorAction SilentlyContinue
}

$titlePlain = $baseName
$rxH1 = [regex]'(?s)<h1[^>]*>(?<t>[\s\S]*?)</h1>'
$mH1 = $rxH1.Match($bodyInner)
if ($mH1.Success) {
  $titlePlain = [regex]::Replace($mH1.Groups['t'].Value, '<[^>]+>', '').Trim()
  if ([string]::IsNullOrWhiteSpace($titlePlain)) { $titlePlain = $baseName }
}
$titleEncoded = [System.Net.WebUtility]::HtmlEncode($titlePlain)

# --- Blason cité ---
$resolvedBlasonPath = $null
if (-not [string]::IsNullOrWhiteSpace($BlasonPath)) {
  if (-not (Test-Path -LiteralPath $BlasonPath)) {
    Write-Error "BlasonPath introuvable : $BlasonPath"
  }
  $resolvedBlasonPath = (Resolve-Path -LiteralPath $BlasonPath).Path
} else {
  $resolvedBlasonPath = Resolve-ExportBlasonPath `
    -MarkdownDirectory $mdDir `
    -MarkdownPath $md.Path `
    -InstitutionNom $citeSlug `
    -MarkdownRaw $markdownRaw `
    -ScriptsRoot $PSScriptRoot `
    -ForcedBlasonPath $null
}

$blasonSrc = ''
if ($resolvedBlasonPath) {
  $blasonPrint = Optimize-ExportImageForPrint -SourcePath $resolvedBlasonPath -MaxEdgePx 192 -CacheDir $exportImageCacheDir
  $blasonSrc = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $blasonPrint
  Write-Host "Blason : $resolvedBlasonPath"
} else {
  Write-Warning "Aucun blason trouve pour $citeSlug."
}

$bodyInner = Add-RegistreCiteBlasonToH1 -BodyInner $bodyInner -BlasonSrc $blasonSrc

$pageOverride = if ($Format -eq 'A3') {
  '@page { size: A3 landscape; margin: 10mm 12mm; }'
} else {
  ''
}

$shellPath = Join-Path $PSScriptRoot 'registre_cite_contrats_shell.html'
$cssPath = Join-Path $PSScriptRoot 'registre_cite_contrats_print.css'
$cssResolved = (Resolve-Path -LiteralPath $cssPath).Path
$cssHref = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $cssResolved
$bodyClass = 'registre-cite-' + ($citeSlug -replace '[^A-Za-z0-9]+', '-').Trim('-').ToLowerInvariant()

$shell = Get-Content -Path $shellPath -Raw -Encoding UTF8
$html = $shell.
  Replace('__CSS_HREF__', $cssHref).
  Replace('__PAGE_OVERRIDE__', $pageOverride).
  Replace('__TITLE__', $titleEncoded).
  Replace('__BODY_CLASS__', $bodyClass).
  Replace('__MARKDOWN_BODY__', $bodyInner)

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
