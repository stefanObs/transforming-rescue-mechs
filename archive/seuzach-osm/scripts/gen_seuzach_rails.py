#!/usr/bin/env python3
"""OSM Overpass-Dump → data/seuzach_rails.json (SBB 821 Gleise, Feldskala)."""

from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "data" / "seuzach_rails_osm.json"
OUT = ROOT / "data" / "seuzach_rails.json"

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

# Playable: Seuzach-Dorf + Ohringen + Forrenberg (A1), nicht Winterthur/Dinhard-Tails.
CLIP = (-25000.0, -24000.0, 32000.0, 18000.0)

# OSM way ids from S09 (tag filter is authoritative; ids are documentation).
THROUGH_WAY_IDS = {32210620, 116582468, 13872887, 13872886, 237404661, 237404663}
LOOP_WAY_ID = 116582444
PLATFORM_WAY_ID = 116582447


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


def _round_pts(pts) -> list[list[float]]:
    return [[round(x, 1), round(y, 1)] for x, y in pts]


def _geom_world(el: dict) -> list[tuple[float, float]]:
    geom = el.get("geometry") or []
    return [gps_to_world(float(p["lat"]), float(p["lon"])) for p in geom]


def _is_abandoned(tags: dict) -> bool:
    rw = str(tags.get("railway") or "")
    if rw in ("abandoned", "disused"):
        return True
    if tags.get("abandoned") in ("yes", "true", "1"):
        return True
    return False


def _is_through(el: dict, tags: dict) -> bool:
    if tags.get("railway") != "rail":
        return False
    if _is_abandoned(tags):
        return False
    if str(tags.get("ref") or "") != "821":
        return False
    if "service" in tags:
        return False
    return True


def _is_loop(el: dict, tags: dict) -> bool:
    if tags.get("railway") != "rail":
        return False
    if _is_abandoned(tags):
        return False
    if el.get("id") == LOOP_WAY_ID:
        return True
    return str(tags.get("railway:track_ref") or "") == "2"


def _is_platform2(el: dict, tags: dict) -> bool:
    if tags.get("railway") != "platform":
        return False
    if el.get("id") == PLATFORM_WAY_ID:
        return True
    return str(tags.get("ref") or "") == "2"


def _build_track_polys(segments: list[list[tuple[float, float]]]) -> list[list[tuple[float, float]]]:
    clipped: list[list[tuple[float, float]]] = []
    for poly in merge_polylines(segments):
        clipped.extend(clip_polyline(poly, CLIP))
    out: list[list[tuple[float, float]]] = []
    for poly in merge_polylines(clipped):
        simp = rdp(poly, SIMPLIFY_WU)
        if len(simp) < 2 or path_len(simp) < MIN_LEN_WU:
            continue
        out.append(simp)
    out.sort(key=path_len, reverse=True)
    return out


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


def main() -> None:
    data = json.loads(SRC.read_text())
    through_segs: list[list[tuple[float, float]]] = []
    loop_segs: list[list[tuple[float, float]]] = []
    platforms: list[dict] = []
    saw_ids: set[int] = set()

    for el in data.get("elements") or []:
        if el.get("type") != "way":
            continue
        tags = el.get("tags") or {}
        pts = _geom_world(el)
        if len(pts) < 2:
            continue
        eid = int(el.get("id") or 0)
        if _is_loop(el, tags):
            loop_segs.append(pts)
            saw_ids.add(eid)
            continue
        if _is_through(el, tags):
            through_segs.append(pts)
            saw_ids.add(eid)
            continue
        if _is_platform2(el, tags):
            ring = list(pts)
            if len(ring) >= 2 and dist(ring[0], ring[-1]) < 2.0:
                ring = ring[:-1]
            if len(ring) >= 3:
                platforms.append({"ref": "2", "points": _round_pts(ring)})
            saw_ids.add(eid)

    tracks: list[dict] = []
    for poly in _build_track_polys(through_segs):
        tracks.append(
            {
                "name": "SBB 821",
                "ref": "821",
                "track_ref": "1",
                "role": "through",
                "points": _round_pts(poly),
            }
        )
    for poly in _build_track_polys(loop_segs):
        tracks.append(
            {
                "name": "SBB 821 Gleis 2",
                "ref": "821",
                "track_ref": "2",
                "role": "loop",
                "points": _round_pts(poly),
            }
        )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "meta": {
            "source": "OSM Overpass railway=rail ref=821",
            "church": [CHURCH_LAT, CHURCH_LON],
            "field_m": FIELD_M,
            "field_wu": FIELD_WU,
            "clip": list(CLIP),
        },
        "tracks": tracks,
        "platforms": platforms,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

    print(f"wrote {OUT} tracks={len(tracks)} platforms={len(platforms)}")
    missing = (THROUGH_WAY_IDS | {LOOP_WAY_ID, PLATFORM_WAY_ID}) - saw_ids
    if missing:
        print("missing expected OSM ids", sorted(missing))
    stop1 = gps_to_world(47.5358162, 8.7389630)
    stop2 = gps_to_world(47.5358434, 8.7390122)
    for t in tracks:
        pts = [(p[0], p[1]) for p in t["points"]]
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        print(
            f"  {t['role']} track_ref={t['track_ref']} n={len(pts)} "
            f"len={path_len(pts):.0f} x {min(xs):.0f}..{max(xs):.0f} "
            f"y {min(ys):.0f}..{max(ys):.0f}"
        )
        if t["track_ref"] == "1":
            print(f"    dist stop1={_dist_to_polyline(stop1, pts):.1f}")
        if t["track_ref"] == "2":
            print(f"    dist stop2={_dist_to_polyline(stop2, pts):.1f}")


if __name__ == "__main__":
    main()
