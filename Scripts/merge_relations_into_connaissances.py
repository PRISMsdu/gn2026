#!/usr/bin/env python3
"""Fusionne Relations clés / Membres du groupe dans # Connaissances."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Groupes"

GROUP_DIRS = [
    ROOT / "Banquiers - UBI" / "2 - Roles des Joueurs",
    ROOT / "Tripot" / "2 - Roles des Joueurs",
    ROOT / "MiVI" / "2 - Roles des Joueurs",
    ROOT / "Palyr" / "2 - Roles des Joueurs",
    ROOT / "Mafia - Les Sangs de la Steppe" / "2 - Roles des Joueurs",
]

SKIP = {"README.md"}


def is_table_sep(line: str) -> bool:
    return bool(re.match(r"^\|[-:\s|]+\|\s*$", line.strip()))


def is_table_header(cols: list[str]) -> bool:
    h = {c.strip().lower() for c in cols}
    keys = {
        "personnage",
        "lien",
        "personne",
        "groupe ou lieu d'attache",
        "type de relation",
        "interaction",
        "rôle",
        "role",
        "avec...",
        "vous savez...",
        "détail",
        "mission",
    }
    return bool(h & keys)


def parse_table_block(lines: list[str]) -> list[tuple[str, str]]:
    sections: list[tuple[str, str]] = []
    for line in lines:
        line = line.rstrip()
        if not line.startswith("|"):
            continue
        if is_table_sep(line):
            continue
        cols = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cols) < 2 or is_table_header(cols):
            continue
        if len(cols) >= 4:
            title = f"{cols[0]} — {cols[1]}"
            body = cols[3]
        else:
            title = cols[0]
            body = cols[1]
        sections.append((title, body))
    return sections


def format_section(title: str, body: str) -> str:
    return f"## {title}\n\n{body.strip()}\n"


def norm_key(title: str) -> str:
    return re.sub(r"\s+", " ", title.strip().lower())


def extract_block(text: str, start_pattern: str) -> tuple[str, str, str] | None:
    m = re.search(start_pattern, text, re.MULTILINE | re.IGNORECASE)
    if not m:
        return None
    start = m.start()
    rest = text[m.end() :]
    end_m = re.search(
        r"\n(?=# [^\n]+|\n## Informations sensibles|\n---\n|\n\*GN Krondaar|\n\*\*Version)",
        rest,
        re.MULTILINE,
    )
    if end_m:
        end = m.end() + end_m.start()
    else:
        end = len(text)
    block = text[start:end]
    before = text[:start]
    after = text[end:]
    return before, block, after


def extract_membres_block(text: str) -> tuple[str, str, str] | None:
    for pat in (
        r"^# Membres du groupe\s*$",
        r"^# Membres du Tripot\s*$",
        r"^### Membres du groupe\s*$",
    ):
        r = extract_block(text, pat)
        if r:
            return r
    return None


def extract_relations_cles(text: str) -> tuple[str, str, str] | None:
    return extract_block(text, r"^## Relations clés(?: à exploiter)?\s*$")


def parse_existing_connaissances(text: str) -> tuple[str, dict[str, str], str]:
    m = re.search(r"^# Connaissances\s*$", text, re.MULTILINE)
    if not m:
        return text, {}, ""

    start = m.end()
    rest = text[start:]
    end_m = re.search(r"\n(?=---\n|\*GN Krondaar|\*\*Version|\Z)", rest, re.MULTILINE)
    body = rest[: end_m.start()] if end_m else rest

    sections: dict[str, str] = {}
    parts = re.split(r"\n(?=## )", body.strip())
    for part in parts:
        part = part.strip()
        if not part:
            continue
        if part.startswith("## "):
            lines = part.split("\n", 1)
            title = lines[0][3:].strip()
            content = lines[1].strip() if len(lines) > 1 else ""
            sections[norm_key(title)] = format_section(title, content)

    before = text[: m.start()]
    after = text[m.end() + (end_m.start() if end_m else len(rest)) :]
    return before + after, sections, ""


def tables_from_block(block: str) -> list[tuple[str, str]]:
    sections: list[tuple[str, str]] = []
    chunks = re.split(r"\n(?=### )", block)
    for chunk in chunks:
        chunk = chunk.strip()
        if not chunk:
            continue
        if chunk.startswith("### "):
            chunk = re.sub(r"^### [^\n]+\n", "", chunk, count=1)
        sections.extend(parse_table_block(chunk.splitlines()))
    return sections


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    new_sections: list[tuple[str, str]] = []

    rel = extract_relations_cles(text)
    if rel:
        text = rel[0] + rel[2]
        new_sections.extend(tables_from_block(rel[1]))

    membres = extract_membres_block(text)
    if membres:
        text = membres[0] + membres[2]
        new_sections.extend(tables_from_block(membres[1]))

    # Marda : Relations hors Tripot -> Connaissances (prose blocks)
    marda_rel = extract_block(text, r"^# Relations hors Tripot\s*$")
    marda_prose: str | None = None
    if marda_rel:
        text = marda_rel[0] + marda_rel[2]
        marda_prose = marda_rel[1].replace("# Relations hors Tripot", "").strip()

    # Corvus : nested ### Connaissances table under Informations générales
    corvus = re.search(
        r"^## Informations générales\s*\n([\s\S]*?)(?=\n---\n|\n\*\*Version|\Z)",
        text,
        re.MULTILINE,
    )
    if corvus:
        block = corvus.group(1)
        conv = re.search(
            r"^### Connaissances\s*\n([\s\S]*?)(?=^### |\Z)",
            block,
            re.MULTILINE,
        )
        if conv:
            for title, body in parse_table_block(conv.group(1).splitlines()):
                new_sections.append((title, body))
            new_block = block[: conv.start()] + block[conv.end() :]
            # remove ### Membres du groupe if present
            memb = re.search(
                r"^### Membres du groupe\s*\n[\s\S]*?(?=^### |\Z)",
                new_block,
                re.MULTILINE,
            )
            if memb:
                new_block = new_block[: memb.start()] + new_block[memb.end() :]
            text = text[: corvus.start(1)] + new_block + text[corvus.end(1) :]

    text, existing, _ = parse_existing_connaissances(text)

    merged = dict(existing)
    for title, body in new_sections:
        key = norm_key(title)
        if key not in merged:
            merged[key] = format_section(title, body)

    if not merged and not marda_prose:
        if text != original:
            path.write_text(text, encoding="utf-8")
        return text != original

    connaissances_body = ""
    if marda_prose:
        # keep prose sections as-is (already ## titled)
        if not marda_prose.startswith("##"):
            connaissances_body = marda_prose + "\n\n"
        else:
            connaissances_body = marda_prose + "\n\n"

    ordered = list(merged.values())
    connaissances_body += "\n".join(ordered).strip()

    footer_m = re.search(r"(\n---\n\n\*GN Krondaar[\s\S]*)", text)
    footer = footer_m.group(1) if footer_m else "\n\n---\n\n*GN Krondaar 2026*\n"
    if footer_m:
        text = text[: footer_m.start()]

    version_m = re.search(r"(\n---\n\n\*\*Version[\s\S]*)", text)
    version_footer = version_m.group(1) if version_m else ""
    if version_m:
        text = text[: version_m.start()]

    text = text.rstrip() + "\n\n# Connaissances\n\n" + connaissances_body.rstrip() + "\n"
    if version_footer:
        text += version_footer
    else:
        text += footer if footer.strip() else "\n"

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed = []
    for group_dir in GROUP_DIRS:
        for path in sorted(group_dir.glob("*.md")):
            if path.name in SKIP:
                continue
            if process_file(path):
                changed.append(path.relative_to(ROOT.parent))
    print(f"Modified {len(changed)} files:")
    for p in changed:
        print(f"  - {p}")


if __name__ == "__main__":
    main()
