# -*- coding: utf-8 -*-
"""Suite des corrections gender + renommage fichier."""
from pathlib import Path

ROOT = Path(r"C:\Users\sebastien-dury\OneDrive - Kheops Technologies S.A\PERSO\GN\2026")

def fix(path, old, new):
    if not path.exists():
        print(f"  MANQUANT : {path.name}")
        return 0
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count:
        path.write_text(text.replace(old, new), encoding="utf-8", newline="\n")
    print(f"  [{count}] {path.name}")
    return count

# Palyr lettre
fix(ROOT / "Groupes" / "Banquiers - UBI" / "2 - Roles des Joueurs" / "vengeance_Edorian" / "lettre_Palyr_contre_Valdris.md",
    "elle tient les taux, mais Valdris tient la facade diplomatique.",
    "il tient les taux, mais Valdris tient la facade diplomatique.")
# variante avec accent
fix(ROOT / "Groupes" / "Banquiers - UBI" / "2 - Roles des Joueurs" / "vengeance_Edorian" / "lettre_Palyr_contre_Valdris.md",
    "elle tient les taux, mais Valdris tient la fa\u00e7ade diplomatique.",
    "il tient les taux, mais Valdris tient la fa\u00e7ade diplomatique.")

# Tripot Ysabeau
fix(ROOT / "Groupes" / "Tripot" / "2 - Roles des Joueurs" / "Tripot_Ysabeau_Hotesse.md",
    "Elle mesure les dettes avant les personnes. Si elle s'int\u00e9resse \u00e0 une perte de salon, demande-toi qui sera tenu de payer.",
    "Il mesure les dettes avant les personnes. S'il s'int\u00e9resse \u00e0 une perte de salon, demande-toi qui sera tenu de payer.")

# Palyr Ilara
fix(ROOT / "Groupes" / "Palyr" / "2 - Roles des Joueurs" / "Palyr_Ilara_Vandesse_Diplomate.md",
    "Seraphin Kaelthorne tient les finances d'Il-Irion, les taux et les dettes inter-\u00eeles. Elle peut pr\u00e9senter Palyr comme une cit\u00e9 qui attaque la banque pour \u00e9viter ses propres co\u00fbts.",
    "Seraphin Kaelthorne tient les finances d'Il-Irion, les taux et les dettes inter-\u00eeles. Il peut pr\u00e9senter Palyr comme une cit\u00e9 qui attaque la banque pour \u00e9viter ses propres co\u00fbts.")

# Interactions UBI
fix(ROOT / "Groupes" / "Banquiers - UBI" / "interactions du groupe UBI.md",
    "Tu cites Seraphin comme ligne fortunes et arrangements c\u00f4t\u00e9 maisons. Elle entre dans les op\u00e9rations que tu dois boucler ou d\u00e9samorcer avant le conseil suivant.",
    "Tu cites Seraphin comme ligne fortunes et arrangements c\u00f4t\u00e9 maisons. Il entre dans les op\u00e9rations que tu dois boucler ou d\u00e9samorcer avant le conseil suivant.")

# Fiche interactions tous groupes
fix(ROOT / "Groupes" / "Fiche_interactions_tous_groupes.md",
    "elle entre dans les op\u00e9rations \u00e0 boucler avant le conseil suivant.",
    "il entre dans les op\u00e9rations \u00e0 boucler avant le conseil suivant.")

# Back Seraphin : seule -> seul
# Le fichier a deja ete renomme ou pas encore ?
p_new = ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Seraphin_Kaelthorne.md"
p_old = ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "back_joueur_Seraphine_Kaelthorne.md"
p_back = p_new if p_new.exists() else p_old
fix(p_back, "pour toi seule.", "pour toi seul.")

# Renommage
if p_old.exists() and not p_new.exists():
    p_old.rename(p_new)
    print("Fichier renomme : back_joueur_Seraphine -> back_joueur_Seraphin")
elif p_new.exists():
    print("Fichier deja renomme OK")
else:
    print("Introuvable !")

# README
readme = ROOT / "Groupes" / "Il-Irion" / "2 - Roles des Joueurs" / "README.md"
fix(readme, "back_joueur_Seraphine_Kaelthorne.md", "back_joueur_Seraphin_Kaelthorne.md")

print("Termine.")
