#!/usr/bin/env python3
"""Éclaircit et réorganise images/Carte_Persuasion_Edorian.svg."""
from __future__ import annotations

import re
from pathlib import Path

SVG = Path(__file__).resolve().parents[1] / "images/Carte_Persuasion_Edorian.svg"

OLD_ART_H = 300
NEW_ART_H = int(round(OLD_ART_H * 0.7))
DELTA = OLD_ART_H - NEW_ART_H
TYPE_Y = 448 - DELTA
TEXT_Y = 498 - DELTA
TEXT_H = 346

content = SVG.read_text(encoding="utf-8")

content = content.replace(
    """    <linearGradient id="cardBg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#0a1420"/>
      <stop offset="48%" stop-color="#152a42"/>
      <stop offset="100%" stop-color="#060c14"/>
    </linearGradient>""",
    """    <linearGradient id="cardBg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#2a4260"/>
      <stop offset="48%" stop-color="#3d5a78"/>
      <stop offset="100%" stop-color="#1e3248"/>
    </linearGradient>""",
)

content = content.replace(
    """    <radialGradient id="eyeGlow" cx="50%" cy="42%" r="62%">
      <stop offset="0%" stop-color="#c9a227" stop-opacity="0.45"/>
      <stop offset="45%" stop-color="#1a3a5c" stop-opacity="0.28"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>""",
    """    <radialGradient id="eyeGlow" cx="50%" cy="38%" r="58%">
      <stop offset="0%" stop-color="#e8c85a" stop-opacity="0.38"/>
      <stop offset="45%" stop-color="#4a7090" stop-opacity="0.16"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>""",
)

content = content.replace(
    'flood-opacity="0.55"/>',
    'flood-opacity="0.32"/>',
    1,
)

content = content.replace(
    'stroke-opacity="0.035"',
    'stroke-opacity="0.055"',
)

content = content.replace(
    """    <linearGradient id="artVignette" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#000000" stop-opacity="0"/>
      <stop offset="70%" stop-color="#0a1420" stop-opacity="0.08"/>
      <stop offset="100%" stop-color="#060c14" stop-opacity="0.35"/>
    </linearGradient>
  </defs>""",
    """    <linearGradient id="artVignette" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#000000" stop-opacity="0"/>
      <stop offset="72%" stop-color="#3d5a78" stop-opacity="0.04"/>
      <stop offset="100%" stop-color="#2a4260" stop-opacity="0.14"/>
    </linearGradient>

    <filter id="printBrighten" color-interpolation-filters="sRGB">
      <feColorMatrix type="matrix" values="1.18 0 0 0 0.06  0 1.14 0 0 0.05  0 0 1.10 0 0.04  0 0 0 1 0"/>
    </filter>
  </defs>""",
)

content = content.replace('fill="#030508"', 'fill="#141a22"', 1)
content = content.replace('fill="#0f1e30"', 'fill="#3d5a78"', 1)
content = content.replace('fill="#060c14" opacity="0.62"', 'fill="#243848" opacity="0.45"', 1)

for pattern in (
    r'(<clipPath id="artClip">\s*<rect x="68" y="132" width="494" height=")300(" rx="20"/>)',
    r'(<rect x="68" y="132" width="494" height=")300(" fill="url\(#eyeGlow\)")',
    r'(<rect x="68" y="132" width="494" height=")300(" fill="url\(#artVignette\)")',
    r'(<rect x="68" y="132" width="494" height=")300(" rx="20" fill="none" stroke="url\(#gold\)")',
):
    content = re.sub(pattern, rf"\g<1>{NEW_ART_H}\2", content)

content = content.replace('translate(422 318)', f'translate(422 {318 - DELTA})')
content = content.replace('translate(465 314)', f'translate(465 {314 - DELTA})')

for old, new in (
    ('preserveAspectRatio="xMidYMid slice"', 'preserveAspectRatio="xMidYMin slice" filter="url(#printBrighten)"'),
    ('preserveAspectRatio="xMidYMid meet"', 'preserveAspectRatio="xMidYMin meet" filter="url(#printBrighten)"'),
):
    if old in content:
        content = content.replace(old, new, 1)
        break
else:
    content = re.sub(
        r'(<image[^>]+height="300")',
        r'\1 preserveAspectRatio="xMidYMin meet" filter="url(#printBrighten)"',
        content,
        count=1,
    )

content = content.replace(
    """  <rect x="48" y="448" width="534" height="42" rx="12" fill="#ead18a" stroke="#6d4212" stroke-width="3"/>
  <text x="315" y="475" text-anchor="middle" fill="#291309" font-family="Georgia, 'Times New Roman', serif" font-size="20" font-weight="700">
    Faveur sociale - Union bancaire d'Il-Irion
  </text>

  <rect x="48" y="498" width="534" height="268" rx="18" fill="#f6ecd2" stroke="#9b6b28" stroke-width="4"/>
  <text x="315" text-anchor="middle" fill="#261510" font-family="Georgia, 'Times New Roman', serif" font-size="20" font-weight="700">
    <tspan x="315" y="556">Les arguments d'Edorian sont fascinants.</tspan>
    <tspan x="315" y="587">Tu ne peux qu'&#234;tre totalement</tspan>
    <tspan x="315" y="618">en accord avec lui.</tspan>
    <tspan x="315" y="649" font-style="italic" font-weight="400">Tu n'es pas sous contr&#244;le et</tspan>
    <tspan x="315" y="680" font-style="italic" font-weight="400">tu ne peux ex&#233;cuter</tspan>
    <tspan x="315" y="711" font-style="italic" font-weight="400">d'actions contre nature.</tspan>
  </text>

  <rect x="84" y="778" width="462" height="54" rx="10" fill="#0f1e30" stroke="#d8aa51" stroke-width="2"/>
  <text x="315" y="801" text-anchor="middle" fill="#ffe7a3" font-family="Georgia, 'Times New Roman', serif" font-size="14">
    <tspan x="315" y="801">Ne force ni violence, ni vol majeur,</tspan>
    <tspan x="315" y="820">ni trahison vitale. Doute : MJ.</tspan>
  </text>""",
    f"""  <rect x="48" y="{TYPE_Y}" width="534" height="42" rx="12" fill="#ead18a" stroke="#6d4212" stroke-width="3"/>
  <text x="315" y="{TYPE_Y + 27}" text-anchor="middle" fill="#291309" font-family="Georgia, 'Times New Roman', serif" font-size="20" font-weight="700">
    Faveur sociale - Union bancaire d'Il-Irion
  </text>

  <rect x="48" y="{TEXT_Y}" width="534" height="{TEXT_H}" rx="18" fill="#faf3e0" stroke="#9b6b28" stroke-width="4"/>
  <text x="315" text-anchor="middle" fill="#261510" font-family="Georgia, 'Times New Roman', serif" font-size="30">
    <tspan x="315" y="{TEXT_Y + 60}" font-weight="700">Les arguments d'Edorian</tspan>
    <tspan x="315" y="{TEXT_Y + 98}" font-weight="700">sont fascinants.</tspan>
    <tspan x="315" y="{TEXT_Y + 136}">Tu ne peux qu'&#234;tre totalement</tspan>
    <tspan x="315" y="{TEXT_Y + 174}">en accord avec lui.</tspan>
    <tspan x="315" y="{TEXT_Y + 212}" font-style="italic">Tu n'es pas sous contr&#244;le</tspan>
    <tspan x="315" y="{TEXT_Y + 250}" font-style="italic">et tu n'ex&#233;cutes pas</tspan>
    <tspan x="315" y="{TEXT_Y + 288}" font-style="italic">d'action contre nature.</tspan>
  </text>

  <rect x="84" y="778" width="462" height="62" rx="12" fill="#ead18a" stroke="#8a5a20" stroke-width="3"/>
  <text x="315" y="816" text-anchor="middle" fill="#291309" font-family="Georgia, 'Times New Roman', serif" font-size="22" font-weight="700">
    &#171; Vous avez parfaitement raison. &#187;
  </text>""",
)

SVG.write_text(content, encoding="utf-8", newline="\n")
print(f"OK — {SVG.name} mis à jour.")
