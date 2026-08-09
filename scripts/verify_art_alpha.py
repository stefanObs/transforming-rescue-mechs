#!/usr/bin/env python3
"""Fail if game-ready art still has opaque white corner backdrops."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parents[1] / "assets" / "art"
WHITE_MIN = 245


def check(path: Path) -> list[str]:
    errors: list[str] = []
    im = Image.open(path)
    if im.mode != "RGBA":
        errors.append(f"{path.name}: mode is {im.mode}, expected RGBA")
        return errors
    w, h = im.size
    corners = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    for x, y in corners:
        r, g, b, a = im.getpixel((x, y))
        if a > 12 and r >= WHITE_MIN and g >= WHITE_MIN and b >= WHITE_MIN:
            errors.append(
                f"{path.name}: opaque white at corner ({x},{y}) a={a} rgb=({r},{g},{b})"
            )
        elif a > 12 and r >= 250 and g >= 250 and b >= 250:
            errors.append(
                f"{path.name}: near-white opaque corner ({x},{y}) a={a}"
            )
    # Sample a few border midpoints
    samples = [(w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]
    white_border = 0
    for x, y in samples:
        r, g, b, a = im.getpixel((x, y))
        if a > 12 and r >= WHITE_MIN and g >= WHITE_MIN and b >= WHITE_MIN:
            white_border += 1
    if white_border >= 3:
        errors.append(f"{path.name}: white backdrop still present on borders ({white_border}/4 samples)")
    return errors


def main() -> int:
    files = sorted(ART.glob("*.png"))
    if not files:
        print("FAIL: no PNGs in", ART, file=sys.stderr)
        return 1
    all_errors: list[str] = []
    for path in files:
        all_errors.extend(check(path))
    if all_errors:
        print("FAIL: white/opaque backdrop checks")
        for e in all_errors:
            print(" -", e)
        return 1
    print(f"OK  verified {len(files)} art PNGs (no white corner backdrops)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
