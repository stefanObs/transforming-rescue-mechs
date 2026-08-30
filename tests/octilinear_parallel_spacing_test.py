#!/usr/bin/env python3
"""S07 regression: absorb near-parallel artifacts; separate real pairs (pure Python)."""
from __future__ import annotations

import importlib.util
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "gen_seuzach_octilinear_roads.py"


def _load():
    spec = importlib.util.spec_from_file_location("gen_octi", SCRIPT)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def fail(msg: str) -> None:
    print(f"FAIL {msg}", file=sys.stderr)
    raise SystemExit(1)


def ok(msg: str) -> None:
    print(f"OK  {msg}")


def test_absorb_artifact_double(g) -> None:
    """Local link riding 200 wu beside a main → absorbed (dropped or merged)."""
    main = {
        "name": "MainCorridor",
        "class": "main",
        "points": [[0.0, 0.0], [4000.0, 0.0]],
    }
    # Artifact double: parallel 200 wu south, long overlap, link-* name.
    double = {
        "name": "link-double-main",
        "class": "local",
        "points": [[200.0, 200.0], [3800.0, 200.0]],
    }
    filler = {
        "name": "FarRoad",
        "class": "local",
        "points": [[0.0, 5000.0], [2000.0, 5000.0]],
    }
    before = g.find_near_parallel_pairs([main, double, filler], max_mid=g.PARALLEL_TOO_CLOSE)
    assert any(p["mid_dist"] <= g.PARALLEL_ABSORB for p in before), before
    out = g.resolve_near_parallels([main, double, filler])
    names = {r["name"] for r in out}
    if "link-double-main" not in names:
        ok("absorb artifact double (link dropped)")
        return
    pairs = g.find_near_parallel_pairs(
        [r for r in out if r["name"] in ("MainCorridor", "link-double-main")],
        max_mid=g.PARALLEL_ABSORB,
        min_mid=0.0,
    )
    if pairs:
        fail(f"absorb left close parallel: {pairs} roads={names}")
    ok("absorb artifact double (link merged, no close parallel)")


def test_separate_real_locals(g) -> None:
    """Two named locals ~300 wu apart → offset so mid-distance ≥ PARALLEL_MIN_GAP."""
    a = {
        "name": "AlphaStrasse",
        "class": "local",
        "points": [[0.0, 0.0], [3000.0, 0.0]],
    }
    b = {
        "name": "BetaStrasse",
        "class": "local",
        "points": [[200.0, 300.0], [2800.0, 300.0]],
    }
    filler = {
        "name": "GammaFar",
        "class": "local",
        "points": [[0.0, 8000.0], [2000.0, 8000.0]],
    }
    before = g.find_near_parallel_pairs([a, b, filler], max_mid=g.PARALLEL_TOO_CLOSE)
    assert before, "expected a near-parallel pair before resolve"
    assert any(80.0 <= p["mid_dist"] <= 400.0 for p in before), before
    out = g.resolve_near_parallels([a, b, filler])
    by = {r["name"]: r for r in out}
    assert "AlphaStrasse" in by and "BetaStrasse" in by
    pairs = g.find_near_parallel_pairs(
        [by["AlphaStrasse"], by["BetaStrasse"]], max_mid=g.PARALLEL_TOO_CLOSE
    )
    for p in pairs:
        if p["mid_dist"] < g.PARALLEL_MIN_GAP - g.LATTICE:
            fail(f"separate left mid_dist={p['mid_dist']:.0f} < min_gap: {p}")
    # Both roads still octilinear
    g.validate_octilinear([by["AlphaStrasse"], by["BetaStrasse"]])
    ok("separate real named locals to min gap")


def test_pinned_main_not_moved(g) -> None:
    """Winterthurerstrasse stays put when a local rides 300 wu beside it."""
    winter = {
        "name": "Winterthurerstrasse",
        "class": "main",
        "points": [[0.0, 0.0], [5000.0, 0.0]],
    }
    local = {
        "name": "Eibenstrasse",
        "class": "local",
        "points": [[400.0, 300.0], [4400.0, 300.0]],
    }
    # Minimal REQUIRED partners so force_required (if triggered) doesn't explode.
    stations = {
        "name": "Stationsstrasse",
        "class": "main",
        "points": [[5000.0, 0.0], [7000.0, 0.0]],
    }
    ohringer = {
        "name": "Ohringerstrasse",
        "class": "main",
        "points": [[-2000.0, 0.0], [0.0, 0.0]],
    }
    out = g.resolve_near_parallels([winter, local, stations, ohringer])
    by = {r["name"]: r for r in out}
    w = [(float(x), float(y)) for x, y in by["Winterthurerstrasse"]["points"]]
    # Winter y should still be ~0 (not offset).
    ys = [p[1] for p in w]
    if max(abs(y) for y in ys) > g.LATTICE * 2:
        fail(f"Winter was moved: {w}")
    pairs = g.find_near_parallel_pairs(
        [by["Winterthurerstrasse"], by["Eibenstrasse"]], max_mid=g.PARALLEL_TOO_CLOSE
    )
    for p in pairs:
        if p["mid_dist"] < g.PARALLEL_MIN_GAP - g.LATTICE:
            fail(f"local not separated from Winter: mid={p['mid_dist']:.0f}")
    ok("pinned Winter stays; local separates")


def test_artifact_metric_nonincreasing(g) -> None:
    """Committed JSON after S07: near-parallel count in 80–400 wu is small."""
    import json

    path = ROOT / "data" / "seuzach_roads_octilinear.json"
    if not path.is_file():
        fail(f"missing {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    n = g.count_near_parallel_pairs(data["roads"], lo=80.0, hi=400.0)
    # Soft bound: pre-S07 ~27 with perp metric; pinned Ohringer↔Winter may remain.
    if n > 6:
        fail(f"too many near-parallel pairs remain in 80–400 wu: {n}")
    ok(f"artifact near-parallel count 80–400 wu = {n}")


def test_no_named_stubs(g) -> None:
    """Named roads must not be collapsed to meet-stubs (<800 wu) by resolve."""
    import json

    path = ROOT / "data" / "seuzach_roads_octilinear.json"
    if not path.is_file():
        fail(f"missing {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    stubs = []
    for r in data["roads"]:
        name = str(r["name"])
        if name.startswith("link-"):
            continue
        pts = [(float(x), float(y)) for x, y in r["points"]]
        L = g._polyline_length(pts)
        if L < 800.0:
            stubs.append((name, L, len(pts)))
    if stubs:
        fail(f"named roads collapsed to stubs: {stubs}")
    # Guard specific victims from review
    by = {r["name"]: r for r in data["roads"]}
    for must in ("Bruggackerweg", "Friedenstrasse", "Rebhogerstrasse", "Breitestrasse"):
        if must not in by:
            fail(f"missing named road {must}")
        L = g._polyline_length([(float(x), float(y)) for x, y in by[must]["points"]])
        if L < 2000.0:
            fail(f"{must} too short after S07: {L:.0f} wu")
    ok("no named-road stubs; key corridors keep length")


def main() -> None:
    print("=== octilinear_parallel_spacing_test start ===")
    if not SCRIPT.is_file():
        fail(f"missing {SCRIPT}")
    g = _load()
    test_absorb_artifact_double(g)
    test_separate_real_locals(g)
    test_pinned_main_not_moved(g)
    # Artifact metric runs after regenerate; still useful if JSON is current.
    test_artifact_metric_nonincreasing(g)
    test_no_named_stubs(g)
    print("=== octilinear_parallel_spacing_test passed ===")


if __name__ == "__main__":
    main()
