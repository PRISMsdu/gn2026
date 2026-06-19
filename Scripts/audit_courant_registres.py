#!/usr/bin/env python3
"""Audit croise contrats courants vs registres UBI, compta et orga."""

from __future__ import annotations

import csv
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRATS_DIR = ROOT / "Contrats_et_Livres"
REG_CONTRATS = ROOT / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "registre_UBI_Contrats_courant.md"
REG_COMPTA = ROOT / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "registre_Comptable_UBI_courant.md"
REG_ORGA = ROOT / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "Registre_UBI_Orga.csv"

REF_RE = re.compile(r"^[A-Z]{2,3}-[IV]+-\d{3}-\d{3}$")
REF_IN_TABLE = re.compile(r"\|\s*([A-Z]{2,3}-[IV]+-\d{3}-\d{3})\s*\|")
SKIP_MD = {"README"}
SKIP_MD_PREFIX = "_template_"
NON_RENSEIGNE = re.compile(r"non\s+renseign", re.I)


def parse_amount(s: str | None) -> int | None:
    if not s:
        return None
    s = s.strip()
    if NON_RENSEIGNE.search(s):
        return None
    sl = s.lower()
    if sl in ("—", "-", ""):
        return None
    if re.fullmatch(r"0\s+couronnes?", sl):
        return 0
    m = re.search(r"([\d\s'\u2019]+)", s.replace("\u2019", "'"))
    if not m:
        return None
    return int(m.group(1).replace("'", "").replace("\u2019", "").replace(" ", ""))


def expected_droit(ref: str, montant: int | None, typ: str) -> int | None:
    if montant is None:
        return None
    # Forfait enregistrement scellé / paraphe (montant déclaré nul)
    if montant == 0:
        if ref.startswith(("PAR-I-", "CH-II-", "CC-II-", "MN-II-", "DF-II-")):
            return 50
        return 0
    if ref.startswith("PB-"):
        return round(montant * 0.04)
    return round(montant * 0.02)


def load_md_refs() -> set[str]:
    refs: set[str] = set()
    for p in CONTRATS_DIR.glob("*.md"):
        if p.stem in SKIP_MD or p.stem.startswith(SKIP_MD_PREFIX):
            continue
        if REF_RE.match(p.stem):
            refs.add(p.stem)
    return refs


def load_registre_contrats() -> tuple[list[str], dict[str, dict]]:
    text = REG_CONTRATS.read_text(encoding="utf-8")
    refs: list[str] = [m.group(1) for m in REF_IN_TABLE.finditer(text)]
    data: dict[str, dict] = {}
    for line in text.splitlines():
        if not line.startswith("|") or "Référence" in line or "---" in line:
            continue
        parts = [p.strip() for p in line.split("|")[1:-1]]
        if len(parts) >= 8 and REF_RE.match(parts[0]):
            data[parts[0]] = {
                "type": parts[1],
                "parties": parts[2],
                "montant_raw": parts[3],
                "droit_raw": parts[4],
                "montant": parse_amount(parts[3]),
                "droit": parse_amount(parts[4]),
                "depot": parts[5],
                "exec": parts[6],
                "statut": parts[7],
            }
    return refs, data


def load_compta() -> tuple[list[str], dict[str, dict]]:
    text = REG_COMPTA.read_text(encoding="utf-8")
    refs: list[str] = []
    data: dict[str, dict] = {}
    for line in text.splitlines():
        if not line.startswith("|") or "Référence contrat" in line or "---" in line:
            continue
        parts = [p.strip() for p in line.split("|")[1:-1]]
        if len(parts) >= 6 and REF_RE.match(parts[0]):
            ref = parts[0]
            refs.append(ref)
            data[ref] = {
                "montant": parse_amount(parts[4]),
                "revenu": parse_amount(parts[5]),
            }
    return refs, data


def load_orga_courant() -> dict[str, dict]:
    out: dict[str, dict] = {}
    with REG_ORGA.open(encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f, delimiter=";"):
            if row.get("periode") != "courant":
                continue
            ref = row.get("reference", "")
            if not REF_RE.match(ref):
                continue
            out[ref] = {
                "montant": parse_amount(row.get("montant", "")),
                "droit": parse_amount(row.get("droit_ubi_paye", "")),
                "source": row.get("source_registre", ""),
                "statut": row.get("statut", ""),
            }
    return out


def check_csv_columns() -> list[tuple[int, int]]:
    lines = REG_ORGA.read_text(encoding="utf-8-sig").splitlines()
    ncols = len(lines[0].split(";"))
    bad: list[tuple[int, int]] = []
    for i, line in enumerate(lines[1:], start=2):
        if ";courant;" not in line:
            continue
        n = len(line.split(";"))
        if n != ncols:
            bad.append((i, n))
    return bad


def main() -> None:
    md = load_md_refs()
    reg_list, reg = load_registre_contrats()
    reg_set = set(reg_list)
    compta_list, compta = load_compta()
    compta_set = set(compta_list)
    orga = load_orga_courant()
    orga_set = set(orga)
    csv_bad = check_csv_columns()

    print("=== EFFECTIFS ===")
    print(f"Fichiers MD courants (Contrats_et_Livres) : {len(md)}")
    print(f"Registre contrats (refs uniques)          : {len(reg_set)} (lignes {len(reg_list)})")
    print(f"Registre compta (contrats courants)       : {len(compta_set)} (lignes {len(compta_list)})")
    print(f"Orga CSV periode=courant                  : {len(orga_set)}")

    if csv_bad:
        print(f"\n=== CSV colonnes cassees (courant) : {len(csv_bad)} ===")
        for row, n in csv_bad[:15]:
            print(f"  L{row}: {n} colonnes")

    dupes = [r for r, c in Counter(reg_list).items() if c > 1]
    if dupes:
        print(f"\nDOUBLONS registre contrats : {len(dupes)}")
        for r in dupes:
            print(f"  {r}")

    sections = [
        ("MD sans registre contrats", sorted(md - reg_set)),
        ("Registre contrats sans MD", sorted(reg_set - md)),
        ("Contrats sans ligne compta", sorted(reg_set - compta_set)),
        ("Compta sans registre contrats", sorted(compta_set - reg_set)),
        ("Contrats sans orga courant", sorted(reg_set - orga_set)),
        ("Orga courant sans registre contrats", sorted(orga_set - reg_set)),
    ]
    for title, items in sections:
        print(f"\n=== {title} : {len(items)} ===")
        for r in items[:30]:
            extra = ""
            if r in reg:
                extra = f" | statut={reg[r]['statut']}"
            print(f"  {r}{extra}")
        if len(items) > 30:
            print(f"  ... +{len(items) - 30} autres")

    bad_droit: list[tuple] = []
    for ref, d in reg.items():
        m, dr = d["montant"], d["droit"]
        exp = expected_droit(ref, m, d["type"])
        if dr is None:
            continue  # non renseigne volontaire
        if exp is not None and exp != dr:
            bad_droit.append((ref, m, dr, exp, d["montant_raw"], d["droit_raw"]))

    print(f"\n=== DROIT UBI registre contrats : {len(bad_droit)} ecarts ===")
    for x in bad_droit:
        print(f"  {x}")

    mismatches: list[tuple] = []
    for ref in sorted(reg_set & compta_set):
        r, c = reg[ref], compta[ref]
        if r["montant"] != c["montant"]:
            mismatches.append(("compta montant", ref, r["montant"], c["montant"]))
        if r["droit"] != c["revenu"]:
            mismatches.append(("compta revenu", ref, r["droit"], c["revenu"]))
    for ref in sorted(reg_set & orga_set):
        r, o = reg[ref], orga[ref]
        if r["montant"] != o["montant"]:
            mismatches.append(("orga montant", ref, r["montant"], o["montant"]))
        if r["droit"] != o["droit"]:
            mismatches.append(("orga droit", ref, r["droit"], o["droit"]))
        expected_source = "registre_UBI_Contrats_courant.md"
        if o["source"] != expected_source:
            mismatches.append(("orga source", ref, o["source"], expected_source))

    print(f"\n=== ALIGNEMENT montants/revenus : {len(mismatches)} ecarts ===")
    for x in mismatches:
        print(f"  {x}")

    # Contrats avec revenu connu
    with_revenu = {ref for ref, d in reg.items() if d["droit"] is not None and d["droit"] > 0}
    total_reg = sum(reg[r]["droit"] for r in with_revenu)
    total_compta = sum(compta[r]["revenu"] for r in with_revenu if r in compta)
    print(f"\n=== TOTAUX revenus droits de garde ===")
    print(f"  Registre contrats (droit > 0) : {total_reg}")
    print(f"  Compta (memes refs)           : {total_compta}")
    if total_reg != total_compta:
        missing_compta_rev = sorted(with_revenu - compta_set)
        if missing_compta_rev:
            print(f"  Refs avec droit > 0 absentes compta : {missing_compta_rev}")

    non_renseigne = sorted(
        ref for ref, d in reg.items()
        if d["montant"] is None or d["droit"] is None
    )
    print(f"\n=== CONTRATS non renseignes (montant ou droit) : {len(non_renseigne)} ===")
    for r in non_renseigne:
        d = reg[r]
        has_md = "oui" if r in md else "non"
        print(f"  {r} | MD={has_md} | statut={d['statut']}")

    zero_revenu = sorted(
        ref for ref, d in reg.items() if d["droit"] == 0 and ref not in compta_set
    )
    print(f"\n=== CONTRATS droit 0 absents compta : {len(zero_revenu)} ===")
    for r in zero_revenu:
        print(f"  {r}")

    ok = (
        not (md - reg_set)
        and not csv_bad
        and not (reg_set - orga_set)
        and not (orga_set - reg_set)
        and not bad_droit
        and not mismatches
        and not dupes
        and total_reg == total_compta
        and not (with_revenu - compta_set)
    )
    # registre sans MD acceptable si non renseigne / depose sans fichier
    reg_sans_md = reg_set - md
    if reg_sans_md - set(non_renseigne):
        ok = False
        unexpected = sorted(reg_sans_md - set(non_renseigne))
        print(f"\n=== REGISTRE sans MD (hors non renseignes) : {len(unexpected)} ===")
        for r in unexpected:
            print(f"  {r} | {reg[r]['statut']}")

    print("\n=== VERDICT ===")
    print("OK — tous les registres sont alignes." if ok else "ECARTS detectes — voir detail ci-dessus.")


if __name__ == "__main__":
    main()
