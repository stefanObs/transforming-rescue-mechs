#!/usr/bin/env python3
"""Make Style-C art PNGs usable in Godot: remove white backdrop, crop, keep RGBA."""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parents[1] / "assets" / "art"
WHITE_MIN = 245
NEAR_WHITE = 230
PAD = 8


def is_white(px: tuple[int, ...], threshold: int = WHITE_MIN) -> bool:
    r, g, b = px[0], px[1], px[2]
    return r >= threshold and g >= threshold and b >= threshold


def border_white_mask(im: Image.Image) -> set[tuple[int, int]]:
    """Pixels that are near-white and connected to the image border."""
    w, h = im.size
    px = im.load()
    visited: set[tuple[int, int]] = set()
    q: deque[tuple[int, int]] = deque()

    def try_push(x: int, y: int) -> None:
        if 0 <= x < w and 0 <= y < h and (x, y) not in visited and is_white(px[x, y]):
            visited.add((x, y))
            q.append((x, y))

    for x in range(w):
        try_push(x, 0)
        try_push(x, h - 1)
    for y in range(h):
        try_push(0, y)
        try_push(w - 1, y)

    while q:
        x, y = q.popleft()
        try_push(x - 1, y)
        try_push(x + 1, y)
        try_push(x, y - 1)
        try_push(x, y + 1)

    return visited


def process(path: Path) -> None:
    im = Image.open(path).convert("RGBA")
    bg = border_white_mask(im)
    px = im.load()
    w, h = im.size

    for x, y in bg:
        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)

    # Soft fringe around removed backdrop
    for x, y in list(bg):
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if not (0 <= nx < w and 0 <= ny < h):
                continue
            if (nx, ny) in bg:
                continue
            r, g, b, a = px[nx, ny]
            if is_white((r, g, b), NEAR_WHITE) and a > 64:
                px[nx, ny] = (r, g, b, 64)

    bbox = im.getbbox()
    if bbox:
        left, top, right, bottom = bbox
        left = max(0, left - PAD)
        top = max(0, top - PAD)
        right = min(w, right + PAD)
        bottom = min(h, bottom + PAD)
        im = im.crop((left, top, right, bottom))

    im.save(path, "PNG", optimize=True)
    print(f"OK  {path.name} -> {im.size[0]}x{im.size[1]} mode={im.mode}")


def main() -> int:
    files = sorted(ART.glob("*.png"))
    if not files:
        print("No PNGs in", ART, file=sys.stderr)
        return 1
    for path in files:
        process(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
