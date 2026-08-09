#!/usr/bin/env python3
"""Make Style-C art PNGs usable in Godot: remove white/black backdrop, crop, keep RGBA."""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parents[1] / "assets" / "art"
## Near-white / light-gray backdrop (AI plates often land at ~238–244, not pure 255).
BACKDROP_MIN = 230
## Max channel spread so teal/yellow highlights are not treated as backdrop.
BACKDROP_CHROMA_MAX = 14
## Near-black AI plates (max channel).
BLACK_MAX = 28
PAD = 8


def is_light_backdrop(px: tuple[int, ...], threshold: int = BACKDROP_MIN) -> bool:
    r, g, b = int(px[0]), int(px[1]), int(px[2])
    if r < threshold or g < threshold or b < threshold:
        return False
    return max(r, g, b) - min(r, g, b) <= BACKDROP_CHROMA_MAX


def is_near_black(px: tuple[int, ...], max_v: int = BLACK_MAX) -> bool:
    return max(int(px[0]), int(px[1]), int(px[2])) <= max_v


def is_content_color(px: tuple[int, ...]) -> bool:
    """Non-backdrop paint (body colors) — used to protect black outlines."""
    r, g, b = int(px[0]), int(px[1]), int(px[2])
    a = int(px[3]) if len(px) > 3 else 255
    if a < 8:
        return False
    if is_light_backdrop((r, g, b)) or is_near_black((r, g, b)):
        return False
    return True


def _border_flood(im: Image.Image, pred) -> set[tuple[int, int]]:
    w, h = im.size
    px = im.load()
    visited: set[tuple[int, int]] = set()
    q: deque[tuple[int, int]] = deque()

    def try_push(x: int, y: int) -> None:
        if 0 <= x < w and 0 <= y < h and (x, y) not in visited and pred(px[x, y]):
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


def border_light_mask(im: Image.Image) -> set[tuple[int, int]]:
    return _border_flood(im, is_light_backdrop)


def border_black_mask(im: Image.Image) -> set[tuple[int, int]]:
    """Near-black border flood, excluding pixels that touch content (keeps Style-C outlines)."""
    w, h = im.size
    px = im.load()
    candidates = _border_flood(im, is_near_black)
    keep: set[tuple[int, int]] = set()
    for x, y in candidates:
        for nx, ny in (
            (x - 1, y),
            (x + 1, y),
            (x, y - 1),
            (x, y + 1),
            (x - 1, y - 1),
            (x + 1, y - 1),
            (x - 1, y + 1),
            (x + 1, y + 1),
        ):
            if 0 <= nx < w and 0 <= ny < h and is_content_color(px[nx, ny]):
                keep.add((x, y))
                break
    return candidates - keep


def process(path: Path) -> None:
    im = Image.open(path).convert("RGBA")
    bg = border_light_mask(im) | border_black_mask(im)
    px = im.load()
    w, h = im.size

    for x, y in bg:
        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)

    # Soft fringe around removed light backdrop only
    for x, y in list(bg):
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if not (0 <= nx < w and 0 <= ny < h):
                continue
            if (nx, ny) in bg:
                continue
            r, g, b, a = px[nx, ny]
            if is_light_backdrop((r, g, b), BACKDROP_MIN) and a > 64:
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
