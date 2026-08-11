# Slice: S11 — Bäche / Riedbach

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S11-baeche-riedbach.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

**Bäche und Flüsse** (Riedbach und lokale Bäche laut OSM/Maps) sind in der Welt als Wasserläufe erkennbar — stilisiert, aber in Lage und Verlauf maps-getreu.

## In diesem Schritt

- Wasserläufe als ein Natur-Feature (Patches/Polylinien), nicht jeder Graben als eigener Slice
- Verlauf nach OSM/Maps (Riedbach + Dorf-Bäche)
- Stil C; Art nur soweit nötig

## Nicht (andere Feature-Schritte)

- Wälder (`S12`)
- Gebäude-Landmarken, Gleise, Wohnhäuser

## Ziel

Spieler sieht in der Seuzach+Ohringen-CLIP **ein** Natur-Feature: OSM-getreue **Bach-Bänder** (Polygon2D, Stil-C-Blau) für den **Chrebsbach** und die übrigen benannten Dorf-Bäche. Kein Bach-Sprite, kein Graben-für-Graben. Bäche liegen **unter** RoadKit-Asphalt (Brücken/Dolen), über dem Gras. Schul-Campi, vier Kigas, Bahnhof, Gleis-Kit und Badi bleiben. Keine Wälder, keine Häuser. OSM-**Riedbach** (Eulach-Zufluss, Oberwinterthur) liegt **ausserhalb** der CLIP — nicht in die Welt ziehen.

## Scope

### In

- **Ein** Natur-Feature: OSM `waterway=stream|river|drain` durch die CLIP-Welt, als Kit-Band unter `%Ground` (nicht als Landmark-Sprite, nicht als hunderte PNGs)
- Generator + JSON analog zu Gleisen (S09): Overpass-Dump → Weltkoordinaten → Ribbon-API
- Benannte Läufe mergen (inkl. `tunnel=yes` / `culvert`-Segmente, die an benannte Ways anschliessen)
- Marker unter `%Ground` für Tests (`stream_name` / `stream_points` / `poi_type=stream`), **ohne** `road_name` (Off-Road-Asserts der Gebäude bleiben Strassen-only)
- Tests: S10-Platzhalter „keine Stream-Sprites“ **behalten** (Kit ≠ Sprite); neue Presence-Asserts auf Ground; `forest_n == 0` **bleibt** bis S12; S01–S10 bleiben grün; Housing weiter abwesend
- Art: **Default keine neuen PNGs** (Cel-Blau im Kit)

### Nicht

- Wälder / Forest-Floor / `landmark_wald_*.png` (`S12`) — `forest_n == 0` nicht umdrehen
- Jeder Feldgraben (`waterway=ditch`), jeder unbenannte Stummel, jeder Weiher/`natural=water` (Badi-Becken bleiben im S10-Sprite)
- OSM-**Riedbach** `waterway=river` in Oberwinterthur (~47.51 N, 8.76 E, CLIP-Welt ≈ `(52000, 47000)`) — CLIP nicht erweitern, Winterthur-Tails nicht zeichnen
- Gebäude-Landmarken, Gleise, Badi-PNG, Housing; Feuerwehr, Gemeindehaus, Kirchen, Läden, Tankstelle, HubEnter
- `seuzach_roads.json` / `gen_seuzach_roads.py` / `seuzach_rails.json` / RailwayKit umbauen
- Collision auf Bächen (wie Strassen/Gleise: visuell, Spieler kann queren) — keine BuildingCollision, kein „leichtes“ Wasser-StaticBody
- `Sprite2D.rotation`; Parent `DistrictOhringen` für Bäche
- Line2D auf `%Ground` (`m2_world_test` verbietet das)
- Bach-Marker als `road_name` oder als Prop-Sprite `poi_type=stream`

### Raster / GPS / OSM

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`). Dieselbe CLIP wie Roads/Rails: `(-25000, -24000, 32000, 18000)`.

**Overpass-BBox** (wie S09, CLIP in WGS84):

| | lat | lon |
|--|-----|-----|
| Süd-West | 47.52493 | 8.70849 |
| Nord-Ost | 47.54493 | 8.74869 |

Fetch etwas **größer**, dann im Generator clippen:

```
south=47.5200 west=8.7000 north=47.5550 east=8.7600
```

Query (Wasserwege, nicht highway/railway, nicht `natural=water`):

```
[out:json][timeout:90];
(
  way["waterway"~"^(stream|river|drain)$"](47.5200,8.7000,47.5550,8.7600);
  relation["type"="waterway"]["waterway"~"^(stream|river|drain)$"](47.5200,8.7000,47.5550,8.7600);
);
out tags geom;
```

Nicht in `seuzach_ways.json` / `seuzach_rails_osm.json` mischen. Dump: `data/seuzach_water_osm.json`. Generiert: `data/seuzach_water.json`.

**Ist-Overpass 2026-08-11** (Fetch-BBox, `waterway=stream|river|drain`, 191 Ways; `ditch` extra und **ausgeschlossen**):

Kein `name=Riedbach` in Fetch **noch** CLIP. OSM-Riedbach (Wikipedia: Zufluss der Eulach, Oberlauf Wiesenbach/Wiesendangen) sitzt bei ~47.511 / 8.763 — **südöstlich ausserhalb** der spielbaren Welt.

| OSM-Name | Rolle in CLIP | Hinweis |
|----------|---------------|---------|
| **Chrebsbach** | Hauptdorf-Bach, Relation `9503502` | 11 Ways; Dorf-Segment way `13872507` ≈ `(17724, 859)`; Tunnel way `27103617` `layer=-1` ≈ `(5738, −5320)`; West-Schwanz way `13872843` ≈ `(−23224, −2799)` in CLIP; SE-Schwanz way `50408666` ≈ `(38710, 11582)` **ausserhalb** → CLIP-Ost kappen |
| **Welsikonerbach** | Nord-Dorf, westlich der Badi | 29 Ways; Sample way `758678996` **47.5393883, 8.7320363** → ≈ `(8385, −12365)`; ~100 m westlich `badi_world()` |
| **Bachtobelgraben** | Nordost, bei Kiga Bachtobel / Birch | 25 Ways; Sample way `78879599` **47.5362754, 8.7362122** → ≈ `(14307, −5827)` |
| **Ohringerbach** | Weiler Ohringen, Relation `9503503` | 12 Ways; Zentroid oft westlich CLIP (`x < −25000`); Ost-Teile `lon ≳ 8.7085` nach CLIP **behalten** (Campus Ohringen liegt in CLIP) |
| Niederriedgraben | Ost-Dorf, kurz | 3 Ways in Fetch; nach CLIP/MIN_LEN nur wenn Band lesbar |
| übrige benannte | Rand/Nachbarn | Ruppbach, Haldenbach, Äschgraben, Wisenbach, Pfaffenstudenbach, … — nur **nach CLIP + Merge + MIN_LEN**; keine Winterthur-/Dägerlen-Tails erzwingen |
| `(unnamed)` stream | 74 Ways, oft Dolene | nur mergen wenn Endpunkt an benannten Lauf andockt (`CONNECT_WU`); isolierte Stummel **drop** |
| `waterway=ditch` | Feldgräben | **nicht** zeichnen (Slice: nicht jeder Graben) |

Relativlage (Kartenbild, N = kleineres Y):

```
        Welsikonerbach (N, bei Badi)              N
        Bachtobelgraben (NO, bei Kiga Bachtobel)
        Chrebsbach-Tunnel unter Dorf / Landstrasse
        Kirche (0,0)     Bahnhof / Gleise O
        Chrebsbach offen SO des Bahnhofs
        Ohringerbach (SW, Weiler)                 Ohringen-Campus
        OSM-Riedbach (Eulach) weit SE — nicht in CLIP
```

z-Stack Ground (bestehend, S11 fügt Water ein):

| Layer | z | Slice |
|-------|---|-------|
| Gras-Canvas | −50 | m2 |
| **Bach-Bank / Wasser** | **−46 / −45** | **S11** |
| RoadKit Trottoir / Asphalt / Streifen | −41 / −40 / −39 | Roads |
| Railway Perron / Schotter / Schiene | −38 / −37 / −36 | S09 |
| Props/Spieler | ~2000+ | Landmarken |

Bäche **unter** Asphalt: Strassen und Brücken decken Dolen; offene Läufe im Gras bleiben blau. Gleise bleiben über der Strasse (S09 unverändert).

**Ist-Zustand:** `_add_continuous_roads()` + `_add_continuous_rails()`; kein Water-JSON. `_assert_badi` fordert `_count_poi(sprites, "stream") == 0`. `forest_n == 0` in `_run` / Railway / Badi. `COLOR_FOREST_FLOOR` existiert, wird nicht platziert.

## Systeme

- `scripts/gen_seuzach_water.py` (**neu**, nicht Roads/Rails-Generator erweitern) — Overpass-Dump → CLIP/RDP/Merge → `data/seuzach_water.json`
- `data/seuzach_water_osm.json` + `data/seuzach_water.json` + `data/README.md`
- `scripts/water_kit.gd` (**neu**) — Polygon2D-Bänder, eigene Farben/`water_kit`-Metas; kein Asphalt, keine Schienen, keine Line2D
- `scripts/world_sandbox.gd` — `_add_continuous_streams()` in `_build_flat_ground` **nach** Gras, **vor** Roads (z erledigt die Brücke); Landmark-Platzierung S01–S10 unverändert
- `tests/m3_world_landmarks_test.gd` — `_assert_streams`; Sprite-Negativ `stream==0` in `_assert_badi` **behalten**; `forest_n==0` **behalten**
- `tests/m2_water_kit_test.gd` (**neu**) — Kit ohne Line2D, Miter wie RoadKit
- `tests/m2_world_test.gd` — Line2D=0 und `ground_polys <= 4000` (WaterKit unter `Streams`-Holder, analog Rails)
- `scripts/run_tests.sh` — neuen Kit-Test eintragen
- Art: **Default keine neuen PNGs** (Cel-Hex im Kit)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Strassen+Gleise+Landmarken stehen, Bachkorridore sind Gras-Lücken; Tests verbieten Stream-Sprites und Forest-Props).

## Technische Schritte

1. **Daten:** Overpass wie oben → `data/seuzach_water_osm.json` committen (kein Netz in Tests). Filter im Generator:
   - Keep: `waterway` ∈ {`stream`, `river`, `drain`}
   - Drop: `waterway=ditch`, `natural=water`, `waterway=canal`, abandoned
   - Name: benannte Ways behalten; unbenannte nur wenn sie an eine benannte Polylinie andocken (`CONNECT_WU≈90`)
   - `name=Riedbach`: mitnehmen **falls** im Dump (heute 0 in CLIP) — Generator darf 0 Riedbach-Tracks schreiben, Tests **fordern** Riedbach **nicht**
   - Ignorieren: Badi-Becken-Ways (`leisure=swimming_pool`), Weiher als Fläche
2. **`gen_seuzach_water.py`:** dieselben `gps_to_world` / `CLIP` / `rdp` (`SIMPLIFY_WU≈22`, Bäche mäandrieren stärker als Gleise) / `merge_polylines` / `clip_polyline` wie Rails. Nach Merge Name vom längsten benannten Stück der Kette. Output-Schema:
   ```
   {
     "meta": { "source": "OSM Overpass waterway=stream|river|drain", "church": [...], "clip": [...] },
     "streams": [
       { "name": "Chrebsbach", "waterway": "stream", "points": [[x,y], ...] },
       { "name": "Welsikonerbach", "waterway": "stream", "points": [...] }
     ]
   }
   ```
   Keine `junctions`. `python3 scripts/gen_seuzach_water.py` schreibt `data/seuzach_water.json`. `MIN_LEN_WU≈400` (~21 m) nach CLIP — kurze CLIP-Randstücke benannter Läufe (Ohringerbach) mit `MIN_LEN_WU≈140` falls Name ∈ {Chrebsbach, Welsikonerbach, Bachtobelgraben, Ohringerbach}. `data/README.md` um Dump+Generator ergänzen.
3. **WaterKit** (eigene Datei, `m2_road_kit_test` / Railway-Farben unangetastet):
   - `add_polyline(parent, points, opts)` → optional schmaleres Bank-Band + Füll-Band (Miter wie RoadKit/RailwayKit)
   - `half_w` Default **16 wu** (~0,85 m halbe Breite, ~1,7 m lesbares Band); `river` darf `24` wenn je ein river in CLIP liegt
   - Farben Stil C, **nicht** `COLOR_ROAD` / nicht Marina-Türkis `#00BFA5` / nicht identisch Himmel `#4DA3FF`: Wasser `#2E8FD4`, Bank `#1F6FB0`
   - Metas `water_kit` = `water` | `bank` (nicht `road_kit`, nicht `railway_kit`)
   - z: Bank **−46**, Wasser **−45** (über Gras −50, unter Trottoir −41)
   - **Keine** Line2D. **Keine** Wellen-Sprites. **Keine** Collision-Bodies
4. **`world_sandbox.gd`:** `WATER_JSON := "res://data/seuzach_water.json"`. In `_build_flat_ground` nach dem Gras-Rect, vor `_add_continuous_roads()`:
   ```
   _add_continuous_streams()
   _add_continuous_roads()
   _add_continuous_rails()
   ```
   - Holder-Node `Streams` unter `%Ground` (wie `Rails`) — Direct-Child-Poly-Cap in `m2_world_test` bleibt
   - Tracks via WaterKit; Marker analog Railway, aber `stream_name`, `waterway`, `half_w`, `stream_points`, `poi_type=stream`
   - **Kein** `road_name`, kein `railway_name`
   - Parent `%Ground`, nicht `%Props`, nicht `DistrictOhringen`
   - `_place_landmarks()` / Schulen / Kigas / Bahnhof / Badi / Rails **nicht** ändern
   - Keine BuildingCollision auf Bächen
5. **Tests zuerst/mit:**
   - **`_assert_badi`:** Zeile `_count_poi(..., "stream") == 0` **behalten** (Sprite-POI bleibt 0). `forest_n == 0` **behalten**. Kein Housing.
   - **`_run` / `_assert_railway`:** `forest_n == 0` **nicht** umdrehen (S12).
   - Neue `_assert_streams(world, sprites)` aus `_run` nach `_assert_badi`:
     - Sprite-POI `stream` **== 0**; Landmark `riedbach` / `bach` **null**
     - Ground-Marker `poi_type=stream` **≥ 1**; darunter `stream_name=Chrebsbach` vorhanden
     - `stream_points`: Distanz Sample **Chrebsbach** `gps_to_world(47.5330924, 8.7386221)` (way `13872507`) zur Chrebsbach-Linie **≤ half_w + 80 wu**
     - Distanz Sample **Welsikonerbach** `gps_to_world(47.5393883, 8.7320363)` (way `758678996`) zur Welsikonerbach-Linie **≤ half_w + 80 wu** (oder Marker `stream_name=Welsikonerbach`)
     - `Bachtobelgraben` **oder** Distanz `kiga_bachtobel_world()` zu irgendeiner Stream-Polylinie **< 4000 wu**
     - Ohringen: Marker `Ohringerbach` **oder** Distanz `ohringen_world()` zu einer Stream-Polylinie **< 5000 wu** (CLIP schneidet den Westschwanz)
     - Chrebsbach überspannt das Dorf: min. x **< 8000** und max. x **> 15000**, oder Länge **> 12000 wu**
     - `water_kit=water` ≥ 1; 0 Line2D (Suite-weit)
     - **Kein** Housing; **`forest_n == 0`**; keine Hill-Marker
     - Schulen je 3 + vier Kigas + Bahnhof Count=1 + Badi Count=1; Railway-Marker bleiben
     - Parent-Kette der Stream-Marker ohne `DistrictOhringen`
     - `_assert_sprite_off_named_roads` **nicht** über Bach-Polylinien laufen lassen
     - **Kein** Assert `stream_name=Riedbach` (liegt nicht in CLIP)
   - Kit-Unit-Test: polyline erzeugt `water_kit` water (+ optional bank), 0 Line2D, 0 `road_kit`, Biege-Ecke gefüllt
   - `m2_world_test`: weiter 0 Line2D, `ground_polys <= 4000` (Holder `Streams`); RoadKit-Counts unverändert
   - `run_tests.sh`: `tests/m2_water_kit_test.gd` einfügen (nach `m2_railway_kit_test.gd`)
6. **Art-Gate:** Default **kein** `comic-rettung-art`. Nur wenn Playtest Blau=Himmel oder Blau=Gras liest: eine kachelbar Cel-Wasserfläche, siehe Art-Bedarf.
7. Suite `./scripts/run_tests.sh`. Playtest: Chrebsbach SO Bahnhof (Zoom 0,5), Welsikonerbach bei Badi, eine Strassenquerung (Bach unter Asphalt), Ohringen-Rand; Schulen/Kigas/Gebäude/Gleise nicht umbauen; **keine** Wald-Patches.

## Testplan

### Automatisiert

- [x] `data/seuzach_water.json` existiert; Chrebsbach-Polylinie maps-getreu (Sample way `13872507` liegt am Band)
- [x] Welsikonerbach-Sample way `758678996` am Band oder gleichnamiger Marker
- [x] Ground-Marker `poi_type=stream` ≥ 1; **keine** Sprite-POIs `stream`; **kein** Landmark-Bach-PNG
- [x] OSM-Riedbach nicht in der Welt (kein Zwang-Marker `Riedbach`)
- [x] Alle drei Schul-Campi, vier Kigas, Bahnhof, Gleis-Kit, Badi **weiter platziert**
- [x] `forest_n == 0`; kein Housing; keine Hill-Marker
- [x] Off-Road der Gebäude gegen **Strassen** unverändert (Bäche nicht in `road_name`)
- [x] 0 Line2D auf Ground; Poly-Cap 4000 hält (Holder)
- [x] `m2_water_kit_test` / `m2_world_test` / S01–S10-Asserts grün

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Blaue Bänder im Gras: Chrebsbach durchs Dorf (nicht ein E–W-Balken auf der Winterthurerstrasse), Welsikonerbach nördlich bei der Badi, Bachtobelgraben NO lesbar
- [x] Strassen **über** dem Bach (Asphalt deckt Dolen/Brücken); Gleise unverändert über der Strasse
- [x] Ohringerbach am Weiler-Rand oder CLIP-Schnitt, nicht durch den Schulhof als See
- [x] Kein Winterthur-Riedbach-Fluss im SE-Offscreen herangezogen
- [x] Spieler kann Bäche queren; keine neue Collision
- [x] Y-Sort: Wasser auf Ground unter Füßen; Landmarken-Sprites decken die Bäche nicht fälschlich als See zu
- [x] Schulen, vier Kigas, Bahnhof, Gleise, Badi sichtbar; **keine Wälder**, keine Häuser
- [x] Keine weissen/schwarzen AI-Platten (keine neuen Sprites erwartet)
- [x] Cel-Blau ≠ Gras `#3DCC5A`, ≠ Asphalt `#8E8E8E`, ≠ Himmel-Platte über der Karte

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. `m2_water_kit_test` (water `#2E8FD4` z=−45, bank, 0 Line2D) und `_assert_streams` (15 water/15 stream markers, Chrebsbach d=8.8, span x −25000..32000, Welsikonerbach d=0, Bachtobelgraben d=524, Ohringerbach d=1719, `riedbach_n=0`, `forest_n=0`); smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s11-chrebsbach.png` (player at `gps_to_world(47.5341937, 8.7386451)` ≈ `(17757, −1455)`, zoom 0.5): Cel-Blau-Band `#2E8FD4` + Bank `#1F6FB0` diagonal durchs Gras `#3DCC5A`, Asphalt `#8E8E8E` daneben/darüber — nicht asphaltgrau, kein E–W-Balken. Crossing `/tmp/s11-chrebsbach-crossing.png` (zoom 0.28): Strasse über dem Bach. Kit-Polygone, keine neuen PNGs; `house_n=0`, Campi je 3, vier Kigas, Bahnhof, Badi. Art-Fallback `water_stream.png` nicht nötig.

## Art-Bedarf

- [x] Keine neuen Assets *(Default — Kit-Polygone mit Stil-C-Hex, analog RoadKit/RailwayKit)*
- [ ] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur falls Playtest das Band nicht als Bach liest**

**Warum kein Art-Default:** RoadKit/RailwayKit zeichnen bereits Cel-Polygone. Dieselbe Sprache für Wasser vermeidet Wellen-PNGs und hält `verify_art_alpha` / Import-Gate raus. `c-iso-city-map` zeigt Bänder — Bäche ebenso. Stil C: Kontur sitzt in der Polygon-Kante (dunkle Bank), nicht als Sprite-Outline.

**Fallback (nur nach Playtest-Fail „unsichtbar / sieht aus wie Pfütze / Himmel“):**

- Genau **eine** Datei `assets/art/water_stream.png` (kleine kachelbar Cel-Wasserfläche, sparsame Kontur) als `Polygon2D.texture` auf dem Water-Band
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Satellit Chrebsbach Seuzach (nicht Rhein, nicht Badi-Becken)
- Pipeline: `process_art_alpha.py` → `verify_art_alpha.py`; Walk-Pad entfällt
- Keine Schilf-Sprites, keine Weiher-Flächen, keine Wald-Art, keine Gebäude-Art

## Akzeptanzkriterien

- [x] Grenzen: nur Water-Kit + JSON; S01–S10 unangetastet; keine Wälder/Housing; nicht jeder Graben
- [x] OSM-Streams in CLIP (Chrebsbach Pflicht, weitere benannte Dorf-Bäche); Riedbach-Eulach nicht in die CLIP holen
- [x] Ein Natur-Feature (Ribbons), 0 Line2D, z unter RoadKit
- [x] Tests: Stream-Presence auf Ground, Sprite-POI stream = 0, `forest_n == 0`; Suite grün
- [x] Style C lesbar (Wasser ≠ Gras ≠ Asphalt)
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
