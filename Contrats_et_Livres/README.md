# Guide d'utilisation des Templates de Contrats

Ce répertoire contient des templates de contrats pour créer des documents officiels dans le cadre de la Confédération. Ces templates suivent un style médiéval mais accessible, et utilisent un format standardisé pour garantir la cohérence des documents.

## 📋 Templates disponibles

| Template | Type de contrat | Fichier |
|----------|----------------|---------|
| **CONTRACT** | Contrat commercial | `_template_CONTRACT.md` |
| **DEBT** | Contrat de dette/prêt | `_template_DEBT.md` |
| **ALLIANCE** | Contrat d'alliance militaire/diplomatique | `_template_ALLIANCE.md` |
| **SERVICE** | Contrat de service (mercenaires, artisans) | `_template_SERVICE.md` |
| **EXPLOITATION** | Contrat d'exploitation de ressources | `_template_EXPLOITATION.md` |
| **EXCLUSIVITY** | Contrat d'exclusivité commerciale | `_template_EXCLUSIVITY.md` |
| **PROTECTION** | Contrat de protection/escorte | `_template_PROTECTION.md` |
| **MARRIAGE** | Pacte matrimonial/alliance par mariage | `_template_MARRIAGE.md` |

## 🚀 Comment utiliser un template

### Étape 1 : Choisir le template approprié

Sélectionnez le template correspondant au type de contrat que vous souhaitez créer. Par exemple :
- Pour un échange commercial : `_template_CONTRACT.md`
- Pour un prêt entre cités : `_template_DEBT.md`
- Pour une alliance militaire : `_template_ALLIANCE.md`

### Étape 2 : Copier le template

Créez une copie du template avec un nouveau nom suivant la convention :
```
[TYPE]-[N°].md
```

Exemples :
- `CONTRACT-001.md` (premier contrat commercial)
- `DEBT-002.md` (deuxième contrat de dette)
- `ALLIANCE-001.md` (première alliance)

### Étape 3 : Remplacer les variables

Toutes les variables dans les templates sont indiquées entre crochets `[variable]`. Remplacez-les par les valeurs appropriées :

**Variables communes :**
- `[N°]` : Numéro du contrat (ex: `001`, `002`)
- `[mil-quatre-cent-vingt-cinq]` : Année en toutes lettres (ex: `mil-cinq-cent-vingt`)
- `[partie1]`, `[partie2]` : Noms des cités ou parties
- `[nom1]`, `[nom2]` : Noms des représentants
- `[DATE]` : Date complète (ex: `le 15 du mois de Ventôse de l'an 1520`)
- `[LIEU]` : Lieu de signature (ex: `la Citadelle d'Ulgarth`)

**Variables spécifiques :**
Chaque template contient des variables spécifiques à son type. Consultez le template pour voir toutes les variables à remplir.

### Étape 4 : Adapter le contenu

Certaines sections peuvent nécessiter des ajustements selon le contexte :
- Ajoutez ou supprimez des éléments de liste si nécessaire
- Adaptez les modalités selon les besoins spécifiques
- Personnalisez les descriptions pour refléter la réalité du contrat

### Étape 5 : Vérifier et finaliser

- Vérifiez que toutes les variables ont été remplacées
- Assurez-vous que les dates et montants sont cohérents
- Vérifiez l'orthographe des noms et des lieux
- Ajoutez les témoins si nécessaire

## 📝 Exemple d'utilisation

### Exemple : Créer un contrat commercial

1. **Copier le template :**
   ```
   Copier _template_CONTRACT.md → CONTRACT-002.md
   ```

2. **Remplacer les variables :**
   - `[N°]` → `002`
   - `[mil-quatre-cent-vingt-cinq]` → `mil-cinq-cent-vingt-trois`
   - `[partie1]` → `Sfaal`
   - `[nom1]` → `Duc Thoren Forgefer`
   - `[partie2]` → `Il-Irion`
   - `[nom2]` → `Seigneur Aldric Ventoss`
   - `[description de l'accord]` → `Sfaal s'engage à fournir à Il-Irion vingt tonnes de minerai de fer`
   - `[marchandise]` → `minerai de fer`
   - `[somme]` → `soixante pièces d'or`
   - `[DATE]` → `le 10 du mois de Germinal de l'an 1523`
   - `[LIEU]` → `la Citadelle d'Ulgarth`

3. **Compléter les sections :**
   - Décrire la marchandise en détail
   - Préciser les modalités de livraison
   - Ajouter les témoins si nécessaire

## 🤖 Utiliser l'IA pour créer un contrat

Vous pouvez demander à l'IA de créer un contrat directement en utilisant un prompt. Voici comment formuler votre demande :

### Format de base du prompt

```
Crée-moi un contrat de [TYPE] entre [partie1] et [partie2] avec les détails suivants :
- [détails spécifiques]
- [autres informations]
```

### Exemples de prompts

#### Exemple 1 : Contrat de protection
```
Crée-moi un contrat de protection entre Palyr et Il-Irion. 
Palyr (représentée par le Légat Kaelen Forgefer) engage Il-Irion 
(représentée par le Seigneur Aldric Ventoss) pour protéger ses 
chantiers navals pendant 6 mois. Il-Irion fournira 10 gardes 
équipés d'armes et d'armures. Le paiement sera de 500 pièces d'or, 
versé en deux fois : la moitié au début, l'autre moitié à la fin. 
Date : le 20 du mois de Germinal de l'an 1522, à la Citadelle d'Ulgarth.
```

#### Exemple 2 : Contrat commercial
```
Crée-moi un contrat commercial entre Sfaal et Palyr. 
Sfaal (Duc Thoren Forgefer) vend à Palyr (Seigneur Aldric Ventoss) 
15 tonnes d'acier de qualité supérieure pour 75 pièces d'or. 
Livraison dans 3 mois par voie terrestre avec escorte. 
Date : le 15 du mois de Ventôse de l'an 1520.
```

#### Exemple 3 : Contrat d'alliance
```
Crée-moi un contrat d'alliance militaire entre Il-Irion et Palyr 
pour une durée de 5 ans. Les deux cités s'engagent à se défendre 
mutuellement en cas d'agression, à partager les informations 
militaires importantes, et à ne pas conclure d'alliance avec 
les ennemis de l'autre sans consultation. Représentants : 
Seigneur Aldric Ventoss pour Il-Irion, Légat Kaelen Forgefer pour Palyr.
```

#### Exemple 4 : Contrat de service
```
Crée-moi un contrat de service. Palyr engage un groupe de 
mercenaires d'Il-Irion (représentés par le Capitaine Marcus) 
pour escorter une caravane commerciale vers Sfaal. 
Service de 2 semaines, rémunération de 200 pièces d'or, 
paiement à la fin de la mission.
```

#### Exemple 5 : Contrat d'exploitation
```
Crée-moi un contrat d'exploitation. Il-Irion accorde à Palyr 
le droit d'exploiter une mine de fer sur son territoire pour 
3 ans. Palyr paiera 20% des bénéfices à Il-Irion et s'engage 
à maintenir une garde de 5 hommes sur le site.
```

### Informations à inclure dans votre prompt

Pour obtenir un contrat complet, essayez d'inclure :

- **Type de contrat** : CONTRACT, DEBT, ALLIANCE, SERVICE, etc.
- **Parties** : Noms des cités/familles et leurs représentants
- **Dates** : Date de signature et dates importantes (échéances, début, fin)
- **Montants** : Sommes d'argent, redevances, rémunérations
- **Durée** : Période de validité du contrat
- **Détails spécifiques** : Marchandises, services, obligations particulières
- **Lieu** : Lieu de signature (généralement la Citadelle d'Ulgarth)
- **Témoins** : Si vous souhaitez des témoins spécifiques

### Prompt minimal

Si vous manquez d'informations, vous pouvez faire un prompt minimal :
```
Crée-moi un contrat de protection entre Palyr et Il-Irion 
en utilisant le template PROTECTION. Utilise des valeurs 
cohérentes avec l'univers et les autres contrats existants.
```

L'IA pourra alors créer un contrat en s'inspirant des exemples existants (`CONTRACT-001.md`, `DEBT-001.md`) pour maintenir la cohérence.

## 🎨 Style et conventions

### Langage
- **Style médiéval mais accessible** : Utilisez un langage formel mais compréhensible
- **Formules solennelles** : Commencez par "En l'an de grâce..." et terminez par "Fait et scellé ce jour..."
- **Formulations traditionnelles** : Utilisez "sous le regard des cieux et la bénédiction des anciens"

### Structure
- **En-tête** : Type de contrat et numéro
- **Introduction** : Date, parties et représentants
- **Sections** : Chaque section commence par "De la/du/des..."
- **Clause finale** : "De la Loi et de l'Honneur" (standardisée)
- **Signatures** : Format tabulaire avec noms, fonctions et signatures
- **Témoins** : Liste des témoins (optionnel)

### Numérotation
- Les numéros de contrats sont séquentiels par type
- Format : `[TYPE]-[N°]` avec `[N°]` sur 3 chiffres (ex: `001`, `002`, `010`)

## 📚 Références

Pour voir des exemples de contrats remplis, consultez :
- `CONTRACT-001.md` : Exemple de contrat commercial
- `DEBT-001.md` : Exemple de contrat de dette

## ⚠️ Notes importantes

1. **Ne modifiez jamais les templates** : Les fichiers `_template_*.md` doivent rester intacts pour servir de modèles
2. **Conservez la structure** : Respectez la structure des sections pour maintenir la cohérence
3. **Variables obligatoires** : Certaines variables sont essentielles (dates, noms, montants) - ne les oubliez pas
4. **Clause standardisée** : La section "De la Loi et de l'Honneur" doit rester identique dans tous les contrats
5. **Enregistrement** : Après création, enregistrez le contrat dans le `Registre_UBI.md` (voir section ci-dessous)

## 📝 Enregistrement dans le Registre UBI

Après avoir créé un contrat, il est **obligatoire** de l'enregistrer dans le `Registre_UBI.md` pour qu'il soit officiellement reconnu et archivé par l'Union Bancaire d'Il-Irion.

### Étape 1 : Déterminer le numéro d'enregistrement

Le registre utilise un système de numérotation continue depuis 1475 :
- Format : `UBI-[N°]` (ex: `UBI-001`, `UBI-002`, `UBI-003`)
- Consultez le registre pour trouver le dernier numéro utilisé
- Le prochain numéro sera celui qui suit

### Étape 2 : Classifier la criticité

Déterminez le niveau de criticité du contrat :

| Criticité | Emoji | Définition | Exemples |
|-----------|-------|------------|----------|
| **🔴 Critique** | 🔴 | Documents pouvant causer la chute de gouvernements | Plans de coups d'État, preuves de génocide |
| **🟠 Très Sensible** | 🟠 | Scandales politiques majeurs, malversations importantes | Accords secrets entre cités, chantage sur nobles |
| **🟡 Sensible** | 🟡 | Secrets commerciaux, affaires privées compromettantes | Contrats commerciaux sensibles, dettes importantes |
| **🟢 Standard** | 🟢 | Contrats normaux, documents administratifs | Prêts standards, contrats de mariage publics |

### Étape 3 : Ajouter une ligne dans le tableau

Ajoutez une nouvelle ligne dans le tableau principal du registre avec les informations suivantes :

| Colonne | Description | Exemple |
|---------|-------------|---------|
| **N° Enregistrement** | Format `UBI-[N°]` | `UBI-003` |
| **Type de Document** | Type de contrat | `Contrat commercial`, `Contrat de dette`, `Contrat d'alliance`, etc. |
| **Parties Impliquées** | Cités/familles concernées | `Sfaal ↔ Palyr`, `Il-Irion ↔ Palyr` |
| **Description du Contenu** | Résumé du contrat | `Fourniture de 10 tonnes d'acier pour 50 pièces d'or` |
| **Déposé par** | Nom du représentant qui dépose | `Duc de Sfaal`, `Seigneur Aldric Ventoss` |
| **Date de Dépôt** | Date de signature du contrat | `1520`, `1522` |
| **Criticité** | Niveau de sensibilité | `🟡 Sensible`, `🟠 Très Sensible`, etc. |
| **Statut** | État du document | `Actif` (en vigueur), `Archivé` (terminé) |
| **Format Document** | Nom du fichier | `CONTRACT-001`, `DEBT-001`, `ALLIANCE-001` |

### Exemple d'enregistrement

Pour un contrat de protection `PROTECTION-001` entre Palyr et Il-Irion :

```
| UBI-003 | Contrat de protection | Palyr ↔ Il-Irion | Protection des chantiers navals de Palyr par 10 gardes d'Il-Irion pour 6 mois, 500 pièces d'or | Légat Kaelen Forgefer | 1522 | 🟡 Sensible | Actif | PROTECTION-001 |
```

### Format du prompt pour l'enregistrement

Vous pouvez demander à l'IA d'enregistrer le contrat :

```
Enregistre le contrat PROTECTION-001 dans le registre UBI.
- Type : Contrat de protection
- Parties : Palyr ↔ Il-Irion
- Description : Protection des chantiers navals de Palyr par 10 gardes d'Il-Irion pour 6 mois, 500 pièces d'or
- Déposé par : Légat Kaelen Forgefer
- Date : 1522
- Criticité : 🟡 Sensible
- Statut : Actif
```

Ou plus simplement :

```
Enregistre le contrat PROTECTION-001 dans le registre UBI avec les informations du contrat.
```

L'IA extraira automatiquement les informations nécessaires du contrat créé.

### Notes sur l'enregistrement

- **Tous les contrats doivent être enregistrés** : C'est une obligation pour la traçabilité
- **Numérotation séquentielle** : Respectez l'ordre chronologique des numéros UBI
- **Criticité par défaut** : Si non spécifiée, utilisez `🟡 Sensible` pour la plupart des contrats
- **Statut initial** : Les nouveaux contrats sont généralement `Actif`
- **Mise à jour** : Si un contrat expire ou est résilié, changez son statut en `Archivé`

## 🔍 Liste des variables par template

### CONTRACT
- `[partie1]`, `[partie2]`, `[nom1]`, `[nom2]`
- `[description de l'accord]`, `[marchandise]`
- `[description élojieuse de la marchandise]`
- `[somme]`

### DEBT
- `[prêteur]`, `[emprunteur]`, `[nom_prêteur]`, `[nom_emprunteur]`
- `[fonction]`, `[montant]`, `[raison_du_prêt]`
- `[taux]`, `[modalités_intérêts]`, `[montant_total]`
- `[modalités_remboursement]`, `[date_première_échéance]`, `[date_échéance_finale]`
- `[description_des_garanties]`, `[pénalité]`, `[nombre_jours]`

### ALLIANCE
- `[partie1]`, `[partie2]`, `[nom1]`, `[nom2]`, `[fonction1]`, `[fonction2]`
- `[objectif_principal_de_l_alliance]`
- `[engagement_militaire_1/2/3]`, `[type_aide]`, `[délai]`, `[nombre]`, `[pourcentage]`
- `[engagement_diplomatique_1/2]`, `[ennemi_commun]`
- `[type_information_1/2]`, `[moyen_de_communication]`
- `[durée]`, `[durée_préavis]`, `[condition_rupture_1/2]`

### SERVICE
- `[employeur]`, `[prestataire]`, `[nom_employeur]`, `[nom_prestataire]`
- `[fonction_employeur]`, `[fonction_prestataire]`
- `[description_service_1/2/3]`, `[domaine_professionnel]`
- `[date_début]`, `[date_fin]`, `[conditions_fin]`
- `[lieu_principal]`, `[lieux_secondaires]`
- `[montant]`, `[modalités_paiement]`, `[modalité_paiement_détaillée]`
- `[obligation_1/2/3]`, `[description_matériaux]`
- `[propriétaire_œuvres]`, `[droit_conservé]`

### EXPLOITATION
- `[propriétaire]`, `[exploitant]`, `[nom_propriétaire]`, `[nom_exploitant]`
- `[fonction_propriétaire]`, `[fonction_exploitant]`
- `[description_ressource]`, `[localisation]`, `[superficie]`, `[volume]`
- `[date_début]`, `[date_fin]`, `[conditions_fin]`, `[durée_renouvellement]`
- `[obligation_exploitant_1/2/3]`, `[droit_exploitant_1/2]`
- `[modalités_redevances]`, `[modalité_paiement]`
- `[modalités_partage]`, `[pourcentage_propriétaire]`, `[pourcentage_exploitant]`
- `[description_installations]`

### EXCLUSIVITY
- `[vendeur]`, `[acheteur]`, `[nom_vendeur]`, `[nom_acheteur]`
- `[fonction_vendeur]`, `[fonction_acheteur]`
- `[type_exclusivité]`, `[produit_ou_service]`
- `[territoire]`, `[durée]`, `[champ_application_1/2]`
- `[obligation_vendeur_1/2]`, `[obligation_acheteur_1/2]`
- `[quantité_minimum]`, `[unité]`, `[période]`
- `[prix]`, `[unité_monétaire]`, `[condition_commerciale_1/2]`
- `[description_territoire]`, `[quantité_ou_volume]`, `[fréquence_livraison]`
- `[lieu_livraison]`, `[durée_renouvellement]`, `[condition_rupture_1/2]`
- `[durée_préavis]`, `[partie_responsable]`, `[montant_indemnité]`

### PROTECTION
- `[protégé]`, `[protecteur]`, `[nom_protégé]`, `[nom_protecteur]`
- `[fonction_protégé]`, `[fonction_protecteur]`
- `[service_protection_1/2/3]`, `[nombre_gardes]`, `[type_équipement]`
- `[objet_protection]`, `[localisation]`, `[durée]`, `[conditions_durée]`
- `[date_début]`, `[date_fin]`, `[conditions_fin]`, `[horaires_protection]`
- `[montant]`, `[modalités_paiement]`, `[modalité_paiement_détaillée]`
- `[obligation_protecteur_1/2/3]`, `[obligation_protégé_1/2]`
- `[conditions_responsabilité]`, `[montant_indemnité]`
- `[condition_résiliation_1/2]`, `[durée_préavis]`

### MARRIAGE
- `[famille1]`, `[famille2]`, `[nom1]`, `[nom2]`
- `[fonction1]`, `[fonction2]`
- `[époux_épouse_1]`, `[époux_épouse_2]`
- `[fonction_époux_épouse_1]`, `[fonction_époux_épouse_2]`
- `[apport_1/2]` (pour chaque famille)
- `[modalités_gestion]`, `[lieu_résidence]`, `[lieu_secondaire]`
- `[condition_héritage_1/2]`, `[droits_héritage_enfants]`
- `[obligation_1/2/3]`, `[engagement_alliance_1/2]`
- `[condition_dissolution_1/2]`, `[autorité_compétente]`
- `[lieu_cérémonie]`, `[date_cérémonie]`, `[tradition_religieuse]`

## 💡 Conseils

- **Utilisez un éditeur de texte** avec recherche/remplacement pour remplacer rapidement toutes les occurrences d'une variable
- **Gardez une copie** du template original pour référence
- **Vérifiez la cohérence** des dates et montants dans tout le document
- **Adaptez le style** si nécessaire, mais gardez l'esprit médiéval
- **Consultez les exemples** (`CONTRACT-001.md`, `DEBT-001.md`) pour voir comment remplir un contrat complet

---

*Dernière mise à jour : Création du guide*

