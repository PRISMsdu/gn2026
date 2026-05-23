#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extrait le texte des PDF de Bibliothèque/Archives Secrètes vers des fichiers .md
(contenu utile seulement : pas de mise en page PDF).

Prérequis : pip install pypdf  (souvent déjà présent sur la machine orga)

Usage (depuis la racine du dépôt) :
  python Scripts/pdf_archives_secretes_to_md.py
  python Scripts/pdf_archives_secretes_to_md.py --pdf "Bibliothèque/Archives Secrètes/Note 001.pdf"
  python Scripts/pdf_archives_secretes_to_md.py --out-dir "Bibliothèque/Archives Secrètes/extraits"
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError:
    print("Module manquant : pip install pypdf", file=sys.stderr)
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = REPO_ROOT / "Bibliothèque" / "Archives Secrètes"
DEFAULT_OUTPUT = DEFAULT_INPUT / "md"

BULLET_ONLY = re.compile(r"^[\u00b7\u2022\u25cf\u25aa\u2219\-–—•·]\s*$")
PAGE_NUMBER = re.compile(r"^\d{1,3}$")
NUMBERED_ITEM = re.compile(r"^(\d+)\.\s+(.*)$")
# Titres de section PDF souvent collés au paragraphe précédent (sans point)
SECTION_BREAK = re.compile(
    r"(?<=[a-zàâäéèêëïîôùûüç0-9%])\s+"
    r"(?=(?:Classification|Diffusion|Objectif|Mission|Conclusion|Directive|"
    r"Situation|Effondrement|Importance|Risque|État|Acquisition|Mise en|"
    r"Note |Rapport |Discours|Déclaration)\s*:"
    r"|[A-ZÉÈÀÂÎÔÛ][a-zéèêàûôîë]+(?:\s+(?:de|du|des|d'|et|notre|la|l'|en))+\s+"
    r"[a-zéèêàûôîë])"
)


def normalize_chars(text: str) -> str:
    replacements = {
        "\u2019": "'",
        "\u2018": "'",
        "\u201c": '"',
        "\u201d": '"',
        "\u00ab": '"',
        "\u00bb": '"',
        "\u2013": "-",
        "\u2014": "-",
        "\ufb01": "fi",
        "\ufb02": "fl",
        "\xa0": " ",
        "\u00ad": "",  # soft hyphen
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text


def extract_pdf_text(pdf_path: Path) -> str:
    reader = PdfReader(str(pdf_path))
    parts: list[str] = []
    for page in reader.pages:
        parts.append(page.extract_text() or "")
    return "\n".join(parts)


def raw_to_lines(text: str) -> list[str]:
    text = normalize_chars(text)
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    lines: list[str] = []
    for raw in text.split("\n"):
        line = re.sub(r"[ \t]+", " ", raw).strip()
        if not line:
            lines.append("")
            continue
        if PAGE_NUMBER.fullmatch(line):
            continue
        if BULLET_ONLY.fullmatch(line):
            lines.append("__BULLET__")
            continue
        m = re.match(r"^[\u00b7\u2022\u25cf\u25aa\u2219•·]\s+(.+)$", line)
        if m:
            lines.append(f"- {m.group(1).strip()}")
            continue
        lines.append(line)
    return lines


def merge_wrapped_lines(lines: list[str]) -> list[str]:
    """Regroupe les retours à la ligne PDF au milieu des phrases."""
    merged: list[str] = []
    buf = ""

    def flush() -> None:
        nonlocal buf
        if buf:
            merged.append(buf.strip())
            buf = ""

    for line in lines:
        if line == "":
            flush()
            merged.append("")
            continue
        if line == "__BULLET__":
            flush()
            merged.append("__BULLET__")
            continue
        if line.startswith("- ") or NUMBERED_ITEM.match(line):
            flush()
            merged.append(line)
            continue

        if not buf:
            buf = line
            continue

        if buf.endswith("-"):
            buf = buf[:-1] + line
            continue

        if buf[-1] in ",:;(" or (buf[-1].isalnum() and line[0].islower()):
            buf = f"{buf} {line}"
            continue

        flush()
        buf = line

    flush()
    return merged


def join_broken_list_items(lines: list[str]) -> list[str]:
    """Rattache les lignes orphelines aux puces ou numéros précédents."""
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        is_bullet = line.startswith("- ")
        num = NUMBERED_ITEM.match(line)
        if not is_bullet and not num:
            out.append(line)
            i += 1
            continue

        chunks = [num.group(2) if num else line[2:]]
        i += 1
        while i < len(lines):
            if lines[i] == "":
                j = i + 1
                while j < len(lines) and lines[j] == "":
                    j += 1
                if j >= len(lines):
                    break
                nxt = lines[j]
                if nxt.startswith("- ") or NUMBERED_ITEM.match(nxt):
                    break
                body = " ".join(chunks)
                if re.search(r"[.!?][\"')\]]*\s*$", body):
                    break
                i = j
                continue
            nxt = lines[i]
            if nxt.startswith("- ") or NUMBERED_ITEM.match(nxt):
                break
            body = " ".join(chunks)
            if re.search(r"[.!?][\"')\]]*\s*$", body):
                break
            chunks.append(nxt)
            i += 1

        joined = " ".join(chunks)
        joined = re.sub(r"\s+", " ", joined).strip()
        if num:
            out.append(f"{num.group(1)}. {joined}")
        else:
            out.append(f"- {joined}")
    return out


def bullets_to_markdown(lines: list[str]) -> list[str]:
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line == "__BULLET__":
            i += 1
            while i < len(lines) and lines[i] == "":
                i += 1
            if i < len(lines) and lines[i] not in ("__BULLET__", ""):
                out.append(f"- {lines[i]}")
                i += 1
            else:
                out.append("-")
            continue
        out.append(line)
        i += 1
    return out


def collapse_blank_lines(lines: list[str], max_run: int = 2) -> list[str]:
    out: list[str] = []
    run = 0
    for line in lines:
        if line == "":
            run += 1
            if run <= max_run:
                out.append("")
            continue
        run = 0
        out.append(line)
    while out and out[-1] == "":
        out.pop()
    return out


def split_inline_sections(text: str) -> str:
    """Découpe les titres de section collés au texte PDF."""
    text = re.sub(r"\s+(À l['\u2019]attention\b)", r"\n\n\1", text)
    text = re.sub(
        r"(Stratégique|Confidentielle|Restreinte|Officielle)\s+(À l)",
        r"\1\n\n\2",
        text,
    )
    text = re.sub(r"\s+(Classification\s*:)", r"\n\n\1", text, flags=re.I)
    text = SECTION_BREAK.sub("\n\n", text)
    text = re.sub(r"\s+(?=(?:Général|Officiers|Madame|Monsieur),)", r"\n\n", text)
    text = re.sub(r"(?<=[.!?])\s+", "\n\n", text)
    return text


def lines_to_paragraphs(lines: list[str]) -> str:
    """Paragraphes simples : blocs séparés par une ligne vide ; listes inchangées."""
    blocks: list[str] = []
    current: list[str] = []

    def flush_para() -> None:
        if not current:
            return
        if len(current) == 1 and (
            current[0].startswith("- ")
            or NUMBERED_ITEM.match(current[0])
            or current[0] == "-"
        ):
            blocks.append(current[0])
        else:
            blocks.append(split_inline_sections(" ".join(current)))
        current.clear()

    for line in lines:
        if line == "":
            flush_para()
            if blocks and blocks[-1] != "":
                blocks.append("")
            continue
        if line.startswith("- ") or NUMBERED_ITEM.match(line) or line == "-":
            flush_para()
            blocks.append(line)
            continue
        current.append(line)

    flush_para()

    text_blocks: list[str] = []
    for b in blocks:
        if b == "":
            if text_blocks and text_blocks[-1] != "":
                text_blocks.append("")
            continue
        if "\n\n" in b:
            for part in b.split("\n\n"):
                part = part.strip()
                if part:
                    text_blocks.append(part)
        else:
            text_blocks.append(b)

    while text_blocks and text_blocks[-1] == "":
        text_blocks.pop()

    return "\n\n".join(text_blocks)


def pdf_to_markdown_body(pdf_path: Path) -> str:
    raw = extract_pdf_text(pdf_path)
    if not raw.strip():
        return "_Aucun texte extractible (PDF scanné ? OCR non géré)._"
    lines = raw_to_lines(raw)
    lines = merge_wrapped_lines(lines)
    lines = bullets_to_markdown(lines)
    lines = join_broken_list_items(lines)
    lines = collapse_blank_lines(lines)
    return lines_to_paragraphs(lines)


def build_markdown(pdf_path: Path, body: str, repo_root: Path) -> str:
    title = pdf_path.stem
    try:
        rel = pdf_path.resolve().relative_to(repo_root.resolve())
        source = rel.as_posix()
    except ValueError:
        source = str(pdf_path)
    return f"# {title}\n\n{body}\n"


def write_markdown(
    pdf_path: Path,
    out_dir: Path,
    repo_root: Path,
    *,
    force: bool,
) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    md_path = out_dir / f"{pdf_path.stem}.md"
    if (
        not force
        and md_path.exists()
        and md_path.stat().st_mtime >= pdf_path.stat().st_mtime
    ):
        return md_path

    body = pdf_to_markdown_body(pdf_path)
    md_path.write_text(
        build_markdown(pdf_path, body, repo_root),
        encoding="utf-8",
        newline="\n",
    )
    return md_path


def resolve_input(path: Path) -> Path:
    p = path if path.is_absolute() else REPO_ROOT / path
    if not p.exists():
        raise FileNotFoundError(p)
    return p.resolve()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="PDF Archives Secrètes → Markdown (texte brut)."
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=DEFAULT_INPUT,
        help="Dossier des PDF (défaut : Bibliothèque/Archives Secrètes)",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="Dossier de sortie .md (défaut : …/Archives Secrètes/md)",
    )
    parser.add_argument(
        "--pdf",
        type=Path,
        action="append",
        default=[],
        help="Un PDF précis (répétable). Sinon tous les .pdf du dossier d'entrée.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Réécrire même si le .md est plus récent que le PDF",
    )
    args = parser.parse_args()

    try:
        input_dir = resolve_input(args.input_dir)
        out_dir = (
            args.out_dir.resolve()
            if args.out_dir.is_absolute()
            else (REPO_ROOT / args.out_dir).resolve()
        )
    except FileNotFoundError as e:
        print(f"Erreur : {e}", file=sys.stderr)
        return 1

    if args.pdf:
        pdfs = []
        for p in args.pdf:
            try:
                pdfs.append(resolve_input(p))
            except FileNotFoundError as e:
                print(f"Erreur : {e}", file=sys.stderr)
                return 1
    else:
        pdfs = sorted(input_dir.glob("*.pdf"))

    if not pdfs:
        print(f"Aucun PDF dans {input_dir}", file=sys.stderr)
        return 1

    written = 0
    skipped = 0
    for pdf in pdfs:
        md_path = out_dir / f"{pdf.stem}.md"
        if (
            not args.force
            and md_path.exists()
            and md_path.stat().st_mtime >= pdf.stat().st_mtime
        ):
            print(f"À jour : {md_path.relative_to(REPO_ROOT)}")
            skipped += 1
            continue
        out = write_markdown(pdf, out_dir, REPO_ROOT, force=args.force)
        print(f"Écrit : {out.relative_to(REPO_ROOT)}")
        written += 1

    print(f"Terminé — {written} fichier(s) écrit(s), {skipped} à jour.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
