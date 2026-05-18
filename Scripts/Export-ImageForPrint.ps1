# Utilitaire partagé : redimensionner / compresser les images avant export PDF (Chrome embarque le fichier source entier).
# Dot-source depuis export_back_groupe.ps1, export_avis.ps1, export_charte_UBI.ps1, export_doc.ps1, generate_signature_ink.ps1.

function Get-MagickExecutableForPrint {
  param([string] $ExplicitPath = '')
  if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
    if (-not (Test-Path -LiteralPath $ExplicitPath)) { return $null }
    return (Resolve-Path -LiteralPath $ExplicitPath).Path
  }
  $cmd = Get-Command magick.exe -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }
  foreach ($c in @(
      (Join-Path $env:ProgramFiles 'ImageMagick-7.1.1-Q16-HDRI\magick.exe')
      (Join-Path $env:ProgramFiles 'ImageMagick-7.1.0-Q16-HDRI\magick.exe')
    )) {
    if (Test-Path -LiteralPath $c) { return $c }
  }
  return $null
}

function Get-ExportImageCacheDir {
  param([string] $ScriptsRoot)
  $d = Join-Path $ScriptsRoot '.export_image_cache'
  if (-not (Test-Path -LiteralPath $d)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
  }
  return $d
}

function Get-ExportImageCacheKey {
  param(
    [string] $SourcePath,
    [int]    $MaxEdgePx
  )
  $fi = Get-Item -LiteralPath $SourcePath
  $blob = $fi.FullName + '|' + $fi.Length + '|' + $fi.LastWriteTimeUtc.Ticks + '|' + $MaxEdgePx
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($blob)
  $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
  return ([System.BitConverter]::ToString($hash).Replace('-', '').ToLowerInvariant().Substring(0, 24))
}

function Get-ImageMaxEdgePx {
  param([string] $SourcePath)
  try {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $img = [System.Drawing.Image]::FromFile($SourcePath)
    try {
      return [int][math]::Max($img.Width, $img.Height)
    } finally {
      $img.Dispose()
    }
  } catch {
    return $null
  }
}

function Save-BitmapToPath {
  param(
    [System.Drawing.Bitmap] $Bitmap,
    [string]              $DestPath
  )
  $ext = [System.IO.Path]::GetExtension($DestPath).ToLowerInvariant()
  if ($ext -in '.jpg', '.jpeg') {
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
      Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
    if ($codec) {
      $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
      $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter (
        [System.Drawing.Imaging.Encoder]::Quality, [long]88)
      $Bitmap.Save($DestPath, $codec, $ep)
      $ep.Dispose()
      return
    }
  }
  $Bitmap.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Resize-ImageWithSystemDrawing {
  param(
    [string] $SourcePath,
    [string] $DestPath,
    [int]    $MaxEdgePx
  )
  Add-Type -AssemblyName System.Drawing -ErrorAction Stop
  $src = [System.Drawing.Image]::FromFile($SourcePath)
  try {
    $w = [double]$src.Width
    $h = [double]$src.Height
    $max = [math]::Max($w, $h)
    $ratio = if ($max -gt $MaxEdgePx) { $MaxEdgePx / $max } else { 1.0 }
    $nw = [int][math]::Max(1, [math]::Round($w * $ratio))
    $nh = [int][math]::Max(1, [math]::Round($h * $ratio))

    if ($ratio -ge 0.999 -and $SourcePath -eq $DestPath) {
      return
    }

    $bmp = New-Object System.Drawing.Bitmap $nw, $nh
    try {
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      try {
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.DrawImage($src, 0, 0, $nw, $nh)
      } finally {
        $g.Dispose()
      }
      Save-BitmapToPath -Bitmap $bmp -DestPath $DestPath
    } finally {
      $bmp.Dispose()
    }
  } finally {
    $src.Dispose()
  }
}

function Optimize-ExportImageForPrint {
  <#
    Retourne un chemin vers une variante redimensionnée (cache) adaptée à l'affichage PDF.
    Les fichiers sources du dépôt ne sont pas modifiés sauf avec -InPlace.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string] $SourcePath,
    [int] $MaxEdgePx = 256,
    [string] $CacheDir = '',
    [switch] $InPlace
  )

  if (-not (Test-Path -LiteralPath $SourcePath)) { return $null }

  $srcAbs = (Resolve-Path -LiteralPath $SourcePath).Path
  $fi = Get-Item -LiteralPath $srcAbs
  $ext = [System.IO.Path]::GetExtension($srcAbs).ToLowerInvariant()
  if ($ext -notin '.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp') {
    return $srcAbs
  }

  $maxEdge = Get-ImageMaxEdgePx -SourcePath $srcAbs
  if ($null -ne $maxEdge -and $maxEdge -le $MaxEdgePx -and $fi.Length -lt 120000) {
    return $srcAbs
  }

  if ([string]::IsNullOrWhiteSpace($CacheDir)) {
    $CacheDir = Join-Path ([System.IO.Path]::GetTempPath()) 'GN2026_export_image_cache'
  }
  if (-not (Test-Path -LiteralPath $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
  }

  $outExt = if ($ext -in '.jpg', '.jpeg') { '.jpg' } else { '.png' }
  $key = Get-ExportImageCacheKey -SourcePath $srcAbs -MaxEdgePx $MaxEdgePx
  $dest = Join-Path $CacheDir ($key + $outExt)

  if ((Test-Path -LiteralPath $dest) -and ((Get-Item -LiteralPath $dest).LastWriteTimeUtc -ge $fi.LastWriteTimeUtc)) {
    if ($InPlace -and ($dest -ne $srcAbs)) {
      Copy-Item -LiteralPath $dest -Destination $srcAbs -Force
    }
    return $(if ($InPlace) { $srcAbs } else { $dest })
  }

  $magick = Get-MagickExecutableForPrint
  $resize = "${MaxEdgePx}x${MaxEdgePx}>"

  if ($magick) {
    if ($outExt -eq '.jpg') {
      $arg = @($srcAbs, '-auto-orient', '-resize', $resize, '-strip', '-quality', '88', $dest)
    } else {
      $arg = @($srcAbs, '-auto-orient', '-resize', $resize, '-strip', '-define', 'png:compression-level=9', $dest)
    }
    $p = Start-Process -FilePath $magick -ArgumentList $arg -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0 -and $null -ne $p.ExitCode) {
      Write-Warning "ImageMagick code $($p.ExitCode) pour $srcAbs - repli System.Drawing."
      Resize-ImageWithSystemDrawing -SourcePath $srcAbs -DestPath $dest -MaxEdgePx $MaxEdgePx
    }
  } else {
    Resize-ImageWithSystemDrawing -SourcePath $srcAbs -DestPath $dest -MaxEdgePx $MaxEdgePx
  }

  if (-not (Test-Path -LiteralPath $dest)) {
    Write-Warning "Optimisation image echouee, source conservee : $srcAbs"
    return $srcAbs
  }

  if ($InPlace) {
    Copy-Item -LiteralPath $dest -Destination $srcAbs -Force
    return $srcAbs
  }
  return $dest
}
