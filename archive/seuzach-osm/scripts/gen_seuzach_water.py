#!/usr/bin/env python3
"""OSM Overpass-Dump → data/seuzach_water.json (benannte Bäche, Feldskala)."""

from __future__ import annotations

import json
import math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "data" / "seuzach_water_osm.json"
OUT = ROOT / "data" / "seuzach_water.json"

CHURCH_LAT = 47.5335012
CHURCH_LON = 8.7261235
FIELD_M = 5.3
FIELD_WU = 100.0
UPM = FIELD_WU / FIELD_M
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(CHURCH_LAT))

CONNECT_WU = 90.0
SIMPLIFY_WU = 22.0
MIN_LEN_WU = 400.0
MIN_LEN_PRIORITY_WU = 140.0

# Playable: Seuzach-Dorf + Ohringen + Forrenberg (A1), nicht Winterthur-Tails.
CLIP = (-25000.0, -24000.0, 32000.0, 18000.0)

KEEP_WATERWAY = {"stream", "river", "drain"}
DROP_WATERWAY = {"ditch", "canal", "abandoned", "disused"}
PRIORITY_NAMES = {
    "Chrebsbach",
    "Welsikonerbach",
    "Bachtobelgraben",
    "Ohringerbach",
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


def _round_pts(pts) -> list[list[float]]:
    return [[round(x, 1), round(y, 1)] for x, y in pts]


def _geom_world(el: dict) -> list[tuple[float, float]]:
    geom = el.get("geometry") or []
    return [gps_to_world(float(p["lat"]), float(p["lon"])) for p in geom]


def _dist_to_polyline(p, pts) -> float:
    best = dist(p, pts[0])
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        ax, ay = a
        bx, by = b
        px, py = p
        abx, aby = bx - ax, by - ay
        len2 = abx * abx + aby * aby
        if len2 < 1e-9:
            best = min(best, dist(p, a))
            continue
        t = max(0.0, min(1.0, ((px - ax) * abx + (py - ay) * aby) / len2))
        best = min(best, dist(p, (ax + t * abx, ay + t * aby)))
    return best


def _ends_dock(pts, named_pts) -> float:
    return min(_dist_to_polyline(pts[0], named_pts), _dist_to_polyline(pts[-1], named_pts))


def _is_abandoned(tags: dict) -> bool:
    ww = str(tags.get("waterway") or "")
    if ww in ("abandoned", "disused"):
        return True
    if tags.get("abandoned") in ("yes", "true", "1"):
        return True
    return False


def _keep_way(tags: dict) -> bool:
    ww = str(tags.get("waterway") or "")
    if ww not in KEEP_WATERWAY:
        return False
    if ww in DROP_WATERWAY:
        return False
    if _is_abandoned(tags):
        return False
    if tags.get("leisure") == "swimming_pool":
        return False
    if tags.get("natural") == "water":
        return False
    return True


def _min_len_for(name: str) -> float:
    if name in PRIORITY_NAMES:
        return MIN_LEN_PRIORITY_WU
    return MIN_LEN_WU


def _build_named_polys(
    segments: list[list[tuple[float, float]]], name: str
) -> list[list[tuple[float, float]]]:
    clipped: list[list[tuple[float, float]]] = []
    for poly in merge_polylines(segments):
        clipped.extend(clip_polyline(poly, CLIP))
    out: list[list[tuple[float, float]]] = []
    min_len = _min_len_for(name)
    for poly in merge_polylines(clipped):
        simp = rdp(poly, SIMPLIFY_WU)
        if len(simp) < 2 or path_len(simp) < min_len:
            continue
        out.append(simp)
    out.sort(key=path_len, reverse=True)
    return out


def _iter_way_elements(data: dict):
    seen: set[int] = set()
    for el in data.get("elements") or []:
        if el.get("type") == "way":
            eid = int(el.get("id") or 0)
            if eid in seen:
                continue
            seen.add(eid)
            yield el
            continue
        if el.get("type") != "relation":
            continue
        for mem in el.get("members") or []:
            if mem.get("type") != "way":
                continue
            geom = mem.get("geometry") or []
            if len(geom) < 2:
                continue
            mid = int(mem.get("ref") or 0)
            if mid in seen:
                continue
            seen.add(mid)
            tags = dict(el.get("tags") or {})
            tags.update(mem.get("tags") or {})
            yield {"type": "way", "id": mid, "tags": tags, "geometry": geom}


def _attach_unnamed(
    named: dict[str, list[list[tuple[float, float]]]],
    unnamed: list[list[tuple[float, float]]],
) -> int:
    attached = 0
    pending = list(unnamed)
    changed = True
    while changed:
        changed = False
        still: list[list[tuple[float, float]]] = []
        for pts in pending:
            best_name = None
            best_d = CONNECT_WU
            for name, segs in named.items():
                for seg in segs:
                    d = _ends_dock(pts, seg)
                    if d <= best_d:
                        best_d = d
                        best_name = name
            if best_name is not None:
                named[best_name].append(pts)
                attached += 1
                changed = True
            else:
                still.append(pts)
        pending = still
    return attached


def main() -> None:
    data = json.loads(SRC.read_text())
    named: dict[str, list[list[tuple[float, float]]]] = defaultdict(list)
    unnamed: list[list[tuple[float, float]]] = []
    waterway_of: dict[str, str] = {}

    for el in _iter_way_elements(data):
        tags = el.get("tags") or {}
        if not _keep_way(tags):
            continue
        pts = _geom_world(el)
        if len(pts) < 2:
            continue
        name = str(tags.get("name") or "").strip()
        ww = str(tags.get("waterway") or "stream")
        if name:
            named[name].append(pts)
            if name not in waterway_of or ww == "river":
                waterway_of[name] = ww
        else:
            unnamed.append(pts)

    attached = _attach_unnamed(named, unnamed)

    streams: list[dict] = []
    for name in sorted(named.keys()):
        ww = waterway_of.get(name, "stream")
        for poly in _build_named_polys(named[name], name):
            streams.append(
                {
                    "name": name,
                    "waterway": ww,
                    "points": _round_pts(poly),
                }
            )

    streams.sort(key=lambda s: path_len([(p[0], p[1]) for p in s["points"]]), reverse=True)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "meta": {
            "source": "OSM Overpass waterway=stream|river|drain",
            "church": [CHURCH_LAT, CHURCH_LON],
            "field_m": FIELD_M,
            "field_wu": FIELD_WU,
            "clip": list(CLIP),
        },
        "streams": streams,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

    names = sorted({s["name"] for s in streams})
    print(
        f"wrote {OUT} streams={len(streams)} names={len(names)} "
        f"unnamed_attached={attached}"
    )
    print("  names:", ", ".join(names) if names else "(none)")
    sample_chreb = gps_to_world(47.5330924, 8.7386221)
    sample_wels = gps_to_world(47.5393883, 8.7320363)
    ried = 0
    for s in streams:
        pts = [(p[0], p[1]) for p in s["points"]]
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        print(
            f"  {s['name']} ww={s['waterway']} n={len(pts)} "
            f"len={path_len(pts):.0f} x {min(xs):.0f}..{max(xs):.0f} "
            f"y {min(ys):.0f}..{max(ys):.0f}"
        )
        if s["name"] == "Chrebsbach":
            print(f"    dist chrebsbach sample={_dist_to_polyline(sample_chreb, pts):.1f}")
        if s["name"] == "Welsikonerbach":
            print(f"    dist welsikonerbach sample={_dist_to_polyline(sample_wels, pts):.1f}")
        if s["name"] == "Riedbach":
            ried += 1
    print(f"  Riedbach tracks={ried}")


if __name__ == "__main__":
    main()
