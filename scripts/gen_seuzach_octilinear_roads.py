#!/usr/bin/env python3
"""Road trace → octilinear seuzach_roads JSON + big SVG.

Input (preferred):  data/seuzach_roads_swiss_trace.json
Fallback:           data/seuzach_roads_gmaps_trace.json
Output: data/seuzach_roads_octilinear.json
        docs/maps/seuzach_octilinear_roads.svg

Uses the same Kirche origin / FIELD / CLIP as gen_seuzach_roads.py so the
result matches the playable world extent. Does not read seuzach_roads.json.
Does not switch world_sandbox.
"""

from __future__ import annotations

import json
import math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC_SWISS = ROOT / "data" / "seuzach_roads_swiss_trace.json"
SRC_FALLBACK = ROOT / "data" / "seuzach_roads_gmaps_trace.json"
OUT_JSON = ROOT / "data" / "seuzach_roads_octilinear.json"
OUT_SVG = ROOT / "docs" / "maps" / "seuzach_octilinear_roads.svg"

CHURCH_LAT = 47.5335012
CHURCH_LON = 8.7261235
FIELD_M = 5.3
FIELD_WU = 100.0
UPM = FIELD_WU / FIELD_M
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(CHURCH_LAT))

CLIP = (-25000.0, -24000.0, 32000.0, 18000.0)
LATTICE = 200.0
JUNCTION_SNAP = 400.0
CONNECT_NEAR = 2000.0  # endpoint↔any snap (S06: tighter than old 3000)
CONNECT_INTERIOR = JUNCTION_SNAP * 2  # interior↔interior only (~800 wu)
CONNECT_MAIN = 5000.0  # component bridges may span farther
MIN_SEG_WU = 120.0
MIN_CORNER_SEG_WU = 250.0  # clean_corners micro-segment threshold
REVERSE_FOLD_DEG = 150.0  # turn ≥ this at a vertex = reverse fold / U-turn
ANGLE_EPS_DEG = 0.75
COLINEAR_DEG = 5.0  # turn below this → colinear merge candidate
STAIR_FLAT_DEG = 135.0  # single zig flatten when shortcut is octilinear
STAIR_FLAT_SLACK = LATTICE * 2  # max chord deviation for stair flatten

# S07 — near-parallel corridor spacing
PARALLEL_LONG_SEG = 400.0  # only consider segments at least this long
PARALLEL_BEARING_DEG = 15.0  # similar bearing (or reverse)
PARALLEL_TOO_CLOSE = 500.0  # mid-distance upper bound for "too close"
PARALLEL_ABSORB = 250.0  # below this → absorb artifact doubles
PARALLEL_MIN_GAP = 600.0  # target mid-distance after separate
PARALLEL_OVERLAP = 800.0  # min longitudinal overlap along shared bearing
PARALLEL_SUBSET_FRAC = 0.72  # weaker mostly projects onto stronger → absorb
CLASS_RANK = {"motorway": 4, "main": 3, "collector": 2, "local": 1}

# Landmark dots for SVG (lat, lon) — same GPS as seuzach_geo.gd
LANDMARKS = {
    "Kirche": (47.5335012, 8.7261235),
    "Bahnhof": (47.5357159, 8.7388969),
    "Ohringen": (47.5280584, 8.7121325),
    "Forrenberg": (47.5263004, 8.7353138),
    "Badi": (47.5393193, 8.7333710),
    "Birch": (47.5353419, 8.7362524),
}

STROKE = {
    "motorway": ("#2a2a2a", 220.0),
    "main": ("#444444", 140.0),
    "collector": ("#666666", 100.0),
    "local": ("#888888", 70.0),
}

REQUIRED_MAINS = {
    "Winterthurerstrasse",
    "Stationsstrasse",
    "Ohringerstrasse",
    "A1",
}

# Never offset these as the moving road if the other of a parallel pair can move.
PARALLEL_PINNED = frozenset(REQUIRED_MAINS)

# Long corridors that should stay nearly axis-aligned (high RDP, protect interiors).
STRAIGHT_CORRIDORS = {
    # Gentle E–W: enough RDP to kill staircases, not so much it invents a SW diagonal.
    "Ohringerstrasse": {"rdp_cells": 4.0, "axis": "ew", "line_slack_wu": 800.0},
}

# Named pairs that must share a vertex after connect (correct street meets correct street).
REQUIRED_JUNCTIONS = [
    ("Winterthurerstrasse", "Stationsstrasse"),
    ("Winterthurerstrasse", "Ohringerstrasse"),
    ("Winterthurerstrasse", "Kirchgasse"),
    ("Winterthurerstrasse", "Breitestrasse"),
    ("Schaffhauserstrasse", "Schulstrasse"),
    ("Stationsstrasse", "Birchstrasse"),
]


def gps_to_world(lat: float, lon: float) -> tuple[float, float]:
    x = (lon - CHURCH_LON) * M_LON * UPM
    y = (CHURCH_LAT - lat) * M_LAT * UPM
    return x, y


def dist(a, b) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def snap_lattice(p: tuple[float, float], cell: float = LATTICE) -> tuple[float, float]:
    return (round(p[0] / cell) * cell, round(p[1] / cell) * cell)


def bearing_deg(a, b) -> float:
    return math.degrees(math.atan2(b[1] - a[1], b[0] - a[0])) % 360.0


def nearest_octilinear(deg: float) -> float:
    return round(deg / 45.0) * 45.0 % 360.0


def dir_vec(deg: float) -> tuple[float, float]:
    r = math.radians(deg)
    return math.cos(r), math.sin(r)


def turn_deg(a: tuple[float, float], b: tuple[float, float], c: tuple[float, float]) -> float:
    """Direction-change at b for path a→b→c, in [0, 180]. 0=straight, 180=reverse."""
    if dist(a, b) < 1.0 or dist(b, c) < 1.0:
        return 0.0
    d = abs((bearing_deg(b, c) - bearing_deg(a, b) + 180.0) % 360.0 - 180.0)
    return d


def is_octilinear_seg(a: tuple[float, float], b: tuple[float, float]) -> bool:
    if dist(a, b) < 1.0:
        return True
    dx, dy = b[0] - a[0], b[1] - a[1]
    return abs(dx) < 1e-6 or abs(dy) < 1e-6 or abs(abs(dx) - abs(dy)) < 1e-6


def project_onto_segment(
    p: tuple[float, float], a: tuple[float, float], b: tuple[float, float]
) -> tuple[tuple[float, float], float]:
    """Project p onto segment a→b. Returns (point, t in [0,1])."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    len2 = dx * dx + dy * dy
    if len2 < 1e-12:
        return a, 0.0
    t = ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / len2
    t = max(0.0, min(1.0, t))
    return (a[0] + t * dx, a[1] + t * dy), t


def point_key(p: tuple[float, float]) -> tuple[float, float]:
    return snap_lattice(p)


def snap_max_distance(
    pi: int, n_i: int, pj: int, n_j: int, *, allow_interior: bool = True
) -> float:
    """Endpoint-first snap budget (S06). Interior↔interior << CONNECT_NEAR."""
    end_i = pi in (0, n_i - 1)
    end_j = pj in (0, n_j - 1)
    if end_i or end_j:
        return CONNECT_NEAR
    if not allow_interior:
        return -1.0
    return CONNECT_INTERIOR


def octilinear_leg(
    a: tuple[float, float],
    b: tuple[float, float],
    *,
    prefer_axis: str | None = None,
) -> list[tuple[float, float]]:
    """Connect a→b with one or two octilinear segments (H/V/45°)."""
    a = snap_lattice(a)
    b = snap_lattice(b)
    if dist(a, b) < 1.0:
        return [a]

    dx = b[0] - a[0]
    dy = b[1] - a[1]

    # Exact axis or exact 45°
    if abs(dx) < 1e-6 or abs(dy) < 1e-6 or abs(abs(dx) - abs(dy)) < 1e-6:
        return [a, b]

    candidates: list[list[tuple[float, float]]] = []
    # H then V / V then H
    candidates.append([a, snap_lattice((b[0], a[1])), b])
    candidates.append([a, snap_lattice((a[0], b[1])), b])
    # 45° then axis finish
    s = math.copysign(min(abs(dx), abs(dy)), dx)
    t = math.copysign(abs(s), dy)
    m1 = snap_lattice((a[0] + s, a[1] + t))
    candidates.append([a, m1, b])
    if abs(dx) > abs(dy):
        m2 = snap_lattice((a[0] + math.copysign(abs(dx) - abs(dy), dx), a[1]))
        candidates.append([a, m2, b])
    else:
        m2 = snap_lattice((a[0], a[1] + math.copysign(abs(dy) - abs(dx), dy)))
        candidates.append([a, m2, b])

    def path_ok(path: list[tuple[float, float]]) -> bool:
        for i in range(len(path) - 1):
            if dist(path[i], path[i + 1]) < 1.0:
                continue
            pdx = path[i + 1][0] - path[i][0]
            pdy = path[i + 1][1] - path[i][1]
            if abs(pdx) < 1e-6 or abs(pdy) < 1e-6 or abs(abs(pdx) - abs(pdy)) < 1e-6:
                continue
            return False
        return True

    def path_err(path: list[tuple[float, float]]) -> float:
        length = sum(dist(path[i], path[i + 1]) for i in range(len(path) - 1))
        e = length + 40.0 * (len(path) - 2)
        if prefer_axis in ("ew", "ns"):
            # Penalize long 45° legs on corridors that should stay axis-dominant.
            for i in range(len(path) - 1):
                pdx = abs(path[i + 1][0] - path[i][0])
                pdy = abs(path[i + 1][1] - path[i][1])
                if abs(pdx - pdy) < 1e-6 and max(pdx, pdy) > LATTICE * 4:
                    e += max(pdx, pdy) * 0.35
        return e

    best = None
    best_e = 1e18
    for cand in candidates:
        clean = [cand[0]]
        for p in cand[1:]:
            if dist(clean[-1], p) >= 1.0:
                clean.append(p)
        if len(clean) < 2 or not path_ok(clean):
            continue
        e = path_err(clean)
        if e < best_e:
            best_e = e
            best = clean
    if best is None:
        mid = snap_lattice((b[0], a[1]))
        best = [a, mid, b] if dist(a, mid) >= 1.0 and dist(mid, b) >= 1.0 else [a, b]
        # last resort axis path must still be octilinear
        if not path_ok(best):
            mid = snap_lattice((a[0], b[1]))
            best = [a, mid, b]
    return best


def rdp(points: list[tuple[float, float]], epsilon: float) -> list[tuple[float, float]]:
    if len(points) < 3:
        return points
    start, end = points[0], points[-1]
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    den = math.hypot(dx, dy) or 1.0
    max_d = -1.0
    idx = 0
    for i in range(1, len(points) - 1):
        p = points[i]
        d = abs(dx * (start[1] - p[1]) - dy * (start[0] - p[0])) / den
        if d > max_d:
            max_d = d
            idx = i
    if max_d > epsilon:
        left = rdp(points[: idx + 1], epsilon)
        right = rdp(points[idx:], epsilon)
        return left[:-1] + right
    return [start, end]


def octilinearize_polyline(
    pts: list[tuple[float, float]],
    *,
    rdp_cells: float = 2.5,
    prefer_axis: str | None = None,
    line_slack_wu: float | None = None,
) -> list[tuple[float, float]]:
    if len(pts) < 2:
        return [snap_lattice(p) for p in pts]
    snapped = [snap_lattice(p) for p in pts]
    clean = [snapped[0]]
    for p in snapped[1:]:
        if dist(clean[-1], p) >= LATTICE * 0.5:
            clean.append(p)
    if len(clean) < 2:
        return clean
    if line_slack_wu is not None and len(clean) >= 3:
        # Drop outliers far from the start→end chord so RDP cannot invent big detours.
        a, b = clean[0], clean[-1]
        dx, dy = b[0] - a[0], b[1] - a[1]
        den = math.hypot(dx, dy) or 1.0
        kept = [a]
        for p in clean[1:-1]:
            d = abs(dx * (a[1] - p[1]) - dy * (a[0] - p[0])) / den
            if d <= line_slack_wu:
                kept.append(p)
        kept.append(b)
        clean = kept if len(kept) >= 2 else [a, b]
    # Aggressive simplify so long corridors become few long octilinear legs (not staircases).
    clean = rdp(clean, LATTICE * rdp_cells)
    clean = [snap_lattice(p) for p in clean]

    out: list[tuple[float, float]] = [clean[0]]
    for i in range(len(clean) - 1):
        leg = octilinear_leg(out[-1], clean[i + 1], prefer_axis=prefer_axis)
        for p in leg[1:]:
            if dist(out[-1], p) >= MIN_SEG_WU * 0.5:
                out.append(p)
            elif dist(out[-1], p) >= 1.0 and i == len(clean) - 2:
                out.append(p)
    if len(out) < 2:
        return clean
    return out

def clip_point(p, clip=CLIP) -> bool:
    return clip[0] <= p[0] <= clip[2] and clip[1] <= p[1] <= clip[3]


def clip_polyline(pts: list[tuple[float, float]]) -> list[tuple[float, float]]:
    """Keep contiguous in-CLIP run (simple filter + endpoint clamp)."""
    if not pts:
        return []
    kept = [p for p in pts if clip_point(p)]
    if len(kept) >= 2:
        return kept
    # If endpoints outside but middle crosses, keep snapped endpoints inside via clamp
    clamped = [
        (
            min(max(p[0], CLIP[0]), CLIP[2]),
            min(max(p[1], CLIP[1]), CLIP[3]),
        )
        for p in pts
    ]
    clean = [clamped[0]]
    for p in clamped[1:]:
        if dist(clean[-1], p) >= 1.0:
            clean.append(p)
    return clean if len(clean) >= 2 else []


def validate_octilinear(roads: list[dict]) -> None:
    bad = []
    for r in roads:
        pts = r["points"]
        for i in range(len(pts) - 1):
            a, b = pts[i], pts[i + 1]
            if dist(a, b) < 1e-3:
                bad.append((r["name"], "zero-length", a, b))
                continue
            ang = bearing_deg(a, b)
            snapped = nearest_octilinear(ang)
            delta = abs((ang - snapped + 180) % 360 - 180)
            if delta > ANGLE_EPS_DEG:
                bad.append((r["name"], f"angle {ang:.2f}", a, b))
    if bad:
        sample = bad[:8]
        raise SystemExit(f"octilinear validation failed ({len(bad)} segs): {sample}")


def _dedupe_polyline(pts: list[tuple[float, float]]) -> list[tuple[float, float]]:
    if not pts:
        return pts
    out = [pts[0]]
    for p in pts[1:]:
        if dist(out[-1], p) >= 1.0:
            out.append(p)
    return out


def connect_network(roads: list[dict]) -> list[dict]:
    """Snap near vertices to shared junctions; add short octilinear stubs for near-misses."""
    # Mutable point lists
    polys: list[list[tuple[float, float]]] = [
        [(float(x), float(y)) for x, y in r["points"]] for r in roads
    ]
    names = [r["name"] for r in roads]
    protected = {i for i, n in enumerate(names) if n in STRAIGHT_CORRIDORS}

    def is_interior(ri: int, pi: int) -> bool:
        return ri in protected and 0 < pi < len(polys[ri]) - 1

    # --- Pass 1: cluster all vertices within JUNCTION_SNAP, snap clusters ---
    verts: list[tuple[int, int, tuple[float, float]]] = []
    for ri, pts in enumerate(polys):
        for pi, p in enumerate(pts):
            verts.append((ri, pi, p))

    parent = list(range(len(verts)))

    def find(i: int) -> int:
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    def union(i: int, j: int) -> None:
        ri, rj = find(i), find(j)
        if ri != rj:
            parent[rj] = ri

    for i in range(len(verts)):
        for j in range(i + 1, len(verts)):
            if verts[i][0] == verts[j][0]:
                continue
            # Do not let side streets yank midpoints of protected straight corridors.
            if is_interior(verts[i][0], verts[i][1]) or is_interior(verts[j][0], verts[j][1]):
                continue
            if dist(verts[i][2], verts[j][2]) <= JUNCTION_SNAP:
                union(i, j)

    clusters: dict[int, list[int]] = defaultdict(list)
    for i in range(len(verts)):
        clusters[find(i)].append(i)

    for members in clusters.values():
        roads_in = {verts[i][0] for i in members}
        if len(roads_in) < 2 and len(members) < 2:
            continue
        if len(roads_in) < 2:
            continue
        cx = sum(verts[i][2][0] for i in members) / len(members)
        cy = sum(verts[i][2][1] for i in members) / len(members)
        jp = snap_lattice((cx, cy))
        for i in members:
            ri, pi, _ = verts[i]
            if is_interior(ri, pi):
                continue
            polys[ri][pi] = jp

    for ri in range(len(polys)):
        polys[ri] = _dedupe_polyline(polys[ri])

    # --- Pass 2: snap near-miss vertices (endpoint-first; skip protected interiors) ---
    n = len(polys)
    class_of = [roads[i]["class"] for i in range(n)]
    for i in range(n):
        if len(polys[i]) < 2:
            continue
        for j in range(i + 1, n):
            if len(polys[j]) < 2:
                continue
            best = 1e18
            bi = bj = 0
            for pi, p in enumerate(polys[i]):
                if is_interior(i, pi):
                    continue
                for pj, q in enumerate(polys[j]):
                    if is_interior(j, pj):
                        continue
                    max_d = snap_max_distance(pi, len(polys[i]), pj, len(polys[j]))
                    if max_d < 0:
                        continue
                    d = dist(p, q)
                    if d > max_d:
                        continue
                    if d < best:
                        best = d
                        bi, bj = pi, pj
            if best < 1.0 or best >= 1e17:
                continue
            mid = snap_lattice(
                (
                    (polys[i][bi][0] + polys[j][bj][0]) * 0.5,
                    (polys[i][bi][1] + polys[j][bj][1]) * 0.5,
                )
            )
            polys[i][bi] = mid
            polys[j][bj] = mid

    for ri in range(len(polys)):
        polys[ri] = _dedupe_polyline(polys[ri])

    # Re-octilinearize after snaps so mid-vertex moves don't create illegal angles.
    for ri in range(len(polys)):
        if len(polys[ri]) < 2:
            continue
        prefer = STRAIGHT_CORRIDORS.get(names[ri], {}).get("axis")
        rebuilt: list[tuple[float, float]] = [snap_lattice(polys[ri][0])]
        for p in polys[ri][1:]:
            leg = octilinear_leg(rebuilt[-1], snap_lattice(p), prefer_axis=prefer)
            for q in leg[1:]:
                if dist(rebuilt[-1], q) >= 1.0:
                    rebuilt.append(q)
        polys[ri] = _dedupe_polyline(rebuilt)

    # --- Pass 3: bridge remaining components with few octilinear stubs ---
    connectors: list[dict] = []

    def road_keys(pts: list[tuple[float, float]]) -> set[tuple[int, int]]:
        cell = JUNCTION_SNAP
        return {(int(round(p[0] / cell)), int(round(p[1] / cell))) for p in pts}

    def components_of(poly_list: list[list[tuple[float, float]]]) -> dict[int, list[int]]:
        parent: dict[tuple[int, int], tuple[int, int]] = {}

        def find(a):
            parent.setdefault(a, a)
            while parent[a] != a:
                parent[a] = parent[parent[a]]
                a = parent[a]
            return a

        def union(a, b):
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[rb] = ra

        for pts in poly_list:
            if len(pts) < 2:
                continue
            keys = list(road_keys(pts))
            for i in range(len(pts) - 1):
                ka = (int(round(pts[i][0] / JUNCTION_SNAP)), int(round(pts[i][1] / JUNCTION_SNAP)))
                kb = (
                    int(round(pts[i + 1][0] / JUNCTION_SNAP)),
                    int(round(pts[i + 1][1] / JUNCTION_SNAP)),
                )
                union(ka, kb)
            for a in keys:
                for b in keys:
                    if abs(a[0] - b[0]) <= 1 and abs(a[1] - b[1]) <= 1:
                        union(a, b)
        # map road index -> component root
        road_comp: dict[int, tuple[int, int]] = {}
        for ri, pts in enumerate(poly_list):
            if len(pts) < 2:
                continue
            k0 = (int(round(pts[0][0] / JUNCTION_SNAP)), int(round(pts[0][1] / JUNCTION_SNAP)))
            road_comp[ri] = find(k0)
        comps: dict[tuple[int, int], list[int]] = defaultdict(list)
        for ri, root in road_comp.items():
            comps[root].append(ri)
        # reindex
        return {i: members for i, members in enumerate(comps.values())}

    link_id = 0
    for _ in range(12):  # at most a handful of bridges
        comps = components_of(polys)
        if len(comps) <= 1:
            break
        # Find closest pair of roads in different components (prefer important classes)
        best = None
        items = list(comps.items())
        for ci, members_i in items:
            for cj, members_j in items:
                if cj <= ci:
                    continue
                for i in members_i:
                    for j in members_j:
                        for pi, p in enumerate(polys[i]):
                            for pj, q in enumerate(polys[j]):
                                d = dist(p, q)
                                if d > CONNECT_MAIN:
                                    continue
                                important = class_of[i] in (
                                    "motorway",
                                    "main",
                                    "collector",
                                ) or class_of[j] in ("motorway", "main", "collector")
                                score = d - (800.0 if important else 0.0)
                                if best is None or score < best[0]:
                                    best = (score, d, i, j, pi, pj)
        if best is None:
            break
        _, d, i, j, bi, bj = best
        a, b = polys[i][bi], polys[j][bj]
        if d <= JUNCTION_SNAP:
            mid = snap_lattice(((a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5))
            polys[i][bi] = mid
            polys[j][bj] = mid
        else:
            leg = _dedupe_polyline(octilinear_leg(a, b))
            if len(leg) < 2:
                break
            polys[i][bi] = leg[0]
            polys[j][bj] = leg[-1]
            link_id += 1
            connectors.append(
                {
                    "name": f"link-{link_id}",
                    "class": "local",
                    "points": [[round(x, 1), round(y, 1)] for x, y in leg],
                }
            )
            # include connector geometry in component analysis only
            polys.append([(float(x), float(y)) for x, y in leg])
            class_of.append("local")

    # Final re-octilinearize of original roads after bridging snaps
    n_orig = len(roads)
    for ri in range(n_orig):
        if len(polys[ri]) < 2:
            continue
        prefer = STRAIGHT_CORRIDORS.get(names[ri], {}).get("axis")
        rebuilt = [snap_lattice(polys[ri][0])]
        for p in polys[ri][1:]:
            leg = octilinear_leg(rebuilt[-1], snap_lattice(p), prefer_axis=prefer)
            for q in leg[1:]:
                if dist(rebuilt[-1], q) >= 1.0:
                    rebuilt.append(q)
        polys[ri] = _dedupe_polyline(rebuilt)

    out: list[dict] = []
    for ri in range(n_orig):
        r = roads[ri]
        pts = polys[ri]
        if len(pts) < 2:
            continue
        length = sum(dist(pts[k], pts[k + 1]) for k in range(len(pts) - 1))
        if length < MIN_SEG_WU:
            continue
        out.append(
            {
                "name": r["name"],
                "class": r["class"],
                "points": [[round(x, 1), round(y, 1)] for x, y in pts],
            }
        )
    # Re-octilinearize connector stubs too
    fixed_connectors = []
    for c in connectors:
        pts = [(float(x), float(y)) for x, y in c["points"]]
        rebuilt = [snap_lattice(pts[0])]
        for p in pts[1:]:
            leg = octilinear_leg(rebuilt[-1], snap_lattice(p))
            for q in leg[1:]:
                if dist(rebuilt[-1], q) >= 1.0:
                    rebuilt.append(q)
        rebuilt = _dedupe_polyline(rebuilt)
        if len(rebuilt) < 2:
            continue
        fixed_connectors.append(
            {
                "name": c["name"],
                "class": c["class"],
                "points": [[round(x, 1), round(y, 1)] for x, y in rebuilt],
            }
        )
    out.extend(fixed_connectors)

    # Preserve shared junctions: snap near verts again, then repair only illegal legs
    # (full re-octilinearize earlier can pull mains apart again).
    polys2 = [[(float(x), float(y)) for x, y in r["points"]] for r in out]
    out_names = [r["name"] for r in out]

    def is_interior_out(ri: int, pi: int) -> bool:
        return out_names[ri] in STRAIGHT_CORRIDORS and 0 < pi < len(polys2[ri]) - 1

    for i in range(len(polys2)):
        for j in range(i + 1, len(polys2)):
            best = 1e18
            bi = bj = 0
            for pi, p in enumerate(polys2[i]):
                if is_interior_out(i, pi):
                    continue
                for pj, q in enumerate(polys2[j]):
                    if is_interior_out(j, pj):
                        continue
                    max_d = snap_max_distance(pi, len(polys2[i]), pj, len(polys2[j]))
                    if max_d < 0:
                        continue
                    d = dist(p, q)
                    if d > max_d:
                        continue
                    if d < best:
                        best, bi, bj = d, pi, pj
            if 1.0 < best < 1e17:
                mid = snap_lattice(
                    (
                        (polys2[i][bi][0] + polys2[j][bj][0]) * 0.5,
                        (polys2[i][bi][1] + polys2[j][bj][1]) * 0.5,
                    )
                )
                polys2[i][bi] = mid
                polys2[j][bj] = mid

    def repair(pts: list[tuple[float, float]], prefer_axis: str | None = None) -> list[tuple[float, float]]:
        if len(pts) < 2:
            return pts
        rebuilt = [snap_lattice(pts[0])]
        for p in pts[1:]:
            target = snap_lattice(p)
            pdx = target[0] - rebuilt[-1][0]
            pdy = target[1] - rebuilt[-1][1]
            ok = (
                dist(rebuilt[-1], target) < 1.0
                or abs(pdx) < 1e-6
                or abs(pdy) < 1e-6
                or abs(abs(pdx) - abs(pdy)) < 1e-6
            )
            if ok:
                if dist(rebuilt[-1], target) >= 1.0:
                    rebuilt.append(target)
            else:
                for q in octilinear_leg(rebuilt[-1], target, prefer_axis=prefer_axis)[1:]:
                    if dist(rebuilt[-1], q) >= 1.0:
                        rebuilt.append(q)
        return _dedupe_polyline(rebuilt)

    final = []
    for ri, r in enumerate(out):
        prefer = STRAIGHT_CORRIDORS.get(r["name"], {}).get("axis")
        pts = repair(polys2[ri], prefer_axis=prefer)
        if len(pts) < 2:
            continue
        length = sum(dist(pts[k], pts[k + 1]) for k in range(len(pts) - 1))
        if length < MIN_SEG_WU and not str(r["name"]).startswith("link-"):
            continue
        final.append(
            {
                "name": r["name"],
                "class": r["class"],
                "points": [[round(x, 1), round(y, 1)] for x, y in pts],
            }
        )
    return final


def _nearest_on_polyline(
    pts: list[tuple[float, float]], p: tuple[float, float]
) -> tuple[str, int, tuple[float, float]]:
    """Locate p on polyline: ('vertex', idx, pt) or ('insert', idx, pt).

    Prefer an existing vertex within JUNCTION_SNAP of the closest projection;
    otherwise insert a lattice-snapped projection onto the nearest segment.
    """
    best_v_i = min(range(len(pts)), key=lambda i: dist(pts[i], p))
    best_v_d = dist(pts[best_v_i], p)

    best_seg: tuple[float, int, tuple[float, float]] | None = None
    for i in range(len(pts) - 1):
        proj, t = project_onto_segment(p, pts[i], pts[i + 1])
        d = dist(p, proj)
        if best_seg is None or d < best_seg[0]:
            best_seg = (d, i, snap_lattice(proj))

    if best_seg is None:
        return "vertex", best_v_i, pts[best_v_i]

    seg_d, seg_i, proj = best_seg
    # Prefer existing vertex when close to projection or to the query point.
    if best_v_d <= JUNCTION_SNAP or best_v_d <= seg_d + 1.0:
        return "vertex", best_v_i, pts[best_v_i]
    if dist(proj, pts[seg_i]) <= JUNCTION_SNAP:
        return "vertex", seg_i, pts[seg_i]
    if dist(proj, pts[seg_i + 1]) <= JUNCTION_SNAP:
        return "vertex", seg_i + 1, pts[seg_i + 1]
    if seg_d + 50.0 < best_v_d:
        return "insert", seg_i + 1, proj
    return "vertex", best_v_i, pts[best_v_i]


def _hub_turn_ok(pts: list[tuple[float, float]], idx: int) -> bool:
    if idx <= 0 or idx >= len(pts) - 1:
        return True
    return turn_deg(pts[idx - 1], pts[idx], pts[idx + 1]) < REVERSE_FOLD_DEG


def _fix_reverse_at(
    pts: list[tuple[float, float]], idx: int
) -> list[tuple[float, float]]:
    """If pts[idx] is a reverse fold, drop it (endpoints kept) or flatten via chord."""
    if idx <= 0 or idx >= len(pts) - 1:
        return pts
    if turn_deg(pts[idx - 1], pts[idx], pts[idx + 1]) < REVERSE_FOLD_DEG:
        return pts
    # Drop the spike vertex; reconnect with octilinear legs.
    left, right = pts[idx - 1], pts[idx + 1]
    mid = snap_lattice(((left[0] + right[0]) * 0.5, (left[1] + right[1]) * 0.5))
    rebuilt = list(pts[: idx - 1])
    rebuilt.extend(octilinear_leg(left, mid))
    rebuilt.extend(octilinear_leg(mid, right)[1:])
    rebuilt.extend(pts[idx + 2 :])
    return _dedupe_polyline(rebuilt)


def point_on_polyline(
    p: tuple[float, float], pts: list[tuple[float, float]], eps: float = LATTICE * 0.6
) -> bool:
    if any(dist(p, q) <= eps for q in pts):
        return True
    for i in range(len(pts) - 1):
        proj, t = project_onto_segment(p, pts[i], pts[i + 1])
        if 0.0 <= t <= 1.0 and dist(p, proj) <= eps:
            return True
    return False


def coincident_edge_length(
    a: list[tuple[float, float]], b: list[tuple[float, float]], eps: float = LATTICE * 0.6
) -> float:
    """Sum of segment lengths of A that lie on B's polyline (double-trace measure)."""
    total = 0.0
    for i in range(len(a) - 1):
        p, q = a[i], a[i + 1]
        if point_on_polyline(p, b, eps) and point_on_polyline(q, b, eps):
            # Also require the midpoint on B so short chords across corners don't count.
            mid = ((p[0] + q[0]) * 0.5, (p[1] + q[1]) * 0.5)
            if point_on_polyline(mid, b, eps):
                total += dist(p, q)
    return total


def prune_coincident_overlap(
    side: list[tuple[float, float]],
    through: list[tuple[float, float]],
    *,
    prefer: str | None = None,
) -> list[tuple[float, float]]:
    """Keep a single meet with `through`; drop side vertices that ride along it.

    Prevents Stations (etc.) from double-tracing Winter for thousands of wu.
    Contiguous on-through runs collapse to one vertex (prefer road-end meets).
    """
    if len(side) < 2 or len(through) < 2:
        return side
    if coincident_edge_length(side, through) < LATTICE * 1.5:
        return side

    on = [point_on_polyline(p, through) for p in side]
    if not any(on):
        return side

    kept: list[tuple[float, float]] = []
    n = len(side)
    i = 0
    while i < n:
        if not on[i]:
            kept.append(side[i])
            i += 1
            continue
        j = i
        while j < n and on[j]:
            j += 1
        run = side[i:j]
        if i == 0:
            keep = run[0]
        elif j == n:
            keep = run[-1]
        else:
            # Interior overlap: keep the end adjacent to the longer off-through remainder.
            keep = run[-1] if (n - j) >= i else run[0]
        if not kept or dist(kept[-1], keep) >= 1.0:
            kept.append(keep)
        i = j

    if len(kept) < 2:
        return side
    rebuilt: list[tuple[float, float]] = [kept[0]]
    for p in kept[1:]:
        rebuilt.extend(octilinear_leg(rebuilt[-1], p, prefer_axis=prefer)[1:])
    rebuilt = _dedupe_polyline(rebuilt)
    if len(rebuilt) < 2:
        return side
    # Safety: if we somehow lost all meets, keep original.
    if not any(point_on_polyline(p, through) for p in rebuilt):
        return side
    return rebuilt


def force_required_junctions(roads: list[dict]) -> list[dict]:
    """Ensure named corridors share a vertex where the Swiss plan expects them to meet.

    Multi-pass so fixing Ohringer↔Winter does not permanently break Winter↔Stations.
    Triple-hub attaches side streets onto Winter without yanking Winter sideways (S06).
    """
    by_idx = {r["name"]: i for i, r in enumerate(roads)}
    polys = [[(float(x), float(y)) for x, y in r["points"]] for r in roads]

    def pair_gap(a_name: str, b_name: str) -> float:
        if a_name not in by_idx or b_name not in by_idx:
            return 1e18
        pa, pb = polys[by_idx[a_name]], polys[by_idx[b_name]]
        if len(pa) < 2 or len(pb) < 2:
            return 1e18
        return min(dist(p, q) for p in pa for q in pb)

    def snap_pair(a_name: str, b_name: str) -> bool:
        if a_name not in by_idx or b_name not in by_idx:
            return False
        ia, ib = by_idx[a_name], by_idx[b_name]
        pa, pb = polys[ia], polys[ib]
        if len(pa) < 2 or len(pb) < 2:
            return False
        if pair_gap(a_name, b_name) < 1.0:
            return False
        candidates: list[tuple[float, int, int]] = []
        for pi, p in enumerate(pa):
            for pj, q in enumerate(pb):
                d = dist(p, q)
                if d > CONNECT_MAIN:
                    continue
                end_bonus = 0.0
                if pi in (0, len(pa) - 1):
                    end_bonus -= 400.0
                if pj in (0, len(pb) - 1):
                    end_bonus -= 400.0
                # Prefer snapping protected corridors at endpoints only.
                if a_name in STRAIGHT_CORRIDORS and pi not in (0, len(pa) - 1):
                    end_bonus += 2000.0
                if b_name in STRAIGHT_CORRIDORS and pj not in (0, len(pb) - 1):
                    end_bonus += 2000.0
                candidates.append((d + end_bonus, pi, pj))
        if not candidates:
            return False
        candidates.sort()
        _, pi, pj = candidates[0]
        if a_name in STRAIGHT_CORRIDORS and pi not in (0, len(pa) - 1):
            d0, d1 = dist(pa[0], pb[pj]), dist(pa[-1], pb[pj])
            pi = 0 if d0 <= d1 else len(pa) - 1
        if b_name in STRAIGHT_CORRIDORS and pj not in (0, len(pb) - 1):
            d0, d1 = dist(pb[0], pa[pi]), dist(pb[-1], pa[pi])
            pj = 0 if d0 <= d1 else len(pb) - 1
        # Prefer attaching the lower-priority road onto the other road's vertex
        # rather than averaging (avoids pulling a through-road into a U-turn).
        through_first = (
            a_name == "Winterthurerstrasse"
            or (b_name != "Winterthurerstrasse" and a_name in REQUIRED_MAINS)
        )
        if through_first:
            mid = snap_lattice(pa[pi])
        else:
            mid = snap_lattice(pb[pj])
        pa[pi] = mid
        pb[pj] = mid
        polys[ia] = _rebuild_octi(pa, STRAIGHT_CORRIDORS.get(a_name, {}).get("axis"))
        polys[ib] = _rebuild_octi(pb, STRAIGHT_CORRIDORS.get(b_name, {}).get("axis"))
        # Reject reverse folds introduced by the snap.
        for name, poly_i in ((a_name, ia), (b_name, ib)):
            pts = polys[poly_i]
            for k in range(1, len(pts) - 1):
                if turn_deg(pts[k - 1], pts[k], pts[k + 1]) >= REVERSE_FOLD_DEG:
                    polys[poly_i] = _fix_reverse_at(pts, k)
                    break
        return True

    def attach_end_to_hub(
        pts: list[tuple[float, float]],
        end_i: int,
        hub: tuple[float, float],
        prefer: str | None = None,
    ) -> list[tuple[float, float]]:
        pts = list(pts)
        pts[end_i] = hub
        if end_i == 0 and len(pts) >= 2:
            rest = pts[1:]
            out = list(octilinear_leg(hub, rest[0], prefer_axis=prefer))
            out.extend(rest[1:])
            return _dedupe_polyline(out)
        if end_i == len(pts) - 1 and len(pts) >= 2:
            head = pts[:-1]
            out = list(head[:-1]) if len(head) > 1 else []
            out.extend(octilinear_leg(head[-1], hub, prefer_axis=prefer))
            return _dedupe_polyline(out)
        return _rebuild_octi(pts, prefer)

    # Triple hub first: attach Ohringer + Stations onto Winter (through-road stays put).
    hub_names = ("Ohringerstrasse", "Winterthurerstrasse", "Stationsstrasse")
    if all(n in by_idx for n in hub_names):
        io, iw, is_ = by_idx[hub_names[0]], by_idx[hub_names[1]], by_idx[hub_names[2]]
        po, pw, ps = list(polys[io]), list(polys[iw]), list(polys[is_])
        # EW corridor reference — do not trust a possibly-yanked east tip far off-axis.
        if po[0][0] <= po[-1][0]:
            o_start, o_end_i = po[0], len(po) - 1
        else:
            o_start, o_end_i = po[-1], 0
        corridor_y = o_start[1]
        target = (max(p[0] for p in po), corridor_y)

        def winter_hub_score(pt: tuple[float, float]) -> float:
            # Prefer Winter points near the Ohringer EW approach (not a far NS tip).
            return dist(pt, target) + 1.5 * abs(pt[1] - corridor_y)

        # Rank existing Winter vertices, then best segment projection of target.
        candidates: list[tuple[float, str, int, tuple[float, float]]] = []
        for i, p in enumerate(pw):
            candidates.append((winter_hub_score(p), "vertex", i, p))
        for i in range(len(pw) - 1):
            proj, t = project_onto_segment(target, pw[i], pw[i + 1])
            if t < 0.02 or t > 0.98:
                continue
            pj = snap_lattice(proj)
            candidates.append((winter_hub_score(pj), "insert", i + 1, pj))
        candidates.sort(key=lambda c: c[0])

        hub = None
        w_idx = 0
        kind = "vertex"
        for _score, cand_kind, cand_idx, cand_pt in candidates[:12]:
            trial = list(pw)
            idx = cand_idx
            if cand_kind == "insert":
                trial = trial[:cand_idx] + [cand_pt] + trial[cand_idx:]
            if not _hub_turn_ok(trial, idx):
                continue
            # Reject hubs that force a huge Ohringer NS stub (> ~1/4 of EW length).
            stub = abs(cand_pt[1] - corridor_y)
            if stub > max(1200.0, abs(cand_pt[0] - o_start[0]) * 0.08):
                continue
            hub, w_idx, kind = cand_pt, idx, cand_kind
            pw = trial if cand_kind == "insert" else pw
            break
        if hub is None:
            # Fallback: nearest on polyline to corridor target (still no sideways yank).
            kind, w_idx, hub = _nearest_on_polyline(pw, target)
            if kind == "insert":
                pw = pw[:w_idx] + [hub] + pw[w_idx:]
            else:
                hub = pw[w_idx]

        prefer_o = STRAIGHT_CORRIDORS.get("Ohringerstrasse", {}).get("axis")
        polys[io] = attach_end_to_hub(po, o_end_i, hub, prefer_o)
        polys[iw] = _dedupe_polyline(pw)
        # Stations: prefer endpoint nearest to hub.
        s_end_i = 0 if dist(ps[0], hub) <= dist(ps[-1], hub) else len(ps) - 1
        if dist(ps[s_end_i], hub) <= CONNECT_MAIN:
            polys[is_] = attach_end_to_hub(ps, s_end_i, hub, None)
        else:
            si = min(range(len(ps)), key=lambda i: dist(ps[i], hub))
            ps = list(ps)
            ps[si] = hub
            polys[is_] = _rebuild_octi(ps, None)
            for k in range(1, len(polys[is_]) - 1):
                if turn_deg(polys[is_][k - 1], polys[is_][k], polys[is_][k + 1]) >= REVERSE_FOLD_DEG:
                    polys[is_] = _fix_reverse_at(polys[is_], k)
                    break

        # Drop Stations vertices that ride along Winter (double corridor).
        polys[is_] = prune_coincident_overlap(polys[is_], polys[iw])
        # Re-assert single hub meet after prune.
        if min(dist(q, hub) for q in polys[is_]) >= 1.0:
            s_end_i = 0 if dist(polys[is_][0], hub) <= dist(polys[is_][-1], hub) else len(polys[is_]) - 1
            polys[is_] = attach_end_to_hub(polys[is_], s_end_i, hub, None)
            polys[is_] = prune_coincident_overlap(polys[is_], polys[iw])

        # Ensure Winter still has hub vertex and turn is ok.
        pw = polys[iw]
        if min(dist(q, hub) for q in pw) >= 1.0:
            kind, w_idx, _ = _nearest_on_polyline(pw, hub)
            if kind == "insert":
                pw = pw[:w_idx] + [hub] + pw[w_idx:]
            else:
                pw[w_idx] = hub
            polys[iw] = _dedupe_polyline(pw)
        pw = polys[iw]
        for k, q in enumerate(pw):
            if dist(q, hub) >= 1.0 or _hub_turn_ok(pw, k):
                continue
            if not (0 < k < len(pw) - 1):
                break
            left, right = pw[k - 1], pw[k + 1]
            if turn_deg(left, hub, right) < REVERSE_FOLD_DEG:
                break
            # Spike: remove hub, reconnect through-path, re-insert hub on chord.
            base = pw[: k - 1] + list(octilinear_leg(left, right)) + pw[k + 2 :]
            kind2, kk, hub2 = _nearest_on_polyline(base, hub)
            if kind2 == "insert" and 0 < kk <= len(base):
                if kk < len(base):
                    proj, _ = project_onto_segment(hub, base[kk - 1], base[kk])
                    hub = snap_lattice(proj)
                else:
                    hub = hub2
                base = base[:kk] + [hub] + base[kk:]
            else:
                hub = base[kk] if kind2 == "vertex" else hub2
            polys[iw] = _dedupe_polyline(base)
            o_end_i2 = (
                len(polys[io]) - 1
                if polys[io][-1][0] >= polys[io][0][0]
                else 0
            )
            polys[io] = attach_end_to_hub(polys[io], o_end_i2, hub, prefer_o)
            s_end_i = (
                0
                if dist(polys[is_][0], hub) <= dist(polys[is_][-1], hub)
                else len(polys[is_]) - 1
            )
            polys[is_] = attach_end_to_hub(polys[is_], s_end_i, hub, None)
            polys[is_] = prune_coincident_overlap(polys[is_], polys[iw])
            break

    for _ in range(4):
        changed = False
        for a_name, b_name in REQUIRED_JUNCTIONS:
            if pair_gap(a_name, b_name) >= 1.0:
                changed = snap_pair(a_name, b_name) or changed
        if not changed:
            break

    # Rebuild protected corridors as near-straight start→hub runs (kills connect zigzags).
    for name, cfg in STRAIGHT_CORRIDORS.items():
        if name not in by_idx:
            continue
        ri = by_idx[name]
        pts = polys[ri]
        if len(pts) < 2:
            continue
        # Keep the west/south-most start (smaller X for EW corridors).
        if cfg.get("axis") == "ew":
            start = pts[0] if pts[0][0] <= pts[-1][0] else pts[-1]
            end = pts[-1] if pts[-1][0] >= pts[0][0] else pts[0]
        else:
            start, end = pts[0], pts[-1]
        # Prefer shared hub with Winter/Stations if present.
        hub_pt = end
        for other in ("Winterthurerstrasse", "Stationsstrasse"):
            if other not in by_idx:
                continue
            for q in polys[by_idx[other]]:
                if dist(q, end) < 1.0:
                    hub_pt = q
                    break
            else:
                continue
            break
        # Also accept any Winter vertex near the east end (after attach).
        if name == "Ohringerstrasse" and "Winterthurerstrasse" in by_idx:
            ww = polys[by_idx["Winterthurerstrasse"]]
            near = min(ww, key=lambda q: dist(q, end))
            if dist(near, end) <= CONNECT_NEAR:
                hub_pt = near
        straight = octilinear_leg(start, hub_pt, prefer_axis=cfg.get("axis"))
        # If still a long 45° detour, force H-then-V / V-then-H for EW.
        if cfg.get("axis") == "ew" and len(straight) >= 2:
            dx = abs(hub_pt[0] - start[0])
            dy = abs(hub_pt[1] - start[1])
            if dy > LATTICE and dx > 4 * dy:
                # Long EW: one horizontal then short vertical (or vice versa at end).
                mid = snap_lattice((hub_pt[0], start[1]))
                straight = _dedupe_polyline([start, mid, hub_pt])
                if dist(start, mid) < 1.0:
                    straight = _dedupe_polyline([start, hub_pt])
                elif dist(mid, hub_pt) < 1.0:
                    straight = _dedupe_polyline([start, hub_pt])
        polys[ri] = straight
        # Re-pin shared hub vertex onto Winter/Stations after replace.
        for other in ("Winterthurerstrasse", "Stationsstrasse"):
            if other not in by_idx:
                continue
            oi = by_idx[other]
            for pj, q in enumerate(polys[oi]):
                if dist(q, end) < 1.0 or dist(q, hub_pt) < 1.0:
                    polys[oi][pj] = hub_pt
                    if not _hub_turn_ok(polys[oi], pj):
                        # Don't yank — restore and ensure hub exists via insert on segment.
                        polys[oi][pj] = q
                        kind, wi, _ = _nearest_on_polyline(polys[oi], hub_pt)
                        if kind == "insert":
                            proj, _ = project_onto_segment(
                                hub_pt, polys[oi][wi - 1], polys[oi][wi]
                            )
                            hub_pt = snap_lattice(proj)
                            polys[oi] = (
                                polys[oi][:wi] + [hub_pt] + polys[oi][wi:]
                            )
                            polys[ri] = octilinear_leg(
                                start, hub_pt, prefer_axis=cfg.get("axis")
                            )
                            if cfg.get("axis") == "ew":
                                dx = abs(hub_pt[0] - start[0])
                                dy = abs(hub_pt[1] - start[1])
                                if dy > LATTICE and dx > 4 * dy:
                                    mid = snap_lattice((hub_pt[0], start[1]))
                                    polys[ri] = _dedupe_polyline(
                                        [start, mid, hub_pt]
                                    )
                        else:
                            hub_pt = polys[oi][wi]
                            polys[ri][-1] = hub_pt
                    break

    # One more junction pass after corridor straighten.
    for _ in range(3):
        changed = False
        for a_name, b_name in REQUIRED_JUNCTIONS:
            if pair_gap(a_name, b_name) >= 1.0:
                changed = snap_pair(a_name, b_name) or changed
        if not changed:
            break

    # Final: side streets must not double-trace Winter (or other through mains).
    if "Winterthurerstrasse" in by_idx:
        iw = by_idx["Winterthurerstrasse"]
        for side_name in ("Stationsstrasse", "Ohringerstrasse", "Welsikonerstrasse", "Kirchgasse"):
            if side_name not in by_idx:
                continue
            si = by_idx[side_name]
            prefer = STRAIGHT_CORRIDORS.get(side_name, {}).get("axis")
            polys[si] = prune_coincident_overlap(polys[si], polys[iw], prefer=prefer)

    out = []
    for ri, r in enumerate(roads):
        pts = polys[ri]
        if len(pts) < 2:
            continue
        out.append(
            {
                "name": r["name"],
                "class": r["class"],
                "points": [[round(x, 1), round(y, 1)] for x, y in pts],
            }
        )
    return out


def _shared_junction_keys(roads: list[dict]) -> set[tuple[float, float]]:
    counts: dict[tuple[float, float], set[str]] = defaultdict(set)
    for r in roads:
        for p in r["points"]:
            counts[point_key((float(p[0]), float(p[1])))].add(str(r["name"]))
    return {k for k, names in counts.items() if len(names) >= 2}


def _clean_polyline(
    pts: list[tuple[float, float]],
    shared: set[tuple[float, float]],
    *,
    prefer_axis: str | None = None,
) -> list[tuple[float, float]]:
    """Remove reverse folds, merge colinear mids, collapse micros, flatten stairs."""
    if len(pts) < 3:
        return _dedupe_polyline(pts)

    def shared_pt(p: tuple[float, float]) -> bool:
        return point_key(p) in shared

    pts = _dedupe_polyline([snap_lattice(p) for p in pts])
    changed = True
    guard = 0
    while changed and guard < 48:
        changed = False
        guard += 1
        if len(pts) < 3:
            break

        # 1) Reverse folds ≥150°
        for i in range(1, len(pts) - 1):
            if turn_deg(pts[i - 1], pts[i], pts[i + 1]) < REVERSE_FOLD_DEG:
                continue
            # Ping-pong A→B→A: always drop B (even if shared key appears twice on one road).
            if dist(pts[i - 1], pts[i + 1]) < 1.0:
                pts = pts[:i] + pts[i + 1 :]
                pts = _dedupe_polyline(pts)
                changed = True
                break
            if not shared_pt(pts[i]):
                # Drop mid; reconnect with octilinear if needed.
                a, c = pts[i - 1], pts[i + 1]
                mid_chain = octilinear_leg(a, c, prefer_axis=prefer_axis)
                pts = pts[: i - 1] + mid_chain + pts[i + 2 :]
                pts = _dedupe_polyline(pts)
                changed = True
                break
            # Shared hub: drop non-shared spike neighbor(s).
            drop_i = None
            if not shared_pt(pts[i - 1]) and i - 1 > 0:
                drop_i = i - 1
            elif not shared_pt(pts[i + 1]) and i + 1 < len(pts) - 1:
                drop_i = i + 1
            if drop_i is not None:
                a = pts[drop_i - 1] if drop_i > 0 else None
                c = pts[drop_i + 1] if drop_i + 1 < len(pts) else None
                if a is not None and c is not None:
                    trial = (
                        pts[: drop_i - 1]
                        + octilinear_leg(a, c, prefer_axis=prefer_axis)
                        + pts[drop_i + 2 :]
                    )
                else:
                    trial = pts[:drop_i] + pts[drop_i + 1 :]
                trial = _dedupe_polyline(trial)
                if trial != pts:
                    pts = trial
                    changed = True
                break
            # Cannot safely edit shared fold here — leave for hub pin / skip.
            continue
        if changed:
            continue

        # 2) Colinear merge (turn ≈ 0)
        for i in range(1, len(pts) - 1):
            if shared_pt(pts[i]):
                continue
            if turn_deg(pts[i - 1], pts[i], pts[i + 1]) > COLINEAR_DEG:
                continue
            if is_octilinear_seg(pts[i - 1], pts[i + 1]):
                pts = pts[:i] + pts[i + 1 :]
                changed = True
                break
        if changed:
            continue

        # 3) Micro-segments < MIN_CORNER_SEG_WU
        for i in range(len(pts) - 1):
            if dist(pts[i], pts[i + 1]) >= MIN_CORNER_SEG_WU:
                continue
            # Prefer dropping non-shared endpoint of the micro seg (not road ends).
            candidates = []
            if i > 0 and not shared_pt(pts[i]):
                candidates.append(i)
            if i + 1 < len(pts) - 1 and not shared_pt(pts[i + 1]):
                candidates.append(i + 1)
            if not candidates:
                continue
            drop = candidates[0]
            # Keep octilinearity after drop.
            trial = pts[:drop] + pts[drop + 1 :]
            trial = _dedupe_polyline(trial)
            ok = True
            for j in range(len(trial) - 1):
                if not is_octilinear_seg(trial[j], trial[j + 1]):
                    # Try octilinear repair across gap.
                    ok = False
                    break
            if not ok and drop > 0 and drop < len(pts) - 1:
                a = pts[drop - 1]
                c = pts[drop + 1]
                trial = pts[: drop - 1] + octilinear_leg(a, c, prefer_axis=prefer_axis) + pts[drop + 2 :]
                trial = _dedupe_polyline(trial)
                ok = all(
                    is_octilinear_seg(trial[j], trial[j + 1])
                    for j in range(len(trial) - 1)
                )
            if ok and len(trial) >= 2:
                pts = trial
                changed = True
                break
        if changed:
            continue

        # 4) Optional: flatten single ~135° stair if a→c is octilinear and close to chord.
        for i in range(1, len(pts) - 1):
            if shared_pt(pts[i]):
                continue
            td = turn_deg(pts[i - 1], pts[i], pts[i + 1])
            if abs(td - STAIR_FLAT_DEG) > 20.0:
                continue
            a, c = pts[i - 1], pts[i + 1]
            if not is_octilinear_seg(a, c):
                continue
            proj, _ = project_onto_segment(pts[i], a, c)
            if dist(pts[i], proj) > STAIR_FLAT_SLACK:
                continue
            pts = pts[:i] + pts[i + 1 :]
            changed = True
            break

    return _dedupe_polyline(pts)


def _polyline_length(pts: list[tuple[float, float]]) -> float:
    return sum(dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def _ang_diff_deg(a: float, b: float) -> float:
    return abs((a - b + 180.0) % 360.0 - 180.0)


def _bearing_similar(a: float, b: float, tol: float = PARALLEL_BEARING_DEG) -> bool:
    return _ang_diff_deg(a, b) <= tol or _ang_diff_deg(a, (b + 180.0) % 360.0) <= tol


def _axis_unit(bearing: float) -> tuple[float, float]:
    r = math.radians(bearing)
    return math.cos(r), math.sin(r)


def _perp_unit(bearing: float) -> tuple[float, float]:
    ux, uy = _axis_unit(bearing)
    return -uy, ux


def _proj_t(p: tuple[float, float], origin: tuple[float, float], ux: float, uy: float) -> float:
    return (p[0] - origin[0]) * ux + (p[1] - origin[1]) * uy


def _longitudinal_overlap(
    a0: tuple[float, float],
    a1: tuple[float, float],
    b0: tuple[float, float],
    b1: tuple[float, float],
    bearing: float,
) -> float:
    ux, uy = _axis_unit(bearing)
    origin = a0
    ta0, ta1 = sorted([_proj_t(a0, origin, ux, uy), _proj_t(a1, origin, ux, uy)])
    tb0, tb1 = sorted([_proj_t(b0, origin, ux, uy), _proj_t(b1, origin, ux, uy)])
    return max(0.0, min(ta1, tb1) - max(ta0, tb0))


def _perp_seg_dist(
    a0: tuple[float, float],
    a1: tuple[float, float],
    b0: tuple[float, float],
    b1: tuple[float, float],
) -> float:
    """Perpendicular distance between two near-parallel segment lines (wu)."""
    br = bearing_deg(a0, a1)
    nx, ny = _perp_unit(br)
    mb = ((b0[0] + b1[0]) * 0.5, (b0[1] + b1[1]) * 0.5)
    return abs((mb[0] - a0[0]) * nx + (mb[1] - a0[1]) * ny)


def _seg_mid_dist(
    a0: tuple[float, float],
    a1: tuple[float, float],
    b0: tuple[float, float],
    b1: tuple[float, float],
) -> float:
    """Alias kept for tests; spacing uses perpendicular distance."""
    return _perp_seg_dist(a0, a1, b0, b1)


def _long_segments(
    pts: list[tuple[float, float]], min_len: float = PARALLEL_LONG_SEG
) -> list[tuple[int, tuple[float, float], tuple[float, float], float, float]]:
    """(seg_index, a, b, length, bearing_deg)."""
    out = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = dist(a, b)
        if L < min_len:
            continue
        out.append((i, a, b, L, bearing_deg(a, b)))
    return out


def _road_priority(road: dict) -> tuple[int, float, int]:
    """Higher = stronger / keep-in-place. Length breaks class ties; non-links win."""
    name = str(road["name"])
    cls = str(road.get("class", "local"))
    pts = [(float(x), float(y)) for x, y in road["points"]]
    length = _polyline_length(pts)
    link_pen = 0 if name.startswith("link-") else 1
    return (link_pen, CLASS_RANK.get(cls, 0), length)


def _is_artifact_pair(
    strong: dict, weak: dict, subset_frac: float, *, perp_dist: float
) -> bool:
    """Absorb when double-trace artifact, not two distinct real streets."""
    wn = str(weak["name"])
    sn = str(strong["name"])
    if wn.startswith("link-") or sn.startswith("link-"):
        return True
    sc, wc = str(strong.get("class", "local")), str(weak.get("class", "local"))
    # Colinear / on-top: only absorb when weak mostly rides on strong.
    if perp_dist <= max(1.0, LATTICE * 0.25):
        return subset_frac >= 0.55
    # Higher-class corridor with a local riding close → absorb only if mostly subset.
    if (
        perp_dist <= PARALLEL_ABSORB
        and CLASS_RANK.get(sc, 0) >= CLASS_RANK.get("collector", 2)
        and wc == "local"
        and subset_frac >= PARALLEL_SUBSET_FRAC
    ):
        return True
    # Weak almost entirely projects onto stronger *and* is lower class → absorb.
    if (
        subset_frac >= PARALLEL_SUBSET_FRAC
        and perp_dist <= PARALLEL_ABSORB
        and CLASS_RANK.get(sc, 0) > CLASS_RANK.get(wc, 0)
    ):
        return True
    return False


def _projection_subset_frac(
    weak_pts: list[tuple[float, float]],
    strong_pts: list[tuple[float, float]],
    bearing: float,
) -> float:
    """Fraction of weak length whose vertices project near strong polyline."""
    if len(weak_pts) < 2 or len(strong_pts) < 2:
        return 0.0
    total = _polyline_length(weak_pts)
    if total < 1.0:
        return 0.0
    covered = 0.0
    for i in range(len(weak_pts) - 1):
        a, b = weak_pts[i], weak_pts[i + 1]
        mid = ((a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5)
        # Near strong if mid projects within PARALLEL_TOO_CLOSE of some strong seg
        # with similar bearing.
        near = False
        for j in range(len(strong_pts) - 1):
            s0, s1 = strong_pts[j], strong_pts[j + 1]
            if dist(s0, s1) < PARALLEL_LONG_SEG * 0.5:
                continue
            sb = bearing_deg(s0, s1)
            if not _bearing_similar(bearing, sb):
                continue
            proj, t = project_onto_segment(mid, s0, s1)
            if 0.0 <= t <= 1.0 and dist(mid, proj) <= PARALLEL_TOO_CLOSE:
                near = True
                break
        if near:
            covered += dist(a, b)
    return covered / total


def find_near_parallel_pairs(
    roads: list[dict],
    *,
    max_mid: float = PARALLEL_TOO_CLOSE,
    min_mid: float = 0.0,
    min_overlap: float = PARALLEL_OVERLAP,
) -> list[dict]:
    """Detect near-parallel long-segment pairs by perpendicular spacing.

    Skips segment pairs that already share an endpoint vertex. Includes colinear
    doubles (perp ≈ 0) so absorb can collapse them.
    """
    polys = [[(float(x), float(y)) for x, y in r["points"]] for r in roads]
    pairs: list[dict] = []
    for i in range(len(roads)):
        segs_i = _long_segments(polys[i])
        if not segs_i:
            continue
        for j in range(i + 1, len(roads)):
            segs_j = _long_segments(polys[j])
            if not segs_j:
                continue
            # Skip roads that already share any vertex (connected junctions).
            # Exception: still flag if a long parallel run exists away from the meet
            # — handled by per-segment shared-endpoint skip below.
            best = None
            for si, a0, a1, La, ba in segs_i:
                for sj, b0, b1, Lb, bb in segs_j:
                    if not _bearing_similar(ba, bb):
                        continue
                    if any(dist(p, q) < 1.0 for p in (a0, a1) for q in (b0, b1)):
                        continue
                    pd = _perp_seg_dist(a0, a1, b0, b1)
                    if not (min_mid <= pd <= max_mid):
                        continue
                    # Tiny float noise: treat sub-wu as 0.
                    if pd < 1.0:
                        pd = 0.0
                    ov = _longitudinal_overlap(a0, a1, b0, b1, ba)
                    if ov < min_overlap:
                        continue
                    cand = {
                        "i": i,
                        "j": j,
                        "si": si,
                        "sj": sj,
                        "mid_dist": pd,
                        "overlap": ov,
                        "bearing": ba,
                        "La": La,
                        "Lb": Lb,
                    }
                    # Prefer closest + longest overlap.
                    if best is None or (cand["mid_dist"], -cand["overlap"]) < (
                        best["mid_dist"],
                        -best["overlap"],
                    ):
                        best = cand
            if best is not None:
                pairs.append(best)
    pairs.sort(key=lambda p: (p["mid_dist"], -p["overlap"]))
    return pairs


def count_near_parallel_pairs(
    roads: list[dict], *, lo: float = 80.0, hi: float = 400.0
) -> int:
    """Metric helper: count pairs with perpendicular spacing in [lo, hi]."""
    return len(find_near_parallel_pairs(roads, max_mid=hi, min_mid=lo))


def _absorb_weak_onto_strong(
    weak: list[tuple[float, float]],
    strong: list[tuple[float, float]],
    *,
    bearing: float,
    shared: set[tuple[float, float]],
    prefer: str | None = None,
    absorb_eps: float = PARALLEL_ABSORB + LATTICE,
) -> list[tuple[float, float]] | None:
    """Collapse weak span that rides near strong.

    Returns new polyline, or None if the weak road should be dropped entirely
    (full artifact double with no remainder off the strong corridor).
    """
    if len(weak) < 2 or len(strong) < 2:
        return weak

    def near_strong(p: tuple[float, float]) -> bool:
        for i in range(len(strong) - 1):
            s0, s1 = strong[i], strong[i + 1]
            if dist(s0, s1) < MIN_SEG_WU:
                continue
            if not _bearing_similar(bearing, bearing_deg(s0, s1), tol=PARALLEL_BEARING_DEG + 5.0):
                continue
            proj, t = project_onto_segment(p, s0, s1)
            if 0.0 <= t <= 1.0 and dist(p, proj) <= absorb_eps:
                return True
        # Also accept near any strong vertex (hubs / short segs).
        return any(dist(p, q) <= absorb_eps for q in strong)

    on = [near_strong(p) for p in weak]
    for i in range(len(weak) - 1):
        mid = ((weak[i][0] + weak[i + 1][0]) * 0.5, (weak[i][1] + weak[i + 1][1]) * 0.5)
        if near_strong(mid):
            if not (point_key(weak[i]) in shared):
                on[i] = True
            if not (point_key(weak[i + 1]) in shared):
                on[i + 1] = True

    if not any(on):
        return weak

    # Full coverage → drop (caller removes road), unless shared hubs must remain.
    if all(on) and not any(point_key(p) in shared for p in weak):
        return None

    kept: list[tuple[float, float]] = []
    n = len(weak)
    i = 0
    while i < n:
        if not on[i]:
            kept.append(weak[i])
            i += 1
            continue
        j = i
        while j < n and on[j]:
            j += 1
        run = weak[i:j]
        # Preserve shared junctions inside the run.
        shared_in_run = [p for p in run if point_key(p) in shared]
        if i == 0 and j == n and not shared_in_run:
            return None
        if shared_in_run:
            meet = shared_in_run[0]
        elif i == 0:
            meet = _nearest_point_on_polyline(strong, run[-1])
        elif j == n:
            meet = _nearest_point_on_polyline(strong, run[0])
        else:
            meet = _nearest_point_on_polyline(strong, run[0])
        if not kept or dist(kept[-1], meet) >= 1.0:
            kept.append(meet)
        # If run is interior and we need to continue past it, one meet is enough.
        i = j

    if len(kept) < 2:
        return None
    rebuilt: list[tuple[float, float]] = [snap_lattice(kept[0])]
    for p in kept[1:]:
        rebuilt.extend(octilinear_leg(rebuilt[-1], snap_lattice(p), prefer_axis=prefer)[1:])
    rebuilt = _dedupe_polyline(rebuilt)
    if len(rebuilt) < 2:
        return None
    # If rebuilt still lies entirely on strong, drop it.
    if all(near_strong(p) for p in rebuilt) and not any(
        point_key(p) in shared for p in rebuilt
    ):
        return None
    return rebuilt


def _nearest_point_on_polyline(
    pts: list[tuple[float, float]], p: tuple[float, float]
) -> tuple[float, float]:
    best = pts[0]
    best_d = dist(p, best)
    for q in pts:
        d = dist(p, q)
        if d < best_d:
            best, best_d = q, d
    for i in range(len(pts) - 1):
        proj, t = project_onto_segment(p, pts[i], pts[i + 1])
        if 0.0 <= t <= 1.0:
            d = dist(p, proj)
            if d < best_d:
                best, best_d = snap_lattice(proj), d
    return snap_lattice(best)


def _offset_polyline(
    pts: list[tuple[float, float]],
    bearing: float,
    delta: float,
    *,
    shared: set[tuple[float, float]],
    prefer: str | None = None,
) -> list[tuple[float, float]]:
    """Offset non-protected vertices perpendicular to bearing by delta (wu)."""
    nx, ny = _perp_unit(bearing)
    out: list[tuple[float, float]] = []
    for p in pts:
        if point_key(p) in shared:
            out.append(p)
            continue
        out.append(snap_lattice((p[0] + nx * delta, p[1] + ny * delta)))
    rebuilt = _rebuild_octi(out, prefer)
    return rebuilt if len(rebuilt) >= 2 else pts


def _pair_shared_keys(
    a: list[tuple[float, float]], b: list[tuple[float, float]]
) -> set[tuple[float, float]]:
    """Vertices of a that coincide with b (pair-local hubs to preserve)."""
    bkeys = {point_key(p) for p in b}
    return {point_key(p) for p in a if point_key(p) in bkeys}


def _choose_mover(
    a: dict, b: dict
) -> tuple[dict, dict]:
    """Return (strong/keep, weak/move). Respect PARALLEL_PINNED."""
    pa, pb = _road_priority(a), _road_priority(b)
    an, bn = str(a["name"]), str(b["name"])
    a_pin = an in PARALLEL_PINNED
    b_pin = bn in PARALLEL_PINNED
    if a_pin and not b_pin:
        return a, b
    if b_pin and not a_pin:
        return b, a
    if pa >= pb:
        return a, b
    return b, a


def resolve_near_parallels(roads: list[dict]) -> list[dict]:
    """Post-pass (after clean_corners): absorb artifact doubles; separate real pairs."""
    if len(roads) < 2:
        return roads

    out: list[dict] = [
        {
            "name": r["name"],
            "class": r["class"],
            "points": [[float(x), float(y)] for x, y in r["points"]],
        }
        for r in roads
    ]

    def _commit_weak(wi: int, new_pts: list[tuple[float, float]]) -> None:
        shared_now = _shared_junction_keys(out)
        prefer = STRAIGHT_CORRIDORS.get(str(out[wi]["name"]), {}).get("axis")
        cleaned = _clean_polyline(new_pts, shared_now, prefer_axis=prefer)
        if len(cleaned) < 2:
            cleaned = new_pts
        out[wi]["points"] = [[round(x, 1), round(y, 1)] for x, y in cleaned]

    # Enough sweeps to clear cascades (absorb → new pairs → separate).
    for _sweep in range(64):
        shared = _shared_junction_keys(out)
        pairs = find_near_parallel_pairs(out, max_mid=PARALLEL_TOO_CLOSE, min_mid=0.0)
        if not pairs:
            break
        changed = False
        for pair in pairs:
            i, j = pair["i"], pair["j"]
            if i >= len(out) or j >= len(out):
                continue
            an, bn = str(out[i]["name"]), str(out[j]["name"])
            # Never move both pinned mains relative to each other.
            if an in PARALLEL_PINNED and bn in PARALLEL_PINNED:
                continue

            strong_r, weak_r = _choose_mover(out[i], out[j])
            si = next(k for k, r in enumerate(out) if r["name"] == strong_r["name"])
            wi = next(k for k, r in enumerate(out) if r["name"] == weak_r["name"])
            strong_pts = [(float(x), float(y)) for x, y in out[si]["points"]]
            weak_pts = [(float(x), float(y)) for x, y in out[wi]["points"]]
            bearing = pair["bearing"]
            md = float(pair["mid_dist"])
            subset = _projection_subset_frac(weak_pts, strong_pts, bearing)
            prefer = STRAIGHT_CORRIDORS.get(str(out[wi]["name"]), {}).get("axis")
            artifact = _is_artifact_pair(
                out[si], out[wi], subset, perp_dist=md
            )

            # 1) Absorb colinear / close artifact doubles.
            if md <= PARALLEL_ABSORB and artifact:
                new_weak: list[tuple[float, float]] | None
                if md <= LATTICE * 0.25:
                    pruned = prune_coincident_overlap(
                        weak_pts, strong_pts, prefer=prefer
                    )
                    if pruned != weak_pts and len(pruned) >= 2:
                        new_weak = pruned
                    else:
                        new_weak = _absorb_weak_onto_strong(
                            weak_pts,
                            strong_pts,
                            bearing=bearing,
                            shared=shared,
                            prefer=prefer,
                        )
                else:
                    new_weak = _absorb_weak_onto_strong(
                        weak_pts,
                        strong_pts,
                        bearing=bearing,
                        shared=shared,
                        prefer=prefer,
                    )
                if new_weak is None:
                    # Full artifact double — drop only synthetic link-* roads.
                    if str(out[wi]["name"]).startswith("link-"):
                        del out[wi]
                        changed = True
                        break
                    # Named road: never stub — keep geometry and try separate below.
                    new_weak = weak_pts
                weak_len = _polyline_length(weak_pts)
                new_len = _polyline_length(new_weak) if new_weak else 0.0
                # Refuse absorb that guts a named corridor (keep ≥40% length unless
                # almost entirely subset already).
                if (
                    not str(out[wi]["name"]).startswith("link-")
                    and weak_len > MIN_SEG_WU * 4
                    and new_len < weak_len * 0.4
                    and subset < 0.9
                ):
                    new_weak = weak_pts
                if len(new_weak) >= 2 and new_weak != weak_pts:
                    _commit_weak(wi, new_weak)
                    changed = True
                    break
                # Absorb no-oped → fall through to separate below.

            # 2) Separate real corridors that are still too close.
            if md >= PARALLEL_MIN_GAP:
                continue
            # Colinear doubles: still separate (nudge off the line) if absorb failed.

            nx, ny = _perp_unit(bearing)
            s_segs = _long_segments(strong_pts)
            w_segs = _long_segments(weak_pts)
            if not s_segs or not w_segs:
                continue
            best_md = None
            best_side = 0.0
            for _, a0, a1, _, ba in s_segs:
                for _, b0, b1, _, bb in w_segs:
                    if not _bearing_similar(ba, bb):
                        continue
                    if _longitudinal_overlap(a0, a1, b0, b1, ba) < PARALLEL_OVERLAP:
                        continue
                    cur = _perp_seg_dist(a0, a1, b0, b1)
                    if best_md is None or cur < best_md:
                        best_md = cur
                        mb = ((b0[0] + b1[0]) * 0.5, (b0[1] + b1[1]) * 0.5)
                        best_side = (mb[0] - a0[0]) * nx + (mb[1] - a0[1]) * ny
            if best_md is None or best_md >= PARALLEL_MIN_GAP:
                continue
            if best_md < 1.0:
                best_md = 0.0
            sign = 1.0 if best_side >= 0 else -1.0
            # If currently colinear-ish side≈0, push to +normal.
            if abs(best_side) < 1.0:
                sign = 1.0
            need = PARALLEL_MIN_GAP - best_md + LATTICE
            need = math.ceil(need / LATTICE) * LATTICE

            protect = _pair_shared_keys(weak_pts, strong_pts)
            weak_name = str(out[wi]["name"])
            for a_name, b_name in REQUIRED_JUNCTIONS:
                if weak_name not in (a_name, b_name):
                    continue
                other = a_name if b_name == weak_name else b_name
                other_r = next((r for r in out if r["name"] == other), None)
                if other_r is None:
                    continue
                op = [(float(x), float(y)) for x, y in other_r["points"]]
                protect |= _pair_shared_keys(weak_pts, op)

            def _min_parallel_gap(
                trial: list[tuple[float, float]],
            ) -> float:
                """Smallest perp gap from trial to any other road's long parallel segs."""
                gap = 1e18
                for rk, r in enumerate(out):
                    if rk == wi:
                        continue
                    other = [(float(x), float(y)) for x, y in r["points"]]
                    for _, a0, a1, _, ba in _long_segments(other):
                        for _, b0, b1, _, bb in _long_segments(trial):
                            if not _bearing_similar(ba, bb):
                                continue
                            if _longitudinal_overlap(a0, a1, b0, b1, ba) < PARALLEL_OVERLAP:
                                continue
                            if any(dist(p, q) < 1.0 for p in (a0, a1) for q in (b0, b1)):
                                continue
                            gap = min(gap, _perp_seg_dist(a0, a1, b0, b1))
                return gap

            # Try both perpendicular directions; pick the one with better global gap
            # (avoids Seestrasse oscillating between Seebühl and Garten).
            candidates: list[tuple[float, list[tuple[float, float]]]] = []
            for trial_sign in (sign, -sign):
                delta = trial_sign * need
                trial = _offset_polyline(
                    weak_pts, bearing, delta, shared=protect, prefer=prefer
                )
                trial = _resnap_required_meets(
                    trial, out, wi, shared_before=shared
                )
                if len(trial) < 2 or trial == weak_pts:
                    continue
                candidates.append((_min_parallel_gap(trial), trial))
            if not candidates:
                continue
            candidates.sort(key=lambda c: -c[0])
            new_weak = candidates[0][1]
            # Only accept if we don't regress the global min gap.
            if _min_parallel_gap(new_weak) + 1.0 < _min_parallel_gap(weak_pts):
                continue
            _commit_weak(wi, new_weak)
            changed = True
            break
        if not changed:
            break

    # Re-assert required junctions if spacing moved endpoints.
    by = {r["name"]: r for r in out}
    need = False
    for a_name, b_name in REQUIRED_JUNCTIONS:
        if a_name not in by or b_name not in by:
            continue
        pa = [(float(x), float(y)) for x, y in by[a_name]["points"]]
        pb = [(float(x), float(y)) for x, y in by[b_name]["points"]]
        if min(dist(p, q) for p in pa for q in pb) >= 1.0:
            need = True
            break
    if need:
        out = force_required_junctions(out)

    # Final light clean to kill any reverse folds from offsets/absorbs.
    shared = _shared_junction_keys(out)
    fixed: list[dict] = []
    for r in out:
        prefer = STRAIGHT_CORRIDORS.get(r["name"], {}).get("axis")
        pts = [(float(x), float(y)) for x, y in r["points"]]
        pts = _clean_polyline(pts, shared, prefer_axis=prefer)
        if len(pts) < 2:
            continue
        fixed.append(
            {
                "name": r["name"],
                "class": r["class"],
                "points": [[round(x, 1), round(y, 1)] for x, y in pts],
            }
        )
    return fixed


def _resnap_required_meets(
    weak_pts: list[tuple[float, float]],
    roads: list[dict],
    weak_i: int,
    *,
    shared_before: set[tuple[float, float]],
) -> list[tuple[float, float]]:
    """After offset, pin endpoints that belonged to shared hubs / REQUIRED pairs."""
    weak_name = str(roads[weak_i]["name"])
    pts = list(weak_pts)
    # Collect partner roads that must share a vertex with weak.
    partners: list[str] = []
    for a, b in REQUIRED_JUNCTIONS:
        if a == weak_name:
            partners.append(b)
        elif b == weak_name:
            partners.append(a)
    by = {r["name"]: r for r in roads}
    for pname in partners:
        if pname not in by:
            continue
        partner = [(float(x), float(y)) for x, y in by[pname]["points"]]
        # If any shared_before key still on partner, snap nearest weak end to it.
        hubs = [p for p in partner if point_key(p) in shared_before]
        if not hubs:
            # Fallback: nearest partner vertex to either weak end.
            hubs = partner
        # Choose which weak end is closer to a hub.
        best = None
        for end_i in (0, len(pts) - 1):
            for h in hubs:
                d = dist(pts[end_i], h)
                if best is None or d < best[0]:
                    best = (d, end_i, h)
        if best is None:
            continue
        _d, end_i, hub = best
        if _d < 1.0:
            continue
        # Only resnap if we moved away from a hub that should still meet.
        if end_i == 0:
            rest = pts[1:]
            pts = list(octilinear_leg(hub, rest[0]))
            pts.extend(rest[1:])
        else:
            head = pts[:-1]
            pts = list(head[:-1]) if len(head) > 1 else []
            pts.extend(octilinear_leg(head[-1], hub))
        pts = _dedupe_polyline(pts)
    return pts if len(pts) >= 2 else weak_pts


def clean_corners(roads: list[dict]) -> list[dict]:
    """Post-pass: kill reverse folds / micros / colinear junk; protect shared junctions."""
    shared = _shared_junction_keys(roads)
    out: list[dict] = []
    for r in roads:
        prefer = STRAIGHT_CORRIDORS.get(r["name"], {}).get("axis")
        pts = [(float(x), float(y)) for x, y in r["points"]]
        pts = _clean_polyline(pts, shared, prefer_axis=prefer)
        if len(pts) < 2:
            continue
        out.append(
            {
                "name": r["name"],
                "class": r["class"],
                "points": [[round(x, 1), round(y, 1)] for x, y in pts],
            }
        )

    # If cleanup opened a required gap, re-snap those pairs then light re-clean.
    by = {r["name"]: r for r in out}
    need = False
    for a_name, b_name in REQUIRED_JUNCTIONS:
        if a_name not in by or b_name not in by:
            continue
        pa = [(float(x), float(y)) for x, y in by[a_name]["points"]]
        pb = [(float(x), float(y)) for x, y in by[b_name]["points"]]
        if min(dist(p, q) for p in pa for q in pb) >= 1.0:
            need = True
            break
    if need:
        out = force_required_junctions(out)
        shared = _shared_junction_keys(out)
        fixed: list[dict] = []
        for r in out:
            prefer = STRAIGHT_CORRIDORS.get(r["name"], {}).get("axis")
            pts = [(float(x), float(y)) for x, y in r["points"]]
            pts = _clean_polyline(pts, shared, prefer_axis=prefer)
            if len(pts) < 2:
                continue
            fixed.append(
                {
                    "name": r["name"],
                    "class": r["class"],
                    "points": [[round(x, 1), round(y, 1)] for x, y in pts],
                }
            )
        out = fixed
    return out


def _rebuild_octi(
    pts: list[tuple[float, float]], prefer_axis: str | None = None
) -> list[tuple[float, float]]:
    if len(pts) < 2:
        return pts
    rebuilt = [snap_lattice(pts[0])]
    for p in pts[1:]:
        leg = octilinear_leg(rebuilt[-1], snap_lattice(p), prefer_axis=prefer_axis)
        for q in leg[1:]:
            if dist(rebuilt[-1], q) >= 1.0:
                rebuilt.append(q)
    return _dedupe_polyline(rebuilt)


def validate_required_junctions(roads: list[dict]) -> None:
    by = {r["name"]: r for r in roads}
    missing = []
    for a_name, b_name in REQUIRED_JUNCTIONS:
        if a_name not in by or b_name not in by:
            missing.append(f"{a_name}↔{b_name} (road missing)")
            continue
        pa = [(float(x), float(y)) for x, y in by[a_name]["points"]]
        pb = [(float(x), float(y)) for x, y in by[b_name]["points"]]
        gap = min(dist(p, q) for p in pa for q in pb)
        if gap >= 1.0:
            missing.append(f"{a_name}↔{b_name} gap={gap:.0f}")
    if missing:
        raise SystemExit(f"required junctions failed: {missing}")


def cluster_junctions(roads: list[dict]) -> list[list[float]]:
    buckets: dict[tuple[int, int], list] = defaultdict(list)
    cell = JUNCTION_SNAP
    for r in roads:
        seen = set()
        for x, y in r["points"]:
            key = (int(round(x / cell)), int(round(y / cell)))
            if key in seen:
                continue
            seen.add(key)
            buckets[key].append((r["name"], x, y))
    junctions = []
    used = set()
    for key, items in buckets.items():
        if key in used:
            continue
        names = {n for n, _, _ in items}
        if len(names) < 2:
            continue
        cluster = list(items)
        used.add(key)
        kx, ky = key
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                nk = (kx + dx, ky + dy)
                if nk in used or nk not in buckets:
                    continue
                other = buckets[nk]
                if {n for n, _, _ in other} & names:
                    cluster.extend(other)
                    used.add(nk)
                    names |= {n for n, _, _ in other}
        if len(names) < 2:
            continue
        cx = sum(x for _, x, _ in cluster) / len(cluster)
        cy = sum(y for _, _, y in cluster) / len(cluster)
        cx, cy = snap_lattice((cx, cy))
        radius = 80.0 + 20.0 * min(4, len(names))
        junctions.append([round(cx, 1), round(cy, 1), round(radius, 1)])
    return junctions


def emit_svg(roads: list[dict], junctions: list[list[float]], path: Path) -> None:
    x0, y0, x1, y1 = CLIP
    w, h = x1 - x0, y1 - y0
    parts = [
        f'<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x0} {y0} {w} {h}" '
        f'width="2280" height="1680">',
        f'<rect x="{x0}" y="{y0}" width="{w}" height="{h}" fill="#e8f0e4"/>',
        f'<g id="grid" stroke="#d0d8cc" stroke-width="20">',
    ]
    # Light field grid every 1000 wu
    for gx in range(int(x0), int(x1) + 1, 1000):
        parts.append(f'<line x1="{gx}" y1="{y0}" x2="{gx}" y2="{y1}"/>')
    for gy in range(int(y0), int(y1) + 1, 1000):
        parts.append(f'<line x1="{x0}" y1="{gy}" x2="{x1}" y2="{gy}"/>')
    parts.append("</g>")

    parts.append('<g id="roads" fill="none" stroke-linecap="round" stroke-linejoin="round">')
    # Draw locals first so mains sit on top
    order = {"local": 0, "collector": 1, "main": 2, "motorway": 3}
    for r in sorted(roads, key=lambda rr: order.get(rr["class"], 0)):
        color, sw = STROKE[r["class"]]
        pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in r["points"])
        parts.append(
            f'<polyline class="{r["class"]}" data-name="{_xml_esc(r["name"])}" '
            f'points="{pts}" stroke="{color}" stroke-width="{sw}"/>'
        )
    parts.append("</g>")

    parts.append('<g id="junctions" fill="#555555" fill-opacity="0.35">')
    for jx, jy, jr in junctions:
        parts.append(f'<circle cx="{jx}" cy="{jy}" r="{jr}"/>')
    parts.append("</g>")

    parts.append('<g id="labels" font-family="sans-serif" font-size="420" fill="#222">')
    for r in roads:
        if r["class"] not in ("motorway", "main", "collector"):
            continue
        pts = r["points"]
        mid = pts[len(pts) // 2]
        parts.append(
            f'<text x="{mid[0]:.1f}" y="{mid[1]:.1f}" '
            f'stroke="#e8f0e4" stroke-width="80" paint-order="stroke">'
            f'{_xml_esc(r["name"])}</text>'
        )
    parts.append("</g>")

    parts.append('<g id="landmarks">')
    for name, (lat, lon) in LANDMARKS.items():
        x, y = gps_to_world(lat, lon)
        if not clip_point((x, y)):
            continue
        parts.append(
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="160" fill="#c0392b"/>'
            f'<text x="{x + 200:.1f}" y="{y - 120:.1f}" font-family="sans-serif" '
            f'font-size="380" fill="#8b1a1a">{_xml_esc(name)}</text>'
        )
    parts.append("</g>")

    # North hint (screen -Y is north)
    parts.append(
        f'<g id="north" transform="translate({x0 + 1800},{y0 + 2200})">'
        f'<polygon points="0,-600 220,200 -220,200" fill="#1a5276"/>'
        f'<text x="0" y="550" text-anchor="middle" font-family="sans-serif" '
        f'font-size="360" fill="#1a5276">N</text></g>'
    )

    parts.append(
        f'<text x="{x0 + 800}" y="{y1 - 800}" font-family="sans-serif" font-size="320" '
        f'fill="#555">Schematic octilinear streets aligned to Swiss Map Raster 10 '
        f'(1072-1 + 1052-3); world scale = project CLIP (Kirche origin). Not live game roads.</text>'
    )
    parts.append("</svg>\n")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(parts), encoding="utf-8")


def _xml_esc(s: str) -> str:
    return (
        s.replace("&", "&amp;")
        .replace('"', "&quot;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def main() -> None:
    src = SRC_SWISS if SRC_SWISS.exists() else SRC_FALLBACK
    raw = json.loads(src.read_text(encoding="utf-8"))
    roads_out: list[dict] = []
    for r in raw["roads"]:
        wpts = r["waypoints"]
        world = [gps_to_world(lat, lon) for lat, lon in wpts]
        world = clip_polyline(world)
        if len(world) < 2:
            continue
        cfg = STRAIGHT_CORRIDORS.get(r["name"], {})
        octi = octilinearize_polyline(
            world,
            rdp_cells=float(cfg.get("rdp_cells", 2.5)),
            prefer_axis=cfg.get("axis"),
            line_slack_wu=cfg.get("line_slack_wu"),
        )
        octi = clip_polyline(octi)
        if len(octi) < 2:
            continue
        # Drop tiny total length
        length = sum(dist(octi[i], octi[i + 1]) for i in range(len(octi) - 1))
        if length < MIN_SEG_WU:
            continue
        roads_out.append(
            {
                "name": r["name"],
                "class": r["class"],
                "points": [[round(x, 1), round(y, 1)] for x, y in octi],
            }
        )

    names = {r["name"] for r in roads_out}
    missing = REQUIRED_MAINS - names
    if missing:
        raise SystemExit(f"missing required mains after octilinearize: {missing}")

    roads_out = connect_network(roads_out)
    roads_out = force_required_junctions(roads_out)
    roads_out = clean_corners(roads_out)
    roads_out = resolve_near_parallels(roads_out)
    validate_octilinear(roads_out)
    validate_required_junctions(roads_out)
    junctions = cluster_junctions(roads_out)

    payload = {
        "meta": {
            "source": "Swiss Map Raster 10 ref (1072-1 + 1052-3) + named highway centerlines → octilinear (H/V/45°) + junction connect",
            "trace": str(src.relative_to(ROOT)),
            "church": [CHURCH_LAT, CHURCH_LON],
            "field_m": FIELD_M,
            "field_wu": FIELD_WU,
            "clip": list(CLIP),
            "lattice_wu": LATTICE,
            "connect_near_wu": CONNECT_NEAR,
            "connect_interior_wu": CONNECT_INTERIOR,
            "min_corner_seg_wu": MIN_CORNER_SEG_WU,
            "parallel_too_close_wu": PARALLEL_TOO_CLOSE,
            "parallel_absorb_wu": PARALLEL_ABSORB,
            "parallel_min_gap_wu": PARALLEL_MIN_GAP,
            "straight_corridors": sorted(STRAIGHT_CORRIDORS.keys()),
            "note": "Not wired into world_sandbox yet; live game still uses seuzach_roads.json",
        },
        "roads": roads_out,
        "junctions": junctions,
    }
    OUT_JSON.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    emit_svg(roads_out, junctions, OUT_SVG)
    print(f"wrote {OUT_JSON} ({len(roads_out)} roads, {len(junctions)} junctions)")
    print(f"wrote {OUT_SVG}")


if __name__ == "__main__":
    main()
