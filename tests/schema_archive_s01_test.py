#!/usr/bin/env python3
"""S01: OSM live snapshot under archive/seuzach-osm; no swisstopo rasters in docs/maps."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCH = ROOT / "archive" / "seuzach-osm"
MAPS = ROOT / "docs" / "maps"


def fail(msg: str) -> None:
    print(f"FAIL {msg}", file=sys.stderr)
    raise SystemExit(1)


def ok(msg: str) -> None:
    print(f"OK  {msg}")


REQUIRED_DATA = [
    "seuzach_roads.json",
    "seuzach_ways.json",
    "seuzach_rails.json",
    "seuzach_rails_osm.json",
    "seuzach_water.json",
    "seuzach_water_osm.json",
    "seuzach_forests.json",
    "seuzach_forests_osm.json",
    "seuzach_roads_swiss_trace.json",
    "seuzach_roads_gmaps_trace.json",
    "seuzach_roads_octilinear.json",
]


def main() -> None:
    if not (ARCH / "README.md").is_file():
        fail("archive/seuzach-osm/README.md missing")
    ok("archive README")
    for name in REQUIRED_DATA:
        path = ARCH / "data" / name
        if not path.is_file() or path.stat().st_size < 100:
            fail("missing or tiny archive data: %s" % path)
    ok("archive OSM/trace JSON")
    geo = ARCH / "scripts" / "seuzach_geo.gd"
    if not geo.is_file():
        fail("archive seuzach_geo.gd missing")
    ok("archive seuzach_geo.gd")
    for script in (
        "gen_seuzach_octilinear_roads.py",
        "gen_seuzach_swiss_road_trace.py",
        "build_seuzach_swiss_raster_ref.py",
    ):
        if not (ARCH / "scripts" / script).is_file():
            fail("archive script missing: %s" % script)
        live = ROOT / "scripts" / script
        if live.exists():
            fail("swiss/octilinear generator still in scripts/: %s" % live)
    ok("generators archived, not in scripts/")
    banned = list(MAPS.glob("*.tif")) + list(MAPS.glob("*.tiff"))
    banned += list(MAPS.glob("seuzach_swiss_raster_ref.jpg"))
    banned += list(MAPS.glob("seuzach_zoom_verify_*.jpg"))
    if banned:
        fail("swisstopo artefacts still under docs/maps: %s" % banned)
    ok("docs/maps has no raster TIFFs/QA JPGs")
    ref = MAPS / "SWISS-RASTER-REF.md"
    text = ref.read_text(encoding="utf-8") if ref.is_file() else ""
    if "gelöscht" not in text and "entfernt" not in text.lower():
        fail("SWISS-RASTER-REF.md should state maps are removed")
    if "1072-1+1052-3" in text and "use" in text.lower() and "Primary" in text:
        fail("SWISS-RASTER-REF.md still reads as live QA ground truth")
    ok("SWISS-RASTER-REF.md is archival notice")
    rule = ROOT / ".cursor" / "rules" / "swiss-raster-maps.mdc"
    if rule.exists():
        fail("swiss-raster-maps.mdc still present")
    ok("swiss-raster-maps rule removed")
    restore = (ROOT / "docs" / "plans" / "restore-stripped-landmarks" / "INDEX.md").read_text(
        encoding="utf-8"
    )
    if "Überholt" not in restore and "überholt" not in restore:
        fail("restore-stripped-landmarks INDEX must be marked superseded")
    ok("restore-stripped-landmarks superseded")


if __name__ == "__main__":
    main()
    print("=== schema_archive_s01_test passed ===")
