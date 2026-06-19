#!/usr/bin/env python3
"""Remplace les ; dans les descriptions CSV par des tirets."""

from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "Groupes" / "Banquiers - UBI" / "3- Compta & registres" / "Registre_UBI_Orga.csv"


def main() -> None:
    text = CSV_PATH.read_text(encoding="utf-8-sig")
    text = text.replace(" ; ", " - ")
    text = text.replace('"', "")
    CSV_PATH.write_text(text, encoding="utf-8-sig")

    lines = text.splitlines()
    ncols = len(lines[0].split(";"))
    bad = [
        (i + 1, len(line.split(";")))
        for i, line in enumerate(lines[1:])
        if len(line.split(";")) != ncols
    ]
    print(f"Colonnes attendues: {ncols}")
    print(f"Lignes incorrectes: {len(bad)}")
    for row_num, count in bad[:10]:
        print(f"  L{row_num}: {count} colonnes")

    with CSV_PATH.open(encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f, delimiter=";"):
            if row["reference"] == "AL-IV-535-006":
                print("AL-IV-535-006 OK:")
                print(f"  montant={row['montant']}")
                print(f"  droit={row['droit_ubi_paye']}")
                print(f"  source={row['source_registre']}")


if __name__ == "__main__":
    main()
