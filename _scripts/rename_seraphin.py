# -*- coding: utf-8 -*-
"""
Remplace "Seraphine" par "Seraphin" dans tous les fichiers concernés,
corrige les accords féminins devenus faux, et renomme le fichier joueur.
"""

from pathlib import Path

ROOT = Path(r"C:\Users\sebastien-dury\OneDrive - Kheops Technologies S.A\PERSO\GN\2026")

# ─── 1. REMPLACEMENT DU NOM PARTOUT ──────────────────────────────────────────
# Liste des fichiers où "Seraphine" doit devenir "Seraphin"
name_files = [
    ROOT / "Groupes" / "Fiche_interactions_tous_groupes.md",
    ROOT / "Groupes" / "Banquiers - UBI" / "interactions du groupe UBI.md",
    ROOT / "Groupes" / "Banquiers - UBI" / "2 - Roles des Joueurs" / "vengeance_Edorian" / "faux_contrat_VIP_Kaelthorne_Valdris.md",
    ROOT / "Groupes" / "Banquiers - UBI" / "2 - Roles des Joueurs" / "vengeance_Edorian" / "lettre_Ther-Felis_contre_Aedris.md",
    ROOT / "Groupes" / "Banquiers - UBI" / "2 - Roles des Joueurs" / "vengeance_Edorian" / "lettre_Arthas_contre_Kaelthorne.md",
    ROOT / "Groupes" / "Banquiers - UBI" / "2 - Roles des Joueurs" / "vengeance_Edorian" / "lettre_Palyr_contre_Valdris.md",
    ROOT / "Groupes" / "Afaire.md",
    ROOT / "Groupes" / "Tripot" / "2 - Roles des Joueurs" / "Tripot_Ysabeau_Hotesse.md",
    ROOT / "Groupes" / "Palyr" / "2 - Roles des Joueurs" / "Palyr_Ilara_Vandesse_Diplomate.md",
    ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Isar_Dornelis.md",
    ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "README.md",
    ROOT / "Groupes" / "Il-Irion" / "1 - Back de groupe" / "Back_groupe_Il-Irion.md",
    ROOT / "Intrigues" / "Intrigue_Il-Irion.md",
    ROOT / "Intrigues" / "Intrigue_Banquiers.md",
    ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Marek_Thorne.md",
    ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Seraphine_Kaelthorne.md",
    ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Calis_Aedris.md",
]

def replace_in_file(path: Path, old: str, new: str) -> int:
    if not path.exists():
        print(f"  MANQUANT : {path}")
        return 0
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count:
        path.write_text(text.replace(old, new), encoding="utf-8", newline="\n")
    return count

total_name = 0
for f in name_files:
    n = replace_in_file(f, "Seraphine", "Seraphin")
    if n:
        print(f"  [{n}] {f.name}")
    total_name += n
print(f"Nom remplacé : {total_name} occurrences au total.\n")

# ─── 2. CORRECTIONS D'ACCORDS FÉMININS ───────────────────────────────────────
# Lettre Arthas contre Kaelthorne
p = ROOT / "Groupes" / "Banquiers - UBI" / "2 - Roles des Joueurs" / "vengeance_Edorian" / "lettre_Arthas_contre_Kaelthorne.md"
fixes = [
    ("Les familles disent qu'elle surveille les taux. En réalité, elle a organisé",
     "Les familles disent qu'il surveille les taux. En réalité, il a organisé"),
    ("il ne la dénoncera pas", "il ne le dénoncera pas"),
    ("où elle intervient. Si elle accuse Edorian (UBI) seul, exigez qu'elle produise le registre de secours qu'elle garde pour sa maison.",
     "où il intervient. S'il accuse Edorian (UBI) seul, exigez qu'il produise le registre de secours qu'il garde pour sa maison."),
]
for old, new in fixes:
    n = replace_in_file(p, old, new)
    print(f"  Arthas lettre [{n}] : {old[:50]}...")

# Lettre Palyr contre Valdris
p = ROOT / "Groupes" / "Banquiers - UBI" / "2 - Roles des Joueurs" / "vengeance_Edorian" / "lettre_Palyr_contre_Valdris.md"
n = replace_in_file(p, "elle tient les taux, mais Valdris tient la façade diplomatique.",
                       "il tient les taux, mais Valdris tient la façade diplomatique.")
print(f"  Palyr lettre [{n}] : elle→il tient les taux")

# Tripot Ysabeau
p = ROOT / "Groupes" / "Tripot" / "2 - Roles des Joueurs" / "Tripot_Ysabeau_Hotesse.md"
n = replace_in_file(p,
    "Elle mesure les dettes avant les personnes. Si elle s'intéresse à une perte de salon, demande-toi qui sera tenu de payer.",
    "Il mesure les dettes avant les personnes. S'il s'intéresse à une perte de salon, demande-toi qui sera tenu de payer.")
print(f"  Tripot Ysabeau [{n}] : Elle→Il mesure / Si elle→S'il s'intéresse")

# Palyr Ilara Vandesse
p = ROOT / "Groupes" / "Palyr" / "2 - Roles des Joueurs" / "Palyr_Ilara_Vandesse_Diplomate.md"
n = replace_in_file(p,
    "Seraphin Kaelthorne tient les finances d'Il-Irion, les taux et les dettes inter-îles. Elle peut présenter Palyr comme une cité qui attaque la banque pour éviter ses propres coûts.",
    "Seraphin Kaelthorne tient les finances d'Il-Irion, les taux et les dettes inter-îles. Il peut présenter Palyr comme une cité qui attaque la banque pour éviter ses propres coûts.")
print(f"  Palyr Ilara [{n}] : Elle→Il peut présenter")

# Interactions UBI
p = ROOT / "Groupes" / "Banquiers - UBI" / "interactions du groupe UBI.md"
n = replace_in_file(p,
    "Tu cites Seraphin comme ligne fortunes et arrangements côté maisons. Elle entre dans les opérations que tu dois boucler ou désamorcer avant le conseil suivant.",
    "Tu cites Seraphin comme ligne fortunes et arrangements côté maisons. Il entre dans les opérations que tu dois boucler ou désamorcer avant le conseil suivant.")
print(f"  Interactions UBI [{n}] : Elle→Il entre")

# Fiche interactions tous groupes
p = ROOT / "Groupes" / "Fiche_interactions_tous_groupes.md"
n = replace_in_file(p,
    "elle entre dans les opérations à boucler avant le conseil suivant.",
    "il entre dans les opérations à boucler avant le conseil suivant.")
print(f"  Fiche interactions [{n}] : elle→il entre")

# Back joueur Seraphin - "pour toi seule" → "pour toi seul"
p = ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Seraphin_Kaelthorne.md"
if not p.exists():
    # Fichier pas encore renommé, utilise l'ancien nom
    p_old = p.parent / "back_joueur_Seraphine_Kaelthorne.md"
    if p_old.exists():
        p = p_old
n = replace_in_file(p, "pour toi seule.", "pour toi seul.")
print(f"  Back Seraphin [{n}] : toi seule→toi seul")

print()

# ─── 3. RENOMMAGE DU FICHIER JOUEUR ──────────────────────────────────────────
old_path = ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Seraphine_Kaelthorne.md"
new_path = ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Seraphin_Kaelthorne.md"
if old_path.exists():
    old_path.rename(new_path)
    print(f"Fichier renommé : back_joueur_Seraphine_Kaelthorne.md → back_joueur_Seraphin_Kaelthorne.md")
elif new_path.exists():
    print(f"Fichier déjà renommé : {new_path.name}")
else:
    print(f"INTROUVABLE : {old_path}")

# Mettre à jour la référence dans README.md
readme = ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "README.md"
n = replace_in_file(readme, "back_joueur_Seraphine_Kaelthorne.md", "back_joueur_Seraphin_Kaelthorne.md")
print(f"README.md mis à jour [{n}] : référence fichier corrigée")

print("\nTerminé.")
