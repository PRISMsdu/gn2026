# Methode - garanties CREDOC et assurances UBI

Ce fichier decrit la couche CREDOC de l'UBI. Elle permet d'assurer des contrats, lettres de credit, connaissements et bordereaux sans modifier les contrats archives existants.

## Principe juridique

Le contrat archive etablit l'obligation entre les parties. Le registre CREDOC etablit la garantie UBI. L'un ne modifie pas l'autre.

Chaque cite fondatrice signe un contrat-cadre `AC-UBI-397-CITE`. Ce contrat-cadre autorise l'UBI a garantir des actes deja deposes, des lettres de credit, des connaissements, des bordereaux de paiement ou des lots documentaires. L'activation de garantie se fait ensuite par une ligne dans `registre_Credoc_archives.md`.

Aucun avenant n'est ajoute aux contrats anciens. Aucun fichier de contrat commercial existant n'est modifie.

## Contrats-cadres

Les cinq contrats-cadres actifs sont :

| Reference | Cite couverte | Role |
|-----------|---------------|------|
| AC-UBI-397-ILIRION | Il-Irion | Garantie documentaire des maisons et ateliers d'Il-Irion |
| AC-UBI-397-PALYR | Palyr | Garantie transport, fret et lettres de credit portuaires |
| AC-UBI-397-ARTHAS | Arthas | Garantie d'execution et arbitrage sur fournitures sensibles |
| AC-UBI-397-THERFELIS | Ther-Felis | Garantie documentaire des services, greniers et registres |
| AC-UBI-397-SFAAL | Sfaal | Garantie transport renforcee et fret industriel |

Ces contrats-cadres sont conserves dans `Contrats_et_Livres/Archives`, mais leurs activations ne passent pas par `Groupes/Banquiers - UBI/3- Compta & registres/registre_UBI_Contrats_archives.md`. Elles passent par le registre CREDOC.

## Niveaux de garantie

| Niveau | Usage | Prime UBI |
|--------|-------|-----------|
| Enregistrement garanti simple | Defaut de paiement reconnu sur acte depose | 1,0 % a 2,0 % |
| Garantie d'execution documentaire | Paiement, livraison ou prestation non recue | 2,5 % a 3,0 % |
| Garantie transport et credit documentaire | Fret, lettre de credit, connaissement, paiement differe | 3,0 % a 3,5 % |
| Garantie renforcee | Route dangereuse, saisie abusive, convoi arme, litige sensible | 4,0 % a 5,0 % |

Les primes inscrites dans le registre CREDOC sont acquises a l'UBI au moment de l'enregistrement. Si la garantie est appelee, l'UBI indemnise dans la limite du montant garanti, puis poursuit la partie fautive ou recouvre sur les depots et suretes deja tenus.

## Format du registre CREDOC

Une ligne CREDOC ne remplace pas le contrat support. Elle resume le lot documentaire couvert par le contrat-cadre de la cite.

```markdown
| Reference CREDOC | Date | Cite couverte | Contrat-cadre | Couverture | Supports declares | Assiette garantie | Taux | Prime UBI | Statut |
|------------------|------|---------------|---------------|------------|-------------------|------------------|------|-----------|--------|
| CD-430-PAL-002 | 430-IX-06 | Palyr | AC-UBI-397-PALYR | garantie transport et credit documentaire | connaissements portuaires, contrats de fret, lettres de credit maritimes | 92'800 couronnes | 3.5 % | 3'248 couronnes | Garanti, non appele |
```

## Comptabilisation

Le registre comptable UBI reprend chaque annee une seule ligne de total :

```markdown
Primes CREDOC garanties documentaires 430 : 15'322 couronnes.
```

Le total annuel du registre comptable additionne :

- droits de garde des contrats archives et couts bancaires des prets PB ;
- primes de depots assures ;
- interets des prets intercites ;
- location et assurance des coffres ;
- redevances annuelles des contrats-cadres CREDOC ;
- primes CREDOC de l'annee.

## Redevance annuelle des cites

La cotisation fixe de fonctionnement est remplacee par une redevance de contrat-cadre. Chaque cite paie 500 couronnes par an pour maintenir son acces au cadre CREDOC, a l'arbitrage documentaire et aux procedures d'appel de garantie.

Cette redevance n'est pas la principale ressource de l'UBI. Elle paie l'acces au systeme. Les revenus importants viennent des primes CREDOC, des depots assures, des coffres assures et des prets.

## Verification

Avant de modifier le registre comptable :

- verifier que chaque annee a un total CREDOC dans `registre_Credoc_archives.md` ;
- verifier que les primes correspondent au taux applique a l'assiette garantie ;
- ne pas modifier les contrats supports existants ;
- ne pas ajouter d'avenants aux contrats anciens ;
- garder les contrats-cadres separes du registre standard des contrats executes.
