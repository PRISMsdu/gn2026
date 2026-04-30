<#
  Export HTML + PDF parchemin medieval pour la Charte Fondatrice de l'UBI.

  Identique a export_avis.ps1, avec une difference :
  le bloc de signatures (liste markdown "- **Cite** : [chemin_blason]")
  est remplace par un cartouche enlumines par signataire :
    Pour [Cite]  ->  blason  ->  signature calligraphiee  ->  ligne  ->  nom de la cite

  Prerequis :
    - Pandoc dans le PATH (https://pandoc.org)
    - Google Chrome ou Microsoft Edge (impression PDF headless)
    - Acces internet au moment de la generation (Google Fonts)

  Exemple (depuis la racine du depot) :
    .\Scripts\export_charte_UBI.ps1
    .\Scripts\export_charte_UBI.ps1 -MarkdownPath "Groupes\Banquiers - UBI\1 - Back de groupe\Charte_UBI.md"

  Sortie dans le meme repertoire que le .md :
    - Charte_UBI_yyyyMMdd_HHmmss.pdf
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
  [string] $PandocPath = ""
)

$ErrorActionPreference = "Stop"

# Noms calligraphies des representants par cite.
# La cle doit correspondre exactement au gras dans le markdown.
$signataireNoms = @{
  'Il-Irion'   = 'Aelindra Vorn'
  'Staal'      = 'Gordas Fen-Mael'
  'Palyr'      = 'Lysa Morwyn'
  'Ther-Felis' = 'Caelindis Thar'
  'Arthas'     = 'Borghal Fervaine'
}

# Chemins absolus des blasons par cite.
# Construits automatiquement depuis le dossier LivretsLocaux/Blasons
# (un niveau au-dessus du dossier Scripts/).
$blasonDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'LivretsLocaux\Blasons'
$signataireBlasons = @{
  'Il-Irion'   = Join-Path $blasonDir 'Blason_Il-Irion_+.png'
  'Staal'      = Join-Path $blasonDir 'Blason_Sfaal_+.png'
  'Palyr'      = Join-Path $blasonDir 'Blason_Palyr_+.png'
  'Ther-Felis' = Join-Path $blasonDir "Blason_Ther-F$([char]0xe9)lis_+.png"
  'Arthas'     = Join-Path $blasonDir 'Blason_Arthas_+.png'
}

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
# Cle interne pour blasons / noms (le markdown peut dire "Sfaal", le script "Staal").
# ---------------------------------------------------------------------------
function Resolve-CiteKey {
  param([string] $Cite)
  $c = $Cite.Trim()
  if ($c -eq 'Sfaal') { return 'Staal' }
  return $c
}

# ---------------------------------------------------------------------------
# Trace vectoriel type encre (courbes de Bézier, pas de police manuscrite).
# Deterministe : meme graine -> meme signature a chaque export.
# ---------------------------------------------------------------------------
function Build-InkPathD {
  param([string] $Seed)
  $bytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($Seed))
  $b = { param([int] $i) [int]$bytes[$i % 32] }
  $n = 9
  $xb = 6.0
  $xe = 194.0
  $inv = [Globalization.CultureInfo]::InvariantCulture
  $parts = [System.Text.StringBuilder]::new()
  $prevX = $xb + (& $b 0) / 40.0
  $prevY = 22.0 + ([int](& $b 1) - 128) / 18.0
  [void]$parts.AppendFormat($inv, 'M{0:0.##},{1:0.##}', $prevX, $prevY)
  for ($k = 1; $k -le $n; $k++) {
    $t = $k / $n
    $x = $xb + $t * ($xe - $xb) + ([int](& $b ($k + 2)) - 128) / 35.0
    $y = 22.0 + [math]::Sin($t * 5.2 + (& $b 5) / 50.0) * 11.0 + ([int](& $b ($k + 10)) - 128) / 28.0
    $c1x = $prevX + ($x - $prevX) * 0.35 + ([int](& $b ($k + 15)) - 128) / 25.0
    $c1y = $prevY + ([int](& $b ($k + 16)) - 128) / 22.0
    $c2x = $prevX + ($x - $prevX) * 0.72 + ([int](& $b ($k + 17)) - 128) / 26.0
    $c2y = $y + ([int](& $b ($k + 18)) - 128) / 30.0
    [void]$parts.AppendFormat($inv, 'C{0:0.##},{1:0.##},{2:0.##},{3:0.##},{4:0.##},{5:0.##}',
      $c1x, $c1y, $c2x, $c2y, $x, $y)
    $prevX = $x
    $prevY = $y
  }
  # Petit juron final (boucle d'encre)
  $fx = [math]::Min(198.0, $prevX + 5.0 + (& $b 24) / 40.0)
  $fy = $prevY - 4.0 - (& $b 25) / 50.0
  $mx = ($prevX + $fx) / 2.0 + ([int](& $b 26) - 128) / 30.0
  $my = ($prevY + $fy) / 2.0 - 3.0 - (& $b 27) / 45.0
  [void]$parts.AppendFormat($inv, 'Q{0:0.##},{1:0.##},{2:0.##},{3:0.##}', $mx, $my, $fx, $fy)
  return $parts.ToString()
}

function Get-InkSignatureSvgHtml {
  param([string] $Seed)
  if ([string]::IsNullOrWhiteSpace($Seed)) { $Seed = '?' }
  $pathD = Build-InkPathD -Seed $Seed
  $id = [System.BitConverter]::ToString(
    [System.Security.Cryptography.MD5]::Create().ComputeHash(
      [System.Text.Encoding]::UTF8.GetBytes($Seed))).Replace('-', '').Substring(0, 10)
  $html = @"
      <div class="charte-sig-ink-wrap">
        <svg class="charte-sig-ink" viewBox="0 0 200 48" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
          <defs>
            <filter id="ink-soft-$id" x="-5%" y="-5%" width="110%" height="110%">
              <feGaussianBlur in="SourceGraphic" stdDeviation="0.18" result="b" />
              <feMerge>
                <feMergeNode in="b" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>
          </defs>
          <path class="charte-sig-ink-under" d="$pathD" fill="none" stroke="#684434" stroke-width="1.95" stroke-linecap="round" stroke-linejoin="round" opacity="0.22" />
          <path class="charte-sig-ink-main" d="$pathD" fill="none" stroke="#1f1210" stroke-width="1.18" stroke-linecap="round" stroke-linejoin="round" filter="url(#ink-soft-$id)" />
        </svg>
      </div>
"@
  return $html
}

# ---------------------------------------------------------------------------
# Construction du bloc de signatures enluminees
# Detecte la <ul> contenant des items "- **Cite** : [...]"
# et la remplace par un cartouche HTML par signataire.
# Les blasons sont fournis via $BlasonsByCite (hashtable cite -> chemin absolu).
# ---------------------------------------------------------------------------
function Build-SignatureBlock {
  param(
    [string]    $BodyHtml,
    [hashtable] $NomsByCite,
    [hashtable] $BlasonsByCite
  )

  # Trouve la <ul> qui contient au moins un item de type : <strong>X</strong> : [...]
  $ulPattern   = '(?s)<ul>.*?</ul>'
  $itemPattern = '<strong>([^<]+)</strong>\s*:\s*\['
  $sigListMatch = $null

  foreach ($m in [regex]::Matches($BodyHtml, $ulPattern)) {
    if ([regex]::IsMatch($m.Value, $itemPattern)) {
      $sigListMatch = $m
      break
    }
  }

  if (-not $sigListMatch) {
    Write-Warning 'Bloc de signatures non detecte dans le HTML genere - la liste reste inchangee.'
    return $BodyHtml
  }

  $items = [regex]::Matches($sigListMatch.Value, $itemPattern)
  $sb    = [System.Text.StringBuilder]::new()

  foreach ($item in $items) {
    $cite      = $item.Groups[1].Value.Trim()
    $citeKey   = Resolve-CiteKey -Cite $cite
    $nom       = if ($NomsByCite.ContainsKey($citeKey))    { $NomsByCite[$citeKey] }    else { '' }
    $imgPath   = if ($BlasonsByCite.ContainsKey($citeKey)) { $BlasonsByCite[$citeKey] } else { '' }

    $citeEnc = [System.Net.WebUtility]::HtmlEncode($cite)
    $nomEnc  = [System.Net.WebUtility]::HtmlEncode($nom)
    $seedInk = "${nom}|${citeKey}"
    $inkHtml = Get-InkSignatureSvgHtml -Seed $seedInk

    if ($imgPath -and (Test-Path -LiteralPath $imgPath -ErrorAction SilentlyContinue)) {
      $imgUri  = ConvertTo-FileUri -AbsolutePath $imgPath
      $imgHtml = '<img src="' + $imgUri + '" class="charte-sig-blason" alt="Blason ' + $citeEnc + '" />'
    } else {
      if ($imgPath) { Write-Warning "Blason introuvable : $imgPath" }
      $imgHtml = '<div class="charte-sig-blason-vide"></div>'
    }

    [void]$sb.Append(
      "`n    <div class=" + '"' + 'charte-signature' + '"' + '>' +
      "`n      <div class=" + '"' + 'charte-sig-pour' + '"' + ">Pour $citeEnc</div>" +
      "`n      $imgHtml" +
      "`n      $inkHtml" +
      "`n      <div class=" + '"' + 'charte-sig-nom-legible' + '"' + ">$nomEnc</div>" +
      "`n      <div class=" + '"' + 'charte-sig-ligne' + '"' + '></div>' +
      "`n      <div class=" + '"' + 'charte-sig-label' + '"' + ">$citeEnc</div>" +
      "`n    </div>"
    )
  }

  $titreTxt  = '&#10022;&ensp;Signatures des Repr&eacute;sentants&ensp;&#10022;'
  $blockHtml = '<section class="charte-signatures">' + "`n" +
               '  <div class="charte-signatures-titre">' + $titreTxt + '</div>' + "`n" +
               '  <div class="charte-signatures-grille">' + $sb.ToString() + "`n  </div>" + "`n" +
               '</section>'

  return $BodyHtml.Replace($sigListMatch.Value, $blockHtml)
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

# Supprimer le h1 (affiche dans l'en-tete)
$bodyInner = [regex]::Replace($bodyInner, '(?s)<h1[^>]*>.*?</h1>', '', 1)

# Remplacer la liste de signatures par le cartouche enluminé
$bodyInner = Build-SignatureBlock -BodyHtml $bodyInner -NomsByCite $signataireNoms -BlasonsByCite $signataireBlasons

# ---------------------------------------------------------------------------
# Blason UBI : detection dans le repertoire du .md (pour l'en-tete institution)
# ---------------------------------------------------------------------------

$blasonSrc = ''
foreach ($ext in @('png', 'jpg', 'jpeg', 'webp')) {
  $found = Get-ChildItem -Path $mdDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^[Bb]lason_.*\.' + $ext + '$' } |
    Select-Object -First 1
  if ($found) {
    $blasonSrc = Get-RelativeUriPath -FromAbsoluteFile $outFile -ToAbsoluteFile $found.FullName
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
  flex-wrap: wrap;
  justify-content: center;
  align-items: flex-start;
  gap: 2.25rem 1.85rem;
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

.charte-sig-ink {
  width: 100%;
  height: auto;
  display: block;
  overflow: visible;
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
