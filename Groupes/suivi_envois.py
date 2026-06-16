from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
import json
import re


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "suivides envois.md"
EMAIL_LOG = ROOT / "suivi_envois_emails.json"

GROUP_ROLE_DIRS = [
    "Tripot/2 - Roles des Joueurs",
    "MiVI/2 - Roles des Joueurs",
    "Mafia - Les Sangs de la Steppe/2 - Roles des Joueurs",
    "Banquiers - UBI/2 - Roles des Joueurs",
    "Palyr/2 - Roles des Joueurs",
]

IGNORED_MD_NAMES = {
    "README.md",
}

EXPORT_SUFFIX_RE = re.compile(r"_[0-9]{8}_[0-9]{6}$")


@dataclass(frozen=True)
class RoleExportStatus:
    group: str
    md_path: Path
    md_date: datetime
    pdf_path: Path | None
    pdf_date: datetime | None
    email_prepared_at: str

    @property
    def status(self) -> str:
        if self.pdf_path is None or self.pdf_date is None:
            return "PDF manquant"
        if self.pdf_date < self.md_date:
            return "PDF ancien"
        return "PDF à jour"


def normalized_stem(path: Path) -> str:
    stem = EXPORT_SUFFIX_RE.sub("", path.stem)
    return stem.casefold()


def file_date(path: Path) -> datetime:
    return datetime.fromtimestamp(path.stat().st_mtime)


def format_date(value: datetime | None) -> str:
    if value is None:
        return "-"
    return value.strftime("%Y-%m-%d %H:%M")


def load_email_log() -> dict[str, str]:
    if not EMAIL_LOG.exists():
        return {}

    try:
        raw = json.loads(EMAIL_LOG.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError:
        return {}

    email_log: dict[str, str] = {}
    for key, value in raw.items():
        normalized_key = key.removeprefix("Groupes/")
        if isinstance(value, str):
            email_log[normalized_key] = value
        elif isinstance(value, dict):
            prepared_at = value.get("prepared_at", "")
            if isinstance(prepared_at, str):
                email_log[normalized_key] = prepared_at
    return email_log


def collect_statuses() -> list[RoleExportStatus]:
    statuses: list[RoleExportStatus] = []
    email_log = load_email_log()

    for relative_dir in GROUP_ROLE_DIRS:
        role_dir = ROOT / relative_dir
        if not role_dir.exists():
            continue

        pdfs_by_stem: dict[str, list[Path]] = {}
        for pdf_path in role_dir.glob("*.pdf"):
            pdfs_by_stem.setdefault(normalized_stem(pdf_path), []).append(pdf_path)

        for md_path in sorted(role_dir.glob("*.md"), key=lambda path: path.name.casefold()):
            if md_path.name in IGNORED_MD_NAMES:
                continue

            candidates = pdfs_by_stem.get(normalized_stem(md_path), [])
            latest_pdf = max(candidates, key=lambda path: path.stat().st_mtime, default=None)

            statuses.append(
                RoleExportStatus(
                    group=role_dir.parent.name,
                    md_path=md_path,
                    md_date=file_date(md_path),
                    pdf_path=latest_pdf,
                    pdf_date=file_date(latest_pdf) if latest_pdf is not None else None,
                    email_prepared_at=email_log.get(markdown_link(md_path), "-"),
                )
            )

    return statuses


def markdown_link(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def render_statuses(statuses: list[RoleExportStatus]) -> str:
    generated_at = datetime.now().strftime("%Y-%m-%d %H:%M")
    missing = [status for status in statuses if status.status == "PDF manquant"]
    outdated = [status for status in statuses if status.status == "PDF ancien"]
    current = [status for status in statuses if status.status == "PDF à jour"]

    lines = [
        "# Suivi des envois",
        "",
        f"Rapport généré le {generated_at}.",
        "",
        "Comparaison des dates de modification entre les rôles `.md` et les exports `.pdf` dans les dossiers joueurs des groupes Tripot, MiVI, Mafia, UBI et Palyr.",
        "",
        "## Synthèse",
        "",
        f"- Rôles suivis : {len(statuses)}",
        f"- PDF manquants : {len(missing)}",
        f"- PDF anciens : {len(outdated)}",
        f"- PDF à jour : {len(current)}",
        "",
        "## Détail",
        "",
        "| Statut | Groupe | Fichier MD | Date MD | Fichier PDF | Date PDF | Dernière préparation email |",
        "|---|---|---|---|---|---|---|",
    ]

    status_order = {
        "PDF ancien": 0,
        "PDF manquant": 1,
        "PDF à jour": 2,
    }
    ordered_statuses = sorted(
        statuses,
        key=lambda status: (
            status_order[status.status],
            status.group.casefold(),
            status.md_path.name.casefold(),
        ),
    )

    for status in ordered_statuses:
        pdf = markdown_link(status.pdf_path) if status.pdf_path is not None else "-"
        lines.append(
            "| "
            + " | ".join(
                [
                    status.status,
                    status.group,
                    markdown_link(status.md_path),
                    format_date(status.md_date),
                    pdf,
                    format_date(status.pdf_date),
                    status.email_prepared_at,
                ]
            )
            + " |"
        )

    lines.extend(
        [
            "",
            "## Règle de comparaison",
            "",
            "- Un PDF est `PDF manquant` si aucun export portant le même nom de base que le `.md` n'est trouvé dans le même dossier.",
            "- Un PDF est `PDF ancien` si sa date de modification est antérieure à celle du `.md`.",
            "- Un PDF est `PDF à jour` si sa date de modification est égale ou postérieure à celle du `.md`.",
            "- Les suffixes d'export de type `_YYYYMMDD_HHMMSS` sont ignorés pour rapprocher un PDF de son `.md` source.",
            "- La colonne `Dernière préparation email` vient de `suivi_envois_emails.json`, mis à jour par le script de régénération et préparation des mails.",
        ]
    )

    return "\n".join(lines) + "\n"


def main() -> None:
    statuses = collect_statuses()
    OUTPUT.write_text(render_statuses(statuses), encoding="utf-8")


if __name__ == "__main__":
    main()
