#!/usr/bin/env python3
"""Fail if game-ready art still has opaque light-gray/white backdrops."""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parents[1] / "assets" / "art"
BACKDROP_MIN = 230
BACKDROP_CHROMA_MAX = 14
## Border-connected backdrop above this share of the image fails.
MAX_BACKDROP_FRAC = 0.005


def is_backdrop(px: tuple[int, ...], threshold: int = BACKDROP_MIN) -> bool:
	r, g, b = int(px[0]), int(px[1]), int(px[2])
	if r < threshold or g < threshold or b < threshold:
		return False
	return max(r, g, b) - min(r, g, b) <= BACKDROP_CHROMA_MAX


def border_backdrop_count(im: Image.Image) -> int:
	w, h = im.size
	px = im.load()
	seen = [[False] * w for _ in range(h)]
	q: deque[tuple[int, int]] = deque()
	for x in range(w):
		q.append((x, 0))
		q.append((x, h - 1))
	for y in range(h):
		q.append((0, y))
		q.append((w - 1, y))
	count = 0
	while q:
		x, y = q.popleft()
		if x < 0 or y < 0 or x >= w or y >= h or seen[y][x]:
			continue
		seen[y][x] = True
		r, g, b, a = px[x, y]
		if a < 8:
			continue
		if not is_backdrop((r, g, b)):
			continue
		count += 1
		q.append((x - 1, y))
		q.append((x + 1, y))
		q.append((x, y - 1))
		q.append((x, y + 1))
	return count


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
		if a > 12 and is_backdrop((r, g, b)):
			errors.append(
				f"{path.name}: opaque backdrop at corner ({x},{y}) a={a} rgb=({r},{g},{b})"
			)
	total = w * h
	bg = border_backdrop_count(im)
	frac = bg / float(total)
	if frac > MAX_BACKDROP_FRAC:
		errors.append(
			f"{path.name}: border-connected backdrop {bg}px ({frac * 100:.2f}% > {MAX_BACKDROP_FRAC * 100:.2f}%)"
		)
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
