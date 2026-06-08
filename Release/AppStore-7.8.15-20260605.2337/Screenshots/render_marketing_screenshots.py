from pathlib import Path
from collections import deque
from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageFilter, ImageOps


W, H = 2880, 1800
ROOT = Path("/Users/ar/Projects/Taglauncher")
ASSETS = ROOT / "docs" / "assets"
RELEASE = Path("/Users/ar/Projects/Taglauncher-7.8.15-source/Release/AppStore-7.8.15-20260605.2337")
OUT = RELEASE / "Screenshots" / "AppStore-Marketing" / "en"
OUT_ZH = RELEASE / "Screenshots" / "AppStore-Marketing" / "zh-Hans"

FONT_REG = "/System/Library/Fonts/SFNS.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_MONO = "/System/Library/Fonts/SFNSMono.ttf"
FONT_CJK = "/System/Library/Fonts/STHeiti Medium.ttc"


def f(size, bold=False, black=False, mono=False, cjk=False):
    path = FONT_CJK if cjk else FONT_MONO if mono else FONT_BLACK if black else FONT_BOLD if bold else FONT_REG
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


def remove_edge_light_background(im, threshold=246):
    im = im.convert("RGBA")
    rgb = im.convert("RGB")
    w, h = rgb.size
    pix = rgb.load()
    seen = bytearray(w * h)
    q = deque()

    def eligible(x, y):
        r, g, b = pix[x, y]
        return min(r, g, b) >= threshold and (max(r, g, b) - min(r, g, b)) <= 24

    def add(x, y):
        idx = y * w + x
        if not seen[idx] and eligible(x, y):
            seen[idx] = 1
            q.append((x, y))

    for x in range(w):
        add(x, 0)
        add(x, h - 1)
    for y in range(h):
        add(0, y)
        add(w - 1, y)

    while q:
        x, y = q.popleft()
        if x > 0:
            add(x - 1, y)
        if x + 1 < w:
            add(x + 1, y)
        if y > 0:
            add(x, y - 1)
        if y + 1 < h:
            add(x, y + 1)

    alpha = Image.new("L", (w, h), 255)
    ap = alpha.load()
    for y in range(h):
        row = y * w
        for x in range(w):
            if seen[row + x]:
                ap[x, y] = 0
    alpha = alpha.filter(ImageFilter.GaussianBlur(2))
    im.putalpha(alpha)
    box = im.getbbox()
    return im.crop(box) if box else im


def paste_floating_visual(base, image, xywh, edge_blur=46, shadow_alpha=52):
    x, y, w, h = xywh
    visual = remove_edge_light_background(image)
    fitted = fit_image(visual, (w, h), mode="contain")
    alpha = fitted.split()[-1]
    shadow_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (28, 38, 58, shadow_alpha))
    shadow_mask = alpha.filter(ImageFilter.GaussianBlur(edge_blur))
    shadow_layer.alpha_composite(shadow, (x + 18, y + 42))
    shadow_layer.putalpha(Image.new("L", base.size, 0))
    shadow_layer.paste((28, 38, 58, shadow_alpha), (x + 18, y + 42), shadow_mask)
    base = Image.alpha_composite(base, shadow_layer)
    base.alpha_composite(fitted, (x, y))
    return base


def crop_light_margin(im, threshold=250, margin=18):
    im = im.convert("RGBA")
    rgb = im.convert("RGB")
    w, h = rgb.size
    pix = rgb.load()
    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    for y in range(h):
        for x in range(w):
            r, g, b = pix[x, y]
            if min(r, g, b) < threshold:
                mp[x, y] = 255
    box = mask.getbbox()
    if not box:
        return im
    l, t, r, b = box
    l = max(0, l - margin)
    t = max(0, t - margin)
    r = min(w, r + margin)
    b = min(h, b + margin)
    return im.crop((l, t, r, b))


def paste_soft_rect_visual(base, image, xywh, edge=90, shadow_alpha=30):
    x, y, w, h = xywh
    visual = crop_light_margin(image)
    fitted = fit_image(visual, (w, h), mode="contain")
    alpha = fitted.split()[-1]
    edge_mask = Image.new("L", (w, h), 0)
    ep = edge_mask.load()
    for yy in range(h):
        dy = min(yy, h - 1 - yy)
        for xx in range(w):
            dx = min(xx, w - 1 - xx)
            a = min(255, int(255 * min(dx, dy, edge) / edge))
            ep[xx, yy] = a
    alpha = ImageChops.multiply(alpha, edge_mask)
    fitted.putalpha(alpha)
    shadow_mask = alpha.filter(ImageFilter.GaussianBlur(52))
    shadow_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow_layer.paste((28, 38, 58, shadow_alpha), (x + 10, y + 38), shadow_mask)
    base = Image.alpha_composite(base, shadow_layer)
    base.alpha_composite(fitted, (x, y))
    return base


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


def text(draw, xy, body, size, fill=(16, 18, 24), bold=False, black=False, spacing=18, mono=False, cjk=False):
    draw.multiline_text(xy, body, font=f(size, bold=bold, black=black, mono=mono, cjk=cjk), fill=fill, spacing=spacing)


def zh(draw, xy, body, size, fill=(16, 18, 24), spacing=18):
    text(draw, xy, body, size, fill=fill, spacing=spacing, cjk=True)


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


def save_zh(base, name):
    OUT_ZH.mkdir(parents=True, exist_ok=True)
    path = OUT_ZH / name
    base.convert("RGB").save(path, quality=96)
    print(path)


def slide_hero():
    base = gradient(1)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    text(d, (132, 430), "Possibly the best\nMac app launcher\nin the world", 128, black=True, spacing=34)
    text(d, (140, 1145), "One shortcut. Every app.\nOrganized by tags.", 54, fill=(38, 43, 53), spacing=28)
    hero = Image.open(ASSETS / "hero-visual.jpg")
    base = paste_soft_rect_visual(base, hero, (1360, 130, 1330, 1210), edge=96, shadow_alpha=26)
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


def slide_hero_zh():
    base = gradient(1)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    zh(d, (132, 415), "可能是世界上\n最好用的 Mac\n应用启动器", 116, spacing=36)
    zh(d, (140, 1125), "一个快捷键，所有应用。\n用标签整理得清清楚楚。", 52, fill=(38, 43, 53), spacing=28)
    hero = Image.open(ASSETS / "hero-visual.jpg")
    base = paste_soft_rect_visual(base, hero, (1360, 130, 1330, 1210), edge=96, shadow_alpha=26)
    d = ImageDraw.Draw(base)
    d.rounded_rectangle((140, 1430, 735, 1536), 53, fill=(255, 255, 255, 186), outline=(255, 255, 255, 210), width=2)
    zh(d, (190, 1458), "macOS 15.0+  |  29 种界面语言", 32, fill=(70, 76, 88))
    save_zh(base, "01-hero-launcher-2880x1800.png")


def slide_views_zh():
    base = gradient(0)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    zh(d, (1510, 250), "4 种视图\n全部一屏\n到底", 108, spacing=30)
    zh(d, (1518, 790), "平铺、无色容器、彩色容器，\n还有无色网格。", 46, fill=(76, 82, 96), spacing=20)
    modes = ["平铺", "无色容器", "彩色容器", "无色网格"]
    y = 1080
    for i, m in enumerate(modes):
        d.ellipse((1524, y + i * 95 + 18, 1552, y + i * 95 + 46), fill=(0, 117, 255))
        zh(d, (1588, y + i * 95), m, 44, fill=(31, 35, 45))
    imgs = [Image.open(ASSETS / "views" / f"view-0{i}.jpg") for i in range(1, 5)]
    positions = [(150, 300), (800, 300), (150, 880), (800, 880)]
    for im, (x, y) in zip(imgs, positions):
        base = card(base, im, (x, y, 590, 384), radius=30, mode="cover", pad=0, bg=(255, 255, 255, 210))
    save_zh(base, "02-four-views-2880x1800.png")


def slide_tags_zh():
    base = gradient(2)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    zh(d, (132, 285), "一个应用\n多个标签", 122, spacing=36)
    zh(d, (140, 740), "别再把工具塞进唯一文件夹。\n它属于哪里，就放在哪里。", 50, fill=(58, 64, 76), spacing=24)
    for i, label in enumerate(["阅读", "编程", "AI", "设计"]):
        x = 140 + i * 210
        y = 1180 + (i % 2) * 98
        colors = [(88, 197, 99), (177, 101, 207), (83, 160, 238), (255, 99, 93)]
        d.rounded_rectangle((x, y, x + 178, y + 62), 31, fill=colors[i])
        zh(d, (x + 42, y + 13), label, 26, fill=(255, 255, 255))
    shot = Image.open(ASSETS / "tags-management.jpg")
    base = card(base, shot, (1160, 250, 1500, 975), radius=42, mode="cover", pad=0, bg=(255, 255, 255, 210))
    save_zh(base, "03-multi-tag-system-2880x1800.png")


def slide_search_zh():
    base = gradient(3)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    zh(d, (136, 280), "搜索应用\n搜索标签\n搜索备注", 104, spacing=30)
    zh(d, (144, 815), "Quick Search 能从应用名、标签\n和备注中找到目标。", 44, fill=(62, 68, 82), spacing=22)
    d.rounded_rectangle((144, 1235, 680, 1345), 55, fill=(255, 255, 255, 190), outline=(255, 255, 255, 220), width=2)
    zh(d, (194, 1262), "Fn + 空格", 36, fill=(20, 24, 32))
    qs = crop_alpha(Image.open(ASSETS / "quick-search.png"))
    base = card(base, qs, (1180, 205, 1440, 1160), radius=70, mode="contain", pad=62, bg=(255, 255, 255, 214))
    save_zh(base, "04-quick-search-2880x1800.png")


def slide_notes_zh():
    base = gradient(4)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    zh(d, (132, 250), "应用备注\n也能搜索\n更快找到", 100, spacing=30)
    zh(d, (140, 765), "记住每个工具的用途。\nQuick Search 也能搜备注。", 44, fill=(58, 64, 76), spacing=22)
    memo = Image.open(ASSETS / "app-memo.png")
    base = card(base, memo, (990, 230, 1570, 1170), radius=46, mode="cover", pad=0, bg=(255, 255, 255, 210))
    d = ImageDraw.Draw(base)
    d.rounded_rectangle((150, 1220, 685, 1326), 53, fill=(255, 255, 255, 185), outline=(255, 255, 255, 215), width=2)
    zh(d, (195, 1248), "悬停查看，马上启动", 32, fill=(35, 39, 50))
    save_zh(base, "05-app-notes-2880x1800.png")


def slide_privacy_zh():
    base = gradient(5)
    paste_brand(base)
    d = ImageDraw.Draw(base)
    zh(d, (132, 285), "100% 离线\n100% 无广告", 118, spacing=38)
    zh(d, (140, 770), "标签、备注与布局都留在本机。\n无分析，无广告，不依赖网络。", 46, fill=(58, 64, 76), spacing=24)
    shield = Image.open(ASSETS / "shield-check.png").convert("RGBA")
    backup = Image.open(ASSETS / "backup-restore.jpg")
    settings = Image.open(ASSETS / "screenshot-settings.jpg")
    base = card(base, backup, (1120, 255, 1360, 745), radius=46, mode="cover", pad=0, bg=(255, 255, 255, 210))
    base = card(base, settings, (1540, 860, 900, 565), radius=42, mode="cover", pad=0, bg=(255, 255, 255, 210))
    shield = shield.resize((430, 430), Image.Resampling.LANCZOS)
    base.alpha_composite(shield, (2240, 180))
    d = ImageDraw.Draw(base)
    for i, item in enumerate(["本地数据", "JSON 备份", "无广告"]):
        y = 1190 + i * 88
        d.rounded_rectangle((150, y, 560, y + 64), 32, fill=(255, 255, 255, 185), outline=(255, 255, 255, 215), width=2)
        zh(d, (190, y + 12), item, 26, fill=(42, 48, 60))
    save_zh(base, "06-private-offline-2880x1800.png")


def contact_sheet(out=OUT):
    files = sorted(out.glob("*.png"))
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
    path = out / "_contact-sheet.png"
    sheet.save(path, quality=94)
    print(path)


def render_en():
    slide_hero()
    slide_views()
    slide_tags()
    slide_search()
    slide_notes()
    slide_privacy()
    contact_sheet(OUT)


def render_zh():
    slide_hero_zh()
    slide_views_zh()
    slide_tags_zh()
    slide_search_zh()
    slide_notes_zh()
    slide_privacy_zh()
    contact_sheet(OUT_ZH)


def main():
    render_en()
    render_zh()


if __name__ == "__main__":
    main()
