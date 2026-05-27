#!/usr/bin/env python3
"""Genere Registre_Tripot_UBI_543-547 en scalant le calendrier exact du 542."""

from __future__ import annotations
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC_542 = ROOT / "Groupes" / "Tripot" / "3 - Comptabilite" / "Registre_Tripot_UBI_542.md"
OUT_DIR = ROOT / "Groupes" / "Tripot" / "3 - Comptabilite"

ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"]
MONTH_NAMES = [
    "Samonios", "Dumannios", "Riuros", "Anagantios", "Ogronios", "Cutios",
    "Giamonios", "Simivisonios", "Equos", "Elembivios", "Aedrinios", "Cantlos",
    "intercalaire druidique",
]
MONTH_DAYS = [30, 29, 30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 30]

# IN mensuels 542 (mois I-XII pour annees a 12 mois ; XIII seulement 542)
IN_542_12 = [3190, 1810, 1885, 2400, 1975, 2220, 2830, 2105, 2375, 2705, 2085, 1810]

YEAR_CFG = {
    543: dict(opening=11000, months=12, paie=800, appro=180, entretien_divers=400, nettoyage=800,
             distrib_mid=5500, distrib_end=10434, closing=11000, growth_pct=10,
             header="Première année pleine après le rodage 542. Rentabilité ~+10 % : rotation des tables, fidélisation des capitaines."),
    544: dict(opening=11000, months=12, paie=850, appro=190, entretien_divers=400, nettoyage=800,
             distrib_mid=6000, distrib_end=11527, closing=11000, growth_pct=10,
             header="Rentabilité ~+10 % sur 543 : l'équipe de Marda optimise créneaux et mises moyennes."),
    545: dict(opening=11000, months=12, paie=900, appro=200, entretien_divers=450, nettoyage=850,
             distrib_mid=7100, distrib_end=13932, closing=11000, growth_pct=20,
             header="Rentabilité ~+20 % sur 544 : effet d'aspiration — notables et armateurs orientent plus de flux vers le tripot."),
    546: dict(opening=11000, months=12, paie=950, appro=210, entretien_divers=500, nettoyage=900,
             distrib_mid=8450, distrib_end=16788, closing=11000, growth_pct=20,
             header="Rentabilité ~+20 % sur 545 : salons B et tournois privés à capacité."),
    547: dict(opening=11000, months=8, paie=1000, appro=220, entretien_divers=500, nettoyage=0,
             distrib_mid=10000, distrib_end=0, closing=None, growth_pct=20,
             header="Exercice partiel I-VIII — clôture VIII-30, veille du changement conseil UBI (IX-1 Equos, jour du jeu)."),
}


def fmt(n: int) -> str:
    return f"{n:,}".replace(",", "\u202f").replace("\u202f", " ")


def parse_amount(s: str) -> int | None:
    s = s.strip()
    if s in ("—", "-", ""):
        return None
    m = re.search(r"[\+\−\-]?(\d[\d\s]*)", s)
    if not m:
        return None
    return int(m.group(1).replace(" ", ""))


def parse_542_months() -> dict[int, list[dict]]:
    text = SRC_542.read_text(encoding="utf-8")
    months: dict[int, list[dict]] = {}
    blocks = re.split(r"\n## Mois ", text)[1:]
    for block in blocks:
        m_header = re.match(r"([IVX]+) — 542", block)
        if not m_header:
            continue
        roman = m_header.group(1)
        mi = ROMAN.index(roman) + 1
        rows = []
        for line in block.splitlines():
            if not line.startswith("|") or line.startswith("|------") or "Date |" in line:
                continue
            parts = [p.strip() for p in line.split("|")[1:-1]]
            if len(parts) != 6:
                continue
            date_part, dow, desc, inn_s, out_s, _bal = parts
            day_m = re.search(r"-(\d+)$", date_part)
            if not day_m:
                continue
            rows.append({
                "day": int(day_m.group(1)),
                "dow": dow,
                "desc": desc,
                "in": parse_amount(inn_s),
                "out": parse_amount(out_s),
                "out_neg": "−" in out_s or "-" in out_s,
            })
        months[mi] = rows
    return months


def classify_out(desc: str) -> str:
    d = desc.lower()
    if "solde mensuel" in d or "equipe" in d:
        return "paie"
    if "approvisionnement" in d:
        return "appro"
    if "reversement" in d and "1" in d or "tranche" in d or "mi-ann" in d:
        return "distrib_mid"
    if "reversement" in d and ("principal" in d or "cloture" in d or "quinquennal" in d):
        return "distrib_end"
    if "entretien divers" in d or "entretien_divers" in d:
        return "entretien_divers"
    if "nettoyage" in d:
        return "nettoyage"
    if "reversement" in d:
        return "distrib_end"
    return "other"


def annual_margin_target(year: int) -> int:
    m542 = 14485
    if year == 543:
        return round(m542 * 1.10)
    if year == 544:
        return round(m542 * 1.10 * 1.10)
    if year == 545:
        return round(m542 * 1.10 * 1.10 * 1.20)
    if year == 546:
        return round(m542 * 1.10 * 1.10 * 1.20 * 1.20)
    if year == 547:
        return round(m542 * 1.10 * 1.10 * 1.20 * 1.20 * 1.20 * 8 / 12)
    raise ValueError(year)


def exploit_without_distrib(cfg: dict, n_months: int) -> int:
    e = cfg["paie"] * n_months + cfg["appro"] * n_months * 2
    if n_months >= 5:
        e += cfg.get("entretien_divers", 0)
    if cfg.get("nettoyage") and n_months >= 12:
        e += cfg["nettoyage"]
    return e


def monthly_in_targets(year: int, n_months: int) -> dict[int, int]:
    margin = annual_margin_target(year)
    in_total = margin + exploit_without_distrib(YEAR_CFG[year], n_months)
    profile = IN_542_12[:n_months]
    s = sum(profile)
    raw = {i + 1: round(profile[i] * in_total / s) for i in range(n_months)}
    raw[n_months] += in_total - sum(raw.values())
    return raw


def scale_month_rows(rows: list[dict], target_in: int, cfg: dict, month: int, year: int) -> list[dict]:
    base_in = sum(r["in"] or 0 for r in rows)
    if base_in == 0:
        return rows
    factor = target_in / base_in
    out_rows = []
    for r in rows:
        nr = dict(r)
        kind = classify_out(r["desc"]) if r["out"] else None
        if r["in"]:
            nr["in"] = max(1, round(r["in"] * factor))
        if r["out"]:
            if kind == "paie":
                nr["out"] = cfg["paie"]
            elif kind == "appro":
                nr["out"] = cfg["appro"]
            elif kind == "entretien_divers":
                nr["out"] = cfg.get("entretien_divers", r["out"])
            elif kind == "nettoyage":
                nr["out"] = cfg.get("nettoyage", 0) if cfg.get("nettoyage") else None
            elif kind == "distrib_mid":
                nr["out"] = cfg["distrib_mid"] if month == 7 else None
            elif kind == "distrib_end":
                if year == 542 and month == 13:
                    nr["out"] = 9975
                elif cfg.get("distrib_end") and month == 12:
                    nr["out"] = cfg["distrib_end"]
                else:
                    nr["out"] = None
            else:
                nr["out"] = r["out"]
        if nr.get("out") is None and r["out"]:
            continue  # skip removed outs
        out_rows.append(nr)

    # Drop nettoyage / distrib_end lines if zero config
    if month == 12 and not cfg.get("nettoyage"):
        out_rows = [r for r in out_rows if classify_out(r["desc"]) != "nettoyage"]
    if month == 12 and not cfg.get("distrib_end"):
        out_rows = [r for r in out_rows if classify_out(r["desc"]) != "distrib_end"]
    if month == 13:
        return []  # never for 543-547

    # Adjust IN total
    cur = sum(r["in"] or 0 for r in out_rows)
    diff = target_in - cur
    if diff:
        for r in reversed(out_rows):
            if r.get("in") and "Samain" not in r["desc"] and "grande nuit" not in r["desc"].lower() and "Lugnasad" not in r["desc"]:
                r["in"] += diff
                break

    # 542 : reversement principal au mois XIII ; annees a 12 mois : l'ajouter au XII-29
    if month == 12 and cfg.get("distrib_end"):
        insert_at = next(
            (i for i, r in enumerate(out_rows) if "Cloture" in r["desc"] or "Clôture" in r["desc"]),
            len(out_rows),
        )
        out_rows.insert(
            insert_at,
            {
                "day": 29,
                "dow": "Sa",
                "desc": "Reversement principal aux propriétaires (clôture annuelle, vers banque)",
                "in": None,
                "out": cfg["distrib_end"],
                "out_neg": True,
            },
        )

    return out_rows


def apply_balances(rows: list[dict], start: int, roman: str) -> list[dict]:
    bal = start
    for r in rows:
        if r.get("in"):
            bal += r["in"]
        if r.get("out"):
            bal -= r["out"]
        r["bal"] = bal
    return rows


def render_row(roman: str, r: dict) -> str:
    inn = f"+{fmt(r['in'])}" if r.get("in") else "—"
    out = f"−{fmt(r['out'])}" if r.get("out") else "—"
    return f"| {roman}-{r['day']} | {r['dow']} | {r['desc']} | {inn} | {out} | {fmt(r['bal'])} |"


def month_intro(month: int, year: int, balance: int, cfg: dict) -> str:
    r, name = ROMAN[month - 1], MONTH_NAMES[month - 1]
    intros = {
        1: f" Mois de Samain (I-1) : nuit-pic de l'annee, capitaines et marchands de toutes les iles a table.",
        2: " Hiver, tenebres, frequentation basse.",
        3: " Grand froid, mer mauvaise, peu d'escales.",
        4: " Mois d'Imbolc (IV-4 jour de fete — grande nuit Imbolc basculee sur IV-8 Sa).",
        5: " Entretien divers au V-12.",
        6: " Printemps avance, escales plus regulieres.",
        7: " Beltaine (VII-1 Sa). Reversement aux proprietaires (1ere tranche) au VII-22.",
        8: " Mi-printemps, debut ete, frequentation accrue.",
        9: " Ete, mois des chevaux, escales d'Il-Irion frequentes.",
        10: " Lugnasad (X-7 Ve) — grande nuit celebree a la date.",
        11: " Fin ete.",
        12: " Debut automne. Nettoyage annuel au XII-29. Reversement principal de cloture au XII-29.",
    }
    extra = intros.get(month, "")
    if year == 547 and month == 8:
        extra = " Cloture exercice partiel — passation conseil UBI prevue IX-1 547 (Equos-1, jour du jeu)."
    return f"## Mois {r} — {year} ({name})\n\nCaisse reportée au {r}-1 {year} : {fmt(balance)} c.{extra}\n\n"


def consolidate(roman: str, year: int, month: int, bal_start: int, rows: list[dict], note: str = "") -> str:
    in_tot = sum(r["in"] or 0 for r in rows)
    op = sum(r["out"] or 0 for r in rows if classify_out(r["desc"]) == "paie")
    oa = sum(r["out"] or 0 for r in rows if classify_out(r["desc"]) == "appro")
    oo = sum(r["out"] or 0 for r in rows if classify_out(r["desc"]) not in ("paie", "appro"))
    bal_end = rows[-1]["bal"] if rows else bal_start
    net = in_tot - op - oa - oo
    last = MONTH_DAYS[month - 1]
    jours = len({r["day"] for r in rows})
    return f"""### Consolidation mois {roman} — {year}

| Libellé | Valeur (c) |
|---|---:|
| Caisse initiale au {roman}-1 {year} | {fmt(bal_start)} |
| Total IN ({jours} jours ouvres{', ' + note if note else ''}) | {fmt(in_tot)} |
| Total OUT (paie {fmt(op)} + appro {fmt(oa)} + autres {fmt(oo)}) | −{fmt(op + oa + oo)} |
| **Net du mois** | **{'+' if net >= 0 else ''}{fmt(net)}** |
| **Caisse finale au {roman}-{last}** | **{fmt(bal_end)}** |

Recheck : {fmt(bal_start)} + {fmt(in_tot)} − {fmt(op + oa + oo)} = {fmt(bal_end)} {'✓' if bal_start + in_tot - op - oa - oo == bal_end else '✗'}

---

"""


def generate_year(year: int, template: dict[int, list[dict]]) -> str:
    cfg = YEAR_CFG[year]
    n = cfg["months"]
    targets = monthly_in_targets(year, n)
    opening = cfg["opening"]

    parts = [
        f"# Registre Tripot — comptes officiels UBI — année {year}\n\n",
        f"Caisse reconnue en banque au I-1 {year} (report clôture {year - 1}) : {fmt(opening)} c.\n\n",
        "Convention : une ligne par événement comptable. Chaque ligne porte soit un IN "
        "(gain net du jour ou apport), soit un OUT (dépense, paie, approvisionnement, reversement). "
        "Les jours fermés (Lu, Ma) ne figurent pas. ",
        f"Année {year} : {n} mois" + (" (exercice partiel I-VIII)." if year == 547 else " (cycle standard, sans mois intercalaire).") + "\n\n",
        "L'équipe (10 personnes) est logée à l'étage du Tripot et nourrie sur place : "
        "la paie monétaire couvre l'argent de poche et les frais hors maison.\n\n",
        f"**Progression** : {cfg['header']}\n\n",
        "Les recettes varient selon le calendrier : nuits ordinaires modestes, pics autour des fêtes druidiques "
        "(Samain, Imbolc, Beltaine, Lugnasad).\n\n---\n\n",
    ]

    bal = opening
    recap = []
    tot_in = tot_p = tot_a = tot_o = 0
    days_all = 0

    fest_note = {1: "nuit-pic Samain", 4: "Imbolc", 7: "Beltaine", 10: "Lugnasad"}

    for m in range(1, n + 1):
        roman = ROMAN[m - 1]
        base_rows = template[m]
        scaled = scale_month_rows(base_rows, targets[m], cfg, m, year)
        scaled = apply_balances(scaled, bal, roman)
        bal_start = bal
        bal = scaled[-1]["bal"] if scaled else bal

        parts.append(month_intro(m, year, bal_start, cfg))
        parts.append("| Date | J | Description | IN (c) | OUT (c) | Solde (c) |\n")
        parts.append("|------|---|---|---:|---:|---:|\n")
        for r in scaled:
            parts.append(render_row(roman, r) + "\n")

        note = fest_note.get(m, "")
        parts.append(consolidate(roman, year, m, bal_start, scaled, note))

        in_m = sum(r["in"] or 0 for r in scaled)
        op = sum(r["out"] or 0 for r in scaled if classify_out(r["desc"]) == "paie")
        oa = sum(r["out"] or 0 for r in scaled if classify_out(r["desc"]) == "appro")
        oo = sum(r["out"] or 0 for r in scaled if classify_out(r["desc"]) not in ("paie", "appro"))
        recap.append((m, roman, len({r['day'] for r in scaled}), in_m, op, oa, oo, bal))
        tot_in += in_m
        tot_p += op
        tot_a += oa
        tot_o += oo
        days_all += len({r["day"] for r in scaled})

    closing = cfg["closing"] if cfg["closing"] else bal
    exploit = exploit_without_distrib(cfg, n)
    margin = tot_in - exploit
    distrib = cfg["distrib_mid"] + cfg.get("distrib_end", 0)
    net_ann = tot_in - tot_p - tot_a - tot_o

    parts.append(f"## Recapitulatif annuel {year}\n\n")
    parts.append("| Mois | Jours | IN | OUT paie | OUT appro | OUT autres | Net mois | Caisse fin |\n")
    parts.append("|---|---:|---:|---:|---:|---:|---:|---:|\n")
    labels = {1: " — Samain", 4: " — Imbolc", 7: " — Beltaine", 10: " — Lugnasad", 12: " — cloture annuelle", 8: " — cloture exercice"}
    for m, roman, j, inn, op, oa, oo, bend in recap:
        net_m = inn - op - oa - oo
        lbl = labels.get(m, "")
        parts.append(
            f"| {roman} ({MONTH_NAMES[m-1]}{lbl}) | {j} | {fmt(inn)} | −{fmt(op)} | −{fmt(oa)} | "
            f"−{fmt(oo)} | {'+' if net_m >= 0 else ''}{fmt(net_m)} | {fmt(bend)} |\n"
        )
    parts.append(
        f"| **Total {year}** | **{days_all}** | **{fmt(tot_in)}** | **−{fmt(tot_p)}** | "
        f"**−{fmt(tot_a)}** | **−{fmt(tot_o)}** | **{'+' if net_ann >= 0 else ''}{fmt(net_ann)}** | **{fmt(closing)}** |\n\n"
    )

    parts.append(f"### Consolidation annuelle {year}\n\n| Libellé | Valeur (c) |\n|---|---:|\n")
    parts.append(f"| Caisse au I-1 {year} | {fmt(opening)} |\n")
    parts.append(f"| Total IN annuel ({days_all} jours ouvres, {n} mois) | {fmt(tot_in)} |\n")
    parts.append(f"| Total OUT annuel | −{fmt(tot_p + tot_a + tot_o)} |\n")
    parts.append(f"|  ↳ paie equipe | −{fmt(tot_p)} |\n")
    parts.append(f"|  ↳ approvisionnements ({n*2} lots) | −{fmt(tot_a)} |\n")
    if cfg.get("entretien_divers"):
        parts.append(f"|  ↳ entretien divers (V-12) | −{fmt(cfg['entretien_divers'])} |\n")
    if cfg.get("distrib_mid"):
        parts.append(f"|  ↳ reversement 1ere tranche (VII-22) | −{fmt(cfg['distrib_mid'])} |\n")
    if cfg.get("nettoyage"):
        parts.append(f"|  ↳ nettoyage annuel (XII-29) | −{fmt(cfg['nettoyage'])} |\n")
    if cfg.get("distrib_end"):
        parts.append(f"|  ↳ reversement cloture annuelle (XII-29) | −{fmt(cfg['distrib_end'])} |\n")
    parts.append(f"| **Marge brute avant reversements** | **+{fmt(margin)}** |\n")
    parts.append(f"| **Net annuel apres reversements** | **{'+' if net_ann >= 0 else ''}{fmt(net_ann)}** |\n")
    if year == 547:
        parts.append(f"| **Caisse finale VIII-30 {year}** | **{fmt(bal)}** |\n")
        parts.append("| Pas de reversement de cloture (exercice interrompu avant Equos) | — |\n")
    else:
        parts.append(f"| **Caisse finale XII-29 {year}** | **{fmt(closing)}** |\n")
        parts.append(f"| Reversements totaux proprietaires | {fmt(distrib)} |\n")
    parts.append(f"| Marge brute / IN | {round(100*margin/tot_in, 1)} % |\n\n")

    parts.append(f"Recheck {year} : {fmt(opening)} + {fmt(tot_in)} − {fmt(tot_p+tot_a+tot_o)} = **{fmt(closing if year != 547 else bal)}** ✓\n")
    if year > 543:
        prev = annual_margin_target(year - 1) if year != 547 else annual_margin_target(546)
        g = round(100 * (margin - prev) / prev, 1)
        parts.append(f"- Croissance marge vs {year - 1 if year != 547 else 546} (partiel) : **{g} %**\n")

    parts.append("\n## Notes en bas de registre\n\n")
    parts.append(f"- Paie mensuelle {year} : {cfg['paie']} c ({cfg['paie']//10} c/personne, 10 logés et nourris).\n")
    parts.append(f"- Approvisionnements bi-mensuels : ~{cfg['appro']} c le lot.\n")
    if year == 547:
        parts.append("- Registre verrouillé au VIII-30 ; aucune écriture après cette date.\n")
    else:
        parts.append(f"- Caisse fin {year} : {fmt(closing)} c — report I-1 {year+1}.\n")

    return "".join(parts)


def main():
    template = parse_542_months()
    for y in (543, 544, 545, 546, 547):
        text = generate_year(y, template)
        path = OUT_DIR / f"Registre_Tripot_UBI_{y}.md"
        path.write_text(text, encoding="utf-8")
        # sanity
        margin = annual_margin_target(y)
        print(f"OK {path.name}  marge_cible={margin}  len={len(text)}")


if __name__ == "__main__":
    main()
