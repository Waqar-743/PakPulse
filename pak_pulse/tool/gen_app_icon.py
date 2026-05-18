"""Generates the Android launcher icons for PAK·PULSE from the brand mark.

Takes the master `Pak-Pulse-ICON.png` (kept one level above the project root,
in the APP/ folder) and renders it down to every required mipmap density so
the launcher shows the real PAK·PULSE logo instead of a placeholder.

Run from the project root:  python tool/gen_app_icon.py
"""

import os
from PIL import Image

# Master brand mark — APP/Pak-Pulse-ICON.png (one level above pak_pulse/).
SRC_CANDIDATES = [
    os.path.join("..", "Pak-Pulse-ICON.png"),
    r"D:\dell\Downloads\APP-FLUTTER\APP\Pak-Pulse-ICON.png",
]

# density bucket -> icon size in px
DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

RES_DIR = os.path.join("android", "app", "src", "main", "res")


def find_source() -> str:
    for path in SRC_CANDIDATES:
        if os.path.isfile(path):
            return path
    raise SystemExit(
        "Pak-Pulse-ICON.png not found; expected it in the APP/ folder "
        "next to the pak_pulse project."
    )


def main() -> None:
    if not os.path.isdir(RES_DIR):
        raise SystemExit(f"run from the project root; {RES_DIR} not found")

    src = find_source()
    master = Image.open(src).convert("RGBA")
    print(f"source: {src} ({master.width}x{master.height})")

    for bucket, size in DENSITIES.items():
        out_dir = os.path.join(RES_DIR, f"mipmap-{bucket}")
        os.makedirs(out_dir, exist_ok=True)
        icon = master.resize((size, size), Image.LANCZOS)
        path = os.path.join(out_dir, "ic_launcher.png")
        icon.save(path, "PNG")
        print(f"wrote {path} ({size}x{size})")


if __name__ == "__main__":
    main()
