#!/usr/bin/env python3
"""Planche A4 : 3 exemplaires de chaque carte poker (63 x 88 mm)."""
from __future__ import annotations

import cairosvg
from io import BytesIO
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "images"

CARDS = [
    ("Persuasion Edorian", ROOT / "Groupes/Banquiers - UBI/1 - Back de groupe/Carte_Persuasion_Edorian.svg"),
    ("Sève grise", ROOT / "Groupes/Tripot/1 - Back de groupe/Carte_Sève_Grise_Marda.svg"),
    ("Sous le charme Ysabeau", ROOT / "Groupes/Tripot/1 - Back de groupe/Carte_Sous_le_charme_Ysabeau.svg"),
]

# Format poker (mm)
CARD_W_MM = 63
CARD_H_MM = 88
SHEET_W_MM = 210
SHEET_H_MM = 297
DPI = 300

MM_TO_IN = 1 / 25.4


def mm_to_px(mm: float, dpi: int = DPI) -> int:
    return round(mm * MM_TO_IN * dpi)


def render_card(svg_path: Path, dpi: int = DPI) -> Image.Image:
    w = mm_to_px(CARD_W_MM, dpi)
    h = mm_to_px(CARD_H_MM, dpi)
    png = cairosvg.svg2png(url=str(svg_path), output_width=w, output_height=h)
    return Image.open(BytesIO(png)).convert("RGB")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    sheet_w = mm_to_px(SHEET_W_MM)
    sheet_h = mm_to_px(SHEET_H_MM)
    card_w = mm_to_px(CARD_W_MM)
    card_h = mm_to_px(CARD_H_MM)

    cols = int(SHEET_W_MM // CARD_W_MM)
    rows = int(SHEET_H_MM // CARD_H_MM)
    used_w_mm = cols * CARD_W_MM
    used_h_mm = rows * CARD_H_MM
    margin_x_mm = (SHEET_W_MM - used_w_mm) / 2
    margin_y_mm = (SHEET_H_MM - used_h_mm) / 2

    sheet = Image.new("RGB", (sheet_w, sheet_h), "#ffffff")

    rendered = {label: render_card(path) for label, path in CARDS}

    for row, (label, _path) in enumerate(CARDS):
        img = rendered[label]
        for col in range(3):
            x = mm_to_px(margin_x_mm + col * CARD_W_MM)
            y = mm_to_px(margin_y_mm + row * CARD_H_MM)
            sheet.paste(img, (x, y))

    base = OUT_DIR / "Planche_cartes_poker_A4_3x3"
    jpg = base.with_suffix(".jpg")
    pdf = base.with_suffix(".pdf")

    sheet.save(jpg, "JPEG", quality=95, optimize=True, subsampling=0, dpi=(DPI, DPI))
    sheet.save(pdf, "PDF", resolution=DPI)

    print(f"Planche {cols}x{rows} = {cols * rows} cartes ({len(CARDS)} types x 3)")
    print(f"Carte : {CARD_W_MM} x {CARD_H_MM} mm @ {DPI} dpi ({card_w} x {card_h} px)")
    print(f"Marges : {margin_x_mm:.1f} x {margin_y_mm:.1f} mm")
    print(f"JPG : {jpg}")
    print(f"PDF : {pdf}")


if __name__ == "__main__":
    main()
