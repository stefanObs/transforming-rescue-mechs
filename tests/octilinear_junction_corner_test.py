#!/usr/bin/env python3
"""S06 regression: hub U-turn, endpoint-first snap, clean_corners (pure Python)."""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "archive" / "seuzach-osm" / "scripts" / "gen_seuzach_octilinear_roads.py"


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


def test_snap_max_distance(g) -> None:
    # Interior↔interior: only CONNECT_INTERIOR (~800)
    assert g.snap_max_distance(1, 5, 2, 5) == g.CONNECT_INTERIOR
    assert g.CONNECT_INTERIOR == g.JUNCTION_SNAP * 2
    # Endpoint↔any: CONNECT_NEAR
    assert g.snap_max_distance(0, 5, 2, 5) == g.CONNECT_NEAR
    assert g.snap_max_distance(1, 5, 4, 5) == g.CONNECT_NEAR
    assert g.snap_max_distance(0, 5, 0, 5) == g.CONNECT_NEAR
    # Far interior pair must not qualify under CONNECT_NEAR budget used alone
    assert g.CONNECT_INTERIOR < 2000.0 <= g.CONNECT_NEAR or g.CONNECT_NEAR == 2000.0
    ok("snap_max_distance endpoint vs interior")


def test_hub_no_uturn(g) -> None:
    """Synthetic Winter spike at averaged hub → force_required leaves turn <150°."""
    # Pre-pin geometry: Winter through-diagonal; Ohringer east end; Stations west end.
    # Old bug: averaging yanked Winter mid to (5600,-3000) creating 180° fold.
    winter = [
        [4000.0, -2000.0],
        [5400.0, -3200.0],
        [5200.0, -3400.0],
        [5000.0, -5000.0],
    ]
    ohringer = [
        [-8000.0, -2400.0],
        [5000.0, -2400.0],
        [5200.0, -2800.0],
    ]
    stations = [
        [4800.0, -2400.0],
        [8000.0, -2400.0],
        [12000.0, -2000.0],
    ]
    roads = [
        {"name": "Winterthurerstrasse", "class": "main", "points": winter},
        {"name": "Ohringerstrasse", "class": "main", "points": ohringer},
        {"name": "Stationsstrasse", "class": "main", "points": stations},
        # Satisfy other REQUIRED pairs with trivial shared stubs (far away).
        {
            "name": "Kirchgasse",
            "class": "local",
            "points": [[4000.0, -2000.0], [4200.0, -1800.0]],
        },
        {
            "name": "Breitestrasse",
            "class": "local",
            "points": [[5000.0, -5000.0], [5200.0, -5200.0]],
        },
        {
            "name": "Schaffhauserstrasse",
            "class": "main",
            "points": [[-1000.0, 1000.0], [0.0, 1000.0]],
        },
        {
            "name": "Schulstrasse",
            "class": "local",
            "points": [[0.0, 1000.0], [200.0, 1200.0]],
        },
        {
            "name": "Birchstrasse",
            "class": "local",
            "points": [[12000.0, -2000.0], [12200.0, -1800.0]],
        },
    ]
    out = g.force_required_junctions(roads)
    by = {r["name"]: r for r in out}
    w = [(float(x), float(y)) for x, y in by["Winterthurerstrasse"]["points"]]
    o = [(float(x), float(y)) for x, y in by["Ohringerstrasse"]["points"]]
    s = [(float(x), float(y)) for x, y in by["Stationsstrasse"]["points"]]

    shared = set()
    for p in w:
        for q in o:
            if g.dist(p, q) < 1.0:
                shared.add(p)
        for q in s:
            if g.dist(p, q) < 1.0 and p in shared:
                shared.add(p)
    # At least one Winter vertex shared with both O and S (triple hub).
    hub_candidates = []
    for p in w:
        on_o = any(g.dist(p, q) < 1.0 for q in o)
        on_s = any(g.dist(p, q) < 1.0 for q in s)
        if on_o and on_s:
            hub_candidates.append(p)
    if not hub_candidates:
        fail(f"no triple hub vertex after pin; W={w} O={o} S={s}")
    for hub in hub_candidates:
        for i, p in enumerate(w):
            if g.dist(p, hub) >= 1.0:
                continue
            if 0 < i < len(w) - 1:
                td = g.turn_deg(w[i - 1], w[i], w[i + 1])
                if td >= g.REVERSE_FOLD_DEG:
                    fail(f"Winter reverse fold {td:.1f}° at hub {hub} idx {i}: {w[i-1]}→{w[i]}→{w[i+1]}")
    ok("hub pin without Winter U-turn")


def test_clean_corners(g) -> None:
    # Reverse fold mid (not shared)
    folded = {
        "name": "FoldRoad",
        "class": "local",
        "points": [[0.0, 0.0], [1000.0, 0.0], [200.0, 0.0], [2000.0, 0.0]],
    }
    # Micro zig + colinear mid
    zig = {
        "name": "ZigRoad",
        "class": "local",
        "points": [
            [0.0, 0.0],
            [1000.0, 0.0],
            [1200.0, 200.0],  # ~135° stair mid
            [2200.0, 200.0],
            [2400.0, 200.0],  # micro then colinear
            [4000.0, 200.0],
        ],
    }
    # Shared junction must survive
    a = {
        "name": "ShareA",
        "class": "local",
        "points": [[0.0, 0.0], [2000.0, 0.0], [4000.0, 0.0]],
    }
    b = {
        "name": "ShareB",
        "class": "local",
        "points": [[2000.0, -2000.0], [2000.0, 0.0], [2000.0, 2000.0]],
    }
    out = g.clean_corners([folded, zig, a, b])
    by = {r["name"]: r for r in out}

    fp = by["FoldRoad"]["points"]
    for i in range(1, len(fp) - 1):
        td = g.turn_deg(
            (fp[i - 1][0], fp[i - 1][1]),
            (fp[i][0], fp[i][1]),
            (fp[i + 1][0], fp[i + 1][1]),
        )
        if td >= g.REVERSE_FOLD_DEG:
            fail(f"clean_corners left reverse fold on FoldRoad: {fp}")
    ok("clean_corners removes reverse fold")

    zp = by["ZigRoad"]["points"]
    micros = sum(
        1
        for i in range(len(zp) - 1)
        if g.dist(zp[i], zp[i + 1]) < g.MIN_CORNER_SEG_WU
    )
    if micros > 1:
        fail(f"clean_corners left too many micros ({micros}): {zp}")
    ok("clean_corners reduces micro/zig")

    sa = {(round(x), round(y)) for x, y in by["ShareA"]["points"]}
    sb = {(round(x), round(y)) for x, y in by["ShareB"]["points"]}
    if (2000, 0) not in sa or (2000, 0) not in sb:
        fail(f"shared junction dropped: A={by['ShareA']['points']} B={by['ShareB']['points']}")
    ok("clean_corners keeps shared junction")


def test_interior_snap_budget(g) -> None:
    """Two roads with interiors 2000 wu apart must not snap; endpoint 800 wu may."""
    # Mimic Pass-2 selection via snap_max_distance only (unit of policy).
    # Interior indices 1,1 distance would be 2000 > CONNECT_INTERIOR.
    assert g.snap_max_distance(1, 3, 1, 3) < 2000.0
    assert g.snap_max_distance(0, 3, 1, 3) >= 800.0
    ok("interior snap budget rejects far interior pairs")


def test_prune_coincident_overlap(g) -> None:
    """Stations must not keep a long coincident NS run with Winter."""
    winter = [
        (5600.0, -2000.0),
        (5600.0, -2400.0),
        (5600.0, -6000.0),
        (5600.0, -8000.0),
    ]
    # Bad Stations: hub then rides Winter south 3600 wu, then peels east.
    stations = [
        (5600.0, -2400.0),
        (5600.0, -6000.0),
        (8000.0, -6000.0),
        (12000.0, -4000.0),
    ]
    before = g.coincident_edge_length(stations, winter)
    assert before >= 3600.0 - 1.0
    pruned = g.prune_coincident_overlap(stations, winter)
    after = g.coincident_edge_length(pruned, winter)
    if after > g.LATTICE * 1.5:
        fail(f"prune left coincident run {after:.0f} wu: {pruned}")
    # Still meets Winter at hub
    if min(g.dist(p, (5600.0, -2400.0)) for p in pruned) >= 1.0:
        fail(f"prune lost hub meet: {pruned}")
    ok("prune_coincident_overlap strips double-trace")


def test_artifact_hub_metrics(g) -> None:
    """Committed JSON: REQUIRED gaps, hub turn, no W∩S long coincidence, Ohringer EW."""
    import json

    path = ROOT / "archive" / "seuzach-osm" / "data" / "seuzach_roads_octilinear.json"
    if not path.is_file():
        fail(f"missing {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    by = {r["name"]: r for r in data["roads"]}
    for a, b in g.REQUIRED_JUNCTIONS:
        if a not in by or b not in by:
            fail(f"missing road for junction {a}↔{b}")
        pa = [(float(x), float(y)) for x, y in by[a]["points"]]
        pb = [(float(x), float(y)) for x, y in by[b]["points"]]
        gap = min(g.dist(p, q) for p in pa for q in pb)
        if gap >= 1.0:
            fail(f"REQUIRED gap {a}↔{b} = {gap:.0f}")
    o = [(float(x), float(y)) for x, y in by["Ohringerstrasse"]["points"]]
    if abs(o[0][1] - o[-1][1]) > g.LATTICE * 2 and len(o) > 2:
        # allow short V stub at end only
        if not (len(o) <= 3 and abs(o[0][1] - o[1][1]) < 1.0):
            fail(f"Ohringer not nearly EW: {o}")
    w = [(float(x), float(y)) for x, y in by["Winterthurerstrasse"]["points"]]
    s = [(float(x), float(y)) for x, y in by["Stationsstrasse"]["points"]]
    shared = set(w) & set(s)
    if not shared:
        fail("Winter/Stations share no hub vertex")
    hub = next(iter(shared))
    # Winter turn at hub < 150°
    for i in range(1, len(w) - 1):
        if g.dist(w[i], hub) < 1.0:
            td = g.turn_deg(w[i - 1], w[i], w[i + 1])
            if td >= g.REVERSE_FOLD_DEG:
                fail(f"Winter reverse at hub: {td:.0f}° {w[i-1]}-{w[i]}-{w[i+1]}")
    overlap = g.coincident_edge_length(s, w)
    if overlap > g.LATTICE * 2:
        fail(f"Stations still double-traces Winter for {overlap:.0f} wu")
    folds = 0
    for r in data["roads"]:
        if str(r["name"]).startswith("link-"):
            continue
        pts = [(float(x), float(y)) for x, y in r["points"]]
        for i in range(1, len(pts) - 1):
            if g.turn_deg(pts[i - 1], pts[i], pts[i + 1]) >= g.REVERSE_FOLD_DEG:
                folds += 1
    if folds:
        fail(f"named reverse folds still {folds}")
    ok("artifact hub/REQUIRED/Ohringer/no double-trace")


def main() -> None:
    print("=== octilinear_junction_corner_test start ===")
    if not SCRIPT.is_file():
        fail(f"missing {SCRIPT}")
    g = _load()
    test_snap_max_distance(g)
    test_interior_snap_budget(g)
    test_hub_no_uturn(g)
    test_clean_corners(g)
    test_prune_coincident_overlap(g)
    test_artifact_hub_metrics(g)
    print("=== octilinear_junction_corner_test passed ===")


if __name__ == "__main__":
    main()
