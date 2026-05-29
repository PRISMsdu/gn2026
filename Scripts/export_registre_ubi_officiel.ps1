<#
  Export PDF du registre officiel UBI a partir du CSV joueur.

  Le script reprend la chaine d'export des registres Tripot :
    - Markdown intermediaire
    - Scripts/export_registre_compta.ps1
    - Scripts/registre_print.css et Scripts/registre_shell.html

  Il produit aussi :
    - README_CAUBI.md : methode de calcul du CA documentaire UBI
    - registre_Comptable_UBI.md : recapitulatif comptable par annee
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string] $CsvPath,

  [string] $OutputMarkdownPath = "",

  [string] $AccountingPath = "",

  [string] $ReadmeCaPath = "",

  [ValidateSet('A4', 'A3')]
  [string] $Format = 'A4',

  [switch] $SkipPdf,

  [ValidateSet('Auto', 'Chrome', 'Edge')]
  [string] $Browser = 'Auto',

  [string] $ChromePath = "",

  [string] $PandocPath = ""
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
  param(
    [string] $Path,
    [string] $Text
  )
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Convert-RomanToInt {
  param([string] $Roman)
  $map = @{
    I = 1; II = 2; III = 3; IV = 4; V = 5; VI = 6
    VII = 7; VIII = 8; IX = 9; X = 10; XI = 11; XII = 12; XIII = 13
  }
  if (-not $map.ContainsKey($Roman)) {
    throw "Mois romain inconnu : $Roman"
  }
  return $map[$Roman]
}

function Convert-DateToKey {
  param([string] $Date)
  $parts = $Date -split '-'
  if ($parts.Count -ne 3) {
    throw "Date invalide : $Date"
  }
  $year = [int]$parts[0]
  $month = Convert-RomanToInt $parts[1]
  $day = [int]$parts[2]
  return ($year * 10000) + ($month * 100) + $day
}

function Get-YearFromDate {
  param([string] $Date)
  return [int](($Date -split '-')[0])
}

function Escape-MdCell {
  param([string] $Value)
  if ($null -eq $Value) { return "" }
  return ($Value -replace '\|', '\|').Trim()
}

function Format-Couronnes {
  param([int] $Value)
  return ("{0:N0}" -f $Value).Replace(',', ' ').Replace([char]160, ' ')
}

function Is-AnonymousDeposit {
  param($Row)
  $deposant = [string]$Row.'Déposé par'
  return ($deposant -match '(?i)anonyme|origine inconnue')
}

function Get-FeeOneShot {
  param([string] $Criticite)
  switch ($Criticite) {
    'I' { return 0 }
    'II' { return 1 }
    'III' { return 10 }
    'IV' { return 50 }
    default { throw "Criticite inconnue : $Criticite" }
  }
}

function Get-FeeAnnual {
  param([string] $Criticite)
  switch ($Criticite) {
    'I' { return 0 }
    'II' { return 1 }
    'III' { return 5 }
    'IV' { return 10 }
    default { throw "Criticite inconnue : $Criticite" }
  }
}

function Get-RecognizedPayer {
  param($Row)
  return ([string]$Row.'Déposé par').Trim()
}

function Get-YearStats {
  param(
    [array] $AllRows,
    [int] $Year
  )

  $rowsThisYear = @($AllRows | Where-Object { $_.DepositYear -eq $Year })
  $recognizedActive = @($AllRows | Where-Object { -not $_.Anonymous -and $_.DepositYear -le $Year })
  $anonymousThisYear = @($AllRows | Where-Object { $_.Anonymous -and $_.DepositYear -eq $Year })

  $payerTotals = @{}
  foreach ($row in $recognizedActive) {
    $payer = Get-RecognizedPayer $row
    $fee = Get-FeeAnnual $row.'Criticité'
    if (-not $payerTotals.ContainsKey($payer)) { $payerTotals[$payer] = 0 }
    $payerTotals[$payer] += $fee
  }

  $oneShotTotal = 0
  foreach ($row in $anonymousThisYear) {
    $oneShotTotal += Get-FeeOneShot $row.'Criticité'
  }

  $annualTotal = 0
  foreach ($value in $payerTotals.Values) { $annualTotal += [int]$value }

  return [pscustomobject]@{
    RowsThisYear = $rowsThisYear
    PayerTotals = $payerTotals
    AnonymousThisYear = $anonymousThisYear
    AnnualTotal = $annualTotal
    OneShotTotal = $oneShotTotal
    Turnover = $annualTotal + $oneShotTotal
  }
}

function Build-OfficialRegisterMarkdown {
  param(
    [array] $Rows,
    [array] $Years
  )

  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.AppendLine("# Registre officiel UBI — documents déposés")
  [void]$sb.AppendLine()
  [void]$sb.AppendLine("Registre de consultation des documents confiés à l'Union bancaire d'Il-Irion.")
  [void]$sb.AppendLine()
  [void]$sb.AppendLine("---")
  [void]$sb.AppendLine()

  $first = $true
  foreach ($year in $Years) {
    if (-not $first) {
      [void]$sb.AppendLine("---")
      [void]$sb.AppendLine()
    }
    $first = $false

    $stats = Get-YearStats -AllRows $Rows -Year $year
    $rowsThisYear = @($stats.RowsThisYear | Sort-Object DateKey, 'Référence')

    [void]$sb.AppendLine("## Année $year")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| Référence | Type de document | Parties | Déposé par | Date | Criticité |")
    [void]$sb.AppendLine("|---|---|---|---|---|---|")
    foreach ($row in $rowsThisYear) {
      [void]$sb.AppendLine("| $(Escape-MdCell $row.'Référence') | $(Escape-MdCell $row.'Type de document') | $(Escape-MdCell $row.'Parties') | $(Escape-MdCell $row.'Déposé par') | $(Escape-MdCell $row.'Date') | $(Escape-MdCell $row.'Criticité') |")
    }
    [void]$sb.AppendLine()

    $critGroups = @($rowsThisYear | Group-Object 'Criticité' | Sort-Object Name)
    $critSummary = if ($critGroups.Count -gt 0) {
      ($critGroups | ForEach-Object { "$($_.Name) : $($_.Count)" }) -join " ; "
    } else {
      "aucune entrée"
    }

    [void]$sb.AppendLine("### Clôture année $year")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| Libellé | Valeur |")
    [void]$sb.AppendLine("|---|---:|")
    [void]$sb.AppendLine("| Entrées enregistrées | $($rowsThisYear.Count) |")
    [void]$sb.AppendLine("| Répartition criticité | $critSummary |")
    [void]$sb.AppendLine("| Dépôts anonymes de l'année | $(@($stats.AnonymousThisYear).Count) |")
    [void]$sb.AppendLine("| Frais annuels facturés | $(Format-Couronnes $stats.AnnualTotal) c |")
    [void]$sb.AppendLine("| Droits d'enregistrement anonymes | $(Format-Couronnes $stats.OneShotTotal) c |")
    [void]$sb.AppendLine("| CA documentaire UBI | $(Format-Couronnes $stats.Turnover) c |")
    [void]$sb.AppendLine()
  }

  return $sb.ToString()
}

function Build-ReadmeCa {
  $text = @'
# README_CAUBI — méthode de calcul

Ce fichier décrit la méthode utilisée pour calculer le chiffre d'affaires documentaire de l'UBI à partir du registre officiel.

## Règles de tarification

Les documents de classe I sont stockés gracieusement.

Les documents anonymes sont payés une seule fois à l'enregistrement :

| Criticité | Prix à l'enregistrement |
|---|---:|
| I | 0 c |
| II | 1 c |
| III | 10 c |
| IV | 50 c |

Les documents impliquant des parties reconnues sont payés annuellement :

| Criticité | Prix annuel |
|---|---:|
| I | 0 c |
| II | 1 c |
| III | 5 c |
| IV | 10 c |

## Application

Un document est traité comme anonyme lorsque la colonne `Déposé par` contient `anonyme` ou `origine inconnue`.

Un document reconnu est facturé au nom inscrit dans la colonne `Déposé par`.

Pour chaque année, le registre comptable additionne :

- les frais annuels de tous les documents reconnus déjà déposés à cette date ;
- les droits d'enregistrement des documents anonymes déposés pendant l'année.

Le CA documentaire annuel est la somme de ces deux montants.
'@
  return $text
}

function Build-AccountingMarkdown {
  param(
    [array] $Rows,
    [array] $Years
  )

  $sb = [System.Text.StringBuilder]::new()
  [void]$sb.AppendLine("# Registre comptable UBI — garde des documents")
  [void]$sb.AppendLine()
  [void]$sb.AppendLine("Registre des frais de garde et des droits d'enregistrement calculés depuis le registre officiel UBI.")
  [void]$sb.AppendLine()
  [void]$sb.AppendLine("---")
  [void]$sb.AppendLine()

  $grandAnnual = 0
  $grandOneShot = 0

  foreach ($year in $Years) {
    $stats = Get-YearStats -AllRows $Rows -Year $year
    $grandAnnual += $stats.AnnualTotal
    $grandOneShot += $stats.OneShotTotal

    [void]$sb.AppendLine("## Année $year")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("### Frais annuels par payeur")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| Payeur | Pièces facturées | Prix facturé |")
    [void]$sb.AppendLine("|---|---:|---:|")

    $payerRows = foreach ($payer in ($stats.PayerTotals.Keys | Sort-Object)) {
      $pieceCount = @($Rows | Where-Object { -not $_.Anonymous -and $_.DepositYear -le $year -and (Get-RecognizedPayer $_) -eq $payer }).Count
      [pscustomobject]@{
        Payer = $payer
        Count = $pieceCount
        Total = [int]$stats.PayerTotals[$payer]
      }
    }

    if (@($payerRows).Count -eq 0) {
      [void]$sb.AppendLine("| Aucun | 0 | 0 c |")
    } else {
      foreach ($payerRow in ($payerRows | Sort-Object Payer)) {
        [void]$sb.AppendLine("| $(Escape-MdCell $payerRow.Payer) | $($payerRow.Count) | $(Format-Couronnes $payerRow.Total) c |")
      }
    }

    [void]$sb.AppendLine()
    [void]$sb.AppendLine("### Droits d'enregistrement anonymes")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| Référence | Criticité | Prix à l'enregistrement |")
    [void]$sb.AppendLine("|---|---|---:|")

    if (@($stats.AnonymousThisYear).Count -eq 0) {
      [void]$sb.AppendLine("| Aucun | — | 0 c |")
    } else {
      foreach ($row in (@($stats.AnonymousThisYear) | Sort-Object DateKey, 'Référence')) {
        $fee = Get-FeeOneShot $row.'Criticité'
        [void]$sb.AppendLine("| $(Escape-MdCell $row.'Référence') | $(Escape-MdCell $row.'Criticité') | $(Format-Couronnes $fee) c |")
      }
    }

    [void]$sb.AppendLine()
    [void]$sb.AppendLine("### Clôture comptable $year")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| Libellé | Valeur |")
    [void]$sb.AppendLine("|---|---:|")
    [void]$sb.AppendLine("| Frais annuels reconnus | $(Format-Couronnes $stats.AnnualTotal) c |")
    [void]$sb.AppendLine("| Droits d'enregistrement anonymes | $(Format-Couronnes $stats.OneShotTotal) c |")
    [void]$sb.AppendLine("| CA documentaire annuel | $(Format-Couronnes $stats.Turnover) c |")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine()
  }

  [void]$sb.AppendLine("## Récapitulatif général")
  [void]$sb.AppendLine()
  [void]$sb.AppendLine("| Libellé | Valeur |")
  [void]$sb.AppendLine("|---|---:|")
  [void]$sb.AppendLine("| Total frais annuels reconnus | $(Format-Couronnes $grandAnnual) c |")
  [void]$sb.AppendLine("| Total droits anonymes à l'enregistrement | $(Format-Couronnes $grandOneShot) c |")
  [void]$sb.AppendLine("| CA documentaire cumulé | $(Format-Couronnes ($grandAnnual + $grandOneShot)) c |")

  return $sb.ToString()
}

$csvResolved = (Resolve-Path -LiteralPath $CsvPath).Path
$csvDir = Split-Path -Parent $csvResolved

if (-not $OutputMarkdownPath) {
  $OutputMarkdownPath = Join-Path $csvDir "Registre_UBI_officiel.md"
}
if (-not $AccountingPath) {
  $AccountingPath = Join-Path $csvDir "registre_Comptable_UBI.md"
}
if (-not $ReadmeCaPath) {
  $ReadmeCaPath = Join-Path $csvDir "README_CAUBI.md"
}

$rows = @(Import-Csv -LiteralPath $csvResolved -Delimiter ';' -Encoding UTF8)
foreach ($row in $rows) {
  $row | Add-Member -NotePropertyName DateKey -NotePropertyValue (Convert-DateToKey $row.'Date') -Force
  $row | Add-Member -NotePropertyName DepositYear -NotePropertyValue (Get-YearFromDate $row.'Date') -Force
  $row | Add-Member -NotePropertyName Anonymous -NotePropertyValue (Is-AnonymousDeposit $row) -Force
}
$rows = @($rows | Sort-Object DateKey, 'Référence')
$years = @($rows | Select-Object -ExpandProperty DepositYear -Unique | Sort-Object)

Write-Utf8NoBom -Path ([System.IO.Path]::GetFullPath($OutputMarkdownPath)) -Text (Build-OfficialRegisterMarkdown -Rows $rows -Years $years)
Write-Utf8NoBom -Path ([System.IO.Path]::GetFullPath($ReadmeCaPath)) -Text (Build-ReadmeCa)
Write-Utf8NoBom -Path ([System.IO.Path]::GetFullPath($AccountingPath)) -Text (Build-AccountingMarkdown -Rows $rows -Years $years)

Write-Host "Markdown registre : $OutputMarkdownPath"
Write-Host "README CA         : $ReadmeCaPath"
Write-Host "Registre compta   : $AccountingPath"

$exportScript = Join-Path $PSScriptRoot "export_registre_compta.ps1"
$resolvedOutputMarkdownPath = [System.IO.Path]::GetFullPath($OutputMarkdownPath)

if ($SkipPdf) {
  if ($ChromePath -and $PandocPath) {
    & $exportScript -MarkdownPath $resolvedOutputMarkdownPath -Format $Format -Browser $Browser -SkipPdf -ChromePath $ChromePath -PandocPath $PandocPath
  } elseif ($ChromePath) {
    & $exportScript -MarkdownPath $resolvedOutputMarkdownPath -Format $Format -Browser $Browser -SkipPdf -ChromePath $ChromePath
  } elseif ($PandocPath) {
    & $exportScript -MarkdownPath $resolvedOutputMarkdownPath -Format $Format -Browser $Browser -SkipPdf -PandocPath $PandocPath
  } else {
    & $exportScript -MarkdownPath $resolvedOutputMarkdownPath -Format $Format -Browser $Browser -SkipPdf
  }
} else {
  if ($ChromePath -and $PandocPath) {
    & $exportScript -MarkdownPath $resolvedOutputMarkdownPath -Format $Format -Browser $Browser -ChromePath $ChromePath -PandocPath $PandocPath
  } elseif ($ChromePath) {
    & $exportScript -MarkdownPath $resolvedOutputMarkdownPath -Format $Format -Browser $Browser -ChromePath $ChromePath
  } elseif ($PandocPath) {
    & $exportScript -MarkdownPath $resolvedOutputMarkdownPath -Format $Format -Browser $Browser -PandocPath $PandocPath
  } else {
    & $exportScript -MarkdownPath $resolvedOutputMarkdownPath -Format $Format -Browser $Browser
  }
}
