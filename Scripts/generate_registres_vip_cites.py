#!/usr/bin/env python3
"""Génère les registres VIP par cité depuis Registre_compta_VIP_UBI.md."""

import re
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "Groupes/Banquiers - UBI/3- Compta & registres/Registre_compta_VIP_UBI.md"

ROW = re.compile(
    r"^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$"
)

CONVENTION = """Convention interne :

- **Montant brut** : somme entrée au Tripot sous couverture de perte, dette de salon ou tournoi privé.
- **Commission Edorian** : 30 % du montant brut, prélevée par Edorian et ses relais.
- **Dépôt banque** : 70 % du montant brut, versés aux coffres de l'UBI et stockés hors registres officiels."""

DOSSIERS = {
    "Il-Irion": [
        ("DC-IV-542-001", "542-543", "30'000 c", "chantage sur capitaines, passages non déclarés et faux retours de cale"),
        ("DC-IV-543-002", "543-544", "30'600 c", "vente de points de contact à la Styrgie et protection de messagers"),
        ("DC-IV-543-003", "543-545", "29'100 c", "séquestration de témoins et pression sur familles de dockers"),
        ("DC-IV-544-004", "544-545", "30'900 c", "vol de charbon de forge, lames de guerre et plaques militaires"),
        ("DC-IV-544-005", "544-546", "30'800 c", "libération de bandits, transfert de prisonniers et achat de gardes"),
        ("DC-IV-545-006", "545-546", "30'650 c", "enlèvement de témoins et neutralisation d'auditions"),
        ("DC-IV-545-007", "545-547", "30'400 c", "vente d'horaires de phares et routes de guerre"),
        ("DC-IV-546-008", "546-547", "29'950 c", "assassinats commandés et disparitions de courriers"),
    ],
    "Palyr": [
        ("DC-IV-546-017", "546", "17'300 c", "chantage sur armateurs et familles du port"),
        ("DC-IV-546-018", "546-547", "22'300 c", "vente d'informations portuaires à Aquilea"),
        ("DC-IV-547-019", "547", "25'400 c", "achat de voix, menace sur greffiers et faux actes"),
        ("DC-IV-547-020", "547", "17'200 c", "sabotages et abandons d'équipage"),
    ],
    "Arthas": [
        ("DC-IV-546-009", "546", "21'600 c", "libération de bandits utiles aux forges d'Arthas"),
        ("DC-IV-546-010", "546-547", "23'800 c", "livraison de lames, harnois et carreaux sous fausse marchandise"),
        ("DC-IV-547-011", "547", "12'300 c", "enlèvement de dignitaires secondaires pour peser sur les votes"),
        ("DC-IV-547-012", "547", "12'400 c", "assassinats confiés à des exécuteurs extérieurs"),
    ],
    "Ther-Félis": [
        ("DC-IV-546-013", "546", "21'400 c", "prise d'otages dans les domaines nourriciers"),
        ("DC-IV-546-014", "546-547", "22'000 c", "sabotage de navires et achat de capitaines ruinés"),
        ("DC-IV-547-015", "547", "17'500 c", "tortures et aveux imposés"),
        ("DC-IV-547-016", "547", "15'600 c", "livraison de blessés et de substances interdites"),
    ],
    "Sfaal": [
        ("DC-IV-546-021", "546", "23'500 c", "livraison de fer militaire hors routes"),
        ("DC-IV-546-022", "546-547", "18'600 c", "enlèvement de clercs et menaces contre familles"),
        ("DC-IV-547-023", "547", "12'400 c", "recrutement de briseurs de grève et tueurs de quai"),
        ("DC-IV-547-024", "547", "14'900 c", "vente de routes sûres à pirates et agents étrangers"),
    ],
}

INTROS = {
    "Il-Irion": """## Ho les vilains… !

Les sept grandes familles d'Il-Irion affichent encore une cité prospère. Plusieurs maisons sont proches du gouffre : dettes de chantiers, reports de taux, créances impayées sur la marine.

Il y a cinq ans, Cyrion Valdris et Seraphin Kaelthorne font monter Edorian au poste de directeur général de l'agence d'Ulghart. Ils veulent organiser des détournements au profit des maisons ilirioniennes. Edorian accepte. Le cercle restreint de la banque sortante prépare en parallèle de doubler les familles et de faire tomber Valdris et Kaelthorne.

Les contrats VIP répondent à ce besoin. Un relais ilirionien règle au Tripot d'Ulghart une somme liée à un service discret. La couverture est une perte aux cartes, une dette de salon ou un pari de régate. Edorian prélève trente pour cent. Les soixante-dix pour cent restants sont versés aux coffres de l'UBI et stockés hors registres officiels.

Ce document reprend les mouvements imputés à Il-Irion. Les dossiers DC-IV ci-dessous décrivent les contrats réels. Les références FC-IV du tableau en sont les règlements partiels passés au Tripot.

La Régate fixe l'échéance. L'argent versé par ce circuit est dans les coffres de la banque, mais absent des comptes que la cité peut présenter en clôture. Il faut le récupérer discrètement avant la passation du mandat UBI. Si les autres cités apprennent qu'Il-Irion utilise ce circuit depuis 542, la coalition se brise.""",

    "Palyr": """## Ho les vilains… !

Palyr manque de trésorerie. Le dernier chargement de minerai en provenance de Sfaal a bloqué les forges. Les taux de l'UBI ont monté sous Edorian. Des dossiers demandés au coffre restent introuvables. Le Conseil doit honorer des commandes militaires sans pouvoir tout montrer au registre public.

On ne sait plus qui a pris contact en premier : Edorian ou des relais palyriens. Le mécanisme existe depuis 546. Un émissaire ou un perdant désigné apporte une somme au Tripot d'Ulghart. La couverture est une perte de jeu ou une dette de salon. Edorian prélève trente pour cent. Les soixante-dix pour cent restants sont versés aux coffres de l'UBI et stockés hors registres officiels.

Ce document reprend les mouvements imputés à Palyr. Les dossiers DC-IV ci-dessous décrivent les contrats réels. Les références FC-IV du tableau en sont les règlements partiels.

La passation du mandat UBI arrive avec la Régate. L'argent versé par ce circuit est dans les coffres de la banque, mais absent des comptes que la délégation peut présenter en clôture. Il faut le récupérer discrètement avant la transmission. Si une autre cité apprend que Palyr a payé des actes illégaux par l'UBI, les négociations sur le fer et sur le conseil de la banque s'arrêtent.""",

    "Arthas": """## Ho les vilains… !

Arthas garde une part importante de ses avoirs et de ses dossiers sensibles dans les coffres de l'UBI. Des prêts bilatéraux signés il y a quatre ans coûtent plus cher que prévu. Plusieurs maisons marchandes doivent régler des soldes que le registre public ne peut pas absorber sans alerter un auditeur.

On ne sait plus qui a pris contact en premier : Edorian ou des relais d'Arthas. Le mécanisme existe depuis 546. Un VIP apporte une somme au Tripot d'Ulghart et la perd aux cartes ou en tournoi privé. Edorian prélève trente pour cent. Les soixante-dix pour cent restants sont versés aux coffres de l'UBI et stockés hors registres officiels.

Ce document reprend les mouvements imputés à Arthas. Les dossiers DC-IV ci-dessous décrivent les contrats réels. Les références FC-IV du tableau en sont les règlements partiels.

La passation du mandat UBI fixe l'échéance. L'argent versé par ce circuit est dans les coffres de la banque, mais absent des comptes que la délégation peut présenter en clôture. Il faut le récupérer discrètement avant la Régate. Si une autre cité apprend qu'Arthas a payé des actes illégaux par l'UBI, la délégation perd sa marge au conseil de la banque.""",

    "Ther-Félis": """## Ho les vilains… !

Ther-Félis cumule des dettes bancaires et des engagements portuaires qu'elle ne peut plus assumer au registre public. La flotte vieillit. Les prêts signés avec l'UBI coûtent plus cher que les taux annoncés à la signature. Des priorités de quai, des silences et des services discrets doivent se payer sans écriture politique publique.

On ne sait plus qui a pris contact en premier : Edorian ou des relais ther-félisiens. Le mécanisme existe depuis 546. Un VIP apporte une somme au Tripot d'Ulghart sous couverture de perte arrangée, de dette de salon ou de tournoi privé. Edorian prélève trente pour cent. Les soixante-dix pour cent restants sont versés aux coffres de l'UBI et stockés hors registres officiels.

Ce document reprend les mouvements imputés à Ther-Félis. Les dossiers DC-IV ci-dessous décrivent les contrats réels. Les références FC-IV du tableau en sont les règlements partiels.

La passation du mandat UBI arrive avec la Régate. L'argent versé par ce circuit est dans les coffres de la banque, mais absent des comptes que la délégation peut présenter en clôture. Il faut le récupérer discrètement avant la transmission. Si une autre cité apprend que Ther-Félis a payé des actes illégaux par l'UBI, l'alliance confédérale se brise.""",

    "Sfaal": """## Ho les vilains… !

Sfaal porte le dossier fer et ses accords commerciaux avec Palyr. Les conséquences du dernier chargement doivent se régler hors procédure ouverte. Plusieurs maisons ont des engagements que les registres publics ne peuvent pas absorber sans provoquer une rupture avec le Levant des Forges ou avec Il-Irion.

On ne sait plus qui a pris contact en premier : Edorian ou des relais sfaaliens. Le mécanisme existe depuis 546. Un VIP apporte une somme au Tripot d'Ulghart sous couverture de jeu. Edorian prélève trente pour cent. Les soixante-dix pour cent restants sont versés aux coffres de l'UBI et stockés hors registres officiels.

Ce document reprend les mouvements imputés à Sfaal. Les dossiers DC-IV ci-dessous décrivent les contrats réels. Les références FC-IV du tableau en sont les règlements partiels.

La passation du mandat UBI arrive avec la Régate. L'argent versé par ce circuit est dans les coffres de la banque, mais absent des comptes que la délégation peut présenter en clôture. Il faut le récupérer discrètement avant la transmission. Si une autre cité apprend que Sfaal a payé des actes illégaux par l'UBI, le procès du chargement défectueux passe au second plan.""",
}

PATHS = {
    "Il-Irion": ROOT / "Groupes/Il-Irion/1 - Back de groupe/registre_VIP_Il-Irion.md",
    "Palyr": ROOT / "Groupes/Palyr/1 - Back de groupe/registre_VIP_Palyr.md",
    "Arthas": ROOT / "Groupes/Arthas/1 - Back de groupe/registre_VIP_Arthas.md",
    "Ther-Félis": ROOT / "Groupes/Ther-Félis/1 - Back de groupe/registre_VIP_Ther-Félis.md",
    "Sfaal": ROOT / "Groupes/Sfaal/Back de groupe/registre_VIP_Sfaal.md",
}

CUM = {
    "Il-Irion": ("180 600", "54 180", "126 420"),
    "Palyr": ("61 300", "18 390", "42 910"),
    "Sfaal": ("50 800", "15 240", "35 560"),
    "Arthas": ("25 100", "7 530", "17 570"),
    "Ther-Félis": ("24 600", "7 380", "17 220"),
}

TABLE_HEADER = (
    "| Date | Réf | Couverture | Montant brut | Commission Edorian 30 % | Dépôt banque 70 % |\n"
    "|---|---|---|---:|---:|---:|"
)
CLOSURE_HEADER = (
    "| Année | Montant brut | Commission Edorian 30 % | Dépôt banque 70 % |\n"
    "|---|---:|---:|---:|"
)


def format_row(r):
    """r = date, ref, cover, brut, tripot, edorian, nette — fusionne tripot+edorian."""
    date, ref, cover, brut, tripot, edorian, nette = r
    commission = int(tripot.replace(" ", "")) + int(edorian.replace(" ", ""))
    commission_s = f"{commission:,}".replace(",", " ") if commission >= 1000 else str(commission)
    return f"| {date} | {ref} | {cover} | {brut} | {commission_s} | {nette} |"


def format_closure(year, c):
    """c = brut, tripot, edorian, perte, nette from master."""
    return f"| {year} | {c[0]} | {c[3]} | {c[4]} |"


def parse_master():
    text = MASTER.read_text(encoding="utf-8")
    by_city = defaultdict(lambda: defaultdict(list))
    closures = defaultdict(dict)
    current_year = None
    in_closure = False

    for line in text.splitlines():
        if line.startswith("## Récapitulatif"):
            in_closure = False
            continue
        if line.startswith("### Clôture"):
            in_closure = True
            continue
        m = re.match(r"^## (\d{3})$", line)
        if m:
            current_year = m.group(1)
            in_closure = False
            continue
        if line.startswith("### ") and not line.startswith("### Clôture"):
            in_closure = False
        if not line.startswith("|"):
            continue
        parts = [p.strip() for p in line.split("|")[1:-1]]
        if parts[0] in ("Date", "Cité", "Année", "---") or parts[0].startswith("**"):
            continue
        if in_closure and len(parts) >= 6 and parts[0] in PATHS:
            closures[parts[0]][current_year] = parts[1:6]
            continue
        if len(parts) >= 8 and parts[2] in PATHS and current_year and not in_closure:
            by_city[parts[2]][current_year].append(
                (parts[0], parts[1], parts[3], parts[4], parts[5], parts[6], parts[7])
            )
    return by_city, closures


def format_year_section(city, year, rows, closure):
    lines = [f"## {year}", ""]
    lines.append(f"### Mouvements {year}")
    lines.append("")
    lines.append(TABLE_HEADER)
    for r in rows:
        lines.append(format_row(r))
    lines.append("")

    if closure:
        lines.append(f"### Clôture annuelle {year}")
        lines.append("")
        lines.append(CLOSURE_HEADER)
        lines.append(format_closure(year, closure))
        lines.append("")
    return lines


def dossiers_section(city):
    lines = ["## Dossiers clandestins rattachés", ""]
    lines.append("| Référence | Période | Total dossier | Objet |")
    lines.append("|---|---|---:|---|")
    for ref, period, total, obj in DOSSIERS[city]:
        lines.append(f"| {ref} | {period} | {total} | {obj} |")
    lines.append("")
    return lines


def build_city(city, by_city, closures):
    out = [f"# Registre comptable VIP — {city}", ""]
    out.append(INTROS[city])
    out.append("")
    out.extend(dossiers_section(city))
    out.append(CONVENTION)
    out.append("")

    years = sorted(by_city[city].keys())
    for year in years:
        out.extend(format_year_section(city, year, by_city[city][year], closures[city].get(year)))

    out.append("## Récapitulatif")
    out.append("")
    out.append(CLOSURE_HEADER)
    for year in years:
        c = closures[city][year]
        out.append(format_closure(year, c))
    cum = CUM[city]
    out.append(f"| **Total cycle** | **{cum[0]}** | **{cum[1]}** | **{cum[2]}** |")
    out.append("")
    return "\n".join(out)


def main():
    by_city, closures = parse_master()
    for city, path in PATHS.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(build_city(city, by_city, closures), encoding="utf-8")
        print(f"Écrit : {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
