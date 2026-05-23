#!/usr/bin/env python3
"""Recadre Blason_Cités_du_levant comme Blason_Palyr : fond blanc, marge haute ~8 %."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BLASONS = ROOT / "LivretsLocaux" / "Blasons"
SRC_FLAT = BLASONS / "Blason_Cités_du_levant.png"
SRC_RELIEF = BLASONS / "Blason_Cités_du_levant_+.png"
_ASSETS = Path(
    r"C:\Users\sebastien-dury\.cursor\projects"
    r"\c-Users-sebastien-dury-OneDrive-Kheops-Technologies-S-A-PERSO-GN-2026\assets"
)
SRC_FLAT_CLEAN = _ASSETS / "Blason_Cites_du_levant_flat_gen.png"
SRC_RELIEF_CLEAN = _ASSETS / "Blason_Cites_du_levant_relief_gen.png"

OUT_SIZE = 1254
# Mesures réelles Blason_Palyr.png (1254×1254)
PALYR_TOP = 105
PALYR_BOTTOM = 0
PALYR_SIDE = 30  # marge max gauche/droite observée


def is_background_pixel(r: int, g: int, b: int) -> bool:
    if r < 55 and g < 55 and b < 65:
        return True
    if r > 228 and g > 228 and b > 228:
        return True
    mx, mn = max(r, g, b), min(r, g, b)
    if mx - mn < 38 and 72 < mx < 215:
        return True
    return False


def flood_background_transparent(im: Image.Image) -> Image.Image:
    rgba = im.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    visited = [[False] * w for _ in range(h)]
    stack: list[tuple[int, int]] = []
    for x in range(w):
        stack.extend([(x, 0), (x, h - 1)])
    for y in range(h):
        stack.extend([(0, y), (w - 1, y)])
    while stack:
        x, y = stack.pop()
        if x < 0 or x >= w or y < 0 or y >= h or visited[y][x]:
            continue
        visited[y][x] = True
        r, g, b, _a = px[x, y]
        if not is_background_pixel(r, g, b):
            continue
        px[x, y] = (r, g, b, 0)
        stack.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    return rgba


def fit_like_palyr(im: Image.Image, size: int = OUT_SIZE) -> Image.Image:
    """Place l'écu : marge haute ~8 %, base au bord, centré en largeur (comme Palyr)."""
    bbox = im.getbbox()
    if not bbox:
        raise RuntimeError("Image entièrement transparente après détourage")
    cropped = im.crop(bbox)
    cw, ch = cropped.size

    inner_w = size - 2 * PALYR_SIDE
    inner_h = size - PALYR_TOP - PALYR_BOTTOM
    scale = min(inner_w / cw, inner_h / ch)
    nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
    scaled = cropped.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - nw) // 2
    oy = PALYR_TOP
    canvas.paste(scaled, (ox, oy), scaled)
    return canvas


def on_white_background(rgba: Image.Image) -> Image.Image:
    """Fond blanc opaque, comme Blason_Palyr.png."""
    white = Image.new("RGBA", rgba.size, (255, 255, 255, 255))
    return Image.alpha_composite(white, rgba).convert("RGB")


def report_margins(im: Image.Image, label: str) -> None:
    px = im.convert("RGB")
    w, h = px.size
    arr = px.load()
    mask = [
        [not (arr[x, y][0] > 250 and arr[x, y][1] > 250 and arr[x, y][2] > 250) for x in range(w)]
        for y in range(h)
    ]
    ys = [y for y in range(h) if any(mask[y])]
    xs = [x for x in range(w) if any(mask[y][x] for y in range(h))]
    if not ys:
        return
    top, bottom, left, right = ys[0], ys[-1], xs[0], xs[-1]
    print(
        f"{label}: marge haut={top}px ({top/h*100:.1f}%), "
        f"bas={h-1-bottom}px, shield {right-left+1}×{bottom-top+1}px"
    )


def process_flat(src: Path, dest: Path) -> None:
    rgba = fit_like_palyr(flood_background_transparent(Image.open(src)))
    out = on_white_background(rgba)
    out.save(dest, "PNG", optimize=True)
    report_margins(out, dest.name)


def mask_from_flat_png(flat_path: Path) -> Image.Image:
    """Masque = silhouette exacte du blason plat (tout pixel non blanc)."""
    rgb = Image.open(flat_path).convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if r < 252 or g < 252 or b < 252:
                mp[x, y] = 255
    return mask


def process_relief(src: Path, dest: Path, flat_ref_path: Path) -> None:
    """Relief : même cadrage que le plat, masque = forme exacte du plat, fond transparent."""
    relief_rgba = fit_like_palyr(flood_background_transparent(Image.open(src)))
    shield_mask = mask_from_flat_png(flat_ref_path)

    r, g, b, _a = relief_rgba.split()
    out = Image.merge("RGBA", (r, g, b, shield_mask))
    out.save(dest, "PNG", optimize=True)

    # Stats (pixels non transparents)
    bbox = out.getbbox()
    if bbox:
        print(
            f"{dest.name}: masque plat appliqué, bbox {bbox[2]-bbox[0]+1}×{bbox[3]-bbox[1]+1}, "
            f"fond transparent"
        )


def main() -> None:
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--relief-only":
        if not SRC_FLAT.is_file():
            raise SystemExit(f"Blason plat requis : {SRC_FLAT}")
        relief_src = SRC_RELIEF_CLEAN if SRC_RELIEF_CLEAN.is_file() else SRC_RELIEF
        process_relief(relief_src, SRC_RELIEF, SRC_FLAT)
        print("Terminé (relief seul).")
        return

    flat_src = SRC_FLAT_CLEAN if SRC_FLAT_CLEAN.is_file() else SRC_FLAT
    relief_src = SRC_RELIEF_CLEAN if SRC_RELIEF_CLEAN.is_file() else SRC_RELIEF

    process_flat(flat_src, SRC_FLAT)
    process_relief(relief_src, SRC_RELIEF, SRC_FLAT)
    print("Terminé.")


if __name__ == "__main__":
    main()
