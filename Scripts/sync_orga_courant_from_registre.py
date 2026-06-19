#!/usr/bin/env python3
"""Complète montant/droit/statut orga courant depuis registre_UBI_Contrats_courant.md."""

from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV = ROOT / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "Registre_UBI_Orga.csv"

import sys

sys.path.insert(0, str(ROOT / "Scripts"))
from audit_courant_registres import load_registre_contrats  # noqa: E402


def fmt_amount(v: int | None, singular: bool = False) -> str:
    if v is None:
        return ""
    if v == 0:
        return "0 couronne"
    word = "couronne" if singular and v == 1 else "couronnes"
    return f"{v:,}".replace(",", "'") + f" {word}"


def main() -> None:
    _, reg = load_registre_contrats()
    rows: list[dict[str, str]] = []
    updated: list[str] = []

    with CSV.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        fields = reader.fieldnames
        assert fields is not None
        for row in reader:
            if row.get("periode") == "courant":
                ref = row["reference"]
                if ref in reg:
                    r = reg[ref]
                    empty = not row.get("montant", "").strip() or not row.get(
                        "droit_ubi_paye", ""
                    ).strip()
                    if empty:
                        if r["montant"] is not None:
                            row["montant"] = fmt_amount(r["montant"])
                        if r["droit"] is not None:
                            row["droit_ubi_paye"] = fmt_amount(r["droit"])
                        if row.get("statut") in ("", "Courant"):
                            row["statut"] = r["statut"]
                        if not row.get("date_execution", "").strip():
                            ex = r.get("exec", "")
                            if ex and "non renseign" not in ex.lower():
                                row["date_execution"] = ex
                        updated.append(ref)
            rows.append(row)

    with CSV.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields, delimiter=";")
        writer.writeheader()
        writer.writerows(rows)

    print(f"Mises à jour : {len(updated)}")
    for ref in updated:
        r = reg[ref]
        print(f"  {ref} | {r['montant']} | {r['droit']} | {r['statut']}")


if __name__ == "__main__":
    main()
