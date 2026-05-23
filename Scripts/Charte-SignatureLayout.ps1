# Signatures type Charte UBI
function Get-CharteSignatureBlockCss { return @'
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
'@ }
function ConvertTo-CharteFileUri {
  param([string] $AbsolutePath)
  $forward = $AbsolutePath.Replace('\', '/')
  return 'file:///' + [Uri]::EscapeUriString($forward)
}

# ---------------------------------------------------------------------------
# Blason : chemin local depuis href Pandoc (file:// ou chemin Windows)
# ---------------------------------------------------------------------------
function ConvertFrom-CharteBlasonHrefToPath {
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
    $blasonPath = ConvertFrom-CharteBlasonHrefToPath -Href $Matches[1]
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
    $imgUri = ConvertTo-CharteFileUri -AbsolutePath $blasonPrint
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
    [string] $HtmlAbsolutePath,
    [int[]] $RowSizes = @(3, 2),
    [string] $TitreHtml = '&#10022;&ensp;Signatures des Repr&eacute;sentants&ensp;&#10022;'
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

  $itemRx = [regex]::new(
    '(?s)<p>\s*<strong>(?<cite>[^<]+)</strong>.*?</p>\s*<div class="doc-export-signature"[^>]*>(?<sig>.*?)</div>',
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
