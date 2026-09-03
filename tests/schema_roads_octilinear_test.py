#!/usr/bin/env python3
"""Schema roads: H/V/45° only; live path is seuzach_schema_roads.json."""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "data" / "seuzach_schema_roads.json"


def fail(msg: str) -> None:
    print(f"FAIL {msg}", file=sys.stderr)
    raise SystemExit(1)


def ok(msg: str) -> None:
    print(f"OK  {msg}")


def is_octilinear(dx: float, dy: float) -> bool:
    if abs(dx) < 1e-6 and abs(dy) < 1e-6:
        return True
    if abs(dx) < 1e-6 or abs(dy) < 1e-6:
        return True
    return abs(abs(dx) - abs(dy)) < 1e-3


def main() -> None:
    if not PATH.is_file():
        fail("missing %s" % PATH)
    data = json.loads(PATH.read_text(encoding="utf-8"))
    roads = data.get("roads", [])
    names = {r.get("name") for r in roads}
    for required in (
        "Hauptstrasse",
        "Stationsstrasse",
        "Ohringerstrasse",
        "Schulstrasse",
        "Wohnstrasse",
    ):
        if required not in names:
            fail("missing road %s" % required)
    ok("named schema roads")
    for road in roads:
        pts = road.get("points", [])
        for i in range(len(pts) - 1):
            a, b = pts[i], pts[i + 1]
            if not is_octilinear(b[0] - a[0], b[1] - a[1]):
                fail("%s segment not H/V/45: %s → %s" % (road.get("name"), a, b))
    ok("all segments H/V/45")
    ws = ROOT / "scripts" / "world_sandbox.gd"
    text = ws.read_text(encoding="utf-8")
    if "seuzach_schema_roads.json" not in text:
        fail("world_sandbox must load seuzach_schema_roads.json")
    if 'ROADS_JSON := "res://data/seuzach_roads.json"' in text:
        fail("world_sandbox still loads OSM seuzach_roads.json")
    ok("world_sandbox schema load path")


if __name__ == "__main__":
    main()
    print("=== schema_roads_octilinear_test passed ===")
