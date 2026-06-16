# -*- coding: utf-8 -*-
import re
from pathlib import Path

repo = Path(r"C:\Users\sebastien-dury\OneDrive - Kheops Technologies S.A\PERSO\GN\2026")
reg = repo / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "registre_Comptable_UBI_Archives.md"
text = reg.read_text(encoding="utf-8")

annees = re.findall(r"^## (\d+)$", text, re.M)
print(f"Sections annee    : {len(annees)} (de {annees[0]} a {annees[-1]})")

totaux = [(int(a), int(v.replace("'", ""))) for a, v in re.findall(r"Total revenus UBI (\d+) : ([0-9']+) couronnes", text)]
print(f"Totaux annuels    : {len(totaux)}")

for y in [397, 430, 510, 547]:
    vals = [v for a, v in totaux if a == y]
    print(f"  Total {y}       : {vals[0] if vals else 'MANQUANT':>10}")

grand = sum(v for _, v in totaux)
print(f"Grand total       : {grand:>12,}".replace(",", "'"))

corrompus = text.count("\ufffd")
print(f"Chars corrompus   : {corrompus}")
print(f"Lignes totales    : {len(text.splitlines())}")

nb_cotis = text.count("Cotisations")
nb_coffres = text.count("Location coffres")
nb_pret_ic = text.count("Interets pret intercite") + text.count("Int\u00e9r\u00eats pr\u00eat intercit\u00e9")
print(f"Lignes cotisation : {nb_cotis}")
print(f"Lignes coffres    : {nb_coffres}")
print(f"Lignes prets IC   : {nb_pret_ic}")

# Comparer avec le recap
recap_m = re.search(r"Total revenus UBI cumul.*?\*\*([0-9']+) couronnes\*\*", text)
if recap_m:
    recap_val = int(recap_m.group(1).replace("'", ""))
    print(f"\nRecap total fichier : {recap_val:>12,}".replace(",", "'"))
    diff = abs(grand - recap_val)
    print(f"Ecart vs grand total: {diff:>12,} {'OK' if diff == 0 else 'ERREUR'}".replace(",", "'"))
