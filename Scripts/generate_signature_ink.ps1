<#
.SYNOPSIS
  Génère une signature vectorielle ; écrit un SVG avec rectangle blanc de prévisualisation, puis selon `-SkipPng` un PNG
  dont le fond (**`-PngBackground`**) peut être transparent ou blanc.

.DESCRIPTION
  Le fichier SVG contient toujours un bloc `id="sig-view-bg"` (fond blanc pour prévisualiser le fichier seul).

  **`-PngBackground`** : **`Transparent`** (défaut) enlève ce rectangle avant conversion puis exporte avec fond transparent ;
  **`White`** convertit depuis le SVG **complet** (rectangle blanc conservé ou fond page blanche selon l’outil) pour un PNG
  à fond blanc opaque.

  Mode défaut RenderMode PenNib : le nom du signataire est rendu en police gothique / blackletter glyphe par glyphe
  (style italique si la famille le permet ; sinon repli romain ou gras), initiales élargies ~×1,3 par mot ou segment après trait d’union dans un même mot, resserrement et petits ponts d’encre
  entre suivantes dans la portion, léger déterminisme vertical sur quelques lettres à jambes, rotation pseudo-aléatoire
  par glyphe d’environ -5° à +5° dérivée du hachage du nom). Les contours proviennent de
  System.Drawing.GraphicsPath (AddString par caractère, rotation autour du point d’ancrage, Flatten puis union des sous-chemins) ; fill-rule evenodd ; même
  échelle viewBox que les autres variantes du script. Option Flourish : petite queue après le dernier contour.

  Les paramètres Energy, Flourish, Weight et Density infléchissent le rendu ou (mode RenderMode Procedural) la géométrie
  déterministe. La couleur d'encre s'applique au trait principal ; halo dérivé ou fixé comme avant.

  Export PNG :
    - ImageMagick (`magick` dans le PATH) en priorité
    - sinon Inkscape (`inkscape` en ligne de commande)

.EXAMPLE
  .\generate_signature_ink.ps1 -Seed "Aelindra Vorn" -OutputPng ".\signature.png"

.EXAMPLE
  .\generate_signature_ink.ps1 -Seed "Test" -Ink "#2a1540" -Energy Wild -Weight Bold -Density Tight `
    -OutputSvg ".\sig.svg" -OutputPng ".\sig.png" -PngWidthPx 1200

.EXAMPLE
  .\generate_signature_ink.ps1 -Seed "Nom" -PngBackground White -OutputPng ".\sig.png"

.NOTES
  ViewBox SVG par défaut : 200 x 48 (unités arbitraires).
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false, Position = 0)]
  [string] $Seed = 'Exemple Nom',

  [ValidateSet('Calm', 'Balanced', 'Wild')]
  [string] $Energy = 'Balanced',

  [ValidateSet('None', 'Short', 'Long')]
  [string] $Flourish = 'Short',

  [ValidateSet('Fine', 'Medium', 'Bold')]
  [string] $Weight = 'Medium',

  [ValidateSet('Airy', 'Normal', 'Tight')]
  [string] $Density = 'Normal',

  # Couleur du trait principal (#RRGGBB)
  [string] $Ink = '#1f1210',

  # Sous-couche (sombreur). Vide = dérivée automatiquement depuis -Ink
  [string] $InkHalo = '',

  # Opacité de la sous-couche (0..1)
  [ValidateRange(0, 1)]
  [double] $HaloOpacity = 0.22,

  [ValidateRange(-18, 18)]
  [double] $SlantDegrees = 0,

  [string] $OutputSvg = '',

  [string] $OutputPng = '',

  # Largeur du PNG en pixels (hauteur proportionnelle au viewBox)
  [ValidateRange(64, 8192)]
  [int] $PngWidthPx = 800,

  [string] $MagickPath = '',

  [string] $InkscapePath = '',

  [switch] $SkipPng,

  [switch] $PassThru,

  # Procédural = ancien tracé par courbes+hachage ; PenNib = contours glyphes GDI+ + remplissage encre (défaut).
  [ValidateSet('PenNib', 'Procedural')]
  [string] $RenderMode = 'PenNib',

  # Gothique / blackletter en priorité, puis sérif de secours.
  [string[]] $FontCandidates = @('Old English Text MT', 'Blackmoor LET', 'Engravers Old English', 'Times New Roman'),

  # Fond du fichier PNG après conversion (**Transparent** = retirer le rect SVG blanc puis alpha ; **White** = fond blanc).
  [ValidateSet('Transparent', 'White')]
  [string] $PngBackground = 'Transparent'
)

function Ensure-DrawingAssembly {
  if ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq 'System.Drawing' }) { return }
  try {
    Add-Type -AssemblyName System.Drawing | Out-Null
  }
  catch {
    throw 'RenderMode PenNib requiert l''assembly System.Drawing (PowerShell sous Windows Desktop, ou dotnet add package System.Drawing.Common).'
  }
}

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Couleurs
# ---------------------------------------------------------------------------
function Test-HexColor {
  param([string] $Color)
  return ($Color -match '^#[0-9A-Fa-f]{6}$')
}

function ConvertFrom-HexColor {
  param([string] $Hex)
  if (-not (Test-HexColor $Hex)) { throw "Couleur invalide (attendu #RRGGBB) : $Hex" }
  $r = [Convert]::ToInt32($Hex.Substring(1, 2), 16)
  $g = [Convert]::ToInt32($Hex.Substring(3, 2), 16)
  $b = [Convert]::ToInt32($Hex.Substring(5, 2), 16)
  return @{ R = $r; G = $g; B = $b }
}

function ConvertTo-HexColor {
  param([int] $R, [int] $G, [int] $B)
  $rr = [math]::Max(0, [math]::Min(255, $R))
  $gg = [math]::Max(0, [math]::Min(255, $G))
  $bb = [math]::Max(0, [math]::Min(255, $B))
  return ('#{0:x2}{1:x2}{2:x2}' -f $rr, $gg, $bb)
}

function Get-DerivedHaloColor {
  param([string] $MainHex)
  $c = ConvertFrom-HexColor $MainHex
  # Mélange vers brun-rouge parchemin + assombrissement léger (halo sous le trait)
  $hr = [int]($c.R * 0.55 + 120 * 0.45)
  $hg = [int]($c.G * 0.55 + 80 * 0.45)
  $hb = [int]($c.B * 0.55 + 60 * 0.45)
  return (ConvertTo-HexColor -R $hr -G $hg -B $hb)
}

# ---------------------------------------------------------------------------
# Résolution style -> nombres
# ---------------------------------------------------------------------------
function Get-StyleNumbers {
  param(
    [string] $Energy,
    [string] $Flourish,
    [string] $Weight,
    [string] $Density
  )

  $n = switch ($Energy) {
    'Calm' { 7 }
    'Balanced' { 9 }
    'Wild' { 11 }
  }

  $yAmp = switch ($Energy) {
    'Calm' { 7.2 }
    'Balanced' { 11.0 }
    'Wild' { 15.5 }
  }

  $span = switch ($Density) {
    'Airy' { @{ Xb = 2.0; Xe = 198.0 } }
    'Normal' { @{ Xb = 6.0; Xe = 194.0 } }
    'Tight' { @{ Xb = 22.0; Xe = 178.0 } }
  }

  $fl = switch ($Flourish) {
    'None' { @{ Mode = 0 } }   # pas de Q final
    'Short' { @{ Mode = 1; Scale = 1.0 } }
    'Long' { @{ Mode = 1; Scale = 1.65 } }
  }

  $w = switch ($Weight) {
    'Fine' { @{ Main = 0.88; Under = 1.45; UnderOp = 0.16 } }
    'Medium' { @{ Main = 1.18; Under = 1.95; UnderOp = 0.22 } }
    'Bold' { @{ Main = 1.58; Under = 2.45; UnderOp = 0.28 } }
  }

  return @{
    SegmentCount = $n
    YAmplitude   = $yAmp
    Xb           = $span.Xb
    Xe           = $span.Xe
    Flourish     = $fl
    Stroke       = $w
  }
}

function Get-SignatureNamePart {
  param([string] $SeedText)
  if ([string]::IsNullOrWhiteSpace($SeedText)) { return 'Signature' }
  $t = $SeedText.Trim()
  # Anciens scripts pouvaient suffixer "|Cité" : tout après '|' est ignoré.
  $pip = $t.IndexOf('|')
  if ($pip -ge 0) { $t = $t.Substring(0, $pip).Trim() }
  if ([string]::IsNullOrWhiteSpace($t)) { return 'Signature' }
  return $t
}

function Format-SignatureTitleCase {
  param([string] $Raw)
  if ([string]::IsNullOrWhiteSpace($Raw)) { return 'Signature' }
  $culture = [System.Globalization.CultureInfo]::InvariantCulture
  $sbOut = [System.Text.StringBuilder]::new()
  $words = @(($Raw.Trim()) -split '\s+' | Where-Object { $_ -ne '' })
  for ($wi = 0; $wi -lt $words.Count; $wi++) {
    if ($wi -gt 0) { [void]$sbOut.Append(' ') }
    $chunks = @($words[$wi] -split '-')
    for ($ci = 0; $ci -lt $chunks.Count; $ci++) {
      $ck = [string]$chunks[$ci]
      if ($ci -gt 0) { [void]$sbOut.Append('-') }
      if ($ck.Length -eq 0) { continue }
      $rest = ''
      if ($ck.Length -gt 1) { $rest = $ck.Substring(1).ToLowerInvariant() }
      [void]$sbOut.Append([char]::ToUpper($ck[0], $culture)); [void]$sbOut.Append($rest)
    }
  }
  $r = $sbOut.ToString()
  return $(if ([string]::IsNullOrWhiteSpace($r)) { 'Signature' } else { $r })
}

function Get-SignatureCapitalWordStartIndexes {
  param([string] $Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return @(0); }
  $len = $Text.Length
  $acc = New-Object System.Collections.Generic.List[int]
  [void]$acc.Add(0)
  for ($i = 1; $i -lt $len; $i++) {
    $pr = [string]$Text[$i - 1]
    if (($pr -eq ' ') -or ($pr -eq '-')) {
      while ($i -lt $len -and [char]::IsWhiteSpace([char]$Text[$i])) {
        $i++
      }
      if ($i -lt $len) { [void]$acc.Add($i); }
    }
  }
  # dédup trié sans décaler l’ordre
  return @([array]($acc | Sort-Object -Unique))
}

function Get-SignatureCapitalLetterIndexes {
  param([string] $Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return @(0) }
  $acc = New-Object System.Collections.Generic.List[int]
  $len = $Text.Length
  for ($ii = 0; $ii -lt $len; $ii++) {
    $chHi = [char]$Text[$ii]
    if (-not ([char]::IsLetter($chHi))) { continue }
    if ([char]::IsUpper($chHi)) { [void]$acc.Add([int]$ii); }
  }
  if ($acc.Count -gt 0) {
    return @([array]($acc | Sort-Object -Unique))
  }
  return (Get-SignatureCapitalWordStartIndexes -Text $Text)
}

function Measure-SignatureInkUnitCount {
  param([string] $Text)
  # Caractères hors espaces (lettres, tirets ponctuants comptés pour la densité d’échantillonnage).
  if ([string]::IsNullOrWhiteSpace($Text)) { return [int]8 }
  $t = (($Text.Trim()) -replace '\s', '')
  return [math]::Max(6, [int]$t.Length)
}

function Measure-BmpPrefixWidthPx {
  param(
    [System.Drawing.Graphics] $G,
    [System.Drawing.Font] $Font,
    [string] $Text,
    [int] $CharCountExclusive
  )
  if ($CharCountExclusive -le 0) { return 0.0 }
  $take = [math]::Min([math]::Min($CharCountExclusive, $Text.Length), $Text.Length)
  $pfx = ''
  try {
    $pfx = $Text.Substring(0, $take)
    $sx = ($G.MeasureString($pfx, $Font)).Width
    return [double]$sx
  }
  catch {
    return 0.0
  }
}

function Measure-BmpSubstringWidthPx {
  param([System.Drawing.Graphics] $G, [System.Drawing.Font] $Font, [string] $Substring)
  if ([string]::IsNullOrEmpty($Substring)) { return [double]0 }
  try { return [double]($G.MeasureString($Substring, $Font).Width); }catch { return 0.01 }
}

function Interpolate-YOnPolyAtXBmp {
  param([double[]] $Bx, [double[]] $By, [double] $xq)
  if ($Bx.Length -lt 2) { return [double]0 }
  $n = $Bx.Length
  if ($xq -le $Bx[0]) { return [double]$By[0] }
  if ($xq -ge $Bx[$n - 1]) { return [double]$By[$n - 1] }
  for ($i = 1; $i -lt $n; $i++) {
    if ($xq -le $Bx[$i]) {
      $den = [double]($Bx[$i] - $Bx[$i - 1])
      if ([math]::Abs($den) -lt 1e-9) {
        return [double]$By[$i - 1]; }
      $t = ($xq - $Bx[$i - 1]) / $den
      return [double]((1.0 - $t) * $By[$i - 1] + $t * $By[$i])
    }
  }
  return [double]$By[$n - 1]
}

function Add-LetterEmphasisLoopsBmp {
  param(
    [double[]] $BxIn,
    [double[]] $ByIn,
    [string] $PlainFormatted,
    [System.Drawing.Graphics] $Gpx,
    [System.Drawing.Font] $FontBmp,
    [double] $OriginLeftPx,
    [byte[]] $SaltByte
  )
  # Arche + demi-boucle avant le glyphe (majuscules du nom affiché ; sinon débuts de mots).
  $n = $BxIn.Length
  if ($n -lt 3) {
    return @{ Xs = $BxIn; Ys = $ByIn }
  }
  $outX = New-Object double[] $n
  $outY = New-Object double[] $n
  [array]::Copy($BxIn, $outX, $n)
  [array]::Copy($ByIn, $outY, $n)

  $starts = Get-SignatureCapitalLetterIndexes -Text $PlainFormatted

  foreach ($wi in $starts) {
    if ($wi -lt 0 -or $wi -ge $PlainFormatted.Length) { continue }
    try {
      $pfxW = (Measure-BmpPrefixWidthPx -G $Gpx -Font $FontBmp -Text $PlainFormatted -CharCountExclusive $wi)
    }
    catch { continue }

    $xS = [double]$OriginLeftPx + [double]$pfxW
    $rem = $PlainFormatted.Length - $wi
    if ($rem -le 0) { continue }
    if ([char]::IsWhiteSpace([char]$PlainFormatted[$wi])) { continue }
    $oneCh = $PlainFormatted.Substring($wi, 1)
    $cw = (Measure-BmpSubstringWidthPx -G $Gpx -Font $FontBmp -Substring $oneCh)
    # Majuscules gothiques : arche plus large que les minuscules
    $isCap = ([char]::IsUpper([char]$oneCh))
    $mulW = if ($isCap) { 1.88 } else { 1.52 }
    $glyW = [math]::Max(10.6, ($cw * $mulW))
    $lead = [math]::Min(11.0, $glyW * 0.42)
    $xE = $xS + $glyW
    $xLo = $xS - $lead

    $ampBase = if ($isCap) { 35.8 } else { 20.8 }
    $amp = $ampBase + (($SaltByte[($wi * 13) % 32] % 14) / 1.45)
    $phs = [double](0.46 + (($SaltByte[($wi + 5) % 32] / 255.0) * 0.58))
    $loopHarm = 1.14 + (($SaltByte[($wi * 3) % 32] % 8) / 36.0)

    for ($i = 0; $i -lt $n; $i++) {
      $xv = [double]$outX[$i]
      if ($xv -lt ($xLo - 0.6) -or ($xv -gt ($xE + 1.1))) { continue }
      $span = [math]::Max(1e-6, ($xE - $xLo))
      $u = [math]::Max(0.0, [math]::Min(1.0, (($xv - $xLo) / $span)))
      $arch = [math]::Sin($u * [math]::PI)
      $secondary = [math]::Sin($u * [math]::PI * $loopHarm)
      $bend = ($arch * $amp) + ($secondary * $amp * 0.24)
      $yRef = [double](Interpolate-YOnPolyAtXBmp -Bx $BxIn -By $ByIn -xq $xv)
      $bulgeMagn = if ($isCap) { (6.2 + (($SaltByte[$wi % 32] % 11) / 4.2)) } else { (4.4 + (($SaltByte[$wi % 32] % 9) / 5.9)) }
      $bulgeCapMul = if ($isCap) { 1.06 } else { 0.74 }
      $bulgeX = [math]::Sin($u * [math]::PI * 2.06) * $bulgeMagn * ($arch + 0.17) * $bulgeCapMul
      $outX[$i] = [double]$outX[$i] + $bulgeX
      $outY[$i] = $yRef - ($bend * (0.52 + $phs)) - ($arch * $amp * 0.14)
    }
  }

  return @{ Xs = $outX; Ys = $outY }
}

function Apply-SignatureTerminalStyleBmp {
  param([double[]] $Bx, [double[]] $By, [byte[]] $Salt)
  if ($Bx.Length -lt 6) {
    return @{ Xs = $Bx; Ys = $By }
  }

  $mode = [int]($Salt[29] % 3)
  $lx = New-Object System.Collections.Generic.List[double]; foreach ($v in $Bx) { [void]$lx.Add([double]$v) }
  $ly = New-Object System.Collections.Generic.List[double]; foreach ($v in $By) { [void]$ly.Add([double]$v) }

  $last = $lx.Count - 1
  $dx = [double]($lx[$last] - $lx[$last - 1]); $dy = [double]($ly[$last] - $ly[$last - 1])
  $ln = [math]::Sqrt([math]::Max(1e-12, $dx * $dx + $dy * $dy))
  $txn = $dx / $ln; $tyn = $dy / $ln
  $px = -$tyn; $py = $txn
  if (($py * -1.0) -lt 0) { $px = -$px; $py = -$py }

  if ($mode -eq 0) {
    for ($kk = 1; $kk -le 10; $kk++) {
      $s = ([double]$kk) / 10.0
      $stretch = ([math]::Pow($s, 1.05)) * 44.0
      $lift = -([math]::Sin($s * [math]::PI * 1.02)) * 27.5
      $nx = [double]$lx[$last] + ($txn * $stretch * (0.28 + $s * 0.62)) + ($px * $stretch * ($s + 0.18))
      $ny = [double]$ly[$last] + ($tyn * $stretch * (0.28 + $s * 0.62)) + $lift
      [void]$lx.Add($nx); [void]$ly.Add($ny)
    }
  }
  elseif ($mode -eq 1) {
    for ($kk = 1; $kk -le 10; $kk++) {
      $s = ([double]$kk) / 10.0
      $stretch = ([math]::Pow($s, 1.06)) * 53.8
      $dip = ([math]::Sin($s * [math]::PI * 0.9)) * 32.9
      $nx = [double]$lx[$last] + ($txn * $stretch * 0.44) + ($px * $stretch * 0.76)
      $ny = [double]$ly[$last] + ($tyn * $stretch * 0.44) + $dip + ($py * ($stretch * 0.079))
      [void]$lx.Add($nx); [void]$ly.Add($ny)
    }
  }
  elseif ($mode -eq 2) {
    $cx = [double]$lx[$last] + 10.9 + (($Salt[7] % 9) / 7.0)
    $cy = [double]$ly[$last] - 7.2 - (($Salt[9] % 9) / 12.5)
    $rd = [double](6.2 + (($Salt[3] % 6) / 6.0))
    $stp = [math]::Min(22, ([math]::Max(10, 9 + ($Salt[5] % 6))))
    for ($a = 0; $a -lt $stp; $a++) {
      $theta = ($a / [double]$stp) * ([math]::PI * 2.0)
      [void]$lx.Add(([double]$cx + [math]::Cos($theta) * $rd * 1.02))
      [void]$ly.Add(([double]$cy + [math]::Sin($theta) * $rd))
    }
  }

  return @{ Xs = [double[]]$lx.ToArray(); Ys = [double[]]$ly.ToArray() }
}

function Get-NibContrastFromEnergy {
  param([string] $Energy)
  switch ($Energy) {
    'Calm' { return 0.38 }
    'Balanced' { return 0.52 }
    'Wild' { return 0.68 }
    default { return 0.52 }
  }
}

function Get-ColumnBlackRuns {
  param(
    [System.Drawing.Bitmap] $Bmp,
    [int] $X,
    [double] $Threshold
  )
  $h = $Bmp.Height
  $runs = [System.Collections.Generic.List[object]]::new()
  $y = 0
  while ($y -lt $h) {
    while ($y -lt $h -and -not (Test-DarkPixel -Bmp $Bmp -X $X -Y $Y -Threshold $Threshold)) { $y++ }
    if ($y -ge $h) { break }
    $y0 = $y
    while ($y -lt $h -and (Test-DarkPixel -Bmp $Bmp -X $X -Y $Y -Threshold $Threshold)) { $y++ }
    $y1 = $y - 1
    [void]$runs.Add(@{ Lo = $y0; Hi = $y1 })
  }
  return $runs
}

function Test-DarkPixel {
  param(
    [System.Drawing.Bitmap] $Bmp,
    [int] $X,
    [int] $Y,
    [double] $Threshold
  )
  if ($X -lt 0 -or $Y -lt 0 -or $X -ge $Bmp.Width -or $Y -ge $Bmp.Height) { return $false }
  $c = $Bmp.GetPixel($X, $Y)
  $b = [double]$c.GetBrightness()
  return ($b -lt $Threshold)
}


function Build-CenterPolylineFromBitmap {
  param(
    [System.Drawing.Bitmap] $Bmp,
    [double] $Threshold = 0.82,
    [int] $LetterUnits = 12
  )
  $w = $Bmp.Width
  $centers = New-Object double[] $w
  $flags = New-Object bool[] $w
  for ($x = 0; $x -lt $w; $x++) {
    $runs = Get-ColumnBlackRuns -Bmp $Bmp -X $x -Threshold $Threshold
    if ($runs.Count -eq 0) { continue }
    $acc = 0.0
    foreach ($r in $runs) { $acc += ($r.Lo + $r.Hi) / 2.0 }
    $yc = $acc / $runs.Count
    $centers[$x] = $yc
    $flags[$x] = $true
  }
  $first = -1
  for ($x = 0; $x -lt $w; $x++) {
    if ($flags[$x]) { $first = $x; break }
  }
  if ($first -lt 0) { return @{ Xs = [double[]]@(); Ys = [double[]]@() } }
  $last = -1
  for ($x = $w - 1; $x -ge 0; $x--) {
    if ($flags[$x]) { $last = $x; break }
  }
  for ($x = 0; $x -lt $first; $x++) {
    $centers[$x] = $centers[$first]; $flags[$x] = $true
  }
  for ($x = $last + 1; $x -lt $w; $x++) {
    $centers[$x] = $centers[$last]; $flags[$x] = $true
  }
  $xscan = 0
  while ($xscan -lt $w) {
    if ($flags[$xscan]) { $xscan++; continue }
    $x0 = $xscan - 1
    $x1 = $xscan
    while ($x1 -lt $w -and -not $flags[$x1]) { $x1++ }
    if ($x0 -ge 0 -and $x1 -lt $w) {
      for ($z = $x0 + 1; $z -lt $x1; $z++) {
        $t = ($z - $x0) / [double]($x1 - $x0)
        $centers[$z] = (1.0 - $t) * $centers[$x0] + $t * $centers[$x1]
        $flags[$z] = $true
      }
    }
    $xscan = [math]::Max($xscan + 1, $x1)
  }

  $xsList = [System.Collections.Generic.List[double]]::new()
  $ysList = [System.Collections.Generic.List[double]]::new()
  # Au moins ~14 colonnes analysées par caractère (nom sans espaces) pour une meilleure définition du centre médian.
  $minVerts = [math]::Max([int]128, ([math]::Max(8, $LetterUnits) * 14))
  $step = [math]::Max(1, [int][math]::Ceiling(([double]$w) / ([double]$minVerts)))
  for ($x = 0; $x -lt $w; $x += $step) {
    [void]$xsList.Add([double]$x)
    [void]$ysList.Add([double]$centers[$x])
  }
  return @{ Xs = $xsList.ToArray(); Ys = $ysList.ToArray() }
}

function Smooth-PolyMa {
  param([double[]] $Xs, [double[]] $Ys, [int] $Passes = 2)
  $n = $Xs.Length
  if ($n -le 2) {
    return @{ Xs = $Xs; Ys = $Ys }
  }
  $xw = New-Object double[] $n
  $yw = New-Object double[] $n
  [array]::Copy($Xs, $xw, $n); [array]::Copy($Ys, $yw, $n)
  for ($p = 0; $p -lt $Passes; $p++) {
    $ox = New-Object double[] $n
    $oy = New-Object double[] $n
    for ($i = 0; $i -lt $n; $i++) {
      if ($i -eq 0 -or $i -eq $n - 1) { $ox[$i] = $xw[$i]; $oy[$i] = $yw[$i]; continue }
      $ox[$i] = ($xw[$i - 1] + 2 * $xw[$i] + $xw[$i + 1]) / 4.0
      $oy[$i] = ($yw[$i - 1] + 2 * $yw[$i] + $yw[$i + 1]) / 4.0
    }
    [array]::Copy($ox, $xw, $n); [array]::Copy($oy, $yw, $n)
  }
  return @{ Xs = $xw; Ys = $yw }
}

function Apply-PolyBmpTremor {
  param([double[]] $Xs, [double[]] $Ys, [byte[]] $Salt, [double] $Amp = 0.55)
  $n = $Xs.Length
  $ox = New-Object double[] $n
  $oy = New-Object double[] $n
  for ($i = 0; $i -lt $n; $i++) {
    $sj = [int]$Salt[$i % $Salt.Length]
    $sk = [int]$Salt[($i + 7) % $Salt.Length]
    $ox[$i] = $Xs[$i] + ($sj - 127) / 280.0 * $Amp
    $oy[$i] = $Ys[$i] + ($sk - 127) / 280.0 * $Amp
  }
  return @{ Xs = $ox; Ys = $oy }
}

function Extend-PolyBmpFlourish {
  param([double[]] $Xs, [double[]] $Ys,
    [ValidateSet('None', 'Short', 'Long')] [string]$FlName,
    [hashtable]$FlScaleCfg
  )
  if ($Xs.Length -lt 4 -or $FlName -eq 'None') {
    return @{ Xs = $Xs; Ys = $Ys }
  }
  $lx = New-Object System.Collections.Generic.List[double]; foreach ($v in $Xs) { [void]$lx.Add($v) }
  $ly = New-Object System.Collections.Generic.List[double]; foreach ($v in $Ys) { [void]$ly.Add($v) }
  $nx = $lx.Count - 1
  $vx = $lx[$nx] - $lx[$nx - 1]; $vy = $ly[$nx] - $ly[$nx - 1]; $slen = [math]::Sqrt($vx * $vx + $vy * $vy)
  if ($slen -lt 1e-9) { return @{ Xs = $lx.ToArray(); Ys = $ly.ToArray() } }
  $vx /= $slen; $vy /= $slen
  $sx = (-$vy); $sy = $vx
  $base = if ($FlName -eq 'Long') { 42.0 * $FlScaleCfg.Scale } else { 24.0 * $FlScaleCfg.Scale }
  $steps = 12
  for ($k = 1; $k -le $steps; $k++) {
    $t = ($k / $steps); $f = [math]::Pow($t, 1.14)
    $len = $base * $f
    $bend = ([math]::Sin($t * [math]::PI)) * 5.8 * ([math]::Pow((1.0 - $t), 1.3))
    $xu = $lx[$nx] + $vx * $len + $sx * $bend
    $yu = $ly[$nx] + $vy * $len + $sy * ($bend * 0.76)
    [void]$lx.Add([double]$xu); [void]$ly.Add([double]$yu)
  }
  return @{ Xs = $lx.ToArray(); Ys = $ly.ToArray() }
}

function New-SignatureRasterAndFont {
  param([string] $Plain, [float] $FontEm, [string[]] $Fam)
  Ensure-DrawingAssembly | Out-Null
  $font = $null
  # Italique en priorité (mouvement) ; repli si la famille ne l’expose pas sous GDI+.
  $styTry = @(
    [System.Drawing.FontStyle]::Italic,
    [System.Drawing.FontStyle]::BoldItalic,
    [System.Drawing.FontStyle]::Regular,
    [System.Drawing.FontStyle]::Bold
  )
  foreach ($fam in $Fam) {
    foreach ($st in $styTry) {
      try {
        $font = New-Object System.Drawing.Font (
          [string]$fam, ([float]$FontEm),
          ($st),
          ([System.Drawing.GraphicsUnit]::Pixel))
        break
      }
      catch {}
    }
    if ($null -ne $font) { break }
  }
  if ($null -eq $font) {
    try {
      $font = New-Object System.Drawing.Font (
        [string]'Times New Roman', ([float]$FontEm),
        ([System.Drawing.FontStyle]::Italic),
        ([System.Drawing.GraphicsUnit]::Pixel))
    }
    catch {
      $font = New-Object System.Drawing.Font (
        [string]'Times New Roman', ([float]$FontEm),
        ([System.Drawing.FontStyle]::Regular),
        ([System.Drawing.GraphicsUnit]::Pixel))
    }
  }

  try {
    $probe = New-Object System.Drawing.Bitmap 4, 4
    $gp = [System.Drawing.Graphics]::FromImage($probe)
    try {
      $sz = $gp.MeasureString($Plain, $font)
      $bw = [math]::Ceiling([double]$sz.Width) + 80
      $bh = [math]::Ceiling([double]$sz.Height) + 80
    }
    finally { $gp.Dispose(); $probe.Dispose() }

    $bmp = New-Object System.Drawing.Bitmap ([int][math]::Max(32,$bw)), ([int][math]::Max(28,$bh))
    $gr = [System.Drawing.Graphics]::FromImage($bmp)
    try {
      $gr.Clear([System.Drawing.Color]::White)
      $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Black)
      try {
        $gr.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $origin = New-Object System.Drawing.PointF ([float]40.0), ([float]42.0)
        $sf = New-Object System.Drawing.StringFormat ([System.Drawing.StringFormat]::GenericTypographic)
        $sf.FormatFlags = 'NoWrap'
        $gr.DrawString($Plain, $font, $br, $origin, $sf)
      }
      finally { $br.Dispose() }
    }
    finally {
      $gr.Dispose()
    }
    return @{ Bitmap = $bmp; Font = $font }
  }
  catch {
    if ($null -ne $font) { $font.Dispose() }
    throw $_
  }
}

function Map-BmpPolylineToSvgUnits {
  param([double[]] $Bx, [double[]] $By, [string]$DensityVal)
  $minx = ($Bx | Measure-Object -Minimum).Minimum
  $maxx = ($Bx | Measure-Object -Maximum).Maximum
  $miny = ($By | Measure-Object -Minimum).Minimum
  $maxy = ($By | Measure-Object -Maximum).Maximum
  $rw = [math]::Max(1e-6, ($maxx - $minx)); $rh = [math]::Max(1e-6, ($maxy - $miny))
  $denseMul = switch ($DensityVal) {
    'Airy' { 1.03 }
    'Tight' { 0.94 }
    Default { 1.0 }
  }
  $availX = ((194.0 - 12.0) * $denseMul)
  $availY = (44.0 - 6.0)
  $scale = [math]::Min($availX / $rw, $availY / $rh)
  $ox = 10.0 + ((200.0 - 22.0) - $rw * $scale) / 2.0
  $oy = 6.0 + ((44.0 - 4.0) - $rh * $scale) / 2.0
  $n = $Bx.Length
  $sx = New-Object double[] $n
  $sy = New-Object double[] $n
  for ($i = 0; $i -lt $n; $i++) {
    $sx[$i] = $ox + ($Bx[$i] - $minx) * $scale
    $sy[$i] = $oy + ($By[$i] - $miny) * $scale
  }
  return @{
    Sx = $sx; Sy = $sy
    MinBmpX = [double]$minx; MinBmpY = [double]$miny
    MapScale = [double]$scale; MapOx = [double]$ox; MapOy = [double]$oy
  }
}

function Compute-NibRibbonHalfWidthsSvg {
  param([double[]] $Sx, [double[]] $Sy,
    [double] $HalfBaseSvg, [string] $Energy, [byte[]] $Salt)
  $cn = Get-NibContrastFromEnergy -Energy $Energy
  $n = $Sx.Length
  $half = New-Object double[] $n
  for ($i = 1; $i -lt $n; $i++) {
    $dx = $Sx[$i] - $Sx[$i - 1]; $dy = $Sy[$i] - $Sy[$i - 1]
    $hyp = [math]::Sqrt([math]::Max(1e-12, $dx * $dx + $dy * $dy))
    $dv = $dy / $hyp
    $jtr = (($Salt[$i % $Salt.Length] - 128) / 128.0) * 0.05
    $mix = ([math]::Max(0.22, [math]::Min(1.65, 0.55 + $dv * $cn * 0.95))) + $jtr
    $mix = ([math]::Max(0.2, [math]::Min(1.75, $mix)))
    $half[$i] = $HalfBaseSvg * $mix
  }
  if ($n -ge 2) {
    $half[0] = $half[1]
    $half[$n - 1] = $half[$n - 2]
  }
  for ($i = 1; $i -lt $n - 1; $i++) {
    $half[$i] = ($half[$i - 1] + $half[$i] + $half[$i + 1]) / 3.0
  }
  for ($ii = 2; $ii -lt ($n - 2); $ii++) {
    $dxv = [double]$Sx[$ii] - [double]$Sx[$ii - 1]; $dyv = [double]$Sy[$ii] - [double]$Sy[$ii - 1]
    $hpv = [math]::Sqrt([math]::Max(1e-12, $dxv * $dxv + $dyv * $dyv))
    if ($hpv -gt 1e-6) {
      $ratioV = [math]::Abs($dyv) / $hpv
      if ($ratioV -gt 0.6) {
        $fac = 1.0 + ([math]::Min(0.36, (($ratioV - 0.6) / 0.45)))
        $half[$ii] = [math]::Min([double]$HalfBaseSvg * [double]2.5, [double]$half[$ii] * $fac)
      }
    }
  }
  return ([double[]]$half)
}

function Get-LeftUnitPerpendicular {
  param([double]$Dx, [double]$Dy)
  $hyp = [math]::Sqrt([math]::Max(1e-14, $Dx * $Dx + $Dy * $Dy))
  @(- ($Dy / $hyp), ($Dx / $hyp))
}

function Build-ClosedRibbonPathDFromCenterline {
  param([double[]] $Sx, [double[]] $Sy, [double[]] $HalfW)
  $inv = [Globalization.CultureInfo]::InvariantCulture
  $sb = [System.Text.StringBuilder]::new()
  $n = $Sx.Length
  if ($n -lt 2 -or $HalfW.Length -ne $n) { return 'M0 0' }
  $px = New-Object double[] $n
  $py = New-Object double[] $n
  $qx = New-Object double[] $n
  $qy = New-Object double[] $n

  for ($i = 0; $i -lt $n; $i++) {
    if ($i -eq 0 -and ($n -ge 2)) {
      $dx = $Sx[$i + 1] - $Sx[$i]; $dy = $Sy[$i + 1] - $Sy[$i]
      $o = Get-LeftUnitPerpendicular -Dx $dx -Dy $dy
    }
    elseif ($i -eq ($n - 1) -and ($n -ge 2)) {
      $dx = $Sx[$i] - $Sx[$i - 1]; $dy = $Sy[$i] - $Sy[$i - 1]
      $o = Get-LeftUnitPerpendicular -Dx $dx -Dy $dy
    }
    else {
      $dx1 = $Sx[$i] - $Sx[$i - 1]; $dy1 = $Sy[$i] - $Sy[$i - 1]
      $dx2 = $Sx[$i + 1] - $Sx[$i]; $dy2 = $Sy[$i + 1] - $Sy[$i]
      $o1 = Get-LeftUnitPerpendicular -Dx $dx1 -Dy $dy1
      $o2 = Get-LeftUnitPerpendicular -Dx $dx2 -Dy $dy2
      $mux = ([double]$o1[0] + [double]$o2[0]); $muy = ([double]$o1[1] + [double]$o2[1])
      $ml = [math]::Sqrt([math]::Max(1e-14, $mux * $mux + $muy * $muy))
      $mux /= $ml; $muy /= $ml
      $o = @($mux, $muy)
    }
    $px[$i] = $Sx[$i] + ($o[0] * $HalfW[$i])
    $py[$i] = $Sy[$i] + ($o[1] * $HalfW[$i])
    $qx[$i] = $Sx[$i] - ($o[0] * $HalfW[$i])
    $qy[$i] = $Sy[$i] - ($o[1] * $HalfW[$i])
  }

  [void]$sb.AppendFormat($inv, 'M{0:0.##},{1:0.##}', $px[0], $py[0])
  for ($i = 1; $i -lt $n; $i++) { [void]$sb.AppendFormat($inv, 'L{0:0.##},{1:0.##}', $px[$i], $py[$i]) }
  for ($i = $n - 1; $i -ge 0; $i--) {
    [void]$sb.AppendFormat($inv, 'L{0:0.##},{1:0.##}', $qx[$i], $qy[$i])
  }
  [void]$sb.Append('Z')
  return $sb.ToString()
}

function Remove-SvgViewerWhiteBackgroundRect {
  param([string] $SvgText)
  # Fond prévisualisation uniquement ; retiré pour export PNG fond transparent.
  $t = [regex]::Replace($SvgText, '(?ms)^\s*<rect\b[^>]+\bid\s*=\s*"sig-view-bg"[^>]*/>\s*\r?\n?', '')
  $t = [regex]::Replace($t, '(?ms)<rect\b[^>]*?\bid\s*=\s*"sig-view-bg"\b[^>]*>\s*</rect>', '')
  return $t
}

function Get-PenNibSegmentEnumerator {
  param([string]$NameFormatted)
  $segments = New-Object System.Collections.Generic.List[hashtable]
  $wr = @(($NameFormatted.Trim()) -split '\s+' | Where-Object { $_ -ne '' })
  for ($wi = 0; $wi -lt $wr.Count; $wi++) {
    $wrd = [string]$wr[$wi]
    $chunkStart = $true
    for ($ix = 0; $ix -lt $wrd.Length; $ix++) {
      $ch = [char]$wrd[$ix]
      if ($ch -eq [char]'-') {
        [void]$segments.Add(@{ Kind = 'Hyphen'; })
        $chunkStart = $true
        continue
      }
      if ($chunkStart) {
        [double]$sc = [double]1.3
      }
      else {
        [double]$sc = [double]1.0
      }
      [void]$segments.Add(@{ Kind = 'Letter'; CharStr = ([string]$ch); LetterScale = $sc })
      $chunkStart = $false
    }
    if ($wi -lt ($wr.Count - 1)) {
      [void]$segments.Add(@{ Kind = 'Space'; })
    }
  }
  return $segments.ToArray()
}

function Get-SignatureJambeDeltaYBmp {
  param(
    [string] $ChOne,
    [int] $IndexInGlyphStream,
    [byte[]] $Entropy
  )
  if ($null -eq $ChOne -or $ChOne.Length -ne 1) { return [double]0.0 }
  [char]$c = $ChOne.ToCharArray()[0]
  if (-not ([char]::IsLetter($c))) { return [double]0.0 }
  [string]$cl = ([string]$c).ToLowerInvariant()
  $dj = @( 'g'; 'j'; 'p'; 'q'; 'y' )
  $aj = @( 'f'; 'h'; 't'; 'b'; 'd'; 'k'; 'l' )
  [bool]$isDesc = ($dj -contains $cl)
  [bool]$isAsc = ($aj -contains $cl)
  if ((-not $isDesc) -and (-not $isAsc)) { return [double]0.0 }

  [int]$b0 = [int]$Entropy[($IndexInGlyphStream * 3 + 5) % 32]
  [int]$b1 = [int]$Entropy[($IndexInGlyphStream * 7 + ([int]$c % 97)) % 32]
  [double]$mag = 1.95 + (($b1 % 13) / 13.0) * 3.85
  if ($isDesc -and (-not $isAsc)) {
    [double]$s = if (($b0 % 2) -eq 0) { [double]1.0 } else { [double]-1.0 }
    if (-not (($b1 % 2) -eq 0)) { $s *= -1.0 }
    return ([double]$s * [double]$mag)
  }
  elseif ($isAsc -and (-not $isDesc)) {
    [double]$s = (($b1 % 3) - 1)
    return ([double]$s / 3.45) * [double]$mag - 1.5
  }
  else {
    # f, t peuvent avoir les deux usages selon graisse ; mélanger légèrement
    [double]$s = (($b0 % 5) / 25.0) * [double]$mag + ($b1 % 3) / 6.75
    return (-1.05 * [double]$s + 2.85)
  }
}

function New-SignatureInkBridgeBmpPath {
  param(
    [System.Drawing.RectangleF] $PrevBounds,
    [System.Drawing.RectangleF] $CurBounds,
    [double] $BendFrac
  )
  # Coordonnées bitmap : Y croissant vers le bas ; le « bas » du glyphe est PrevBounds.Bottom (Grand Y).
  $gap = [double]$CurBounds.Left - [double]$PrevBounds.Right
  if (($gap -gt 52.5) -or ($gap -lt -25.5)) {
    return $null
  }

  [double]$x1 = [double]$PrevBounds.Right - 4.98
  [double]$x2 = [double]$CurBounds.Left + 5.9
  if (($x2 - $x1) -lt [double]5.76) {
    [double]$midx = ([double]$PrevBounds.Right + [double]$CurBounds.Left) / 2.0
    $x1 = $midx - [double]4.94
    $x2 = $midx + [double]4.94
  }

  [double]$dyB = ([double]$BendFrac * 6.4)
  [double]$thickBase = [math]::Max(1.12, (($PrevBounds.Height + $CurBounds.Height) * 0.044))
  # Épaisseur au départ (appui sur le pied de la lettre précédente), puis amincissement vers la droite (relèvement de plume).
  [double]$tStart = ([math]::Max(1.35, [math]::Min(10.6, ($thickBase + 2.12))))
  [double]$taperEntropy = 0.085 + ([math]::Abs($BendFrac) * 0.14) + ((0.5 + $BendFrac) * 0.095)
  [double]$tEnd = [math]::Max(0.38, [math]::Min($tStart * 0.44, ($tStart * $taperEntropy)))

  # Bord gauche : centre vertical tel que le bas du trapèze épouse le bas du gabarit précédent (trait qui « part » du pied).
  [double]$ycLeft = ([double]$PrevBounds.Bottom - ($tStart * 0.5)) + ($dyB * 0.55)
  # Bord droit : légère montée vers la lettre suivante + mélange avec le bas du glyphe courant (entropie BendFrac).
  [double]$ycCurFoot = ([double]$CurBounds.Bottom - ($tEnd * 0.42))
  [double]$wBlend = [math]::Max(0.28, [math]::Min(0.62, (0.46 + ($BendFrac * 0.18))))
  [double]$ycRight = ((1.0 - $wBlend) * $ycLeft + $wBlend * $ycCurFoot) - ([math]::Abs($gap) * 0.028) - ($dyB * 0.42)

  [float]$x1f = [float]$x1
  [float]$x2f = [float]$x2

  $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $pts = New-Object System.Drawing.PointF[] 4
  $pts[0] = [System.Drawing.PointF]::new($x1f, ([float]($ycLeft - ($tStart * 0.5))))
  $pts[1] = [System.Drawing.PointF]::new($x2f, ([float]($ycRight - ($tEnd * 0.5))))
  $pts[2] = [System.Drawing.PointF]::new($x2f, ([float]($ycRight + ($tEnd * 0.5))))
  $pts[3] = [System.Drawing.PointF]::new($x1f, ([float]($ycLeft + ($tStart * 0.5))))

  try {
    [void]$gp.AddPolygon($pts)
    return [System.Drawing.Drawing2D.GraphicsPath]$gp
  }
  catch {
    try { $gp.Dispose() } catch {}
    return $null
  }
}

function Convert-GlyphGraphicsPathToSvgFillPathD {
  param(
    [System.Drawing.Drawing2D.GraphicsPath] $GlyphPath,
    [string] $DensityVal,
    [ValidateSet('None', 'Short', 'Long')] [string]$FlourishName,
    [hashtable] $FlScaleCfg
  )
  $inv = [Globalization.CultureInfo]::InvariantCulture

  [void]$GlyphPath.Flatten([System.Drawing.Drawing2D.Matrix]::new())
  $ptc = [int]$GlyphPath.PointCount
  if ($ptc -lt 3) {
    return 'M0 0 Z'
  }

  $bb = $GlyphPath.GetBounds()
  $rw = [math]::Max([double]1e-6, [double]$bb.Width)
  $rh = [math]::Max([double]1e-6, [double]$bb.Height)
  $denseMul = switch ($DensityVal) {
    'Airy' { 1.03 }
    'Tight' { 0.94 }
    Default { 1.0 }
  }
  $availX = ((194.0 - 12.0) * $denseMul)
  $availY = (44.0 - 6.0)
  $scal = [math]::Min(($availX / $rw), ($availY / $rh))
  $oxBmp = ($bb.Left)
  $oyBmp = ($bb.Top)
  $oxSvg = [double](10.0 + ((200.0 - 22.0) - ([double]$rw * $scal)) / 2.0)
  $oySvg = [double](6.0 + ((44.0 - 4.0) - ([double]$rh * $scal)) / 2.0)

  $mapX = {
    param([double] $BmpX)
    [double]$oxSvg + (([double]$BmpX - $oxBmp) * [double]$scal)
  }

  $mapY = {
    param([double] $BmpY)
    [double]$oySvg + (([double]$BmpY - $oyBmp) * [double]$scal)
  }

  function LocalAppendFlourishBmpToSvgSb {
    param([float]$X0,[float]$Y0,[float]$X1,[float]$Y1)
    # $X1/Y1 : dernier point du contour (= position de réf.) ; tangent depuis $X0/Y0 (comme Extend-PolyBmpFlourish)
    $vx = [double]$X1 - [double]$X0; $vy = [double]$Y1 - [double]$Y0
    $slen = [math]::Sqrt([math]::Max(1e-12, ($vx * $vx + $vy * $vy)))
    if ($slen -lt 1e-6) { return }
    $vx /= $slen; $vy /= $slen
    $sx = (-$vy); $sy = $vx
    [double]$base = 0.0
    if ($FlourishName -eq 'Long') {
      $base = [double]$FlScaleCfg.Scale * [double]42.0
    }
    else {
      $base = [double]$FlScaleCfg.Scale * [double]24.0
    }
    # Après le dernier Z du bloc texte, le point courant SVG n'est pas la fin du mot : repartir avec M sur ce point.
    [void]$Script:sbGlyphs.Append(' ')
    [void]$Script:sbGlyphs.AppendFormat($inv, 'M{0:0.##},{1:0.##}', (&$Script:mapX ([double]$X1)), (&$Script:mapY ([double]$Y1)))
    $steps = 12
    for ($gk = 1; $gk -le $steps; $gk++) {
      $tj = ([double]$gk / [double]$steps); $tjf = ([math]::Pow($tj, 1.14))
      [double]$nlen = ([double]$base * $tjf)
      [double]$bend = ([math]::Sin($tj * [math]::PI)) * [double](4.85) * ([math]::Pow(([double](1.0 - $tj)), [double](1.3)))
      [float]$xu = [double]$X1 + ($vx * $nlen) + ($sx * $bend)
      [float]$yu = [double]$Y1 + ($vy * $nlen) + ($sy * ($bend * [double]0.76))
      [void]$Script:sbGlyphs.AppendFormat($inv, ('L{0:0.##},{1:0.##}'), (&$Script:mapX ([double]$xu)), (&$Script:mapY ([double]$yu)))
    }
  }

  $sbGlyphs = [System.Text.StringBuilder]::new()
  $Script:sbGlyphs = $sbGlyphs
  $Script:mapX = $mapX
  $Script:mapY = $mapY

  for ($jj = 0; $jj -lt $ptc; $jj++) {
    [float]$pfx = [float]$GlyphPath.PathPoints[$jj].X
    [float]$pfy = [float]$GlyphPath.PathPoints[$jj].Y
    $rawTb = [byte]$GlyphPath.PathTypes[$jj]
    [int]$vk = ([int]$rawTb -band 7)

    # Start = 0, Line/Bézier aplati = typ. 1, fermeture 0x80
    if ($vk -eq 0) {
      $sxVa = &$mapX ([double]$pfx)
      $syVa = &$mapY ([double]$pfy)
      if ($sbGlyphs.Length -lt 3) {
        [void]$sbGlyphs.AppendFormat($inv, ('M{0:0.##},{1:0.##}'), [double]$sxVa, [double]$syVa)
      }
      else {
        [void]$sbGlyphs.Append(' ')
        [void]$sbGlyphs.AppendFormat($inv, ('M{0:0.##},{1:0.##}'), [double]$sxVa, [double]$syVa)
      }
    }
    else {
      $sxVa = &$mapX ([double]$pfx); $syVa = &$mapY ([double]$pfy)
      [void]$sbGlyphs.AppendFormat($inv, ('L{0:0.##},{1:0.##}'), [double]$sxVa, [double]$syVa)
      if (($rawTb -band 128) -ne 0) {
        [void]$sbGlyphs.Append('Z ')
      }
    }
  }

  if ($FlourishName -ne 'None' -and $ptc -ge 7) {
    $xA = [float]$GlyphPath.PathPoints[$ptc - 2].X
    $yA = [float]$GlyphPath.PathPoints[$ptc - 2].Y
    $xB = [float]$GlyphPath.PathPoints[$ptc - 1].X
    $yB = [float]$GlyphPath.PathPoints[$ptc - 1].Y
    LocalAppendFlourishBmpToSvgSb -X0 $xA -Y0 $yA -X1 $xB -Y1 $yB
  }

  $out = ([string]$sbGlyphs.ToString()).Trim()
  if ([string]::IsNullOrWhiteSpace($out)) { return 'M0 0 Z' }
  return $out
}

function Invoke-PenNibFillPathAndDispose {
  param(
    [string] $GeometrySeed,
    [hashtable]$StyleNum,
    [string] $EnergyLabel,
    [string] $FlourishName,
    [string] $DensityVal,
    [string[]]$FontFam,
    [double] $EffectiveHalfBaseSvg
  )

  $namePlain = Format-SignatureTitleCase (Get-SignatureNamePart -SeedText $GeometrySeed)

  try {
    $rast = New-SignatureRasterAndFont -Plain $namePlain -FontEm ([float]58.0) -Fam $FontFam
  }
  catch {
    throw
  }

  [byte[]]$entropy32 = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes([string]$namePlain + '|pen|jambe|lnk'))

  $bmpObj = $rast.Bitmap
  $fon = $rast.Font
  $measGfx = $null
  $gp = $null
  try {
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath

    [float]$cursorX = [float]40.0
    [float]$yBaselinePx = [float]42.0
    [single]$baseEmPx = [single]$fon.Size
    [System.Drawing.RectangleF]$prevRb = [System.Drawing.RectangleF]::Empty
    [bool]$prevEligibleBridge = $false

    $measGfx = [System.Drawing.Graphics]::FromImage($bmpObj)
    $measGfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    [System.Drawing.StringFormat]$sfMeas = [System.Drawing.StringFormat]::GenericTypographic.Clone()
    $sfMeas.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap

    $segList = Get-PenNibSegmentEnumerator -NameFormatted ([string]$namePlain)
    [int]$glyStreamIdx = 0
    [int]$jambeIx = 0

    foreach ($segOne in [object[]]$segList) {
      $sk = [string]$segOne.Kind

      if ($sk -eq 'Space') {
        $fsp = New-Object System.Drawing.Font (
          ([System.Drawing.FontFamily]$fon.FontFamily), ([float]$baseEmPx),
          ([int]$fon.Style), ([System.Drawing.GraphicsUnit]::Pixel))
        try {
          [System.Drawing.SizeF]$sw = [System.Drawing.SizeF]::empty
          $sw = $measGfx.MeasureString(([string]' '), $fsp)
          [int]$ixSp = ((([int]$glyStreamIdx) * 11) % 32)
          [double]$spVar = (([double][int]$entropy32[$ixSp]) % [double](5.0)) / [double](140.0)
          [double]$spAdd = ([double]$sw.Width) * ([double]1.11 + [double]$spVar)
          $cursorX = [float]([double]$cursorX + [double]$spAdd)
        }
        finally {
          try { $fsp.Dispose() } catch {}
          $fsp = $null
        }
        $prevEligibleBridge = $false
        $prevRb = [System.Drawing.RectangleF]::Empty
        [int]$glyStreamIdx++
        continue
      }

      [string]$chStr = ''
      [double]$ltrSc = [double]1.0
      if ($sk -eq 'Hyphen') {
        [string]$chStr = [string]'-'
        [double]$ltrSc = [double]1.0
      }
      else {
        [string]$chStr = ([string]$segOne.CharStr)
        [double]$ltrSc = [double]$segOne.LetterScale
      }
      [float]$scaledEm = [single](([double]$baseEmPx * [double]$ltrSc))
      [System.Drawing.Font]$fDraw = $null
      try {
        $fDraw = New-Object System.Drawing.Font (
          ([System.Drawing.FontFamily]$fon.FontFamily), ([float]$scaledEm),
          ([int]$fon.Style), ([System.Drawing.GraphicsUnit]::Pixel))
      }
      catch {
        throw $_
      }

      [double]$dyJb = [double]0
      [string]$sOne = ([string]$chStr)
      if ((-not ([string]::IsNullOrEmpty($sOne))) -and ($sOne -ne '-') -and ($sOne.Length -eq 1)) {
        $dyJb = Get-SignatureJambeDeltaYBmp -ChOne ([string]$sOne) `
          -IndexInGlyphStream ([int]$jambeIx) -Entropy ([byte[]]$entropy32)
      }

      [bool]$priorInkLink = [bool]$prevEligibleBridge
      [System.Drawing.Drawing2D.GraphicsPath]$gpChr = $null
      try {
        $gpChr = New-Object System.Drawing.Drawing2D.GraphicsPath
        [single]$yf = [single](([double]$yBaselinePx + [double]$dyJb))
        [System.Drawing.PointF]$pfOr = New-Object System.Drawing.PointF (($cursorX), ($yf))

        try {
          $gpChr.AddString([string]$chStr, [System.Drawing.FontFamily]$fon.FontFamily,
            ([int]$fon.Style), ([single][math]::Round([single]$scaledEm, [int]5)), ([System.Drawing.PointF]$pfOr), ([System.Drawing.StringFormat]$sfMeas))
        }
        catch {
          throw $_
        }

        # Déviation d’angle par glyphe (déterministe, même graine → même trace) ; plage [-5°, +5°].
        [int]$ixAngA = (([int]$glyStreamIdx * 13 + 1) % 32)
        [int]$ixAngB = (([int]$glyStreamIdx * 29 + 5) % 32)
        [int]$angCombine = (([int]$entropy32[$ixAngA] -shl 8) -bor ([int]$entropy32[$ixAngB] -band 255))
        [double]$angleDeg = ([double]($angCombine % 10001) / 10000.0) * 10.0 - 5.0
        $mxRot = New-Object System.Drawing.Drawing2D.Matrix
        try {
          [void]$mxRot.RotateAt([float]$angleDeg, $pfOr)
          [void]$gpChr.Transform($mxRot)
        }
        finally {
          try { $mxRot.Dispose() } catch {}
        }

        [void]$gpChr.Flatten([System.Drawing.Drawing2D.Matrix]::new())
        [System.Drawing.RectangleF]$bChr = $gpChr.GetBounds()

        if ($prevEligibleBridge -and ($bChr.Width -gt 1e-3) -and ($prevRb.Width -gt 1e-3)) {
          [double]$bendFrac = (((( [int]$entropy32[ (($glyStreamIdx * 23) % 16) ]) / 254.95) ) - [double](0.5))
          [System.Drawing.Drawing2D.GraphicsPath]$gpBr =
            New-SignatureInkBridgeBmpPath -PrevBounds ([System.Drawing.RectangleF]$prevRb) `
            -CurBounds ([System.Drawing.RectangleF]$bChr) -BendFrac ([double]$bendFrac)
          if ($null -ne $gpBr) {
            try {
              [void]$gp.AddPath($gpBr, [bool]$false)
            }
            finally {
              try { $gpBr.Dispose() } catch {}
            }
          }
        }

        [void]$gp.AddPath($gpChr, [bool]$false)

        # Resserrement entre glyphes d’un même lien (sans toucher aux initiales élargies 1,30×).
        # +20 % de tirage supplémentaire par rapport à la version initiale (lettres plus rapprochées dans un même mot).
        [double]$intraWordTightenMul = [double]1.20
        [double]$pull = [double]0
        if ($priorInkLink -and (([double]$ltrSc + 0.0001) -lt [double]1.222)) {
          [int]$ixKu = (((( [int]$glyStreamIdx ) * 3) % 31))
          [double]$kIn = (([double][int]$entropy32[$ixKu]) % [double](5.0)) / [double](160.0)
          $pull = [math]::Min([double]$bChr.Width * ([double]0.128 + [double]$kIn), [double]20.98)
          if ([string]$sk -eq 'Hyphen') {
            [double]$p2 = ([math]::Min([double]([double]$bChr.Width * [double]0.104), [double]11.6))
            if ($pull -lt $p2) { $pull = $p2 }
          }
          $pull = [double]$pull * [double]$intraWordTightenMul
        }
        [double]$rightShifted = ([double]$bChr.Right - [double]$pull)
        $cursorX = [float]([math]::Max([double]$cursorX, [double]$rightShifted))

        $prevRb = $bChr
        $prevEligibleBridge = $true
      }
      finally {
        if ($gpChr -ne $null) { try { $gpChr.Dispose(); $gpChr = $null } catch {} }
        if ($fDraw -ne $null) {
          try {
            $fDraw.Dispose(); $fDraw = $null
          }
          catch {}
        }
      }

      [int]$glyStreamIdx++
      [int]$jambeIx++
    }

    try {
      [void]$sfMeas.Dispose()
    }
    catch {}

    try {
      if ($null -ne $measGfx) {
        try { $measGfx.Dispose(); $measGfx = $null } catch {}
      }
    }
    catch {}

    if (([int]$gp.PointCount -lt [int](32))) {
      throw ('Mode PenNib : contours de glyphes vides ou police indisponible pour « ' + $namePlain + ' ».')
    }

    [string]$pathDMain = (Convert-GlyphGraphicsPathToSvgFillPathD -GlyphPath ([System.Drawing.Drawing2D.GraphicsPath]$gp) -DensityVal $DensityVal `
        -FlourishName ([string]$FlourishName) -FlScaleCfg ([hashtable]$StyleNum.Flourish))

    [string]$pathDUnder = ([string]$pathDMain)

    return @{
      FillPathUnder = [string]$pathDUnder
      FillPathMain = [string]$pathDMain
    }
  }
  finally {
    if ($null -ne $gp) { try { $gp.Dispose() } catch {} ; $gp = $null }
    if ($measGfx -ne $null) { try { $measGfx.Dispose(); $measGfx = $null } catch {} }
    if ($fon) { try { $fon.Dispose() } catch {} ; $fon = $null }
    if ($bmpObj) {
      try {
        $bmpObj.Dispose(); $bmpObj = $null
      }
      catch {}
    }
  }
}

function Build-SignatureSvgRibbon {
  param(
    [string] $PathUnder,
    [string] $PathMain,
    [string] $InkUnder,
    [string] $InkMain,
    [double] $UnderOpacity,
    [double] $SlantDeg,
    [string] $FilterUniqueId
  )

  $c = [Globalization.CultureInfo]::InvariantCulture
  $uo = $UnderOpacity.ToString($c)

  $slant = if ([math]::Abs($SlantDeg) -gt 0.01) {
    ' transform="rotate(' + ($SlantDeg.ToString($c)) + ' 100 24)"'
  } else { '' }

  $svg = @"
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 48" width="200" height="48">
  <rect id="sig-view-bg" width="200" height="48" fill="#ffffff"/>
  <defs>
    <filter id="ink-soft-$FilterUniqueId" x="-14%" y="-14%" width="128%" height="128%" color-interpolation-filters="sRGB">
      <feGaussianBlur in="SourceGraphic" stdDeviation="0.12" result="b"/>
      <feMerge>
        <feMergeNode in="b"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <rect width="200" height="48" fill="none"/>
  <g id="signature-plume"$slant>
    <path d="$PathUnder" fill="$InkUnder" opacity="$uo" transform="translate(0.25 0.18)"/>
    <path d="$PathMain" fill="$InkMain" fill-rule="evenodd" filter="url(#ink-soft-$FilterUniqueId)"/>
  </g>
</svg>
"@
  return $svg
}
function Build-SignatureInkPathD {
  param(
    [string] $GeometrySeed,
    [hashtable] $StyleNum
  )

  $geomOnly = Format-SignatureTitleCase (Get-SignatureNamePart -SeedText $GeometrySeed)
  $bytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($geomOnly))
  $b = { param([int] $i) [int]$bytes[$i % 32] }

  $namePart = $geomOnly
  if ([string]::IsNullOrWhiteSpace($namePart)) { $namePart = 'Signature' }
  $nameChars = $namePart.ToCharArray()
  $charCount = [math]::Max(1, $nameChars.Length)

  # Trop peu de segments => un seul ruban presque droit. On scale avec le nom.
  $nBase = [int]$StyleNum.SegmentCount
  $nRoll = [int](& $b 31) % 5
  $nByName = [int][math]::Ceiling($charCount * 2.1) + 3
  $n = [math]::Min(34, [math]::Max($nBase + $nRoll, $nByName))

  $xb0 = [double]$StyleNum.Xb
  $xe0 = [double]$StyleNum.Xe
  $fullW = $xe0 - $xb0
  # Même +20 % de resserrement horizontal qu’en PenNib (tronçon utile = 80 % de la plage, centré).
  $usableW = $fullW * 0.80
  $xb = $xb0 + ($fullW - $usableW) / 2.0
  $xe = $xb + $usableW
  $yAmp = [double]$StyleNum.YAmplitude

  $inv = [Globalization.CultureInfo]::InvariantCulture
  $parts = [System.Text.StringBuilder]::new()

  $firstCode = [int][char]$nameChars[0]
  $prevX = $xb + ($firstCode % 17) / 7.5 + (& $b 0) / 48.0
  $prevY = 24.0 + (($firstCode % 23) - 11) * 0.45 + ([int](& $b 1) - 128) / (40.0 + $n * 0.55)
  [void]$parts.AppendFormat($inv, 'M{0:0.##},{1:0.##}', $prevX, $prevY)

  $prevCharIdx = -1

  for ($k = 1; $k -le $n; $k++) {
    $t = $k / $n
    $charIdx = [int][math]::Floor(($k - 1) * $charCount / [double]$n)
    if ($charIdx -ge $charCount) { $charIdx = $charCount - 1 }

    $ch = $nameChars[$charIdx]
    $ich = [int][char]$ch
    $crossLetter = ($charIdx -ne $prevCharIdx)
    if ($crossLetter) { $prevCharIdx = $charIdx }

    # Horizon : progression + micro-secousse (le hash ne porte plus toute la « forme »).
    $xBase = $xb + $t * $usableW
    $x = $xBase + (($ich % 11) - 5) / 7.0 + ([int](& $b ($k + 2)) - 128) / (38.0 + $n * 0.35)

    $glyphLift = (($ich % 41) - 20) * 0.1
    if ([char]::IsUpper($ch)) { $glyphLift -= 1.05 }
    $sinPhase = ($ich % 19) / 31.0 + $t * 5.8 + (& $b 5) / 52.0
    $y = 24.0 + [math]::Sin($sinPhase) * $yAmp * 0.9 + $glyphLift + ([int](& $b ($k + 10)) - 128) / (22.0 + $n * 0.28)

    if ($crossLetter -and (-not [char]::IsWhiteSpace($ch))) {
      $y += ((($ich % 5) - 2) * 1.2)
    }

    if ([char]::IsWhiteSpace($ch)) {
      $y += 2.4
      $x += (($ich % 5)) * 0.35
    }

    if ($ch -eq '-') {
      $y -= 1.9
    }

    $c1x = $prevX + ($x - $prevX) * 0.38 + ((($ich + $k * 3) % 41) - 20) / 13.5 + ([int](& $b ($k + 15)) - 128) / 27.0
    $c1y = $prevY + ((($ich -band 31) - 15) / 12.0) + ([int](& $b ($k + 16)) - 128) / 21.0
    $c2x = $prevX + ($x - $prevX) * 0.73 + ((($ich * 7 + $k) % 37) - 18) / 15.0 + ([int](& $b ($k + 17)) - 128) / 26.5
    $c2y = $y + ((($ich % 13) - 6) * 0.38) + ([int](& $b ($k + 18)) - 128) / 29.0
    [void]$parts.AppendFormat($inv, 'C{0:0.##},{1:0.##},{2:0.##},{3:0.##},{4:0.##},{5:0.##}',
      $c1x, $c1y, $c2x, $c2y, $x, $y)
    $prevX = $x
    $prevY = $y
  }

  if ($StyleNum.Flourish.Mode -gt 0) {
    $sc = [double]$StyleNum.Flourish.Scale
    $lastCode = [int][char]$nameChars[$charCount - 1]
    $fx = [math]::Min(198.0, $prevX + (5.0 + ($lastCode % 17) / 18.0 + (& $b 24) / 45.0) * $sc)
    $fy = $prevY - (4.0 + ($lastCode % 13) / 16.0 + (& $b 25) / 48.0) * $sc
    $mx = ($prevX + $fx) / 2.0 + (([int](& $b 26) - 128) / 29.0 + (($lastCode % 7) - 3) * 0.25) * $sc
    $my = ($prevY + $fy) / 2.0 - (3.0 + (& $b 27) / 44.0) * $sc
    [void]$parts.AppendFormat($inv, 'Q{0:0.##},{1:0.##},{2:0.##},{3:0.##}', $mx, $my, $fx, $fy)
  }

  return $parts.ToString()
}


function New-FilterId {
  param([string] $Text)
  $h = [System.Security.Cryptography.MD5]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($Text))
  return ([System.BitConverter]::ToString($h).Replace('-', '').Substring(0, 12))
}

function Build-SignatureSvgDocument {
  param(
    [string] $PathD,
    [string] $InkMain,
    [string] $InkUnder,
    [double] $UnderOpacity,
    [double] $MainWidth,
    [double] $UnderWidth,
    [double] $SlantDeg,
    [string] $FilterUniqueId
  )

  $c = [Globalization.CultureInfo]::InvariantCulture
  $uw = $UnderWidth.ToString($c)
  $mw = $MainWidth.ToString($c)
  $uo = $UnderOpacity.ToString($c)

  $slant = if ([math]::Abs($SlantDeg) -gt 0.01) {
    ' transform="rotate(' + ($SlantDeg.ToString($c)) + ' 100 24)"'
  } else { '' }

  $svg = @"
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 48" width="200" height="48">
  <rect id="sig-view-bg" width="200" height="48" fill="#ffffff"/>
  <defs>
    <filter id="ink-soft-$FilterUniqueId" x="-8%" y="-8%" width="116%" height="116%" color-interpolation-filters="sRGB">
      <feGaussianBlur in="SourceGraphic" stdDeviation="0.18" result="b"/>
      <feMerge>
        <feMergeNode in="b"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  <rect width="200" height="48" fill="none"/>
  <g id="signature-ink"$slant>
    <path d="$PathD" fill="none" stroke="$InkUnder" stroke-width="$uw" stroke-linecap="round" stroke-linejoin="round" opacity="$uo"/>
    <path d="$PathD" fill="none" stroke="$InkMain" stroke-width="$mw" stroke-linecap="round" stroke-linejoin="round" filter="url(#ink-soft-$FilterUniqueId)"/>
  </g>
</svg>
"@
  return $svg
}

function Get-MagickExecutable {
  param([string] $Explicit)
  if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
    if (-not (Test-Path -LiteralPath $Explicit)) { throw "MagickPath introuvable : $Explicit" }
    return (Resolve-Path -LiteralPath $Explicit).Path
  }
  $cmd = Get-Command magick.exe -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) { return $cmd.Source }
  $candidates = @(
    (Join-Path $env:ProgramFiles 'ImageMagick-7.1.1-Q16-HDRI\magick.exe')
    (Join-Path $env:ProgramFiles 'ImageMagick-7.1.0-Q16-HDRI\magick.exe')
  )
  foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
  return $null
}

function Get-InkscapeExecutable {
  param([string] $Explicit)
  if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
    if (-not (Test-Path -LiteralPath $Explicit)) { throw "InkscapePath introuvable : $Explicit" }
    return (Resolve-Path -LiteralPath $Explicit).Path
  }
  $cmd = Get-Command inkscape.exe -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) { return $cmd.Source }
  $candidates = @(
    (Join-Path ${env:ProgramFiles} 'Inkscape\bin\inkscape.exe')
    (Join-Path ${env:ProgramFiles(x86)} 'Inkscape\bin\inkscape.exe')
  )
  foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
  return $null
}

function Export-SvgToPng {
  param(
    [string] $SvgPath,
    [string] $PngPath,
    [int] $WidthPx,
    [string] $MagickExe,
    [string] $InkscapeExe,
    [ValidateSet('Transparent', 'White')]
    [string] $PngBackground = 'Transparent'
  )

  $svgFull = (Resolve-Path -LiteralPath $SvgPath).Path
  $pngFull = [System.IO.Path]::GetFullPath($PngPath)
  $pngDir  = Split-Path -Parent $pngFull
  if (-not (Test-Path -LiteralPath $pngDir)) {
    New-Item -ItemType Directory -Path $pngDir -Force | Out-Null
  }

  [string]$rawSvgTxt = [System.IO.File]::ReadAllText($svgFull, ([System.Text.Encoding]::UTF8))
  [string]$inputSvgRaster = $svgFull
  # Ne pas typer [string] : $null serait coercé en '' et $null -ne $tmpStrip deviendrait vrai → Remove-Item -LiteralPath ''.
  $tmpStrip = $null
  if (($PngBackground -eq 'Transparent') -and ($rawSvgTxt -match '\bid\s*=\s*"sig-view-bg"')) {
    [string]$svgForRaster = Remove-SvgViewerWhiteBackgroundRect -SvgText ([string]$rawSvgTxt)
    if (($null -ne $svgForRaster) -and ($svgForRaster -ne $rawSvgTxt)) {
      $tmpStrip = Join-Path $env:TEMP ('sig_png_nobg_' + [Guid]::NewGuid().ToString('N') + '.svg')
      [System.IO.File]::WriteAllText($tmpStrip, $svgForRaster, ([System.Text.UTF8Encoding]::new($false)))
      $inputSvgRaster = $tmpStrip
    }
  }

  if ($MagickExe) {
    $dpi = [int][math]::Max(96, [math]::Min(600, $WidthPx / 200.0 * 120))
    $bg = if ($PngBackground -eq 'Transparent') { 'none' } else { 'white' }
    if ($PngBackground -eq 'Transparent') {
      $arg = @(
        '-density', $dpi.ToString()
        '-background', $bg
        $inputSvgRaster
        '-resize', ($WidthPx.ToString() + 'x')
        '-alpha', 'on'
        $pngFull
      )
    }
    else {
      $arg = @(
        '-density', $dpi.ToString()
        '-background', $bg
        $inputSvgRaster
        '-resize', ($WidthPx.ToString() + 'x')
        '-alpha', 'off'
        $pngFull
      )
    }
    $p = Start-Process -FilePath $MagickExe -ArgumentList $arg -Wait -PassThru -NoNewWindow
    $exitM = $p.ExitCode
    if ($null -eq $exitM) { $exitM = 0 }
    if ($exitM -ne 0) { throw "ImageMagick a retourne le code $exitM." }
    if (-not (Test-Path -LiteralPath $pngFull)) { throw "PNG non cree : $pngFull" }
    if ($tmpStrip) { Remove-Item -LiteralPath $tmpStrip -Force -ErrorAction SilentlyContinue }
    return 'ImageMagick'
  }

  if ($InkscapeExe) {
    # Inkscape GTK : chemins avec espaces ou '=' mal cités ⇒ « multiple input files » ; on travaille en TEMP sans espaces.
    $svgWork = $inputSvgRaster
    $cleanupSvg = $false
    if ($svgFull -match '[\s;]') {
      $svgWork = Join-Path $env:TEMP ("sig_ink_in_" + [Guid]::NewGuid().ToString('N') + '.svg')
      Copy-Item -LiteralPath $inputSvgRaster -Destination $svgWork -Force
      $cleanupSvg = $true
    }
    $exportTarget = $pngFull
    if ($pngFull -match '[\s;]') {
      $exportTarget = Join-Path $env:TEMP ("sig_ink_" + [Guid]::NewGuid().ToString('N') + '.png')
    }
    if ($PngBackground -eq 'Transparent') {
      $arg = @(
        $svgWork
        '--export-type=png'
        "--export-filename=$exportTarget"
        "--export-width=$WidthPx"
        '--export-background-opacity=0'
      )
    }
    else {
      $arg = @(
        $svgWork
        '--export-type=png'
        "--export-filename=$exportTarget"
        "--export-width=$WidthPx"
        '--export-background=#ffffff'
        '--export-background-opacity=1'
      )
    }
    $p = Start-Process -FilePath $InkscapeExe -ArgumentList $arg -Wait -PassThru -NoNewWindow
    $exitI = $p.ExitCode
    if ($null -eq $exitI) { $exitI = 0 }
    if ($exitI -ne 0) {
      if ($cleanupSvg -and (Test-Path -LiteralPath $svgWork)) {
        Remove-Item -LiteralPath $svgWork -Force -ErrorAction SilentlyContinue
      }
      throw "Inkscape a retourne le code $exitI."
    }
    if (-not (Test-Path -LiteralPath $exportTarget)) {
      if ($cleanupSvg -and (Test-Path -LiteralPath $svgWork)) {
        Remove-Item -LiteralPath $svgWork -Force -ErrorAction SilentlyContinue
      }
      throw "PNG non cree : $exportTarget"
    }
    if ($exportTarget -ne $pngFull) {
      Copy-Item -LiteralPath $exportTarget -Destination $pngFull -Force
      Remove-Item -LiteralPath $exportTarget -Force -ErrorAction SilentlyContinue
    }
    if ($cleanupSvg -and (Test-Path -LiteralPath $svgWork)) {
      Remove-Item -LiteralPath $svgWork -Force -ErrorAction SilentlyContinue
    }
    if (-not (Test-Path -LiteralPath $pngFull)) { throw "PNG non copie : $pngFull" }
    if ($tmpStrip) { Remove-Item -LiteralPath $tmpStrip -Force -ErrorAction SilentlyContinue }
    return 'Inkscape'
  }

  if ($tmpStrip) { Remove-Item -LiteralPath $tmpStrip -Force -ErrorAction SilentlyContinue }
  throw "Aucun outil de conversion SVG->PNG (installez ImageMagick ou Inkscape, ou utilisez -SkipPng)."
}

# ---------------------------------------------------------------------------
# Corps
# ---------------------------------------------------------------------------

if (-not (Test-HexColor $Ink)) { throw "Ink invalide. Utilisez #RRGGBB, ex: #1f1210  (valeur recue : $Ink)" }
if (-not [string]::IsNullOrWhiteSpace($InkHalo)) {
  if (-not (Test-HexColor $InkHalo)) { throw "InkHalo invalide (#RRGGBB) : $InkHalo" }
}

$haloResolved = if ([string]::IsNullOrWhiteSpace($InkHalo)) {
  Get-DerivedHaloColor -MainHex $Ink
} else { $InkHalo }

$geomSeed = $Seed.Trim()

$styleNum = Get-StyleNumbers -Energy $Energy -Flourish $Flourish -Weight $Weight -Density $Density
$mainW = $styleNum.Stroke.Main
$underW = $styleNum.Stroke.Under
$effectiveHaloOpacity = [math]::Max($HaloOpacity, $styleNum.Stroke.UnderOp)

$fid = New-FilterId -Text ($geomSeed + '|sig|blackletter')

if ($RenderMode -eq 'PenNib') {
  Ensure-DrawingAssembly | Out-Null
  $halfBaseSvg = [double](([double]$mainW) * 0.74)

  $penPk = Invoke-PenNibFillPathAndDispose -GeometrySeed $geomSeed `
    -StyleNum $styleNum `
    -EnergyLabel $Energy `
    -FlourishName $Flourish `
    -DensityVal $Density `
    -FontFam ([string[]]$FontCandidates) `
    -EffectiveHalfBaseSvg $halfBaseSvg

  $svgDoc = Build-SignatureSvgRibbon -PathUnder $penPk.FillPathUnder -PathMain $penPk.FillPathMain `
    -InkUnder $haloResolved -InkMain $Ink -UnderOpacity $effectiveHaloOpacity `
    -SlantDeg $SlantDegrees -FilterUniqueId $fid
  $d = [string]$penPk.FillPathMain
}
else {
  $d = Build-SignatureInkPathD -GeometrySeed $geomSeed -StyleNum $styleNum
  $svgDoc = Build-SignatureSvgDocument -PathD $d `
    -InkMain $Ink -InkUnder $haloResolved -UnderOpacity $effectiveHaloOpacity `
    -MainWidth $mainW -UnderWidth $underW -SlantDeg $SlantDegrees -FilterUniqueId $fid
}

$safeStem = ([regex]::Replace($Seed.Substring(0, [math]::Min(48, $Seed.Length)), '[^\p{L}\p{N}_\-\s]', '')).Trim() -replace '\s+', '_'
if ([string]::IsNullOrWhiteSpace($safeStem)) { $safeStem = 'signature' }

# Sorties par défaut : Scripts/Signatures/ (répertoire du script)
$signatureOutDir = Join-Path $PSScriptRoot 'Signatures'

$outSvg = $OutputSvg
if ([string]::IsNullOrWhiteSpace($outSvg)) {
  if (-not (Test-Path -LiteralPath $signatureOutDir)) {
    New-Item -ItemType Directory -LiteralPath $signatureOutDir -Force | Out-Null
  }
  $outSvg = Join-Path $signatureOutDir ($safeStem + '_ink.svg')
}

$svgFull = [System.IO.Path]::GetFullPath($outSvg)
[System.IO.File]::WriteAllText($svgFull, $svgDoc, [System.Text.UTF8Encoding]::new($false))
Write-Host "SVG : $svgFull"

$result = [ordered]@{
  SvgPath              = $svgFull
  PngPath              = $null
  GeometrySeed         = $geomSeed
  PathLength           = $d.Length
  Energy               = $Energy
  Flourish             = $Flourish
  Weight               = $Weight
  Density              = $Density
  InkMain              = $Ink
  InkHaloResolved      = $haloResolved
  RenderMode           = $RenderMode
  PngBackground        = $PngBackground
}

if (-not $SkipPng) {
  $outPng = $OutputPng
  if ([string]::IsNullOrWhiteSpace($outPng)) {
    $outPng = [System.IO.Path]::ChangeExtension($svgFull, '.png')
  }
  $magickExe = Get-MagickExecutable -Explicit $MagickPath
  $inksExe = Get-InkscapeExecutable -Explicit $InkscapePath
  $which = Export-SvgToPng -SvgPath $svgFull -PngPath $outPng -WidthPx $PngWidthPx `
    -MagickExe $magickExe -InkscapeExe $inksExe -PngBackground $PngBackground
  Write-Host "PNG : $(([System.IO.Path]::GetFullPath($outPng)))  (via $which)"
  $result['PngPath'] = [System.IO.Path]::GetFullPath($outPng)
  $result['Renderer'] = $which
} else {
  Write-Host "PNG omis (-SkipPng)."
}

if ($PassThru) {
  return [pscustomobject]$result
}
