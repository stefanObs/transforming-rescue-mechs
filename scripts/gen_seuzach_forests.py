#!/usr/bin/env python3
"""OSM Overpass-Dump → data/seuzach_forests.json (Waldflächen, Feldskala)."""

from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "data" / "seuzach_forests_osm.json"
WATER_SRC = ROOT / "data" / "seuzach_water.json"
OUT = ROOT / "data" / "seuzach_forests.json"

CHURCH_LAT = 47.5335012
CHURCH_LON = 8.7261235
FIELD_M = 5.3
FIELD_WU = 100.0
UPM = FIELD_WU / FIELD_M
M_LAT = 111320.0
M_LON = 111320.0 * math.cos(math.radians(CHURCH_LAT))

SIMPLIFY_WU = 48.0
MIN_AREA_WU2 = 400000.0
MAX_SILHOUETTES = 8
STREAM_A_CLEAR_WU = 400.0
STREAM_B_CLEAR_WU = 800.0
ANCHOR_CLEAR_WU = 500.0
HUB_CLEAR_WU = 400.0

# Playable: Seuzach-Dorf + Ohringen + Forrenberg (A1), nicht Winterthur-Tails.
CLIP = (-25000.0, -24000.0, 32000.0, 18000.0)

DROP_NATURAL = {"tree", "scrub"}
DROP_LANDUSE = {"orchard", "vineyard", "meadow"}
DROP_LEISURE = {"garden", "park"}

# Same GPS as scripts/seuzach_geo.gd — keep silhouettes off buildings / enter zone.
BAHNHOF = (47.5357159, 8.7388969)
BIRCH_A = (47.5352696, 8.7368319)
BIRCH_B = (47.5351495, 8.7362716)
BIRCH_GYM = (47.5354751, 8.7362554)
RIET_A = (47.5360788, 8.7273791)
RIET_B = (47.5365102, 8.7275595)
RIET_GYM = (47.5361323, 8.7262616)
OHR_A = (47.5283478, 8.7123497)
OHR_B = (47.5281003, 8.7125046)
OHR_GYM = (47.5279647, 8.7122618)
FORRENBERG = (47.5263004, 8.7353138)
BADI = (47.5393193, 8.7333710)
KIGA_BACHTOBEL = (47.5376225, 8.7380927)
KIGA_WEID = (47.5330589, 8.7379167)
KIGA_SCHNECKE = (47.5347527, 8.7310559)
KIGA_OHRINGEN = (47.5278851, 8.7126832)
HUB_ENTER_SOUTH_WU = 320.0

VILLAGE_EDGE_NAMES = {"Buechwäldli", "Laubholz"}
## Clip tails of Winterthur forests may remain as floors; do not steal silhouette slots.
WINTERTHUR_NAMES = {
    "Lindberg",
    "Wolfensberg",
    "Schoren",
    "Stadlerberg",
    "Fröschholz",
    "Eschberg",
}


def gps_to_world(lat: float, lon: float) -> tuple[float, float]:
    x = (lon - CHURCH_LON) * M_LON * UPM
    y = (CHURCH_LAT - lat) * M_LAT * UPM
    return x, y


def dist(a, b) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


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


def _drop_closing_dup(pts: list[tuple[float, float]]) -> list[tuple[float, float]]:
    if len(pts) >= 2 and dist(pts[0], pts[-1]) <= 2.0:
        return pts[:-1]
    return pts


def _dedupe_consecutive(pts: list[tuple[float, float]]) -> list[tuple[float, float]]:
    out: list[tuple[float, float]] = []
    for p in pts:
        if not out or dist(out[-1], p) > 1.0:
            out.append(p)
    return out


def poly_area(pts) -> float:
    if len(pts) < 3:
        return 0.0
    s = 0.0
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        s += x1 * y2 - x2 * y1
    return abs(s) * 0.5


def poly_centroid(pts) -> tuple[float, float]:
    if not pts:
        return 0.0, 0.0
    a2 = 0.0
    cx = 0.0
    cy = 0.0
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        cross = x1 * y2 - x2 * y1
        a2 += cross
        cx += (x1 + x2) * cross
        cy += (y1 + y2) * cross
    if abs(a2) < 1e-6:
        return (
            sum(p[0] for p in pts) / len(pts),
            sum(p[1] for p in pts) / len(pts),
        )
    return cx / (3.0 * a2), cy / (3.0 * a2)


def _intersect_x(a, b, x: float) -> tuple[float, float]:
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    t = 0.0 if abs(dx) < 1e-12 else (x - a[0]) / dx
    return x, a[1] + t * dy


def _intersect_y(a, b, y: float) -> tuple[float, float]:
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    t = 0.0 if abs(dy) < 1e-12 else (y - a[1]) / dy
    return a[0] + t * dx, y


def _clip_edge(pts, inside, intersect) -> list[tuple[float, float]]:
    if not pts:
        return []
    out: list[tuple[float, float]] = []
    prev = pts[-1]
    prev_in = inside(prev)
    for cur in pts:
        cur_in = inside(cur)
        if cur_in:
            if not prev_in:
                out.append(intersect(prev, cur))
            out.append(cur)
        elif prev_in:
            out.append(intersect(prev, cur))
        prev = cur
        prev_in = cur_in
    return out


def clip_polygon(pts, clip) -> list[tuple[float, float]]:
    xmin, ymin, xmax, ymax = clip
    ring = _drop_closing_dup(list(pts))
    ring = _clip_edge(ring, lambda p: p[0] >= xmin, lambda a, b: _intersect_x(a, b, xmin))
    ring = _clip_edge(ring, lambda p: p[0] <= xmax, lambda a, b: _intersect_x(a, b, xmax))
    ring = _clip_edge(ring, lambda p: p[1] >= ymin, lambda a, b: _intersect_y(a, b, ymin))
    ring = _clip_edge(ring, lambda p: p[1] <= ymax, lambda a, b: _intersect_y(a, b, ymax))
    return _dedupe_consecutive(_drop_closing_dup(ring))


def simplify_ring(pts) -> list[tuple[float, float]]:
    ## Open ring: closing first==last makes RDP's baseline degenerate (all d=0).
    ring = _drop_closing_dup(list(pts))
    if len(ring) < 3:
        return ring
    simp = rdp(ring, SIMPLIFY_WU)
    return _dedupe_consecutive(_drop_closing_dup(simp))


def _round_pts(pts) -> list[list[float]]:
    return [[round(x, 1), round(y, 1)] for x, y in pts]


def _geom_world(geom) -> list[tuple[float, float]]:
    return [gps_to_world(float(p["lat"]), float(p["lon"])) for p in (geom or [])]


def _is_abandoned(tags: dict) -> bool:
    if tags.get("abandoned") in ("yes", "true", "1"):
        return True
    if str(tags.get("landuse") or "") in ("abandoned",):
        return True
    return False


def _keep_forest(tags: dict) -> bool:
    if _is_abandoned(tags):
        return False
    nat = str(tags.get("natural") or "")
    lu = str(tags.get("landuse") or "")
    if nat in DROP_NATURAL:
        return False
    if lu in DROP_LANDUSE:
        return False
    leisure = str(tags.get("leisure") or "")
    if leisure in DROP_LEISURE and lu != "forest" and nat != "wood":
        return False
    return lu == "forest" or nat == "wood"


def _osm_kind(tags: dict) -> str:
    if str(tags.get("landuse") or "") == "forest":
        return "forest"
    return "wood"


def _point_in_ring(p, pts) -> bool:
    if len(pts) < 3:
        return False
    x, y = p
    inside = False
    n = len(pts)
    j = n - 1
    for i in range(n):
        xi, yi = pts[i]
        xj, yj = pts[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) or 1e-12) + xi):
            inside = not inside
        j = i
    return inside


def _dist_to_polyline(p, pts) -> float:
    if not pts:
        return 1.0e18
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


def _dist_to_streams(p, streams: list[list[tuple[float, float]]]) -> float:
    if not streams:
        return 1.0e18
    return min(_dist_to_polyline(p, s) for s in streams)


def _load_stream_polylines() -> list[list[tuple[float, float]]]:
    if not WATER_SRC.exists():
        return []
    data = json.loads(WATER_SRC.read_text())
    out: list[list[tuple[float, float]]] = []
    for rec in data.get("streams") or []:
        pts = []
        for p in rec.get("points") or []:
            if isinstance(p, list) and len(p) >= 2:
                pts.append((float(p[0]), float(p[1])))
        if len(pts) >= 2:
            out.append(pts)
    return out


def _merge_polylines(segments: list[list[tuple[float, float]]], connect_wu: float):
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
                if pairs[0][0] <= connect_wu:
                    segs[i] = pairs[0][1]
                    segs.pop(j)
                    changed = True
                    merged = True
                    break
                j += 1
            if not merged:
                i += 1
    return segs


def _assemble_rings(segments: list[list[tuple[float, float]]]) -> list[list[tuple[float, float]]]:
    rings: list[list[tuple[float, float]]] = []
    for poly in _merge_polylines(segments, 4.0):
        ring = _drop_closing_dup(poly)
        if len(ring) >= 3:
            rings.append(ring)
    return rings


def _finish_ring(pts: list[tuple[float, float]]) -> list[tuple[float, float]] | None:
    clipped = clip_polygon(pts, CLIP)
    simp = simplify_ring(clipped)
    if len(simp) < 3:
        return None
    if poly_area(simp) < MIN_AREA_WU2:
        return None
    return simp


def _anchor_worlds() -> tuple[list[tuple[float, float]], tuple[float, float]]:
    gps = [
        BAHNHOF,
        BIRCH_A,
        BIRCH_B,
        BIRCH_GYM,
        RIET_A,
        RIET_B,
        RIET_GYM,
        OHR_A,
        OHR_B,
        OHR_GYM,
        BADI,
        KIGA_BACHTOBEL,
        KIGA_WEID,
        KIGA_SCHNECKE,
        KIGA_OHRINGEN,
    ]
    anchors = [gps_to_world(lat, lon) for lat, lon in gps]
    fx, fy = gps_to_world(*FORRENBERG)
    hub = (fx, fy + HUB_ENTER_SOUTH_WU)
    return anchors, hub


def _min_anchor_dist(p, anchors, hub) -> tuple[float, float]:
    d_anchor = min(dist(p, a) for a in anchors) if anchors else 1.0e18
    d_hub = dist(p, hub)
    return d_anchor, d_hub


def _nudge_clear(pos, ring, anchors, hub):
    px, py = pos
    for _ in range(24):
        d_a, d_h = _min_anchor_dist((px, py), anchors, hub)
        if d_a >= ANCHOR_CLEAR_WU and d_h >= HUB_CLEAR_WU:
            return (px, py)
        nearest = hub if d_h < HUB_CLEAR_WU else min(anchors, key=lambda a: dist((px, py), a))
        vx, vy = px - nearest[0], py - nearest[1]
        n = math.hypot(vx, vy) or 1.0
        px += vx / n * 180.0
        py += vy / n * 180.0
        # Stay near the patch: pull back toward centroid if we drifted far.
        cx, cy = poly_centroid(ring)
        if dist((px, py), (cx, cy)) > 2500.0:
            px = (px + cx) * 0.5
            py = (py + cy) * 0.5
    d_a, d_h = _min_anchor_dist((px, py), anchors, hub)
    if d_a >= ANCHOR_CLEAR_WU and d_h >= HUB_CLEAR_WU:
        return (px, py)
    return None


def _region_of(name: str, cx: float, cy: float) -> str | None:
    if cx < -15000.0 and cy > 8000.0:
        return "ohringen"
    if cx > 5000.0 and cy > 8000.0:
        return "forrenberg_a1"
    if cy < -8000.0:
        return "north"
    if name in VILLAGE_EDGE_NAMES:
        return "village_edge"
    if cx > 5000.0 and cy > -2000.0:
        return "village_edge"
    return None


def _iter_way_rings(data: dict):
    seen: set[int] = set()
    for el in data.get("elements") or []:
        if el.get("type") != "way":
            continue
        tags = el.get("tags") or {}
        if not _keep_forest(tags):
            continue
        eid = int(el.get("id") or 0)
        pts = _geom_world(el.get("geometry"))
        if len(pts) < 3:
            continue
        seen.add(eid)
        yield {
            "id": eid,
            "name": str(tags.get("name") or "").strip(),
            "osm": _osm_kind(tags),
            "points": _drop_closing_dup(pts),
        }

    for el in data.get("elements") or []:
        if el.get("type") != "relation":
            continue
        tags = el.get("tags") or {}
        if not _keep_forest(tags):
            continue
        outer_segs: list[list[tuple[float, float]]] = []
        for mem in el.get("members") or []:
            if mem.get("type") != "way":
                continue
            if str(mem.get("role") or "outer") == "inner":
                continue
            mid = int(mem.get("ref") or 0)
            if mid in seen:
                continue
            geom = mem.get("geometry") or []
            if len(geom) < 2:
                continue
            outer_segs.append(_geom_world(geom))
        name = str(tags.get("name") or "").strip()
        osm = _osm_kind(tags)
        for ring in _assemble_rings(outer_segs):
            yield {
                "id": int(el.get("id") or 0),
                "name": name,
                "osm": osm,
                "points": ring,
            }


def _pick_silhouettes(forests: list[dict], streams) -> list[dict]:
    anchors, hub = _anchor_worlds()
    by_region: dict[str, list[dict]] = {
        "village_edge": [],
        "forrenberg_a1": [],
        "ohringen": [],
        "north": [],
    }
    for rec in forests:
        cx, cy = rec["centroid"]
        region = _region_of(rec["name"], cx, cy)
        if region:
            by_region[region].append(rec)

    chosen: list[dict] = []
    for region, recs in by_region.items():
        recs.sort(key=lambda r: r["area"], reverse=True)
        picked = None
        for rec in recs:
            if rec["name"] in WINTERTHUR_NAMES:
                continue
            pos = _nudge_clear(tuple(rec["centroid"]), rec["points"], anchors, hub)
            if pos is None:
                continue
            if _dist_to_streams(pos, streams) < STREAM_A_CLEAR_WU:
                continue
            picked = rec, pos
            break
        if picked is None:
            continue
        rec, pos = picked
        chosen.append(
            {
                "name": rec["name"],
                "art": "a",
                "pos": [round(pos[0], 1), round(pos[1], 1)],
                "region": region,
                "_stream_d": _dist_to_streams(pos, streams),
            }
        )

    # At most one wald_b, and only on a patch far from WaterKit brooks.
    far = [s for s in chosen if s["_stream_d"] > STREAM_B_CLEAR_WU]
    if far:
        far.sort(key=lambda s: s["_stream_d"], reverse=True)
        far[0]["art"] = "b"

    out = []
    for s in chosen[:MAX_SILHOUETTES]:
        out.append({"name": s["name"], "art": s["art"], "pos": s["pos"]})
    return out


def main() -> None:
    data = json.loads(SRC.read_text())
    streams = _load_stream_polylines()
    forests: list[dict] = []
    for raw in _iter_way_rings(data):
        ring = _finish_ring(raw["points"])
        if ring is None:
            continue
        cx, cy = poly_centroid(ring)
        forests.append(
            {
                "name": raw["name"],
                "osm": raw["osm"],
                "points": ring,
                "centroid": (cx, cy),
                "area": poly_area(ring),
            }
        )
    forests.sort(key=lambda r: r["area"], reverse=True)

    payload_forests = []
    for rec in forests:
        payload_forests.append(
            {
                "name": rec["name"],
                "osm": rec["osm"],
                "points": _round_pts(rec["points"]),
                "centroid": [round(rec["centroid"][0], 1), round(rec["centroid"][1], 1)],
            }
        )
        rec["centroid"] = (
            float(payload_forests[-1]["centroid"][0]),
            float(payload_forests[-1]["centroid"][1]),
        )

    silhouettes = _pick_silhouettes(forests, streams)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "meta": {
            "source": "OSM Overpass landuse=forest|natural=wood",
            "church": [CHURCH_LAT, CHURCH_LON],
            "field_m": FIELD_M,
            "field_wu": FIELD_WU,
            "clip": list(CLIP),
        },
        "forests": payload_forests,
        "silhouettes": silhouettes,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

    named = sorted({f["name"] for f in payload_forests if f["name"]})
    print(f"wrote {OUT} forests={len(payload_forests)} named={len(named)} silhouettes={len(silhouettes)}")
    if named:
        print("  names:", ", ".join(named))
    samples = {
        "Buechwäldli": gps_to_world(47.5306911, 8.7357986),
        "A1/Forrenberg": gps_to_world(47.5281998, 8.7332964),
        "Ohringen": gps_to_world(47.5262718, 8.7123371),
        "Nord": gps_to_world(47.5402506, 8.7179862),
    }
    for rec in payload_forests:
        pts = [(p[0], p[1]) for p in rec["points"]]
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        label = rec["name"] or f"unnamed-{rec['osm']}"
        print(
            f"  {label} osm={rec['osm']} n={len(pts)} area={poly_area(pts):.0f} "
            f"c=({rec['centroid'][0]:.0f},{rec['centroid'][1]:.0f}) "
            f"x {min(xs):.0f}..{max(xs):.0f} y {min(ys):.0f}..{max(ys):.0f}"
        )
    for label, sample in samples.items():
        if not payload_forests:
            print(f"    dist {label} sample=(no forests)")
            continue
        inside = any(_point_in_ring(sample, [(p[0], p[1]) for p in f["points"]]) for f in payload_forests)
        best = min(
            _dist_to_polyline(sample, [(p[0], p[1]) for p in f["points"]])
            for f in payload_forests
        )
        print(f"    dist {label} sample-to-ring={best:.1f} inside={inside}")
    for s in silhouettes:
        print(f"  silhouette {s['art']} {s['name'] or '(unnamed)'} @ {s['pos']}")


if __name__ == "__main__":
    main()
