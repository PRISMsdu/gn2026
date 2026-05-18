# Utilitaire inclus par export_doc.ps1 et export_avis.ps1 pour inserer les signatures PNG aux exports.
# Detecte dans le Markdown les marqueurs du type :
#   (*Signature*: Nom) ou (*Signatures*: Nom)
#   Espaces facultatifs autour de * Signature * et avant : tolérés pour relectures humaines.
# et les remplace par du HTML brut pointant vers un PNG genere par generate_signature_ink.ps1
# sous Scripts/Signatures/ (nom stable par hash SHA256 du texte UTF-8).

function ConvertTo-ExportMarkdownHtmlUriPath {
  param([string] $Path)
  return ($Path -replace '\\', '/')
}

function Get-RelativeUriBetweenFiles {
  param(
    [string] $FromAbsoluteFile,
    [string] $ToAbsoluteFile
  )
  $fromDir = Split-Path -Parent $FromAbsoluteFile
  if (-not $fromDir.EndsWith('\')) { $fromDir += '\' }
  $fromUri = New-Object System.Uri $fromDir
  $toUri = New-Object System.Uri $ToAbsoluteFile
  $rel = $fromUri.MakeRelativeUri($toUri).ToString()
  return (ConvertTo-ExportMarkdownHtmlUriPath $rel)
}

function Expand-MarkdownInkSignatureMarkers {
  param(
    [Parameter(Mandatory)][string]$MarkdownRaw,
    [Parameter(Mandatory)][string]$HtmlAbsolutePath,
    [Parameter(Mandatory)][string]$ScriptsPSScriptRoot,
    [switch]$ForceRegenerate,
    [int]$SignatureMaxEdgePx = 400
  )

  $pattern = '(?msi)\(\*\s*[Ss]ignatures?\s*\*\s*:\s*([^\)]+)\)'
  $rx = New-Object regex $pattern

  $genScript = Join-Path $ScriptsPSScriptRoot 'generate_signature_ink.ps1'
  if (-not (Test-Path -LiteralPath $genScript)) {
    throw ('Script de signature introuvable : ' + $genScript)
  }

  $sigDir = Join-Path $ScriptsPSScriptRoot 'Signatures'
  if (-not (Test-Path -LiteralPath $sigDir)) {
    New-Item -ItemType Directory -Path $sigDir -Force | Out-Null
  }

  $matches = [array]$rx.Matches($MarkdownRaw)
  if (-not $matches -or ($matches.Length -eq 0)) {
    return $MarkdownRaw
  }

  # Remplacements de la fin vers le debut pour preserver les index.
  [System.Text.StringBuilder]$sbOut = New-Object System.Text.StringBuilder ($MarkdownRaw)
  for ($i = $matches.Count - 1; $i -ge 0; $i--) {
    $m = $matches[$i]
    $signatory = ($m.Groups[1].Value.Trim())
    if ([string]::IsNullOrWhiteSpace($signatory)) { continue }

    $sigBytes = [System.Text.Encoding]::UTF8.GetBytes($signatory)
    $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($sigBytes)
    $hex16 = ([System.BitConverter]::ToString($h).Replace('-', '').Substring(0, 16)).ToLowerInvariant()
    $pngName = 'sig_sha256_' + $hex16 + '.png'
    $pngAbs = [System.IO.Path]::GetFullPath((Join-Path $sigDir $pngName))

    if ($ForceRegenerate -or (-not (Test-Path -LiteralPath $pngAbs))) {
      # generate_signature_ink.ps1 utilise Write-Host pour les chemins : silencieux cote succes.
      & $genScript -Seed $signatory -OutputPng $pngAbs | Out-Null
      if (-not (Test-Path -LiteralPath $pngAbs)) {
        throw ('PNG de signature non cree : ' + $pngAbs + ' pour « ' + $signatory + ' »')
      }
    }

    $sigCacheDir = Join-Path $ScriptsPSScriptRoot '.export_image_cache'
    $pngForPrint = $pngAbs
    if (Get-Command Optimize-ExportImageForPrint -ErrorAction SilentlyContinue) {
      $opt = Optimize-ExportImageForPrint -SourcePath $pngAbs -MaxEdgePx $SignatureMaxEdgePx -CacheDir $sigCacheDir
      if ($opt) { $pngForPrint = $opt }
    }

    $rel = Get-RelativeUriBetweenFiles -FromAbsoluteFile $HtmlAbsolutePath -ToAbsoluteFile $pngForPrint
    $altEsc = [System.Net.WebUtility]::HtmlEncode($signatory)
    # Bloc brut accepte par Pandoc Markdown (HTML passe en sortie lorsque autorise par le format).
    $replacement = "`n<div class=`"doc-export-signature`">`n<img src=`"$rel`" alt=`"$altEsc`" class=`"doc-export-signature-ink`" />`n</div>`n"

    [void]$sbOut.Remove($m.Index, $m.Length)
    [void]$sbOut.Insert($m.Index, $replacement)
  }

  return ($sbOut.ToString())
}
