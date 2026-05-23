<#
  Export HTML + PDF parchemin medieval pour la Charte Fondatrice de l'UBI.

  Identique a export_avis.ps1 pour le flux signatures :
  marqueurs (*Signature*: Nom) dans le .md, PNG via generate_signature_ink.ps1
  (Expand-MarkdownExportSignatures.ps1). Apres Pandoc, les blocs cite + blason + signature
  sont regroupes en cartouche enlumine (grille charte-signatures).

  Prerequis :
    - Pandoc dans le PATH (https://pandoc.org)
    - Google Chrome ou Microsoft Edge (impression PDF headless)
    - Acces internet au moment de la generation (Google Fonts)

  Exemple (depuis la racine du depot) :
    .\Scripts\export_charte_UBI.ps1
    .\Scripts\export_charte_UBI.ps1 -MarkdownPath "Groupes\Banquiers - UBI\1 - Back de groupe\Charte_UBI.md"

  Sortie dans le meme repertoire que le .md :
    - Charte_UBI_yyyyMMdd_HHmmss.pdf

  Les blasons LivretsLocaux (souvent 2-3 Mo chacun) sont redimensionnes avant PDF
  (voir Export-ImageForPrint.ps1) : Chrome embarquait les PNG pleine resolution (~16 Mo au total).
#>

[CmdletBinding()]
param(
  [string] $MarkdownPath  = "Groupes\Banquiers - UBI\1 - Back de groupe\Charte_UBI.md",
  [string] $OutputHtmlPath = "",
  [string] $InstitutionNom = "Union Bancaire d'Il-Irion",
  [ValidateSet('A4', 'A3')]
  [string] $Format = 'A4',
  [switch] $SkipPdf,
  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',
  [string] $ChromePath = "",
  [string] $PandocPath = "",
  [switch] $ForceSignatures
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Export-ImageForPrint.ps1')
. (Join-Path $PSScriptRoot 'Expand-MarkdownExportSignatures.ps1')

$exportImageCacheDir = Get-ExportImageCacheDir -ScriptsRoot $PSScriptRoot

# ---------------------------------------------------------------------------
# Fonctions utilitaires (identiques a export_avis.ps1)
# ---------------------------------------------------------------------------

function ConvertTo-HtmlUriPath {
  param([string] $Path)
  return ($Path -replace '\\', '/')
}

function Get-RelativeUriPath {
  param([string] $FromAbsoluteFile, [string] $ToAbsoluteFile)
  $fromDir = Split-Path -Parent $FromAbsoluteFile
  if (-not $fromDir.EndsWith('\')) { $fromDir += '\' }
  $fromUri = New-Object System.Uri $fromDir
  $toUri   = New-Object System.Uri $ToAbsoluteFile
  $rel     = $fromUri.MakeRelativeUri($toUri).ToString()
  return (ConvertTo-HtmlUriPath $rel)
}

function Get-PandocExecutable {
  param([string] $ExplicitPath)
  if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
    if (-not (Test-Path -LiteralPath $ExplicitPath)) { Write-Error "PandocPath introuvable : $ExplicitPath" }
    return (Resolve-Path -LiteralPath $ExplicitPath).Path
  }
  $cmd = Get-Command pandoc.exe -ErrorAction SilentlyContinue
  if (-not $cmd) { $cmd = Get-Command pandoc -ErrorAction SilentlyContinue }
  if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }
  foreach ($c in @(
      (Join-Path $env:ProgramFiles         'Pandoc\pandoc.exe')
      (Join-Path ${env:ProgramFiles(x86)}  'Pandoc\pandoc.exe')
    )) {
    if (Test-Path -LiteralPath $c) { return $c }
  }
  return $null
}

function Get-EdgeExecutable {
  $candidates = @(
    (Join-Path $env:ProgramFiles        'Microsoft\Edge\Application\msedge.exe')
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe')
  )
  foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
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
    if (-not (Test-Path -LiteralPath $p)) { Write-Error "ChromePath introuvable : $p" }
    return (Resolve-Path -LiteralPath $p).Path
  }
  foreach ($cmdName in @('chrome.exe', 'chrome')) {
    $fromPath = Get-Command $cmdName -ErrorAction SilentlyContinue
    if ($fromPath -and $fromPath.Source -and (Test-Path -LiteralPath $fromPath.Source)) { return $fromPath.Source }
  }
  $reg = Get-ChromeFromRegistry
  if ($reg) { return $reg }
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA        'Google\Chrome\Application\chrome.exe')
    (Join-Path $env:ProgramFiles        'Google\Chrome\Application\chrome.exe')
    (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
    (Join-Path $env:ProgramFiles        'Google\Chrome Dev\Application\chrome.exe')
  )
  foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
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
  Write-Error 'Aucun navigateur trouve pour l export PDF.'
}

function Export-HtmlFileToPdf {
  param([string] $HtmlAbsolutePath, [string] $PdfAbsolutePath, [string] $BrowserExe)
  $htmlResolved = (Resolve-Path -LiteralPath $HtmlAbsolutePath).Path
  $htmlUri      = ([System.Uri]$htmlResolved).AbsoluteUri
  $pdfArg       = '--print-to-pdf="' + $PdfAbsolutePath + '"'
  $procArgs = @(
    '--headless=new'
    '--disable-gpu'
    '--no-first-run'
    '--no-default-browser-check'
    '--no-pdf-header-footer'
    $pdfArg
    $htmlUri
  )
  $p    = Start-Process -FilePath $BrowserExe -ArgumentList $procArgs -Wait -PassThru -NoNewWindow
  $code = $p.ExitCode
  if ($null -eq $code) { $code = 0 }
  if (-not (Test-Path -LiteralPath $PdfAbsolutePath)) {
    Write-Error "Le fichier PDF n'a pas ete cree : $PdfAbsolutePath (navigateur : $BrowserExe)"
  }
  if ($code -ne 0) {
    Write-Warning "Le navigateur a retourne le code $code, mais le PDF existe : $PdfAbsolutePath"
  }
}

# Conversion chemin Windows absolu -> file:// URI
function ConvertTo-FileUri {
  param([string] $AbsolutePath)
  $forward = $AbsolutePath.Replace('\', '/')
  return 'file:///' + [Uri]::EscapeUriString($forward)
}

# ---------------------------------------------------------------------------
# Blason : chemin local depuis href Pandoc (file:// ou chemin Windows)
# ---------------------------------------------------------------------------
function ConvertFrom-BlasonHrefToPath {
  param([string] $Href)
  if ([string]::IsNullOrWhiteSpace($Href)) { return $null }
  $h = $Href.Trim()
  if ($h -match '^file:///(.+)$') {
    return [Uri]::UnescapeDataString($Matches[1]).Replace('/', [IO.Path]::DirectorySeparatorChar)
  }
  if ($h -match '^file://(.+)$') {
    return [Uri]::UnescapeDataString($Matches[1]).Replace('/', [IO.Path]::DirectorySeparatorChar)
  }
  if (Test-Path -LiteralPath $h) { return (Resolve-Path -LiteralPath $h).Path }
  return $null
}

# ---------------------------------------------------------------------------
# Cartouche signatures : **Cite** : [blason] + (*Signature*: Nom) -> PNG ink
# ---------------------------------------------------------------------------
$script:CharteSignatoryCities = @(
  'Il-Irion', 'Sfaal', 'Staal', 'Palyr', 'Ther-Felis', 'Ther-Félis', 'Arthas'
)

function Remove-CharteClosingFormulaFromHtml {
  param([string] $BodyHtml)
  # Retire la formule de clôture (souvent sur plusieurs lignes après Pandoc).
  $rx = '(?is)<p>\s*<strong>\s*Sign.*?scell.*?</strong>\s*</p>\s*'
  return [regex]::Replace($BodyHtml, $rx, '')
}

function New-CharteSignatureCartoucheHtml {
  param(
    [System.Text.RegularExpressions.Match] $Match,
    [hashtable] $BlasonByCite,
    [string] $ImageCacheDir,
    [string] $HtmlAbsolutePath
  )
  $cite = $Match.Groups['cite'].Value.Trim()
  $citeEnc = [System.Net.WebUtility]::HtmlEncode($cite)
  $between = $Match.Value
  $blasonPath = $null
  if ($between -match '<img\s[^>]*src="([^"]+)"') {
    $blasonPath = ConvertFrom-BlasonHrefToPath -Href $Matches[1]
    if (-not $blasonPath) {
      $rel = $Matches[1] -replace '/', '\'
      $fromHtml = Join-Path (Split-Path -Parent $HtmlAbsolutePath) $rel
      if (Test-Path -LiteralPath $fromHtml) { $blasonPath = (Resolve-Path -LiteralPath $fromHtml).Path }
    }
  }
  if (-not $blasonPath -and $BlasonByCite.ContainsKey($cite)) {
    $blasonPath = $BlasonByCite[$cite]
  }

  if ($blasonPath -and (Test-Path -LiteralPath $blasonPath)) {
    $blasonPrint = Optimize-ExportImageForPrint -SourcePath $blasonPath -MaxEdgePx 160 -CacheDir $ImageCacheDir
    $imgUri = ConvertTo-FileUri -AbsolutePath $blasonPrint
    $imgHtml = '<img src="' + $imgUri + '" class="charte-sig-blason" alt="Blason ' + $citeEnc + '" />'
  } else {
    if ($cite) { Write-Warning "Blason introuvable pour $cite" }
    $imgHtml = '<div class="charte-sig-blason-vide"></div>'
  }

  $sigBlock = $Match.Groups['sig'].Value.Trim()
  $nomEnc = $citeEnc
  if ($sigBlock -match 'alt="([^"]+)"') {
    $nomEnc = [System.Net.WebUtility]::HtmlEncode($Matches[1])
  }

  return (
    "`n    <div class=`"charte-signature`">" +
    "`n      <div class=`"charte-sig-pour`">Pour $citeEnc</div>" +
    "`n      $imgHtml" +
    "`n      <div class=`"charte-sig-ink-wrap`"><div class=`"doc-export-signature charte-sig-ink-slot`">$sigBlock</div></div>" +
    "`n      <div class=`"charte-sig-nom-legible`">$nomEnc</div>" +
    "`n      <div class=`"charte-sig-ligne`"></div>" +
    "`n      <div class=`"charte-sig-label`">$citeEnc</div>" +
    "`n    </div>"
  )
}

function Build-CharteSignatureBlockFromHtml {
  param(
    [string] $BodyHtml,
    [string] $ImageCacheDir,
    [string] $HtmlAbsolutePath
  )

  $BodyHtml = Remove-CharteClosingFormulaFromHtml -BodyHtml $BodyHtml

  $blasonDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'LivretsLocaux\Blasons'
  $blasonByCite = @{
    'Il-Irion'   = Join-Path $blasonDir 'Blason_Il-Irion_+.png'
    'Sfaal'      = Join-Path $blasonDir 'Blason_Sfaal_+.png'
    'Staal'      = Join-Path $blasonDir 'Blason_Sfaal_+.png'
    'Palyr'      = Join-Path $blasonDir 'Blason_Palyr_+.png'
    'Ther-Felis' = Join-Path $blasonDir "Blason_Ther-F$([char]0xe9)lis_+.png"
    'Ther-Félis' = Join-Path $blasonDir "Blason_Ther-F$([char]0xe9)lis_+.png"
    'Arthas'     = Join-Path $blasonDir 'Blason_Arthas_+.png'
    'Cités du Levant' = Join-Path $blasonDir "Blason_Cit$([char]0xe9)s_du_levant_+.png"
    'Cites du Levant' = Join-Path $blasonDir "Blason_Cit$([char]0xe9)s_du_levant_+.png"
    'Confédération'   = Join-Path $blasonDir "Blason_Cit$([char]0xe9)s_du_levant_+.png"
    'Confederation'   = Join-Path $blasonDir "Blason_Cit$([char]0xe9)s_du_levant_+.png"
  }

  $citeAlternation = ($script:CharteSignatoryCities | ForEach-Object { [regex]::Escape($_) }) -join '|'
  $itemRx = [regex]::new(
    "(?s)<p>\s*<strong>(?<cite>$citeAlternation)</strong>.*?</p>\s*<div class=`"doc-export-signature`"[^>]*>(?<sig>.*?)</div>",
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

  $matches = @($itemRx.Matches($BodyHtml))
  if ($matches.Count -eq 0) {
    Write-Warning 'Bloc signatures charte non detecte (cite + (*Signature*: ...) attendus dans le HTML).'
    return $BodyHtml
  }

  $firstIndex = $matches[0].Index
  $lastIndex = $matches[$matches.Count - 1].Index + $matches[$matches.Count - 1].Length

  $row1 = [System.Text.StringBuilder]::new()
  $row2 = [System.Text.StringBuilder]::new()
  for ($i = 0; $i -lt $matches.Count; $i++) {
    $cartouche = New-CharteSignatureCartoucheHtml -Match $matches[$i] `
      -BlasonByCite $blasonByCite -ImageCacheDir $ImageCacheDir -HtmlAbsolutePath $HtmlAbsolutePath
    if ($i -lt 3) {
      [void]$row1.Append($cartouche)
    } else {
      [void]$row2.Append($cartouche)
    }
  }

  $titreTxt = '&#10022;&ensp;Signatures des Repr&eacute;sentants&ensp;&#10022;'
  $blockHtml = '<section class="charte-signatures">' + "`n" +
    '  <div class="charte-signatures-titre">' + $titreTxt + '</div>' + "`n" +
    '  <div class="charte-signatures-grille">' + "`n" +
    '    <div class="charte-signatures-row charte-signatures-row-trois">' + $row1.ToString() + "`n    </div>" + "`n" +
    '    <div class="charte-signatures-row charte-signatures-row-deux">' + $row2.ToString() + "`n    </div>" + "`n" +
    '  </div>' + "`n" +
    '</section>'

  return $BodyHtml.Substring(0, $firstIndex) + $blockHtml + $BodyHtml.Substring($lastIndex)
}


# ---------------------------------------------------------------------------
# Resolution du chemin .md
# ---------------------------------------------------------------------------

$md       = Resolve-Path -LiteralPath $MarkdownPath
$mdDir    = Split-Path -Parent $md
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($md.Path)

if (-not $OutputHtmlPath) {
  $OutputHtmlPath = Join-Path $mdDir ($baseName + '_charte_print.html')
}

$outFile  = [System.IO.Path]::GetFullPath($OutputHtmlPath)
$outDir   = Split-Path -Parent $outFile
$pdfStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$pdfFile  = [System.IO.Path]::GetFullPath((Join-Path $mdDir ($baseName + '_' + $pdfStamp + '.pdf')))

if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Pandoc : Markdown -> corps HTML
# ---------------------------------------------------------------------------

$pandocExe = Get-PandocExecutable -ExplicitPath $PandocPath
if (-not $pandocExe) { Write-Error 'Pandoc introuvable. Ajoutez Pandoc au PATH ou passez -PandocPath.' }

$markdownUtf8Raw = Get-Content -LiteralPath $md.Path -Raw -Encoding UTF8
$markdownSansComments = [regex]::Replace($markdownUtf8Raw, '<!--[\s\S]*?-->', '')

$pandocSourcePath = $md.Path
$tempMdExpanded = ''
if ($markdownSansComments -match '(?msi)\(\*\s*[Ss]ignatures?\s*\*\s*:') {
  $expandedMdText = Expand-MarkdownInkSignatureMarkers -MarkdownRaw $markdownSansComments `
    -HtmlAbsolutePath $outFile -ScriptsPSScriptRoot $PSScriptRoot `
    -ForceRegenerate:$ForceSignatures
  $tempMdExpanded = [System.IO.Path]::GetTempFileName() + '.md'
  [System.IO.File]::WriteAllText($tempMdExpanded, $expandedMdText,
    ([System.Text.UTF8Encoding]::new($false)))
  $pandocSourcePath = $tempMdExpanded
}

$tempBody = [System.IO.Path]::GetTempFileName() + '.html'
try {
  & $pandocExe $pandocSourcePath -f markdown -t html5 --standalone=false -o $tempBody
  $bodyInner = Get-Content -Path $tempBody -Raw -Encoding UTF8
  if ($bodyInner -match '(?s)<body[^>]*>(.*)</body>') {
    $bodyInner = $Matches[1].Trim()
  }
} finally {
  Remove-Item -Force -LiteralPath $tempBody -ErrorAction SilentlyContinue
  if ($tempMdExpanded -ne '') {
    Remove-Item -Force -LiteralPath $tempMdExpanded -ErrorAction SilentlyContinue
  }
}

# Supprimer le h1 (affiche dans l'en-tete)
$bodyInner = [regex]::Replace($bodyInner, '(?s)<h1[^>]*>.*?</h1>', '', 1)

# Regrouper cite + blason + signature PNG en cartouche charte
$bodyInner = Build-CharteSignatureBlockFromHtml -BodyHtml $bodyInner -ImageCacheDir $exportImageCacheDir -HtmlAbsolutePath $outFile

# ---------------------------------------------------------------------------
# Blason UBI : detection dans le repertoire du .md (pour l'en-tete institution)
# ---------------------------------------------------------------------------

$blasonSrc = ''
foreach ($ext in @('png', 'jpg', 'jpeg', 'webp')) {
  $found = Get-ChildItem -Path $mdDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^[Bb]lason_.*\.' + $ext + '$' } |
    Select-Object -First 1
  if ($found) {
    $blasonPrint = Optimize-ExportImageForPrint -SourcePath $found.FullName -MaxEdgePx 220 -CacheDir $exportImageCacheDir
    $blasonSrc = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $blasonPrint
    break
  }
}

$blasonHtml = if ($blasonSrc) {
  '<img src="' + $blasonSrc + '" class="avis-blason" alt="Blason" />'
} else { '' }

# ---------------------------------------------------------------------------
# Format de page
# ---------------------------------------------------------------------------

if ($Format -eq 'A3') {
  $pageOverride = '@page { size: A3; margin: 25mm 22mm; } body.avis-document { width: 297mm; max-width: 297mm; min-height: 420mm; padding: 25mm 22mm; }'
} else {
  $pageOverride = ''
}

# CSS du bloc de signatures (concatene au page override)
$signatureCss = '
/* ======== Bloc de signatures de charte ======== */

.charte-signatures {
  margin-top: 2.5rem;
  page-break-inside: avoid;
}

.charte-signatures-titre {
  font-family: "Cinzel Decorative", Georgia, serif;
  font-size: 0.78rem;
  color: #8b5a1a;
  text-align: center;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  margin-bottom: 2rem;
  border-top: 1px solid #a06820;
  border-bottom: 1px solid #a06820;
  padding: 0.35em 0;
}

.charte-signatures-grille {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2rem;
}

.charte-signatures-row {
  display: flex;
  flex-wrap: nowrap;
  justify-content: center;
  align-items: flex-start;
  gap: 1.85rem;
  width: 100%;
}

.charte-signatures-row-deux {
  max-width: 22rem;
}

.charte-signature {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 0 0 auto;
  width: 124px;
  max-width: min(124px, 32vw);
  text-align: center;
  box-sizing: border-box;
}

.charte-sig-pour {
  font-family: "Cinzel Decorative", Georgia, serif;
  font-size: 0.54rem;
  color: #5c1400;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  margin-bottom: 0.65rem;
  line-height: 1.4;
}

.charte-sig-blason {
  width: 80px;
  height: 80px;
  object-fit: contain;
  margin-bottom: 0.9rem;
}

.charte-sig-blason-vide {
  width: 80px;
  height: 80px;
  border: 1px dashed #a06820;
  margin-bottom: 0.85rem;
}

.charte-sig-ink-wrap {
  width: 100%;
  max-width: 118px;
  margin: 0 auto 0.35rem auto;
}

.charte-sig-ink-slot.doc-export-signature {
  margin: 0;
  text-align: center;
}

.charte-sig-ink-slot img.doc-export-signature-ink {
  display: block;
  width: 100%;
  max-width: 118px;
  max-height: 42px;
  height: auto;
  margin: 0 auto;
}

.charte-sig-nom-legible {
  font-family: "IM Fell English", Georgia, serif;
  font-size: 0.58rem;
  color: #4a3428;
  font-style: italic;
  line-height: 1.2;
  margin-bottom: 0.35rem;
  max-width: 100%;
  overflow-wrap: anywhere;
  hyphens: auto;
}

.charte-sig-ligne {
  width: 100%;
  height: 1px;
  background: #a06820;
  margin-bottom: 0.3rem;
}

.charte-sig-label {
  font-family: "IM Fell English", Georgia, serif;
  font-size: 0.65rem;
  color: #5c1400;
  font-style: italic;
  letter-spacing: 0.02em;
}
'

$pageOverride = $pageOverride + $signatureCss

# ---------------------------------------------------------------------------
# Titre du document
# ---------------------------------------------------------------------------

$institutionHtml = [System.Net.WebUtility]::HtmlEncode($InstitutionNom)

$titlePlain = $baseName
$rxH1 = [regex]'(?s)<h1[^>]*>(?<t>[\s\S]*?)</h1>'
$mH1  = $rxH1.Match($bodyInner)
if ($mH1.Success) {
  $titlePlain = [regex]::Replace($mH1.Groups['t'].Value, '<[^>]+>', '').Trim()
  if ([string]::IsNullOrWhiteSpace($titlePlain)) { $titlePlain = $baseName }
}

# ---------------------------------------------------------------------------
# Assemblage HTML
# ---------------------------------------------------------------------------

$shellPath = Join-Path $PSScriptRoot 'avis_shell.html'
$cssPath   = Join-Path $PSScriptRoot 'avis_print.css'

$cssResolved = (Resolve-Path -LiteralPath $cssPath).Path
$cssHref     = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $cssResolved

$shell = Get-Content -Path $shellPath -Raw -Encoding UTF8
$html  = $shell.
  Replace('__CSS_HREF__',        $cssHref).
  Replace('__PAGE_OVERRIDE__',   $pageOverride).
  Replace('__BLASON_HTML__',     $blasonHtml).
  Replace('__INSTITUTION_NOM__', $institutionHtml).
  Replace('__MARKDOWN_BODY__',   $bodyInner)

[System.IO.File]::WriteAllText($outFile, $html, [System.Text.UTF8Encoding]::new($false))

# ---------------------------------------------------------------------------
# Export PDF
# ---------------------------------------------------------------------------

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
