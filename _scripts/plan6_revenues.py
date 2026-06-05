# -*- coding: utf-8 -*-
"""
Plan 6 - Implémentation des nouvelles sources de revenus UBI :
  1. Mouvements bancaires généralisés 398-547 (tableau compact par famille)
  2. 3 prêts intercités longs termes (intérêts annuels)
  3. Location de coffres (5 c/coffre/an, croissance 50->220)
  4. Cotisations des 5 cités fondatrices (5 × 4'000 c/an)
"""

from pathlib import Path
import re, random, math

# ─── CHEMINS ──────────────────────────────────────────────────────────────────
repo = Path(r"C:\Users\sebastien-dury\OneDrive - Kheops Technologies S.A\PERSO\GN\2026")
reg_path = repo / "Groupes" / "Banquiers - UBI" / "3 - Comptabilite" / "registre_Comptable_UBI_Archives.md"
meth_path = repo / "Contrats_et_Livres" / "Archives" / "methode_versement_archives.md"

# ─── FAMILLES ─────────────────────────────────────────────────────────────────
FAMILIES = [
    ("Maison Valdris",      "Il-Irion"),
    ("Maison Kaelthorne",   "Il-Irion"),
    ("Maison Aedris",       "Il-Irion"),
    ("Maison Halvaren",     "Il-Irion"),
    ("Maison Vandesse",     "Palyr"),
    ("Maison Keld",         "Palyr"),
    ("Maison Thorne",       "Arthas"),
    ("Maison Orist",        "Arthas"),
    ("Maison Halet",        "Ther-Félis"),
    ("Maison Forgecendre",  "Sfaal"),
]

# ─── PRÊTS INTERCITÉS ─────────────────────────────────────────────────────────
# (référence, cité, principal, taux %, début, fin)
LOANS = [
    ("PT-CC-430-001", "Ther-Félis",  80_000, 7.0, 430, 445),
    ("PT-CC-455-001", "Arthas",      60_000, 6.5, 455, 467),
    ("PT-CC-510-001", "Palyr",      100_000, 7.5, 510, 530),
]

# ─── PARAMÈTRES FIXES ─────────────────────────────────────────────────────────
COTISATION_PAR_CITE  = 4_000      # couronnes / cité / an
NB_CITES             = 5
COTISATION_ANNUELLE  = COTISATION_PAR_CITE * NB_CITES  # 20'000 c/an
TARIF_COFFRE         = 5           # c/coffre/an
COFFRES_START        = 50          # en 397
COFFRES_END          = 220         # à partir de 540
ANNEE_DEBUT          = 397
ANNEE_FIN            = 547

# ─── HELPERS ──────────────────────────────────────────────────────────────────
def fmt(n: int) -> str:
    return f"{int(n):,}".replace(",", "'")

def coffers_for(year: int):
    if year >= 540:
        n = COFFRES_END
    else:
        n = int(COFFRES_START + (year - ANNEE_DEBUT) / (540 - ANNEE_DEBUT) * (COFFRES_END - COFFRES_START))
    return n, n * TARIF_COFFRE

def loans_for(year: int):
    total, lines = 0, []
    for ref, city, principal, rate, start, end in LOANS:
        if start <= year <= end:
            interest = int(principal * rate / 100)
            total += interest
            lines.append(
                f"Intérêts prêt intercité {ref} ({city}, {fmt(principal)} couronnes à {rate} %) : {fmt(interest)} couronnes."
            )
    return total, lines

def movements_for(year: int):
    """Pour 397 : rien (tableau détaillé déjà présent). Pour 398+ : tableau compact annuel."""
    if year == ANNEE_DEBUT:
        return None, 1_024   # prime déjà dans le total 397 existant
    rng = random.Random(year * 7_919 + 314_159)
    # Base de dépôt croît de 8'000 en 397 à 13'000 en 547
    base = 8_000 + int((year - ANNEE_DEBUT) / (ANNEE_FIN - ANNEE_DEBUT) * 5_000)
    rows, total_prime = [], 0
    for fam, city in FAMILIES:
        dep  = (rng.randint(int(base * 0.75), int(base * 1.25)) // 100) * 100
        ret  = (rng.randint(int(dep  * 0.55), int(dep  * 0.85)) // 100) * 100
        prime = int(dep * 0.01)
        total_prime += prime
        rows.append((fam, city, dep, ret, prime))
    return rows, total_prime

# ─── LECTURE DU REGISTRE ──────────────────────────────────────────────────────
text  = reg_path.read_text(encoding="utf-8")
lines = text.splitlines()

year_pat = re.compile(r"^## (\d+)$")
year_positions = [(int(m.group(1)), i)
                  for i, l in enumerate(lines)
                  for m in [year_pat.match(l)] if m]

recap_idx = next((i for i, l in enumerate(lines) if l.startswith("## Récapitulatif général")), len(lines))

header = lines[:year_positions[0][1]]   # tout avant ## 397

sections = []
for idx, (year, pos) in enumerate(year_positions):
    end = year_positions[idx + 1][1] if idx + 1 < len(year_positions) else recap_idx
    sections.append((year, lines[pos:end]))

# ─── RECONSTRUCTION ───────────────────────────────────────────────────────────
total_pat   = re.compile(r"^Total revenus UBI (\d+) : ([0-9']+) couronnes\.")
prime_dep_p = re.compile(r"^Total primes UBI sur dépôts (\d+)")
loan_line_p = re.compile(r"^Intérêts prêt intercité")
coffre_p    = re.compile(r"^Location coffres")
cotis_p     = re.compile(r"^Cotisations cités fondatrices")

out            = header[:]
if out and out[-1] != "":
    out.append("")

# ── Bloc récapitulatif des prêts intercités (avant les années) ─────────────────
out += [
    "## Prêts intercités longs termes",
    "",
    "| Référence | Bénéficiaire | Principal | Taux | Durée | Intérêts annuels |",
    "|-----------|--------------|-----------|------|-------|-----------------|",
]
for ref, city, principal, rate, s, e in LOANS:
    interest = int(principal * rate / 100)
    out.append(f"| {ref} | {city} | {fmt(principal)} couronnes | {rate} % | {s}–{e} | {fmt(interest)} couronnes/an |")
out += ["", ""]

# ── Accumulateurs ──────────────────────────────────────────────────────────────
g_existing   = 0   # somme des totaux existants (contrats + 1024 primes 397)
g_primes_new = 0   # primes dépôts 398-547 (nouvelles)
g_loans      = 0
g_coffers    = 0
g_cotis      = 0

for year, sec in sections:
    # ── Récupère le total existant (contrats ± primes 397) ─────────────────────
    existing_total = 0
    for l in sec:
        m = total_pat.match(l)
        if m and int(m.group(1)) == year:
            existing_total = int(m.group(2).replace("'", ""))

    # ── Génère les nouvelles données ───────────────────────────────────────────
    move_rows, move_prime = movements_for(year)
    n_cof, cof_rev        = coffers_for(year)
    loan_total, loan_lines = loans_for(year)
    cotis_rev             = COTISATION_ANNUELLE

    # ── Reconstruit la section sans les lignes de total / additions ────────────
    new_sec = []
    for l in sec:
        if total_pat.match(l) and str(year) in l:    continue
        if prime_dep_p.match(l):                     continue
        if loan_line_p.match(l):                     continue
        if coffre_p.match(l):                        continue
        if cotis_p.match(l):                         continue
        new_sec.append(l)

    # Supprime les blancs de fin
    while new_sec and new_sec[-1].strip() == "":
        new_sec.pop()

    # ── Ajoute les mouvements (tableau compact pour 398+) ─────────────────────
    if year == ANNEE_DEBUT:
        # 397 : tableau détaillé déjà présent, prime 1'024 déjà dans existing_total
        # Rien à ajouter pour les mouvements
        additions = cof_rev + loan_total + cotis_rev
        new_total = existing_total + additions
    else:
        new_sec += [
            "",
            f"Mouvements bancaires classiques {year} :",
            "",
            "| Client | Cité | Dépôts annuels | Retraits annuels | Prime UBI |",
            "|--------|------|----------------|------------------|-----------|",
        ]
        for fam, city, dep, ret, prime in move_rows:
            new_sec.append(
                f"| {fam} | {city} | {fmt(dep)} couronnes | {fmt(ret)} couronnes | {fmt(prime)} couronnes |"
            )
        new_sec += [
            "",
            f"Total primes UBI sur dépôts {year} : {fmt(move_prime)} couronnes.",
        ]
        additions = move_prime + loan_total + cof_rev + cotis_rev
        new_total = existing_total + additions

    # ── Ajoute intérêts prêts intercités ──────────────────────────────────────
    for ll in loan_lines:
        new_sec.append(ll)

    # ── Ajoute location coffres ────────────────────────────────────────────────
    new_sec.append(f"Location coffres ({n_cof} coffres à 5 couronnes/an) : {fmt(cof_rev)} couronnes.")

    # ── Ajoute cotisations cités ───────────────────────────────────────────────
    new_sec.append(
        f"Cotisations cités fondatrices ({NB_CITES} cités × {fmt(COTISATION_PAR_CITE)} couronnes) : {fmt(cotis_rev)} couronnes."
    )

    # ── Total annuel ───────────────────────────────────────────────────────────
    new_sec += ["", f"Total revenus UBI {year} : {fmt(new_total)} couronnes.", ""]

    out.extend(new_sec)

    # ── Accumulateurs ──────────────────────────────────────────────────────────
    g_existing   += existing_total
    g_coffers    += cof_rev
    g_loans      += loan_total
    g_cotis      += cotis_rev
    if year != ANNEE_DEBUT:
        g_primes_new += move_prime

# Primes 397 déjà dans g_existing (= 1'024 c)
g_primes_total = g_primes_new + 1_024
# Droits de garde purs = g_existing - primes 397
g_droits = g_existing - 1_024
grand = g_droits + g_primes_total + g_loans + g_coffers + g_cotis

nb_annees = ANNEE_FIN - ANNEE_DEBUT + 1  # 151 ans

charges_annuelles = 22_500
charges_totales   = charges_annuelles * nb_annees
solde             = grand - charges_totales

# ─── RÉCAPITULATIF ────────────────────────────────────────────────────────────
out += [
    "## Récapitulatif général",
    "",
    f"Période couverte : {ANNEE_DEBUT}–{ANNEE_FIN} ({nb_annees} ans).",
    "",
    "| Source de revenus | Total cumulé |",
    "|-------------------|-------------|",
    f"| Droits de garde contrats et coûts prêts PB | {fmt(g_droits)} couronnes |",
    f"| Primes sur dépôts classiques (1 %) | {fmt(g_primes_total)} couronnes |",
    f"| Intérêts prêts intercités | {fmt(g_loans)} couronnes |",
    f"| Location de coffres (5 couronnes/coffre/an) | {fmt(g_coffers)} couronnes |",
    f"| Cotisations cités fondatrices (5 × 4'000 couronnes/an) | {fmt(g_cotis)} couronnes |",
    f"| **Total revenus UBI cumulés** | **{fmt(grand)} couronnes** |",
    "",
    "Charges annuelles estimées :",
    "",
    "| Poste | Annuel |",
    "|-------|--------|",
    "| 1 directeur général (personnage joueur, 100 couronnes/mois) | 1'200 couronnes |",
    "| 4 conseillers/banquiers joueurs (100 couronnes/mois) | 4'800 couronnes |",
    "| 15 gardes (50 couronnes/mois, nourris et logés) | 9'000 couronnes |",
    "| 5 commis et personnel non joueur (30 couronnes/mois) | 1'800 couronnes |",
    "| 1 conseiller senior / arbitre (200 couronnes/mois) | 2'400 couronnes |",
    "| Entretien forteresse et coffres | 2'500 couronnes |",
    "| Déplacements, opérations, sceau | 800 couronnes |",
    "| **Total charges annuelles** | **22'500 couronnes** |",
    "",
    f"- Revenus cumulés sur {nb_annees} ans : {fmt(grand)} couronnes",
    f"- Charges cumulées estimées : {fmt(charges_totales)} couronnes",
    f"- Solde indicatif : {fmt(abs(solde))} couronnes ({'excédent' if solde >= 0 else 'déficit'})",
    "",
    "Résultat : l'institution est viable sur la durée. La cotisation des cités fondatrices couvre "
    "l'essentiel des charges. Les prêts intercités génèrent des pics de revenus significatifs "
    "(+5'600 à +7'500 couronnes/an pendant leur durée). Les coffres et les dépôts familiaux "
    "assurent un socle de revenus réguliers. Les trois prêts intercités à eux seuls rapportent "
    f"{fmt(g_loans)} couronnes sur l'ensemble de la période.",
    "",
]

# ─── ÉCRITURE ─────────────────────────────────────────────────────────────────
reg_path.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
print(f"  Droits de garde contrats : {fmt(g_droits)} couronnes")
print(f"  Primes sur dépôts        : {fmt(g_primes_total)} couronnes")
print(f"  Prêts intercités         : {fmt(g_loans)} couronnes")
print(f"  Location coffres         : {fmt(g_coffers)} couronnes")
print(f"  Cotisations cités        : {fmt(g_cotis)} couronnes")
print(f"  ─────────────────────────────────────────────")
print(f"  TOTAL REVENUS            : {fmt(grand)} couronnes")
print(f"  Charges totales ({nb_annees} ans) : {fmt(charges_totales)} couronnes")
print(f"  SOLDE                    : {'+' if solde >= 0 else ''}{fmt(abs(solde))} couronnes ({'excédent' if solde >= 0 else 'déficit'})")
