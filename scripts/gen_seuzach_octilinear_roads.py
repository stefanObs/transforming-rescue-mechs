#!/usr/bin/env python3
"""Google Maps WGS84 trace → octilinear seuzach_roads JSON + big SVG.

Input:  data/seuzach_roads_gmaps_trace.json
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
SRC = ROOT / "data" / "seuzach_roads_gmaps_trace.json"
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
JUNCTION_SNAP = 250.0
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


def octilinear_leg(a: tuple[float, float], b: tuple[float, float]) -> list[tuple[float, float]]:
    """Connect a→b with one or two octilinear segments (H/V/45°)."""
    a = snap_lattice(a)
    b = snap_lattice(b)
    if dist(a, b) < 1.0:
        return [a]

    dx = b[0] - a[0]
    dy = b[1] - a[1]
    direct = nearest_octilinear(bearing_deg(a, b))
    ux, uy = dir_vec(direct)
    # Project onto snapped direction; if residual is large, use two-leg L/45 path.
    proj = dx * ux + dy * uy
    mid = (a[0] + ux * proj, a[1] + uy * proj)
    mid = snap_lattice(mid)
    residual = dist(mid, b)

    if residual <= LATTICE * 0.6:
        # Single leg: end exactly at b along octilinear if possible
        if abs(dx) < 1e-6 or abs(dy) < 1e-6 or abs(abs(dx) - abs(dy)) < LATTICE * 0.6:
            return [a, b]
        # Force exact octilinear by choosing axis-aligned or 45° two-leg
        pass

    # Two-leg candidates: axis-then-axis, or axis-then-diagonal
    candidates: list[list[tuple[float, float]]] = []
    # H then V
    candidates.append([a, snap_lattice((b[0], a[1])), b])
    # V then H
    candidates.append([a, snap_lattice((a[0], b[1])), b])
    # Match |dx| on 45° then finish axis
    if abs(dx) >= 1.0 and abs(dy) >= 1.0:
        s = math.copysign(min(abs(dx), abs(dy)), dx)
        t = math.copysign(abs(s), dy)
        m1 = snap_lattice((a[0] + s, a[1] + t))
        candidates.append([a, m1, b])
        # Prefer finishing the longer axis first
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
            ang = bearing_deg(path[i], path[i + 1])
            if abs((ang - nearest_octilinear(ang) + 180) % 360 - 180) > ANGLE_EPS_DEG:
                return False
        return True

    def path_err(path: list[tuple[float, float]]) -> float:
        # Prefer short total length + few corners
        length = sum(dist(path[i], path[i + 1]) for i in range(len(path) - 1))
        return length + 40.0 * (len(path) - 2)

    best = None
    best_e = 1e18
    for cand in candidates:
        # Dedup consecutive
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
        # Fallback: H then V (always octilinear)
        mid = snap_lattice((b[0], a[1]))
        best = [a, mid, b] if dist(a, mid) >= 1.0 and dist(mid, b) >= 1.0 else [a, b]
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


def octilinearize_polyline(pts: list[tuple[float, float]]) -> list[tuple[float, float]]:
    if len(pts) < 2:
        return [snap_lattice(p) for p in pts]
    snapped = [snap_lattice(p) for p in pts]
    clean = [snapped[0]]
    for p in snapped[1:]:
        if dist(clean[-1], p) >= LATTICE * 0.5:
            clean.append(p)
    if len(clean) < 2:
        return clean
    # Aggressive simplify so long corridors become few long octilinear legs (not staircases).
    clean = rdp(clean, LATTICE * 2.5)
    clean = [snap_lattice(p) for p in clean]

    out: list[tuple[float, float]] = [clean[0]]
    for i in range(len(clean) - 1):
        leg = octilinear_leg(out[-1], clean[i + 1])
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
        # Merge nearby keys
        cluster = list(items)
        used.add(key)
        kx, ky = key
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                nk = (kx + dx, ky + dy)
                if nk == key or nk in used or nk not in buckets:
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
        f'fill="#555">Schematic octilinear streets digitized from Google Maps; '
        f'world scale matches project CLIP (Kirche origin). Not live game roads.</text>'
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
    raw = json.loads(SRC.read_text(encoding="utf-8"))
    roads_out: list[dict] = []
    for r in raw["roads"]:
        wpts = r["waypoints"]
        world = [gps_to_world(lat, lon) for lat, lon in wpts]
        world = clip_polyline(world)
        if len(world) < 2:
            continue
        octi = octilinearize_polyline(world)
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

    validate_octilinear(roads_out)
    junctions = cluster_junctions(roads_out)

    payload = {
        "meta": {
            "source": "Google Maps digitization → octilinear (H/V/45°)",
            "trace": "data/seuzach_roads_gmaps_trace.json",
            "church": [CHURCH_LAT, CHURCH_LON],
            "field_m": FIELD_M,
            "field_wu": FIELD_WU,
            "clip": list(CLIP),
            "lattice_wu": LATTICE,
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
