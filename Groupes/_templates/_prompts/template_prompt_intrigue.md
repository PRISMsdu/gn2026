# Template de Prompt - Génération d'Intrigue

## Instructions d'utilisation

1. **Copier ce template** dans le répertoire `./prompts/` avec le nom `prompt_Intrigue_[NOM_DU_GROUPE].md`
2. **Compléter les sections** avec les informations spécifiques au groupe
3. **Exécuter le prompt** en utilisant l'IA pour générer l'intrigue
4. **Sauvegarder le prompt utilisé** pour référence future

---

## Prompt pour génération d'intrigue

```
Tu es un scénariste expert en Grandeur Nature (GN) spécialisé dans l'univers de Krondaar. 

## Contexte et Objectif

Je veux créer une intrigue pour le groupe **[NOM_DU_GROUPE]** dans l'univers de Krondaar. Cette intrigue doit être immersive, dramatique et offrir des enjeux clairs pour les joueurs.

## Informations sur le Groupe

### Groupe cible
- **Nom du groupe** : [NOM_DU_GROUPE]
- **Type d'organisation** : [TYPE]
- **Contexte** : [BREF_DESCRIPTION]

### Codex et Références
- **Codex principal** : [FICHIER_CODEX_PRINCIPAL]
- **Codex secondaires** : 
  - [FICHIER_CODEX_1]
  - [FICHIER_CODEX_2]
  - [FICHIER_CODEX_3]

### Intrigues de groupes déjà écrites (cohérence)
- **Fichiers** : [CHEMIN_VERS_INTRIGUE_1, INTRIGUE_2…]
- **Points à ne pas contredire** : [RAPPEL_COURT]

### Fichiers d'inspiration
- **Intrigues similaires** : [FICHIER_INTRIGUE_1, FICHIER_INTRIGUE_2]
- **Groupes connexes** : [GROUPE_1, GROUPE_2]
- **Événements du monde** : [EVENEMENT_1, EVENEMENT_2]

## Idées et Directions

### Thèmes principaux
- [IDEE_1]
- [IDEE_2]
- [IDEE_3]

### Conflits potentiels
- [CONFLIT_1]
- [CONFLIT_2]
- [CONFLIT_3]

### Enjeux souhaités
- [ENJEU_1]
- [ENJEU_2]
- [ENJEU_3]

### Relations avec d'autres groupes
- **[GROUPE_1]** : [TYPE_DE_RELATION] - [DESCRIPTION]
- **[GROUPE_2]** : [TYPE_DE_RELATION] - [DESCRIPTION]
- **[GROUPE_3]** : [TYPE_DE_RELATION] - [DESCRIPTION]

## Contraintes et Exigences

### Contraintes techniques
- **Durée du GN** : [DURÉE]
- **Nombre de joueurs** : [NOMBRE]
- **Lieu principal** : [LIEU]
- **Période** : [PÉRIODE]

### Exigences narratives
- **Ton souhaité** : [DRAMATIQUE, ÉPIQUE, MYSTÉRIEUX, etc.]
- **Niveau de violence** : [FAIBLE, MOYEN, ÉLEVÉ]
- **Complexité** : [SIMPLE, MOYENNE, COMPLEXE]

## Instructions de génération

Génère une intrigue complète en utilisant le template `template_intrigue.md` avec les sections suivantes :

1. **Informations générales** : Intrigue, groupe, type d’intrigue, type d’organisation, siège, période, statut légal
2. **Lecture rapide orga**
3. **Situation et contexte**
4. **Objectifs**
5. **Acteurs et parties prenantes** (tableau)
6. **Identité du groupe (orga)** : structure, rôles nécessaires, constitution nommée, règles internes, culture et tensions
7. **Secrets et informations sensibles**
8. Rappeler que le **document collectif joueurs** (rôle de tout le groupe) est `Groupes/.../1 - Back de groupe/Back_groupe_[Groupe].md` — rédigé **après** l’intrigue, pas fusionné dans le même fichier que l’orga

## Style et Format

- **Ton** : Dramatique et immersif
- **Format** : Markdown strictement conforme au template
- **Longueur** : 3-4 pages A4
- **Détails** : Concrets et utilisables en jeu
- **Cohérence** : Avec l'univers de Krondaar et les autres groupes

## Exemple de sortie attendue

L'intrigue doit ressembler à ceci :
```markdown
# [NOM_ACROCHEUR] - Intrigue de Groupe

## Informations Générales
- **Nom de l'intrigue** : [Titre accrocheur]
- **Groupe concerné** : [NOM_DU_GROUPE]
- **Type d'intrigue** : [Type spécifique]

[... reste du template rempli ...]
```

Génère maintenant l'intrigue complète.
```

---

## Notes d'utilisation

### Avant de générer
- [ ] Remplir toutes les sections du template
- [ ] Vérifier la cohérence avec l'univers
- [ ] S'assurer que les rôles nécessaires sont définis

### Après génération
- [ ] Vérifier que l’**identité du groupe** (organigramme, règles, culture) est bien remplie dans le même fichier
- [ ] Adapter les rôles si nécessaire
- [ ] Valider les relations avec les autres groupes

### Sauvegarde
- [ ] Sauvegarder le prompt utilisé
- [ ] Documenter les modifications apportées
- [ ] Mettre à jour les relations inter-groupes

---

*Template créé pour la génération d'intrigues - GN Krondaar 2026*
