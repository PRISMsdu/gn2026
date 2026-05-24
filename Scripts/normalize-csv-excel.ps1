# Normalise les CSV GN pour Excel Windows : UTF-8 avec BOM + fins CRLF.
# Usage : .\scripts\normalize-csv-excel.ps1 [-Path "Groupes\...\file.csv"]

param(
    [string[]]$Path = @(
        "Groupes\Mafia - Les Sangs de la Steppe\1 - Back de groupe\Competences_Mafia.csv",
        "Groupes\MiVI\1 - Back de groupe\Competence_MiVI.csv",
        "Groupes\Tripot\1 - Back de groupe\Competence_tripot.csv",
        "Groupes\Palyr\1 - Back de groupe\Competences_Palyr.csv",
        "Groupes\Banquiers - UBI\1 - Back de groupe\Comptences_UBI.csv"
    )
)

$root = Split-Path $PSScriptRoot -Parent
$utf8Bom = New-Object System.Text.UTF8Encoding $true

foreach ($rel in $Path) {
    $full = Join-Path $root $rel
    if (-not (Test-Path $full)) {
        Write-Warning "Absent : $rel"
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $text = $utf8.GetString($bytes)
  $text = $text -replace "`r`n", "`n" -replace "`n", "`r`n"
    $text = $text.TrimEnd("`r", "`n") + "`r`n"
    [System.IO.File]::WriteAllText($full, $text, $utf8Bom)
    $check = [System.IO.File]::ReadAllBytes($full)
    $hasBom = ($check.Length -ge 3 -and $check[0] -eq 0xEF -and $check[1] -eq 0xBB -and $check[2] -eq 0xBF)
    Write-Host ("OK {0} BOM={1}" -f (Split-Path $rel -Leaf), $hasBom)
}
