"""
Generateur du support 3D commun aux badges UBI (Conseiller / Chambrier / Garde).

Sortie :
  - badge_UBI_support.stl   : modele 3D binaire, pret a slicer
  - badge_UBI_silhouette.svg : silhouette vue de dessus, gabarit de decoupe DTF

Dimensions par defaut (mm) :
  - Diametre du medaillon : 60
  - Largeur de l'attache  : 6
  - Hauteur (gap) attache : 1
  - Diametre belier ext.  : 9
  - Diametre belier int.  : 4.5 (cordon jusqu'a 3 mm)
  - Epaisseur du support  : 3
  - Hauteur totale        : 70 mm (= 7 cm pile)

Le STL est genere comme une union "naive" de trois primitives qui se
chevauchent (medaillon, attache, beliere). Tout slicer moderne fusionne
correctement ce type d'union au tranchage.
"""

from __future__ import annotations

import math
import struct
from pathlib import Path

# ----- Parametres (mm) ---------------------------------------------------

# WITH_BAIL = True  : medaillon + attache + beliere (ancien design pendentif)
# WITH_BAIL = False : medaillon rond simple (l'accroche se gere autrement :
#                     epingle, broche, aimant, agrafe arriere).
WITH_BAIL = False

DIAM_MED = 60.0
ATTACHE_L = 6.0
ATTACHE_H = 1.0
DIAM_BEL_EXT = 9.0
DIAM_BEL_INT = 4.5
EPAISSEUR = 3.0
N_SEG = 128

R_MED = DIAM_MED / 2.0
R_BEL_EXT = DIAM_BEL_EXT / 2.0
R_BEL_INT = DIAM_BEL_INT / 2.0
Y_BEL_CENTER = R_MED + ATTACHE_H + R_BEL_EXT
if WITH_BAIL:
    HAUTEUR_TOTALE = R_MED + ATTACHE_H + DIAM_BEL_EXT + R_MED  # bas medaillon -> haut beliere
else:
    HAUTEUR_TOTALE = DIAM_MED

# Recouvrement de l'attache avec medaillon / beliere (mm) pour assurer la fusion.
EMBOIT = 1.0

# ----- Generateur STL ----------------------------------------------------

Triangle = tuple[tuple[float, float, float], tuple[float, float, float], tuple[float, float, float]]
triangles: list[Triangle] = []


def add_triangle(v1, v2, v3) -> None:
    triangles.append((v1, v2, v3))


def add_quad(v1, v2, v3, v4) -> None:
    add_triangle(v1, v2, v3)
    add_triangle(v1, v3, v4)


def cylinder_full(cx: float, cy: float, radius: float, z_bot: float, z_top: float, n: int = N_SEG) -> None:
    pts_top = [
        (cx + radius * math.cos(2 * math.pi * i / n), cy + radius * math.sin(2 * math.pi * i / n), z_top)
        for i in range(n)
    ]
    pts_bot = [
        (cx + radius * math.cos(2 * math.pi * i / n), cy + radius * math.sin(2 * math.pi * i / n), z_bot)
        for i in range(n)
    ]
    center_top = (cx, cy, z_top)
    center_bot = (cx, cy, z_bot)
    for i in range(n):
        j = (i + 1) % n
        add_triangle(center_top, pts_top[i], pts_top[j])
        add_triangle(center_bot, pts_bot[j], pts_bot[i])
        add_quad(pts_bot[i], pts_bot[j], pts_top[j], pts_top[i])


def box(x_min: float, y_min: float, z_min: float, x_max: float, y_max: float, z_max: float) -> None:
    p000 = (x_min, y_min, z_min)
    p100 = (x_max, y_min, z_min)
    p110 = (x_max, y_max, z_min)
    p010 = (x_min, y_max, z_min)
    p001 = (x_min, y_min, z_max)
    p101 = (x_max, y_min, z_max)
    p111 = (x_max, y_max, z_max)
    p011 = (x_min, y_max, z_max)
    add_quad(p000, p010, p110, p100)
    add_quad(p001, p101, p111, p011)
    add_quad(p000, p100, p101, p001)
    add_quad(p010, p011, p111, p110)
    add_quad(p000, p001, p011, p010)
    add_quad(p100, p110, p111, p101)


def ring_flat(cx: float, cy: float, r_ext: float, r_int: float, z_bot: float, z_top: float, n: int = N_SEG) -> None:
    pts_ext_top = [
        (cx + r_ext * math.cos(2 * math.pi * i / n), cy + r_ext * math.sin(2 * math.pi * i / n), z_top)
        for i in range(n)
    ]
    pts_ext_bot = [
        (cx + r_ext * math.cos(2 * math.pi * i / n), cy + r_ext * math.sin(2 * math.pi * i / n), z_bot)
        for i in range(n)
    ]
    pts_int_top = [
        (cx + r_int * math.cos(2 * math.pi * i / n), cy + r_int * math.sin(2 * math.pi * i / n), z_top)
        for i in range(n)
    ]
    pts_int_bot = [
        (cx + r_int * math.cos(2 * math.pi * i / n), cy + r_int * math.sin(2 * math.pi * i / n), z_bot)
        for i in range(n)
    ]
    for i in range(n):
        j = (i + 1) % n
        add_quad(pts_int_top[i], pts_ext_top[i], pts_ext_top[j], pts_int_top[j])
        add_quad(pts_int_bot[i], pts_int_bot[j], pts_ext_bot[j], pts_ext_bot[i])
        add_quad(pts_ext_bot[i], pts_ext_bot[j], pts_ext_top[j], pts_ext_top[i])
        add_quad(pts_int_bot[j], pts_int_bot[i], pts_int_top[i], pts_int_top[j])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def normalize(v):
    n = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2)
    if n == 0:
        return (0.0, 0.0, 1.0)
    return (v[0] / n, v[1] / n, v[2] / n)


def normal_of(v1, v2, v3):
    a = (v2[0] - v1[0], v2[1] - v1[1], v2[2] - v1[2])
    b = (v3[0] - v1[0], v3[1] - v1[1], v3[2] - v1[2])
    return normalize(cross(a, b))


def write_stl_binary(path: Path) -> None:
    with path.open("wb") as f:
        header = b"badge_UBI_support v1 (mm) " + b"\0" * 80
        f.write(header[:80])
        f.write(struct.pack("<I", len(triangles)))
        for v1, v2, v3 in triangles:
            n = normal_of(v1, v2, v3)
            f.write(struct.pack("<3f", *n))
            f.write(struct.pack("<3f", *v1))
            f.write(struct.pack("<3f", *v2))
            f.write(struct.pack("<3f", *v3))
            f.write(struct.pack("<H", 0))


# ----- Generation de la geometrie ----------------------------------------

# 1) Medaillon : cylindre centre en (0, 0)
cylinder_full(0.0, 0.0, R_MED, 0.0, EPAISSEUR)

if WITH_BAIL:
    # 2) Attache : boite qui penetre medaillon et beliere
    box(
        -ATTACHE_L / 2.0,
        R_MED - EMBOIT,
        0.0,
        ATTACHE_L / 2.0,
        Y_BEL_CENTER - R_BEL_EXT + EMBOIT,
        EPAISSEUR,
    )

    # 3) Beliere : anneau plat
    ring_flat(0.0, Y_BEL_CENTER, R_BEL_EXT, R_BEL_INT, 0.0, EPAISSEUR)


# ----- Sortie fichiers ---------------------------------------------------

OUT_DIR = Path(__file__).resolve().parent.parent / "Groupes" / "Banquiers - UBI" / "1 - Back de groupe"

stl_path = OUT_DIR / "badge_UBI_support.stl"
write_stl_binary(stl_path)


# ----- SVG silhouette (gabarit DTF) --------------------------------------
#
# Convention :
#   - Coordonnees en millimetres, taille reelle 1:1.
#   - L'axe Y du SVG est inverse par rapport au repere "math" du STL :
#     y_math positif = haut, y_svg positif = bas, donc y_svg = -y_math.
#   - On dessine une SILHOUETTE PLEINE NOIRE (forme du badge), avec
#     un fond blanc explicite et le trou de la beliere transparent
#     (gere par fill-rule="evenodd"). On ajoute un repere de centre,
#     un cadre de marge et les dimensions, pour valider visuellement
#     l'alignement avant decoupe DTF.

svg_path = OUT_DIR / "badge_UBI_silhouette.svg"

margin = 4.0  # marge autour de la silhouette (mm)

# Bornes du badge en coordonnees "math"
if WITH_BAIL:
    y_top_math = Y_BEL_CENTER + R_BEL_EXT   # haut beliere
else:
    y_top_math = R_MED                      # haut medaillon
y_bot_math = -R_MED                          # bas medaillon
view_x = -R_MED - margin
view_w = DIAM_MED + 2 * margin
view_y = -(y_top_math + margin)              # min-y du viewBox (= haut SVG)
view_h = (y_top_math - y_bot_math) + 2 * margin

# Conversion math -> SVG : y_svg = -y_math
m2s = lambda y: -y  # noqa: E731

if WITH_BAIL:
    ax = ATTACHE_L / 2.0
    y_med_attache = math.sqrt(R_MED ** 2 - ax ** 2)
    y_bel_attache = Y_BEL_CENTER - math.sqrt(R_BEL_EXT ** 2 - ax ** 2)
    silhouette_path = (
        f"M {-ax:.4f} {m2s(y_med_attache):.4f} "
        f"A {R_MED} {R_MED} 0 1 1 {ax:.4f} {m2s(y_med_attache):.4f} "
        f"L {ax:.4f} {m2s(y_bel_attache):.4f} "
        f"A {R_BEL_EXT} {R_BEL_EXT} 0 1 1 {-ax:.4f} {m2s(y_bel_attache):.4f} "
        f"L {-ax:.4f} {m2s(y_med_attache):.4f} Z "
        f"M {R_BEL_INT:.4f} {m2s(Y_BEL_CENTER):.4f} "
        f"A {R_BEL_INT} {R_BEL_INT} 0 1 0 {-R_BEL_INT:.4f} {m2s(Y_BEL_CENTER):.4f} "
        f"A {R_BEL_INT} {R_BEL_INT} 0 1 0 {R_BEL_INT:.4f} {m2s(Y_BEL_CENTER):.4f} Z"
    )
    cartouche = (
        f"Gabarit badge UBI - medaillon Ø{DIAM_MED:.0f} mm, beliere "
        f"Ø{DIAM_BEL_EXT:.0f}/{DIAM_BEL_INT:.1f} mm, hauteur {HAUTEUR_TOTALE:.0f} mm (echelle 1:1)"
    )
else:
    # Cercle plein dessine en deux arcs (point de depart sur le bord droit).
    silhouette_path = (
        f"M {R_MED:.4f} 0 "
        f"A {R_MED} {R_MED} 0 1 1 {-R_MED:.4f} 0 "
        f"A {R_MED} {R_MED} 0 1 1 {R_MED:.4f} 0 Z"
    )
    cartouche = (
        f"Gabarit badge UBI - medaillon rond Ø{DIAM_MED:.0f} mm "
        f"(echelle 1:1)"
    )

svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg"
     width="{view_w:.2f}mm" height="{view_h:.2f}mm"
     viewBox="{view_x:.2f} {view_y:.2f} {view_w:.2f} {view_h:.2f}">
  <title>Silhouette badge UBI - gabarit DTF</title>
  <desc>
    Contour commun aux badges Conseiller / Chambrier / Garde.
    Echelle 1:1, dimensions en millimetres.
  </desc>

  <!-- Fond blanc opaque -->
  <rect x="{view_x:.2f}" y="{view_y:.2f}" width="{view_w:.2f}" height="{view_h:.2f}" fill="#fff"/>

  <!-- Silhouette pleine -->
  <path fill="#000" stroke="#000" stroke-width="0.2" fill-rule="evenodd"
        d="{silhouette_path}"/>

  <!-- Croix de centrage au centre du medaillon (blanc sur noir) -->
  <g stroke="#fff" stroke-width="0.25" fill="none">
    <line x1="-4" y1="0" x2="4" y2="0"/>
    <line x1="0" y1="-4" x2="0" y2="4"/>
    <circle cx="0" cy="0" r="1.2" />
  </g>

  <!-- Cartouche de coin : dimensions -->
  <g font-family="sans-serif" font-size="2.2" fill="#000">
    <text x="{view_x + 1:.2f}" y="{view_y + view_h - 1.2:.2f}">{cartouche}</text>
  </g>
</svg>
"""

svg_path.write_text(svg, encoding="utf-8")


# ----- Apercu PNG (controle visuel) --------------------------------------
#
# Genere une image 1:1 a 600 dpi a partir des memes coordonnees, pour
# verification visuelle directe dans l'IDE sans avoir a ouvrir un viewer SVG.

import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Rectangle

png_path = OUT_DIR / "badge_UBI_silhouette_apercu.png"

fig_w_in = view_w / 25.4
fig_h_in = view_h / 25.4
fig, ax_plt = plt.subplots(figsize=(fig_w_in, fig_h_in), dpi=300)
fig.patch.set_facecolor("white")
ax_plt.set_facecolor("white")

# La silhouette comme union de primitives noires
ax_plt.add_patch(Circle((0, 0), R_MED, facecolor="black", edgecolor="black", linewidth=0))
if WITH_BAIL:
    ax_plt.add_patch(
        Rectangle(
            (-ATTACHE_L / 2.0, R_MED - EMBOIT),
            ATTACHE_L,
            ATTACHE_H + 2 * EMBOIT,
            facecolor="black",
            edgecolor="black",
            linewidth=0,
        )
    )
    ax_plt.add_patch(
        Circle((0, Y_BEL_CENTER), R_BEL_EXT, facecolor="black", edgecolor="black", linewidth=0)
    )
    # Trou beliere : disque blanc par dessus
    ax_plt.add_patch(
        Circle((0, Y_BEL_CENTER), R_BEL_INT, facecolor="white", edgecolor="white", linewidth=0)
    )
# Croix de centrage blanche au centre du medaillon
ax_plt.plot([-4, 4], [0, 0], color="white", linewidth=0.6)
ax_plt.plot([0, 0], [-4, 4], color="white", linewidth=0.6)
ax_plt.add_patch(Circle((0, 0), 1.2, facecolor="none", edgecolor="white", linewidth=0.6))

# Cadre et limites (math, y positif vers le haut)
ax_plt.set_xlim(view_x, view_x + view_w)
ax_plt.set_ylim(-view_y - view_h, -view_y)  # inversion : on dessine en repere math
ax_plt.set_aspect("equal")
ax_plt.set_xticks([])
ax_plt.set_yticks([])
for s in ax_plt.spines.values():
    s.set_visible(False)

# Cartouche
if WITH_BAIL:
    cartouche_png = (
        f"Gabarit badge UBI - Ø{DIAM_MED:.0f}/Ø{DIAM_BEL_EXT:.0f}/Ø{DIAM_BEL_INT:.1f} mm, "
        f"h={HAUTEUR_TOTALE:.0f} mm (1:1)"
    )
else:
    cartouche_png = f"Gabarit badge UBI - medaillon Ø{DIAM_MED:.0f} mm (1:1)"
ax_plt.text(
    view_x + 1,
    -view_y - view_h + 1.5,
    cartouche_png,
    fontsize=4.5,
    color="#000",
    ha="left",
    va="bottom",
)

plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
plt.savefig(png_path, dpi=600, bbox_inches="tight", pad_inches=0.05, facecolor="white")
plt.close(fig)

print(f"STL  ecrit : {stl_path}  ({len(triangles)} triangles)")
print(f"SVG  ecrit : {svg_path}")
print(f"PNG  ecrit : {png_path}")
print(f"Hauteur totale : {HAUTEUR_TOTALE:.2f} mm")
print(f"Diametre medaillon : {DIAM_MED:.2f} mm")
print(f"Beliere : ext {DIAM_BEL_EXT:.2f} / int {DIAM_BEL_INT:.2f} mm")
