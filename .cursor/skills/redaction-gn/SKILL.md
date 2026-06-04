---
name: redaction-gn
description: >-
  Rédige ou révise des textes GN joueur (backs, rôles, codex, scènes) en prose
  factuelle — référence Marda Velyss / codex Trois Îles. Bullets + sources +
  7 passes de relecture obligatoires (dont passe sens explicite finale). Utiliser pour rédaction, révision style,
  ou quand l'utilisateur cite rédaction GN, ton joueur, anti-charabia.
---

# Rédaction GN

## Principe

Le livrable joueur est un **briefing in-univers** : qui tu es, ce qui s'est passé, ce que tu peux faire ce week-end.
Chaque phrase dit **un fait**. Le style est **discret** : si la formulation attire l'attention, c'est mauvais.

**Règle d'or** : si un joueur ne peut pas en déduire **une action, une relation ou une contrainte** après lecture, la phrase n'a pas sa place.

**Référence qualité (rôle)** : `Groupes/Tripot/2 - Roles des Joueurs/Tripot_Marda_Velyss_Patronne.md` — biographie longue, dates, noms, documents, paragraphes développés.

**Référence qualité (codex joueur)** : registre sobre de `codex/Monde/histoire_confederation.md` (§ La Confédération des Trois Îles) — faits posés un par un.

**Anti-référence** : rôles Tripot courts (Éliane, Lydwen, Varek, etc.) — chapitres I–V d'une phrase, gras, métaphores, sens caché.

Règles dépôt à croiser selon le type :
- Joueur : `.cursor/rules/redaction-textes-joueurs.mdc`
- Gras orga : `.cursor/rules/markdown-gras-intitules.mdc` pour `Intrigues/`, `Afaire.md`

---

## Ton attendu

- Simple, direct, sans jargon d'auteur.
- Le texte cherche à être **compris**, pas à impressionner.

---

## Entrées utilisateur

| Entrée | Rôle |
|--------|------|
| **Sources** | Fichiers à lire (intrigue MJ, back groupe, autres rôles). Lire avant d'écrire. |
| **Bullets** | Faits bruts, sans style. Base exclusive du contenu narratif. |
| **Directives** | Longueur, personne, secrets, ton — **priment** sur les sources. |
| **Livrable** | Chemin + type (joueur / orga). |

Sans bullets : extraire d'abord une liste de faits en bullets, ou ne rédiger qu'avec les faits explicites des sources — **jamais inventer**.

---

## Workflow (7 étapes — ne pas sauter)

### 1. Inventaire des sources

1. Lister les fichiers lus.
2. Noter les faits : qui, quoi, où, quand, document, chiffre, relation.
3. Repérer doublons et contradictions.
4. Contradiction non résolue : signaler en une phrase ; ne pas trancher par invention.

### 2. Plan (avant la prose)

**Rôle joueur** — fixer avant d'écrire :
- 5 à 8 sections biographie (titres = **période ou enjeu**, pas « Chapitre I : Les origines » vide).
- 3 à 5 objectifs prioritaires (verbe + résultat).
- Table relations (≥ 5 entrées si le back le permet).
- Secrets : ce que le PJ sait / ignore / ce que les autres ignorent.

**Back groupe / codex** : plan par sections avec un fait jouable minimum par section.

### 3. Rédaction bullet → prose

**Méthode** :
1. Chaque groupe de bullets → 2 à 5 phrases.
2. Au plus une ou deux phrases par bullet.
3. Ordre logique des faits ; aucun ajout hors bullets + sources + directives.
4. Fait flou → phrase la plus simple possible, sans combler.

**Structure phrase** :
- Une idée par phrase ; sujet — verbe — complément.
- Pas de point-virgule pour empiler trois idées.
- Pas de subordonnées empilées.

**Ancrage obligatoire** (au moins 2 par section biographie) :
- date relative (il y a X ans, depuis Y ans) ;
- lieu (Il-Irion, Tripot, UBI…) ;
- nom propre ;
- chiffre (10 %, 400 po, six morts) ;
- document (bordereau, registre, code pièce).

**Paragraphe** : 2 à 5 phrases ; un sujet par paragraphe ; si > 5 phrases, couper.

**Orienté jeu** : chaque paragraphe utile apporte au moins une info exploitable (relation, contrainte, lieu, document, délai, risque). Supprimer l'« ambiance seule ».

**« Tu » (2e personne)** :
- Ne pas commencer chaque phrase par « tu ».
- Alterner : lieu, contexte, nom propre, puis « tu ».
- Éviter : *Tu sais… Tu comprends… Tu réalises…*

**Émotion** : par les faits, pas les adjectifs (*tragique*, *crucial*, *inestimable*).

**Fusion de sources** : directives > bullets > sources. Un fait une seule fois. Ne pas recopier un doc technique entier. Noms canon du dépôt (Ulghart, Il-Irion, Escalèche…).

### 4. Passe anti-charabia (obligatoire)

Relire **chaque phrase**. Supprimer ou réécrire si :

| Signal d'alarme | Action |
|-----------------|--------|
| Section biographie ≤ 2 phrases | Interdit — développer depuis sources |
| Phrase ≤ 8 mots sans nom, date ni lieu | Fusionner ou développer |
| Mot en gras porte seul le sens | Enlever gras ; écrire le fait en clair |
| Métaphore, jeu de mots, image poétique | Remplacer par action concrète |
| Mot abstrait seul (*marge*, *levier*, *angle*, *ombre*, *résonner*, *tisser*, *voix*, *fil*) | Nommer qui fait quoi |
| « ligne » au sens fil d'intrigue orga | Nommer l'enjeu : banque, mafia, audit, fuite |
| « accord table », « autoplay », « selon MJ » dans la bio | Déplacer en commentaire HTML ou note orga |
| Voix passive / jargon archive dans la voix perso | Acteur + verbe concret |
| Peur / rêve / valeurs en énigme | Reformuler en fait concret |

**Formes indirectes à couper** (voix du perso) :
- *indiquer une ligne de…*, *laissée en veille*, *est déposé*, *prestataire*, *exécution acquittée* ;
- négations tordues (*ne pas… sans…*) ;
- compléments d'objet abstraits sans acteur.

**Comment réécrire** : sujet clair + verbe concret (*donner*, *filer*, *chercher*, *dire*, *griffonner*, *fermer*, *filature*). D'abord ce que le perso a reçu (*une piste*, *un nom*, *un code*), puis le détail si besoin.

**Test voix haute** : brief à un autre PJ dans la cuisine du Tripot. Si ça sonne poème, discours ou notice d'archive → réécrire en langage parlé.

### 5. Passe forme

Appliquer [`checklist.md`](checklist.md). Corriger avant livraison.

### 6. Passe densité (rôle joueur)

- Biographie ≥ **40 lignes** pour un rôle principal (≥ **25** si rôle secondaire).
- ≥ **5 sections** biographie nommées.
- ≥ **3 objectifs** prioritaires.
- Section `# Connaissances` : un `##` par contact **hors groupe** ou sujet documenté ; pas de fiche sur les coéquipiers (chapitre V + back de groupe).

Si plus court → **sous-rédaction** : retour aux sources, pas ajout de style.

### 7. Passe sens explicite (obligatoire — dernière avant livraison)

Relire **le document entier**, phrase par phrase **et chapitre par chapitre**, comme si tu briefais un joueur qui ne connaît pas le jargon orga.

**Objectif phrase** : chaque phrase doit avoir un sens **littéral et vérifiable** — qui fait quoi, où, avec quel document, quel résultat attendu.

**Objectif chapitre** : chaque section (chapitre biographie, bloc Connaissances, objectif prioritaire) doit tenir **seule** : le joueur comprend de quoi il s'agit, pourquoi c'est là, et **ce qu'il peut faire en jeu** avec l'information. Un chapitre qui empile noms, codes pièce ou termes métier sans expliquer le geste jouable est une **information injouable** : la développer en paragraphes (contexte → acteurs → action possible → limite ou risque).

| Signal d'alarme | Action |
|-----------------|--------|
| Image détournée (*acheter des secondes*, *ouvrir des portes*, *brûler une source*, *cesse de respirer*) | Remplacer par l'action réelle : retenir un témoin, présenter quelqu'un à une commission, abandonner un informateur, tuer |
| Métaphore maritime ou de jeu appliquée à une relation (*mise sur son visage*, *terrain de jeu*) | Nommer le lieu et le geste : Tripot, fausse identité, table de jetons |
| Phrase compréhensible seulement par allusion | Ajouter sujet, objet, lieu ou conséquence |
| Anglais ou jargon orga dans le texte joueur (*cover story*, *PJ*, *double rôle*) | Français in-univers : fausse identité, délégation, mission secrète |
| Deux phrases courtes qui esquivent le fait | Fusionner en une phrase directe |
| Liste de noms ou code pièce sans contexte (*Noms utiles : X, Y, Z*) | Expliquer le cadre (commission, quai, salon), le rôle de chaque nom et la proposition concrète à tenir |
| Chapitre qui enchaîne faits sans fil (couverture → pièce → autre pièce) | Reprendre le chapitre : fil chronologique ou par chantier, paragraphes de 2 à 5 phrases, une idée par paragraphe |
| Bloc Connaissances plus sec que la biographie | Reprendre le même niveau de détail jouable que dans le chapitre correspondant |

**Test phrase** : lire la phrase à voix haute. Si l'interlocuteur peut répondre « oui, mais concrètement tu fais quoi ? », réécrire.

**Test chapitre** : lire le titre de section puis poser « à quoi ça sert en jeu ? ». Si la réponse exige de deviner le jargon orga ou de lire une autre fiche, développer le chapitre.

**Exemples à ne plus produire** :
- ❌ *Tu lui achètes des secondes avec des mots ; il passe les portes que la politesse n'ouvre plus.*
- ✅ *Tu retiens le gardien ou l'hôte par la conversation. Varro entre quand la parole ne suffit plus. Tu préviens Théven avant que Varro n'agisse seul.*

- ❌ *Il décide si on brûle une source ou si on attend.*
- ✅ *Il décide si on abandonne un informateur ou si on attend le lendemain.*

- ❌ *Liste d'intermédiaires pour enchères d'escales. Noms utiles : Sera Orist, Jonn Halet, Maison Veth & Roole.*
- ✅ *Pendant la Convention, les maisons se disputent l'ordre d'accostage et les rabais fret. Sera Orist (Arthas, armateur) peut soutenir une sous-enchère Palyr–Il-Irion. Jonn Halet (Ther-Félis) attribue les quais ; négocie en personne. Maison Veth & Roole sert aux billets différés — seulement si Théven l'ordonne.*

Cette passe **s'applique après** les passes 4 à 6. Elle ne remplace pas l'anti-charabia : elle vérifie que le sens reste explicite une fois le style corrigé, **y compris à l'échelle d'un chapitre entier**.

---

## Interdits (liste fermée)

- Métaphores et images poétiques.
- Dramatisation artificielle (*jackpot dramatique*, *tempête de jetons*).
- Vocabulaire abstrait sans fait derrière.
- Effets d'auteur (*le lecteur comprendra*, *peu de gens savent*).
- Tournures alambiquées ou phrases « sens caché ».
- Exemples concrets à ne jamais écrire :
  - « le jeu invisible du pouvoir »
  - « l'ombre des décisions »
  - « une toile complexe de relations »
  - « une émotion est une marge si tu sais l'étiqueter »
  - « le filet sous la soie du tapis »

**Grandeur nature** — interdits absolus :
- « selon ce que la table… », « à la table », « ce que la table décide » ;
- « tenir la ligne », « sur cette ligne », « la ligne de… » au sens fil d'intrigue orga (OK : *ligne de crédit*, *ligne de flottaison* au sens maritime si dans les sources).

---

## Markdown — gras

**Livrable joueur** (backs, fiches rôle, codex joueur, gazette, contrats remis…) :
- Pas de gras décoratif.
- Structure : titres, listes, tableaux, paragraphes courts.
- Libellés : `Intitulé : détail` sans `**`.
- Pas de gras sur noms propres ni pour « insister ».
- **Jamais** de mention orga type `*(règlement — orga)*`, `*(règlement orga)*` ou équivalent dans une fiche rôle remise au joueur — la classe ou profession seule suffit (ex. `Guerrier`, pas `Guerrier *(règlement — orga)*`).

**Orga** (`Intrigues/`, `Afaire.md`) : gras uniquement sur intitulé immédiat avant `:` en tête de puce — voir règle dépôt markdown-gras-intitules.

---

## Structure type — fiche rôle joueur

```
## Apparence et caractère (table — traits factuels)

# Biographie
## [Période ou enjeu — titre explicite]
…

# Tes missions et actions
## Ton rôle au quotidien
## Objectifs prioritaires
## Ce que tu ne fais pas (optionnel)
## Informations sensibles (optionnel)

# Connaissances
## Prénom Nom — groupe / lieu *(hors ton groupe)*
… (contacts externes, pièces — pas les coéquipiers)
```

Ne pas livrer « Chapitre I : Les origines » avec une ou deux phrases. Voir `examples.md` pour paires Tripot avant/après.

---

## Formats de demande (exemples)

```markdown
## Rédaction GN

**Livrable** : Groupes/…/Back_groupe_X.md (joueur)
**Sources** : Intrigues/Intrigue_X.md, codex/…/fiche.md
**Directives** : tutoiement ; pas de secret X
**Bullets** :
- …
```

```markdown
## Révision style seule

**Fichier** : …
**Directives** : aligner sur Marda ; garder tous les noms propres
```

---

## Livraison

- Écrire dans le fichier cible.
- Si révision : 3–5 puces « ce qui a changé ».
- Ne pas committer sauf demande explicite.

---

## Ressources

- Checklist : [`checklist.md`](checklist.md)
- Exemples : [`examples.md`](examples.md)

---

## Règle finale

Un bon texte est discret. Si le style attire plus l'attention que le contenu, il est mauvais.
