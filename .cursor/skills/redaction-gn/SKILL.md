---
name: redaction-gn
description: >-
  Rédige ou révise des textes GN (backs, codex, intrigues, fiches) en appliquant
  Groupes/_templates/Style.md : bullets et directives utilisateur + fusion de
  plusieurs fichiers sources, relecture obligatoire. Utiliser quand l'utilisateur
  demande une rédaction, un contrôle de style, une transformation bullet → prose,
  ou cite Style.md, rédaction GN, ton joueur.
---

# Rédaction GN — contrôle de style

## Référence canon

Lire **avant toute rédaction** : [`Groupes/_templates/Style.md`](../../../Groupes/_templates/Style.md).

Ton cible pour les livrables joueur : registre sobre type prologue de [`codex/Monde/histoire_confederation.md`](../../../codex/Monde/histoire_confederation.md) (faits posés un par un), pas les longs passages fleuris du même fichier.

Règles dépôt à croiser selon le type de fichier :
- Joueur : `.cursor/rules/redaction-textes-joueurs.mdc`, `backs-prose-claire.mdc`, `gn-back-narratif.mdc` si `Back_groupe`
- Gras : `Style.md` §11 prime sur le joueur ; orga (`Intrigues/`, `Afaire.md`) → `.cursor/rules/markdown-gras-intitules.mdc`

---

## Ce que l'utilisateur fournit (obligatoire à clarifier si manquant)

| Entrée | Rôle |
|--------|------|
| **Sources** | Un ou plusieurs chemins (fichier ou dossier). Lire tout le contenu utile avant d'écrire. |
| **Bullets** | Faits bruts, sans style. Base exclusive du contenu narratif (§1 Style.md). |
| **Directives** | Consignes explicites : longueur, personne (tu / il), section cible, interdits, ton, ce qu'il faut garder ou couper. **Priment sur les sources** en cas de conflit. |
| **Livrable** | Chemin du fichier à créer ou modifier + type (joueur / orga / technique). |

Si les bullets sont absents mais les sources présentes : extraire d'abord une liste de faits en bullets (sans style), la soumettre brièvement à l'utilisateur **ou** rédiger en ne gardant que les faits explicitement présents dans les sources — **jamais** d'invention.

---

## Workflow

### 1. Inventaire des sources

1. Lister les fichiers lus (chemins relatifs au dépôt).
2. Noter les **faits** (qui, quoi, où, quand, document, chiffre, relation).
3. Repérer les **doublons** et les **contradictions** entre sources.
4. En cas de contradiction non résolue par une directive utilisateur : signaler en une phrase et ne pas trancher par invention.

### 2. Fusion du contenu

Ordre de priorité pour le texte final :

1. **Directives** utilisateur (structure, angle, longueur, secrets à exclure)
2. **Bullets** fournis
3. **Sources** — uniquement pour compléter un bullet ou pour vocabulaire / noms canon

Règles de fusion :
- Un fait ne paraît qu'une fois dans la prose (pas de répétition entre deux sections).
- Ne pas recopier un document technique entier : résumer, renvoyer si besoin vers la fiche source.
- Respecter les noms canon du dépôt (Ulghart, Andulin, Escalèche, etc.).
- Chaque paragraphe apporte au moins une info **exploitable en jeu** (§7 Style.md).

### 3. Transformation bullet → prose (§1 Style.md)

Pour chaque groupe de bullets (souvent une section) :

1. Produire **2 à 5 phrases** par paragraphe.
2. **Au plus une ou deux phrases** par bullet.
3. Enchaîner dans l'ordre logique des faits.
4. **Aucun ajout** hors bullets + sources + directives.
5. Fait flou → phrase la plus simple possible, sans combler.

Structure phrase (§4) : une idée par phrase ; sujet — verbe — complément ; pas de point-virgule pour empiler des idées ; pas de subordonnées empilées.

### 4. Relecture obligatoire (§9 — ne pas sauter)

Appliquer [`checklist.md`](checklist.md) sur le brouillon. Corriger avant livraison.

### 5. Livraison

- Proposer le texte dans le fichier cible (ou le bloc demandé).
- Si révision : résumer en 3–5 puces ce qui a changé (coupe style, faits retirés pour flou, conflits sources).
- Ne pas committer sauf demande explicite.

---

## Formats de demande (exemples pour l'utilisateur)

Copier-coller et remplir :

```markdown
## Rédaction GN

**Livrable** : Groupes/…/Back_groupe_X.md (joueur)
**Sources** : Intrigues/Intrigue_X.md, codex/…/fiche.md
**Directives** : 2e personne modérée ; pas de secret Corvyn ; § « Ce qui a cassé » en premier
**Bullets** :
- …
- …
```

```markdown
## Révision style seule

**Fichier** : …
**Directives** : raccourcir de moitié ; garder tous les noms propres
```

---

## Anti-patterns (rappel court)

Interdits §3 Style.md : métaphores, dramatisation, abstractions sans fait, effets d'auteur, tournures alambiquées.

Test : lire à voix haute — si ça sonne discours ou roman, réécrire en langage parlé.

Émotion par les faits, pas les adjectifs (§8).

« Tu » : ne pas commencer chaque phrase par « tu » (§6).

---

## Ressources

- Checklist relecture : [checklist.md](checklist.md)
- Avant / après : [examples.md](examples.md)
