"""Renders Shedlock's app icon and splash image from the in-app logo pixel
art (lib/ui/widgets/logo_art.dart), so the icon always matches the logo.

    python3 tool/gen_icon.py
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
"""
import re
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "lib/ui/widgets/logo_art.dart"
OUT = ROOT / "assets/icon"

SCREEN = (0xB2, 0xC6, 0x9A, 255)
GHOST = (0xA6, 0xBA, 0x8E, 255)
INK = (0x1E, 0x2A, 0x1B, 255)
MID = (0x4A, 0x5F, 0x3F, 255)
SHADOW = (0x1E, 0x2A, 0x1B, 0x48)


def logo_rows():
    text = SRC.read_text()
    block = text[text.index("logoPixels = ["):text.index("];")]
    return re.findall(r"'([.LMSE]+)'", block)


def draw_logo(img, rows, box_px, center):
    """Draws the logo so its width is box_px, centred at center."""
    w, h = len(rows[0]), len(rows)
    px = box_px // w
    ox = center[0] - (px * w) // 2
    oy = center[1] - (px * h) // 2
    d = ImageDraw.Draw(img, "RGBA")
    colours = {"L": INK, "S": INK, "M": MID}
    sh = max(1, px // 3)
    for shadow in (True, False):
        for y, row in enumerate(rows):
            for x, c in enumerate(row):
                if c == "." or (shadow and c == "E"):
                    continue
                colour = SHADOW if shadow else (SCREEN if c == "E" else colours[c])
                o = sh if shadow else 0
                d.rectangle(
                    [ox + x * px + o, oy + y * px + o, ox + (x + 1) * px - 1 + o, oy + (y + 1) * px - 1 + o],
                    fill=colour,
                )


def ghost_grid(img, cell):
    d = ImageDraw.Draw(img)
    n = img.width // cell
    for y in range(n):
        for x in range(n):
            g = cell // 8
            d.rectangle([x * cell + g, y * cell + g, (x + 1) * cell - g - 1, (y + 1) * cell - g - 1], fill=GHOST)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = logo_rows()
    size = 1024

    # Full icon (iOS, legacy Android): LCD screen with ghost pixels.
    icon = Image.new("RGBA", (size, size), SCREEN)
    ghost_grid(icon, 64)
    draw_logo(icon, rows, int(size * 0.78), (size // 2, size // 2))
    icon.convert("RGB").save(OUT / "icon.png")

    # Adaptive foreground: logo inside the 66% safe zone, transparent.
    fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_logo(fg, rows, int(size * 0.58), (size // 2, size // 2))
    fg.save(OUT / "icon_foreground.png")

    # Native splash image (centred on the LCD colour).
    splash = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    draw_logo(splash, rows, 660, (384, 384))
    splash.save(OUT / "splash.png")
    print("wrote", ", ".join(p.name for p in sorted(OUT.glob("*.png"))))


if __name__ == "__main__":
    main()
