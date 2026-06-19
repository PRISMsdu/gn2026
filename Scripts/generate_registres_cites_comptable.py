#!/usr/bin/env python3
"""Genere un registre comptable markdown courant par cite (extrait UBI, format Arthas)."""

from __future__ import annotations

import csv
import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REG_COMPTA = (
    ROOT
    / "Groupes"
    / "Banquiers - UBI"
    / "3- Compta & registres"
    / "registre_Comptable_UBI_courant.md"
)
CSV_SOURCE = (
    ROOT
    / "Groupes"
    / "Banquiers - UBI"
    / "3- Compta & registres"
    / "Registre_UBI_Orga.csv"
)
REG_CREDOC = (
    ROOT
    / "Groupes"
    / "Banquiers - UBI"
    / "3- Compta & registres"
    / "registre_Credoc_courant.md"
)

REF_RE = re.compile(r"^[A-Z]{2,3}-[IV]+-\d{3}-\d{3}$")
TAGGED_NAME = re.compile(r"([^;(]+)\s*\(([^)]+)\)")
AMOUNT_RE = re.compile(r"([\d']+)\s+couronnes?")
CREDOC_REDEVANCE = 500

CITIES: dict[str, dict[str, object]] = {
    "Arthas": {
        "output_dir": ROOT / "Groupes" / "Arthas" / "1 - Back de groupe",
        "labels": ["Arthas"],
        "bank_labels": ["Arthas"],
        "gentile": "arthassien",
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
        "bank_labels": ["Il-Irion"],
        "gentile": "ilirionien",
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
        "bank_labels": ["Palyr"],
        "gentile": "palyrien",
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
        "bank_labels": ["Sfaal"],
        "gentile": "sfaalien",
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
        "bank_labels": ["Ther-Félis", "Ther-Felis"],
        "gentile": "ther-felisien",
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


@dataclass
class DeposantRow:
    cite: str
    deposant: str
    report: int | None
    cycle: int | None
    cumule: int | None
    depots: int | None = None
    retraits: int | None = None
    solde_annuel: int | None = None


def parse_amount(value: str) -> int | None:
    if not value or "non renseign" in value.lower():
        return None
    m = AMOUNT_RE.search(value.replace("'", "'"))
    if not m:
        return None
    return int(m.group(1).replace("'", ""))


def format_amount(value: int) -> str:
    return f"{value:,}".replace(",", "'") + " couronnes"


def city_article(city: str) -> str:
    return f"d'{city}" if city[0] in "AEIOUÀÂÉÈÊËÎÏÔÙÛÜ" else f"de {city}"


def load_tagged_members() -> dict[str, set[str]]:
    tagged: dict[str, set[str]] = {city: set() for city in CITIES}
    with CSV_SOURCE.open(encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f, delimiter=";"):
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


def year_label(raw_heading: str) -> str:
    m = re.match(r"^(\d{3})", raw_heading.strip())
    return m.group(1) if m else raw_heading.strip()


def parse_table_row(line: str) -> list[str]:
    return [p.strip() for p in line.split("|")[1:-1]]


def parse_compta_sections() -> dict[str, dict[str, list[str]]]:
    text = REG_COMPTA.read_text(encoding="utf-8")
    sections: dict[str, dict[str, list[str]]] = {}
    current_year: str | None = None
    mode: str | None = None

    for line in text.splitlines():
        if line.startswith("## ") and not line.startswith("## Recapitulatif"):
            if "Soldes generaux" in line or "Prêts intercités" in line:
                current_year = None
                continue
            current_year = year_label(line[3:])
            sections[current_year] = {"contracts": [], "banking": [], "balance": []}
            mode = None
            continue
        if line.startswith("## Recapitulatif") or line.startswith("Resume auditeur"):
            current_year = None
            continue
        if current_year is None:
            continue
        if line.startswith("Mouvements bancaires"):
            mode = "banking"
            continue
        if line.startswith("Balance annuelle"):
            mode = "balance"
            continue
        if not line.startswith("|"):
            if line.startswith("Total primes") or line.startswith("Total revenus"):
                mode = None
            continue
        if "---" in line or "Référence contrat" in line or "Client | Cité" in line:
            continue
        if "Cite | Deposant" in line:
            continue
        parts = parse_table_row(line)
        if not parts:
            continue
        if REF_RE.match(parts[0]):
            sections[current_year]["contracts"].append(line)
            mode = "contracts"
        elif mode == "banking" and len(parts) >= 5:
            sections[current_year]["banking"].append(line)
        elif mode == "balance" and len(parts) >= 5:
            sections[current_year]["balance"].append(line)

    return sections


def parse_credoc_courant() -> tuple[list[str], dict[str, list[str]]]:
    text = REG_CREDOC.read_text(encoding="utf-8")
    cadre_lines: list[str] = []
    by_year: dict[str, list[str]] = {}
    current_year: str | None = None
    in_cadre = False

    for line in text.splitlines():
        if line.startswith("## Contrats-cadres actifs"):
            in_cadre = True
            continue
        if line.startswith("## Registre annuel"):
            in_cadre = False
            continue
        if line.startswith("### "):
            current_year = year_label(line[4:])
            by_year.setdefault(current_year, [])
            continue
        if line.startswith("## Recapitulatif"):
            current_year = None
            continue
        if in_cadre and line.startswith("| AC-"):
            cadre_lines.append(line)
        if current_year and line.startswith("| CD-"):
            by_year[current_year].append(line)

    return cadre_lines, by_year


def filter_credoc_cadre_line(lines: list[str], labels: list[str]) -> str | None:
    for line in lines:
        parts = parse_table_row(line)
        if len(parts) >= 2 and matches_city(parts[1], labels, set()):
            return line
    return None


def filter_credoc_year_lines(lines: list[str], labels: list[str]) -> list[str]:
    filtered: list[str] = []
    for line in lines:
        parts = parse_table_row(line)
        if len(parts) >= 3 and matches_city(parts[2], labels, set()):
            filtered.append(line)
    return filtered


def credoc_prime(line: str) -> int:
    parts = parse_table_row(line)
    if len(parts) < 9:
        return 0
    return parse_amount(parts[8]) or 0


def render_credoc_year_block(city: str, year: str, credoc_rows: list[str]) -> list[str]:
    if not credoc_rows:
        return []
    header = (
        "| Reference CREDOC | Date | Contrat-cadre | Couverture | Supports declares | "
        "Assiette garantie | Taux | Prime UBI | Statut |"
    )
    sep = (
        "|------------------|------|---------------|------------|-------------------|"
        "------------------|------|-----------|--------|"
    )
    body_rows: list[str] = []
    for line in credoc_rows:
        parts = parse_table_row(line)
        if len(parts) < 10:
            continue
        body_rows.append(
            f"| {parts[0]} | {parts[1]} | {parts[3]} | {parts[4]} | {parts[5]} | "
            f"{parts[6]} | {parts[7]} | {parts[8]} | {parts[9]} |"
        )
    if not body_rows:
        return []
    label = f"Garanties documentaires CREDOC {year} :"
    if year == "542":
        label = "Garanties documentaires CREDOC 542 depuis Equos :"
    return ["", label, "", header, sep, *body_rows, ""]


def parse_auditor_block(text: str, marker: str) -> list[DeposantRow]:
    rows: list[DeposantRow] = []
    start = text.find(marker)
    if start < 0:
        return rows
    chunk = text[start:]
    in_table = False
    for line in chunk.splitlines():
        if line.startswith("Cumul auditeur par cite et deposant"):
            in_table = True
            continue
        if in_table and line.startswith("## "):
            break
        if in_table and line.startswith("Solde banque"):
            break
        if in_table and line.startswith("|") and "---" not in line and "Cite | Deposant" not in line:
            parts = parse_table_row(line)
            if len(parts) < 5:
                continue
            rows.append(
                DeposantRow(
                    cite=parts[0],
                    deposant=parts[1],
                    report=parse_amount(parts[2]),
                    cycle=parse_amount(parts[3]),
                    cumule=parse_amount(parts[4]),
                )
            )
    return rows


def parse_year_perimetre(text: str) -> dict[str, tuple[int, int, int]]:
    out: dict[str, tuple[int, int, int]] = {}
    capture = False
    for line in text.splitlines():
        if line.startswith("Resume auditeur - cycle"):
            capture = True
            continue
        if capture and line.startswith("| Report precedent global"):
            break
        if capture and line.startswith("|") and "---" not in line and "Perimetre" not in line:
            parts = parse_table_row(line)
            if len(parts) >= 4 and parts[0] != "Total cycle":
                dep = parse_amount(parts[1])
                ret = parse_amount(parts[2])
                net = parse_amount(parts[3])
                if dep is not None and ret is not None and net is not None:
                    out[parts[0]] = (dep, ret, net)
    return out


def filter_city_rows(rows: list[DeposantRow], bank_labels: list[str]) -> list[DeposantRow]:
    labels = set(bank_labels)
    filtered = [
        r
        for r in rows
        if r.cite in labels
        or any(lbl in r.cite for lbl in labels)
        or ("Sous-total" in r.deposant and any(lbl in r.cite for lbl in labels))
    ]
    return filtered


def filter_balance_rows(lines: list[str], bank_labels: list[str]) -> list[DeposantRow]:
    rows: list[DeposantRow] = []
    labels = set(bank_labels)
    for line in lines:
        parts = parse_table_row(line)
        if len(parts) < 5:
            continue
        if parts[0] not in labels:
            continue
        rows.append(
            DeposantRow(
                cite=parts[0],
                deposant=parts[1],
                report=None,
                cycle=None,
                cumule=None,
                depots=parse_amount(parts[2]),
                retraits=parse_amount(parts[3]),
                solde_annuel=parse_amount(parts[4]),
            )
        )
    return rows


def render_balance_table(rows: list[DeposantRow]) -> list[str]:
    lines = [
        "Balance annuelle nette par deposant :",
        "",
        "| Cite | Deposant | Depots | Retraits | Solde annuel |",
        "|------|----------|--------|----------|--------------|",
    ]
    for r in rows:
        lines.append(
            f"| {r.cite} | {r.deposant} | {format_amount(r.depots or 0)} | "
            f"{format_amount(r.retraits or 0)} | {format_amount(r.solde_annuel or 0)} |"
        )
    lines.append("")
    return lines


def render_auditor_table(rows: list[DeposantRow], city: str) -> list[str]:
    lines = [
        "| Cite | Deposant | Report precedent | Solde cycle | Solde cumule |",
        "|------|----------|------------------|-------------|--------------|",
    ]
    for r in rows:
        lines.append(
            f"| {city} | {r.deposant} | {format_amount(r.report or 0)} | "
            f"{format_amount(r.cycle or 0)} | {format_amount(r.cumule or 0)} |"
        )
    return lines


def filter_contract_line(line: str, labels: list[str], members: set[str]) -> bool:
    parts = parse_table_row(line)
    if len(parts) < 4:
        return False
    return matches_city(";".join(parts), labels, members)


def filter_banking_line(line: str, bank_labels: list[str]) -> bool:
    parts = parse_table_row(line)
    if len(parts) < 2:
        return False
    return parts[1] in bank_labels


def contract_revenu(line: str) -> int:
    parts = parse_table_row(line)
    if len(parts) < 6:
        return 0
    return parse_amount(parts[5]) or 0


def banking_prime(line: str) -> int:
    parts = parse_table_row(line)
    if len(parts) < 5:
        return 0
    return parse_amount(parts[4]) or 0


def build_markdown(
    city: str,
    sections: dict[str, dict[str, list[str]]],
    labels: list[str],
    bank_labels: list[str],
    members: set[str],
    gentile: str,
    opening_rows: list[DeposantRow],
    closing_rows: list[DeposantRow],
    year_perimetre: dict[str, tuple[int, int, int]],
    credoc_cadre_line: str | None,
    credoc_by_year: dict[str, list[str]],
) -> str:
    lines = [
        f"# Registre comptable {city} — courant",
        "",
        f"Ce registre reprend, pour la cité {city_article(city)} et ses mandataires, "
        f"les mouvements inscrits à l'UBI depuis le mois d'Equos 542 jusqu'à la fin de l'année 547.",
        "",
        f"Les postes suivants concernent {city} :",
        "",
        "1. **Droits de garde** : contrats déposés où la cité ou l'un de ses signataires est partie.",
        "2. **Primes d'assurance sur dépôts classiques** : mouvements des maisons de la cité à l'UBI.",
        "3. **Redevance contrat-cadre CREDOC** : 500 couronnes par an "
        f"(part {city_article(city)} sur le cadre des cinq cités).",
        "4. **Primes CREDOC** : primes annuelles sur garanties documentaires activées pour la cité.",
        "",
        "## Prêts intercités longs termes",
        "",
        "Aucun prêt intercité long terme du tableau archive n'est actif sur la période courante 542-547.",
        "",
        "## Soldes generaux a l'ouverture (1er Equos 542)",
        "",
    ]

    opening_sub = next((r for r in opening_rows if "Sous-total" in r.deposant), None)
    if opening_sub:
        lines.extend(
            [
                f"Soldes deposants {city} — cumul auditeur a l'ouverture :",
                "",
                "| Report precedent cite | Solde cumule auditeur cite |",
                "|-----------------------|----------------------------|",
                f"| {format_amount(opening_sub.report or 0)} | {format_amount(opening_sub.cumule or 0)} |",
                "",
                "Cumul auditeur par deposant a l'ouverture :",
                "",
                "| Cite | Deposant | Report precedent | Solde cycle (archives) | Solde cumule |",
                "|------|----------|------------------|------------------------|--------------|",
            ]
        )
        for r in opening_rows:
            if "Sous-total" in r.deposant:
                continue
            lines.append(
                f"| {city} | {r.deposant} | {format_amount(r.report or 0)} | "
                f"{format_amount(r.cycle or 0)} | {format_amount(r.cumule or 0)} |"
            )
        if opening_sub:
            lines.append(
                f"| {city} | {opening_sub.deposant} | "
                f"{format_amount(opening_sub.report or 0)} | "
                f"{format_amount(opening_sub.cycle or 0)} | "
                f"{format_amount(opening_sub.cumule or 0)} |"
            )
        lines.append("")

    if credoc_cadre_line:
        lines.extend(
            [
                "## Contrat-cadre CREDOC actif",
                "",
                "| Reference | Cite couverte | Signataire cite | Signataire UBI | "
                "Redevance annuelle | Statut |",
                "|-----------|---------------|-----------------|----------------|"
                "--------------------|--------|",
                credoc_cadre_line,
                "",
            ]
        )

    header_contract = (
        "| Référence contrat | Date de dépôt | Date d'exécution | Signataires | "
        "Montant contrat | Revenu UBI |"
    )
    sep_contract = (
        "|-------------------|---------------|------------------|-------------|"
        "-----------------|------------|"
    )
    header_banking = "| Client | Cité | Dépôts annuels | Retraits annuels | Prime UBI |"
    sep_banking = "|--------|------|----------------|------------------|-----------|"

    totals_garde = 0
    totals_primes = 0
    totals_redevance_credoc = 0
    totals_primes_credoc = 0
    totals_charges = 0
    cycle_dep = 0
    cycle_ret = 0
    cycle_net = 0

    all_years = sorted(set(sections) | set(credoc_by_year))
    for year in all_years:
        raw = sections.get(year, {"contracts": [], "banking": [], "balance": []})
        contracts = [ln for ln in raw["contracts"] if filter_contract_line(ln, labels, members)]
        banking = [ln for ln in raw["banking"] if filter_banking_line(ln, bank_labels)]
        balance = filter_balance_rows(raw["balance"], bank_labels)

        credoc_rows = filter_credoc_year_lines(credoc_by_year.get(year, []), labels)

        if not contracts and not banking and not credoc_rows:
            continue

        heading = f"## {year}" if year != "542" else "## 542 - depuis Equos"
        lines.extend([heading, ""])
        if contracts:
            lines.extend([header_contract, sep_contract, *contracts, ""])

        garde_year = sum(contract_revenu(ln) for ln in contracts)
        primes_year = sum(banking_prime(ln) for ln in banking)

        if banking:
            lines.extend(
                [
                    f"Mouvements bancaires classiques {year} :",
                    "",
                    header_banking,
                    sep_banking,
                    *banking,
                    "",
                ]
            )
        if balance:
            lines.extend(render_balance_table(balance))

        lines.extend(render_credoc_year_block(city, year, credoc_rows))

        redevance_year = CREDOC_REDEVANCE
        primes_credoc_year = sum(credoc_prime(ln) for ln in credoc_rows)
        charges_year = garde_year + primes_year + redevance_year + primes_credoc_year

        totals_garde += garde_year
        totals_primes += primes_year
        totals_redevance_credoc += redevance_year
        totals_primes_credoc += primes_credoc_year
        totals_charges += charges_year

        sub = next((r for r in balance if "Sous-total" in r.deposant), None)
        if sub and sub.solde_annuel is not None:
            cycle_net += sub.solde_annuel
            cycle_dep += sub.depots or 0
            cycle_ret += sub.retraits or 0

        if garde_year:
            lines.append(
                f"Total droits de garde (contrats {city}) {year} : {format_amount(garde_year)}."
            )
        if primes_year:
            lines.append(f"Total primes UBI sur dépôts {year} : {format_amount(primes_year)}.")
        if primes_credoc_year:
            lines.append(
                f"Primes CREDOC garanties documentaires {year} : "
                f"{format_amount(primes_credoc_year)}."
            )
        lines.append(
            f"Redevance contrat-cadre CREDOC {city} {year} : {format_amount(redevance_year)}."
        )
        lines.append(f"Total charges {city} {year} : {format_amount(charges_year)}.")
        lines.append("")

    closing_sub = next((r for r in closing_rows if "Sous-total" in r.deposant), None)
    lines.extend(
        [
            f"Resume auditeur {city} — cycle 542 depuis Equos - 547 :",
            "",
            f"Le solde cumule reprend l'ouverture auditeur au 1er Equos 542 et les soldes annuels nets "
            f"des deposants {gentile}s sur la periode courante.",
            "",
            "| Perimetre | Depots | Retraits | Solde net |",
            "|-----------|--------|----------|-----------|",
        ]
    )
    for year in sorted(sections):
        sub = filter_balance_rows(sections[year]["balance"], bank_labels)
        row = next((r for r in sub if "Sous-total" in r.deposant), None)
        if row and row.depots is not None:
            lines.append(
                f"| {year} | {format_amount(row.depots)} | {format_amount(row.retraits or 0)} | "
                f"{format_amount(row.solde_annuel or 0)} |"
            )
    if closing_sub:
        lines.append(
            f"| Total cycle | {format_amount(cycle_dep)} | {format_amount(cycle_ret)} | "
            f"{format_amount(cycle_net)} |"
        )
    lines.append("")
    if closing_sub:
        lines.extend(
            [
                f"Soldes deposants {city} — clôture du cycle courant :",
                "",
                "| Report precedent cite | Solde du cycle | Solde cumule auditeur cite |",
                "|-----------------------|----------------|----------------------------|",
                f"| {format_amount(closing_sub.report or 0)} | {format_amount(closing_sub.cycle or 0)} | "
                f"{format_amount(closing_sub.cumule or 0)} |",
                "",
                "Cumul auditeur par deposant en clôture :",
                "",
                *render_auditor_table(closing_rows, city),
                "",
            ]
        )

    deposant_details = [
        f"{r.deposant} {r.cumule:,}".replace(",", "'")
        for r in closing_rows
        if "Sous-total" not in r.deposant and r.cumule is not None
    ]
    encours = format_amount(closing_sub.cumule or 0) if closing_sub else "0 couronne"

    lines.extend(
        [
            "## Recapitulatif general",
            "",
            "Periode couverte : 542 depuis Equos - 547.",
            "",
            "| Poste | Total cumule |",
            "|-------|-------------|",
            f"| Droits de garde contrats | {format_amount(totals_garde)} |",
            f"| Primes d'assurance sur depots classiques (1 %) | {format_amount(totals_primes)} |",
            f"| Primes CREDOC garanties documentaires | {format_amount(totals_primes_credoc)} |",
            f"| Redevance contrat-cadre CREDOC (500 couronnes/an) | {format_amount(totals_redevance_credoc)} |",
            f"| **Total charges {city} cumulees** | **{format_amount(totals_charges)}** |",
            "",
            f"Encours deposants {city} a l'UBI en clôture : {encours} "
            f"({'; '.join(deposant_details)}).",
            "",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def main() -> None:
    text = REG_COMPTA.read_text(encoding="utf-8")
    sections = parse_compta_sections()
    credoc_cadre_all, credoc_by_year_all = parse_credoc_courant()
    tagged = load_tagged_members()
    opening_all = parse_auditor_block(text, "Soldes generaux a l'ouverture")
    closing_all = parse_auditor_block(text, "Resume auditeur - cycle 542")

    target_cities = list(CITIES.keys())
    if len(__import__("sys").argv) > 1:
        target_cities = __import__("sys").argv[1:]

    for city in target_cities:
        if city not in CITIES:
            raise SystemExit(f"Cite inconnue : {city}")
        cfg = CITIES[city]
        labels: list[str] = cfg["labels"]  # type: ignore[assignment]
        bank_labels: list[str] = cfg["bank_labels"]  # type: ignore[assignment]
        gentile: str = cfg["gentile"]  # type: ignore[assignment]
        out_dir: Path = cfg["output_dir"]  # type: ignore[assignment]
        members = set(cfg["members"]) | tagged[city]  # type: ignore[arg-type]
        out_dir.mkdir(parents=True, exist_ok=True)

        opening_rows = filter_city_rows(opening_all, bank_labels)
        closing_rows = filter_city_rows(closing_all, bank_labels)
        credoc_cadre = filter_credoc_cadre_line(credoc_cadre_all, labels)
        credoc_by_year = {
            year: filter_credoc_year_lines(rows, labels)
            for year, rows in credoc_by_year_all.items()
        }

        content = build_markdown(
            city,
            sections,
            labels,
            bank_labels,
            members,
            gentile,
            opening_rows,
            closing_rows,
            {},
            credoc_cadre,
            credoc_by_year,
        )
        out_path = out_dir / f"registre_{city}_comptable_courant.md"
        out_path.write_text(content, encoding="utf-8")
        print(f"{city} -> {out_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
