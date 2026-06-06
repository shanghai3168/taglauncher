#!/usr/bin/env python3
"""Compose a 3D stacked-window hero from the real TagLauncher screenshot."""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
_jpg = ASSETS / "hero-source-grid.jpg"
_png = ASSETS / "hero-source-grid.png"
SRC = _jpg if _jpg.exists() else _png
OUT = ASSETS / "hero-visual-stack.jpg"

CANVAS_W, CANVAS_H = 1180, 640
BG = (255, 255, 255, 255)


def find_coeffs(src: list[tuple[float, float]], dst: list[tuple[float, float]]) -> list[float]:
    matrix = []
    for (x, y), (u, v) in zip(src, dst):
        matrix.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        matrix.append([0, 0, 0, x, y, 1, -v * x, -v * y])
    a = np.matrix(matrix, dtype=float)
    b = np.array(dst).reshape(8)
    res = np.dot(np.linalg.inv(a.T * a) * a.T, b)
    return np.array(res).reshape(8).tolist()


def warp_quad(img: Image.Image, quad: list[tuple[float, float]], out_size: tuple[int, int]) -> Image.Image:
    w, h = img.size
    src = [(0, 0), (w, 0), (w, h), (0, h)]
    coeffs = find_coeffs(src, quad)
    return img.transform(out_size, Image.PERSPECTIVE, coeffs, Image.BICUBIC)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def crop_app_content(src: Image.Image) -> Image.Image:
    w, h = src.size
    if w > 2000:
        top = int(h * 0.055)
        left = int(w * 0.018)
        right = int(w * 0.982)
        bottom = int(h * 0.93)
    else:
        top = int(h * 0.04)
        left = int(w * 0.02)
        right = int(w * 0.98)
        bottom = int(h * 0.96)
    return src.crop((left, top, right, bottom))


def make_window(content: Image.Image, title_h: int = 34, radius: int = 14) -> Image.Image:
    content = content.convert("RGBA")
    cw, ch = content.size
    frame = Image.new("RGBA", (cw, ch + title_h), (0, 0, 0, 0))
    body = Image.new("RGBA", (cw, ch + title_h), (245, 245, 247, 255))
    mask = rounded_mask((cw, ch + title_h), radius)
    body.putalpha(mask)
    frame.alpha_composite(body)

    draw = ImageDraw.Draw(frame)
    bar_h = title_h
    draw.rounded_rectangle((0, 0, cw - 1, bar_h + 6), radius=radius, fill=(236, 236, 238, 255))
    lights = [(18, bar_h // 2), (38, bar_h // 2), (58, bar_h // 2)]
    colors = [(255, 95, 86, 255), (255, 189, 46, 255), (39, 201, 63, 255)]
    for (x, y), color in zip(lights, colors):
        r = 7
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)

    shadow = Image.new("RGBA", (cw, ch + title_h), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((8, 10, cw - 2, ch + title_h - 2), radius=radius, fill=(0, 0, 0, 42))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    out = Image.new("RGBA", (cw + 16, ch + title_h + 16), (0, 0, 0, 0))
    out.alpha_composite(shadow, (0, 0))
    out.alpha_composite(frame, (8, 4))
    out.alpha_composite(content, (8, 4 + title_h))
    return out


def tint_layer(img: Image.Image, brightness: float, alpha: float) -> Image.Image:
    layer = ImageEnhance.Brightness(img).enhance(brightness)
    layer = ImageEnhance.Color(layer).enhance(0.75)
    r, g, b, a = layer.split()
    a = a.point(lambda v: int(v * alpha))
    layer.putalpha(a)
    return layer


def draw_tag_sidebar(size: tuple[int, int]) -> Image.Image:
    w, h = size
    side = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(side)
    draw.rounded_rectangle((0, 0, w - 1, h - 1), radius=12, fill=(34, 34, 38, 235))
    colors = [
        (76, 175, 80),
        (156, 39, 176),
        (33, 150, 243),
        (244, 67, 54),
        (255, 152, 0),
        (0, 188, 212),
        (233, 30, 99),
    ]
    gap = 8
    bar_w = w - 18
    bar_h = max(18, (h - gap * (len(colors) + 1)) // len(colors))
    y = 10
    for color in colors:
        draw.rounded_rectangle((9, y, 9 + bar_w, y + bar_h), radius=6, fill=(*color, 255))
        y += bar_h + gap
    return side


def place_layer(
    canvas: Image.Image,
    layer: Image.Image,
    quad: list[tuple[float, float]],
    shadow_blur: int = 18,
    shadow_alpha: int = 55,
) -> None:
    xs = [p[0] for p in quad]
    ys = [p[1] for p in quad]
    pad = 30
    min_x, max_x = int(min(xs)) - pad, int(max(xs)) + pad
    min_y, max_y = int(min(ys)) - pad, int(max(ys)) + pad
    box_w = max(1, max_x - min_x)
    box_h = max(1, max_y - min_y)
    local_quad = [(x - min_x, y - min_y) for x, y in quad]
    warped = warp_quad(layer, local_quad, (box_w, box_h))

    shadow = Image.new("RGBA", (box_w, box_h), (0, 0, 0, 0))
    alpha = warped.split()[3]
    shadow.putalpha(alpha.point(lambda v: min(v, shadow_alpha)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(shadow_blur))
    canvas.alpha_composite(shadow, (min_x + 10, min_y + 16))
    canvas.alpha_composite(warped, (min_x, min_y))


def add_reflection(canvas: Image.Image, subject_box: tuple[int, int, int, int], strength: float = 0.22) -> None:
    x0, y0, x1, y1 = subject_box
    subject = canvas.crop((x0, y0, x1, y1)).convert("RGBA")
    refl_h = int((y1 - y0) * 0.14)
    if refl_h < 8:
        return
    strip = subject.crop((0, subject.height - refl_h, subject.width, subject.height))
    reflected = ImageOps.flip(strip)
    grad = Image.linear_gradient("L").resize((reflected.width, reflected.height))
    reflected.putalpha(grad.point(lambda v: int(v * strength)))
    canvas.alpha_composite(reflected, (x0, y1 + 2))


def build() -> Image.Image:
    src = Image.open(SRC).convert("RGBA")
    content = crop_app_content(src)
    target_w = 820 if content.width < 2000 else 760
    scale = target_w / content.width
    target_h = int(content.height * scale)
    content = content.resize((target_w, target_h), Image.LANCZOS)

    front = make_window(content, title_h=30, radius=12)
    back_content = content.resize((int(target_w * 0.92), int(target_h * 0.92)), Image.LANCZOS)
    back = tint_layer(make_window(back_content, title_h=26, radius=10), brightness=0.42, alpha=0.92)
    deep = tint_layer(make_window(back_content.resize((int(target_w * 0.84), int(target_h * 0.84)), Image.LANCZOS), title_h=22, radius=10), brightness=0.28, alpha=0.88)
    sidebar = draw_tag_sidebar((74, int(target_h * 0.78)))

    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), BG)
    fw, fh = front.size

    ox, oy = 210, 36
    front_quad = [
        (ox, oy + fh * 0.1),
        (ox + fw * 0.97, oy + fh * 0.02),
        (ox + fw * 0.99, oy + fh * 0.96),
        (ox + fw * 0.05, oy + fh),
    ]
    back_quad = [
        (ox + 88, oy - 24),
        (ox + fw + 62, oy - 56),
        (ox + fw + 78, oy + fh - 42),
        (ox + 104, oy + fh - 12),
    ]
    deep_quad = [
        (ox + 138, oy - 64),
        (ox + fw + 104, oy - 98),
        (ox + fw + 120, oy + fh - 78),
        (ox + 154, oy + fh - 40),
    ]
    side_quad = [
        (ox + fw + 22, oy + 24),
        (ox + fw + 98, oy + 8),
        (ox + fw + 104, oy + fh - 52),
        (ox + fw + 30, oy + fh - 18),
    ]

    place_layer(canvas, deep, deep_quad, shadow_blur=24, shadow_alpha=40)
    place_layer(canvas, back, back_quad, shadow_blur=20, shadow_alpha=48)
    place_layer(canvas, sidebar, side_quad, shadow_blur=12, shadow_alpha=70)
    place_layer(canvas, front, front_quad, shadow_blur=22, shadow_alpha=62)

    all_x = [p[0] for quad in (deep_quad, back_quad, side_quad, front_quad) for p in quad]
    all_y = [p[1] for quad in (deep_quad, back_quad, side_quad, front_quad) for p in quad]
    add_reflection(canvas, (int(min(all_x)), int(min(all_y)), int(max(all_x) + fw * 0.2), int(max(all_y) + fh * 0.05)))

    return canvas.convert("RGB")


def main() -> None:
    img = build()
    img.save(OUT, quality=93, optimize=True, progressive=True)
    print(f"wrote {OUT} ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()