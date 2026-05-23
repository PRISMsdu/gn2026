#!/usr/bin/env python3
"""Supprime les ## Connaissances sur les coéquipiers du même groupe."""

from __future__ import annotations

import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Groupes"

GROUPS: dict[str, list[str]] = {
    "Banquiers - UBI": [
        "edorian",
        "ydria",
        "ventoss",
        "vaelric",
        "sybrel",
        "dornik",
        "selvara",
        "quenndral",
        "melian",
        "torv",
        "kaelen",
        "veynar",
        "horgrim",
        "dval",
        "corvus",
    ],
    "Tripot": [
        "marda",
        "velyss",
        "ardan",
        "trevil",
        "fenric",
        "ossel",
        "eliane",
        "éliane",
        "sira",
        "lira",
        "vestrann",
        "ysabeau",
        "varek",
        "soren",
        "guelievre",
        "marech",
        "lydwen",
    ],
    "MiVI": [
        "theven",
        "théven",
        "corvel",
        "lucan",
        "drest",
        "ysel",
        "marivent",
        "varro",
        "selt",
        "miraen",
        "talvas",
    ],
    "Palyr": [
        "corvyn",
        "valdrak",
        "ilara",
        "vandesse",
        "lysa",
        "morwyn",
        "thoran",
        "keld",
        "saevar",
        "dren",
        "maren",
        "holt",
        "syndri",
        "ashfeld",
        "bran",
        "lyrd",
    ],
    "Mafia - Les Sangs de la Steppe": [
        "kaelan",
        "thormane",
        "vorak",
        "ironhand",
        "gareth",
        "ironfist",
        "drask",
        "bloodmoon",
        "shadow",
        "raven",
    ],
}

SKIP = {"README.md"}


def strip_accents(text: str) -> str:
    nfkd = unicodedata.normalize("NFKD", text)
    return "".join(c for c in nfkd if not unicodedata.combining(c))


def norm(text: str) -> str:
    return strip_accents(text.lower())


def self_tokens_from_filename(path: Path) -> set[str]:
    """Ex. MiVI_Lucan_Drest_Negociateur -> lucan, drest."""
    stem = path.stem
    parts = stem.split("_", 1)
    if len(parts) < 2:
        return set()
    rest = parts[1]
    tokens = re.split(r"[_\s]+", rest)
    out: set[str] = set()
    for t in tokens:
        t = norm(t)
        if t and t not in {"negociateur", "chef", "de", "mission", "infiltration", "couverture", "salles",
                           "renseignement", "directeur", "general", "tresoriere", "discreteur", "ombre",
                           "archiviste", "en", "chef", "conseiller", "spirituel", "executeur", "contrats",
                           "garde", "coffres", "gardien", "des", "patronne", "capitaine", "gardes",
                           "maitre", "registres", "maitresse", "paris", "hotesse", "pisteur", "homme",
                           "main", "croupiere", "oracle", "gouvernante", "marchand", "herboriste",
                           "securite", "militaire", "diplomate", "delegation", "druide", "second",
                           "alchimiste", "interrogateur", "reseaux", "famille"}:
            out.add(t)
    return out


def section_matches_teammate(title: str, group_key: str, self_tokens: set[str]) -> bool:
    title_n = norm(title)
    main = norm(title.split("—")[0].strip())

    # Composés Tripot
    if group_key == "Tripot" and "sira" in title_n and "lira" in title_n:
        return True

    members = GROUPS[group_key]
    for token in members:
        if token in self_tokens:
            continue
        # Match token as whole word-ish in title
        if re.search(rf"(?<![a-z]){re.escape(token)}(?![a-z])", main) or re.search(
            rf"(?<![a-z]){re.escape(token)}(?![a-z])", title_n
        ):
            return True
    return False


def process_file(path: Path, group_key: str) -> bool:
    text = path.read_text(encoding="utf-8")
    m = re.search(r"^# Connaissances\s*$", text, re.MULTILINE)
    if not m:
        return False

    before = text[: m.start()]
    after_start = m.end()
    rest = text[after_start:]
    end_m = re.search(r"\n(?=---\n|\*GN Krondaar|\*\*Version|\Z)", rest, re.MULTILINE)
    body = rest[: end_m.start()] if end_m else rest
    tail = rest[end_m.start() :] if end_m else ""

    self_tokens = self_tokens_from_filename(path)
    sections = re.split(r"\n(?=## )", body.strip())
    kept: list[str] = []
    removed = 0

    for sec in sections:
        sec = sec.strip()
        if not sec:
            continue
        if not sec.startswith("## "):
            kept.append(sec)
            continue
        title_line = sec.split("\n", 1)[0][3:].strip()
        if section_matches_teammate(title_line, group_key, self_tokens):
            removed += 1
            continue
        kept.append(sec)

    if removed == 0:
        return False

    new_body = "\n\n".join(kept).strip()
    if new_body:
        new_text = before + "# Connaissances\n\n" + new_body + "\n" + tail
    else:
        new_text = before + "# Connaissances\n\n" + tail.lstrip("\n")

    path.write_text(new_text, encoding="utf-8")
    return True


def main() -> None:
    changed: list[str] = []
    for group_key in GROUPS:
        role_dir = ROOT / group_key / "2 - Roles des Joueurs"
        if not role_dir.is_dir():
            continue
        for path in sorted(role_dir.glob("*.md")):
            if path.name in SKIP:
                continue
            if process_file(path, group_key):
                changed.append(str(path.relative_to(ROOT.parent)))

    print(f"Modified {len(changed)} files:")
    for p in changed:
        print(f"  - {p}")


if __name__ == "__main__":
    main()
