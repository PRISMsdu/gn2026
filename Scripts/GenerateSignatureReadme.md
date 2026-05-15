# Génération de signatures vectorielles (`generate_signature_ink.ps1`)

Ce script écrit une signature vectorielle sous forme SVG, puis sous forme PNG si un convertisseur (ImageMagick ou Inkscape) est disponible.

**Fond** : le fichier **SVG** contient toujours un rectangle blanc (`id="sig-view-bg"`) pour prévisualiser le tracé. Le **PNG** est piloté par **`-PngBackground`** : **`Transparent`** (défaut) retire ce rectangle avant la conversion et produit une image à fond transparent ; **`White`** rasterise avec fond blanc opaque (bloc conservé ou équivalent selon l’outil).

**PenNib** : police blackletter rendue glyphe par glyphe. La première lettre de chaque mot (espaces comme séparateurs) et au début de chaque segment après trait d’union dans un mot composé utilise une taille d’em environ 1,3 fois celle du reste (~+30 %). Les autres lettres d’une même portion sont davantage resserrées et reliées par de petites formes fermées (« ponts » encré) sous le pied de ligne entre glyphes. Les lettres porteuses de jambes en minuscules (par ex. parmi g, j, p, q, y, f, …) peuvent prendre une translation verticale pseudo-aléatoire mais déterministe à partir du hash du nom pour varier les hauteurs sans casser les positions inter-mots.

Pour une même valeur de `-Seed`, la sortie est stable.

## Prérequis

- **Windows** avec **PowerShell** (exécution de scripts autorisée le cas échéant, par exemple `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`).

- **Pour le PNG** (optionnel) : l’un des outils suivant accessible en ligne de commande :

  - **ImageMagick** 7+ : commande `magick` (recherche dans le `PATH` ou emplacements courants sous `Program Files`).

  - **Inkscape** : exécutable `inkscape` (souvent `C:\Program Files\Inkscape\bin\inkscape.exe`).

  Si aucun n’est installé, utilisez **`-SkipPng`** pour ne générer que le **SVG** (ou installez un des convertisseurs ci-dessus).

- **Aucun accès Internet** n’est requis pour l’exécution du script lui-même.

## Emplacement

Fichier : `Scripts\generate_signature_ink.ps1` (à lancer depuis la racine du dépôt ou en indiquant le chemin complet du script).

## Lancement typique

```powershell
cd "C:\…\PERSO\GN\2026\Scripts"

.\generate_signature_ink.ps1 -Seed "Prénom Nom" -OutputPng ".\ma_signature.png"
```

Le **premier argument positionnel** est le `Seed` :

```powershell
.\generate_signature_ink.ps1 "Aelindra Vorn" -OutputPng ".\sig.png"
```

## Paramètres

| Paramètre | Rôle | Défaut / remarque |
|-----------|------|-------------------|
| `Seed` | Nom du signataire (**un ou plusieurs mots** ; espaces ; tirets pour les noms composés). Sans cité ni suffixe : la forme ne dépend que du nom. | `Exemple Nom` |
| `Energy` | **Calm** = tracé plus serré (moins de segments, moins d’amplitude) ; **Balanced** ; **Wild** = plus de segments, plus d’amplitude. | `Balanced` |
| `Flourish` | **None** = pas de boucle finale ; **Short** / **Long** = queue d’encre plus ou moins longue. | `Short` |
| `Weight` | **Fine** / **Medium** / **Bold** = épaisseur du trait (et du halo associé). | `Medium` |
| `Density` | **Airy** = plus étalé sur l’horizontale ; **Normal** ; **Tight** = plus resserré. | `Normal` |
| `Ink` | Couleur du trait principal, format **`#RRGGBB`**. | `#1f1210` |
| `InkHalo` | Couleur de la sous-couche (halo). **Vide** = couleur **dérivée** automatiquement à partir de `Ink`. | vide |
| `HaloOpacity` | Opacité du halo, entre **0** et **1**. Le script peut augmenter légèrement l’opacité minimale selon le `Weight`. | `0.22` |
| `SlantDegrees` | Inclinaison du groupe de tracés, entre **-18** et **18** degrés. | `0` |
| `OutputSvg` | Chemin du fichier SVG de sortie. Si omis : **`Scripts/Signatures`** + nom dérivé du `Seed` (`*_ink.svg`). Le dossier est créé au besoin (à côté du script `.ps1`). | vide |
| `OutputPng` | Chemin du PNG. Si omis avec génération PNG, **même dossier que le SVG** (par défaut `Scripts/Signatures`) et même nom de base, extension `.png`. | vide |
| `PngHeightPx` | **Hauteur** du PNG en pixels ; la largeur suit le ratio du viewBox **200×48** (comportement par défaut pour un rendu lisible à l’impression). | `280` |
| `PngWidthPx` | Si **> 0** : ancien comportement retranché **par largeur** (ignore alors `PngHeightPx`). | `0` (désactivé) |
| `MagickPath` | Chemin explicite vers `magick.exe` si non dans le `PATH`. | vide |
| `InkscapePath` | Chemin explicite vers `inkscape.exe` si non dans le `PATH`. | vide |
| `SkipPng` | Ne génère **que** le SVG, pas le PNG. | — |
| `PassThru` | Renvoie un **objet** (chemins, graine, options) en fin d’exécution. | — |
| `PngBackground` | **`Transparent`** = suppression de `sig-view-bg` avant conversion, PNG à fond transparent ; **`White`** = PNG à fond blanc. | **`Transparent`** |
| `FontCandidates` | Familles tentées dans l’ordre (gothiques en tête : **`Old English Text MT`**, etc.). Liste PowerShell surchargeable depuis la ligne de commande. | (voir défaut dans le script) |

## Comportement

- **Déterminisme** : le tracé dérive d’un hachage du **nom** (`Seed` après normalisation). Changer **uniquement** `Ink` ou `SlantDegrees` ne change pas la forme des courbes, seulement l’apparence (couleur, rotation légère du groupe).

- **PenNib / gothique** : raster **Regular** puis **Bold** pour chaque police candidate ; axe médian avec **nombre de colonnes proportionnel au nom** (densité bien supérieure à ≈ 10 segments par lettre en pratique) ; emphase géométrique forte sur les **majuscules** ; léger tremor pour le grain d’encre ; pas de trait traversant automatique. Entre **glyphes consécutifs du même mot** (sans espace), le resserrement horizontal est **× 1,20** par rapport à l’ancienne formule : les lettres se touchent davantage ; les **espaces entre mots** ne sont pas raccourcis de la même façon.

- **Procedural** : la progression horizontale du faux-tracé utilise une plage utile **réduite de 20 %** (centrée), pour un ruban **plus dense**, aligné sur la même idée de rapprochement.

- **ViewBox** : le document SVG fait **200×48** unités. Par défaut, le raster fixe **la hauteur** (`PngHeightPx`) ; avec l’ancien mode largeur uniquement : largeur du PNG = `PngWidthPx`, hauteur = `PngWidthPx × 48 / 200`.

- **Rendu PNG** : **ImageMagick** est essayé en premier ; sinon **Inkscape**. Fond du PNG selon **`-PngBackground`** (voir ci-dessus).

## Exemples

Signature plus expressive, encre violette, image large :

```powershell
.\generate_signature_ink.ps1 -Seed "Test" -Ink "#2a1540" -Energy Wild -Weight Bold -Density Tight `
  -OutputSvg ".\sig.svg" -OutputPng ".\sig.png" -PngHeightPx 320
```

SVG seul (pas d’outil de conversion installé) :

```powershell
.\generate_signature_ink.ps1 -Seed "Perso Dupont" -SkipPng -OutputSvg ".\signature_seule.svg"
```

Récupérer le résultat en objet PowerShell :

```powershell
$o = .\generate_signature_ink.ps1 -Seed "Prénom Nom" -PassThru -SkipPng
$o.SvgPath
```

## Dépannage

- **Erreur « Aucun outil de conversion SVG→PNG »** : installez **ImageMagick** ou **Inkscape**, ou bien passez **`-SkipPng`** et convertissez le SVG avec un autre outil.

- **Couleur refusée** : `Ink` et `InkHalo` doivent être au strict format **`#RRGGBB`** (six chiffres hexadécimaux après `#`).

- **Nom de fichier par défaut bizarre** : le nom sans `-OutputSvg` est dérivé des premiers caractères du `Seed` (caractères non sûrs retirés). Précisez **`-OutputSvg`** et **`-OutputPng`** pour maîtriser les chemins.

## Voir aussi

- Script d’export de la charte UBI qui intègre un bloc « encre » inline dans le HTML : `export_charte_UBI.ps1`.
