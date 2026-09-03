# Archiv: OSM-Seuzach (vor Schema-Dorf)

Snapshot des **live** OSM-Felds (Kirche-Origin, 1 Feld = 5,3 m = 100 wu, CLIP ca. (−25000,−24000)–(32000,18000)) plus Trace/Octilinear-Generatoren.

Bis Schema-S02 lädt `world_sandbox` weiterhin `data/seuzach_roads.json` (Rails/Water/Forests unter `data/`). Dieses Verzeichnis ist der OSM-Snapshot; nach S02 ist die Live-Quelle das Schema-Dorf, nicht dieses Archiv.

## Inhalt

| Pfad | Rolle |
|------|--------|
| `data/seuzach_roads.json` | Live-Straßen zum Archivzeitpunkt (RoadKit) |
| `data/seuzach_ways.json` | OSM-Overpass Highways |
| `data/seuzach_rails.json` / `_osm.json` | SBB 821 |
| `data/seuzach_water.json` / `_osm.json` | Bäche |
| `data/seuzach_forests.json` / `_osm.json` | Wälder |
| `data/seuzach_roads_swiss_trace.json` | Named-highway-Trace (früher vs. Swiss Raster QA) |
| `data/seuzach_roads_gmaps_trace.json` | Älterer GMaps-Trace |
| `data/seuzach_roads_octilinear.json` | H/V/45°-Netz aus dem Trace (nie live verdrahtet) |
| `docs/maps/seuzach_octilinear_roads.svg` | Schema-SVG dazu |
| `scripts/seuzach_geo.gd` | GPS-Getter zum Archivzeitpunkt |
| `scripts/gen_seuzach_*.py` | OSM-Generatoren + Swiss/Octilinear (historisch) |

Swisstopo-GeoTIFFs und QA-JPGs sind **gelöscht**, nicht mitarchiviert.

Generator-`ROOT` in den kopierten Python-Skripten ist dieses Archivverzeichnis (`archive/seuzach-osm/`), nicht das Repo-Root.
