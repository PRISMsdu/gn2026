<#
  Prepare des mails Outlook pour envoyer les roles joueurs deja exportes en PDF.

  Le script lit les fiches .md dans "2 - Roles des Joueurs", extrait :
    - E-mail joueur
    - Joueur
    - Nom du personnage
    - Groupe

  Il attache le PDF correspondant au role. Par defaut, le PDF est cherche dans le
  meme dossier que la fiche, avec le meme nom de base que le .md. Si plusieurs PDF
  correspondent, le plus recent est utilise.

  Exemples, depuis la racine du depot :
    .\Scripts\preparer_mails_roles.ps1 -RolePath "Groupes\Palyr\2 - Roles des Joueurs\Palyr_Thoran_Keld_Marchand.md"
    .\Scripts\preparer_mails_roles.ps1 -GroupPath "Groupes\Palyr" -Mode Draft
    .\Scripts\preparer_mails_roles.ps1 -RolesDirectory "Groupes\Palyr\2 - Roles des Joueurs" -Mode Display
    .\Scripts\preparer_mails_roles.ps1 -GroupPath "Groupes\Palyr" -DryRun

  Mode Draft   : cree les mails dans les brouillons Outlook.
  Mode Display : ouvre les mails Outlook.
  DryRun       : affiche les donnees sans lancer Outlook.
#>

[CmdletBinding(DefaultParameterSetName = 'ByRole')]
param(
  [Parameter(ParameterSetName = 'ByRole', Mandatory = $true, Position = 0)]
  [string] $RolePath,

  [Parameter(ParameterSetName = 'ByGroup', Mandatory = $true)]
  [string] $GroupPath,

  [Parameter(ParameterSetName = 'ByDirectory', Mandatory = $true)]
  [string] $RolesDirectory,

  [ValidateSet('Display', 'Draft')]
  [string] $Mode = 'Draft',

  [string] $PdfDirectory = '',

  [string] $SubjectTemplate = 'Votre role GN Krondaar 2026 - {Personnage}',

  [switch] $DryRun,

  [string] $BodyTemplate = @'
Bonjour {Joueur},

Tu trouveras ton role en piece jointe.

Bonne lecture,
Sebastien
'@
)

$ErrorActionPreference = 'Stop'

function Resolve-RepositoryRelativePath {
  param([string] $Path)

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if (-not (Test-Path -LiteralPath $fullPath)) {
    Write-Error "Chemin introuvable : $Path"
  }
  return (Resolve-Path -LiteralPath $fullPath).Path
}

function Resolve-RolesDirectoryFromGroup {
  param([string] $Path)

  $resolved = Resolve-RepositoryRelativePath -Path $Path
  $item = Get-Item -LiteralPath $resolved
  if (-not $item.PSIsContainer) {
    Write-Error "GroupPath doit etre un dossier : $Path"
  }

  if ($item.Name -eq '2 - Roles des Joueurs') {
    return $item.FullName
  }

  $rolesDir = Join-Path $item.FullName '2 - Roles des Joueurs'
  if (-not (Test-Path -LiteralPath $rolesDir)) {
    Write-Error "Dossier de roles introuvable : $rolesDir"
  }
  return (Resolve-Path -LiteralPath $rolesDir).Path
}

function Get-MarkdownTableValue {
  param(
    [string] $MarkdownRaw,
    [string] $Label
  )

  $escapedLabel = [regex]::Escape($Label)
  $pattern = "(?im)^\|\s*$escapedLabel\s*\|\s*(?<value>.*?)\s*\|"
  $match = [regex]::Match($MarkdownRaw, $pattern)
  if (-not $match.Success) {
    return ''
  }
  return $match.Groups['value'].Value.Trim()
}

function Resolve-RolePdf {
  param(
    [System.IO.FileInfo] $RoleFile,
    [string] $ExplicitPdfDirectory
  )

  $searchDir = $RoleFile.DirectoryName
  if (-not [string]::IsNullOrWhiteSpace($ExplicitPdfDirectory)) {
    $searchDir = Resolve-RepositoryRelativePath -Path $ExplicitPdfDirectory
  }

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($RoleFile.Name)
  $pdfs = Get-ChildItem -LiteralPath $searchDir -File -Filter "$baseName*.pdf" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending

  if ($pdfs.Count -gt 0) {
    return $pdfs[0].FullName
  }

  return ''
}

function Expand-MailTemplate {
  param(
    [string] $Template,
    [hashtable] $Values
  )

  $result = $Template
  foreach ($key in $Values.Keys) {
    $result = $result.Replace('{' + $key + '}', [string]$Values[$key])
  }
  return $result
}

function Get-RoleMailData {
  param([string] $MarkdownPath)

  $resolved = Resolve-RepositoryRelativePath -Path $MarkdownPath
  $roleFile = Get-Item -LiteralPath $resolved
  if ($roleFile.PSIsContainer -or $roleFile.Extension -ne '.md') {
    Write-Error "RolePath doit pointer vers une fiche .md : $MarkdownPath"
  }

  $raw = Get-Content -LiteralPath $roleFile.FullName -Raw -Encoding UTF8
  $characterName = Get-MarkdownTableValue -MarkdownRaw $raw -Label 'Nom du personnage'
  $playerName = Get-MarkdownTableValue -MarkdownRaw $raw -Label 'Joueur'
  $playerEmail = Get-MarkdownTableValue -MarkdownRaw $raw -Label 'E-mail joueur'
  $groupName = Get-MarkdownTableValue -MarkdownRaw $raw -Label 'Groupe'
  $pdfPath = Resolve-RolePdf -RoleFile $roleFile -ExplicitPdfDirectory $PdfDirectory

  if ([string]::IsNullOrWhiteSpace($characterName)) {
    $characterName = [System.IO.Path]::GetFileNameWithoutExtension($roleFile.Name)
  }

  [pscustomobject]@{
    RolePath = $roleFile.FullName
    PdfPath = $pdfPath
    CharacterName = $characterName
    PlayerName = $playerName
    PlayerEmail = $playerEmail
    GroupName = $groupName
  }
}

function Get-RoleMarkdownFiles {
  param([string] $DirectoryPath)

  Get-ChildItem -LiteralPath $DirectoryPath -File -Filter '*.md' |
    Where-Object { $_.Name -ne 'README.md' -and -not $_.Name.StartsWith('_') } |
    Sort-Object Name |
    Select-Object -ExpandProperty FullName
}

function New-OutlookRoleMail {
  param(
    [object] $Outlook,
    [object] $RoleData
  )

  if ([string]::IsNullOrWhiteSpace($RoleData.PdfPath)) {
    Write-Warning "PDF introuvable pour $($RoleData.RolePath). Mail non cree."
    return
  }

  $values = @{
    Personnage = $RoleData.CharacterName
    Joueur = $RoleData.PlayerName
    Groupe = $RoleData.GroupName
  }

  $mail = $Outlook.CreateItem(0)
  $mail.To = $RoleData.PlayerEmail
  $mail.Subject = Expand-MailTemplate -Template $SubjectTemplate -Values $values
  $mail.Body = Expand-MailTemplate -Template $BodyTemplate -Values $values
  [void] $mail.Attachments.Add($RoleData.PdfPath)

  if ($Mode -eq 'Draft') {
    $mail.Save()
    Write-Host "Brouillon cree : $($RoleData.CharacterName) <$($RoleData.PlayerEmail)>"
  }
  else {
    $mail.Display($false)
    Write-Host "Mail ouvert : $($RoleData.CharacterName) <$($RoleData.PlayerEmail)>"
  }
}

$rolePaths = @()

switch ($PSCmdlet.ParameterSetName) {
  'ByRole' {
    $rolePaths = @(Resolve-RepositoryRelativePath -Path $RolePath)
  }
  'ByGroup' {
    $rolesDir = Resolve-RolesDirectoryFromGroup -Path $GroupPath
    $rolePaths = @(Get-RoleMarkdownFiles -DirectoryPath $rolesDir)
  }
  'ByDirectory' {
    $rolesDir = Resolve-RepositoryRelativePath -Path $RolesDirectory
    $rolePaths = @(Get-RoleMarkdownFiles -DirectoryPath $rolesDir)
  }
}

if ($rolePaths.Count -eq 0) {
  Write-Error 'Aucune fiche role trouvee.'
}

$roleMails = foreach ($path in $rolePaths) {
  Get-RoleMailData -MarkdownPath $path
}

if ($DryRun) {
  $roleMails |
    Select-Object CharacterName, PlayerName, PlayerEmail, PdfPath, RolePath |
    Format-Table -AutoSize
  return
}

$outlook = New-Object -ComObject Outlook.Application

foreach ($roleMail in $roleMails) {
  New-OutlookRoleMail -Outlook $outlook -RoleData $roleMail
}

