#!/usr/bin/env python3
"""Pad robot walk frames per (character, direction) to a shared canvas (feet bottom-center)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parents[1] / "assets" / "art"
CHARS = ("bolt", "marina", "rush")
DIRS = ("n", "e", "s", "ne", "se")


def pad_group(paths: list[Path]) -> None:
    imgs = [Image.open(p).convert("RGBA") for p in paths]
    max_w = max(im.size[0] for im in imgs)
    max_h = max(im.size[1] for im in imgs)
    for p, im in zip(paths, imgs):
        canvas = Image.new("RGBA", (max_w, max_h), (0, 0, 0, 0))
        x = (max_w - im.size[0]) // 2
        y = max_h - im.size[1]
        canvas.paste(im, (x, y), im)
        canvas.save(p, "PNG", optimize=True)
        print(f"OK  {p.name} -> {max_w}x{max_h}")


def main() -> int:
    for c in CHARS:
        for d in DIRS:
            paths = [ART / f"{c}_robot_walk_{d}_{i:02d}.png" for i in range(1, 5)]
            if not all(p.exists() for p in paths):
                print(f"SKIP {c} walk_{d} (missing frames)")
                continue
            pad_group(paths)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
