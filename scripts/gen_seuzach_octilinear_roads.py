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
CONNECT_NEAR = 3000.0  # snap near-miss vertices within ~160 m
CONNECT_MAIN = 5000.0  # component bridges may span farther
MIN_SEG_WU = 120.0
ANGLE_EPS_DEG = 0.75

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

    # --- Pass 2: snap near-miss vertices (no stubs yet); skip protected interiors ---
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
                    d = dist(p, q)
                    if d < best:
                        best = d
                        bi, bj = pi, pj
            if best < 1.0 or best > CONNECT_NEAR:
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
                    d = dist(p, q)
                    if d < best:
                        best, bi, bj = d, pi, pj
            if 1.0 < best <= CONNECT_NEAR:
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
    return force_required_junctions(final)


def force_required_junctions(roads: list[dict]) -> list[dict]:
    """Ensure named corridors share a vertex where the Swiss plan expects them to meet.

    Multi-pass so fixing Ohringer↔Winter does not permanently break Winter↔Stations.
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
        mid = snap_lattice(
            ((pa[pi][0] + pb[pj][0]) * 0.5, (pa[pi][1] + pb[pj][1]) * 0.5)
        )
        pa[pi] = mid
        pb[pj] = mid
        polys[ia] = _rebuild_octi(pa, STRAIGHT_CORRIDORS.get(a_name, {}).get("axis"))
        polys[ib] = _rebuild_octi(pb, STRAIGHT_CORRIDORS.get(b_name, {}).get("axis"))
        return True

    # Triple hub first: Ohringer + Winter + Stations should share one node.
    hub_names = ("Ohringerstrasse", "Winterthurerstrasse", "Stationsstrasse")
    if all(n in by_idx for n in hub_names):
        io, iw, is_ = by_idx[hub_names[0]], by_idx[hub_names[1]], by_idx[hub_names[2]]
        po, pw, ps = list(polys[io]), list(polys[iw]), list(polys[is_])
        o_end_i = len(po) - 1 if po[-1][0] >= po[0][0] else 0
        o_end = po[o_end_i]
        wi = min(range(len(pw)), key=lambda i: dist(pw[i], o_end))
        si = min(range(len(ps)), key=lambda i: dist(ps[i], pw[wi]))
        hub = snap_lattice(
            (
                (o_end[0] + pw[wi][0] + ps[si][0]) / 3.0,
                (o_end[1] + pw[wi][1] + ps[si][1]) / 3.0,
            )
        )

        def pin_vertex(
            pts: list[tuple[float, float]], idx: int, prefer: str | None = None
        ) -> list[tuple[float, float]]:
            """Move pts[idx] to hub; repair only the adjacent legs."""
            pts = list(pts)
            left = pts[:idx]
            right = pts[idx + 1 :]
            out: list[tuple[float, float]] = []
            if left:
                out.extend(left[:-1])
                out.extend(octilinear_leg(left[-1], hub, prefer_axis=prefer))
            else:
                out.append(hub)
            if right:
                # last point of out should be hub
                if not out or dist(out[-1], hub) >= 1.0:
                    out.append(hub)
                out.extend(octilinear_leg(hub, right[0], prefer_axis=prefer)[1:])
                out.extend(right[1:])
            elif not out or dist(out[-1], hub) >= 1.0:
                out.append(hub)
            return _dedupe_polyline(out)

        prefer_o = STRAIGHT_CORRIDORS.get("Ohringerstrasse", {}).get("axis")
        polys[io] = pin_vertex(po, o_end_i, prefer_o)
        polys[iw] = pin_vertex(pw, wi, None)
        polys[is_] = pin_vertex(ps, si, None)

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
        straight = octilinear_leg(
            start, hub_pt, prefer_axis=cfg.get("axis")
        )
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
                    break

    # One more junction pass after corridor straighten.
    for _ in range(3):
        changed = False
        for a_name, b_name in REQUIRED_JUNCTIONS:
            if pair_gap(a_name, b_name) >= 1.0:
                changed = snap_pair(a_name, b_name) or changed
        if not changed:
            break

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
