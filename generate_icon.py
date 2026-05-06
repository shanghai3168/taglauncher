#!/usr/bin/env python3
"""Generate Apptag app icon — two overlapping tags (red + blue) on macOS squircle."""
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import math, os, subprocess

SIZE = 1024
OUT_DIR = "/Users/ar/Projects/Apptag/Apptag/Assets.xcassets/AppIcon.appiconset"
os.makedirs(OUT_DIR, exist_ok=True)

def rounded_rectangle_mask(size, radius):
    """Create a mask for a rounded rectangle."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size-1, size-1)], radius=radius, fill=255)
    return mask

def draw_tag(draw, cx, cy, width, height, color, angle_deg, hole_ratio=0.22):
    """Draw a tag shape (rounded rect with hole) rotated by angle."""
    # Create a temp image for this tag
    padding = int(width * 1.5)
    tag_img = Image.new("RGBA", (padding*2, padding*2), (0,0,0,0))
    tag_draw = ImageDraw.Draw(tag_img)
    
    x0 = padding - width//2
    y0 = padding - height//2
    x1 = padding + width//2
    y1 = padding + height//2
    r = int(min(width, height) * 0.18)  # corner radius
    
    # Main tag body
    tag_draw.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=color)
    
    # Hole at top
    hole_r = int(width * hole_ratio)
    hole_x = padding + width//2 - int(width * 0.22)
    hole_y = padding - height//2 + int(height * 0.2)
    tag_draw.ellipse(
        [hole_x - hole_r, hole_y - hole_r, hole_x + hole_r, hole_y + hole_r],
        fill=(0,0,0,0)
    )
    
    # Rotate
    tag_img = tag_img.rotate(angle_deg, resample=Image.BICUBIC, expand=True)
    
    return tag_img, padding, hole_x, hole_y

# --- Build the icon ---
img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
draw = ImageDraw.Draw(img)

# macOS Big Sur style squircle background
squircle_r = int(SIZE * 0.225)  # ~225px for 1024 canvas
bg_mask = rounded_rectangle_mask(SIZE, squircle_r)
bg_color = Image.new("RGBA", (SIZE, SIZE), (240, 241, 245, 255))  # Light gray bg
img = Image.composite(bg_color, img, bg_mask)

# Create two tags
red_color = (220, 45, 85, 255)    # Rich red/pink
blue_color = (45, 130, 220, 255)  # Vibrant blue

# Red tag - slightly tilted left, on top
tag_w = int(SIZE * 0.42)
tag_h = int(SIZE * 0.55)
red_tag, red_pad, _, _ = draw_tag(None, 0, 0, tag_w, tag_h, red_color, -8)
# Position center, slightly up
red_x = SIZE//2 - red_tag.width//2
red_y = SIZE//2 - red_tag.height//2 - int(SIZE * 0.04)

# Blue tag - tilted right, behind/below
tag_w2 = int(SIZE * 0.46)
tag_h2 = int(SIZE * 0.58)
blue_tag, _, _, _ = draw_tag(None, 0, 0, tag_w2, tag_h2, blue_color, 12)
blue_x = SIZE//2 - blue_tag.width//2 + int(SIZE * 0.02)
blue_y = SIZE//2 - blue_tag.height//2 + int(SIZE * 0.03)

# Composite: blue behind, red in front
# Add drop shadows first
shadow = blue_tag.copy()
shadow_data = shadow.getdata()
shadow.putdata([(0,0,0, min(a//4, 80)) if a > 0 else (0,0,0,0) for (r,g,b,a) in shadow_data])
shadow = shadow.filter(ImageFilter.GaussianBlur(radius=SIZE*0.025))
img.paste(shadow, (blue_x+int(SIZE*0.015), blue_y+int(SIZE*0.02)), shadow)

img.paste(blue_tag, (blue_x, blue_y), blue_tag)

# Red tag shadow
shadow2 = red_tag.copy()
shadow_data2 = shadow2.getdata()
shadow2.putdata([(0,0,0, min(a//3, 80)) if a > 0 else (0,0,0,0) for (r,g,b,a) in shadow_data2])
shadow2 = shadow2.filter(ImageFilter.GaussianBlur(radius=SIZE*0.02))
img.paste(shadow2, (red_x+int(SIZE*0.01), red_y+int(SIZE*0.015)), shadow2)

img.paste(red_tag, (red_x, red_y), red_tag)

# Apply squircle clip mask
mask = rounded_rectangle_mask(SIZE, squircle_r)
img.putalpha(mask)

# --- Save PNG variants for .icns ---
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
    resized.save(os.path.join(OUT_DIR, name), "PNG")
    print(f"  {name} ({size}x{size})")

# Also save a 1024 preview
img.save(os.path.join(OUT_DIR, "icon_1024_preview.png"), "PNG")
print(f"\nSaved {len(variants)} variants to {OUT_DIR}")

# --- Generate .icns using iconutil ---
iconset_dir = OUT_DIR.rstrip('/')
subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", 
    "/Users/ar/Projects/Apptag/build/Apptag.app/Contents/Resources/AppIcon.icns"],
    check=True)
print("Generated AppIcon.icns")

# Also copy to build dir
subprocess.run(["cp", os.path.join(OUT_DIR, "icon_1024_preview.png"),
    "/Users/ar/Projects/Apptag/icon_preview.png"], check=True)
print("Preview: /Users/ar/Projects/Apptag/icon_preview.png")
