#!/usr/bin/env python3
"""Regenerate the current TagLauncher grid/rainbow app icon assets."""

from __future__ import annotations

import colorsys
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


SIZE = 1024
PROJECT_DIR = Path(__file__).resolve().parent
APPICON_DIR = PROJECT_DIR / "Apptag" / "Assets.xcassets" / "AppIcon.appiconset"
ROOT_ICNS = PROJECT_DIR / "icon-icns.icns"

RELEASE_ICON_TARGETS = [
    PROJECT_DIR
    / "Release"
    / "AppStore-7.6.0-20260527.0124"
    / "Assets"
    / "TagLauncher-AppIcon-1024.png",
    PROJECT_DIR
    / "Release"
    / "_archive"
    / "AppStore-7.6.0-20260525.0016"
    / "Assets"
    / "TagLauncher-AppIcon-1024.png",
]

SOURCE_CANDIDATES = [
    APPICON_DIR / "icon_512x512@2x.png",
    RELEASE_ICON_TARGETS[0],
    ROOT_ICNS,
]

VARIANTS = [
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

# The approved grid/rainbow icon artwork sits inside this rounded rect.
# Keeping this mask explicit prevents the old opaque-white square corners from
# reappearing when assets are regenerated from an older flattened source.
MASK_BOUNDS = (77, 57, 943, 934)
MASK_RADIUS = 232


def load_source() -> tuple[Path, Image.Image]:
    for path in SOURCE_CANDIDATES:
        if not path.exists():
            continue
        with Image.open(path) as image:
            image.load()
            source = image.convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS)
        return path, source
    raise FileNotFoundError("No app icon source found.")


def assert_current_grid_rainbow_icon(image: Image.Image) -> None:
    """Reject the removed two-tag icon if it is accidentally used as source."""

    bands = {"yellow": 0, "green": 0, "cyan": 0, "purple": 0}
    pixels = image.load()

    for y in range(120, 900, 4):
        for x in range(520, 900, 4):
            red, green, blue, alpha = pixels[x, y]
            if alpha < 128:
                continue
            hue, saturation, value = colorsys.rgb_to_hsv(
                red / 255.0, green / 255.0, blue / 255.0
            )
            if saturation < 0.30 or value < 0.35:
                continue
            if 0.10 <= hue <= 0.19:
                bands["yellow"] += 1
            elif 0.20 <= hue <= 0.42:
                bands["green"] += 1
            elif 0.43 <= hue <= 0.58:
                bands["cyan"] += 1
            elif 0.70 <= hue <= 0.86:
                bands["purple"] += 1

    present_bands = [name for name, count in bands.items() if count >= 100]
    if len(present_bands) < 3:
        raise ValueError(
            "Source image does not match the current grid/rainbow icon family; "
            f"detected color bands: {bands}"
        )


def icon_mask() -> Image.Image:
    x0, y0, x1, y1 = MASK_BOUNDS
    mask = Image.new("L", (SIZE, SIZE), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        [x0, y0, x1 - 1, y1 - 1],
        radius=MASK_RADIUS,
        fill=255,
    )
    return mask


def normalize_icon(image: Image.Image) -> Image.Image:
    image = image.resize((SIZE, SIZE), Image.LANCZOS).convert("RGBA")
    alpha = ImageChops.multiply(image.getchannel("A"), icon_mask())
    normalized = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    normalized.paste(image, (0, 0), alpha)
    normalized.putalpha(alpha)
    return normalized


def save_png(path: Path, image: Image.Image, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize((size, size), Image.LANCZOS)
    resized.save(path, "PNG", optimize=True)
    print(f"  {path.relative_to(PROJECT_DIR)} ({size}x{size})")


def generate_icns(image: Image.Image) -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        iconset = Path(temp_dir) / "AppIcon.iconset"
        iconset.mkdir()
        for name, size in VARIANTS:
            image.resize((size, size), Image.LANCZOS).save(iconset / name, "PNG")
        subprocess.run(
            ["iconutil", "-c", "icns", str(iconset), "-o", str(ROOT_ICNS)],
            check=True,
        )
    print(f"  {ROOT_ICNS.relative_to(PROJECT_DIR)}")


def print_corner_alpha(path: Path) -> None:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        width, height = rgba.size
        corners = [
            rgba.getpixel((0, 0))[3],
            rgba.getpixel((width - 1, 0))[3],
            rgba.getpixel((0, height - 1))[3],
            rgba.getpixel((width - 1, height - 1))[3],
        ]
    print(f"  alpha corners {path.relative_to(PROJECT_DIR)}: {corners}")


def main() -> None:
    source_path, source = load_source()
    assert_current_grid_rainbow_icon(source)
    icon = normalize_icon(source)

    print(f"Source: {source_path.relative_to(PROJECT_DIR)}")
    print("Writing AppIcon.appiconset:")
    save_png(APPICON_DIR / "icon_1024_preview.png", icon, 1024)
    for name, size in VARIANTS:
        save_png(APPICON_DIR / name, icon, size)

    print("Writing release 1024 assets:")
    for target in RELEASE_ICON_TARGETS:
        save_png(target, icon, 1024)

    print("Writing root .icns:")
    generate_icns(icon)

    print("Validation:")
    print_corner_alpha(ROOT_ICNS)
    print_corner_alpha(APPICON_DIR / "icon_512x512@2x.png")
    for target in RELEASE_ICON_TARGETS:
        print_corner_alpha(target)


if __name__ == "__main__":
    main()
