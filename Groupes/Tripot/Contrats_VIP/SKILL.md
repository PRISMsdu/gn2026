---
name: contrats-vip-tripot
description: Redige les dossiers clandestins DC-IV et leurs reglements FC-IV lies aux registres VIP Edorian. Utiliser quand il faut creer ou corriger les dossiers VIP depuis Registre_VIP_Edorian_542 a 547, dans Groupes/Tripot/Contrats_VIP.
disable-model-invocation: true
---

# Dossiers VIP Edorian

## Sources

Lire d'abord le registre annuel concerne dans `Groupes/Tripot/3 - Comptabilite`.

Chaque ligne utile donne un reglement :
- la reference `FC-IV-YYY-NNN` ;
- la date ;
- la description courte ;
- le code beneficiaire ;
- le montant ;
- le payeur visible.

Le dossier produit doit rattacher ces donnees a une affaire clandestine plus large sans expliquer la comptabilite du registre.

Si une ligne du registre porte `FC-III-YYY-NNN`, la reclasser en `FC-IV-YYY-NNN` avant de produire le contrat. Tous les contrats VIP Edorian sont des contrats de classe IV.

## Codes beneficiaires

- `II` : Il-Irion.
- `AR` : Arthas.
- `TR` ou `TF` : Ther-Felis.
- `SF` ou `FS` : Sfaal.
- `PA` : Palyr.

Le code reste dans le contrat comme identifiant de partie. Ne pas developper la mecanique de code.

## Principe de redaction

Le fichier principal est un dossier clandestin `DC-IV-YYY-NNN`. Il regroupe plusieurs reglements `FC-IV` issus des registres.

Chaque reglement `FC-IV` devient une ligne ou une clause dans un dossier. Ne pas creer un fichier autonome par reglement, sauf demande explicite.

Le dossier ne nomme pas le circuit comptable. Il ne decrit pas comment l'argent circule. Il ne mentionne pas le lieu ou la methode de paiement. Il doit se lire comme une piece autonome trouvee hors registre.

Le contenu doit etre illegal ou compromettant : enlevement de dignitaires, sequestration, torture, assassinat commande, relaxation de bandits, vente d'informations a l'etranger, livraison d'armes ou de personnes, mercenaires, Sangs de la Steppe, Redempteurs, Styrgie, Aquilea, Empire Tchelene, violation du Paraphe des treize lignes marchandes, faux pavillon, blocage de quai, disparition de temoin.

Chaque dossier mentionne un tiers payeur explicite : personne privee, etat ennemi, pirates, guilde ou maison privee. Ce tiers ne doit pas etre une autre cite confederee. La cite codee est la cite executante : elle est payee pour organiser, gerer et faire executer les actes du dossier. Si une autre cite confederee est impliquee, creer un dossier miroir ou une contre-partie separee.

## Interdits dans le texte du contrat

Ne jamais mentionner dans les dossiers :
- Tripot, casino, salon, table, des, cartes, perte designee ;
- caisse, marge, quittance, remise, sortie, blanchiment ;
- UBI, depot, registre bancaire, non-enregistrement ;
- mecanique de circulation de l'argent, lieu de paiement ou intermediaire financier ;
- commanditaire cache, beneficiaire reel, absence de signature, absence de copie ;
- commentaire orga expliquant pourquoi le document existe.

Le contrat doit montrer l'acte par ses obligations concretes, pas par son camouflage.

## Format dossier

Creer un fichier dans `Groupes/Tripot/Contrats_VIP` :

```markdown
# DC-IV-YYY-NNN -- dossier clandestin de classe IV

Document prive. Exemplaire unique.

<div style="font-family: 'Segoe Script', 'Bradley Hand ITC', cursive; font-size: 9pt; font-style: italic; line-height: 1.18;">

DOSSIER CLANDESTIN  
No DC-IV-YYY-NNN

Periode : [annees ou mois].  
Beneficiaire code : [code].  
Cite executante : [cite liee au code].  
Reglements rattaches : [liste FC-IV].  
Classement : IV.

[Objet du dossier : acte principal intolerable.]

[Faits couverts : otages, meurtre, torture, liberation, vente d'information, livraison.]

## Reglements rattaches

| Reference | Date | Acteur engage | Somme | Objet du reglement |
|-----------|------|---------------|-------|-------------------|
| FC-IV-YYY-NNN | date | acteur | montant | execution partielle |

## Engagements

Le tiers payeur est [personne privee, etat ennemi, pirates ou guilde]. Le porteur du code [code] agit pour [cite] comme executant paye : il organise, gere et fait executer [objet du dossier].
Les acteurs listes dans les reglements recoivent leurs ordres de [cite]. Ils livrent les faits attendus : [faits couverts].
Chaque reglement vaut ordre partiel : surveillance, contrainte, transport, fourniture ou violence confiee. Les personnes nommees peuvent etre deplacees, retenues, forcees a signer ou tuees selon le reglement applicable.
En cas de rupture, [cite] saisit une cargaison, livre un nom aux Sangs de la Steppe ou impose un service de remplacement avant la fin du mois suivant.
Le tiers payeur reconnait que ce dossier rattache [cite] a l'execution des reglements et aux faits couverts.

Pour le beneficiaire code : porteur du code [code]  
(*Signature*: code [code])

Mention finale : dossier clos apres execution des reglements rattaches.

</div>
```

## Verification

Avant de terminer :
- relire le dossier et supprimer toute explication de circuit comptable ;
- rechercher les mots interdits ;
- verifier que chaque reference FC-IV rattachee existe dans le registre ;
- verifier que les dossiers 546-547 incriminent bien toutes les cites ;
- garder un style factuel, court, sans effet d'auteur.
