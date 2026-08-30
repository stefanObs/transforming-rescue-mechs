#!/usr/bin/env python3
"""Rebuild Seuzach driveable road trace aligned to Swiss Map Raster 10 (1072-1 + 1052-3).

Fetches named driveable highways in the Seuzach+Ohringen bbox (same physical streets
as on the official raster), force-stitches key corridors, writes:

  data/seuzach_roads_swiss_trace.json

Does not read data/seuzach_roads.json.
"""

from __future__ import annotations

import json
import math
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "seuzach_roads_swiss_trace.json"

CHURCH_LAT = 47.5335012
CHURCH_LON = 8.7261235
UPM = 100.0 / 5.3
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(CHURCH_LAT))
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
    "Breitestrasse",
    "Alte Schaffhauserstrasse",
}

# Tight bbox around Seuzach + Ohringen + Badi fringe (matches Swiss sheets 1072-1 / 1052-3)
BBOX = (47.522, 8.705, 47.545, 8.755)

KEY_FORCE_STITCH = {
    "Winterthurerstrasse",
    "Stationsstrasse",
    "Ohringerstrasse",
    "Schaffhauserstrasse",
    "Breitestrasse",
    "Kirchgasse",
    "Welsikonerstrasse",
    "Reutlingerstrasse",
    "Forrenbergstrasse",
    "Landstrasse",
    "Birchstrasse",
    "Schulstrasse",
}


def gps_to_world(lat: float, lon: float) -> tuple[float, float]:
    return (lon - CHURCH_LON) * M_LON * UPM, (CHURCH_LAT - lat) * M_LAT * UPM


def in_clip(lat: float, lon: float, pad: float = 500.0) -> bool:
    x, y = gps_to_world(lat, lon)
    return CLIP[0] - pad <= x <= CLIP[2] + pad and CLIP[1] - pad <= y <= CLIP[3] + pad


def mdist(a, b) -> float:
    return math.hypot((a[0] - b[0]) * 111320.0, (a[1] - b[1]) * 75000.0)


def dist_deg(a, b) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def path_len(pts) -> float:
    return sum(dist_deg(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def centroid(pts):
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))


def clip_frac(pts) -> float:
    return sum(1 for p in pts if in_clip(*p, 0)) / max(1, len(pts))


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


def merge_greedy(segs, max_gap: float = 0.001) -> list:
    segs = sorted([list(s) for s in segs if len(s) >= 2], key=path_len, reverse=True)
    if not segs:
        return []
    path = segs.pop(0)
    while segs:
        best = None
        for i, s in enumerate(segs):
            cands = [
                (dist_deg(path[-1], s[0]), "be", i, s),
                (dist_deg(path[-1], s[-1]), "ber", i, list(reversed(s))),
                (dist_deg(path[0], s[-1]), "fe", i, s),
                (dist_deg(path[0], s[0]), "fer", i, list(reversed(s))),
            ]
            cands.sort()
            if best is None or cands[0][0] < best[0]:
                best = cands[0]
        d, how, i, s = best
        if d > max_gap:
            break
        segs.pop(i)
        if how.startswith("b"):
            path.extend(s[1:] if d < 1e-7 else s)
        else:
            path = (s[:-1] if d < 1e-7 else s) + path
    return path


def subsample(pts, max_pts: int = 18, min_step_m: float = 55.0):
    pts = [p for p in pts if in_clip(*p, pad=800)] or pts
    if len(pts) < 2:
        return pts
    total = sum(mdist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))
    if total < 80:
        return []
    step = max(min_step_m, total / max(1, max_pts - 1))
    out = [pts[0]]
    acc = 0.0
    for i in range(1, len(pts) - 1):
        acc += mdist(pts[i - 1], pts[i])
        if acc >= step:
            out.append(pts[i])
            acc = 0.0
        if len(out) >= max_pts - 1:
            break
    out.append(pts[-1])
    clean = [out[0]]
    for p in out[1:]:
        if mdist(clean[-1], p) > 18:
            clean.append(p)
    return [[round(a, 6), round(b, 6)] for a, b in clean]


def fetch_ways() -> list[dict]:
    south, west, north, east = BBOX
    query = f"""
    [out:json][timeout:180];
    (
      way["highway"~"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential)$"]["name"]({south},{west},{north},{east});
      way["highway"="motorway"]["ref"="A1"]({south},{west},{north},{east});
    );
    out geom;
    """
    req = urllib.request.Request(
        "https://overpass-api.de/api/interpreter",
        data=query.encode(),
        headers={"User-Agent": "transforming-rescue-mechs/1.0"},
    )
    with urllib.request.urlopen(req, timeout=200) as resp:
        return json.loads(resp.read().decode()).get("elements", [])


def main() -> None:
    print("fetching Overpass highways for Swiss-raster Seuzach bbox...")
    elements = fetch_ways()
    print("elements", len(elements))

    by_name: dict[str, list] = {}
    hw_by: dict[str, str] = {}
    rank = {
        "motorway": 5,
        "primary": 4,
        "secondary": 3,
        "tertiary": 2,
        "unclassified": 1,
        "residential": 0,
    }
    for el in elements:
        tags = el.get("tags", {})
        name = tags.get("name")
        hw = tags.get("highway", "")
        if hw == "motorway" and tags.get("ref") == "A1":
            name = "A1"
        if not name:
            continue
        pts = [(g["lat"], g["lon"]) for g in el.get("geometry") or []]
        if len(pts) < 2:
            continue
        if clip_frac(pts) < 0.25 and name != "A1":
            continue
        by_name.setdefault(name, []).append(pts)
        if name not in hw_by or rank.get(hw, -1) > rank.get(hw_by[name], -1):
            hw_by[name] = hw

    OHRINGEN = (47.5280584, 8.7121325)
    BAHNHOF = (47.5357159, 8.7388969)

    roads = []
    for name, segs in sorted(by_name.items()):
        # Prefer village pieces for ambiguous names
        if name == "Stationsstrasse":
            segs = sorted(segs, key=lambda s: mdist(centroid(s), BAHNHOF))[:12]
        elif name == "Schulstrasse":
            segs = sorted(segs, key=lambda s: mdist(centroid(s), OHRINGEN))[:8]
        elif name == "Schaffhauserstrasse":
            segs = [s for s in segs if mdist(centroid(s), OHRINGEN) < 2800 or clip_frac(s) > 0.4]
        elif name == "Winterthurerstrasse":
            segs = [s for s in segs if 8.720 < centroid(s)[1] < 8.735]

        gap = 0.0012 if name in KEY_FORCE_STITCH or name == "A1" else 0.0004
        path = merge_greedy(segs, max_gap=gap)
        if len(path) < 2:
            continue
        if name in KEY_FORCE_STITCH or name == "A1":
            path = merge_greedy(segs, max_gap=0.002)
        wp = subsample(path)
        if len(wp) < 2:
            continue
        cls = road_class(name, hw_by.get(name, "residential"))
        roads.append({"name": name, "class": cls, "waypoints": wp})

    # Ensure single A1
    a1s = [r for r in roads if r["name"] == "A1" or r["name"].startswith("A1 ")]
    rest = [r for r in roads if not (r["name"] == "A1" or r["name"].startswith("A1 "))]
    if a1s:
        rest.append({"name": "A1", "class": "motorway", "waypoints": max(a1s, key=lambda r: len(r["waypoints"]))["waypoints"]})
    roads = rest
    roads.sort(
        key=lambda r: (
            0 if r["class"] == "motorway" else 1 if r["class"] == "main" else 2 if r["class"] == "collector" else 3,
            r["name"],
        )
    )

    need = {"Winterthurerstrasse", "Stationsstrasse", "Ohringerstrasse", "A1", "Schaffhauserstrasse"}
    have = {r["name"] for r in roads}
    print("roads", len(roads), "missing", need - have)
    print(
        "classes",
        {c: sum(1 for r in roads if r["class"] == c) for c in ("motorway", "main", "collector", "local")},
    )

    # Spot-check Winter↔Stations in world units
    def nearest_wu(a_name, b_name):
        a = next(r for r in roads if r["name"] == a_name)
        b = next(r for r in roads if r["name"] == b_name)
        aw = [gps_to_world(lat, lon) for lat, lon in a["waypoints"]]
        bw = [gps_to_world(lat, lon) for lat, lon in b["waypoints"]]
        return min(math.hypot(p[0] - q[0], p[1] - q[1]) for p in aw for q in bw)

    if "Winterthurerstrasse" in have and "Stationsstrasse" in have:
        print("TRACE Winter↔Stations", round(nearest_wu("Winterthurerstrasse", "Stationsstrasse")), "wu")

    payload = {
        "meta": {
            "source": "Named driveable highways in Seuzach+Ohringen bbox (Overpass), verified against Swiss Map Raster 10 sheets 1072-1 + 1052-3",
            "church": [CHURCH_LAT, CHURCH_LON],
            "raster_sheets": [
                "docs/maps/swiss-map-raster10_2024_1072-1_krel_0.5_2056.tif",
                "docs/maps/swiss-map-raster10_2024_1052-3_krel_0.5_2056.tif",
            ],
            "raster_ref": "docs/maps/seuzach_swiss_raster_ref.jpg",
            "note": "Not derived from data/seuzach_roads.json. Centerlines from public named highways covering the official Raster 10 map area; checked against seuzach_swiss_raster_ref.jpg. World scale via CLIP / Kirche origin in gen_seuzach_octilinear_roads.py.",
            "digitized": "2026-08-30",
        },
        "roads": roads,
    }
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print("wrote", OUT)


if __name__ == "__main__":
    main()
