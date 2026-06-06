from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps


W, H = 2880, 1800
ROOT = Path("/Users/ar/Projects/Taglauncher")
ASSETS = ROOT / "docs" / "assets"
RELEASE = Path("/Users/ar/Projects/Taglauncher-7.8.15-source/Release/AppStore-7.8.15-20260605.2337")
OUT = RELEASE / "Screenshots" / "AppStore-Marketing" / "en"

FONT_REG = "/System/Library/Fonts/SFNS.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_MONO = "/System/Library/Fonts/SFNSMono.ttf"


def f(size, bold=False, black=False, mono=False):
    path = FONT_MONO if mono else FONT_BLACK if black else FONT_BOLD if bold else FONT_REG
    return ImageFont.truetype(path, size)


def rgba(c):
    if len(c) == 4:
        return c
    return (*c, 255)


def lerp(a, b, t):
    return int(a + (b - a) * t)


def gradient(seed=0):
    palettes = [
        ((248, 251, 255), (243, 248, 246), [(90, 150, 255), (92, 210, 150), (255, 118, 168)]),
        ((250, 252, 255), (247, 246, 255), [(107, 142, 255), (255, 137, 182), (112, 215, 160)]),
        ((250, 252, 249), (245, 250, 255), [(96, 215, 151), (104, 164, 255), (255, 174, 92)]),
        ((251, 252, 255), (246, 250, 248), [(94, 175, 255), (255, 128, 160), (124, 214, 132)]),
        ((252, 251, 255), (247, 251, 252), [(115, 142, 255), (104, 219, 177), (255, 199, 92)]),
        ((250, 252, 255), (246, 249, 246), [(80, 210, 150), (120, 155, 255), (255, 130, 150)]),
    ]
    top, bottom, accents = palettes[seed % len(palettes)]
    small = Image.new("RGBA", (360, 225), top + (255,))
    pix = small.load()
    for y in range(small.height):
        t = y / (small.height - 1)
        for x in range(small.width):
            side = x / (small.width - 1)
            c = tuple(lerp(top[i], bottom[i], t * 0.85 + side * 0.15) for i in range(3))
            pix[x, y] = (*c, 255)
    base = small.resize((W, H), Image.Resampling.BICUBIC)
    spots = [
        (-260, -180, 1050, accents[0], 44),
        (W - 720, 100, 1100, accents[1], 36),
        (W // 2 - 360, H - 560, 980, accents[2], 30),
    ]
    for x, y, size, color, alpha in spots:
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        d.ellipse((x, y, x + size, y + size), fill=(*color, alpha))
        layer = layer.filter(ImageFilter.GaussianBlur(size // 4))
        base = Image.alpha_composite(base, layer)
    return base


def shadow(base, xywh, radius=50, blur=54, offset=(0, 34), alpha=48):
    x, y, w, h = xywh
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    m = Image.new("L", base.size, 0)
    d = ImageDraw.Draw(m)
    ox, oy = offset
    d.rounded_rectangle((x + ox, y + oy, x + w + ox, y + h + oy), radius, fill=alpha)
    m = m.filter(ImageFilter.GaussianBlur(blur))
    layer.paste((28, 38, 58, 255), (0, 0), m)
    return Image.alpha_composite(base, layer)


def round_mask(size, radius):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((0, 0, size[0], size[1]), radius, fill=255)
    return m


def crop_alpha(im):
    im = im.convert("RGBA")
    if im.getbands()[-1] == "A":
        box = im.split()[-1].getbbox()
        if box:
            return im.crop(box)
    return im


def fit_image(im, size, mode="contain"):
    im = im.convert("RGBA")
    iw, ih = im.size
    w, h = size
    if mode == "cover":
        scale = max(w / iw, h / ih)
    else:
        scale = min(w / iw, h / ih)
    nw, nh = max(1, int(iw * scale)), max(1, int(ih * scale))
    resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
    if mode == "cover":
        left = max(0, (nw - w) // 2)
        top = max(0, (nh - h) // 2)
        return resized.crop((left, top, left + w, top + h))
    out = Image.new("RGBA", size, (255, 255, 255, 0))
    out.alpha_composite(resized, ((w - nw) // 2, (h - nh) // 2))
    return out


def card(base, image, xywh, radius=46, mode="contain", pad=0, bg=(255, 255, 255, 222), border=(255, 255, 255, 160)):
    x, y, w, h = xywh
    base = shadow(base, xywh, radius=radius)
    panel = Image.new("RGBA", (w, h), bg)
    pd = ImageDraw.Draw(panel)
    pd.rounded_rectangle((0, 0, w - 1, h - 1), radius, fill=bg, outline=border, width=2)
    inner = fit_image(image, (w - pad * 2, h - pad * 2), mode=mode)
    panel.alpha_composite(inner, (pad, pad))
    mask = round_mask((w, h), radius)
    clipped = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    clipped.paste(panel, (0, 0), mask)
    base.alpha_composite(clipped, (x, y))
    return base


def text(draw, xy, body, size, fill=(16, 18, 24), bold=False, black=False, spacing=18, mono=False):
    draw.multiline_text(xy, body, font=f(size, bold=bold, black=black, mono=mono), fill=fill, spacing=spacing)


def small_brand(draw, x, y, dark=False):
    fill = (24, 28, 36) if not dark else (255, 255, 255)
    draw.rounded_rectangle((x, y, x + 270, y + 82), 41, fill=(255, 255, 255, 180), outline=(255, 255, 255, 180), width=2)
    icon = Image.open(ASSETS / "app-icon-256.png").convert("RGBA").resize((52, 52), Image.Resampling.LANCZOS)
    return icon, fill


def paste_brand(base, x=132, y=118):
    icon, fill = small_brand(ImageDraw.Draw(base), x, y)
    base.alpha_composite(icon, (x + 20, y + 15))
    ImageDraw.Draw(base).text((x + 88, y + 23), "TagLauncher", font=f(28, bold=True), fill=fill)


def save(base, name):
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    base.convert("RGB").save(path, quality=96)
    print(path)


def slide_hero():
    base = gradient(1)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    text(d, (132, 430), "Possibly the best\nMac app launcher\nin the world", 128, black=True, spacing=34)
    text(d, (140, 1145), "One shortcut. Every app.\nOrganized by tags.", 54, fill=(38, 43, 53), spacing=28)
    hero = Image.open(ASSETS / "hero-visual.jpg")
    base = card(base, hero, (1370, 168, 1330, 1200), radius=38, mode="contain", pad=0, bg=(255, 255, 255, 145))
    d = ImageDraw.Draw(base)
    d.rounded_rectangle((140, 1430, 680, 1536), 53, fill=(255, 255, 255, 186), outline=(255, 255, 255, 210), width=2)
    text(d, (190, 1460), "macOS 15.0+  |  29 languages", 34, fill=(70, 76, 88), bold=True)
    save(base, "01-hero-launcher-2880x1800.png")


def slide_views():
    base = gradient(0)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    text(d, (1510, 250), "Four views.\nEverything on\none screen.", 112, black=True, spacing=30)
    text(d, (1518, 790), "Flat, plain containers,\ncolored containers, and grid.", 48, fill=(76, 82, 96), spacing=20)
    modes = ["Flat", "Plain containers", "Colored containers", "Plain grid"]
    y = 1080
    for i, m in enumerate(modes):
        d.ellipse((1524, y + i * 95 + 18, 1552, y + i * 95 + 46), fill=(0, 117, 255))
        text(d, (1588, y + i * 95), m, 46, fill=(31, 35, 45), bold=True)
    imgs = [Image.open(ASSETS / "views" / f"view-0{i}.jpg") for i in range(1, 5)]
    positions = [(150, 300), (800, 300), (150, 880), (800, 880)]
    for im, (x, y) in zip(imgs, positions):
        base = card(base, im, (x, y, 590, 384), radius=30, mode="cover", pad=0, bg=(255, 255, 255, 210))
    save(base, "02-four-views-2880x1800.png")


def slide_tags():
    base = gradient(2)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    text(d, (132, 285), "One app.\nMany tags.", 128, black=True, spacing=34)
    text(d, (140, 740), "Stop forcing tools into\nsingle folders. Put an app\nwherever it belongs.", 50, fill=(58, 64, 76), spacing=24)
    for i, label in enumerate(["Reading", "Coding", "AI", "Design"]):
        x = 140 + i * 210
        y = 1180 + (i % 2) * 98
        colors = [(88, 197, 99), (177, 101, 207), (83, 160, 238), (255, 99, 93)]
        d.rounded_rectangle((x, y, x + 178, y + 62), 31, fill=colors[i])
        d.text((x + 28, y + 16), label, font=f(24, bold=True), fill=(255, 255, 255))
    shot = Image.open(ASSETS / "tags-management.jpg")
    base = card(base, shot, (1160, 250, 1500, 975), radius=42, mode="cover", pad=0, bg=(255, 255, 255, 210))
    save(base, "03-multi-tag-system-2880x1800.png")


def slide_search():
    base = gradient(3)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    text(d, (136, 280), "Search apps.\nSearch tags.\nSearch notes.", 104, black=True, spacing=28)
    text(d, (144, 815), "Quick Search finds the right app\neven when you remember only\na tag or note.", 44, fill=(62, 68, 82), spacing=22)
    d.rounded_rectangle((144, 1235, 680, 1345), 55, fill=(255, 255, 255, 190), outline=(255, 255, 255, 220), width=2)
    text(d, (194, 1262), "Fn + Space", 38, fill=(20, 24, 32), bold=True, mono=True)
    qs = crop_alpha(Image.open(ASSETS / "quick-search.png"))
    base = card(base, qs, (1180, 205, 1440, 1160), radius=70, mode="contain", pad=62, bg=(255, 255, 255, 214))
    save(base, "04-quick-search-2880x1800.png")


def slide_notes():
    base = gradient(4)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    text(d, (132, 250), "App notes.\nFind them\nfast.", 104, black=True, spacing=28)
    text(d, (140, 765), "Remember what each tool is for.\nQuick Search can find notes too.", 44, fill=(58, 64, 76), spacing=22)
    memo = Image.open(ASSETS / "app-memo.png")
    base = card(base, memo, (990, 230, 1570, 1170), radius=46, mode="cover", pad=0, bg=(255, 255, 255, 210))
    d = ImageDraw.Draw(base)
    d.rounded_rectangle((150, 1220, 610, 1326), 53, fill=(255, 255, 255, 185), outline=(255, 255, 255, 215), width=2)
    text(d, (195, 1248), "Hover. Read. Launch.", 34, fill=(35, 39, 50), bold=True)
    save(base, "05-app-notes-2880x1800.png")


def slide_privacy():
    base = gradient(5)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    text(d, (132, 285), "100% offline.\n100% ad-free.", 126, black=True, spacing=36)
    text(d, (140, 770), "Your tags, notes, and layout\nstay on your Mac. No analytics,\nno ads, no network dependency.", 48, fill=(58, 64, 76), spacing=24)
    shield = Image.open(ASSETS / "shield-check.png").convert("RGBA")
    backup = Image.open(ASSETS / "backup-restore.jpg")
    settings = Image.open(ASSETS / "screenshot-settings.jpg")
    base = card(base, backup, (1120, 255, 1360, 745), radius=46, mode="cover", pad=0, bg=(255, 255, 255, 210))
    base = card(base, settings, (1540, 860, 900, 565), radius=42, mode="cover", pad=0, bg=(255, 255, 255, 210))
    shield = shield.resize((430, 430), Image.Resampling.LANCZOS)
    base.alpha_composite(shield, (2240, 180))
    d = ImageDraw.Draw(base)
    for i, item in enumerate(["Local data", "JSON backup", "No ads"]):
        y = 1190 + i * 88
        d.rounded_rectangle((150, y, 560, y + 64), 32, fill=(255, 255, 255, 185), outline=(255, 255, 255, 215), width=2)
        text(d, (190, y + 15), item, 26, fill=(42, 48, 60), bold=True)
    save(base, "06-private-offline-2880x1800.png")


def contact_sheet():
    files = sorted(OUT.glob("*.png"))
    thumbs = []
    for p in files:
        im = Image.open(p).resize((720, 450), Image.Resampling.LANCZOS)
        thumbs.append((p, im))
    sheet = Image.new("RGB", (1500, 1450), (246, 248, 252))
    d = ImageDraw.Draw(sheet)
    for idx, (p, im) in enumerate(thumbs):
        x = 40 + (idx % 2) * 740
        y = 40 + (idx // 2) * 470
        sheet.paste(im, (x, y))
        d.text((x, y + 455), p.name, font=f(18, bold=True), fill=(48, 54, 68))
    path = OUT / "_contact-sheet.png"
    sheet.save(path, quality=94)
    print(path)


def main():
    slide_hero()
    slide_views()
    slide_tags()
    slide_search()
    slide_notes()
    slide_privacy()
    contact_sheet()


if __name__ == "__main__":
    main()
