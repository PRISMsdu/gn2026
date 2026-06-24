#!/usr/bin/env python3
"""Recadre et centre le croquis Brina sur une page A4 paysage (200 dpi)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "images" / "brina_croquis_fusain_stele_wyv.png"
DPI = 200
MM_TO_IN = 1 / 25.4

PAGE_W_MM = 297
PAGE_H_MM = 210
MARGIN_MM = 8
# Reliure gauche + bandes noires du scan source (1536 x 1024)
SOURCE_CROP = (80, 28, 1528, 1010)


def mm_to_px(mm: float) -> int:
    return round(mm * MM_TO_IN * DPI)


def prepare_a4_landscape(source: Path = SRC) -> None:
    page_w = mm_to_px(PAGE_W_MM)
    page_h = mm_to_px(PAGE_H_MM)
    margin = mm_to_px(MARGIN_MM)
    inner_w = page_w - 2 * margin
    inner_h = page_h - 2 * margin

    img = Image.open(source).convert("RGB")
    art = img.crop(SOURCE_CROP)
    aw, ah = art.size

    scale = min(inner_w / aw, inner_h / ah)
    nw = max(1, round(aw * scale))
    nh = max(1, round(ah * scale))
    art_resized = art.resize((nw, nh), Image.Resampling.LANCZOS)

    corners = [
        art.getpixel((10, 10)),
        art.getpixel((aw - 11, 10)),
        art.getpixel((10, ah - 11)),
        art.getpixel((aw - 11, ah - 11)),
    ]
    paper = tuple(int(sum(c[i] for c in corners) / 4) for i in range(3))

    canvas = Image.new("RGB", (page_w, page_h), paper)
    ox = (page_w - nw) // 2
    oy = (page_h - nh) // 2
    canvas.paste(art_resized, (ox, oy))

    canvas.save(source, format="PNG", optimize=True, dpi=(DPI, DPI))
    pdf_path = source.with_suffix(".pdf")
    jpg_path = source.with_suffix(".jpg")
    canvas.save(pdf_path, "PDF", resolution=DPI)
    canvas.save(jpg_path, "JPEG", quality=92, optimize=True, dpi=(DPI, DPI))

    print(f"Motif recadré : {aw} x {ah} -> {nw} x {nh}, centré ({ox}, {oy})")
    print(f"Page A4 paysage : {page_w} x {page_h} px @ {DPI} dpi")
    for p in (source, pdf_path, jpg_path):
        print(f"  {p.name} : {p.stat().st_size // 1024} Ko")


if __name__ == "__main__":
    prepare_a4_landscape()
