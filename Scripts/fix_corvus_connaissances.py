from pathlib import Path

p = Path(
    r"c:\Users\sebastien-dury\OneDrive - Kheops Technologies S.A\PERSO\GN\2026"
    r"\Groupes\Banquiers - UBI\2 - Roles des Joueurs\UBI_Corvus_Gardien_des_coffres.md"
)
text = p.read_text(encoding="utf-8")
start = text.index("# Connaissances")
end = text.index("\n---\n\n**Version")
new_block = """# Connaissances

## Edorian — UBI (direction)

Edorian et toi connaissez les coffres, les combinaisons et les procédures d'ouverture. Votre coopération et sa sortie dépendent l'une de l'autre quand la Régate referme le mandat.

## Ydria Ventoss — UBI (trésorerie)

Tu sais qu'elle exige des inventaires propres et des dates respectées.

## Selvara Quenndral — UBI (archives)

Tu vois les noms et les heures qu'elle amène ; elle sait que tu bloques toute ouverture hors procédure.

## Horgrim Dval — UBI (garde)

Tu coordonnes les accès physiques quand sa sécurité impose des rondes ou des verrouillages. Tu lui rends compte des cycles vannes et des anomalies sur les couloirs bas.

## Vannes et couloirs bas — UBI

Tu connais la séquence d'alimentation et d'évacuation, l'emplacement de la roue de rechange et la feuille de ronde du poste. Tant que les couloirs sont inondés, personne n'atteint les salles des coffres sans déroger à la procédure.

## Vaelric Dorn — UBI (discrétion)

Ta couverture marchande via la Guilde des Ports Unis peut croiser ses partenariats ; vous évitez les contradictions publiques.

## Melian Torv — UBI (conseiller spirituel)

Vous croisez les flux et les scellés ; une erreur de son côté ou du tien se lit vite sur les écarts.

## Kaelan Thormane — Les Sangs

Tu es son relais à l'Union sous le nom Corvus ; il connaît Torvent Sorel comme ton alias hors banque. Il te soupçonne de lui cacher ce que le noyau du conseil organise ; tu ne lui as pas livré l'ampleur du détournement.
"""
p.write_text(text[:start] + new_block + text[end:], encoding="utf-8")
print("OK")
