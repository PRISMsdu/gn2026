# Methode - mouvements bancaires archives UBI

Ce fichier decrit la generation des mouvements bancaires classiques archives de l'UBI : depots d'argent et retraits.

Ces mouvements ne creent pas de contrat archive. Ils ne doivent donc pas produire de fichier `TT-R-YYY-NNN.md` dans `Contrats_et_Livres/Archives`.

Ils sont inscrits uniquement dans le registre comptable :

```text
Groupes\Banquiers - UBI\3 - Comptabilite\registre_Comptable_UBI_Archives.md
```

## Nature des mouvements

Deux types de mouvements sont utilises :

- `Depot` : une cite ou une famille depose de l'argent dans les coffres UBI ;
- `Retrait` : une cite ou une famille retire de l'argent deja depose.

Les depots generent un revenu bancaire.

Les retraits ne generent aucun revenu bancaire pour la famille. Ils sont inscrits pour tracer la sortie d'argent, mais la colonne de prime UBI reste a `0 couronne`.

## Clients

Les clients peuvent etre :

- une cite ;
- une grande famille d'une cite ;
- une maison marchande ou patricienne liee a une delegation.

Pour les familles, utiliser en priorite les noms deja presents dans les delegations et roles :

- Il-Irion : Valdris, Kaelthorne, Aedris, Halvaren, Dornelis, Thorne ;
- Palyr : Vandesse, Keld, Voss, Mire ;
- Arthas : Thorne, Orist, Calveran, Kharvek ;
- Ther-Felis : Halet, Seld, Tern, Ask ;
- Sfaal : Forgecendre, Morven, Vost, Kelveg.

Il est possible d'inventer d'autres noms de familles si le registre a besoin de volume, mais ils doivent rester sobres et coherents avec la cite.

## Volumes moyens

Pour une annee d'exemple :

- chaque famille fait en moyenne environ `10'000 couronnes` de depot total ;
- chaque famille fait en moyenne environ `8'000 couronnes` de retrait total ;
- ces montants peuvent etre divises en plusieurs operations ;
- chaque famille doit avoir au moins un depot et au moins un retrait si l'exemple demande une activite complete.

## Prime UBI sur depot

Chaque depot assure paie une prime bancaire UBI de 1 %.

Calcul :

```text
prime UBI = montant du depot x 0,01
```

Exemples :

```text
10'000 couronnes deposees -> 100 couronnes de prime UBI
6'200 couronnes deposees -> 62 couronnes de prime UBI
4'300 couronnes deposees -> 43 couronnes de prime UBI
```

Les retraits ne paient rien :

```text
8'000 couronnes retirees -> 0 couronne de revenu UBI
```

## Format dans le registre comptable

Dans `registre_Comptable_UBI_Archives.md`, ajouter les mouvements sous l'annee concernee, apres les revenus issus des contrats de cette annee.

Format conseille :

```markdown
Mouvements bancaires classiques 397 :

| Date | Type | Client | Cite | Montant | Prime UBI |
|------|------|--------|------|---------|-----------|
| 397-I-12 | Depot | Maison Valdris | Il-Irion | 6'200 couronnes | 62 couronnes |
| 397-II-04 | Retrait | Maison Valdris | Il-Irion | 3'200 couronnes | 0 couronne |

Total primes UBI sur mouvements bancaires 397 : 102 couronnes.
```

Le total annuel du registre comptable doit additionner :

- revenus des contrats archives ;
- droits de garde ;
- couts bancaires des prets ;
- primes UBI de 1 % sur depots ;
- aucun revenu sur retraits.

## Verification

Avant de terminer :

- chaque depot a une prime UBI egale a 1 % du montant ;
- chaque retrait a `0 couronne` de prime UBI ;
- chaque famille a au moins un depot et un retrait quand l'exemple le demande ;
- les totaux annuels incluent les primes de depot ;
- le recapitulatif general inclut les primes de depot ;
- aucun fichier de contrat n'est cree pour un simple depot ou retrait.

## Prets intercites longs termes

Un pret intercite est un pret de l'UBI a une cite entiere ou a une delegation officielle, sur une duree de 10 a 20 ans, a taux fixe. Il ne genere pas de contrat archive individuel de type `PB`. Il est enregistre dans le bloc descriptif en tete du registre comptable (tableau des prets intercites actifs) et dans chaque annee concernee sous la forme d'une ligne d'interets.

Reference : utiliser le type `PT-CC-YYY-NNN` (PT = Pret Territorial, CC = code Confederation).

Taux habituels : entre 6 % et 8 % selon la capacite financiere de la cite.

Format dans le registre comptable (une ligne par annee, tant que le pret est actif) :

```markdown
Interets pret intercite PT-CC-430-001 (Ther-Felix, 80'000 couronnes a 7.0 %) : 5'600 couronnes.
```

Le remboursement du capital n'est pas inscrit dans le registre comptable UBI (il est note dans un acte separe, hors archives).

Chaque pret intercite doit etre enregistre dans le tableau de tete :

```markdown
## Prets intercites longs termes

| Reference | Beneficiaire | Principal | Taux | Duree | Interets annuels |
|-----------|--------------|-----------|------|-------|-----------------|
| PT-CC-430-001 | Ther-Felix | 80'000 couronnes | 7.0 % | 430-445 | 5'600 couronnes/an |
```

## Location de coffres

L'UBI loue des coffres-forts individuels a des familles, des marchands ou des delegations. La location est un forfait annuel par coffre, sans contrat archive individuel.

Tarif : 12 couronnes par coffre et par an, location et assurance de base comprises.

Le nombre de coffres croît avec le volume d'activite : environ 50 coffres a l'an 397, pour atteindre 220 coffres vers l'an 540.

Format dans le registre comptable (une ligne par annee) :

```markdown
Location et assurance coffres (89 coffres a 12 couronnes/an) : 1'068 couronnes.
```

Aucun fichier de contrat n'est cree pour une location de coffre. Le tarif peut etre ajuste en cas d'evenement majeur (crise, siege, incendie).

## Redevances des contrats-cadres CREDOC

Les cinq cites fondatrices de l'UBI (Il-Irion, Palyr, Arthas, Ther-Felis, Sfaal) ne versent plus une cotisation de fonctionnement massive. Chaque cite paie une redevance annuelle de contrat-cadre CREDOC.

Redevance actuelle : 500 couronnes par cite, soit 2'500 couronnes par an.

Format dans le registre comptable (une ligne par annee) :

```markdown
Redevances contrats-cadres CREDOC (5 cites x 500 couronnes) : 2'500 couronnes.
```

Cette redevance maintient l'acces a l'arbitrage documentaire, aux lettres de credit garanties et aux appels de garantie. Elle ne couvre pas a elle seule les charges de l'UBI : les revenus principaux viennent des primes CREDOC, des depots assures, des coffres assures et des prets.


## Garanties CREDOC et assurances documentaires

Les garanties CREDOC sont inscrites dans `registre_Credoc_archives.md`. Elles s'appuient sur les contrats-cadres `AC-UBI-397-CITE` et ne creent pas d'avenant aux contrats supports.

Format dans le registre comptable (une ligne par annee) :

```markdown
Primes CREDOC garanties documentaires 430 : 15'322 couronnes.
```

Le detail des inscriptions reste dans le registre CREDOC. Le registre comptable ne reprend que le total annuel de primes acquises par l'UBI.

## Lettres de change (mention pour usage futur)

Une lettre de change est un acte par lequel un tireur ordonne a un tire de payer une somme a un beneficiaire a une echeance donnee. L'UBI peut servir d'intermediaire de garantie.

Si ce type d'acte est active, il genere un droit UBI de 0,5 % du montant, inscrit dans le registre comptable sous la forme :

```markdown
Lettre de change LC-XX-YYY-NNN (X tire sur Y pour Z couronnes) : W couronnes de droit UBI.
```

Aucun contrat archive individuel n'est cree pour une lettre de change simple. Un contrat de type `LC` peut etre genere si la lettre est contestee ou complexe.
