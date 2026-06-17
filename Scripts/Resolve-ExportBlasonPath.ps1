# Résolution du blason pour export_avis.ps1, export_doc.ps1, etc.
# Ordre : Blason_* dans le dossier du .md → LivretsLocaux/Blasons → chemin forcé (GN_AVIS_BLASON_PATH).

function Get-ExportBlasonCatalogDir {
  param([string] $ScriptsRoot)
  Join-Path (Split-Path -Parent $ScriptsRoot) 'LivretsLocaux\Blasons'
}

function Get-ExportBlasonGroupSlug {
  param(
    [string] $Directory,
    [string[]] $PreferredNames = @()
  )

  if (-not (Test-Path -LiteralPath $Directory)) { return $null }

  foreach ($name in $PreferredNames) {
    $candidate = Join-Path $Directory $name
    if (Test-Path -LiteralPath $candidate) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  foreach ($ext in @('png', 'jpg', 'jpeg', 'webp')) {
    $found = Get-ChildItem -LiteralPath $Directory -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match ('^[Bb]lason_.*\.' + $ext + '$') } |
      Sort-Object @{
        Expression = {
          if ($_.Name -match '_\+') { 0 } else { 1 }
        }
      }, Name |
      Select-Object -First 1
    if ($found) { return $found.FullName }
  }

  return $null
}

function Get-ExportBlasonPreferredNames {
  param([string] $Slug)

  $e = [char]0xe9
  $therFelis = "Ther-F$e" + 'lis'

  $map = @{
    'Palyr'      = @('Blason_Palyr_+.png', 'Blason_Palyr.png')
    'Arthas'     = @('Blason_Arthas_+.png', 'Blason_Arthas.png')
    'Il-Irion'   = @('Blason_Il-Irion_+.png', 'Blason_Il-Irion.png')
    'Sfaal'      = @('Blason_Sfaal_+.png', 'Blason_Sfaal.png')
    'Staal'      = @('Blason_Sfaal_+.png', 'Blason_Sfaal.png')
    'Ther-Félis' = @("Blason_$therFelis`_+.png", "Blason_$therFelis`.png")
    'Ther-Felis' = @("Blason_$therFelis`_+.png", "Blason_$therFelis`.png")
    'UBI'        = @('Blason_UBI.png')
    'Tripot'     = @('Blason_Tripot.png', 'badge_Tripot.png')
    'Guilde des Ports Unis' = @('blason_guilde_ports_unis_+.png', 'blason_guilde_ports_unis.png')
    'Talamh'     = @('Blason_Talamh.png')
    'Confédération' = @("Blason_Cit${e}s_du_levant_+.png", "Blason_Cit${e}s_du_levant.png")
    'Confederation' = @("Blason_Cit${e}s_du_levant_+.png", "Blason_Cit${e}s_du_levant.png")
  }

  if ($map.ContainsKey($Slug)) { return $map[$Slug] }

  return @()
}

function Get-ExportBlasonGroupSlug {
  param([string] $GroupFolder)

  switch -Regex ($GroupFolder) {
    '^Palyr$' { return 'Palyr' }
    '^Arthas$' { return 'Arthas' }
    '^Sfaal$' { return 'Sfaal' }
    '^Il-Irion$' { return 'Il-Irion' }
    '^Ther-F' { return 'Ther-Félis' }
    'UBI|Banquiers' { return 'UBI' }
    '^Tripot$' { return 'Tripot' }
    'Guilde|Ports Unis|Sangs' { return 'Guilde des Ports Unis' }
    '^MiVI$' { return 'Styrgie' }
    default { return $null }
  }
}

function Get-ExportBlasonSlugsFromText {
  param([string] $Text)

  if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

  $found = [System.Collections.Generic.List[string]]::new()

  function Add-Slug {
    param([string] $Slug)
    if ([string]::IsNullOrWhiteSpace($Slug)) { return }
    if (-not $found.Contains($Slug)) { [void]$found.Add($Slug) }
  }

  if ($Text -match 'Union bancaire|Banquiers|\bUBI\b') { Add-Slug 'UBI' }
  if ($Text -match 'Guilde des Ports Unis|\bGuilde\b') { Add-Slug 'Guilde des Ports Unis' }
  if ($Text -match 'Confédération|Confederation|\bCités du Levant\b|\bCites du Levant\b') { Add-Slug 'Confédération' }
  if ($Text -match '\bIl-Irion\b') { Add-Slug 'Il-Irion' }
  if ($Text -match '\bTher-F[eé]lis\b') { Add-Slug 'Ther-Félis' }
  if ($Text -match '\bPalyr\b') { Add-Slug 'Palyr' }
  if ($Text -match '\bArthas\b') { Add-Slug 'Arthas' }
  if ($Text -match '\bSfaal\b|\bStaal\b') { Add-Slug 'Sfaal' }
  if ($Text -match '\bTripot\b') { Add-Slug 'Tripot' }
  if ($Text -match '\bTalamh\b') { Add-Slug 'Talamh' }

  return @($found)
}

function Get-ExportBlasonSlugHints {
  param(
    [string] $MarkdownPath,
    [string] $InstitutionNom,
    [string] $MarkdownRaw
  )

  $hints = [System.Collections.Generic.List[string]]::new()

  function Add-Hint {
    param([string] $Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return }
    if (-not $hints.Contains($Value)) { [void]$hints.Add($Value) }
  }

  if ($MarkdownPath -match '[\\/]Groupes[\\/]([^\\/]+)') {
    $groupSlug = Get-ExportBlasonGroupSlug -GroupFolder $Matches[1]
    if ($groupSlug) { Add-Hint $groupSlug }
  }

  if ($MarkdownRaw -match '(?m)^\s*InstitutionLigne\s*:\s*(.+?)\s*$') {
    foreach ($slug in (Get-ExportBlasonSlugsFromText -Text $Matches[1])) {
      Add-Hint $slug
    }
  }

  foreach ($slug in (Get-ExportBlasonSlugsFromText -Text $InstitutionNom)) {
    Add-Hint $slug
  }

  return @($hints)
}

function Find-BlasonInCatalog {
  param(
    [string] $CatalogDir,
    [string[]] $SlugHints
  )

  if (-not (Test-Path -LiteralPath $CatalogDir)) { return $null }

  foreach ($hint in $SlugHints) {
    $preferred = Get-ExportBlasonPreferredNames -Slug $hint
    if ($preferred.Count -eq 0) { continue }
    $found = Find-BlasonImageInDirectory -Directory $CatalogDir -PreferredNames $preferred
    if ($found) { return $found }
  }

  return $null
}

function Resolve-ForcedExportBlasonPath {
  param([string] $ForcedBlasonPath)

  if ([string]::IsNullOrWhiteSpace($ForcedBlasonPath)) { return $null }

  if ([System.IO.Path]::IsPathRooted($ForcedBlasonPath)) {
    $candidate = $ForcedBlasonPath
  } else {
    $candidate = Join-Path (Get-Location).Path $ForcedBlasonPath
  }

  if (Test-Path -LiteralPath $candidate) {
    return (Resolve-Path -LiteralPath $candidate).Path
  }

  return $null
}

function Resolve-ExportBlasonPath {
  param(
    [string] $MarkdownDirectory,
    [string] $MarkdownPath,
    [string] $InstitutionNom,
    [string] $MarkdownRaw,
    [string] $ScriptsRoot,
    [string] $ForcedBlasonPath = $null
  )

  $local = Find-BlasonImageInDirectory -Directory $MarkdownDirectory
  if ($local) { return $local }

  $catalogDir = Get-ExportBlasonCatalogDir -ScriptsRoot $ScriptsRoot
  $hints = Get-ExportBlasonSlugHints -MarkdownPath $MarkdownPath `
    -InstitutionNom $InstitutionNom -MarkdownRaw $MarkdownRaw
  $catalog = Find-BlasonInCatalog -CatalogDir $catalogDir -SlugHints $hints
  if ($catalog) { return $catalog }

  return Resolve-ForcedExportBlasonPath -ForcedBlasonPath $ForcedBlasonPath
}
