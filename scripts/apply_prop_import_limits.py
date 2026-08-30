#!/usr/bin/env python3
"""Set process/size_limit on house_street_* and landmark_* Godot .import files (S02)."""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ART = ROOT / "assets" / "art"
SIZE_LIMIT = 768
PATTERNS = ("house_street_*.png.import", "landmark_*.png.import")


def patch(path: pathlib.Path) -> bool:
	text = path.read_text(encoding="utf-8")
	new, n = re.subn(
		r"(?m)^process/size_limit=\d+\s*$",
		f"process/size_limit={SIZE_LIMIT}",
		text,
	)
	if n == 0:
		return False
	if new == text:
		return False
	path.write_text(new, encoding="utf-8")
	return True


def main() -> int:
	changed = 0
	for pat in PATTERNS:
		for path in sorted(ART.glob(pat)):
			if patch(path):
				changed += 1
				print(f"updated {path.relative_to(ROOT)}")
	print(f"size_limit={SIZE_LIMIT}: {changed} file(s) changed")
	return 0


if __name__ == "__main__":
	sys.exit(main())
