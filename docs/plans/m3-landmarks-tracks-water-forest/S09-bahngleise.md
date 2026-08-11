# Slice: S09 — Bahngleise (S-Bahn)

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S09-bahngleise.md`  
**Hängt ab von:** S08

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Die **S-Bahn-Gleise** durch Seuzach sind als ein Strecken-Feature sichtbar: grob Ost–West, maps-getreu zu OSM/Maps, und sie treffen den Bahnhof aus S08.

## In diesem Schritt

- Eine durchlaufende Gleisanlage (nicht jedes Schwellenstück einzeln); Lage/Kurve nach OSM/Maps
- Anschluss an den Bahnhof (Perron/Gleisflucht)
- Art nur soweit nötig (es gibt noch kein Gleis-PNG); Stil C

## Nicht (andere Feature-Schritte)

- Bahnhofsgebäude (`S08`)
- Schul-Campi, Kindergärten, Badi, Bäche, Wälder, Wohnhäuser

## Ziel

Spieler sieht **nördlich** des Bahnhofsgebäudes (Stationsstrasse 53) ein durchlaufendes **Gleisband** der SBB-Linie Winterthur–Etzwilen (OSM `ref=821`, S11-Endstation / S29-Durchfahrt): Schotter + zwei Schienen als RoadKit-ähnliche Polylinien, maps-getreu, ohne Schwellen-Props und ohne Zug. Das Band trifft die Nordkante/Vordach aus S08 (Stop ref 1 ≈ 11 m nördlich des Gebäudes). Schul-Campi (S01–S03), alle **vier** Kindergärten und der Bahnhof bleiben stehen. Keine Badi, keine Bäche, keine Wälder, keine Häuser.

## Scope

### In

- **Ein** Strecken-Feature: OSM `railway=rail` `ref=821` durch die CLIP-Welt, als Kit-Band unter `%Ground` (nicht als Landmark-Sprite, nicht als hunderte PNGs)
- Generator + JSON analog zu Roads: Overpass-Dump → Weltkoordinaten → `RoadKit`-ähnliche Ribbon-API
- Durchgangsgleis **track_ref=1** (usage=branch) plus Stations-Gegengleis **track_ref=2** (OSM `service=siding` way `116582444`) — zwei parallele Kit-Bänder, immer noch ein Feature
- Kurzes **Perron 2** (Nord) als Kit-Polygon aus OSM way `116582447` (`railway=platform` `ref=2`) — kein zweites Gebäude-Sprite
- Marker unter `%Ground` für Tests (`railway_name` / `railway_points` / `poi_type=railway`), **ohne** `road_name` (Off-Road-Asserts der Gebäude bleiben Strassen-only)
- Tests: S08-Platzhalter „keine Gleise“ umdrehen → Strecke **ist** da; S01–S08 bleiben grün; Badi/Housing/Wälder/Bäche weiter abwesend

### Nicht

- Bahnhofsgebäude, Vordach, Perron-1-Kante im Sprite (`S08`) — PNG/`bahnhof_world()` nicht verschieben
- Zug, Fahrleitung, Signale, Schranken, Bahnsteigkanten als eigene Landmark-PNGs
- Jede Schwelle als Prop oder Polygon (m2: `ground_polys <= 4000`; ~2 km Strecke × Schwellenabstand 0,6 m würde die Cap sprengen)
- `seuzach_roads.json` / `gen_seuzach_roads.py` umbauen; keine RoadKit-Kreuzungs-Scheiben auf Gleisen
- Schul-Campi, Kindergärten, Badi (`S10`), Bäche (`S11`), Wälder (`S12`), Housing
- Feuerwehr, Gemeindehaus, Kirchen, Läden, Tankstelle, HubEnter
- Bus-Perron way `315997018`, Parkplatz way `128879908`
- `Sprite2D.rotation` am Bahnhof; `DistrictBahnhof`; Parent `DistrictOhringen` für Gleise
- Line2D auf `%Ground` (m2_world_test verbietet das)
- Gleise als `road_name`-Marker (sonst rutscht die Strecke in `_assert_sprite_off_named_roads`)

### Raster / GPS / OSM

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`). Dieselbe CLIP wie Roads: `(-25000, -24000, 32000, 18000)`.

**Overpass-BBox** (CLIP in WGS84, 2026-08-11 nachgerechnet):

| | lat | lon |
|--|-----|-----|
| Süd-West | 47.52493 | 8.70849 |
| Nord-Ost | 47.54493 | 8.74869 |

Fetch etwas **größer**, dann im Generator clippen:

```
south=47.5200 west=8.7000 north=47.5550 east=8.7600
```

Query (nur `railway=rail`, nicht highway):

```
[out:json][timeout:90];
(
  way["railway"="rail"](47.5200,8.7000,47.5550,8.7600);
  way["railway"="platform"](47.5200,8.7000,47.5550,8.7600);
  node["railway"="stop"](47.5200,8.7000,47.5550,8.7600);
);
out tags geom;
```

Nicht in `seuzach_ways.json` mischen (das ist highway-only). Dump: `data/seuzach_rails_osm.json`. Generiert: `data/seuzach_rails.json`.

**Ist-Overpass 2026-08-11** (CLIP-BBox, 16 Elemente): Linie **821** SBB Winterthur–Etzwilen, `gauge=1435`, `electrified=contact_line`. Lokal am Bahnhof **NW–SE** (Winterthur/SE ↔ Dinhard/Etzwilen N–NE) — slicer „grob Ost–West“ = dieser Korridor durchs Ost-Dorf, nicht eine achsparallele E–W-Linie.

| OSM | Rolle | Hinweis |
|-----|--------|---------|
| way `32210620` | Durchgang **Gleis 1** durch die Station | `railway:track_ref=1` `usage=branch`; enthält Stop 1; min. **12,2 m** zum Gebäude-Zentroid |
| way `116582444` | Stations-**Gleis 2** (Kreuzungsgleis) | `railway:track_ref=2` `service=siding`; Stop 2; min. **16,6 m** zum Gebäude |
| way `116582468` + `13872887` (Brücke) + `13872886` | Fortsetzung SE Richtung Winterthur | nach CLIP-Ost `x=32000` kappen |
| way `237404661` + `237404663` | Fortsetzung N/NE Richtung Dinhard | nach CLIP-Nord `y=-24000` kappen |
| node `130250360` | Stop **ref 1** | **47.5358162, 8.7389630** → Welt ≈ `(18207.5, −4862.4)`; **11,2 m** nördlich des Gebäudes (`dy ≈ −211 wu`) |
| node `1313973485` | Stop **ref 2** | **47.5358434, 8.7390122** → Welt ≈ `(18277.3, −4919.5)`; ~5 m NNW von Stop 1 (Doppelspur-Abstand) |
| way `116582447` | Perron **2** Nord | `shelter=no`; Kit-Polygon, kein Sprite |
| way `116582443` | Perron **1** Süd | schon kurze Masse im S08-Sprite — **kein** zweites Voll-Perron-1-Band über das Gebäude legen |
| node `1313973484` | `railway=station` *Seuzach* | **nicht** als Strecken-GPS |
| way `116582470` | Gebäude | S08, südlich der Gleise |

`bahnhof_world()` bleibt `(18113.8, −4651.7)`. Relativlage:

```
        Bahnstrasse / Perron 2          N     ← Kit-Polygon Perron 2
        Gleis 2 (track_ref=2)
        Gleis 1 (track_ref=1, Stop ref 1)
        Perron 1 + Vordach (im S08-Sprite)
              Bahnhofgebäude 53               ← S08, nicht anfassen
        Stationsstrasse S
        Birch ~184 m SW der Gleis-Vertices
        Kirche WSW
```

Geklipptes Durchgangsgleis ≈ **2,0 km** (sechs Ways, mergen). Gleis 2 ≈ **680 m** (nur Stationsbereich). Birch-Campus min. ~184 m von Gleis-1-Vertices; Kiga Bachtobel ~78 m — Off-Road-Strassen-Asserts unverändert, weil Gleise **kein** `road_name` bekommen.

Level Crossings (OSM, nur Kontext, **keine** Schranken-Props): u. a. `(15437, −8517)`, `(15325, −12271)`, `(21176, −21773)`. Gleis-z **über** RoadKit-Asphalt, damit die Strecke an Bahnübergängen lesbar bleibt.

**Ist-Zustand:** `_add_continuous_roads()` zeichnet nur Highways. Kein Railway-JSON. Tests in `_assert_bahnhof`: `_count_poi(sprites, "railway") == 0` und kein Landmark `gleise`.

## Systeme

- `scripts/gen_seuzach_rails.py` (**neu**, nicht `gen_seuzach_roads.py` erweitern) — Overpass-Dump → CLIP/RDP/Merge → `data/seuzach_rails.json`
- `data/seuzach_rails_osm.json` + `data/seuzach_rails.json` + `data/README.md`
- `scripts/railway_kit.gd` (**neu**) **oder** `RoadKit.add_railway_polyline` mit eigenen Farben/`railway_kit`-Metas — kein Asphalt-Grau, keine Trottoirs, keine Mittellinie
- `scripts/world_sandbox.gd` — `_add_continuous_rails()` nach `_add_continuous_roads()` in `_build_flat_ground`; Landmark-Platzierung S01–S08 unverändert
- `tests/m3_world_landmarks_test.gd` — `_assert_railway`; S08-Negativ-Asserts umdrehen
- `tests/m2_railway_kit_test.gd` (**neu**) oder Erweiterung `m2_road_kit_test.gd` — Kit ohne Line2D
- `tests/m2_world_test.gd` — Line2D=0 und `ground_polys <= 4000` nicht sprengen
- Art: **Default keine neuen PNGs** (Cel-Farben im Kit)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Bahnhof steht, Gleiskorridor nördlich ist Lücke; Tests verbieten railway-Sprites).

## Technische Schritte

1. **Daten:** Overpass wie oben → `data/seuzach_rails_osm.json` committen (kein Netz in Tests). Filter:
   - Durchgang: `railway=rail` und `ref=821` und **kein** `service=*` (Ways `32210620`, `116582468`, `13872887`, `13872886`, `237404661`, `237404663`)
   - Loop: `railway:track_ref=2` way `116582444`
   - Perron 2: way `116582447`
   - Ignorieren: `abandoned`/`disused`, Perron 1 als extra Band, `railway=station`-Node
2. **`gen_seuzach_rails.py`:** dieselben `gps_to_world` / `CLIP` / `rdp` (`SIMPLIFY_WU≈28`) / `merge_polylines` / `clip_polyline` wie Roads. Output-Schema:
   ```
   {
     "meta": { "source": "OSM Overpass railway=rail ref=821", "church": [...], "clip": [...] },
     "tracks": [
       { "name": "SBB 821", "ref": "821", "track_ref": "1", "role": "through", "points": [[x,y], ...] },
       { "name": "SBB 821 Gleis 2", "ref": "821", "track_ref": "2", "role": "loop", "points": [...] }
     ],
     "platforms": [
       { "ref": "2", "points": [[x,y], ...] }
     ]
   }
   ```
   Keine `junctions`. `python3 scripts/gen_seuzach_rails.py` schreibt `data/seuzach_rails.json`. `data/README.md` um Dump+Generator ergänzen.
3. **RailwayKit** (bevorzugt eigene Datei, damit `m2_road_kit_test` und Asphalt-Farben unangetastet bleiben):
   - `add_polyline(parent, points, opts)` → **ein** mitered Schotter-Band + **zwei** Schienen-Bänder (links/rechts der Achse, Abstand ≈ Spurweite/2 = 0,72 m ≈ **13,5 wu**)
   - `half_w` Schotter ≈ **38 wu** (~2,0 m), vergleichbar `ROAD_HW_LOCAL`
   - Farben Stil C, **nicht** `COLOR_ROAD` `#8E8E8E`: Schotter `#8A7A68`, Schiene `#C5C5C5`, optional dunkle Unterkante `#1A1A1A` als etwas breiteres Band darunter
   - Metas `railway_kit` = `ballast` | `rail` (nicht `road_kit=road`)
   - z: Schotter **−37**, Schiene **−36** (über RoadKit −41…−39, unter Props 2000)
   - **Keine** Line2D. **Keine** Polygon2D-Schwelle pro Schwellenabstand. Schwellen höchstens als `_draw`-Striche auf **einem** Node2D oder ganz weglassen (zwei Schienen auf Schotter reichen in der Übersicht)
   - `add_platform(parent, points)` für Perron 2: helles Band `#D4D0C8`, z −38, meta `railway_kit=platform`
4. **`world_sandbox.gd`:** `RAILS_JSON := "res://data/seuzach_rails.json"`. In `_build_flat_ground` nach den Strassen `_add_continuous_rails()`:
   - Tracks via RailwayKit; Marker analog `_add_road_marker`, aber `railway_name`, `track_ref`, `half_w`, `railway_points`, `poi_type=railway`
   - **Kein** `road_name`
   - Parent `%Ground`, nicht `%Props`, nicht `DistrictOhringen`
   - `_place_landmarks()` / `_place_bahnhof()` / Schulen / Kigas **nicht** ändern
   - Keine BuildingCollision auf Gleisen (wie Strassen: nur visuell, Spieler kann queren)
5. **Tests zuerst/mit:**
   - In `_assert_bahnhof` die Zeilen `_count_poi(..., "railway") == 0` und `gleise == null` **ersetzen**: Sprite-POI `railway` bleibt **0** (Kit ≠ Sprite), Landmark `gleise` bleibt **null**; Presence-Check wandert nach `_assert_railway`. Kommentar „S09“ aktualisieren. `no badi` bleibt.
   - Neue `_assert_railway(world, sprites)` aus `_run` nach `_assert_bahnhof`:
     - Ground-Marker mit `poi_type=railway` **≥ 1**; davon `track_ref=1` through vorhanden
     - `railway_points` Polylinie: Distanz von Stop-ref-1-Weltpunkt zur Gleis-1-Linie **≤ half_w + 40 wu**
     - Bahnhof-Prop **südlich** der Gleis-1-Linie am Stop (weiter `bahnhof.position.y > stop_ref1.y`); Distanz Gebäude-Zentroid zur Gleis-1-Linie **80…400 wu** (Ist ~231 wu / 12 m)
     - Durchgang überspannt das Ost-Dorf: min. x der through-Punkte **< 16000**, max. x **> 28000** (oder Länge **> 20000 wu**)
     - Gleis 2 optional aber erwartet: Marker `track_ref=2` oder zweite Polylinie; Stop 2 nahe Gleis 2
     - Perron 2: mind. ein `railway_kit=platform` **oder** Marker `platform_ref=2`, nördlich von Gleis 1 (kleineres Y als Stop 1)
     - Kein Housing, kein Forest, kein Badi, keine Hill-Marker
     - Schulen je 3 + vier Kigas + Bahnhof Count=1 unverändert
     - Parent-Kette der Marker ohne `DistrictOhringen`
     - `_assert_sprite_off_named_roads` **nicht** über Gleise laufen lassen
   - Kit-Unit-Test: polyline erzeugt ballast+rail-Metas, 0 Line2D, Biege-Ecke gefüllt wie RoadKit-Miter
   - `m2_world_test`: weiter 0 Line2D, `ground_polys <= 4000` (RailwayKit als Subnode unter einem `Rails`-Holder ist ok, solange keine Schwellenflut)
6. **Art-Gate:** Default **kein** `comic-rettung-art`. Nur wenn Playtest Schotter=Asphalt liest: eine Repeating-Textur, siehe Art-Bedarf.
7. Suite `./scripts/run_tests.sh`. Playtest am Bahnhof (Zoom 0,5) plus ein Stück Korridor Ost und Nord; Schulen/Kigas/Gebäude nicht umbauen.

## Testplan

### Automatisiert

- [x] `data/seuzach_rails.json` existiert; through-Polylinie maps-getreu (Stop ref 1 liegt auf/am Band)
- [x] Ground-Marker `poi_type=railway` ≥ 1; **keine** Sprite-POIs `railway`; **kein** Landmark `gleise`
- [x] Strecke nördlich des Bahnhofs; Gebäude-GPS unverändert `(18113.8, −4651.7)`
- [x] Gleis 2 und Perron-2-Polygon vorhanden (Kit, kein PNG)
- [x] Alle drei Schul-Campi und vier Kigas + Bahnhof weiter platziert
- [x] Kein Housing, kein Forest-Prop, keine Hill-Marker, kein Badi-Prop
- [x] Off-Road der Gebäude gegen **Strassen** unverändert (Gleise nicht in `road_name`)
- [x] 0 Line2D auf Ground; Poly-Cap 4000 hält
- [x] `m2_world_test` / S01–S08-Asserts grün

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Am Bahnhof: Schotter+Schienen **nördlich** von Gebäude/Vordach, nicht auf der Stationsstrasse; Korridor folgt der OSM-Kurve (NW–SE), nicht ein gerader E–W-Balken
- [x] Band läuft durchs Ost-Dorf (Richtung Winterthur SE und Dinhard N), nicht nur ein Stub am Perron
- [x] Kein Zug, keine gebackenen Gleise im Bahnhof-Sprite (S08 bleibt)
- [x] Spieler kann die Gleise queren; Collision nur am Gebäude
- [x] Y-Sort: Gleise unter Füßen (Ground); Bahnhof-Sprite deckt die Strecke nicht zu
- [x] Schulen und vier Kigas sichtbar; keine Badi, keine Wälder, keine Häuser
- [x] Keine weissen/schwarzen AI-Platten (keine neuen Sprites erwartet)
- [x] Bahnübergänge: Gleis über Asphalt lesbar; keine Schranken nötig

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. `m2_railway_kit_test` (ballast+rail Metas, 0 Line2D) und `_assert_railway` (ballast=2 rail=4, Stop1 d=10.3, Bahnhof südlich y=-4652 vs -4862, through x 15067..32000); smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s09-bahnhof-gleise.png` (player at `bahnhof_world()`, zoom 0.5): zwei Schotterbänder `#8A7A68` **nördlich** des Gebäudes, zwei Schienen `#C5C5C5`, Perron 2 hell, Stationsstrasse Asphalt `#8E8E8E` SW — Schotter liest sich braun, nicht asphaltgrau. Optional `/tmp/s09-gleise-korridor.png` (NW–SE-Kurve, nicht E–W-Balken). Kit-Polygone, keine neuen PNGs; house_n=0, Campi je 3, vier Kigas. Art-Fallback `rail_ballast.png` nicht nötig.

## Art-Bedarf

- [x] Keine neuen Assets *(Default — Kit-Polygone mit Stil-C-Hex, analog RoadKit)*
- [ ] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur falls Playtest das Band nicht als Bahn liest**

**Warum kein Art-Default:** RoadKit zeichnet Strassen bereits als Cel-Polygone. Dieselbe Sprache für Schotter+Schienen vermeidet hunderte Schwellen-PNGs und hält `verify_art_alpha` / Import-Gate raus. `c-iso-city-map` zeigt Strassen als Bänder — Gleise ebenso.

**Fallback (nur nach Playtest-Fail „sieht aus wie Strasse“):**

- Genau **eine** Datei `assets/art/rail_ballast.png` (kleine kachelbar Cel-Schotterfläche, Kontur sparsam) als `Polygon2D.texture` auf dem Ballast-Band
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Satellit Bahnhof Seuzach (Gleisseite Nord, nicht HB Winterthur)
- Pipeline: `process_art_alpha.py` → `verify_art_alpha.py`; Walk-Pad entfällt
- Keine Schwellen-Sprites, kein Zug, keine Fahrleitung, keine Schul-/Kiga-/Badi-Art

## Akzeptanzkriterien

- [x] Grenzen: nur Gleis-Kit + Perron 2; S01–S08 unangetastet; keine Badi/Bach/Wald/Housing
- [x] OSM-Linie 821 durch CLIP, trifft Bahnhof nördlich (Stop ref 1); Gebäude bleibt südlich
- [x] Ein Strecken-Feature (Ribbon), keine Schwellen-Props; 0 Line2D
- [x] Tests: railway Presence auf Ground, Sprite-POI railway = 0; Suite grün
- [x] Style C lesbar (Schotter ≠ Asphalt)
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
