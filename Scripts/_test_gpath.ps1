Add-Type -AssemblyName System.Drawing
$f = New-Object Drawing.Font ('Times New Roman', [float]48.0,
  [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$gp = New-Object Drawing.Drawing2D.GraphicsPath
$sf = [Drawing.StringFormat]::GenericTypographic.Clone()
$sf.FormatFlags = 'NoWrap'
$gp.AddString('Ysvel', [Drawing.FontFamily]$f.FontFamily, [int]$f.Style,
  [float]$f.Size, [Drawing.Point]::new(40, 50), $sf)
Write-Host Before Flatten $($gp.PointCount)
$gp.Flatten()
Write-Host After Flatten $($gp.PointCount)
$n = [math]::Min(40, $gp.PointCount - 1)
for ($r = 0; $r -lt $gp.PointCount; $r++) {
  $tb = [int]$gp.PathTypes[$r]
  if (($tb -band 128) -ne 0) { Write-Host "CLOSE_AT $r type=$tb" }
}
