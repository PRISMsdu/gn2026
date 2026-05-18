<#
  Export PDF pour documents officiels Markdown (contrats, lettres d ordre, avis génériques).
  Apparence : meme charte typo que les Avis UBI (avis_print.css), sans bandeau GN.
  Aucun ornement Unicode en en-tete ni sur les lignes horizontales (-- en markdown) ni sur les titres h2,
  car le moteur PDF de Chrome les degrade souvent en mojibake.
  Export doc-officiel : par defaut, chaque titre h2 sous #contenu-avis commence sur une nouvelle page.
  Pour enchaîner les sections sans saut de page : -nochangepage (ou -SkipH2PageBreak).

  Prerequis : Pandoc, Chrome ou Edge, accès Google Fonts lors de la generation.

  Par defaut : pas de bandeau institution (seul un léger ornement sous le titre de page navigateur).

  Pour un bandeau du type Union bancaire : -InstitutionLigne "Union bancaire d Il-Irion - Citadelle d Ulghart"
  Dans ce cas, si un fichier Blason_*.png|jpg existe dans le repertoire du .md, il est inclus comme pour export_avis.

  Exemples (depuis la racine du depot) :
    .\Scripts\export_doc.ps1 -MarkdownPath "Groupes\MiVI\1 - Back de groupe\Lettre_ordre_Oblats_Questeur_Montfou.md"
    .\Scripts\export_doc.ps1 -MarkdownPath "Contrats_et_Livres\CO-II-545-001.md"
    .\Scripts\export_doc.ps1 -MarkdownPath "Groupes\Banquiers - UBI\1 - Back de groupe\Avis_depot_documents_UBI.md" -InstitutionLigne "Union bancaire d Il-Irion - Citadelle d Ulghart"
    .\Scripts\export_doc.ps1 -MarkdownPath "codex\Monde\Fonctionnement de la bourse des échanges de la Confédération.md" -nochangepage

  Sortie : dossier du .md, fichier <nom>_doc_yyyyMMdd_HHmmss.pdf

  Signatures automatiques (PNG avec generate_signature_ink.ps1) :
    ligne du type (*Signature*: Nom...) ou avec espaces autour du mot Signature ; le Nom est passe en -Seed ;
    le fichier est Scripts\Signatures puis insere avec un chemin relatif vers la page d impression.

  Pour forcer la regeneration des PNG deja presents : -ForceSignatures

  Disposition signatures type Charte UBI (cartouches, blasons, taille reduite) :
    -CharteSignatures
  Format markdown : **Cite** : ![blason](chemin) puis (*Signature*: Nom) — voir Charte_UBI.md
#>

[CmdletBinding(DefaultParameterSetName = 'ByPath')]
param(
  [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 0)]
  [string] $MarkdownPath,

  [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
  [string] $DocumentFileName,

  [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
  [string] $DocumentDirectory,

  [string] $OutputHtmlPath = "",
  [string] $InstitutionLigne = "",
  [ValidateSet('A4', 'A3')]
  [string] $Format = 'A4',
  [switch] $SkipPdf,
  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',
  [string] $ChromePath = "",
  [string] $PandocPath = "",
  [switch] $ForceSignatures,
  [Alias('nochangepage')]
  [switch] $SkipH2PageBreak,
  [switch] $CharteSignatures
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Expand-MarkdownExportSignatures.ps1')
. (Join-Path $PSScriptRoot 'Export-ImageForPrint.ps1')
. (Join-Path $PSScriptRoot 'Charte-SignatureLayout.ps1')
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
    if (-not (Test-Path -LiteralPath $ExplicitPath)) { Write-Error "PandocPath introuvable : $ExplicitPath" }
    return (Resolve-Path -LiteralPath $ExplicitPath).Path
  }
  $cmd = Get-Command pandoc.exe -ErrorAction SilentlyContinue
  if (-not $cmd) { $cmd = Get-Command pandoc -ErrorAction SilentlyContinue }
  if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }
  foreach ($c in @(
      (Join-Path $env:ProgramFiles 'Pandoc\pandoc.exe')
      (Join-Path ${env:ProgramFiles(x86)} 'Pandoc\pandoc.exe')
    )) {
    if (Test-Path -LiteralPath $c) { return $c }
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
    }
    catch { }
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
  foreach ($p in @(
      (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
      (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe')
      (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
    )) {
    if (Test-Path -LiteralPath $p) { return $p }
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
  Write-Error 'Aucun navigateur trouve pour l export PDF.'
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
  $procArgs = @(
    '--headless=new'
    '--disable-gpu'
    '--no-first-run'
    '--no-default-browser-check'
    '--no-pdf-header-footer'
    $pdfArg
    $htmlUri
  )
  $p = Start-Process -FilePath $BrowserExe -ArgumentList $procArgs -Wait -PassThru -NoNewWindow
  $code = $p.ExitCode
  if ($null -eq $code) { $code = 0 }
  if (-not (Test-Path -LiteralPath $PdfAbsolutePath)) {
    Write-Error "Le fichier PDF n a pas ete cree : $PdfAbsolutePath"
  }
  if ($code -ne 0) {
    Write-Warning "Navigateur exit code $code - PDF peut quand meme exister."
  }
}

function Get-ExtractedPlainFromFirstH1 {
  param([string] $Html)
  $rx = [regex]'(?s)<h1[^>]*>(?<t>.*?)</h1>'
  $m = $rx.Match($Html)
  if (-not $m.Success) { return '' }
  return [regex]::Replace($m.Groups['t'].Value, '<[^>]+>', '').Trim()
}

# --- MarkdownPath ---

if ($PSCmdlet.ParameterSetName -eq 'ByName') {
  $name = $DocumentFileName.Trim()
  if ($name -notmatch '\.md$') { $name = "$name.md" }
  $MarkdownPath = Join-Path ([System.IO.Path]::GetFullPath($DocumentDirectory)) $name
}

$md = Resolve-Path -LiteralPath $MarkdownPath
$mdDir = Split-Path -Parent $md
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($md.Path)

if (-not $OutputHtmlPath) {
  $OutputHtmlPath = Join-Path $mdDir "${baseName}_document_print.html"
}

$outFile = [System.IO.Path]::GetFullPath($OutputHtmlPath)
$outDir = Split-Path -Parent $outFile
$pdfStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$pdfFile = [System.IO.Path]::GetFullPath((Join-Path $mdDir "${baseName}_doc_${pdfStamp}.pdf"))

if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$pandocExe = Get-PandocExecutable -ExplicitPath $PandocPath
if (-not $pandocExe) { Write-Error 'Pandoc introuvable.' }

$markdownUtf8Raw = Get-Content -LiteralPath $md.Path -Raw -Encoding UTF8
$markdownSansComments = [regex]::Replace($markdownUtf8Raw, '<!--[\s\S]*?-->', '')

$pandocSourcePath = $md.Path
$tempMdExpanded = ''
if ($markdownSansComments -match '(?msi)\(\*\s*[Ss]ignature\s*\*\s*:') {
  $sigMaxPx = if ($CharteSignatures) { 160 } else { 400 }
  $expandedMdText = Expand-MarkdownInkSignatureMarkers -MarkdownRaw $markdownSansComments `
    -HtmlAbsolutePath $outFile -ScriptsPSScriptRoot $PSScriptRoot `
    -ForceRegenerate:$ForceSignatures -SignatureMaxEdgePx $sigMaxPx
  $tempMdExpanded = [System.IO.Path]::GetTempFileName() + '.md'
  [System.IO.File]::WriteAllText($tempMdExpanded, $expandedMdText,
    ([System.Text.UTF8Encoding]::new($false)))
  $pandocSourcePath = $tempMdExpanded
}

$tempBody = [System.IO.Path]::GetTempFileName() + '.html'
try {
  & $pandocExe $pandocSourcePath -f markdown -t html5 --standalone=false -o $tempBody
  $bodyInner = Get-Content -LiteralPath $tempBody -Raw -Encoding UTF8
  if ($bodyInner -match '(?s)<body[^>]*>(.*)</body>') {
    $bodyInner = $Matches[1].Trim()
  }
}
finally {
  Remove-Item -Force -LiteralPath $tempBody -ErrorAction SilentlyContinue
  if ($tempMdExpanded -ne '') {
    Remove-Item -Force -LiteralPath $tempMdExpanded -ErrorAction SilentlyContinue
  }
}

# Commentaires MJ / HTML hors impression
$bodyInner = [regex]::Replace($bodyInner, '<!--[\s\S]*?-->', '')

if ($CharteSignatures) {
  $bodyInner = Build-CharteSignatureBlockFromHtml -BodyHtml $bodyInner `
    -ImageCacheDir $exportImageCacheDir -HtmlAbsolutePath $outFile `
    -TitreHtml '&#10022;&ensp;Signatures et visa&ensp;&#10022;'
}

$pageTitle = Get-ExtractedPlainFromFirstH1 -Html $bodyInner
if ([string]::IsNullOrWhiteSpace($pageTitle)) { $pageTitle = $baseName }
$pageTitleEsc = [System.Net.WebUtility]::HtmlEncode($pageTitle)

# Bandeau optionnel (-InstitutionLigne) : titre institution + blason local éventuel uniquement.
$blasonHtml = ''
$institutionHtml = ''
if (-not [string]::IsNullOrWhiteSpace($InstitutionLigne)) {
  foreach ($ext in @('png', 'jpg', 'jpeg', 'webp')) {
    $found = Get-ChildItem -LiteralPath $mdDir -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match '^[Bb]lason_.*\.' + $ext + '$' } |
      Select-Object -First 1
    if ($found) {
      $blasonPrint = Optimize-ExportImageForPrint -SourcePath $found.FullName -MaxEdgePx 220 -CacheDir $exportImageCacheDir
      $rel = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $blasonPrint
      $blasonHtml = '<img src="' + $rel + '" class="avis-blason" alt="" />'
      break
    }
  }
  $institutionHtml = '<div class="avis-institution-nom">' +
    ([System.Net.WebUtility]::HtmlEncode($InstitutionLigne.Trim())) + '</div>'
  $headerBlock = @"
  <header class="avis-entete doc-officiel-bandeau">
    <div class="avis-entete-inner">
      $blasonHtml
      $institutionHtml
    </div>
  </header>
"@
}
else {
  $headerBlock = ''
}

# surcharge : pas de lignes décoratives unicode sur les hr (le markdown "---" sinon produit â¸» etc. dans le PDF)
$docOverridesCss = @'

body.doc-officiel #contenu-avis hr {
  border: none;
  margin: 1.1rem 0;
  height: 0;
  border-top: 1px solid #a06820;
  overflow: visible;
}

body.doc-officiel #contenu-avis hr::after {
  content: none;
}

.doc-officiel-bandeau {
  padding-bottom: 0.85rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #a06820;
}

'@

if (-not $SkipH2PageBreak) {
  $docOverridesCss += @'

body.doc-officiel #contenu-avis h2 {
  break-before: page;
  page-break-before: always;
}

'@
}

$docOverridesCss += @'

body.doc-officiel #contenu-avis h2::before,
body.doc-officiel #contenu-avis h2::after {
  content: none;
}

'@
if ($Format -eq 'A3') {
  $pageOverride = '@page { size: A3; margin: 25mm 22mm; } body.avis-document { width: 297mm; max-width: 297mm; min-height: 420mm; padding: 25mm 22mm; }'
}
else {
  $pageOverride = ''
}
$pageOverride += $docOverridesCss
if ($CharteSignatures) {
  $pageOverride += (Get-CharteSignatureBlockCss)
}

$shellPath = Join-Path $PSScriptRoot 'document_shell.html'
$cssPath = Join-Path $PSScriptRoot 'avis_print.css'

$cssResolved = (Resolve-Path -LiteralPath $cssPath).Path
$cssHref = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $cssResolved

$shell = Get-Content -LiteralPath $shellPath -Raw -Encoding UTF8
$html = $shell.Replace('__CSS_HREF__', $cssHref).
  Replace('__PAGE_OVERRIDE__', $pageOverride).
  Replace('__PAGE_TITLE_ESCAPED__', $pageTitleEsc).
  Replace('__HEADER_HTML__', $headerBlock.Trim()).
  Replace('__MARKDOWN_BODY__', $bodyInner)

[System.IO.File]::WriteAllText($outFile, $html, [System.Text.UTF8Encoding]::new($false))

if ($SkipPdf) {
  Write-Host ('HTML conserve : ' + $outFile)
}
else {
  $script:ChromePathParam = $ChromePath
  $browserExe = Resolve-BrowserForPdf -Mode $Browser
  Write-Host ('Navigateur : ' + $browserExe)
  Export-HtmlFileToPdf -HtmlAbsolutePath $outFile -PdfAbsolutePath $pdfFile -BrowserExe $browserExe
  Remove-Item -LiteralPath $outFile -Force -ErrorAction Stop
  Write-Host ('PDF : ' + $pdfFile)
}
