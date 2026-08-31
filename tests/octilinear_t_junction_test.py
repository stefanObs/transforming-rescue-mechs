#!/usr/bin/env python3
"""S08 regression: T-junction attach, overshoot trim, orphan links (pure Python)."""
from __future__ import annotations

import importlib.util
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


def test_octilinear_intersect(g) -> None:
    hit = g.octilinear_seg_intersect(
        (0.0, 0.0), (800.0, 0.0), (400.0, -400.0), (400.0, 400.0)
    )
    if hit is None or abs(hit[0] - 400.0) > 1.0 or abs(hit[1]) > 1.0:
        fail(f"H/V intersect expected (400,0) got {hit}")
    ok("octilinear_seg_intersect H×V")


def test_attach_interior_t(g) -> None:
    """Side endpoint on host interior → shared vertex after attach."""
    main = {
        "name": "MainStrasse",
        "class": "main",
        "points": [[0.0, 0.0], [4000.0, 0.0], [8000.0, 0.0]],
    }
    side = {
        "name": "SideGasse",
        "class": "local",
        "points": [[2000.0, 2000.0], [2000.0, 400.0]],
    }
    out = g.attach_t_junctions([main, side])
    by = {r["name"]: [(float(x), float(y)) for x, y in r["points"]] for r in out}
    m, s = by["MainStrasse"], by["SideGasse"]
    end = s[-1]
    if not any(g.dist(end, p) < 1.0 for p in m):
        fail(f"side end {end} not on main {m}")
    shared = g._shared_junction_keys(out)
    if g.point_key(end) not in shared:
        fail(f"T hub not shared: end={end} shared={shared}")
    ok("attach_t_junctions interior T")


def test_attach_no_reverse_fold(g) -> None:
    main = {
        "name": "Through",
        "class": "main",
        "points": [[0.0, 0.0], [6000.0, 0.0], [6000.0, 4000.0]],
    }
    side = {
        "name": "Stub",
        "class": "local",
        "points": [[3000.0, 2000.0], [3000.0, 600.0]],
    }
    out = g.attach_t_junctions([main, side])
    by = {r["name"]: [(float(x), float(y)) for x, y in r["points"]] for r in out}
    m = by["Through"]
    for i in range(1, len(m) - 1):
        td = g.turn_deg(m[i - 1], m[i], m[i + 1])
        if td >= g.REVERSE_FOLD_DEG:
            fail(f"reverse fold on host after attach: {m}")
    ok("attach_t_junctions no host reverse fold")


def test_trim_overshoot(g) -> None:
    main = {
        "name": "Host",
        "class": "main",
        "points": [[0.0, 0.0], [4000.0, 0.0]],
    }
    # Side overshoots past intersection at (2000,0).
    side = {
        "name": "Side",
        "class": "local",
        "points": [[2000.0, 2000.0], [2000.0, -400.0]],
    }
    out = g.trim_endpoint_overshoot([main, side])
    by = {r["name"]: [(float(x), float(y)) for x, y in r["points"]] for r in out}
    end = by["Side"][-1]
    if abs(end[0] - 2000.0) > 1.0 or abs(end[1]) > 1.0:
        fail(f"trim expected (2000,0) got {end}")
    ok("trim_endpoint_overshoot")


def test_prune_orphan_link(g) -> None:
    a = {
        "name": "Alpha",
        "class": "local",
        "points": [[0.0, 0.0], [2000.0, 0.0]],
    }
    b = {
        "name": "Beta",
        "class": "local",
        "points": [[2000.0, 0.0], [4000.0, 0.0]],
    }
    link = {
        "name": "link-99",
        "class": "local",
        "points": [[0.0, 0.0], [2000.0, 0.0]],
    }
    out = g.prune_orphan_links([a, b, link])
    names = {r["name"] for r in out}
    if "link-99" in names:
        fail("orphan link should be pruned when both ends are shared hubs")
    ok("prune_orphan_links drops redundant link-*")


def test_artifact_t_miss_and_links(g) -> None:
    import json

    path = ROOT / "data" / "seuzach_roads_octilinear.json"
    if not path.is_file():
        fail(f"missing {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    roads = data["roads"]
    n = g.count_t_miss(roads)
    if n:
        fail(f"committed JSON still has {n} interior T-misses")
    links = [r for r in roads if str(r["name"]).startswith("link-")]
    if links:
        fail(f"link-* stubs remain after S08: {[r['name'] for r in links]}")
    near = g.count_near_parallel_pairs(roads, lo=80.0, hi=400.0)
    if near > 1:
        fail(f"near-parallel 80-400 wu regressed to {near}")
    ok(f"artifact t_miss=0 links={len(links)} near_parallel_80-400={near}")


def main() -> None:
    print("=== octilinear_t_junction_test start ===")
    if not SCRIPT.is_file():
        fail(f"missing {SCRIPT}")
    g = _load()
    test_octilinear_intersect(g)
    test_attach_interior_t(g)
    test_attach_no_reverse_fold(g)
    test_trim_overshoot(g)
    test_prune_orphan_link(g)
    test_artifact_t_miss_and_links(g)
    print("=== octilinear_t_junction_test passed ===")


if __name__ == "__main__":
    main()
