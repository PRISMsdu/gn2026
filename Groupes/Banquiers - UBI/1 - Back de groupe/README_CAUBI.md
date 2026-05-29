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