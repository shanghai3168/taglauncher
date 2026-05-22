#!/usr/bin/env python3
"""Generate TagLauncher app icon — two overlapping tags (red + blue) on macOS squircle."""
from PIL import Image, ImageDraw, ImageFilter
import math, os, subprocess, tempfile

SIZE = 1024
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))

def rounded_rectangle_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size-1, size-1)], radius=radius, fill=255)
    return mask

def draw_tag(cx, cy, width, height, color, angle_deg, hole_ratio=0.22):
    padding = int(width * 1.5)
    tag_img = Image.new("RGBA", (padding*2, padding*2), (0,0,0,0))
    tag_draw = ImageDraw.Draw(tag_img)
    x0 = padding - width//2
    y0 = padding - height//2
    x1 = padding + width//2
    y1 = padding + height//2
    r = int(min(width, height) * 0.18)
    tag_draw.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=color)
    hole_r = int(width * hole_ratio)
    hole_x = padding + width//2 - int(width * 0.22)
    hole_y = padding - height//2 + int(height * 0.2)
    tag_draw.ellipse(
        [hole_x - hole_r, hole_y - hole_r, hole_x + hole_r, hole_y + hole_r],
        fill=(0,0,0,0)
    )
    tag_img = tag_img.rotate(angle_deg, resample=Image.BICUBIC, expand=True)
    return tag_img

# --- Build the icon ---
img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))

squircle_r = int(SIZE * 0.225)
bg_mask = rounded_rectangle_mask(SIZE, squircle_r)
bg_color = Image.new("RGBA", (SIZE, SIZE), (240, 241, 245, 255))
img = Image.composite(bg_color, img, bg_mask)

red_color = (220, 45, 85, 255)
blue_color = (45, 130, 220, 255)

tag_w = int(SIZE * 0.42)
tag_h = int(SIZE * 0.55)
red_tag = draw_tag(0, 0, tag_w, tag_h, red_color, -8)
red_x = SIZE//2 - red_tag.width//2
red_y = SIZE//2 - red_tag.height//2 - int(SIZE * 0.04)

tag_w2 = int(SIZE * 0.46)
tag_h2 = int(SIZE * 0.58)
blue_tag = draw_tag(0, 0, tag_w2, tag_h2, blue_color, 12)
blue_x = SIZE//2 - blue_tag.width//2 + int(SIZE * 0.02)
blue_y = SIZE//2 - blue_tag.height//2 + int(SIZE * 0.03)

# Drop shadows
shadow = blue_tag.copy()
shadow_data = shadow.getdata()
shadow.putdata([(0,0,0, min(a//4, 80)) if a > 0 else (0,0,0,0) for (r,g,b,a) in shadow_data])
shadow = shadow.filter(ImageFilter.GaussianBlur(radius=SIZE*0.025))
img.paste(shadow, (blue_x+int(SIZE*0.015), blue_y+int(SIZE*0.02)), shadow)
img.paste(blue_tag, (blue_x, blue_y), blue_tag)

shadow2 = red_tag.copy()
shadow_data2 = shadow2.getdata()
shadow2.putdata([(0,0,0, min(a//3, 80)) if a > 0 else (0,0,0,0) for (r,g,b,a) in shadow_data2])
shadow2 = shadow2.filter(ImageFilter.GaussianBlur(radius=SIZE*0.02))
img.paste(shadow2, (red_x+int(SIZE*0.01), red_y+int(SIZE*0.015)), shadow2)
img.paste(red_tag, (red_x, red_y), red_tag)

mask = rounded_rectangle_mask(SIZE, squircle_r)
img.putalpha(mask)

# --- Save PNG variants to temp .iconset, then generate .icns ---
with tempfile.TemporaryDirectory() as tmpdir:
    iconset = os.path.join(tmpdir, "AppIcon.iconset")
    os.makedirs(iconset)

    variants = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    for name, size in variants:
        resized = img.resize((size, size), Image.LANCZOS)
        path = os.path.join(iconset, name)
        resized.save(path, "PNG", optimize=True)
        print(f"  {name} ({size}x{size}): {os.path.getsize(path):,}B")

    # Generate .icns to project root
    out_icns = os.path.join(PROJECT_DIR, "icon-icns.icns")
    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", out_icns], check=True)
    icns_size = os.path.getsize(out_icns)
    print(f"\nGenerated: {out_icns} ({icns_size:,}B, {icns_size/1024:.0f}KB)")

# Also save 1024x1024 preview
preview_path = os.path.join(PROJECT_DIR, "icon_preview.png")
img.save(preview_path, "PNG", optimize=True)
print(f"Preview: {preview_path}")
