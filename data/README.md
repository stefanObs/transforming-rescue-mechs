# Kartendaten

`seuzach_ways.json` ist ein OpenStreetMap-Overpass-Dump (benannte Highways + A1) für Seuzach und Ohringen.

`seuzach_roads.json` ist daraus generiert (`scripts/gen_seuzach_roads.py`) in Spielwelt-Koordinaten (Kirche = Ursprung, 1 Feld = 5,3 m = 100 wu).

`seuzach_rails_osm.json` ist ein Overpass-Dump (`railway=rail` / `railway=platform` / `railway=stop`, BBox 47.520–47.555 N, 8.700–8.760 E). Nicht mit den Highway-Ways mischen.

`seuzach_rails.json` ist daraus generiert (`scripts/gen_seuzach_rails.py`): SBB-Linie 821 (Durchgang `track_ref=1`, Stations-Gleis 2, Perron 2) in denselben Weltkoordinaten und CLIP wie die Strassen.

`seuzach_water_osm.json` ist ein Overpass-Dump (`waterway=stream|river|drain`, BBox 47.520–47.555 N, 8.700–8.760 E). Nicht mit Highway- oder Railway-Ways mischen.

`seuzach_water.json` ist daraus generiert (`scripts/gen_seuzach_water.py`): benannte Bäche in CLIP (Chrebsbach, Welsikonerbach, Bachtobelgraben, Ohringerbach, …) in denselben Weltkoordinaten. Feldgräben (`ditch`) und der OSM-Riedbach (Eulach, ausserhalb CLIP) sind nicht enthalten.

`seuzach_forests_osm.json` ist ein Overpass-Dump (`landuse=forest` / `natural=wood`, BBox 47.520–47.555 N, 8.700–8.760 E). Nicht mit Highway-, Railway- oder Waterway-Ways mischen.

`seuzach_forests.json` ist daraus generiert (`scripts/gen_seuzach_forests.py`): Waldflächen in CLIP (Buechwäldli, Laubholz, Forrenberg/A1, Ohringen, Seuzach-Nord, …) plus wenige Silhouette-Positionen in denselben Weltkoordinaten. Winterthur-Wälder (Lindberg, Wolfensberg, Schoren, Stadlerberg, Fröschholz) nur als CLIP-Schnitt, nicht als Pflicht-Patches.

## Octilinear / Google-Maps-Trace (noch nicht live)

`seuzach_roads_gmaps_trace.json` ist eine **Google-Maps-Digitalisierung** (WGS84-Waypoints entlang der sichtbaren Strassen in Seuzach + Ohringen). **Nicht** aus `seuzach_roads.json` / `seuzach_ways.json` abgeleitet.

`seuzach_roads_octilinear.json` und `docs/maps/seuzach_octilinear_roads.svg` erzeugt `scripts/gen_seuzach_octilinear_roads.py` daraus: nur H/V/45°-Segmente (Arrow-Key-8-dir), gleiche Kirche-Origin / FIELD / CLIP wie die Spielwelt.

Die Live-Sandbox lädt weiterhin `seuzach_roads.json` — das octilineare Netz ist noch **nicht** umgeschaltet.

Schematic street layout digitized from Google Maps; world scale matches project CLIP. OSM-Karten unten: © OpenStreetMap-Mitwirkende, [ODbL](https://opendatacommons.org/licenses/odbl/).
