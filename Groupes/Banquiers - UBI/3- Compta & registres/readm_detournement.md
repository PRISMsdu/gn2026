# Methode de detournement - comptes courants UBI

Ce fichier decrit la methode utilisee par Edorian Kaelthorne pour diminuer les revenus declares de l'UBI sans diminuer les sommes demandees aux acteurs.

## Principe

Les contrats courants et le registre CREDOC courant restent les traces opposables aux clients. Ils gardent les droits de garde, les taux et les primes demandes aux maisons, cites et delegations.

Le registre comptable officiel applique une baisse progressive des taux. Cette baisse est presentee comme une decision de direction pour calmer les cites et montrer que l'UBI reduit ses frais. Les clients paient pourtant les montants inscrits dans les contrats et les CREDOC.

La difference entre les sommes demandees et les sommes declarees est sortie de la comptabilite officielle. Elle est suivie dans `registre_Comptable_UBI_détournement.md`.

## Coefficients declares

| Exercice | Coefficient officiel |
|----------|----------------------|
| 542 depuis Equos | x1,0 |
| 543 | x0,9 |
| 544 | x0,8 |
| 545 | x0,7 |
| 546 | x0,6 |
| 547 | x0,5 |

## Application

Les droits de garde des contrats courants sont declares avec le coefficient de l'exercice. Les lignes sans montant ou sans droit UBI restent `Non renseigné`.

Les primes CREDOC sont declarees avec le coefficient de l'exercice. Le registre CREDOC courant conserve les taux demandes aux acteurs. Le registre comptable courant inscrit seulement les revenus declares.

## Lecture des ecarts

Pour chaque exercice :

1. Relever les droits et primes demandes dans les contrats courants et le registre CREDOC courant.
2. Relever les droits et primes declares dans `registre_Comptable_UBI_courant.md`.
3. Inscrire la difference dans `registre_Comptable_UBI_détournement.md`.

Les depots classiques, les coffres et les redevances de contrats-cadres ne sont pas modifies par cette methode.
