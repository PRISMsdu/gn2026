# Prompts — génération de contenu GN (Krondaar 2026)

## Rôle de ce dossier

Templates et prompts pour l’aide à la rédaction (IA ou humain). La **méthode de référence** du dépôt est décrite dans **`Groupes/_templates/README.md`**.

## Chaîne courte (méthode actuelle)

```
Codex & références
        ↓
Intrigue orga  →  Intrigues/Intrigue_[Groupe].md
        ↓
Back_groupe    →  document unique pour TOUT le groupe (= rôle collectif)
        ↓
Rôles joueurs  →  une fiche par PJ
```

Il n’y a **pas** d’étape séparée « Histoire du groupe » sous un autre nom : le **Back_groupe** est le livret remis à l’ensemble des joueurs du groupe.

## Fichiers utiles

| Fichier | Usage |
|---------|--------|
| `template_prompt_intrigue.md` | Base pour `prompt_Intrigue_[Groupe].md` |
| `prompt_intrigue_*.md` | Prompts sauvegardés par groupe / lieu |
| `../0 - Intrigues/template_intrigue.md` | Gabarit de sortie intrigue |
| `../1 - Back de groupe/template_back_groupe.md` | Gabarit du document collectif joueurs |
| `../2 - Roles de groupe/template_GROUPE_NomDuPersonnage_role.md` | Gabarit fiche individuelle |

## Ordre de génération recommandé

1. **Intrigue** — copier / compléter `template_prompt_intrigue.md`, produire `Intrigues/Intrigue_[Groupe].md`.
2. **Back_groupe** — à partir de l’intrigue, rédiger le récit + objectifs + tableau d’équipe **pour les joueurs** (`Back_groupe_[Groupe].md`). Pas de secrets MJ dans ce fichier.
3. **Rôles joueurs** — une fiche par personnage, alignée intrigue + Back_groupe.

### Intrigue

1. Copier `template_prompt_intrigue.md` → `prompt_Intrigue_[NOM_DU_GROUPE].md`
2. Compléter les sections
3. Exécuter le prompt ; sauvegarder le résultat dans `Intrigues/`

### Back_groupe (après l’intrigue)

- Utiliser `../1 - Back de groupe/template_back_groupe.md`
- Ou demander à l’IA : « À partir de `Intrigue_[Groupe].md`, rédige le Back_groupe joueur selon `template_back_groupe.md`. »

### Rôle joueur

- Utiliser `../2 - Roles de groupe/template_GROUPE_NomDuPersonnage_role.md`
- Source : intrigue + Back_groupe

## Exemples de chemins (références projet)

- **Mafia** : `Intrigue_Mafia.md` → `Back_groupe` côté Sangs si présent → `3 - Roles des Joueurs/{Groupe}_*_{Role}.md`
- **MiVI** : `Intrigue_MiVI.md` → `Groupes/MiVI/1 - Back de groupe/Back_groupe_MiVI.md` → rôles Corvel

## Checklist

**Avant publication joueurs**

- [ ] Secrets MJ uniquement dans l’intrigue (ou fiche perso), pas dans le Back_groupe commun
- [ ] Back_groupe cohérent avec les objectifs de l’intrigue
- [ ] Rôles joueurs sans contradiction avec le Back_groupe

---

*GN Krondaar 2026*
