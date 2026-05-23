#!/usr/bin/env python3
"""Dédoublonne les ## Connaissances (même sujet, titres proches)."""

import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Groupes"
GROUP_DIRS = [
    ROOT / "Banquiers - UBI" / "2 - Roles des Joueurs",
    ROOT / "Tripot" / "2 - Roles des Joueurs",
    ROOT / "MiVI" / "2 - Roles des Joueurs",
    ROOT / "Palyr" / "2 - Roles des Joueurs",
    ROOT / "Mafia - Les Sangs de la Steppe" / "2 - Roles des Joueurs",
]


def norm_key(title: str) -> str:
    t = unicodedata.normalize("NFKD", title.split("—")[0].strip().lower())
    return "".join(c for c in t if not unicodedata.combining(c))


def dedupe_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    m = re.search(r"^# Connaissances\s*$", text, re.MULTILINE)
    if not m:
        return False

    before = text[: m.start()]
    rest = text[m.end() :]
    end_m = re.search(r"\n(?=---\n|\*GN Krondaar|\*\*Version|\Z)", rest, re.MULTILINE)
    body = rest[: end_m.start()] if end_m else rest
    tail = rest[end_m.start() :] if end_m else ""

    sections = re.split(r"\n(?=## )", body.strip())
    seen: dict[str, str] = {}
    order: list[str] = []

    for sec in sections:
        sec = sec.strip()
        if not sec.startswith("## "):
            continue
        title = sec.split("\n", 1)[0][3:].strip()
        key = norm_key(title)
        if key not in seen or len(sec) > len(seen[key]):
            if key in seen and key in order:
                order.remove(key)
            seen[key] = sec
            order.append(key)

    new_body = "\n\n".join(seen[k] for k in order).strip()
    if new_body == body.strip():
        return False

    path.write_text(before + "# Connaissances\n\n" + new_body + "\n" + tail, encoding="utf-8")
    return True


def main() -> None:
    n = 0
    for d in GROUP_DIRS:
        for f in d.glob("*.md"):
            if f.name == "README.md":
                continue
            if dedupe_file(f):
                n += 1
                print(f.name)
    print(f"Deduped {n} files")


if __name__ == "__main__":
    main()
