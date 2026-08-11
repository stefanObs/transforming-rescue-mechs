#!/usr/bin/env python3
"""OSM Overpass-Dump → data/seuzach_roads.json (Maps-Strassennetz, Feldskala)."""

from __future__ import annotations

import json
import math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "data" / "seuzach_ways.json"
OUT = ROOT / "data" / "seuzach_roads.json"

CHURCH_LAT = 47.5335012
CHURCH_LON = 8.7261235
FIELD_M = 5.3
FIELD_WU = 100.0
UPM = FIELD_WU / FIELD_M
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(CHURCH_LAT))

CONNECT_WU = 90.0
SIMPLIFY_WU = 28.0
MIN_LEN_WU = 140.0
JUNCTION_SNAP = 120.0

# Playable: Seuzach-Dorf + Ohringen + Forrenberg (A1), nicht Winterthur/Dinhard-Tails.
CLIP = (-25000.0, -24000.0, 32000.0, 18000.0)

FORCE_MAIN = {
    "Winterthurerstrasse",
    "Ohringerstrasse",
    "Stationsstrasse",
    "Welsikonerstrasse",
    "Schaffhauserstrasse",
    "Rietstrasse",
}
FORCE_COLLECTOR = {
    "Landstrasse",
    "Reutlingerstrasse",
    "Stadlerstrasse",
    "Hettlingerstrasse",
    "Forrenbergstrasse",
    "Südabfahrt",
    "Etzwilerstrasse",
    "Wiesendangerstrasse",
}


def gps_to_world(lat: float, lon: float) -> tuple[float, float]:
    x = (lon - CHURCH_LON) * M_LON * UPM
    y = (CHURCH_LAT - lat) * M_LAT * UPM
    return x, y


def dist(a, b) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def path_len(pts) -> float:
    return sum(dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def rdp(points, epsilon: float):
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


ALLOWED_HIGHWAY = {
    "motorway",
    "trunk",
    "primary",
    "secondary",
    "tertiary",
    "unclassified",
    "residential",
}


def road_name(tags: dict) -> str | None:
    hw = tags.get("highway", "")
    if hw not in ALLOWED_HIGHWAY:
        return None
    if hw == "motorway" and tags.get("ref") == "A1":
        return "A1"
    name = (tags.get("name") or "").strip()
    if not name:
        return None
    return name


def road_class(name: str, hw: str) -> str:
    if name == "A1" or hw == "motorway":
        return "motorway"
    if name in FORCE_MAIN:
        return "main"
    if name in FORCE_COLLECTOR:
        return "collector"
    if hw in ("primary", "secondary"):
        return "main"
    if hw in ("tertiary", "unclassified"):
        return "collector"
    return "local"


def half_w_for(cls: str) -> float:
    return {"motorway": 110.0, "main": 72.0, "collector": 52.0, "local": 36.0}[cls]


def merge_polylines(segments: list[list[tuple[float, float]]]) -> list[list[tuple[float, float]]]:
    segs = [list(s) for s in segments if len(s) >= 2]
    changed = True
    while changed:
        changed = False
        i = 0
        while i < len(segs):
            a = segs[i]
            j = i + 1
            merged = False
            while j < len(segs):
                b = segs[j]
                pairs = [
                    (dist(a[-1], b[0]), a + b[1:]),
                    (dist(a[-1], b[-1]), a + list(reversed(b))[1:]),
                    (dist(a[0], b[-1]), b + a[1:]),
                    (dist(a[0], b[0]), list(reversed(b)) + a[1:]),
                ]
                pairs.sort(key=lambda t: t[0])
                if pairs[0][0] <= CONNECT_WU:
                    segs[i] = pairs[0][1]
                    segs.pop(j)
                    changed = True
                    merged = True
                    break
                j += 1
            if not merged:
                i += 1
    return segs


def _inside(p, clip) -> bool:
    x0, y0, x1, y1 = clip
    return x0 <= p[0] <= x1 and y0 <= p[1] <= y1


def _liang_barsky(a, b, clip):
    x0, y0, x1, y1 = clip
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    p = [-dx, dx, -dy, dy]
    q = [a[0] - x0, x1 - a[0], a[1] - y0, y1 - a[1]]
    u1, u2 = 0.0, 1.0
    for pi, qi in zip(p, q):
        if abs(pi) < 1e-12:
            if qi < 0:
                return None
            continue
        t = qi / pi
        if pi < 0:
            u1 = max(u1, t)
        else:
            u2 = min(u2, t)
        if u1 > u2:
            return None
    return (a[0] + u1 * dx, a[1] + u1 * dy), (a[0] + u2 * dx, a[1] + u2 * dy)


def clip_polyline(pts, clip) -> list[list[tuple[float, float]]]:
    pieces: list[list[tuple[float, float]]] = []
    cur: list[tuple[float, float]] = []
    for i in range(len(pts) - 1):
        clipped = _liang_barsky(pts[i], pts[i + 1], clip)
        if clipped is None:
            if len(cur) >= 2:
                pieces.append(cur)
            cur = []
            continue
        c0, c1 = clipped
        if not cur:
            cur = [c0, c1]
        else:
            if dist(cur[-1], c0) > 2.0:
                if len(cur) >= 2:
                    pieces.append(cur)
                cur = [c0, c1]
            else:
                cur.append(c1)
    if len(cur) >= 2:
        pieces.append(cur)
    return pieces


def cluster_junctions(roads) -> list[list[float]]:
    buckets: dict[tuple[int, int], list] = defaultdict(list)
    cell = JUNCTION_SNAP
    for r in roads:
        hw = half_w_for(r["class"])
        seen = set()
        for x, y in r["points"]:
            key = (int(round(x / cell)), int(round(y / cell)))
            if key in seen:
                continue
            seen.add(key)
            buckets[key].append((r["name"], hw, x, y))
    junctions = []
    used = set()
    keys = list(buckets.keys())
    for key in keys:
        if key in used:
            continue
        items = list(buckets[key])
        # merge neighbour cells
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                nk = (key[0] + dx, key[1] + dy)
                if nk == key or nk not in buckets:
                    continue
                items.extend(buckets[nk])
                used.add(nk)
        used.add(key)
        names = {it[0] for it in items}
        if len(names) < 2:
            continue
        sx = sum(it[2] for it in items) / len(items)
        sy = sum(it[3] for it in items) / len(items)
        hw = max(it[1] for it in items)
        junctions.append([round(sx, 1), round(sy, 1), round(hw + 8.0, 1)])
    return junctions


def main() -> None:
    data = json.loads(SRC.read_text())
    by_name: dict[str, list] = defaultdict(list)
    hw_by_name: dict[str, str] = {}
    for el in data["elements"]:
        tags = el.get("tags") or {}
        geom = el.get("geometry") or []
        if len(geom) < 2:
            continue
        name = road_name(tags)
        if not name:
            continue
        pts = [gps_to_world(p["lat"], p["lon"]) for p in geom]
        by_name[name].append(pts)
        hw = tags.get("highway", "")
        prev = hw_by_name.get(name)
        rank = {
            "motorway": 5,
            "trunk": 4,
            "primary": 3,
            "secondary": 3,
            "tertiary": 2,
            "unclassified": 1,
            "residential": 0,
        }
        if prev is None or rank.get(hw, -1) > rank.get(prev, -1):
            hw_by_name[name] = hw

    roads = []
    for name, segs in sorted(by_name.items()):
        cls = road_class(name, hw_by_name.get(name, "residential"))
        clipped: list[list[tuple[float, float]]] = []
        for poly in merge_polylines(segs):
            clipped.extend(clip_polyline(poly, CLIP))
        for poly in merge_polylines(clipped):
            simp = rdp(poly, SIMPLIFY_WU)
            if len(simp) < 2 or path_len(simp) < MIN_LEN_WU:
                continue
            roads.append(
                {
                    "name": name,
                    "class": cls,
                    "points": [[round(x, 1), round(y, 1)] for x, y in simp],
                }
            )

    junctions = cluster_junctions(roads)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "meta": {
            "source": "OSM Overpass highway named + A1",
            "church": [CHURCH_LAT, CHURCH_LON],
            "field_m": FIELD_M,
            "field_wu": FIELD_WU,
            "clip": list(CLIP),
        },
        "roads": roads,
        "junctions": junctions,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(f"wrote {OUT} roads={len(roads)} junctions={len(junctions)}")
    names = sorted({r["name"] for r in roads})
    print("names", len(names))
    xs = [p[0] for r in roads for p in r["points"]]
    ys = [p[1] for r in roads for p in r["points"]]
    print(f"bbox x {min(xs):.0f}..{max(xs):.0f}  y {min(ys):.0f}..{max(ys):.0f}")
    must = [
        "A1",
        "Winterthurerstrasse",
        "Ohringerstrasse",
        "Stationsstrasse",
        "Forrenbergstrasse",
        "Kirchhügelstrasse",
        "Birchstrasse",
    ]
    for n in must:
        print(f"  has {n}: {n in names}")


if __name__ == "__main__":
    main()
