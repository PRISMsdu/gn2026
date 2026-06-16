# Methode - creer un contrat archive UBI

Ce dossier contient les contrats archives de l'UBI. La generation complete se fait en deux temps :

1. rediger un fichier `.md` conforme au format des archives ;
2. exporter ce `.md` en PDF avec le script d'archives.

Le script d'export ne genere pas le texte du contrat. Il met en page un fichier deja redige, ajoute les signatures manuscrites, les sceaux et le style visuel d'archive. Ne pas lancer l'export PDF sans demande explicite dans le prompt ou confirmation explicite de l'utilisateur.

## Source des informations

Utiliser d'abord `Groupes/Banquiers - UBI/3- Compta & registres/registre_UBI_Contrats_archives.md`.

La ligne du registre donne les informations de base :

- reference ;
- type ;
- parties ;
- objet ;
- montant ;
- droit de garde UBI paye ;
- date de depot ;
- date d'execution ;
- statut.

La reference du registre est aussi le nom du fichier, sans extension. Exemple :

```text
CO-II-542-003 -> CO-II-542-003.md
```

Pour un contrat commercial archive de classe II, la reference suit le format :

```text
CO-II-YYY-NNN
```

`YYY` est l'annee in-univers du depot. `NNN` est le rang global de l'acte dans cette annee, tel qu'il apparait dans le registre.

## Generation autonome d'un contrat archive

Quand la demande est de creer un nouveau contrat archive sans parametres imposes, definir d'abord les parametres de generation, puis rediger le fichier `.md`.

Procedure :

1. choisir deux cites au hasard parmi les cites utilisees dans les archives : `Il-Irion`, `Sfaal`, `Palyr`, `Ther-Felis`, `Arthas` ;
2. definir un sujet dans un domaine de trading, de fourniture, de transport, de protection, de service, d'exploitation ou d'exclusivite ;
3. varier fortement les sujets : marchandises, matieres premieres, armes, outils, produits agricoles, livres, objets de culte, pierres, bois, textiles, animaux, services de commis, escortes, manutention, expertise, travaux, entretien, etc. ;
4. lire quatre ou cinq contrats existants pris au hasard dans `Contrats_et_Livres/Archives` pour capter le ton, la structure, les clauses et les montants usuels ;
5. choisir une date de depot au hasard entre 397 et 471 ;
6. determiner la reference a partir de l'annee, du type et du niveau de criticite, en conservant le format `TT-R-YYY-NNN` ;
7. reprendre le niveau de criticite donne dans la demande initiale (`I`, `II`, `III` ou `IV`) ;
8. adapter le contenu a ce niveau de criticite ;
9. calculer le droit de garde UBI, egal a 2 % de la valeur du contrat ;
10. integrer dans le contrat que ce droit est paye a l'UBI avant enregistrement ;
11. inventer des noms de signataires coherents avec les cites ;
12. choisir un temoin bancaire UBI ;
13. rediger le fichier `.md` dans le format archive ;
14. ajouter ou verifier la ligne correspondante dans `Groupes/Banquiers - UBI/3- Compta & registres/registre_UBI_Contrats_archives.md` si le contrat doit faire partie du registre.

La criticite n'est pas choisie au hasard : elle est toujours fournie en parametre de lancement du prompt. Ce niveau influence ensuite le contenu et le montant :

- `I` : contrat courant, administratif, faible enjeu, clauses simples, montant inferieur a 3'000 couronnes.
- `II` : contrat sensible mais legal, enjeu commercial ou bancaire notable, clauses de controle plus presentes, montant inferieur a 5'000 couronnes.
- `III` : contrat hautement secret, montant jusqu'a 10'000 couronnes. Il releve souvent de prets importants, d'actions militaires, d'alliances industrielles, de produits rares ou d'ingredients magiques. Il peut aussi couvrir une dette cachee, un transport discret, un service compromettant ou un arrangement susceptible de creer un scandale.
- `IV` : contrat critique, secret industriel ou secret de defense, montant jusqu'a 20'000 couronnes. Ces actes ne doivent jamais sortir en public. Ils impliquent souvent des choses graves, en limite de legalite, ou des relations avec des pays opposes a la Confederation : Styrgie, Aquileas, voire l'empire tchelene.

Pour une archive ancienne, le texte doit rester factuel : ne pas expliquer l'intrigue au joueur, mais laisser le risque apparaitre par l'objet, les clauses, les montants, les personnes impliquees et la mention de classement.

## Droit de garde UBI

Chaque contrat enregistre a l'UBI paie un droit de garde a vie.

Regle :

- le droit de garde vaut 2 % de la valeur du contrat ;
- il garantit la garde jusqu'a archivage ou retrait ;
- il est payable a l'UBI avant enregistrement ;
- le contrat n'est enregistre que si ce droit est paye ;
- la somme est partagee entre les signataires ;
- la somme payee est indiquee dans le contrat sur une ligne en bas de page ;
- la somme payee est ajoutee dans le registre, sur la ligne du contrat.

Calcul :

```text
droit de garde UBI = montant du contrat x 0,02
part de chaque signataire = droit de garde UBI / nombre de signataires
```

Exemples :

```text
2'500 couronnes -> 50 couronnes
4'800 couronnes -> 96 couronnes
9'600 couronnes -> 192 couronnes
20'000 couronnes -> 400 couronnes
```

Dans le texte du contrat, faire apparaitre une ligne en bas de page, juste avant la derniere ligne de cloture du contrat (`Mention de classement`). Cette ligne porte le montant de garde paye et le calcul de la part de chaque signataire, par exemple :

```markdown
Droit de garde UBI : 192 couronnes, soit deux pour cent de la valeur du present contrat, versees avant enregistrement pour conservation jusqu'a archivage ou retrait ; part Ther-Felis : 96 couronnes ; part Palyr : 96 couronnes.
```

Dans le registre, ajouter une colonne `Droit UBI paye` pour chaque ligne.

Le registre officiel est organise par annee :

```markdown
## 438

| Reference | Type | Parties | Objet | Montant | Droit UBI paye | Date de depot | Date d'execution | Statut |
|-----------|------|---------|-------|---------|----------------|---------------|------------------|--------|
| CO-III-438-004 | Contrat commercial | Ther-Felis <-> Palyr | Fourniture confidentielle de sels de dormance, racines de mnesis sechees et fioles d'huile lunaire | 9'600 couronnes | 192 couronnes | 438-XII-18 | 439-II-06 | Execute, solde, classe |

Recapitulatif 438 : revenus UBI sur droits de garde : 192 couronnes.
```

Chaque annee a son propre tableau et son recapitulatif. Le recapitulatif annuel additionne uniquement les droits de garde UBI payes pour les contrats de cette annee de depot.

Le registre de revenus `Groupes\Banquiers - UBI\3- Compta & registres\registre_Comptable_UBI_Archives.md` doit aussi etre mis a jour a chaque creation de contrat. Il reprend, annee par annee, la reference du contrat, les dates, les signataires, le montant du contrat et le revenu UBI correspondant.

Les garanties CREDOC ne modifient pas ce contrat. Si un contrat archive est couvert par assurance ou lettre de credit, l'activation est inscrite dans `registre_Credoc_archives.md` selon `METHODE_credoc_archives.md`, sans avenant au fichier du contrat support.

## Generation d'un contrat de pret bancaire

Un contrat de pret bancaire peut etre genere en complement d'un contrat archive de niveau `III` ou `IV`.

Principe :

- seuls les contrats de niveau `III` ou `IV` peuvent servir de base ;
- l'emprunteur est en principe la partie qui produit, fabrique, transporte, protege ou execute la prestation avant d'etre payee ;
- le pret finance l'avance de production ou d'execution ;
- la somme empruntee vaut en principe 50 % de la valeur totale du contrat de base ;
- le pret entraine un cout bancaire de 4 % du montant emprunte ;
- ce cout de 4 % est payable a l'avance a l'UBI ;
- le capital emprunte est rembourse a la cloture du contrat de base ;
- les contrats de pret generes ici sont toujours consideres comme rembourses, car ils sont archives apres cloture.

Calcul :

```text
montant emprunte = montant du contrat de base x 0,50
cout bancaire UBI = montant emprunte x 0,04
```

Exemples :

```text
9'600 couronnes -> pret de 4'800 couronnes -> cout UBI 192 couronnes
17'150 couronnes -> pret de 8'575 couronnes -> cout UBI 343 couronnes
20'000 couronnes -> pret de 10'000 couronnes -> cout UBI 400 couronnes
```

Reference :

Utiliser le type `PB` pour `Pret bancaire`.

```text
PB-III-YYY-NNN
PB-IV-YYY-NNN
```

`YYY` est l'annee de depot du pret. `NNN` est le prochain rang libre de l'annee dans le registre standard, comme pour les autres actes. Le niveau du pret reprend le niveau du contrat finance (`III` ou `IV`).

Parties :

- l'UBI est toujours une partie du contrat ;
- l'autre partie est l'emprunteur ;
- la partie qui paie le contrat de base n'est pas signataire du pret, sauf si le texte l'impose explicitement ;
- le temoin bancaire peut etre distinct du signataire UBI.

Objet :

L'objet du pret doit nommer le contrat finance et la raison concrete de l'avance. Exemple :

```text
Pret bancaire pour avance de production liee au contrat CO-IV-520-005 : vente couverte de cristaux d'ecoute, sels de narcose et fioles de memoire.
```

Structure du texte :

- notice UBI en une phrase ;
- intitule `CONTRAT DE PRET BANCAIRE` ;
- reference exacte ;
- UBI representee par un signataire bancaire ;
- emprunteur represente par son signataire ;
- rappel de la reference du contrat finance ;
- montant emprunte, egal en principe a 50 % du contrat finance ;
- cout bancaire UBI de 4 %, paye a l'avance ;
- remboursement du capital a la cloture du contrat finance ;
- mention que le pret est archive parce que le remboursement a ete recu ;
- signatures de l'UBI, de l'emprunteur et du temoin bancaire ;
- mention de classement finale.

Ligne de cout bancaire :

Dans le contrat de pret, remplacer la ligne de droit de garde par une ligne de cout bancaire, juste avant la mention de classement :

```markdown
Cout bancaire UBI : 192 couronnes, soit quatre pour cent du montant emprunte, payees a l'avance avant decaissement du pret.
```

Registres :

Le contrat de pret est ajoute au registre standard `Groupes/Banquiers - UBI/3- Compta & registres/registre_UBI_Contrats_archives.md`.

Dans la colonne `Montant`, indiquer le montant emprunte, pas la valeur totale du contrat finance.

Dans la colonne `Droit UBI paye`, indiquer le cout bancaire UBI de 4 %. Ce montant participe aux revenus de la banque au meme titre que les droits de garde.

Le registre de revenus `Groupes\Banquiers - UBI\3- Compta & registres\registre_Comptable_UBI_Archives.md` doit aussi etre mis a jour. La ligne reprend :

- la reference du pret ;
- la date de depot ;
- la date de cloture ou de remboursement ;
- les signataires UBI et emprunteur ;
- le montant emprunte ;
- le revenu UBI, egal au cout bancaire de 4 %.

Statut :

Tous les prets archives generes par cette methode sont notes :

```text
Execute, rembourse, classe
```

Le texte de classement doit indiquer que le capital a ete rembourse a la cloture du contrat finance et que le cout bancaire avait ete paye avant decaissement.


## Format du fichier Markdown

Creer le fichier dans `Contrats_et_Livres/Archives`.

Structure attendue :

```markdown
# CO-II-542-003 -- contrat commercial archive de classe II

<div style="font-family: 'Segoe Script', 'Bradley Hand ITC', cursive; font-size: 9pt; font-style: italic; line-height: 1.18;">

Notice UBI : CO-II-542-003 ; contrat commercial legal de classe II ; depot 542-XII-01 ; Arthas <-> Il-Irion ; 10'250 couronnes ; execute, solde et classe.

CONTRAT COMMERCIAL  
N° CO-II-542-003

En l'an de grace cinq cent quarante-deux, le 1 du mois de Edrion, sous le regard des cieux et devant un comptoir reconnu de l'Union Bancaire d'Il-Irion, est conclu le present accord entre la cite d'Arthas, representee par Edran Thorne, et la cite d'Il-Irion, representee par Darian Quenndral.

Arthas s'engage envers Il-Irion pour l'objet suivant : fourniture de dalles de marbre veine, colonnettes et chaux fine. La partie representee par Edran Thorne livre les pierres de parement et les matieres de pose indiquees. La partie representee par Darian Quenndral recoit les biens pour les ateliers, ecuries, halles, chantiers ou maisons nommes dans le bordereau de depot.

Le prix total est fixe a 10'250 couronnes. Il-Irion verse 5'100 couronnes a la signature. Le solde de 5'150 couronnes est du apres controle par un commis d'Il-Irion et un clerc de l'UBI.

Tout defaut constate doit etre ecrit le jour meme dans le registre de reception. La partie fautive dispose de trente jours pour remplacer, reparer ou completer ce qui manque, sans nouveau paiement.

Les parties acceptent l'arbitrage UBI avant toute saisie d'un conseil de cite. Une fois les signatures portees au bas du registre, le contrat est classe parmi les actes executes de la banque.

Fait a Il-Irion, le 1 du mois de Edrion de l'an cinq cent quarante-deux.

Pour Arthas : Edran Thorne  
(*Signature*: Edran Thorne)

Pour Il-Irion : Darian Quenndral  
(*Signature*: Darian Quenndral)

Temoin bancaire : Jorven Hal, clerc de l'UBI  
(*Signature*: Jorven Hal)

Droit de garde UBI : 205 couronnes, soit deux pour cent de la valeur du present contrat, versees avant enregistrement pour conservation jusqu'a archivage ou retrait ; part Arthas : 102,5 couronnes ; part Il-Irion : 102,5 couronnes.

Mention de classement : execution recue le 6 du mois de Edrion 542. Solde verse le meme jour. Acte execute et clos.

</div>
```

Adapter les noms, dates, parties, objet, montant, lieu et temoin bancaire a partir du registre et des exemples existants.

## Conventions de redaction

Le style attendu est court, administratif et lisible. Le contrat archive n'est pas un grand contrat ceremonial : c'est une minute bancaire ancienne, deja executee et classee.

Inclure toujours :

- une notice UBI en une phrase ;
- l'intitule du contrat ;
- la reference exacte ;
- les parties et leurs representants ;
- l'objet du contrat ;
- le montant total ;
- le droit de garde UBI paye, calcule a 2 % du montant total, sur une ligne basse avant la mention de classement ;
- pour un pret bancaire, remplacer ce droit par le cout bancaire UBI de 4 % du montant emprunte ;
- la repartition du droit de garde entre les signataires figure sur cette meme ligne, sauf pour un pret bancaire ou le cout est paye par l'emprunteur ;
- un acompte et un solde coherents ;
- une clause de defaut ou de reception ;
- une clause de transport, controle ou arbitrage ;
- la date et le lieu de signature ;
- deux signatures de parties ;
- un temoin bancaire UBI ;
- une mention de classement finale.

Les marqueurs de signature doivent rester sous cette forme exacte :

```markdown
(*Signature*: Nom du signataire)
```

Le script les remplace automatiquement par des images de signatures. En mode archives, il ajoute aussi les sceaux des cites et le sceau UBI.

## Relecture des sauts de ligne

Apres generation d'un contrat archive, relire et normaliser le fichier Markdown avant de le considerer termine.

Regles obligatoires :

- une seule ligne vide entre deux paragraphes ;
- aucune ligne vide entre l'intitule du contrat et la ligne `N° ...` ;
- aucune ligne vide entre une ligne `Pour ...` ou `Temoin bancaire ...` et son marqueur `(*Signature*: Nom)` ;
- aucune sequence de trois sauts de ligne ou plus dans le fichier ;
- conserver une seule ligne vide avant `</div>` ;
- ecrire le fichier avec des fins de ligne stables, de preference `LF`, pour eviter les lignes vides doubles sous Windows.

Verification rapide a appliquer sur chaque lot genere :

```text
pas de \n\n\n
pas de "  \n\nN° "
pas de "  \n\n(*Signature*:"
```

## Export PDF

L'export PDF est optionnel. Ne le lancer que si le prompt le demande explicitement ou si l'utilisateur le confirme apres la creation du `.md`.

Depuis la racine du depot, lancer :

```powershell
.\Scripts\export_avis_archives.ps1 -MarkdownPath "Contrats_et_Livres\Archives\CO-II-542-003.md"
```

Remplacer le nom du fichier par la reference voulue.

Le PDF est cree dans le meme dossier que le `.md`, avec un nom horodate :

```text
CO-II-542-003_avis_yyyyMMdd_HHmmss.pdf
```

## Ce que fait le script

`Scripts/export_avis_archives.ps1` appelle `Scripts/export_avis.ps1` avec des options speciales :

- CSS force : `avis_archives_print.css` ;
- blason force : `Groupes\Banquiers - UBI\1 - Back de groupe\Blason_UBI.png` ;
- mode signatures et sceaux : `GN_AVIS_SIGNATURE_SEALS=archives` ;
- format par defaut : A4.

`export_avis.ps1` effectue ensuite :

1. lecture du Markdown ;
2. suppression des commentaires HTML ;
3. remplacement des marqueurs `(*Signature*: Nom)` par des signatures PNG ;
4. conversion Markdown vers HTML via Pandoc ;
5. ajout du blason, du style archive, du tampon "Acte execute et clos." et des sceaux ;
6. impression PDF headless via Chrome ou Edge ;
7. suppression du HTML temporaire si le PDF est cree.

## Prerequis

L'export PDF suppose que les outils suivants sont disponibles :

- Pandoc dans le `PATH`, ou fourni avec `-PandocPath` ;
- Chrome ou Edge installe, ou fourni avec `-ChromePath` ;
- les fichiers de sceaux dans `LivretsLocaux\Blasons` ;
- le blason UBI dans `Groupes\Banquiers - UBI\1 - Back de groupe`.

Si le PDF ne se cree pas, verifier d'abord Pandoc, puis Chrome/Edge, puis les chemins de blason et de sceaux.

## Verification rapide

Avant export :

- le nom du fichier correspond exactement a la reference ;
- la notice UBI reprend la ligne du registre ;
- le montant total est coherent avec l'acompte et le solde ;
- le droit UBI paye correspond a 2 % du montant total, ou a 4 % du montant emprunte pour un pret bancaire ;
- le registre contient la colonne `Droit UBI paye` et le recapitulatif annuel correspondant ;
- pour un pret bancaire, le registre de revenus reprend le cout bancaire de 4 % comme revenu UBI ;
- les dates sont au calendrier de Krondaar ;
- chaque signature utilise `(*Signature*: Nom)` ;
- le fichier se termine par `</div>`.

Apres export :

- le PDF est present dans `Contrats_et_Livres/Archives` ;
- le titre et la reference apparaissent correctement ;
- les signatures et sceaux sont visibles ;
- la mention de classement tient en bas de page.
