# Journal — consolidation `Afaire.md`

Ce fichier trace les actions réalisées lors des passes « check groupe » pour ajuster les skills / procédures si besoin.

---

## 2026-04-21 — Groupe **Palyr** (premier item de la liste)

**Référence procédure** : `Groupes/Afaire.md`, chapitre « Check d’un groupe » (hors commentaires HTML sur interactions manquantes).

### Actions réalisées

1. **Alignement intrigue ↔ back (lecture seule + livrable)**  
   - Fichier créé : `Groupes/Palyr/1 - Back de groupe/check_back.md`  
   - Contenu : plan agent listant écarts / manques entre `Back_groupe_Palyr.md` et `Intrigues/Intrigue_Palyr.md`, avec auto-relecture. **Aucune modification** de l’intrigue ni du back.

2. **Alignement rôles ↔ back (lecture seule + livrable)**  
   - Fichier créé : `Groupes/Palyr/1 - Back de groupe/check_role.md`  
   - Périmètre : les `perso_Palyr_*-orga.md` (pas de dossier `3 - Rôles des Joueurs` pour ce groupe dans le dépôt). **Aucune modification** des persos ni du back.

3. **Synthèse interactions**  
   - Fichier créé : `Groupes/Palyr/interactions du groupe Palyr.md`  
   - Méthode : extraction depuis Relations / Motivations / Éléments de jeu des persos orga (pas de section « Connaissances » titrée sur ces fiches).  
   - Style descriptifs : vouvoiement évité dans le tableau ; formulation **tu** pour injection fiche joueur, comme demandé dans `Afaire.md`.

4. **Fiche globale**  
   - Fichier mis à jour : `Groupes/Fiche_interactions_tous_groupes.md` — chapitre **§5. Palyr** : tableau enrichi, renvoi vers la synthèse Palyr, harmonisation de noms (ex. Melian Torv), ajout des lignes absentes (Selvara, Gorvan, Lira, Éliane, Oblats, etc.) ; retrait ultérieur des PNJ nommés (Goryn / Queldaryn) du canon joueur partagé.

5. **Suivi checklist**  
   - Fichier mis à jour : `Groupes/Afaire.md` — case **« checker le groupe Palyr »** passée à `[x]`.

### Décisions / notes pour affiner les skills

| Sujet | Note |
|--------|------|
| Source « Connaissances » | Pour Palyr, prévoir dans la skill l’fallback : *Relations + Motivations + Éléments de jeu* si pas de heading « Connaissances ». |
| Orthographe Arguetheim | Incohérence relevée dans `check_role.md` (arguethaim vs Arguetheim) — correction réservée à une passe globale, pas faite ici. |
| Fiche globale vs perso | Ligne Horgrim–Saevar conservée dans la fiche générale ; écart avec le perso Saevar signalé dans `check_role.md` pour arbitrage scénariste. |
| Emplacement synthèse groupe | Fichier placé sous `Groupes/Palyr/` à la racine du dossier groupe ; si tu préfères tout sous `1 - Back de groupe/`, déplacer et mettre à jour le lien dans `Fiche_interactions_tous_groupes.md`. |

### Reste à faire (autres groupes)

- ~~Tripot, Mafia, MiVI~~ : traités le 2026-05-04 ; **UBI** : à confirmer selon état du dépôt (`Afaire.md` l.7).

---

## 2026-04-23 — Palyr : fin de l’étape « backs orga » + pivot **Saevar**

- Supprimé : répertoire `Groupes/Palyr/2 - Backs de persos/` (fiches `perso_Palyr_*-orga.md`). La chaîne de publication pour ce groupe est désormais **intrigue** → **Back_groupe** → **`2 - Roles des Joueurs/back_joueur_*.md`**.
- Casting : le cinquième homme reste **Saevar Dren** (références croisées avec d’autres groupes) ; les angles « réseaux / Tripot » qui avaient été regroupés sous le nom Brael sont portés par **Saevar** sur la fiche joueur et dans les tableaux d’interactions.
- `_templates/README.md` et prompts : retrait de la mention d’une étape intermédiaire `perso_*-orga.md` comme étape de workflow du dépôt.

---

## 2026-05-04 — Groupes **Tripot**, **Mafia (Sangs)**, **MiVI** (consolidation Afaire)

**Référence** : `Groupes/Afaire.md`, chapitre « Check d’un groupe » (hors commentaires HTML sur interactions manquantes).

### Actions réalisées

1. **Backs** : `Back_groupe_Tripot.md`, `Back_groupe_Mafia.md` (ex-`Back_Mafia.md`), `Back_groupe_MiVI.md` — ton factuel, structure type UBI (déjà en place en amont de cette passe).
2. **Checks** : `check_back.md` et `check_role.md` dans `1 - Back de groupe/` pour chacun des trois groupes — inventaires orga sans modification des intrigues, backs ou rôles dans ces fichiers.
3. **Synthèses interactions** : `interactions du groupe Tripot.md`, `interactions du groupe Mafia.md`, `interactions du groupe MiVI.md` à la racine des dossiers groupe (uniquement hors-groupe, tableaux style Palyr).
4. **Fiche globale** : `Fiche_interactions_tous_groupes.md` — §4 Mafia et §6 Tripot réalignés sur ces synthèses ; **§9 MiVI** ajouté ; §5 Palyr : ligne Thoran×Gorvan retirée, ligne **Lysa×Gorvan** ajoutée (cohérence `role_joueur_Lysa_Morwyn.md`).
5. **Checklist** : cases Tripot, Mafia, MiVI passées à `[x]` dans `Afaire.md` (l.3–5).
