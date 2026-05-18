"""Generates the Android launcher icons for PAK·PULSE.

The project was scaffolded without `mipmap/ic_launcher` resources, which fails
release resource linking. This renders an on-brand icon (dark ops-console navy
background with the red "pulse" rings + dot) at every required density.

Run from the project root:  python tool/gen_launcher_icons.py
"""

import os
from PIL import Image, ImageDraw

# PAK·PULSE palette
BG = (10, 14, 26, 255)        # #0A0E1A backgroundBase
PULSE = (255, 59, 92, 255)    # #FF3B5C critical / pulse

# density bucket -> icon size in px
DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

RES_DIR = os.path.join("android", "app", "src", "main", "res")


def render(size: int) -> Image.Image:
    # Supersample 4x for clean anti-aliased curves, then downscale.
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), BG)
    draw = ImageDraw.Draw(img)
    cx = cy = s / 2

    # Concentric pulse rings (fading outward).
    for radius_frac, alpha, width_frac in (
        (0.40, 70, 0.022),
        (0.29, 130, 0.026),
    ):
        r = s * radius_frac
        w = max(1, int(s * width_frac))
        draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            outline=(PULSE[0], PULSE[1], PULSE[2], alpha),
            width=w,
        )

    # Solid centre dot.
    r = s * 0.165
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PULSE)

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    if not os.path.isdir(RES_DIR):
        raise SystemExit(f"run from the project root; {RES_DIR} not found")
    for bucket, size in DENSITIES.items():
        out_dir = os.path.join(RES_DIR, f"mipmap-{bucket}")
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, "ic_launcher.png")
        render(size).save(path, "PNG")
        print(f"wrote {path} ({size}x{size})")


if __name__ == "__main__":
    main()
