#!/usr/bin/env python3
"""Prototype de composition depuis Cités_du_levant.jpg (PIL).

Les fichiers livrés dans LivretsLocaux/Blasons/ sont produits par rendu IA
+ redimensionnement 1254 px, calqués sur Blason_Palyr.png / Blason_Palyr_+.png.
"""
from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "LivretsLocaux" / "Blasons" / "Cités_du_levant.jpg"
OUT_FLAT = ROOT / "LivretsLocaux" / "Blasons" / "Blason_Cités_du_levant.png"
OUT_RELIEF = ROOT / "LivretsLocaux" / "Blasons" / "Blason_Cités_du_levant_+.png"

SIZE = 1254
# Champ : bleu marine proche Il-Irion / insigne confédération
FIELD = (26, 42, 74)
FIELD_LIGHT = (38, 58, 98)
BORDER_GOLD = (198, 156, 58)
BORDER_BLACK = (18, 14, 10)


def heater_shield_mask(size: int) -> Image.Image:
    w = h = size
    cx = w / 2
    top_y = h * 0.06
    shoulder_y = h * 0.14
    curve_y = h * 0.42
    point_y = h * 0.94
    inset = w * 0.08

    poly = [
        (cx, top_y),
        (w - inset, shoulder_y),
        (w - inset * 0.55, curve_y),
        (cx, point_y),
        (inset * 0.55, curve_y),
        (inset, shoulder_y),
    ]
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    return mask.filter(ImageFilter.GaussianBlur(0.6))


def inner_field_mask(shield: Image.Image, margin: float = 0.045) -> Image.Image:
    w, h = shield.size
    cx = w / 2
    m = margin
    poly = [
        (cx, h * (0.06 + m)),
        (w * (1 - 0.08 - m * 0.5), h * (0.14 + m * 0.3)),
        (w * (1 - 0.08 * 0.55 - m), h * (0.42 + m * 0.2)),
        (cx, h * (0.94 - m)),
        (w * (0.08 * 0.55 + m), h * (0.42 + m * 0.2)),
        (w * (0.08 + m * 0.5), h * (0.14 + m * 0.3)),
    ]
    inner = Image.new("L", (w, h), 0)
    ImageDraw.Draw(inner).polygon(poly, fill=255)
    return inner


def load_logo_rgba() -> Image.Image:
    im = Image.open(SRC).convert("RGBA")
    # Fond gris-bleu du logo -> transparent
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r > 210 and g > 220 and b > 230:
                px[x, y] = (r, g, b, 0)
    return im


def compose_charge(logo: Image.Image, field_box: tuple[int, int, int, int]) -> Image.Image:
    """Recadre le logo (château, soleil, mer) dans la zone utile de l'écu."""
    x0, y0, x1, y1 = field_box
    fw, fh = x1 - x0, y1 - y0
    # Rogner le logo : retirer marges transparentes
    bbox = logo.getbbox()
    if not bbox:
        raise RuntimeError("Logo vide après détourage")
    cropped = logo.crop(bbox)
    # Légèrement plus haut que large dans l'écu
    target_w = int(fw * 0.88)
    target_h = int(fh * 0.82)
    scale = min(target_w / cropped.width, target_h / cropped.height)
    nw, nh = max(1, int(cropped.width * scale)), max(1, int(cropped.height * scale))
    scaled = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    ox = (fw - nw) // 2
    oy = int(fh * 0.06)
    layer.paste(scaled, (ox, oy), scaled)
    return layer


def draw_field(size: int, inner: Image.Image, relief: bool) -> Image.Image:
    base = Image.new("RGB", (size, size), (12, 12, 14))
    field = Image.new("RGB", (size, size), FIELD)
    if relief:
        # Texture subtile + dégradé vertical
        noise = Image.effect_noise((size, size), 12).convert("L")
        noise = noise.filter(ImageFilter.GaussianBlur(1.2))
        grad = Image.new("L", (size, size))
        gp = grad.load()
        for y in range(size):
            v = int(110 + 35 * (y / size))
            for x in range(size):
                gp[x, y] = v
        comb = ImageChops.multiply(noise, grad)
        tint = Image.new("RGB", (size, size), FIELD_LIGHT)
        field = Image.composite(tint, field, comb)
        field = field.filter(ImageFilter.UnsharpMask(radius=1.2, percent=80, threshold=2))
    inner_rgb = inner.convert("RGB")
    return Image.composite(field, base, inner)


def add_borders(img: Image.Image, shield: Image.Image, relief: bool) -> Image.Image:
    w, h = img.size
    out = img.copy()
    draw = ImageDraw.Draw(out)
    cx = w / 2
    poly_outer = [
        (cx, h * 0.06),
        (w * 0.92, h * 0.14),
        (w * 0.915, h * 0.42),
        (cx, h * 0.94),
        (w * 0.085, h * 0.42),
        (w * 0.08, h * 0.14),
    ]
    poly_gold = [
        (cx, h * 0.065),
        (w * 0.905, h * 0.145),
        (w * 0.90, h * 0.42),
        (cx, h * 0.935),
        (w * 0.10, h * 0.42),
        (w * 0.095, h * 0.145),
    ]
    bw = 5 if relief else 4
    gw = 3 if relief else 2
    draw.polygon(poly_outer, outline=BORDER_BLACK, width=bw + (2 if relief else 0))
    draw.polygon(poly_gold, outline=BORDER_GOLD, width=gw)
    if relief:
        # Reflet sur le bord supérieur
        highlight = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        hd = ImageDraw.Draw(highlight)
        hd.polygon(poly_gold, outline=(230, 200, 120, 90), width=1)
        out = Image.alpha_composite(out.convert("RGBA"), highlight).convert("RGB")
    # Masquer hors écu
    outside = Image.new("RGB", (w, h), (12, 12, 14))
    return Image.composite(out, outside, shield)


def apply_relief_charge(base: Image.Image, charge: Image.Image, inner: Image.Image) -> Image.Image:
    w, h = base.size
    # Ombre portée
    alpha = charge.split()[3]
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 160), (8, 10), alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(6))
    result = base.convert("RGBA")
    result = Image.alpha_composite(result, shadow)
    # Charge avec léger emboss
    rgb = Image.new("RGB", charge.size, (255, 255, 255))
    embossed = ImageOps.grayscale(rgb)
    embossed = embossed.filter(ImageFilter.EMBOSS)
    embossed = ImageOps.colorize(embossed, (40, 40, 50), (255, 255, 255))
    embossed.putalpha(alpha)
    # Mélange : charge originale + highlight sur les bords clairs du logo
    charge_hi = charge.copy()
    hi_layer = embossed.copy()
    hi_layer.putalpha(alpha.point(lambda a: min(255, int(a * 0.35)) if a else 0))
    result = Image.alpha_composite(result, charge_hi)
    result = Image.alpha_composite(result, hi_layer)
    # Soleil : renforcer l'orange (détection couleur chaude)
    px = charge.load()
    warm = Image.new("L", charge.size, 0)
    wp = warm.load()
    for y in range(charge.height):
        for x in range(charge.width):
            r, g, b, a = px[x, y]
            if a > 20 and r > 180 and g > 100 and b < 180:
                wp[x, y] = min(255, int(a * 0.5))
    glow = Image.new("RGBA", charge.size, (255, 180, 60, 0))
    glow.putalpha(warm.filter(ImageFilter.GaussianBlur(8)))
    result = Image.alpha_composite(result, glow)
    return Image.composite(result.convert("RGB"), base, inner)


def build(relief: bool) -> Image.Image:
    shield = heater_shield_mask(SIZE)
    inner = inner_field_mask(shield)
    # Boîte intérieure pour la charge
    bbox = inner.getbbox()
    if not bbox:
        raise RuntimeError("Masque intérieur vide")
    logo = load_logo_rgba()
    charge = compose_charge(logo, bbox)
    field_img = draw_field(SIZE, inner, relief=relief)
    # Coller la charge
    cx, cy = bbox[0], bbox[1]
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    layer.paste(charge, (cx, cy), charge)
    if relief:
        composed = apply_relief_charge(field_img, layer, inner)
    else:
        composed = Image.alpha_composite(field_img.convert("RGBA"), layer).convert("RGB")
        composed = Image.composite(composed, field_img, inner)
    return add_borders(composed, shield, relief=relief)


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"Source introuvable : {SRC}")
    flat = build(relief=False)
    relief = build(relief=True)
    flat.save(OUT_FLAT, "PNG", optimize=True)
    relief.save(OUT_RELIEF, "PNG", optimize=True)
    print(f"Écrit : {OUT_FLAT} ({flat.size})")
    print(f"Écrit : {OUT_RELIEF} ({relief.size})")


if __name__ == "__main__":
    main()
