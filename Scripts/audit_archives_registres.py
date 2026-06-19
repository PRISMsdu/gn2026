#!/usr/bin/env python3
"""Audit croise contrats archives vs registres UBI, compta et orga."""

from __future__ import annotations

import csv
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCH = ROOT / "Contrats_et_Livres" / "Archives"
REG_CONTRATS = ROOT / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "registre_UBI_Contrats_archives.md"
REG_COMPTA = ROOT / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "registre_Comptable_UBI_Archives.md"
REG_ORGA = ROOT / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "Registre_UBI_Orga.csv"

REF_RE = re.compile(r"^[A-Z]{2,3}-[IV]+-\d{3}-\d{3}$")
REF_IN_TABLE = re.compile(r"\|\s*([A-Z]{2,3}-[IV]+-\d{3}-\d{3})\s*\|")
SKIP_MD = {"METHODE_contrat_archive", "METHODE_credoc_archives", "methode_versement_archives"}


def parse_amount(s: str | None) -> int | None:
    if not s:
        return None
    s = s.strip().lower()
    if s in ("—", "-", ""):
        return None
    if re.fullmatch(r"0\s+couronnes?", s):
        return 0
    m = re.search(r"([\d\s'\u2019]+)", s.replace("\u2019", "'"))
    if not m:
        return None
    return int(m.group(1).replace("'", "").replace("\u2019", "").replace(" ", ""))


def expected_droit(ref: str, montant: int | None, typ: str) -> int | None:
    if montant is None:
        return None
    if ref.startswith("PAR-I-") and montant == 0:
        return 50
    if montant == 0:
        return 0
    if ref.startswith("PB-"):
        return round(montant * 0.04)
    return round(montant * 0.02)


def load_md_refs() -> set[str]:
    refs: set[str] = set()
    for p in ARCH.glob("*.md"):
        if p.stem in SKIP_MD:
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


def load_orga_archives() -> tuple[dict[str, dict], list[str]]:
    out: dict[str, dict] = {}
    bad_rows: list[str] = []
    with REG_ORGA.open(encoding="utf-8-sig", newline="") as f:
        for i, row in enumerate(csv.DictReader(f, delimiter=";"), start=2):
            if row.get("periode") != "archives":
                continue
            ref = row.get("reference", "")
            if not REF_RE.match(ref):
                bad_rows.append(f"L{i}: reference invalide {ref!r}")
                continue
            out[ref] = {
                "montant": parse_amount(row.get("montant", "")),
                "droit": parse_amount(row.get("droit_ubi_paye", "")),
                "source": row.get("source_registre", ""),
            }
    return out, bad_rows


def main() -> None:
    md = load_md_refs()
    reg_list, reg = load_registre_contrats()
    reg_set = set(reg_list)
    compta_list, compta = load_compta()
    compta_set = set(compta_list)
    orga, orga_bad = load_orga_archives()
    orga_set = set(orga)

    print("=== EFFECTIFS ===")
    print(f"Fichiers MD archives (contrats)     : {len(md)}")
    print(f"Registre contrats (refs uniques)    : {len(reg_set)} (lignes {len(reg_list)})")
    print(f"Registre compta (contrats archives) : {len(compta_set)} (lignes {len(compta_list)})")
    print(f"Orga CSV periode=archives           : {len(orga_set)}")

    dupes = [r for r, c in Counter(reg_list).items() if c > 1]
    if dupes:
        print(f"\nDOUBLONS registre contrats : {len(dupes)}")
        for r in dupes[:10]:
            print(f"  {r} x{Counter(reg_list)[r]}")

    sections = [
        ("MD sans registre contrats", sorted(md - reg_set)),
        ("Registre contrats sans MD", sorted(reg_set - md)),
        ("Contrats sans ligne compta", sorted(reg_set - compta_set)),
        ("Compta sans registre contrats", sorted(compta_set - reg_set)),
        ("Contrats sans orga archives", sorted(reg_set - orga_set)),
        ("Orga archives sans registre contrats", sorted(orga_set - reg_set)),
    ]
    for title, items in sections:
        print(f"\n=== {title} : {len(items)} ===")
        for r in items[:25]:
            print(f"  {r}")
        if len(items) > 25:
            print(f"  ... +{len(items) - 25} autres")

    # Droits : 2 % garde, 4 % PB, 50 c. PAR-I
    bad_droit: list[tuple] = []
    for ref, d in reg.items():
        m, dr = d["montant"], d["droit"]
        exp = expected_droit(ref, m, d["type"])
        if dr is None:
            bad_droit.append((ref, "droit manquant", m, dr, exp))
            continue
        if exp is not None and exp != dr:
            bad_droit.append((ref, m, dr, exp))

    print(f"\n=== DROIT UBI registre contrats : {len(bad_droit)} ecarts ===")
    for x in bad_droit[:20]:
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
        if o["source"] != "registre_UBI_Contrats_archives.md":
            mismatches.append(("orga source", ref, o["source"], "registre_UBI_Contrats_archives.md"))

    print(f"\n=== ALIGNEMENT montants/revenus : {len(mismatches)} ecarts ===")
    for x in mismatches[:30]:
        print(f"  {x}")

    # Totaux annuels recap vs somme des lignes de chaque section
    recap_re = re.compile(
        r"Récapitulatif (\d+) : revenus UBI sur droits de garde : ([\d\s']+) couronnes"
    )
    recaps: dict[int, int] = {}
    year_sums: dict[int, int] = {}
    text = REG_CONTRATS.read_text(encoding="utf-8")
    current_year: int | None = None
    for line in text.splitlines():
        sec = re.match(r"^### (\d{3})$", line.strip())
        if sec:
            current_year = int(sec.group(1))
            continue
        rm = recap_re.search(line)
        if rm:
            recaps[int(rm.group(1))] = parse_amount(rm.group(2) + " couronnes") or 0
            continue
        if current_year and line.startswith("|") and not line.startswith("| ---"):
            parts = [p.strip() for p in line.split("|")[1:-1]]
            if len(parts) >= 5 and REF_RE.match(parts[0]):
                droit = parse_amount(parts[4])
                if droit is not None:
                    year_sums[current_year] = year_sums.get(current_year, 0) + droit

    bad_recap = []
    for y in sorted(recaps):
        s = year_sums.get(y, 0)
        if s != recaps[y]:
            bad_recap.append((y, recaps[y], s))

    print(f"\n=== RECAP ANNUEL droits de garde vs somme lignes : {len(bad_recap)} ecarts ===")
    for y, declared, computed in bad_recap[:20]:
        print(f"  {y}: declare {declared}, calcule {computed}, delta {computed - declared}")

    zero_revenu = sorted(
        ref for ref, d in reg.items() if d["droit"] == 0 and ref not in compta_set
    )
    print(f"\n=== CONTRATS droit 0 absents compta (attendu?) : {len(zero_revenu)} ===")
    for r in zero_revenu:
        print(f"  {r} montant={reg[r]['montant']}")

    suspicious_zero = [
        (ref, reg[ref]["montant"])
        for ref in zero_revenu
        if (reg[ref]["montant"] or 0) > 0
    ]
    if suspicious_zero:
        print(f"\n=== DROIT 0 mais montant > 0 : {len(suspicious_zero)} ===")
        for x in suspicious_zero:
            print(f"  {x}")

    ok = (
        not (md - reg_set)
        and not (reg_set - md)
        and not (reg_set - orga_set)
        and not (orga_set - reg_set)
        and not bad_droit
        and not mismatches
        and not bad_recap
        and not dupes
        and not suspicious_zero
    )
    print("\n=== VERDICT ===")
    print("OK — tous les registres sont alignes." if ok else "ECARTS detectes — voir detail ci-dessus.")


if __name__ == "__main__":
    main()
