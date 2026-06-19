<#
  Export HTML + PDF parchemin medieval pour un avis GN a partir d'un fichier .md.

  Prerequis :
    - Pandoc dans le PATH (https://pandoc.org)
    - Google Chrome ou Microsoft Edge (impression PDF headless)
    - Acces internet au moment de la generation (Google Fonts chargees cote navigateur)

  Navigateur : par defaut Chrome puis Edge. Pour forcer : -Browser Chrome | Edge

  Exemples (depuis la racine du depot) :
    .\Scripts\export_avis.ps1 -MarkdownPath "Groupes\Banquiers - UBI\1 - Back de groupe\Avis_depot_biens_UBI.md"
    .\Scripts\export_avis.ps1 -MarkdownPath "Groupes\...\Avis_xxx.md" -Format A3 -InstitutionNom "Guilde des Ports Unis"

  Sortie dans le meme repertoire que le .md :
    - nom_avis_yyyyMMdd_HHmmss.pdf

  Marqueurs (*Signature*: Nom) : PNG automatique via generate_signature_ink.ps1 (Scripts\\Signatures).
  Pour forcer la regeneration des PNG deja presents : -ForceSignatures
#>

[CmdletBinding(DefaultParameterSetName = 'ByPath')]
param(
  [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, Position = 0)]
  [string] $MarkdownPath,

  [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
  [string] $AvisFileName,

  [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
  [string] $AvisDirectory,

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
. (Join-Path $PSScriptRoot "Expand-MarkdownExportSignatures.ps1")
. (Join-Path $PSScriptRoot 'Export-ImageForPrint.ps1')
. (Join-Path $PSScriptRoot 'Resolve-ExportBlasonPath.ps1')
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

  $browserArgs = @(
    '--headless=new'
    '--disable-gpu'
    '--no-first-run'
    '--no-default-browser-check'
    '--no-pdf-header-footer'
    $pdfArg
    $htmlUri
  )

  $p = Start-Process -FilePath $BrowserExe -ArgumentList $browserArgs -Wait -PassThru -NoNewWindow
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

if ($PSCmdlet.ParameterSetName -eq 'ByName') {
  $name = $AvisFileName.Trim()
  if ($name -notmatch '\.md$') {
    $name = "$name.md"
  }
  $dir = [System.IO.Path]::GetFullPath($AvisDirectory)
  $MarkdownPath = Join-Path $dir $name
}

$md = Resolve-Path -LiteralPath $MarkdownPath
$mdDir = Split-Path -Parent $md
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($md.Path)

if (-not $OutputHtmlPath) {
  $OutputHtmlPath = Join-Path $mdDir "${baseName}_avis_print.html"
}

$outFile = [System.IO.Path]::GetFullPath($OutputHtmlPath)
$outDir = Split-Path -Parent $outFile

$pdfStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$pdfFile = Join-Path $mdDir "${baseName}_avis_${pdfStamp}.pdf"
$pdfFile = [System.IO.Path]::GetFullPath($pdfFile)

if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# --- Pandoc : Markdown -> corps HTML ---

$pandocExe = Get-PandocExecutable -ExplicitPath $PandocPath
if (-not $pandocExe) {
  Write-Error "Pandoc introuvable. Ajoutez Pandoc au PATH ou passez -PandocPath."
}

$markdownUtf8Raw = Get-Content -LiteralPath $md.Path -Raw -Encoding UTF8
$markdownSansComments = [regex]::Replace($markdownUtf8Raw, "<!--[\s\S]*?-->", "")

$pandocSourcePath = $md.Path
$tempMdExpanded = ""
if ($markdownSansComments -match "(?msi)\(\*\s*[Ss]ignature\s*\*\s*:") {
  $expandedMdText = Expand-MarkdownInkSignatureMarkers -MarkdownRaw $markdownSansComments `
    -HtmlAbsolutePath $outFile -ScriptsPSScriptRoot $PSScriptRoot `
    -ForceRegenerate:$ForceSignatures
  $tempMdExpanded = [System.IO.Path]::GetTempFileName() + ".md"
  [System.IO.File]::WriteAllText($tempMdExpanded, $expandedMdText,
    ([System.Text.UTF8Encoding]::new($false)))
  $pandocSourcePath = $tempMdExpanded
}

$tempBody = [System.IO.Path]::GetTempFileName() + ".html"
try {
  & $pandocExe $pandocSourcePath -f markdown -t html5 --standalone=false -o $tempBody
  $bodyInner = Get-Content -Path $tempBody -Raw -Encoding UTF8
  if ($bodyInner -match '(?s)<body[^>]*>(.*)</body>') {
    $bodyInner = $Matches[1].Trim()
  }
} finally {
  Remove-Item -Force -LiteralPath $tempBody -ErrorAction SilentlyContinue
  if ($tempMdExpanded -ne "") {
    Remove-Item -Force -LiteralPath $tempMdExpanded -ErrorAction SilentlyContinue
  }
}

# Supprimer le h1 du corps (il sera affiche dans l'entete)
$bodyInner = [regex]::Replace($bodyInner, '(?s)<h1[^>]*>.*?</h1>', '', 1)

# --- Blason : dossier du .md, puis LivretsLocaux/Blasons, puis chemin force ---

$blasonSrc = ''
$foundBlasonPath = Resolve-ExportBlasonPath -MarkdownDirectory $mdDir -MarkdownPath $md.Path `
  -InstitutionNom $InstitutionNom -MarkdownRaw $markdownUtf8Raw -ScriptsRoot $PSScriptRoot `
  -ForcedBlasonPath $env:GN_AVIS_BLASON_PATH
if ($foundBlasonPath) {
  $blasonPrint = Optimize-ExportImageForPrint -SourcePath $foundBlasonPath -MaxEdgePx 220 -CacheDir $exportImageCacheDir
  $blasonSrc = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $blasonPrint
}

if ($blasonSrc) {
  $blasonHtml = '<img src="' + $blasonSrc + '" class="avis-blason" alt="Blason" />'
} else {
  $blasonHtml = ''
}

function Add-HtmlElementClass {
  param(
    [string] $Attrs,
    [string] $ClassName
  )
  if ($Attrs -match 'class="([^"]*)"') {
    $existing = $Matches[1].Trim()
    if (($existing -split '\s+') -contains $ClassName) {
      return $Attrs
    }
    return ($Attrs -replace 'class="[^"]*"', ('class="' + $existing + ' ' + $ClassName + '"'))
  }
  return ($Attrs + (' class="' + $ClassName + '"'))
}

function Normalize-AvisPourCityLabel {
  param([string] $Raw)
  $label = $Raw.Trim()
  if ($label -match '^\s*(.+?)\s*:') { $label = $Matches[1].Trim() }
  if ($label -match '^(?i)la\s+') { $label = $label -replace '^(?i)la\s+', '' }
  if ($label -match "(?i)^l'") { $label = $label.Substring(2).Trim() }
  return $label
}

function Resolve-AvisSealCityKey {
  param(
    [string] $CityLabel,
    [hashtable] $SealSrcByCity
  )

  $city = Normalize-AvisPourCityLabel -Raw $CityLabel
  if ($city -like 'Ther-F*lis') { return 'Ther-Félis' }
  if ($city -like '*Styrgie*') { return 'Styrgie' }
  if ($city -match 'Guilde|Ports Unis') { return 'Ther-Félis' }
  if ($city -match 'Conseil des Oblats') { return 'Il-Irion' }
  if ($city -match '(?i)aquil') { return 'Styrgie' }
  if ($city -match 'Empire|Tch[eéè]l') { return 'Styrgie' }
  if ($city -match 'Sangs des Steppes|Fraternit') { return 'Styrgie' }
  if ($city -match 'UBI|Union bancaire|Banque d''Ulghart') { return 'UBI' }
  if ($SealSrcByCity.ContainsKey($city)) { return $city }
  foreach ($slug in (Get-ExportBlasonSlugsFromText -Text $city)) {
    if ($SealSrcByCity.ContainsKey($slug)) { return $slug }
  }
  return $null
}

function Add-AvisSealToSignatureDiv {
  param(
    [string] $SignatureDivHtml,
    [string] $CityKey,
    [hashtable] $SealSrcByCity,
    [hashtable] $SealVariantState,
    [string] $SealAlt
  )
  if ($SignatureDivHtml -match 'doc-export-signature-seal') { return $SignatureDivHtml }
  if ([string]::IsNullOrWhiteSpace($CityKey) -or -not $SealSrcByCity.ContainsKey($CityKey)) {
    return $SignatureDivHtml
  }
  $variant = $SealVariantState.Index % 5
  $SealVariantState.Index += 1
  $sealHtml = '<img src="' + $SealSrcByCity[$CityKey] + '" alt="' + $SealAlt + '" class="doc-export-signature-seal seal-variant-' + $variant + '" />'
  return ($SignatureDivHtml -replace '</div>\s*$', ($sealHtml + "`n</div>"))
}

# --- Sceaux de signature : option archives ---

if ($env:GN_AVIS_SIGNATURE_SEALS -eq 'archives') {
  $rxSigDivClosed = '<div class="doc-export-signature">(?:(?!</div>).)*</div>'
  $rxPourPartyLine = '(?<label><p>Pour\s+(?<city>[\s\S]*?)</p>\s*)'
  $rxPourPartyBlock = '<p>Pour\s+[\s\S]*?</p>\s*' + $rxSigDivClosed
  $rxFooterAfterParties = '(?=\s*<p>\s*T.moin\s+bancaire|\s*<p>\s*(?:Droit de garde UBI|Droit d''enregistrement UBI|Mention de classement)|\s*</section>|\s*$)'

  $bodyInner = [regex]::Replace($bodyInner, '<p>\s*(Notice UBI\s*:[\s\S]*?)</p>', '<p class="archive-notice">$1</p>', 1)
  $bodyInner = [regex]::Replace($bodyInner, '<p>\s*(Droit de garde UBI\s*:[\s\S]*?)</p>', '<p class="archive-fee-mention">$1</p>', 1)
  $bodyInner = [regex]::Replace($bodyInner, '<p>\s*(Mention de classement\s*:[\s\S]*?)</p>', '<p class="archive-closing-mention">$1</p>', 1)
  $contractBodyRegex = [regex]'(?s)(?<header><p>\s*CONTRAT[\s\S]*?</p>)(?<body>[\s\S]*?)(?=<p>Pour\s+)'
  $contractBodyEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      $body = [regex]::Replace($m.Groups['body'].Value, '<p>(?!\s*(?:Pour\s|T.moin bancaire|Droit de garde UBI|Droit d''enregistrement UBI|Mention de classement))', '<p class="archive-contract-body">')
      return ($m.Groups['header'].Value + $body)
    }
  $bodyInner = $contractBodyRegex.Replace($bodyInner, $contractBodyEvaluator, 1)

  $sealBaseDir = Join-Path (Get-Location).Path 'LivretsLocaux\Blasons'
  $sealFilesByCity = @{
    'Il-Irion' = 'Sceau_Il-Irion.png'
    'Sfaal' = 'Sceau_Sfaal.png'
    'Palyr' = 'Sceau_Palyr.png'
    'Ther-Félis' = 'Sceau_Ther-Felis.png'
    'Arthas' = 'Sceau_Arthas.png'
    'Styrgie' = 'Sceau_Styrgie.png'
    'UBI' = 'Sceau_UBI.png'
  }
  $sealSrcByCity = @{}
  foreach ($city in $sealFilesByCity.Keys) {
    $sealPath = Join-Path $sealBaseDir $sealFilesByCity[$city]
    if (-not (Test-Path -LiteralPath $sealPath)) {
      Write-Error "Sceau introuvable pour $city : $sealPath"
    }
    $sealPrint = Optimize-ExportImageForPrint -SourcePath $sealPath -MaxEdgePx 96 -CacheDir $exportImageCacheDir
    $sealSrcByCity[$city] = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $sealPrint
  }
  $sealVariantState = @{ Index = 0 }

  $citySealRegex = [regex]"(?s)$rxPourPartyLine(?<sig>$rxSigDivClosed)"
  $citySealEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      $city = $m.Groups['city'].Value.Trim()
      $cityKey = Resolve-AvisSealCityKey -CityLabel $city -SealSrcByCity $sealSrcByCity
      if (-not $cityKey) { return $m.Value }
      $sealAlt = [System.Net.WebUtility]::HtmlEncode("Sceau $city")
      $sig = Add-AvisSealToSignatureDiv -SignatureDivHtml $m.Groups['sig'].Value -CityKey $cityKey `
        -SealSrcByCity $sealSrcByCity -SealVariantState $sealVariantState -SealAlt $sealAlt
      return ($m.Groups['label'].Value + $sig)
    }
  $bodyInner = $citySealRegex.Replace($bodyInner, $citySealEvaluator)

  $citySealEnsureRegex = [regex]"(?s)$rxPourPartyLine(?<sig>$rxSigDivClosed)"
  $citySealEnsureEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      if ($m.Groups['sig'].Value -match 'doc-export-signature-seal') { return $m.Value }
      $city = $m.Groups['city'].Value.Trim()
      $cityKey = Resolve-AvisSealCityKey -CityLabel $city -SealSrcByCity $sealSrcByCity
      if (-not $cityKey) { return $m.Value }
      $sealAlt = [System.Net.WebUtility]::HtmlEncode("Sceau $city")
      $sig = Add-AvisSealToSignatureDiv -SignatureDivHtml $m.Groups['sig'].Value -CityKey $cityKey `
        -SealSrcByCity $sealSrcByCity -SealVariantState $sealVariantState -SealAlt $sealAlt
      return ($m.Groups['label'].Value + $sig)
    }
  $bodyInner = $citySealEnsureRegex.Replace($bodyInner, $citySealEnsureEvaluator)

  $partyBlockItemRx = [regex]"(?s)$rxPourPartyBlock"
  $partyRunRx = [regex]"(?s)(?<run>(?:$rxPourPartyBlock\s*)+)$rxFooterAfterParties"
  $partyRunEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      $blocks = $partyBlockItemRx.Matches($m.Groups['run'].Value)
      if ($blocks.Count -eq 0) { return $m.Value }
      $sb = New-Object System.Text.StringBuilder
      [void]$sb.Append('<div class="archive-signatures-grid">')
      foreach ($b in $blocks) {
        [void]$sb.Append('<div class="archive-party-signature">')
        [void]$sb.Append($b.Value.Trim())
        [void]$sb.Append('</div>')
      }
      [void]$sb.Append('</div>')
      return $sb.ToString()
    }
  $bodyInner = $partyRunRx.Replace($bodyInner, $partyRunEvaluator, 1)

  $witnessSealRegex = [regex]"(?s)(?<label><p>T.moin bancaire\s*:[\s\S]*?</p>\s*)(?<sig>$rxSigDivClosed)"
  $witnessSealEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      $sealAlt = [System.Net.WebUtility]::HtmlEncode('Sceau UBI')
      $sig = Add-AvisSealToSignatureDiv -SignatureDivHtml $m.Groups['sig'].Value -CityKey 'UBI' `
        -SealSrcByCity $sealSrcByCity -SealVariantState $sealVariantState -SealAlt $sealAlt
      return ($m.Groups['label'].Value + $sig)
    }
  $bodyInner = $witnessSealRegex.Replace($bodyInner, $witnessSealEvaluator)

  # Bloc signatures indivisible : reste en bas de page si la place suffit, sinon bascule entier.
  $sigSectionRx = [regex]'(?s)(?<block><h2[^>]*>\s*Signatures\s*</h2>(?<tail>[\s\S]*?))(?=\s*<p>\s*(?:Droit de garde UBI|Droit d''enregistrement UBI|Mention de classement)|\s*$)'
  $sigSectionEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      if ($m.Value -match 'archive-signatures-section') { return $m.Value }
      return '<section class="archive-signatures-section">' + $m.Groups['block'].Value + '</section>'
    }
  $bodyInner = $sigSectionRx.Replace($bodyInner, $sigSectionEvaluator, 1)
  if ($bodyInner -notmatch 'archive-signatures-section') {
    $gridOnlyRx = [regex]'(?s)<div class="archive-signatures-grid">(?:\s*<div class="archive-party-signature">[\s\S]*?</div>)+\s*</div>'
    $gridOnlyEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
        param([System.Text.RegularExpressions.Match]$m)
        return '<section class="archive-signatures-section">' + $m.Value + '</section>'
      }
    $bodyInner = $gridOnlyRx.Replace($bodyInner, $gridOnlyEvaluator, 1)
  }

  $orphanSigRx = [regex]"(?s)(?<prev><p>[\s\S]*?</p>\s*)?<sig>$rxSigDivClosed"
  $orphanSigEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      if ($m.Groups['sig'].Value -match 'doc-export-signature-seal') { return $m.Value }
      $prev = $m.Groups['prev'].Value
      $cityKey = $null
      $sealAlt = 'Sceau'
      if ($prev -match 'T.moin bancaire') {
        $cityKey = 'UBI'
        $sealAlt = 'Sceau UBI'
      }
      elseif ($prev -match 'Pour\s+([\s\S]*?)</p>') {
        $cityLabel = $Matches[1].Trim()
        $cityKey = Resolve-AvisSealCityKey -CityLabel $cityLabel -SealSrcByCity $sealSrcByCity
        $sealAlt = [System.Net.WebUtility]::HtmlEncode("Sceau $cityLabel")
      }
      if (-not $cityKey) { return $m.Value }
      $sig = Add-AvisSealToSignatureDiv -SignatureDivHtml $m.Groups['sig'].Value -CityKey $cityKey `
        -SealSrcByCity $sealSrcByCity -SealVariantState $sealVariantState -SealAlt $sealAlt
      return ($m.Groups['prev'].Value + $sig)
    }
  $bodyInner = $orphanSigRx.Replace($bodyInner, $orphanSigEvaluator)

  # Repères « Article » : espacement PDF via classe avis-article (h2 ou paragraphe **Article**).
  $h2ArticleRx = [regex]'<h2(?<attrs>[^>]*)>(?<inner>Article[^<]*)</h2>'
  $h2ArticleEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      $attrs = Add-HtmlElementClass -Attrs $m.Groups['attrs'].Value -ClassName 'avis-article'
      return ('<h2' + $attrs + '>' + $m.Groups['inner'].Value + '</h2>')
    }
  $bodyInner = $h2ArticleRx.Replace($bodyInner, $h2ArticleEvaluator)

  $pArticleRx = [regex]'<p(?<attrs>[^>]*)>\s*<strong>Article\s'
  $pArticleEvaluator = [System.Text.RegularExpressions.MatchEvaluator]{
      param([System.Text.RegularExpressions.Match]$m)
      $attrs = Add-HtmlElementClass -Attrs $m.Groups['attrs'].Value -ClassName 'avis-article'
      return ('<p' + $attrs + '><strong>Article ')
    }
  $bodyInner = $pArticleRx.Replace($bodyInner, $pArticleEvaluator)
}

# --- Format de page : surcharge CSS ---

if ($Format -eq 'A3') {
  $pageOverride = '@page { size: A3; margin: 25mm 22mm; } body.avis-document { width: 297mm; max-width: 297mm; min-height: 420mm; padding: 25mm 22mm; }'
} else {
  $pageOverride = ''
}

# --- Titre du document et institution ---

$institutionHtml = [System.Net.WebUtility]::HtmlEncode($InstitutionNom)

$titlePlain = $baseName
$rxH1 = [regex]'(?s)<h1[^>]*>(?<t>[\s\S]*?)</h1>'
$mH1 = $rxH1.Match($bodyInner)
if ($mH1.Success) {
  $titlePlain = [regex]::Replace($mH1.Groups['t'].Value, '<[^>]+>', '').Trim()
  if ([string]::IsNullOrWhiteSpace($titlePlain)) { $titlePlain = $baseName }
}

# --- Assemblage HTML ---

$shellPath = Join-Path $PSScriptRoot "avis_shell.html"
$cssOverridePath = $env:GN_AVIS_CSS_PATH
if ([string]::IsNullOrWhiteSpace($cssOverridePath)) {
  $cssPath = Join-Path $PSScriptRoot "avis_print.css"
} elseif ([System.IO.Path]::IsPathRooted($cssOverridePath)) {
  $cssPath = $cssOverridePath
} else {
  $cssPath = Join-Path $PSScriptRoot $cssOverridePath
}

$cssResolved = (Resolve-Path -LiteralPath $cssPath).Path
$cssHref = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $cssResolved

$shell = Get-Content -Path $shellPath -Raw -Encoding UTF8
if ($env:GN_AVIS_SIGNATURE_SEALS -eq 'archives') {
  $quickRef = [System.Net.WebUtility]::HtmlEncode($baseName)
  $archiveStampText = $env:GN_AVIS_ARCHIVE_STAMP_TEXT
  if ([string]::IsNullOrWhiteSpace($archiveStampText)) {
    $archiveStampText = 'Acte execute et clos.'
  }
  if ($archiveStampText -eq '__NO_STAMP__') {
    $shell = $shell.Replace('__TOP_RIGHT_HTML__', '')
  } else {
    $archiveStampHtml = [System.Net.WebUtility]::HtmlEncode($archiveStampText)
    $shell = $shell.Replace('__TOP_RIGHT_HTML__', '<div class="avis-archive-corner"><div class="avis-archive-ref">' + $quickRef + '</div><div class="avis-archive-stamp">' + $archiveStampHtml + '</div></div>')
  }
} else {
  $shell = $shell.Replace('__TOP_RIGHT_HTML__', '')
}
$html = $shell.
  Replace('__CSS_HREF__', $cssHref).
  Replace('__PAGE_OVERRIDE__', $pageOverride).
  Replace('__BLASON_HTML__', $blasonHtml).
  Replace('__INSTITUTION_NOM__', $institutionHtml).
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
