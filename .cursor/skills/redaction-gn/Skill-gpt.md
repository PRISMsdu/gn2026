---
name: redaction-gn-gpt
description: >
  Rédige ou révise des textes GN joueur en prose factuelle stricte.
  Optimisé GPT : zéro métaphore, zéro abstraction, sens explicite obligatoire.
  Pipeline imposé + vérification dure. Style sobre, jouable immédiatement.
---

# Skill — Rédaction GN (Optimisé GPT)

## Objectif

Rédiger ou réviser des textes GN joueur sous forme de **briefing in-universe clair, factuel et jouable**.

Le texte final doit être :
- Compréhensible immédiatement
- Utilisable en jeu sans interprétation
- Sans style littéraire inutile
- Directement exploitable par un joueur

---

## 🔴 PRIORITÉS (ordre strict)

1. Sens explicite  
2. Utilité en jeu  
3. Clarté  
4. Concision  
5. Style (en dernier uniquement)

Si conflit → respecter cet ordre sans exception

---

## 🧠 Règle centrale

Chaque phrase doit permettre au joueur de répondre immédiatement à au moins une question :

- Que fais-tu ?
- Avec qui ?
- Où ?
- Pourquoi ?
- Avec quel risque ou objectif ?

Si aucune réponse claire → supprimer la phrase

---

## 🚫 Interdictions absolues

Tout élément ci-dessous invalide immédiatement la phrase.

### Style interdit

- Métaphore
- Image poétique
- Symbolisme
- Effet littéraire
- Ambiguïté volontaire
- “Ambiance” sans information exploitable

### Formes interdites

- "tu apprends à…"
- "tu sens que…"
- "tu comprends que…"
- "il semble que…"
- "dans l’ombre…"
- "une tension…"
- "une dynamique…"
- "comme un…"
- "une toile de…"
- "un jeu de…"

### Abstraction interdite

Tout mot abstrait sans acteur réel :

- tension
- relation
- dynamique
- système
- influence
- équilibre
- situation

Remplacement obligatoire :

> acteur + action + conséquence

---

## 🧩 Format de phrase obligatoire

Chaque phrase suit obligatoirement :

[Sujet explicite] + [verbe concret] + [action ou objet] + [contexte optionnel]


### ✅ Correct

- Tu rencontres Halet au quai 3.
- Il demande 400 po.
- Tu refuses sans reçu.
- La livraison reste bloquée.

### ❌ Incorrect

- Tu sens qu’il est dangereux.
- Une tension monte.
- Il joue un jeu complexe.
- L’équilibre change.


## 🏗️ Règles de paragraphes

- 2 à 4 phrases maximum
- 1 sujet par paragraphe
- 1 idée principale
- >4 phrases → couper

---

## ⚙️ Pipeline obligatoire (ordre strict)

### 1. Extraction des faits

- Lire toutes les sources
- Lister les faits en bullets
- Ne rien inventer
- Signaler contradictions si présentes

---

### 2. Plan

Rôle joueur :

- 5 à 8 sections biographiques
- 3 à 5 objectifs prioritaires
- ≥5 relations si possible

---

### 3. Rédaction

- 1 bullet → 1 à 3 phrases
- Respect strict des faits
- Ordre logique uniquement
- Aucun ajout implicite

---

### 4. Anti-abstraction (critique dure)

Pour chaque phrase vérifier :

- acteur identifié ?
- action claire ?
- résultat compréhensible ?

Si NON → réécriture obligatoire

---

### 5. Test joueur (obligatoire)

Pour chaque section, vérifier :

> “Qu’est-ce que je fais avec cette information ?”

Si réponse non immédiate → corriger

---

### 6. Compression

- Supprimer répétitions
- Supprimer phrases faibles
- Supprimer transitions inutiles
- Supprimer phrases décoratives

---

### 7. Validation finale (bloquante)

Le texte est valide uniquement si :

- aucune métaphore
- aucune phrase abstraite
- aucune ambiguïté
- aucune phrase décorative
- chaque section est exploitable en jeu

Sinon → reprise complète

---

## ⚠️ Règles spécifiques GPT

### Interdiction de dérive stylistique

Ne jamais :

- embellir
- rendre plus littéraire
- ajouter des effets
- améliorer “le style” au détriment du sens

---

### Interdiction d’invention

Si une information est absente :

- ne pas compléter
- ne pas interpréter
- ne pas extrapoler
- rester strictement factuel

Si nécessaire → produire moins de texte

---

### Interdiction de narration

Le texte n’est PAS :

- une histoire
- un récit
- une ambiance
- une mise en scène

Le texte EST :

- un briefing
- un dossier opérationnel
- un guide de jeu

---

## ✅ Exemple de bon style


Tu travailles pour la maison Veth depuis 3 ans.
Tu gères les contrats entre Palyr et Il-Irion.
Depuis 6 mois, Halet bloque certains envois.
Il exige une commission non déclarée.
Tu refuses.
Tu dois décider avant la Convention.

---

## ❌ Exemple de mauvais style


Depuis quelque temps, une tension s’installe.
Tu sens que les règles changent.
Une ombre plane sur les échanges.

---

## 🎯 Règle finale

Si le texte ressemble à :

- un roman
- un texte littéraire
- une ambiance
- un texte d’auteur

→ MAUVAIS

Si le texte ressemble à :

- un briefing
- un plan d’action
- un document exploitable

→ BON

---

## 🔧 Mode d’utilisation recommandé

Ajouter systématiquement en début de prompt :


Mode strict.
Applique toutes les règles sans exception.
Tolérance zéro pour métaphores et abstraction.