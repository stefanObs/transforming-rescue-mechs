# Slice: S12 — Wälder (Patches)

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S12-waelder.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

**Wälder** am Dorfrand, zur A1 und um Ohringen sind als Flächen-Patches sichtbar — Lage nach OSM/Maps, nicht jeder einzelne Baum.

## In diesem Schritt

- Wald-Patches aus OSM/Maps (Dorfrand / A1 / Ohringen); bestehende `landmark_wald_a.png` / `_b.png`
- Neue Art nur wenn Silhouette für Flächen-Patches nicht reicht
- Mehrere Patches, kein Baum-für-Baum

## Nicht (andere Feature-Schritte)

- Bäche (`S11`) — WaterKit bleibt; Bäche nicht umbauen
- Gebäude-Landmarken, Gleise, Wohnhäuser

## Ziel

Spieler sieht in der Seuzach+Ohringen-CLIP **ein** Natur-Feature: OSM-getreue **Wald-Bodenflächen** (`Polygon2D`, `COLOR_FOREST_FLOOR`) plus **wenige** Baumcluster-Sprites (`landmark_wald_a.png` / `_b.png`) als Silhouette. Kein Baum-für-Baum, kein Hügel-Mound. Lage nach `landuse=forest` / `natural=wood`. Bäche bleiben über dem Waldboden sichtbar; Strassen/Gleise darüber. Schul-Campi, vier Kigas, Bahnhof, Gleis-Kit, Badi und Housing-Abwesenheit bleiben. Nach Phase-4-Pass dieses Slices kann das Parent-INDEX der Aufgabe auf **Erledigt** (Parent nach Playtest/Git).

## Scope

### In

- **Ein** Natur-Feature: OSM-Wald **als Fläche** unter `%Ground` (nicht hunderte Einzelbäume, nicht `natural=tree`)
- Generator + JSON analog zu S11: Overpass-Dump → Weltkoordinaten → CLIP → `Polygon2D`
- Boden: `COLOR_FOREST_FLOOR` (`#2F9A45`, bereits in `world_sandbox.gd`) — dunkler als Gras `#3DCC5A`
- Silhouette: **wenige** bestehende Cluster-PNGs auf `%Props` mit `terrain=forest` (Tests drehen `forest_n == 0` um)
- Marker unter `%Ground` für Tests (`forest_name` / `forest_points` / `poi_type=forest`), **ohne** `road_name`
- Tests: `forest_n == 0` in `_run` / `_assert_railway` / `_assert_badi` / `_assert_streams` **umdrehen** (`forest_n >= 1`); Housing weiter `== 0`; S01–S11 bleiben grün
- Art: **Default keine neuen PNGs** — `landmark_wald_a.png` / `_b.png` existieren bereits (`GEO_ART`)

### Nicht

- Jeder einzelne Baum (`natural=tree`), jeder Garten-Hain, `natural=scrub`, `landuse=orchard|vineyard|meadow`, Alleen, Friedhofs-Bäume
- Winterthur-Wälder **ausserhalb** CLIP heranziehen: Lindberg, Wolfensberg, Schoren, Stadlerberg, Fröschholz (Zentren ausserhalb) — nur CLIP-Schnitt behalten
- Hügel (`terrain=hill` / `_add_hill_mound`) — Asserts `hills == 0` bleiben
- Bäche / WaterKit / `seuzach_water.json` umbauen (`S11`)
- Gebäude-Landmarken, Gleise, Badi-PNG, Housing; Feuerwehr, Gemeindehaus, Kirchen, Läden, Tankstelle, HubEnter/Forrenberg-**Gebäude**
- `seuzach_roads.json` / `gen_seuzach_roads.py` / Rails / Water-Generator umbauen
- Collision auf Waldboden oder Silhouetten (Spieler quert den Wald) — **kein** `BuildingCollision` auf Wald-Sprites
- `Sprite2D.rotation`; Wald-Boden unter `DistrictOhringen`
- Line2D auf `%Ground`
- Forest-Marker als `road_name` oder als Sprite-POI `poi_type=stream`
- Neues ForestKit analog WaterKit (**unnötig**: Fläche, kein Miter-Band)

### Raster / GPS / OSM

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`). Dieselbe CLIP wie Roads/Rails/Water: `(-25000, -24000, 32000, 18000)`.

**Overpass-BBox** (wie S09/S11, CLIP in WGS84):

| | lat | lon |
|--|-----|-----|
| Süd-West | 47.52493 | 8.70849 |
| Nord-Ost | 47.54493 | 8.74869 |

Fetch etwas **größer**, dann im Generator clippen:

```
south=47.5200 west=8.7000 north=47.5550 east=8.7600
```

Query (Waldflächen, nicht highway/railway/waterway, nicht Einzelbäume):

```
[out:json][timeout:90];
(
  way["landuse"="forest"](47.5200,8.7000,47.5550,8.7600);
  way["natural"="wood"](47.5200,8.7000,47.5550,8.7600);
  relation["landuse"="forest"](47.5200,8.7000,47.5550,8.7600);
  relation["natural"="wood"](47.5200,8.7000,47.5550,8.7600);
);
out tags geom;
```

Nicht in `seuzach_ways.json` / `seuzach_water_osm.json` mischen. Dump: `data/seuzach_forests_osm.json`. Generiert: `data/seuzach_forests.json`.

**Ist-Overpass 2026-08-11** (Fetch-BBox, `landuse=forest` | `natural=wood`, 31 Elemente: 8 benannt, 23 unbenannt; `out tags center`):

Ausserhalb CLIP (nicht in die Welt ziehen, ausser echter Polygon-Schnitt nach Geom-CLIP):

| OSM-Name | Zentrum ≈ | Hinweis |
|----------|-----------|---------|
| Schoren way `5078015` | `(51573, 18063)` | Ost, ausserhalb |
| Eschberg way `13872999` | `(36413, −18884)` | Ost, ausserhalb |
| Fröschholz way `13891955` | `(19003, −38924)` | Nord, ausserhalb |
| Lindberg rel `6464469` | `(11592, 34973)` | Winterthur-Süd, ausserhalb |
| Wolfensberg rel `18176559` | `(−27025, 31387)` | SW, ausserhalb |
| Stadlerberg rel `20806717` | `(58225, −22873)` | NO, ausserhalb |

In / am CLIP-Rand (Pflichtrichtung für Patches; Geom-CLIP + `MIN_AREA` entscheidet):

| OSM | Zentrum ≈ Welt | Rolle |
|-----|----------------|-------|
| **Buechwäldli** way `31766718` **47.5306911, 8.7357986** | `(13720, 5902)` | Dorfrand Süd, zwischen Kirche und Forrenberg |
| **Laubholz** way `37140568` **47.530572, 8.7435778** | `(24752, 6152)` | Dorfrand Südost |
| way `1033172691` **47.5281998, 8.7332964** | `(10172, 11135)` | **A1 / Forrenberg**-Wald (unbenannt), NW des HubEnter |
| way `43018831` **47.5262718, 8.7123371** | `(−19550, 15184)` | **Ohringen**-Wald |
| way `448994597` **47.5272984, 8.7112314** | `(−21118, 13028)` | **Ohringen**-Wald |
| way `40559092` **47.5402506, 8.7179862** | `(−11539, −14176)` | **Seuzach Nord** |
| way `40404327` `natural=wood` **47.5449027, 8.729447** | `(4713, −23947)` | Nord, CLIP-Kante `ymin=−24000` — nur falls nach CLIP Fläche bleibt |
| way `131648273` **47.5325776, 8.7383869** | `(17391, 1940)` | Dorfrand Ost (bei Bahnhof/Birch) — behalten wenn `MIN_AREA` |
| rel `20703786` **47.5437755, 8.7399288** | `(19577, −21580)` | Nord-Komplex — Outer-Ringe clippen |

Relativlage (Kartenbild, N = kleineres Y):

```
        Seuzach-Nord-Wald (way 40559092 / wood 40404327)     N
        Badi
        Kirche (0,0)     Bahnhof / Gleise O     Dorfrand-Ost
        Buechwäldli (S)              Laubholz (SO)
        A1 / Forrenberg-Wald         HubEnter (kein Gebäude hier)
        Ohringen-Wälder (SW)                                      Ohringen-Campus
```

z-Stack Ground (S12 fügt Forest **unter** Water ein):

| Layer | z | Slice |
|-------|---|-------|
| Gras-Canvas | −50 | m2 |
| **Waldboden** | **−48** | **S12** |
| Bach-Bank / Wasser | −46 / −45 | S11 |
| RoadKit Trottoir / Asphalt / Streifen | −41 / −40 / −39 | Roads |
| Railway Perron / Schotter / Schiene | −38 / −37 / −36 | S09 |
| Props/Spieler (Silhouette-Sprites) | ~2000+ | Landmarken + Wald-Silhouette |

Waldboden **unter** Bach: Bäche im Wald bleiben blau. Strassen **über** dem Wald (A1 durch Forrenberg-Wald). Gleise unverändert über der Strasse. Silhouetten sind Props (Y-Sort), nicht Ground-Sprites (`m2_world_test`: 0 Sprite2D auf Ground).

**Ist-Zustand:** `_build_flat_ground` legt Gras + Streams + Roads + Rails; Kommentar „no … forest floors“. `COLOR_FOREST_FLOOR` existiert, wird nicht platziert. `landmark_wald_a.png` / `_b.png` liegen auf Disk (`GEO_ART`), sind **nicht** in der Welt. `forest_n == 0` in `_run`, `_assert_railway`, `_assert_badi`, `_assert_streams` (zählt Props-Sprites mit `terrain=forest`). `_add_prop` setzt immer `BuildingCollision` — Wald-Silhouetten dürfen das **nicht** nutzen.

## Systeme

- `scripts/gen_seuzach_forests.py` (**neu**, nicht Water/Roads/Rails-Generator erweitern) — Overpass-Dump → CLIP (Sutherland–Hodgman) / RDP / `MIN_AREA` → `data/seuzach_forests.json`
- `data/seuzach_forests_osm.json` + `data/seuzach_forests.json` + `data/README.md`
- `scripts/world_sandbox.gd` — `_add_forest_floors()` in `_build_flat_ground` **nach** Gras, **vor** Streams; `_place_forest_silhouettes()` aus `_place_landmarks` **nach** Badi; `FORESTS_JSON`
- `tests/m3_world_landmarks_test.gd` — `_assert_forests`; `forest_n == 0` **umdrehen**; Housing bleibt 0; S01–S11-Asserts bleiben
- `tests/m2_world_test.gd` — Line2D=0, Ground-Sprites=0, `ground_polys <= 4000` (Holder `Forests`, analog Streams/Rails)
- Art: **Default keine neuen PNGs** (`landmark_wald_a.png` / `_b.png`)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Strassen+Gleise+Bäche+Landmarken stehen, Waldkorridore sind Gras; Tests verbieten Forest-Props).

## Technische Schritte

1. **Daten:** Overpass wie oben → `data/seuzach_forests_osm.json` committen (kein Netz in Tests). Filter im Generator:
   - Keep: `landuse=forest` **oder** `natural=wood` (Ways + Relation-Outer)
   - Drop: `natural=tree`, `natural=scrub`, `landuse=orchard|vineyard`, `leisure=garden|park` ohne forest/wood, abandoned
   - Inner-Ringe von Multipolygonen **v1 weglassen** (Lichtungen bleiben waldfarben — Comic-Karte, kein Loch-Kit)
   - Name: `tags.name` übernehmen (Buechwäldli, Laubholz); unbenannt `""` — Tests fordern Namen nur wo Sample-GPS Pflicht ist
   - Winterthur-Namen (Lindberg, Wolfensberg, Schoren, Stadlerberg, Fröschholz): mitnehmen **falls** CLIP-Schnitt; Tests **fordern** diese Namen **nicht**
2. **`gen_seuzach_forests.py`:** dieselben `gps_to_world` / `CLIP` wie Water. **Polygon**-Clip (Sutherland–Hodgman gegen CLIP-Rechteck), nicht `clip_polyline`. RDP auf Ringe `SIMPLIFY_WU≈48` (gröber als Bäche). `MIN_AREA_WU2≈400000` (~0,11 ha) — winzige Haine droppen. Geschlossenen Ring nicht doppelt speichern. Output-Schema:
   ```
   {
     "meta": { "source": "OSM Overpass landuse=forest|natural=wood", "church": [...], "clip": [...] },
     "forests": [
       { "name": "Buechwäldli", "osm": "forest", "points": [[x,y], ...], "centroid": [x,y] },
       { "name": "", "osm": "wood", "points": [...], "centroid": [x,y] }
     ],
     "silhouettes": [
       { "name": "Buechwäldli", "art": "a", "pos": [x,y] }
     ]
   }
   ```
   `python3 scripts/gen_seuzach_forests.py` schreibt `data/seuzach_forests.json`.
   **Silhouetten im Generator** (wenige, nicht pro Way): je **eine** Position in den Regionen
   - `village_edge` (Buechwäldli und/oder Laubholz / Ost-Dorfrand)
   - `forrenberg_a1` (nahe `forrenberg_world()`, y > 8000, x > 5000)
   - `ohringen` (x < −15000, y > 8000)
   - optional `north` (y < −8000)
   je am Centroid des **größten** CLIP-Patches der Region. **Max 8** Einträge gesamt. `art`: default `"a"` (`landmark_wald_a.png`). Höchstens **eine** `"b"` auf einem Patch **ohne** nahen Bach (Centroid-Distanz zu allen Stream-Polylinien **> 800 wu**), weil `landmark_wald_b.png` Bach/Brücke eingebrannt hat. Abstand Silhouette-Pos zu Badi/Bahnhof/Schul-Ankern **≥ 500 wu**; zu `hub_enter_pos()` **≥ 400 wu**. `data/README.md` um Dump+Generator ergännen.
3. **Kein `forest_kit.gd`.** In `world_sandbox.gd`: Holder-Node `Forests` unter `%Ground`. Pro JSON-Ring ein `Polygon2D`: `color = COLOR_FOREST_FLOOR`, `z_index = -48`, Meta `forest_kit=floor` **und** `terrain=forest`. **Keine** Line2D, **keine** Collision, **keine** Ground-Sprites.
4. **`world_sandbox.gd`:** `FORESTS_JSON := "res://data/seuzach_forests.json"`. In `_build_flat_ground` nach dem Gras-Rect, **vor** Streams:
   ```
   _add_forest_floors()
   _add_continuous_streams()
   _add_continuous_roads()
   _add_continuous_rails()
   ```
   - Marker analog Streams: `forest_name`, `osm`, `forest_points`, `poi_type=forest`, Position = Centroid
   - **Kein** `road_name`, kein `railway_name`, kein `stream_name`
   - Parent `%Ground`, nicht `%Props`, nicht `DistrictOhringen`
   - Kommentar „no forest floors“ entfernen
   **`_place_landmarks`:** nach `_place_badi()` → `_place_forest_silhouettes()`:
   - **Nicht** `_add_prop` (das hängt `BuildingCollision` an)
   - Eigene Helper: Sprite, `LANDMARK_SCALE` (oder leicht größer, nicht baumklein), `feet_offset_y`, `compute_prop_z`, Metas `terrain=forest`, `landmark_id=wald`, `forest_name`, `art` a|b
   - Parent `%Props` (Ohringen-Silhouetten **nicht** unter `DistrictOhringen`)
   - `has_building_collision` **nicht** setzen
   - `_place_school_clusters` / Kigas / Bahnhof / Badi / HubEnter / Streams **nicht** ändern
5. **Tests zuerst/mit:**
   - **`_run`:** `forest_n == 0` → `forest_n >= 1` (Message nicht mehr „no forest props“). `house_n == 0` **behalten**.
   - **`_assert_railway` / `_assert_badi` / `_assert_streams`:** `forest_n == 0` → `forest_n >= 1`; `house_n == 0` **behalten**. Stream-Sprite-Negativ in `_assert_badi` **behalten**. `_assert_streams` weiter aufrufen (Bäche bleiben).
   - Neue `_assert_forests(world, sprites)` aus `_run` **nach** `_assert_streams`:
     - `data/seuzach_forests.json` existiert
     - Ground-Holder `Forests`; `forest_kit=floor` **≥ 3**; 0 Line2D
     - Ground-Marker `poi_type=forest` **≥ 3**
     - Point-in-Polygon (oder Distanz Centroid **≤ 80 wu** zum Sample) für:
       - **Buechwäldli** `gps_to_world(47.5306911, 8.7357986)` (way `31766718`) — Marker `forest_name=Buechwäldli` **oder** Sample in irgendeinem Forest-Ring
       - **A1/Forrenberg** `gps_to_world(47.5281998, 8.7332964)` (way `1033172691`) — Distanz `forrenberg_world()` zu einem Forest-Centroid **< 6000 wu** **oder** Sample im Ring
       - **Ohringen** `gps_to_world(47.5262718, 8.7123371)` (way `43018831`) — Distanz `ohringen_world()` zu einem Forest-Ring **< 5000 wu**
       - **Nord** `gps_to_world(47.5402506, 8.7179862)` (way `40559092`) **oder** ein Marker/Ring mit Centroid `y < -8000`
     - Props: `terrain=forest` **≥ 3** und **≤ 10** (Silhouette, kein Baumteppich)
     - `house_n == 0`; keine Hill-Marker
     - Schulen je 3 + vier Kigas + Bahnhof Count=1 + Badi Count=1; Stream-Marker `poi_type=stream` ≥ 1; Railway-Marker bleiben
     - Parent-Kette der Forest-**Boden**-Marker ohne `DistrictOhringen`
     - `_assert_sprite_off_named_roads` **nicht** über Wald-Sprites laufen lassen (A1 durch Wald ist maps-getreu)
     - **Kein** Assert auf Lindberg/Wolfensberg/Schoren
     - Silhouette-Sprites: 0 `BuildingCollision` / kein `has_building_collision`
   - `m2_world_test`: weiter 0 Line2D, 0 Ground-Sprite2D, `ground_polys <= 4000` (Holder `Forests`); RoadKit-Counts unverändert
   - **Kein** neues `m2_forest_kit_test.gd`; `run_tests.sh` unverändert sofern kein neuer Testfile
6. **Art-Gate:** Default **kein** `comic-rettung-art`. `landmark_wald_a.png` ist ein Baumcluster auf Transparenz — als Silhouette auf `COLOR_FOREST_FLOOR` gedacht. `landmark_wald_b.png` enthält eingezeichneten Bach/Pfad/Brücke — nur 0–1×, nicht über WaterKit. Neue Art nur nach Playtest-Fail (Boden=Gras / Silhouette=Diorama / weisse Platte).
7. Suite `./scripts/run_tests.sh`. Playtest: Buechwäldli südlich der Kirche (Zoom ~0,4), Forrenberg-Wald bei A1/HubEnter, Ohringen-Waldrand, Nordwald; Bäche im Wald noch blau; Strasse über Wald; Schulen/Kigas/Bahnhof/Badi/Gleise unangetastet; **keine Häuser**, keine Hügel.

## Testplan

### Automatisiert

- [x] `data/seuzach_forests.json` existiert; Buechwäldli-Sample (way `31766718`) auf/in einem Forest-Ring
- [x] A1/Forrenberg-Sample way `1033172691` und Ohringen-Sample way `43018831` maps-getreu (Ring oder Distanz-Guard)
- [x] Seuzach-Nord: Ring oder Marker mit `y < -8000` (way `40559092` bevorzugt)
- [x] Ground `forest_kit=floor` ≥ 3; Holder `Forests`; **keine** Ground-Sprites; 0 Line2D
- [x] Props `terrain=forest` ≥ 3 und ≤ 10; **kein** Housing; keine Hill-Marker
- [x] Alle drei Schul-Campi, vier Kigas, Bahnhof, Gleis-Kit, Badi, **Bäche** weiter platziert
- [x] Off-Road der Gebäude gegen **Strassen** unverändert (Wälder nicht in `road_name`)
- [x] Poly-Cap 4000 hält (Holder); `m2_world_test` / S01–S11-Asserts grün
- [x] Wald-Sprites ohne BuildingCollision

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Dunkleres Waldgrün `#2F9A45` als Flächen am Dorfrand, zur A1/Forrenberg und um Ohringen — nicht ein Vollteppich über dem Dorfkern
- [x] Wenige Baumcluster-Silhouetten, kein Nadelwald aus Einzelbäumen
- [x] Bäche **über** dem Waldboden (blau im Wald); Strassen **über** dem Wald; Gleise unverändert über der Strasse
- [x] HubEnter am Forrenberg weiter unsichtbar/betretbar; Silhouette nicht auf der Enter-Zone
- [x] Spieler kann Wald queren; keine neue Collision
- [x] Y-Sort: Boden auf Ground; Silhouetten als Props; Landmarken nicht vom Wald zugedeckt als „Gebäude im Dickicht“-Bug
- [x] Schulen, vier Kigas, Bahnhof, Gleise, Badi, Bäche sichtbar; **keine Häuser**, keine Hügel
- [x] Keine weissen/schwarzen AI-Platten
- [x] Waldgrün ≠ Gras `#3DCC5A`, ≠ Asphalt `#8E8E8E`, ≠ Himmel `#4DA3FF`
- [x] `landmark_wald_b` falls benutzt: nicht als zweiter Bach über dem Chrebsbach lesbar

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. `_assert_forests` (11 `forest_kit=floor`, 11 Ground-Marker, Buechwäldli named, A1/Forrenberg hit d=5142, Ohringen ring d=698, Nord y<−8000, silhouettes 3, `wald_a_0`/`wald_b_1`/`wald_a_2` off brooks d=8304/13144/11942 ≥400, `house_n=0`, Campi je 3, vier Kigas, Bahnhof, Badi, 15 Streams); `m2_world_test` 0 Line2D, 0 Ground-Sprites, polys 1912 ≤4000 (Forests-Holder). Smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s12-buechwaeldli.png` (player at `gps_to_world(47.5306911, 8.7357986)` ≈ `(13720, 5902)`, zoom 0.4): Waldboden `#2F9A45` füllt den Frame (97%), ein `wald_a`-Cluster, keine Häuser/Platten. Wide `/tmp/s12-buechwaeldli-wide.png` (zoom 0.18): Patch 76% Waldgrün vs 21% Gras `#3DCC5A` + Asphalt am Rand — kein Vollteppich. Forrenberg `/tmp/s12-forrenberg-wald.png`: eine `wald_b`-Silhouette weit weg von WaterKit (d=13144); eingezeichneter Bach nur im Sprite, nicht über Chrebsbach. Keine neuen PNGs; Art-Fallback `landmark_wald_c.png` nicht nötig.

## Art-Bedarf

- [x] Keine neuen Assets *(Default — Boden = Cel-Polygon `COLOR_FOREST_FLOOR`; Silhouette = bestehende `landmark_wald_a.png` / `_b.png`)*
- [ ] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur falls Playtest den Boden nicht als Wald liest oder die Cluster-PNGs als Diorama/Bach stören**

**Warum kein Art-Default:** `GEO_ART` enthält bereits zwei Wald-Cluster. `wald_a` ist ein Baumfleck auf Transparenz und sitzt auf der Bodenfläche. RoadKit/WaterKit-Sprache (Cel-Polygon) gilt für den Boden — Kontur sitzt in der Farbkante Gras→Wald, nicht als Sprite-Outline um die ganze Gemarkung.

**`wald_b`-Hinweis:** Asset enthält Bach, Steg und Pfad. Nicht als Flächen-Ersatz, nicht auf Stream-Bändern. Bevorzugt überall `wald_a`.

**Fallback (nur nach Playtest-Fail „unsichtbar / sieht aus wie Wiese / wald_b = Bach-Szene“):**

- Genau **eine** neue Datei `assets/art/landmark_wald_c.png` — reiner Baumcluster, Stil C, **ohne** Gewässer/Brücke/Pfad, transparente Fläche
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Satellit/Street View Waldrand Seuzach (Buechwäldli / Forrenberg-A1 / Ohringen), nicht Schwarzwald-Panorama
- Pipeline: `process_art_alpha.py` → `verify_art_alpha.py`; Walk-Pad entfällt; ggf. `godot --headless --path . --import`
- Keine Einzelbaum-Sets, keine Hügel-Art, keine Gebäude-Art, keine Bach-Art

## Akzeptanzkriterien

- [x] Grenzen: nur Forest-JSON + Boden-Polygone + wenige Silhouetten; S01–S11 unangetastet; kein Housing, keine Hügel, nicht jeder Baum
- [x] OSM-Wälder in CLIP: Dorfrand (Buechwäldli Pflicht-Richtung), A1/Forrenberg, Ohringen; Nord falls CLIP hält; Winterthur-Tails nicht erzwingen
- [x] Ein Natur-Feature (Flächen + wenige Sprites), 0 Line2D, z unter WaterKit
- [x] Tests: `forest_n >= 1` (und ≤ 10), Forest-Presence auf Ground, `house_n == 0`; Suite grün
- [x] Style C lesbar (Wald ≠ Gras ≠ Asphalt); bestehende Cluster-PNGs oder dokumentierter Art-Fallback
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass

**Danach (Parent, nicht dieser Slice):** INDEX-Zeile S12 → `erledigt`; Aufgaben-INDEX **Erledigt** nach Git dieses Slices.
