"""Process CARE-AI / Child-Care Thrive brand assets.

Run from the repository root after the two raw logo/splash PNGs have been uploaded to:

    branding/source/

This script detects the two uploaded PNGs, identifies the portrait splash asset versus the
HSPN ribbon logo asset, and writes cleaned implementation-ready files to:

    branding/processed/

Install dependency:
    python -m pip install pillow numpy

Run:
    python tools/process_brand_assets.py
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "branding" / "source"
OUT_DIR = ROOT / "branding" / "processed"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def open_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def nonwhite_bbox(img: Image.Image, threshold: int = 245, padding: int = 30) -> tuple[int, int, int, int]:
    arr = np.array(img)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    nonwhite = (alpha > 0) & ~((rgb[:, :, 0] > threshold) & (rgb[:, :, 1] > threshold) & (rgb[:, :, 2] > threshold))
    ys, xs = np.where(nonwhite)
    if len(xs) == 0:
        return (0, 0, img.width, img.height)
    return (
        max(0, int(xs.min()) - padding),
        max(0, int(ys.min()) - padding),
        min(img.width, int(xs.max()) + 1 + padding),
        min(img.height, int(ys.max()) + 1 + padding),
    )


def detect_assets() -> tuple[Path, Path]:
    pngs = sorted([p for p in SOURCE_DIR.glob("*.png") if not p.name.startswith(".")])
    if len(pngs) < 2:
        raise SystemExit(f"Expected at least two PNG files in {SOURCE_DIR}. Found: {[p.name for p in pngs]}")

    scored = []
    for p in pngs:
        img = Image.open(p)
        ratio = img.height / max(img.width, 1)
        scored.append((ratio, p, img.size))

    # The splash screen is portrait/tall. The HSPN ribbon logo is landscape/square-ish.
    splash_path = max(scored, key=lambda x: x[0])[1]
    logo_path = min(scored, key=lambda x: x[0])[1]
    return logo_path, splash_path


def process_hspn_logo(path: Path) -> None:
    logo = open_rgba(path)
    arr = np.array(logo)
    rgb = arr[:, :, :3]

    # Remove obvious black corner/background pixels before cropping.
    dark = (rgb[:, :, 0] < 20) & (rgb[:, :, 1] < 20) & (rgb[:, :, 2] < 20)
    arr_for_bbox = arr.copy()
    arr_for_bbox[dark, 3] = 0
    crop_source = Image.fromarray(arr_for_bbox, "RGBA")
    crop = logo.crop(nonwhite_bbox(crop_source, padding=30))

    # Horizontal logo on white background.
    horizontal = crop.copy()
    h_arr = np.array(horizontal)
    h_rgb = h_arr[:, :, :3]
    h_dark = (h_rgb[:, :, 0] < 20) & (h_rgb[:, :, 1] < 20) & (h_rgb[:, :, 2] < 20)
    h_arr[h_dark, :3] = 255
    h_arr[h_dark, 3] = 255
    horizontal = Image.fromarray(h_arr, "RGBA")
    horizontal.thumbnail((1200, 500), Image.Resampling.LANCZOS)
    horizontal.save(OUT_DIR / "hspn-ribbon-logo-horizontal.png", optimize=True)

    # Transparent version: remove white canvas and black corners.
    transparent = crop.copy()
    t_arr = np.array(transparent)
    t_rgb = t_arr[:, :, :3]
    white = (t_rgb[:, :, 0] > 245) & (t_rgb[:, :, 1] > 245) & (t_rgb[:, :, 2] > 245)
    dark = (t_rgb[:, :, 0] < 20) & (t_rgb[:, :, 1] < 20) & (t_rgb[:, :, 2] < 20)
    t_arr[white | dark, 3] = 0
    transparent = Image.fromarray(t_arr, "RGBA")
    transparent.thumbnail((1200, 500), Image.Resampling.LANCZOS)
    transparent.save(OUT_DIR / "hspn-ribbon-logo-transparent.png", optimize=True)


def process_splash(path: Path) -> None:
    splash = open_rgba(path)
    w, h = splash.size

    # Android splash source, padded to 1080 x 1920.
    canvas = Image.new("RGBA", (1080, 1920), (255, 255, 255, 255))
    sp = splash.copy()
    sp.thumbnail((1080, 1920), Image.Resampling.LANCZOS)
    canvas.alpha_composite(sp, ((1080 - sp.width) // 2, (1920 - sp.height) // 2))
    canvas.save(OUT_DIR / "child-care-thrive-splash-portrait.png", optimize=True)

    # Login/header logo: crop the top identity area.
    header = splash.crop((0, 0, w, int(h * 0.32)))
    header = header.crop(nonwhite_bbox(header, padding=40))
    login = header.copy()
    login.thumbnail((1000, 300), Image.Resampling.LANCZOS)
    login.save(OUT_DIR / "care-ai-login-logo.png", optimize=True)

    header_small = header.copy()
    header_small.thumbnail((600, 180), Image.Resampling.LANCZOS)
    header_small.save(OUT_DIR / "care-ai-header-logo.png", optimize=True)

    # App icon/favicon source: crop the blue heart from the top of the splash.
    heart = splash.crop((int(w * 0.28), int(h * 0.03), int(w * 0.72), int(h * 0.20)))
    arr = np.array(heart)
    rgb = arr[:, :, :3]
    blue = (rgb[:, :, 2] > 130) & (rgb[:, :, 0] < 150) & (rgb[:, :, 1] > 70)
    ys, xs = np.where(blue)
    if len(xs) > 0:
        box = (
            max(0, int(xs.min()) - 40),
            max(0, int(ys.min()) - 40),
            min(heart.width, int(xs.max()) + 1 + 40),
            min(heart.height, int(ys.max()) + 1 + 40),
        )
        heart = heart.crop(box)

    icon = Image.new("RGBA", (1024, 1024), (234, 244, 255, 255))
    heart.thumbnail((720, 720), Image.Resampling.LANCZOS)
    icon.alpha_composite(heart, ((1024 - heart.width) // 2, (1024 - heart.height) // 2))
    icon.save(OUT_DIR / "child-care-thrive-app-icon.png", optimize=True)

    favicon = icon.resize((512, 512), Image.Resampling.LANCZOS)
    favicon.save(OUT_DIR / "child-care-thrive-favicon.png", optimize=True)


def main() -> None:
    logo_path, splash_path = detect_assets()
    print(f"Detected HSPN logo: {logo_path}")
    print(f"Detected splash screen: {splash_path}")
    process_hspn_logo(logo_path)
    process_splash(splash_path)
    print("Processed assets written to:")
    for p in sorted(OUT_DIR.glob("*.png")):
        print(f" - {p.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
