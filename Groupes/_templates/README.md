# Templates GN — Krondaar 2026

## Chaîne de production (méthode actuelle)

Trois niveaux seulement, dans l’ordre :

```
Codex & références
        ↓
Intrigue orga
        ↓
Back_groupe  ← document unique distribué à TOUT le groupe (= rôle collectif)
        ↓
Rôles joueurs  ← une fiche par PJ
```

| Étape | Fichier type | Public | Rôle |
|-------|----------------|--------|------|
| **1** | `Intrigues/Intrigue_[Groupe].md` | Orga / MJ / scénaristes | Tout le volet auteur : lecture rapide, situation, objectifs, interactions, identité du groupe (tableau des rôles), secrets, ressources. Gabarit : `0 - Intrigues/template_intrigue.md`. |
| **2** | `Groupes/[Groupe]/1 - Back de groupe/Back_groupe_[Groupe].md` | **Tous les joueurs du groupe** | **Le seul texte « groupe » remis aux joueurs** : récit immersif (légende, enjeux, ton), résumé des objectifs jouables, composition de l’équipe — **sans** les secrets réservés MJ (ceux-ci restent dans l’intrigue ou sur une fiche perso). Gabarit : `1 - Back de groupe/template_back_groupe.md`. |
| **3** | `Groupes/[Groupe]/2 - Roles des Joueurs/back_joueur_*.md` (ou `role_joueur_*.md` selon le groupe) | **Chaque joueur** | Fiche individuelle : pratique GN, portrait, histoire courte, missions, contacts, informations sensibles du perso. Gabarit : `2 - Roles de groupe/template_role_joueur.md`. |

**Important.** Le **Back_groupe** n’est pas une « ébauche orga » à part : c’est **directement** le document que vous donnez à l’ensemble du groupe. Il ne remplace pas l’intrigue (l’intrigue reste la référence auteur) et il ne doublonne pas un autre fichier « Histoire du groupe » sous un autre nom — **sauf** choix volontaire de maintenir un fichier séparé pour un groupe donné.

## Dossiers de templates

| Dossier | Contenu |
|---------|---------|
| `0 - Intrigues/` | `template_intrigue.md` — intrigue tout-en-un orga |
| `1 - Back de groupe/` | `template_back_groupe.md` — rôle / livret **collectif** joueurs |
| `2 - Roles de groupe/` | `template_role_joueur.md` — fiche **individuelle** joueur |
| `_prompts/` | Prompts IA et `README` d’ordre de génération |

## Avantages

- **Une intrigue** pour trancher et cacher ce qu’il faut.
- **Un seul livret groupe** à maintenir pour le ton et la mission partagée.
- **Des rôles joueurs** alignés sans répéter trois fois la même légende.

---

*GN Krondaar 2026*
