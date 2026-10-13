"""Builds the Google Play store graphics from the raw app screens.

    flutter test tool/store_assets_test.dart   # → build/store/raw/*.png
    python3 tool/store_assets.py               # → build/store/*.png

Outputs (Play's required sizes):
  icon-512.png                       512×512 app icon
  feature-graphic.png                1024×500 feature graphic
  screenshot-1..6.png                1080×1920 phone screenshots with captions
Needs Pillow.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "build/store/raw"
OUT = ROOT / "build/store"
FONTS = ROOT / "assets/fonts"


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"Nunito-{weight}.ttf"), size)


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def paste_with_shadow(canvas: Image.Image, img: Image.Image, xy, radius: int, shadow=(0, 0, 0, 90)):
    x, y = xy
    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow_layer).rounded_rectangle(
        [x, y + 24, x + img.width, y + img.height + 24], radius, fill=shadow
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(36))
    canvas.alpha_composite(shadow_layer)
    canvas.alpha_composite(rounded(img, radius), (x, y))


def centered_text(draw, y, text, fnt, fill, width):
    w = draw.textlength(text, font=fnt)
    draw.text(((width - w) / 2, y), text, font=fnt, fill=fill)


def wrap(draw, text, fnt, max_w):
    words, lines, line = text.split(), [], ""
    for w in words:
        trial = f"{line} {w}".strip()
        if draw.textlength(trial, font=fnt) <= max_w:
            line = trial
        else:
            lines.append(line)
            line = w
    lines.append(line)
    return lines


SCREENS = [
    ("1-game-paper", "Shed your tail.\nLock your prey.", "Leave walls behind you and trap fleeing prey for a big bonus.", "#14958C", "#FFFFFF"),
    ("2-game-dusk", "Grow long, score big", "A longer snake means a bigger multiplier. Light or dark.", "#12161C", "#FFFFFF"),
    ("3-daily", "One daily board for everyone", "Same puzzle worldwide. Share your result and keep your streak.", "#F26B5B", "#FFFFFF"),
    ("4-shop", "Make it yours", "Themes, skins and trails. Cosmetic only, never pay-to-win.", "#4C7A57", "#FFFFFF"),
    ("5-game-retro", "Retro LCD mode", "The classic pixel look, as a theme.", "#B2C69A", "#1E2A1B"),
    ("6-home", "Easy to learn, hard to master", "Swipe to turn, tap to shed. Crash? Rewind three seconds.", "#F5F3EE", "#1F2A2E"),
]


def screenshot(name, title, sub, bg, fg, index):
    W, H = 1080, 1920
    canvas = Image.new("RGBA", (W, H), bg)
    d = ImageDraw.Draw(canvas)
    title_font, sub_font = font("ExtraBold", 84), font("SemiBold", 40)
    y = 110
    for line in title.split("\n"):
        for part in wrap(d, line, title_font, W - 140):
            centered_text(d, y, part, title_font, fg, W)
            y += 98
    y += 14
    for part in wrap(d, sub, sub_font, W - 180):
        centered_text(d, y, part, sub_font, fg + "D9" if len(fg) == 7 else fg, W)
        y += 54
    shot = Image.open(RAW / f"{name}.png").convert("RGBA")
    top = y + 50
    avail_h = H - top + 140  # let the phone run off the bottom edge
    scale = min((W - 180) / shot.width, avail_h / shot.height)
    shot = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)
    paste_with_shadow(canvas, shot, ((W - shot.width) // 2, top), radius=56)
    canvas.convert("RGB").save(OUT / f"screenshot-{index}.png", optimize=True)


def feature_graphic():
    W, H = 1024, 500
    canvas = Image.new("RGBA", (W, H), "#F5F3EE")
    d = ImageDraw.Draw(canvas)
    logo = Image.open(ROOT / "assets/icon/splash.png").convert("RGBA").resize((170, 170), Image.LANCZOS)
    canvas.alpha_composite(logo, (52, 70))
    d.text((64, 250), "Shedlock", font=font("ExtraBold", 84), fill="#1F2A2E")
    d.text((68, 360), "Shed your tail.", font=font("SemiBold", 32), fill="#66737A")
    d.text((68, 400), "Lock your prey.", font=font("SemiBold", 32), fill="#66737A")
    shot = Image.open(RAW / "1-game-paper.png").convert("RGBA")
    shot = shot.resize((int(shot.width * 0.36), int(shot.height * 0.36)), Image.LANCZOS)
    shot = shot.crop((0, 0, shot.width, 520))
    paste_with_shadow(canvas, shot, (W - shot.width - 60, 44), radius=36, shadow=(31, 42, 46, 70))
    canvas.convert("RGB").save(OUT / "feature-graphic.png", optimize=True)


def icon():
    Image.open(ROOT / "assets/icon/icon.png").convert("RGBA").resize((512, 512), Image.LANCZOS).save(
        OUT / "icon-512.png", optimize=True
    )


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for i, (name, title, sub, bg, fg) in enumerate(SCREENS, start=1):
        screenshot(name, title, sub, bg, fg, i)
    feature_graphic()
    icon()
    print("Wrote", sorted(p.name for p in OUT.glob("*.png")))
