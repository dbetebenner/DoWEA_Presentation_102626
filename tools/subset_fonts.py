#!/usr/bin/env python3
"""Build the Latin-subset woff2 fonts that the deck embeds.

Quarto's embed-resources drops the theme's remote Google Fonts @import, so
the deck carries its own copies of Josefin Sans, Noto Sans and Noto Sans
Mono (all SIL Open Font License 1.1). Josefin Sans is instanced from the
Google Fonts variable font; the Noto families come from the installed TTFs.

    python3 -m venv /tmp/fontenv && /tmp/fontenv/bin/pip install fonttools brotli
    /tmp/fontenv/bin/python tools/subset_fonts.py [FONT_DIR]
"""
import sys
import urllib.request
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else Path.home() / "Library/Fonts")
OUT = Path(__file__).resolve().parent.parent / "assets/fonts"

UNICODES = (
    "U+0020-007E,U+00A0-00FF,U+0131,U+0152-0153,U+02C6,U+02DA,U+02DC,"
    "U+2000-206F,U+20AC,U+2122,U+2190-2193,U+2212,U+2215,U+2264-2265,U+2500"
)

JOSEFIN_URL = (
    "https://github.com/google/fonts/raw/main/ofl/josefinsans/JosefinSans%5Bwght%5D.ttf"
)
JOSEFIN_VF = Path("/tmp/JosefinSans-VF.ttf")
JOSEFIN_WEIGHTS = (300, 400, 500, 600, 700)

# Body text uses Reveal's embedded Source Sans Pro; Noto Sans is only the
# D3 scene label face (growth-animations.js), at these two weights.
STATIC = {
    "NotoSans-400": "NotoSans-Regular.ttf",
    "NotoSans-600": "NotoSans-SemiBold.ttf",
}


def write_subset(font, name):
    options = subset.Options()
    options.flavor = "woff2"
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=subset.parse_unicodes(UNICODES))
    subsetter.subset(font)
    path = OUT / f"{name}.woff2"
    font.flavor = "woff2"
    font.save(path)
    print(f"{path.name:32s} {path.stat().st_size / 1024:6.1f} KB")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    if not JOSEFIN_VF.exists():
        urllib.request.urlretrieve(JOSEFIN_URL, JOSEFIN_VF)
    for weight in JOSEFIN_WEIGHTS:
        font = instancer.instantiateVariableFont(TTFont(JOSEFIN_VF), {"wght": weight})
        write_subset(font, f"JosefinSans-{weight}")
    for name, file in STATIC.items():
        write_subset(TTFont(SRC / file), name)
    mono = instancer.instantiateVariableFont(
        TTFont(SRC / "NotoSansMono[wdth,wght].ttf"), {"wdth": 100, "wght": 400}
    )
    write_subset(mono, "NotoSansMono-400")


if __name__ == "__main__":
    main()
