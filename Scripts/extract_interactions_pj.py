#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extrait les interactions nominatives PJ↔PJ depuis les fiches rôle d'un groupe (`2 - Roles des Joueurs/*.md`),
agrégées par couple (une seule ligne par paire de personnages).

Usage:
  python scripts/extract_interactions_pj.py "Groupes/Mafia - Les Sangs de la Steppe"

Source : uniquement le tableau « Contacts extérieurs » dans chaque rôle (colonnes attache, type, lien).
Les renvois `` `Contrats_et_Livres/…` `` sont complétés par des extraits ; le détail de sortie est rédigé en **phrases**
pour relecture scénariste (plus de chaîne « UBI — Ombre — Tunnel — … »).
Formulations purement orga / vides sont retirées (ex. « croisement possible avec d'autres PJ »).

Ignore les lignes (PNJ), placeholders [nom à trouver], etc.

Sortie : uniquement `interactions_<Slug>_PJ.md` (pas de CSV).
**PJ1 est toujours** un personnage du groupe passé en argument ; lignes **triées par PJ1** puis par PJ2.
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path


PREFIXES = ("maître ", "maitre ", "dame ", "frère ", "frere ", "m. ")

ROLE_DIR_SKIP = frozenset({"README.md"})


def is_role_player_file(path: Path) -> bool:
    name = path.name
    return (
        path.suffix == ".md"
        and name not in ROLE_DIR_SKIP
        and not name.startswith("template_")
    )


def iter_role_files(directory: Path):
    for md in sorted(directory.glob("*.md")):
        if is_role_player_file(md):
            yield md


def fold(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    return "".join(c for c in s if not unicodedata.combining(c)).lower()


def strip_title(s: str) -> str:
    s = s.strip()
    low = s.lower()
    for p in PREFIXES:
        if low.startswith(p):
            return s[len(p) :].strip()
    return s


def normalize_key(name: str) -> str:
    return re.sub(r"\s+", " ", strip_title(name)).strip()


def nom_variants(line: str) -> list[str]:
    line = line.strip()
    out = [line]
    inner = re.sub(r"«[^»]+»\s*", "", line)
    inner = re.sub(r"\s+", " ", inner).strip()
    if inner and inner not in out:
        out.append(inner)
    return out


def collect_registry(groupes_root: Path) -> dict[str, tuple[str, Path, str]]:
    reg: dict[str, tuple[str, Path, str]] = {}
    for roles_dir in groupes_root.glob("**/2 - Roles des Joueurs"):
        if not roles_dir.is_dir():
            continue
        for md in iter_role_files(roles_dir):
            text = md.read_text(encoding="utf-8")
            m = re.search(r"^\| Nom du personnage \| ([^|]+) \|", text, re.MULTILINE)
            if not m:
                continue
            raw = m.group(1).strip()
            group_folder = md.parent.parent.name
            for variant in nom_variants(raw):
                k = fold(normalize_key(variant))
                if k and k not in reg:
                    reg[k] = (variant, md, group_folder)
    corvus = reg.get(fold(normalize_key("Maître Corvus")))
    if corvus:
        reg.setdefault("torven sorel", corvus)
    return reg


def lookup_contact(name: str, reg: dict[str, tuple[str, Path, str]]) -> tuple[str, Path, str] | None:
    n = normalize_key(name)
    k = fold(n)
    if k in reg:
        return reg[k]
    k2 = fold(strip_title(name))
    if k2 in reg:
        return reg[k2]
    parts = k2.split()
    if len(parts) >= 2:
        short = " ".join(parts[-2:])
        for rk, val in reg.items():
            if rk.endswith(short) or rk == short:
                return val
    return None


def is_placeholder(name: str) -> bool:
    n = name.lower()
    if "[" in name or "nom à trouver" in n or "à trouver" in n:
        return True
    if "anonyme" in n and "receveur" in n:
        return True
    if name.strip() in ("—", "-", "…"):
        return True
    return False


def parse_contacts_externes(text: str) -> list[tuple[str, str, str, str]]:
    """Lignes du tableau : personne, attache, type de relation, lien (texte complet de la dernière colonne)."""
    rows: list[tuple[str, str, str, str]] = []
    m = re.search(
        r"### Contacts extérieurs\s*(.*?)(?=^## \S)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    if not m:
        return rows
    block = m.group(1)
    for line in block.splitlines():
        line = line.strip()
        if not line.startswith("|") or re.match(r"^\|\s*---", line):
            continue
        parts = [p.strip() for p in line.split("|")[1:-1]]
        if len(parts) < 4:
            continue
        if parts[0].lower() in ("personne", "élément"):
            continue
        pers, attache, type_rel = parts[0], parts[1], parts[2]
        lien = " | ".join(parts[3:])
        rows.append((pers, attache, type_rel, lien))
    return rows


# Phrases méta / creuses souvent ajoutées en orga (pas du contenu jouable).
_META_STRIP: list[re.Pattern[str]] = [
    re.compile(
        r"\s*;\s*croisement possible avec d'autres PJ sur le même fil\.?",
        re.IGNORECASE,
    ),
    re.compile(
        r"\s*\(chevauchement volontaire[^)]*\)",
        re.IGNORECASE,
    ),
]


def strip_meta_phrases(s: str) -> str:
    t = s.strip()
    for pat in _META_STRIP:
        t = pat.sub("", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def _paths_in_backticks(text: str) -> list[str]:
    return re.findall(r"`([^`]+\.md)`", text)


def extract_playable_excerpt(md_path: Path, max_len: int = 420) -> str:
    """Extrait un passage jouable depuis un .md du dépôt (pièces Contrats_et_Livres, codes cinq lettres, etc.)."""
    try:
        raw = md_path.read_text(encoding="utf-8")
    except OSError:
        return ""
    # Bloc « Contenu » (plusieurs variantes)
    for pat in (
        r"^## Contenu déchiffré[^\n]*\n+(.*?)(?=^---|\n## |\Z)",
        r"^## Contenu[^\n]*\n+(.*?)(?=^---|\n## |\Z)",
        r"^### De la Dette[^\n]*\n+(.*?)(?=^### |\n## |\Z)",
        r"^## Parties[^\n]*\n+(.*?)(?=^---|\n## |\Z)",
    ):
        m = re.search(pat, raw, re.MULTILINE | re.DOTALL | re.IGNORECASE)
        if m:
            body = m.group(1).strip()
            break
    else:
        if "---" in raw:
            tail = raw.split("---", 1)[1]
            body = tail.split("---")[0] if "---" in tail else tail
        else:
            body = raw
        body = body.strip()
    lines: list[str] = []
    for ln in body.splitlines():
        s = ln.strip()
        if not s or s.startswith("#"):
            continue
        if s.startswith("*Référence") or s.startswith("*référence"):
            continue
        if s.startswith("```"):
            continue
        lines.append(s)
    text = " ".join(lines)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"`[^`]+`", "", text)
    # Indications de mise en forme scénique (*[Écriture…]*) peu utiles dans la synthèse
    text = re.sub(r"\*\[[^\]]*\]\*\s*", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        text = re.sub(r"\s+", " ", body.replace("#", " "))[:max_len]
    if len(text) > max_len:
        return text[: max_len - 1].rstrip() + "…"
    return text


def humanize_lien_for_scenariste(lien_col: str) -> str:
    """Remplace les chemins `` `…/fichier.md` `` par le nom court de la pièce ; garde le reste du texte jouable."""
    t = strip_meta_phrases(lien_col)
    if not t:
        return ""

    def repl_backtick(m: re.Match[str]) -> str:
        path = m.group(1).replace("\\", "/")
        stem = Path(path).stem
        return f"« {stem} »"

    t = re.sub(r"`([^`]+\.md)`", repl_backtick, t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def shorten_lien_if_doc_covers_ref(lien_h: str, docs: str) -> str:
    """Retire du résumé Lien les « STEM » déjà développés dans les extraits (évite codes pièce répétés)."""
    if not lien_h or not docs:
        return lien_h
    t = lien_h.strip()
    docs_s = docs.strip()

    def stem_in_docs(stem: str) -> bool:
        s = stem.strip()
        return bool(s) and s in docs_s

    # Enlève en tête les « STEM », « STEM2 », … tant que chaque STEM est déjà dans les extraits
    while True:
        m = re.match(r"^«\s*([^»]+)\s*»\s*(?:,\s*)?", t)
        if not m:
            break
        stem = m.group(1)
        if stem_in_docs(stem):
            t = t[m.end() :].strip()
        else:
            break

    # Cas « STEM » — reste (une seule pièce)
    m2 = re.match(r"^«\s*([^»]+)\s*»\s*—\s*(.*)$", t)
    if m2 and stem_in_docs(m2.group(1)):
        t = m2.group(2).strip()

    t = re.sub(r"^\s*—\s*", "", t)
    t = re.sub(r"\s+", " ", t).strip(" —.")
    return t


def expand_contrats_excerpts(repo_root: Path, lien_col: str) -> str:
    """Pour chaque `…/Contrats_et_Livres/….md` cité, ajoute un extrait du texte du document."""
    rr = repo_root.resolve()
    contrats = rr / "Contrats_et_Livres"
    resolved_paths: list[Path] = []
    seen: set[str] = set()
    for rel in _paths_in_backticks(lien_col):
        rel_norm = rel.replace("\\", "/").strip()
        if rel_norm.startswith("Contrats_et_Livres/"):
            path = (rr / rel_norm).resolve()
        elif "/" not in rel_norm and rel_norm.lower().endswith(".md"):
            path = (contrats / rel_norm).resolve()
        else:
            continue
        try:
            path.relative_to(contrats)
        except ValueError:
            continue
        if not path.is_file():
            continue
        key = str(path)
        if key in seen:
            continue
        seen.add(key)
        resolved_paths.append(path)

    if not resolved_paths:
        return ""

    # Plusieurs pièces dans une même cellule : éviter des lignes illisibles (le rôle garde la liste complète).
    max_docs = 2
    extra_note = ""
    n_all = len(resolved_paths)
    if n_all > max_docs:
        n_skip = n_all - max_docs
        extra_note = (
            " (+1 autre pièce : voir la colonne Lien du rôle.)"
            if n_skip == 1
            else f" (+{n_skip} autres pièces : voir la colonne Lien du rôle.)"
        )
        resolved_paths = resolved_paths[:max_docs]

    per_cap = 280 if len(resolved_paths) > 1 else 360
    excerpts: list[str] = []
    for path in resolved_paths:
        ex = extract_playable_excerpt(path, max_len=per_cap)
        if ex:
            excerpts.append(f"{path.stem} : {ex}")
    if not excerpts:
        return ""
    return " ".join(excerpts) + extra_note


def compose_scenariste_detail(
    src_label: str,
    other_name: str,
    attache: str,
    type_rel: str,
    lien_col: str,
    repo_root: Path,
) -> str:
    """
    Texte lisible pour relecture scénariste : qui, quel cadre, quoi jouer,
    ce que disent les pièces — sans chaîne « UBI — Ombre — Tunnel — … ».
    """
    att = attache.strip()
    typ = type_rel.strip()
    lien_h = humanize_lien_for_scenariste(lien_col)
    docs = expand_contrats_excerpts(repo_root, lien_col)

    chunks: list[str] = []

    # 1) Ancrage lisible (sans chaîne « UBI — Ombre — Tunnel »)
    if att:
        chunks.append(
            f"{src_label} a inscrit {other_name} comme contact extérieur dans le tableau « Contacts extérieurs », avec pour cadre : {att}."
        )
    else:
        chunks.append(f"{src_label} a inscrit {other_name} comme contact extérieur.")

    # 2) Type nommé dans le rôle
    if typ:
        chunks.append(f"Le rôle nomme ce lien : « {typ} ».")

    # 3) D'abord la substance des pièces (concret), puis ce que le rôle ajoute (souvent l'angle PJ)
    if docs:
        chunks.append(f"Ce que disent les pièces citées (extraits) : {docs}")
    lien_rest = shorten_lien_if_doc_covers_ref(lien_h, docs)
    if lien_rest:
        chunks.append(f"Ce que la fiche ajoute par rapport aux seules pièces : {lien_rest.rstrip('.')}.")
    if not typ and not lien_h and not docs:
        chunks.append("Le tableau ne fournit pas assez de détail dans cette fiche (à compléter en orga).")

    # 4) Contrôle relecture croisée (objectif : deux rôles jouables)
    chunks.append(
        f"Contrôle scénariste : la fiche de {other_name} et celle de {src_label} donnent-elles chacune assez de chapitres pour jouer la même interaction (amorcer, réagir, enjeu partagé) ?"
    )

    return " ".join(chunks)


def source_pj_from_file(text: str) -> str | None:
    m = re.search(r"^\| Nom du personnage \| ([^|]+) \|", text, re.MULTILINE)
    return m.group(1).strip() if m else None


def short_pj_label(name: str) -> str:
    if " (" in name:
        return name.split(" (", 1)[0].strip()
    return name.strip()


def oriented_pair(
    local_name: str, local_group: str, other_name: str, other_group: str
) -> tuple[str, str, str, str]:
    """Couple orienté : toujours (PJ du groupe scanné, son groupe, l'autre PJ, son groupe)."""
    return (
        short_pj_label(local_name),
        local_group,
        short_pj_label(other_name),
        other_group.strip(),
    )


def run(group_path: Path, groupes_root: Path, repo_root: Path) -> str:
    reg = collect_registry(groupes_root)
    roles_dir = group_path / "2 - Roles des Joueurs"
    if not roles_dir.is_dir():
        sys.stderr.write(f"Pas de dossier : {roles_dir}\n")
        sys.exit(1)

    local_group_name = group_path.name
    # snippets par couple : clé (PJ local, groupe local, autre PJ, autre groupe) — PJ local en tête
    aggregated: dict[tuple[str, str, str, str], list[str]] = defaultdict(list)

    for f in iter_role_files(roles_dir):
        text = f.read_text(encoding="utf-8")
        src = source_pj_from_file(text)
        if not src:
            continue
        src_label = short_pj_label(src)
        src_key = fold(normalize_key(nom_variants(src)[0]))

        for pers, attache, type_rel, lien in parse_contacts_externes(text):
            if is_placeholder(pers):
                continue
            if "(PNJ)" in attache or "(pnj)" in attache.lower():
                continue

            lien = lien.strip()
            hit = lookup_contact(pers, reg)

            if not hit:
                n2, g2 = short_pj_label(pers.strip()), attache.strip()
                k = oriented_pair(src_label, local_group_name, n2, g2)
                vue = compose_scenariste_detail(src_label, n2, attache, type_rel, lien, repo_root)
                if vue not in aggregated[k]:
                    aggregated[k].append(vue)
                continue

            c_display, c_path, c_group = hit
            c_key = fold(normalize_key(c_display))
            if c_key == src_key:
                continue
            if c_path.parent.parent == roles_dir.parent:
                continue

            n2, g2 = short_pj_label(c_display), c_group
            k = oriented_pair(src_label, local_group_name, n2, g2)
            vue = compose_scenariste_detail(src_label, n2, attache, type_rel, lien, repo_root)
            if vue not in aggregated[k]:
                aggregated[k].append(vue)

    rows_out: list[dict] = []
    for (p1, g1, p2, g2), vues in sorted(
        aggregated.items(),
        key=lambda x: (
            fold(normalize_key(x[0][0])),
            fold(normalize_key(x[0][2])),
        ),
    ):
        detail = " ".join(vues).strip()
        rows_out.append(
            {
                "pj1": p1,
                "pj2": p2,
                "groupe2": g2,
                "detail": detail,
            }
        )

    group_label = group_path.name
    slug = group_label.split(" - ")[0].replace(" ", "_")
    lines: list[str] = [
        f"# Interactions nominatives (PJ) — {group_label}",
        "",
        f"**Fichier** : généré depuis les rôles (`2 - Roles des Joueurs/*.md`). Compléter au besoin avec la vue intrigue du groupe dans `1 - Back de groupe/`.",
        "**Commande** : `python scripts/extract_interactions_pj.py \"Groupes/…\"`",
        "",
        "Une ligne par **couple** ; le **premier personnage** est toujours un membre de ce groupe (le nom du groupe est celui du titre ci-dessus), lignes **classées par ce personnage** puis par le contact. La colonne **Détail** est rédigée pour une **relecture scénariste** : phrases complètes (qui contacte qui, cadre, type de relation, contenu jouable issu du rôle, extraits des pièces citées), puis une phrase de contrôle pour vérifier que les deux fiches permettent de jouer la même interaction.",
        "",
        "| Personnage | Contact | Groupe du contact | Détail des interactions |",
        "|---|---|---|---|",
    ]
    for r in rows_out:
        d = r["detail"].replace("|", "\\|")
        lines.append(
            f"| {r['pj1']} | {r['pj2']} | {r['groupe2']} | {d} |"
        )
    lines.append("")

    return "\n".join(lines)


def main() -> None:
    ap = argparse.ArgumentParser(description="Extraire interactions PJ par couple depuis les rôles d'un groupe.")
    ap.add_argument(
        "groupe",
        nargs="?",
        default="Groupes/Mafia - Les Sangs de la Steppe",
        help="Chemin du dossier groupe (ex. Groupes/Mafia - Les Sangs de la Steppe)",
    )
    ap.add_argument(
        "--root",
        type=Path,
        default=None,
        help="Racine du dépôt (parent de Groupes/).",
    )
    args = ap.parse_args()
    script_dir = Path(__file__).resolve().parent
    repo_root = args.root or script_dir.parent
    groupes_root = repo_root / "Groupes"
    group_path = (repo_root / args.groupe).resolve() if not Path(args.groupe).is_absolute() else Path(args.groupe)

    if not group_path.is_dir():
        sys.stderr.write(f"Dossier introuvable : {group_path}\n")
        sys.exit(1)

    md_text = run(group_path, groupes_root, repo_root)
    back = group_path / "1 - Back de groupe"
    back.mkdir(parents=True, exist_ok=True)
    slug = group_path.name.split(" - ")[0].replace(" ", "_")
    out_md = back / f"interactions_{slug}_PJ.md"
    out_md.write_text(md_text, encoding="utf-8", newline="\n")
    print(f"Écrit : {out_md}")


if __name__ == "__main__":
    main()
