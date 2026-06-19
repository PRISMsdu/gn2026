#!/usr/bin/env python3
"""Genere un registre markdown courant par cite (format UBI + colonne Detail)."""

from __future__ import annotations

import csv
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV_SOURCE = (
    ROOT
    / "Groupes"
    / "Banquiers - UBI"
    / "3- Compta & registres"
    / "Registre_UBI_Orga.csv"
)
REG_CONTRATS = (
    ROOT
    / "Groupes"
    / "Banquiers - UBI"
    / "3- Compta & registres"
    / "registre_UBI_Contrats_courant.md"
)
CONTRATS_DIR = ROOT / "Contrats_et_Livres"

REF_RE = re.compile(r"^[A-Z]{2,3}-[IV]+-\d{3}-\d{3}$")
REF_YEAR = re.compile(r"-(\d{3})-\d{3}$")
TAGGED_NAME = re.compile(r"([^;(]+)\s*\(([^)]+)\)")

MAX_DETAIL_CHARS = 200
MAX_DETAIL_SENTENCES = 2

CITIES: dict[str, dict[str, object]] = {
    "Arthas": {
        "output_dir": ROOT / "Groupes" / "Arthas" / "1 - Back de groupe",
        "labels": ["Arthas"],
        "members": [
            "Aurelian Marvek",
            "Cassiane Jakmar",
            "Luceriane Darsen",
            "Bastion Kharvek",
            "Septimus Calveran",
            "Varik Sorell",
            "Tiber Kaelos",
            "Valerian Marvek",
            "Marra Kesh",
            "Edran Thorne",
            "Tiber Khar",
            "Sera Orist",
        ],
    },
    "Il-Irion": {
        "output_dir": ROOT / "Groupes" / "Il-Irion" / "1 - Back de groupe",
        "labels": ["Il-Irion", "Il Irion"],
        "members": [
            "Calis Aedris",
            "Seraphin Kaelthorne",
            "Cyrion Valdris",
            "Lucan Marivent",
            "Isar Dornelis",
            "Marek Thorne",
            "Garrick Halvaren",
            "Odran Calev",
            "Tovan Ilmari",
            "Ryliane Sorne",
            "Darian Quenndral",
            "Eldran Voss",
            "Selvian Dorn",
            "Neriane Vossel",
            "Calven Oristel",
            "Vaeric Noll",
            "Selvian Kaelthorne",
        ],
    },
    "Palyr": {
        "output_dir": ROOT / "Groupes" / "Palyr" / "1 - Back de groupe",
        "labels": ["Palyr"],
        "members": [
            "Ilara Vandesse",
            "Corvyn Valdrak",
            "Orel Vant",
            "Lysa Morwyn",
            "Thoran Keld",
            "Maren Holt",
            "Saevar Dren",
            "Brina Lyrd",
            "Syndri Ashfeld",
            "Kaelen Voss",
            "Seigneur Aldric Ventoss",
            "Neral Voss",
            "Liora Veyss",
            "Tessa Mire",
            "Mirel Osk",
            "Karyk Valdrak",
        ],
    },
    "Sfaal": {
        "output_dir": ROOT / "Groupes" / "Sfaal" / "Back de groupe",
        "labels": ["Sfaal"],
        "members": [
            "Synex Aliriis",
            "Peyl Tergun",
            "Rym Naksane",
            "Daya Guelendag",
            "Grisbe Jab-fer",
            "Catlkael Cisau",
            "Lithia Mevaror",
            "Phia Donug",
            "Jabren Feld",
            "Sorna Kelveg",
            "Branik Telg",
            "Merra Forgecendre",
            "Duc Thoren Forgefer",
            "Maison Aliriis",
            "Maison Guelendag",
            "Maison Jab-Fer",
        ],
    },
    "Ther-Félis": {
        "output_dir": ROOT / "Groupes" / "Ther-Félis" / "1 - Back de groupe",
        "labels": ["Ther-Félis", "Ther-Felis", "Ter Félis"],
        "members": [
            "Rauth Kaelmar",
            "Ysara Vell",
            "Dorian Marest",
            "Joric Tann",
            "Sven Orlac",
            "Miret Sael",
            "Odran Veyl",
            "Marda Velyss",
            "Jonn Halet",
            "Maelis Tern",
            "Sabel Tern",
        ],
    },
}


def load_registre_contrats() -> dict[str, dict[str, str]]:
    text = REG_CONTRATS.read_text(encoding="utf-8")
    data: dict[str, dict[str, str]] = {}
    for line in text.splitlines():
        if not line.startswith("|") or "Référence" in line or "---" in line:
            continue
        parts = [p.strip() for p in line.split("|")[1:-1]]
        if len(parts) >= 8 and REF_RE.match(parts[0]):
            data[parts[0]] = {
                "type": parts[1],
                "parties": parts[2],
                "montant": parts[3],
                "droit": parts[4],
                "depot": parts[5],
                "exec": parts[6],
                "statut": parts[7],
            }
    return data


def load_orga_descriptions() -> dict[str, str]:
    out: dict[str, str] = {}
    with CSV_SOURCE.open(encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f, delimiter=";"):
            if row.get("periode") != "courant":
                continue
            ref = row.get("reference", "")
            if REF_RE.match(ref):
                out[ref] = (row.get("description_contenu") or "").strip()
    return out


def load_orga_rows() -> list[dict[str, str]]:
    with CSV_SOURCE.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f, delimiter=";"))


def collect_tagged_members(rows: list[dict[str, str]]) -> dict[str, set[str]]:
    tagged: dict[str, set[str]] = {city: set() for city in CITIES}
    for row in rows:
        blob = ";".join(row.values())
        for name, label in TAGGED_NAME.findall(blob):
            name = name.strip()
            for city, cfg in CITIES.items():
                if any(lbl in label for lbl in cfg["labels"]):  # type: ignore[arg-type]
                    tagged[city].add(name)
    return tagged


def matches_city(text: str, labels: list[str], members: set[str]) -> bool:
    if any(label in text for label in labels):
        return True
    return any(member in text for member in members)


def one_line(text: str) -> str:
    text = re.sub(r"\s+", " ", text.strip())
    text = text.replace("|", "\\|")
    return text


def split_sentences(text: str) -> list[str]:
    text = one_line(text)
    parts = re.split(r"(?<=[.!?…])\s+(?=[A-ZÀ-ÖØ-Þ«\"])", text)
    return [p.strip() for p in parts if p.strip()]


def summarize_detail(text: str) -> str:
    if not text or text.strip().lower() in ("non renseigné", "non renseignée"):
        return "Non renseigné"

    text = one_line(text)

    if " ; " in text:
        text = text.split(" ; ", 1)[0].strip()

    label = re.match(
        r"^(?:Article\s+[IVXLCDM\d]+[^:]*|[^:]{4,45})\s*:\s*",
        text,
        re.IGNORECASE,
    )
    if label:
        text = text[label.end() :].strip()

    sentences = split_sentences(text)
    kept: list[str] = []
    for sentence in sentences:
        if re.search(
            r"(?i)(est conclu le présent|devant un comptoir reconnu|sous le regard des cieux)",
            sentence,
        ) and not re.search(
            r"(?i)(vend|achète|confie|loue|prête|fournit|transport|mandat|protection|alliance)",
            sentence,
        ):
            continue
        kept.append(sentence)

    if not kept:
        kept = sentences[:MAX_DETAIL_SENTENCES]

    result = " ".join(kept[:MAX_DETAIL_SENTENCES])
    if len(result) > MAX_DETAIL_CHARS:
        cut = result[: MAX_DETAIL_CHARS - 1].rsplit(" ", 1)[0]
        result = cut.rstrip(",;:") + "…"
    return one_line(result)


def extract_detail_from_contract(path: Path) -> str | None:
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"!\[[^\]]*\]\([^)]+\)", "", text)
    text = re.sub(r"^#+\s.*$", "", text, flags=re.MULTILINE)

    simple = re.search(
        r"^(Le \d+ .+?)(?=\n\n(?:Le prix|Les |Arthas |Palyr |Sfaal |Il-Irion |Ther|Fait |Pour |\Z))",
        text,
        re.MULTILINE | re.DOTALL,
    )
    if simple:
        return one_line(simple.group(1))

    inline = re.search(
        r"\*\*Article\s+(?:premier|1|I)[^*]+\*\*\s*:\s*(.+?)(?=\n\n\*\*Article|\Z)",
        text,
        re.DOTALL | re.IGNORECASE,
    )
    if inline:
        return one_line(inline.group(1))

    block = re.search(
        r"##\s+Article\s+(?:premier|1)[^\n]*\n\n(.+?)(?=\n\n##\s+Article|\Z)",
        text,
        re.DOTALL | re.IGNORECASE,
    )
    if block:
        return one_line(block.group(1))

    obj = re.search(
        r"\*\*Article\s+I[^*]*\*\*\s*:\s*(.+?)(?=\n\n\*\*Article|\Z)",
        text,
        re.DOTALL | re.IGNORECASE,
    )
    if obj:
        return one_line(obj.group(1))

    engage = re.search(
        r"(?:s'engage envers|confie à|vend à|achète à|loue à)\s+.+?\.",
        text,
        re.IGNORECASE,
    )
    if engage:
        return one_line(engage.group(0))

    bullets = re.findall(r"^\*\*([^*]+)\*\*\s*:\s*(.+)$", text, re.MULTILINE)
    if bullets:
        key, value = bullets[0]
        return one_line(f"{key.strip()} : {value.strip()}")

    return None


def contract_detail(ref: str, fallback: str) -> str:
    if fallback:
        return summarize_detail(fallback)
    extracted = extract_detail_from_contract(CONTRATS_DIR / f"{ref}.md")
    if extracted:
        return summarize_detail(extracted)
    return "Non renseigné"


def year_of(ref: str) -> str:
    m = REF_YEAR.search(ref)
    return m.group(1) if m else "000"


def escape_cell(value: str) -> str:
    return value.replace("|", "\\|")


def build_markdown(city: str, entries: list[tuple[str, dict[str, str], str]]) -> str:
    by_year: dict[str, list[tuple[str, dict[str, str], str]]] = defaultdict(list)
    for ref, row, detail in entries:
        by_year[year_of(ref)].append((ref, row, detail))

    lines = [
        f"# Registre {city} — contrats courants",
        "",
        f"Registre joueur des contrats et pièces déposés à l'UBI depuis le 1er Equos 542 "
        f"auxquels {city} ou l'un de ses mandataires est partie. "
        f"La colonne Détail reprend un résumé du contenu connu de la délégation (une ou deux lignes).",
        "",
        "",
        "## Registre annuel",
        "",
    ]

    header = (
        "| Référence | Type | Parties | Montant | Droit UBI | "
        "Date dépôt | Date exécution | Statut | Détail |"
    )
    sep = "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"

    for year in sorted(by_year):
        lines.extend([f"### {year}", "", header, sep])
        for ref, row, detail in by_year[year]:
            lines.append(
                "| "
                + " | ".join(
                    [
                        ref,
                        escape_cell(row["type"]),
                        escape_cell(row["parties"]),
                        escape_cell(row["montant"]),
                        escape_cell(row["droit"]),
                        escape_cell(row["depot"]),
                        escape_cell(row["exec"]),
                        escape_cell(row["statut"]),
                        escape_cell(detail),
                    ]
                )
                + " |"
            )
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    registre = load_registre_contrats()
    descriptions = load_orga_descriptions()
    orga_rows = load_orga_rows()
    tagged = collect_tagged_members(orga_rows)

    for city, cfg in CITIES.items():
        labels: list[str] = cfg["labels"]  # type: ignore[assignment]
        out_dir: Path = cfg["output_dir"]  # type: ignore[assignment]
        members = set(cfg["members"]) | tagged[city]  # type: ignore[arg-type]
        out_dir.mkdir(parents=True, exist_ok=True)

        entries: list[tuple[str, dict[str, str], str]] = []
        orga_by_ref = {r.get("reference", ""): r for r in orga_rows}
        for ref, row in registre.items():
            orga_row = orga_by_ref.get(ref, {})
            blob = ";".join(orga_row.values()) if orga_row else row["parties"]
            if not matches_city(blob, labels, members):
                continue
            detail = contract_detail(ref, descriptions.get(ref, ""))
            entries.append((ref, row, detail))

        out_path = out_dir / f"registre_{city}_contrats_courant.md"
        out_path.write_text(build_markdown(city, entries), encoding="utf-8")

        old_csv = out_dir / f"Registre_{city}_courant.csv"
        if old_csv.exists():
            old_csv.unlink()

        print(f"{city}: {len(entries)} lignes -> {out_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
