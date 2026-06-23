#!/usr/bin/env python3
"""Build Carte_Sève_Grise_Marda.svg with embedded PNG art."""
import base64
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PNG = ROOT / "Groupes/Tripot/1 - Back de groupe/Carte_Seve_Grise_art.png"
SVG_OUT = ROOT / "Groupes/Tripot/1 - Back de groupe/Carte_Sève_Grise_Marda.svg"
EDORIAN = ROOT / "Groupes/Banquiers - UBI/1 - Back de groupe/Carte_Persuasion_Edorian.svg"

with open(EDORIAN, "r", encoding="utf-8") as f:
    ed = f.read()
m = re.search(r"<image ([^>]+)>", ed)
if not m:
    raise SystemExit("No image tag in Edorian SVG")
attrs = m.group(1)
for key in ("x", "y", "width", "height", "preserveAspectRatio"):
    km = re.search(rf'{key}="([^"]*)"', attrs)
    print(f"{key}={km.group(1) if km else '?'}")

b64 = base64.b64encode(PNG.read_bytes()).decode("ascii")
print(f"PNG bytes: {PNG.stat().st_size}, b64 len: {len(b64)}")

SVG_TEMPLATE = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="63mm" height="88mm" viewBox="0 0 630 880" role="img" aria-labelledby="title desc">
  <title id="title">Carte S&#232;ve grise</title>
  <desc id="desc">Carte de jeu au format poker, poison de contact par la s&#232;ve grise.</desc>

  <defs>
    <linearGradient id="cardBg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#0a1008"/>
      <stop offset="48%" stop-color="#142018"/>
      <stop offset="100%" stop-color="#060806"/>
    </linearGradient>

    <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#fff0a8"/>
      <stop offset="35%" stop-color="#d7a84b"/>
      <stop offset="70%" stop-color="#7b4f17"/>
      <stop offset="100%" stop-color="#f2cf76"/>
    </linearGradient>

    <radialGradient id="poisonGlow" cx="50%" cy="42%" r="62%">
      <stop offset="0%" stop-color="#8ab892" stop-opacity="0.42"/>
      <stop offset="45%" stop-color="#1a2818" stop-opacity="0.28"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>

    <filter id="softShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="7" stdDeviation="6" flood-color="#000000" flood-opacity="0.55"/>
    </filter>

    <filter id="goldGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="0" stdDeviation="3" flood-color="#f5c96b" flood-opacity="0.55"/>
    </filter>

    <pattern id="velvetPattern" width="48" height="48" patternUnits="userSpaceOnUse" patternTransform="rotate(35)">
      <path d="M0 24 C12 8, 36 8, 48 24 C36 40, 12 40, 0 24Z" fill="none" stroke="#ffffff" stroke-opacity="0.035" stroke-width="3"/>
    </pattern>

    <clipPath id="artClip">
      <rect x="68" y="132" width="494" height="300" rx="20"/>
    </clipPath>

    <linearGradient id="artVignette" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#000000" stop-opacity="0"/>
      <stop offset="70%" stop-color="#0a1008" stop-opacity="0.08"/>
      <stop offset="100%" stop-color="#060806" stop-opacity="0.35"/>
    </linearGradient>
  </defs>

  <rect x="6" y="6" width="618" height="868" rx="38" fill="#030403"/>
  <rect x="18" y="18" width="594" height="844" rx="32" fill="url(#cardBg)" stroke="url(#gold)" stroke-width="8"/>
  <rect x="34" y="34" width="562" height="812" rx="24" fill="none" stroke="#f6d67a" stroke-opacity="0.65" stroke-width="2"/>
  <rect x="44" y="44" width="542" height="792" rx="18" fill="url(#velvetPattern)" opacity="0.9"/>

  <g fill="#f3d277" font-family="Georgia, 'Times New Roman', serif" font-weight="700" filter="url(#goldGlow)" opacity="0.82">
    <text x="52" y="83" font-size="30">M</text>
    <text x="578" y="801" font-size="30" transform="rotate(180 578 801)">M</text>
  </g>

  <g filter="url(#softShadow)">
    <rect x="104" y="54" width="422" height="62" rx="18" fill="#101810" stroke="url(#gold)" stroke-width="4"/>
    <rect x="114" y="64" width="402" height="42" rx="12" fill="#060806" opacity="0.62"/>
    <text x="315" y="93" text-anchor="middle" fill="#ffe9a6" font-family="Georgia, 'Times New Roman', serif" font-size="28" font-weight="700" letter-spacing="0.3">
      S&#232;ve grise
    </text>
  </g>

  <g clip-path="url(#artClip)">
    <image xlink:href="data:image/png;base64,{b64}" x="68" y="132" width="494" height="300" preserveAspectRatio="xMidYMid slice"/>
    <rect x="68" y="132" width="494" height="300" fill="url(#poisonGlow)" opacity="0.12"/>
    <rect x="68" y="132" width="494" height="300" fill="url(#artVignette)"/>

    <g transform="translate(422 318) rotate(-11)" opacity="0.92">
      <rect x="0" y="0" width="44" height="60" rx="5" fill="#f8efcf" stroke="#b58a35" stroke-width="3"/>
      <path d="M22 14 C14 6 6 10 8 22 C10 32 22 38 22 38 C22 38 34 32 36 22 C38 10 30 6 22 14Z" fill="#2a3828"/>
      <circle cx="22" cy="22" r="4" fill="#8ab892" opacity="0.8"/>
    </g>
    <g transform="translate(465 314) rotate(8)" opacity="0.92">
      <rect x="0" y="0" width="44" height="60" rx="5" fill="#f8efcf" stroke="#b58a35" stroke-width="3"/>
      <path d="M22 14 C14 6 6 10 8 22 C10 32 22 38 22 38 C22 38 34 32 36 22 C38 10 30 6 22 14Z" fill="#2a3828"/>
      <circle cx="22" cy="22" r="4" fill="#8ab892" opacity="0.8"/>
    </g>
  </g>
  <rect x="68" y="132" width="494" height="300" rx="20" fill="none" stroke="url(#gold)" stroke-width="5" filter="url(#softShadow)"/>

  <rect x="48" y="448" width="534" height="42" rx="12" fill="#ead18a" stroke="#6d4212" stroke-width="3"/>
  <text x="315" y="475" text-anchor="middle" fill="#291309" font-family="Georgia, 'Times New Roman', serif" font-size="20" font-weight="700">
    Empoisonnement
  </text>

  <rect x="48" y="498" width="534" height="268" rx="18" fill="#f6ecd2" stroke="#9b6b28" stroke-width="4"/>
  <text x="315" text-anchor="middle" fill="#261510" font-family="Georgia, 'Times New Roman', serif" font-size="20" font-weight="700">
    <tspan x="315" y="556">Empoisonnement grave.</tspan>
    <tspan x="315" y="594">&#8722;1 PS toutes les 10 minutes</tspan>
    <tspan x="315" y="632">coma dans 1 heure</tspan>
    <tspan x="315" y="670">Antidote herboriste ou alchimiste</tspan>
    <tspan x="315" y="708">&#224; temps pour stopper l'effet.</tspan>
  </text>

  <rect x="84" y="778" width="462" height="54" rx="10" fill="#101810" stroke="#d8aa51" stroke-width="2"/>
  <text x="315" y="812" text-anchor="middle" fill="#ffe7a3" font-family="Georgia, 'Times New Roman', serif" font-size="16" font-style="italic">
    fallait pas me chercher
  </text>

  <rect x="28" y="28" width="574" height="824" rx="26" fill="none" stroke="#ffffff" stroke-opacity="0.18" stroke-dasharray="9 8" stroke-width="2"/>
</svg>
"""

SVG_OUT.write_text(SVG_TEMPLATE.format(b64=b64), encoding="utf-8")
print(f"Wrote {SVG_OUT} ({SVG_OUT.stat().st_size} bytes)")

import xml.etree.ElementTree as ET
ET.parse(SVG_OUT)
print("XML validation: OK")
