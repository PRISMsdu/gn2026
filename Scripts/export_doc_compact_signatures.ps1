<#
  Export PDF document officiel, avec signatures compactes.

  Ce wrapper réutilise export_doc.ps1 pour garder la charte officielle, puis
  injecte une surcharge CSS qui limite uniquement les images situées après le
  titre "## Signatures". Il est utile pour les actes qui contiennent plusieurs
  blasons et signatures manuscrites en fin de document.

  Exemple :
    powershell -NoProfile -ExecutionPolicy Bypass -File "Scripts/export_doc_compact_signatures.ps1" `
      -MarkdownPath "codex/Monde/Paraphe des treize lignes marchandes — an 542.md" `
      -InstitutionLigne "Confédération des cités libres du Levant"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string] $MarkdownPath,

  [string] $InstitutionLigne = "",

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = ""
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Export-ImageForPrint.ps1')

function Get-ChromeFromRegistry {
  foreach ($key in @(
      'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'
      'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'
    )) {
    if (-not (Test-Path -LiteralPath $key)) { continue }
    try {
      $def = (Get-ItemProperty -LiteralPath $key -ErrorAction Stop).'(default)'
      if (-not [string]::IsNullOrWhiteSpace($def) -and (Test-Path -LiteralPath $def)) {
        return $def
      }
    }
    catch { }
  }
  return $null
}

function Get-ChromeExecutable {
  param([string] $ExplicitPath)
  if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
    if (-not (Test-Path -LiteralPath $ExplicitPath)) { Write-Error "ChromePath introuvable : $ExplicitPath" }
    return (Resolve-Path -LiteralPath $ExplicitPath).Path
  }
  foreach ($cmdName in @('chrome.exe', 'chrome')) {
    $fromPath = Get-Command $cmdName -ErrorAction SilentlyContinue
    if ($fromPath -and $fromPath.Source -and (Test-Path -LiteralPath $fromPath.Source)) {
      return $fromPath.Source
    }
  }
  $reg = Get-ChromeFromRegistry
  if ($reg) { return $reg }
  foreach ($p in @(
      (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
      (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe')
      (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
    )) {
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

function Get-EdgeExecutable {
  foreach ($p in @(
      (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe')
      (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe')
    )) {
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

function Resolve-BrowserForPdf {
  param([string] $Mode, [string] $ExplicitChromePath)
  if ($Mode -eq 'Edge') {
    $edge = Get-EdgeExecutable
    if (-not $edge) { Write-Error 'Edge demandé mais introuvable.' }
    return $edge
  }
  if ($Mode -eq 'Chrome') {
    $chrome = Get-ChromeExecutable -ExplicitPath $ExplicitChromePath
    if (-not $chrome) { Write-Error 'Chrome demandé mais introuvable.' }
    return $chrome
  }
  $chromeAuto = Get-ChromeExecutable -ExplicitPath $ExplicitChromePath
  if ($chromeAuto) { return $chromeAuto }
  $edgeAuto = Get-EdgeExecutable
  if ($edgeAuto) { return $edgeAuto }
  Write-Error 'Aucun navigateur trouvé pour l export PDF.'
}

$mdResolved = Resolve-Path -LiteralPath (Join-Path (Get-Location) $MarkdownPath) -ErrorAction SilentlyContinue
if (-not $mdResolved) {
  $mdResolved = Resolve-Path -LiteralPath $MarkdownPath
}
$mdPathAbs = $mdResolved.Path
$mdDir = Split-Path -Parent $mdPathAbs
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($mdPathAbs)

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$htmlPath = Join-Path $mdDir "${baseName}_compact_signatures_print.html"
$pdfPath = Join-Path $mdDir "${baseName}_doc_compact_${stamp}.pdf"

$exportDoc = Join-Path $PSScriptRoot 'export_doc.ps1'
$exportArgs = @(
  '-NoProfile', '-ExecutionPolicy', 'Bypass',
  '-File', $exportDoc,
  '-MarkdownPath', $mdPathAbs,
  '-OutputHtmlPath', $htmlPath,
  '-SkipPdf',
  '-nochangepage'
)
if (-not [string]::IsNullOrWhiteSpace($InstitutionLigne)) {
  $exportArgs += @('-InstitutionLigne', $InstitutionLigne)
}
if (-not [string]::IsNullOrWhiteSpace($ChromePath)) {
  $exportArgs += @('-ChromePath', $ChromePath)
}
if (-not [string]::IsNullOrWhiteSpace($PandocPath)) {
  $exportArgs += @('-PandocPath', $PandocPath)
}

& powershell @exportArgs
if (-not (Test-Path -LiteralPath $htmlPath)) {
  Write-Error "HTML temporaire non créé : $htmlPath"
}

function Convert-SignatureSectionToGrid {
  param([string] $Html)

  $sectionRx = [regex]::new(
    '(?is)<h2 id="signatures">Signatures</h2>(?<body>.*?)(?<tail><p>\s*<em>Copies certifi.*?</em>\s*</p>)',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $sectionMatch = $sectionRx.Match($Html)
  if (-not $sectionMatch.Success) {
    Write-Warning 'Section Signatures non détectée : grille compacte non appliquée.'
    return $Html
  }

  $itemRx = [regex]::new(
    '(?is)<p>\s*<strong>(?<label>.*?)</strong>\s*:\s*(?<blason><img\b[^>]*>)?\s*</p>\s*(?<signature><div class="doc-export-signature"[^>]*>.*?</div>)?',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $items = @($itemRx.Matches($sectionMatch.Groups['body'].Value))
  if ($items.Count -eq 0) {
    Write-Warning 'Aucune signature détectée dans la section Signatures.'
    return $Html
  }

  function ConvertTo-LocalFileUri {
    param([string] $AbsolutePath)
    $resolved = (Resolve-Path -LiteralPath $AbsolutePath).Path
    return ([System.Uri]$resolved).AbsoluteUri
  }

  function Get-KnownBlasonPath {
    param([string] $Label)
    $blasonDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'LivretsLocaux\Blasons'
    $known = @{
      'Il-Irion' = 'Blason_Il-Irion_+.png'
      'Palyr' = 'Blason_Palyr_+.png'
      'Sfaal' = 'Blason_Sfaal_+.png'
      'Arthas' = 'Blason_Arthas_+.png'
      'Ther-Félis' = 'Blason_Ther-Félis_+.png'
      'Greffe UBI' = 'Blason_UBI.png'
      'Grands ordonnateurs de la Convention' = 'Blason_Talamh.png'
    }
    if (-not $known.ContainsKey($Label)) { return $null }
    $candidate = Join-Path $blasonDir $known[$Label]
    if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
    return $null
  }

  function Resolve-BlasonSourcePath {
    param(
      [string] $BlasonHtml,
      [string] $Label
    )
    $known = Get-KnownBlasonPath -Label $Label
    if ($known) { return $known }

    if ($BlasonHtml -match 'src="([^"]+)"') {
      $src = [System.Net.WebUtility]::HtmlDecode($Matches[1])
      if ([string]::IsNullOrWhiteSpace($src)) { return $null }
      if ($src -match '^file://') {
        try { return ([System.Uri]$src).LocalPath } catch { return $null }
      }
      if ([System.IO.Path]::IsPathRooted($src) -and (Test-Path -LiteralPath $src)) {
        return (Resolve-Path -LiteralPath $src).Path
      }
      $relativeCandidate = Join-Path (Split-Path -Parent $htmlPath) ($src -replace '/', '\')
      if (Test-Path -LiteralPath $relativeCandidate) {
        return (Resolve-Path -LiteralPath $relativeCandidate).Path
      }
    }
    return $null
  }

  function New-CompactBlasonHtml {
    param(
      [string] $BlasonHtml,
      [string] $Label
    )
    $source = Resolve-BlasonSourcePath -BlasonHtml $BlasonHtml -Label $Label
    if (-not $source) {
      Write-Warning "Blason introuvable pour $Label"
      return '<div class="paraphe-signature-no-blason"></div>'
    }
    $cacheDir = Get-ExportImageCacheDir -ScriptsRoot $PSScriptRoot
    $printImage = Optimize-ExportImageForPrint -SourcePath $source -MaxEdgePx 180 -CacheDir $cacheDir
    if (-not $printImage) {
      Write-Warning "Blason non optimisé pour $Label : $source"
      return '<div class="paraphe-signature-no-blason"></div>'
    }
    $uri = ConvertTo-LocalFileUri -AbsolutePath $printImage
    $alt = [System.Net.WebUtility]::HtmlEncode("Blason $Label")
    return '<img src="' + $uri + '" alt="' + $alt + '" />'
  }

  $grid = [System.Text.StringBuilder]::new()
  [void]$grid.AppendLine('<h2 id="signatures">Signatures</h2>')
  [void]$grid.AppendLine('<section class="paraphe-signatures-grid">')
  foreach ($item in $items) {
    $label = $item.Groups['label'].Value.Trim()
    $blason = $item.Groups['blason'].Value.Trim()
    $signature = $item.Groups['signature'].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($signature)) {
      $signature = '<div class="doc-export-signature paraphe-signature-empty"></div>'
    }
    $blason = New-CompactBlasonHtml -BlasonHtml $blason -Label $label

    [void]$grid.AppendLine('  <div class="paraphe-signature-card">')
    [void]$grid.AppendLine('    <div class="paraphe-signature-label">' + $label + '</div>')
    [void]$grid.AppendLine('    <div class="paraphe-signature-blason">' + $blason + '</div>')
    [void]$grid.AppendLine('    <div class="paraphe-signature-ink">' + $signature + '</div>')
    [void]$grid.AppendLine('  </div>')
  }
  [void]$grid.AppendLine('</section>')
  [void]$grid.AppendLine($sectionMatch.Groups['tail'].Value)

  return $Html.Substring(0, $sectionMatch.Index) + $grid.ToString() +
    $Html.Substring($sectionMatch.Index + $sectionMatch.Length)
}

$compactCss = @'

/* Surcharge locale : signatures alignées en deux lignes maximum.
   Les images de l'en-tête institutionnel ne sont pas touchées. */
#contenu-avis .paraphe-signatures-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 0.65rem 0.85rem;
  align-items: start;
  margin: 0.65rem 0 0.9rem;
  page-break-inside: avoid;
}

#contenu-avis .paraphe-signature-card {
  min-width: 0;
  text-align: center;
  page-break-inside: avoid;
}

#contenu-avis .paraphe-signature-label {
  font-family: "Cinzel Decorative", Georgia, serif;
  font-size: 0.56rem;
  color: #5c1400;
  letter-spacing: 0.04em;
  line-height: 1.15;
  min-height: 1.4rem;
  margin-bottom: 0.18rem;
}

#contenu-avis .paraphe-signature-blason {
  height: 16mm;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 0.12rem;
}

#contenu-avis .paraphe-signature-blason img {
  max-width: 15mm;
  max-height: 15mm;
  width: auto;
  height: auto;
  object-fit: contain;
}

#contenu-avis .paraphe-signature-no-blason {
  width: 15mm;
  height: 15mm;
}

#contenu-avis .paraphe-signature-ink .doc-export-signature {
  margin: 0;
  text-align: center;
}

#contenu-avis .paraphe-signature-ink img.doc-export-signature-ink {
  max-width: 30mm;
  max-height: 9mm;
  width: auto;
  height: auto;
}

#contenu-avis .paraphe-signature-empty {
  height: 9mm;
}

#contenu-avis .paraphe-signatures-grid + p {
  margin-top: 0.9rem;
}

'@

$html = Get-Content -LiteralPath $htmlPath -Raw -Encoding UTF8
$html = Convert-SignatureSectionToGrid -Html $html
$html = $html -replace '</style>', ($compactCss + "`n</style>")
[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($false))

$browserExe = Resolve-BrowserForPdf -Mode $Browser -ExplicitChromePath $ChromePath
Write-Host ('Navigateur : ' + $browserExe)

$htmlUri = ([System.Uri](Resolve-Path -LiteralPath $htmlPath).Path).AbsoluteUri
$pdfArg = '--print-to-pdf="' + $pdfPath + '"'
$procArgs = @(
  '--headless=new',
  '--disable-gpu',
  '--no-first-run',
  '--no-default-browser-check',
  '--no-pdf-header-footer',
  $pdfArg,
  $htmlUri
)

$p = Start-Process -FilePath $browserExe -ArgumentList $procArgs -Wait -PassThru -NoNewWindow
if (-not (Test-Path -LiteralPath $pdfPath)) {
  Write-Error "Le fichier PDF n a pas été créé : $pdfPath"
}
if ($p.ExitCode -ne 0) {
  Write-Warning "Navigateur exit code $($p.ExitCode) - PDF peut quand même exister."
}

Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
Write-Host ('PDF : ' + $pdfPath)
