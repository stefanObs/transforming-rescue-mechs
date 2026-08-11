# Slice: S10 — Schwimmbad Weiher

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S10-badi-weiher.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Das **Schwimmbad Weiher** (Landstrasse 26, nördlich der Kirche) ist als Outdoor-Badi in der Welt sichtbar; Beckenlage und Ausrichtung folgen Google Maps / OSM.

## In diesem Schritt

- `landmark_badi_weiher.png` maps-getreu platzieren; GPS `BADI_LAT`/`BADI_LON` in `seuzach_geo` (Helfer analog `bahnhof_world()`)
- Facing/Grundriss an Satellit/Maps; neue Art nur wenn Silhouette/Ausrichtung falsch ist
- Freibad, kein Hallenbad

## Nicht (andere Feature-Schritte)

- Schul-Campi, Kindergärten, Bahnhof, Gleise, Bäche, Wälder, Wohnhäuser

## Ziel

Spieler sieht **nördlich** der Kirche an der **Landstrasse 26** **ein** Outdoor-Badi-Prop — 33-m-Becken, Nichtschwimmer, Plansch, lange Rutsche, Hecke — Füße auf der Anlage **neben** dem RoadKit-Asphalt (nicht auf der Landstrasse), Collision wie andere Landmarken, **keine** Sprite-Rotation. Schul-Campi (S01–S03), alle **vier** Kindergärten (S04–S07), Bahnhof (S08) und Gleis-Kit (S09) bleiben stehen. Keine Bäche, keine Wälder, keine Häuser, kein Hallenbad/Spa, keine Extra-Sportplatz-Props.

## Scope

### In

- Nur **Schwimmbad Weiher**: ein Prop, Node-Name `badi_weiher`
- GPS in `SeuzachGeo`: bestehende `BADI_LAT`/`BADI_LON` **behalten** (verifiziert, siehe Raster) + neuen Getter `badi_world()` analog `bahnhof_world()`
- Platzierung in `world_sandbox` via `_add_prop` (`landmark_badi_weiher.png`, `LANDMARK_SCALE` 0.24) aus `_place_landmarks()` — neues `_place_badi()` direkt nach `_place_bahnhof()`
- Parent: direkt unter `%Props`, **nicht** unter `DistrictOhringen`
- Metas: `landmark_id=badi_weiher`, `district=seuzach`, optional `poi_type=swimming`  
  **Kein** `school_cluster`, **kein** `kindergarten_id`, **kein** `district=ohringen` / `forrenberg`
- Collision über bestehendes `_attach_building_collision` (kein Hub-Sonderpfad)
- Tests: Badi **ist** platziert — `_assert_bahnhof` / `_assert_railway` „no badi“ **umdrehen**; `if badi:` in `_assert_geo_quadrants` wird zur Pflicht; S01–S09 bleiben grün; Housing/Wälder/Bäche weiter abwesend
- Art: bestehende PNG **wiederverwenden** (Silhouette passt); Rewrite nur als Playtest-Fallback, siehe Art-Bedarf

### Nicht

- Schul-Campi Birch / Rietacker / Ohringen (`S01`–`S03`): Getter, Cluster-Counts (=3), Off-Road der Schulen **nicht** umbauen
- Kindergärten Bachtobel, Weid, Schneckenwiese, Ohringen (`S04`–`S07`): Getter, Props, Tests **nicht entfernen**
- Bahnhof (`S08`) und Gleis-Kit + Perron 2 (`S09`): `_place_bahnhof()`, `seuzach_rails.json`, RailwayKit **nicht** ändern
- Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing; Feuerwehr, Gemeindehaus, Kirchen, Läden, Tankstelle, HubEnter
- Sportplätze östlich der Anlage (OSM beachvolley `136505929`, volleyball `139073047`, soccer `482858955`) — kein `landmark_sportplatz.png`, keine Extra-Props
- Indoor **Lehrschwimmbecken Birch** (Bachwiesenstrasse / Campus Birch) — anderes Gebäude, anderer Slice-Kontext
- Hallenbad / Spa / Sauna als Silhouette
- RoadKit / `seuzach_roads.json` ändern (Landstrasse existiert; Off-Road-Slack ist grün)
- `SCHOOL_SCALE` / `LANDMARK_SCALE`-Konstanten global ändern
- `Sprite2D.rotation` an der Badi (Iso-¾ wie authored; Lage = Maps-Ausrichtung)
- Parent `DistrictOhringen` (Nominatim-Adresszeile `village=Oberohringen` ist OSM-Hierarchie, **nicht** der Weiler Ohringen)

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

| | |
|--|--|
| OSM Anlage | way `37106305` `leisure=sports_centre` + `amenity=public_bath` + `sport=swimming`, `name=Schwimmbad Weiher`, `alt_name=Schwimmbad Seuzach`, `addr:housenumber=26`, `addr:street=Landstrasse`, `addr:city=Seuzach`, `fee=yes` |
| OSM Becken (nicht als Sprite-GPS) | way `37084074` `leisure=swimming_pool` `length=33` `location=outdoor` · way `37084078` (unregelmäßig, Nichtschwimmer) · way `37084086` (≈15×15 m Quadrat, Sprung) · way `482858953` (klein unregelmäßig, Plansch) |
| OSM Garderoben | way `136505882` `building=yes` südlich der Becken, zur Landstrasse |
| Gemeinde | **Landstrasse 26, 8472 Seuzach**; Freibad seit 1983, Sanierung 2015; ~20 000 m²; 33-m-Becken (6 Bahnen), Nichtschwimmer mit Strömungskanal, Plansch, Sprung 1/3/5 m, **72–73 m** Rutsche |
| GPS Platzierung | **47.5393193, 8.7333710** — Nominatim-Zentroid way `37106305` (**bereits** `BADI_LAT`/`BADI_LON`) |
| Welt | `badi_world()` ≈ `(10277.6, −12220.2)` · Feld ≈ `(103, −122)` |
| Lage | ~648 m Nord / ~545 m Ost der Kirche (~846 m NNO); **nördlich** der Landstrasse; **westlich** Bahnhof; **nicht** Ohringen-SW |

**GPS-Verifikation (kein falscher POI):**

| Kandidat | Koordinate | Urteil |
|----------|------------|--------|
| Nominatim way `37106305` | **47.5393193, 8.7333710** | **Treffer** = Ist-Konstanten. Facility-Zentroid, nicht ein einzelnes Becken |
| Overpass `out center` derselben Way | 47.5391518, 8.7333071 | BBox-Mitte, ~19 m südlich — **nicht** umstellen |
| 33-m-Becken way `37084074` | 47.5389537, 8.732669 | ~53 m W / ~41 m S des Facility-Zentroids — **nicht** als Sprite-GPS (würde die Anlage aufs Becken nageln) |
| Lehrschwimmbecken Birch | Campus Birch / Bachwiesenstrasse | Indoor, **S01**-Kontext, nicht diese Konstanten |
| Nominatim `village=Oberohringen` | Adresszeile | OSM-Hierarchie wie Bahnhof/`hamlet=Forrenberg` — **nicht** `district=ohringen` |

Ein Getter, ein Prop: Facility-Zentroid wie Bahnhof-Gebäude-Zentroid (nicht der `railway=station`-Node, hier nicht das einzelne `leisure=swimming_pool`).

Guard: Badi `x > 5000` und `y < -8000` (Nord-Dorf, nördlich der Kirche), plus Distanz zu `forrenberg_world()` **> 20000 wu** und zu `ohringen_world()` **> 15000 wu**. Altes Quadranten-`y < -200` stammt vom stilisierten Maßstab `(460, −550)` und ist bei Feldskala zu schwach.

Relativlage (Kartenbild, N = kleineres Y):

```
        Erdbühlstrasse / Welsikonerstrasse     N
        Beachvolley (NO der Anlage, kein Prop)
        Sprung ≈15 m (NW)   Nichtschwimmer (N des 33 m)
              33-m-Becken E–W     Plansch (O der Beckengruppe)
        Garderoben-Gebäude (S, zur Landstrasse)
        Landstrasse collector (S-Rand)          ← Address 26
        Kirche SSW                              Bahnhof OSO
        Forrenberg-Hub weit S (nicht hier)
        Ohringen weit SW (nicht hier)
```

33-m-Becken: OSM `length=33`, lange Achse **Ost–West** (Bearing ≈ −90°), südlich von Nichtschwimmer/Sprung innerhalb der Beckengruppe. Anlage-BBox ~169 m N–S × ~233 m O–W. Spiel-Sprite bei `LANDMARK_SCALE=0.24` ist visuell ~19×13 m (Ist-PNG 1530×1006) — Landmark-Konvention, hier **nicht** auf reale Meter skalieren. Ost-Teil der Anlage (Volleyball/Fussball) bleibt leer (kein Sportplatz-Prop).

RoadKit: Facility-Zentroid vs. `seuzach_roads.json` Landstrasse (`class=collector`, `half_w=52`), E–W-Segment y ≈ −10400: Füße ≈ **1781 wu** vs. Need 116 / AABB Need 66. Nächste anderen: Welsikonerstrasse ~1746 wu, Weiherstrasse ~2191 wu (nicht die Front; nur Namensvetter), Erdbühlstrasse ~2504 wu. Off-Road-Asserts sollen ohne JSON-Änderung grün bleiben. `_assert_road_near(..., "Landstrasse", badi_world(), …)` braucht Slack **2200** (nicht 900 wie Bahnhof/Stationsstrasse) — der Zentroid liegt ~95 m nördlich der Strasse in der 169-m-Anlage.

Ist-Zustand (warum dieser Slice): `_place_landmarks()` setzt Schulen + vier Kigas + Bahnhof. PNG existiert in `REQUIRED_ART`, wird aber **nicht** platziert. `BADI_LAT`/`BADI_LON` existieren, **`badi_world()` fehlt**. `_assert_bahnhof` und `_assert_railway` fordern `badi_weiher == null`. `_assert_geo_quadrants` prüft Badi **nur falls vorhanden** (`if badi:` → `y < -200`). S10 platziert **genau ein** Badi-Prop, ergänzt den Getter und macht die Quadranten-Prüfung zur Pflicht.

### Art-Entscheidung (Reuse vs. Rewrite)

Ist-PNG `assets/art/landmark_badi_weiher.png` (1530×1006 RGBA) ist bereits der Geo-Realign-Rewrite: Outdoor-Komplex, 6-Bahn-Becken, Nichtschwimmer, Plansch mit Pilz, lange gelbe Rutsche + Turm, Hecke, Garderoben-Trakt — **kein** Hallenbad, keine Burg-Spiralrutsche, kein Hex-Plansch.

Facility-Facing: Canvas-unten = Süd = Garderoben/Landstrasse; Beckengruppe „dahinter“ (N) — passt zu OSM-Gebäude `136505882` südlich der Becken.

Innere Becken-Packung weicht von OSM ab (PNG: Sprung **südlich** des 33 m, Nichtschwimmer **östlich**; OSM: Sprung **NW**, Nichtschwimmer **N**, 33 m E–W). Das ist Icon-Kompression auf ~13 m Höhe für 169×233 m Gelände, **kein** Quadranten-Fehler und **kein** Silhouetten-Kippen (vgl. S08: gebackene Gleise auf der Strassenseite hätten S09 dupliziert).

**Entscheid: Reuse** (gleicher Dateiname). Kein `comic-rettung-art` in Phase 2b, solange Playtest Outdoor-Badi an der Landstrasse liest. Fallback-Rewrite nur wenn Playtest Hallenbad/Spa, fehlende Lange-Rutsche oder Becken **auf** dem Asphalt zeigt.

## Systeme

- `scripts/seuzach_geo.gd` — Kommentar an `BADI_LAT`/`LON`; neuer Getter `badi_world()`; Schul-/Kiga-/Bahnhof-/Forrenberg-Konstanten unangetastet
- `scripts/world_sandbox.gd` — `_place_landmarks()` um Badi erweitern; `_place_school_clusters()` / `_place_kindergartens()` / `_place_bahnhof()` / RailwayKit unverändert; `_add_prop` + `_attach_building_collision` unverändert
- `tests/m3_world_landmarks_test.gd` — Badi-Layout; S01–S09-Asserts bleiben; `if badi:` → Pflicht; Housing/Wald/Hügel-Absents bleiben; „no badi“ in Bahnhof-/Railway-Asserts entfernen
- `tests/m3_building_occlusion_test.gd` — Sample bleibt Birch; neuer Prop mit `landmark_id` fällt unter Feet-Offset-Schleife (`>= 8` bleibt gültig)
- `tests/m2_world_test.gd` — nicht regressieren (`prop_sprites >= 1`)
- Art `assets/art/landmark_badi_weiher.png` (bestehend, Reuse)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Badi-PNG auf Disk, nicht platziert; GPS-Konstanten korrekt ohne Getter; Tests verbieten die Badi absichtlich bis S10).

## Technische Schritte

1. **`SeuzachGeo`:** Schul-/Kiga-/Bahnhof-/Forrenberg-Konstanten nicht ändern. `BADI_LAT`/`BADI_LON` **Werte behalten** (47.5393193 / 8.7333710). Kommentar ergänzen: OSM way `37106305` Landstrasse 26 (`leisure=sports_centre` + `amenity=public_bath`), nicht einzelne `leisure=swimming_pool`-Ways `37084074` / `37084078` / `37084086` / `482858953`, nicht Lehrschwimmbecken Birch, nicht Nominatim-`village=Oberohringen` als District. Neu:
   ```
   static func badi_world() -> Vector2:
       return gps_to_world(BADI_LAT, BADI_LON)
   ```
2. **`world_sandbox.gd`:** In `_place_landmarks()` **Schulen, alle vier Kigas und Bahnhof behalten**. Danach Badi unter `%Props` (`_prop_parent = _props`):
   ```
   _add_prop(
     "landmark_badi_weiher.png",
     SeuzachGeo.badi_world(),
     LANDMARK_SCALE,
     {"landmark_id": "badi_weiher", "district": "seuzach", "poi_type": "swimming"},
     "badi_weiher"
   )
   ```
   Keine `rotation`. Kein `school_cluster`. Kein `kindergarten_id`. Nicht unter `DistrictOhringen`. Kein Bach-/Wald-/Housing-/Sportplatz-Prop. `_place_bahnhof()` und Railway-Pfad nicht anfassen. Kommentar an `_place_landmarks` von „+ Bahnhof“ auf „+ Badi“ anpassen.
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd`:
   - Neue Funktion `_assert_badi(world, sprites)` aus `_run` aufrufen (nach `_assert_railway`, vor oder mit `_assert_geo_quadrants`).
   - Badi **vorhanden:** Node `badi_weiher`; Metas `landmark_id=badi_weiher`, `district=seuzach`; `_find_landmark(..., "badi_weiher")` nicht null; Count = 1.
   - GPS-Konstanten matchen die Tabelle (47.5393193 / 8.7333710); Getter `distance_to(Vector2(10277.6, -12220.2)) < 1.0`.
   - Position ≤ **80 wu** zum Getter.
   - Quadrant: `x > 5000` und `y < -8000` (Nord-Dorf nördlich der Kirche, nicht Forrenberg-Süd, nicht Ohringen-SW).
   - Relativ: `badi.position.y < kiga_bachtobel_world().y` (nördlicher als Bachtobel); `badi.position.x < bahnhof_world().x` (westlich Bahnhof); `badi.position.x > rietacker_world().x`; Distanz zu `forrenberg_world()` **> 20000**; Distanz zu `ohringen_world()` / `kiga_ohringen_world()` **> 15000**.
   - Parent-Kette **ohne** `DistrictOhringen`.
   - `rotation == 0`; `has_building_collision`; **kein** `school_cluster` / `kindergarten_id`; `district != forrenberg` und `!= ohringen`.
   - **S01–S09 bleiben:** drei Campi je 3, vier Kigas, Bahnhof Count = 1; `_assert_railway` weiter aufrufen (Kit bleibt). `house_n == 0`, `forest_n == 0`, keine Hill-Marker, keine Bach-Props.
   - **`_assert_bahnhof`:** Zeile `_find_landmark(..., "badi_weiher") == null` **löschen** (Presence wandert nach `_assert_badi`). Bahnhof-GPS/Off-Road unverändert.
   - **`_assert_railway`:** Zeile `no badi prop` **löschen** (nicht durch Count=1 ersetzen — das ist `_assert_badi`). Schulen/Kigas/Bahnhof-Counts in Railway bleiben.
   - **`_assert_geo_quadrants`:** `if badi:` durch Pflicht ersetzen (`badi != null`, `y < -8000`, `x > 5000`). Hub weiter nur falls vorhanden. Birch/Rietacker/Ohringen/Bahnhof-Blöcke nicht umbauen.
   - Off-Road: `_assert_schools_off_roads` **nicht** um `school_cluster` an der Badi erweitern. In `_assert_badi` `_assert_sprite_off_named_roads(world, badi)` (Need = `half_w+64` / `half_w+14`). Plus `_assert_road_near(ground, "Landstrasse", SeuzachGeo.badi_world(), 2200.0)` — nicht Weiherstrasse (liegt südlicher, nicht die Adresse).
4. **Occlusion / m2:** keine Sample-Umbiegung auf die Badi; `m3_building_occlusion_test` Cluster-Spacing bleibt `school_cluster`; Badi bekommt Feet-Offset-Checks automatisch über `landmark_id`. `m2_world_test` unverändert erwarten.
5. **Art-Gate:** Reuse; `comic-rettung-art` **nicht** starten, solange die PNG Outdoor-Badi mit 33-m-Charakter, langer Rutsche und Hecke bleibt. Pipeline nur falls Fallback-Rewrite: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Badi (Schulen/Kigas/Bahnhof/Gleise visuell nicht umbauen; keine Bäche/Wälder zeichnen).

## Testplan

### Automatisiert

- [x] `badi_weiher` in `world_sandbox` unter `%Props` vorhanden, Metas wie Scope; genau 1
- [x] Position ≈ `badi_world()`, Toleranz 80 wu; Getter ≈ `(10277.6, −12220.2)`; Konstanten = Facility-Zentroid way `37106305`, nicht 33-m-Becken, nicht Birch-Lehrbecken
- [x] Guard `x > 5000`, `y < -8000`; nördlicher als Kiga Bachtobel; westlich Bahnhof; weit von Forrenberg-Hub und Ohringen
- [x] Alle drei Schul-Campi (je 3), alle vier Kigas, Bahnhof und Gleis-Kit **weiter platziert**
- [x] Kein Housing, kein Forest-Prop, keine Hill-Marker, keine Bach-Props, kein Sportplatz-Prop
- [x] Off-Road (Füße + AABB) inkl. Landstrasse ohne Road-JSON-Änderung
- [x] BuildingCollision; `rotation` 0; Parent **nicht** `DistrictOhringen`
- [x] S01–S09-Asserts und `m2_world_test` grün
- [x] Art-Datei existiert (`REQUIRED_ART` enthält `landmark_badi_weiher.png` bereits)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Ein Outdoor-Freibad an Landstrasse 26 (NNO der Kirche), Füße auf Gras/Anlage **nicht** auf Asphalt; Landstrasse südlich lesbar
- [x] Silhouette: Becken + lange Rutsche + Plansch + Hecke; **kein** Hallenbad/Spa; **kein** Indoor-Lehrbecken am Birch-Campus
- [x] Collision blockiert die Anlage; Spieler kann an der Hecke / Fassade und zwischen Badi und Landstrasse vorbei
- [x] Y-Sort: Spieler südlich (Landstrasse-Seite) davor, nördlich hinter/unter je nach Y
- [x] Schulen, vier Kigas, Bahnhof und Gleise weiter sichtbar; keine Wälder, keine Häuser, keine Bäche
- [x] Kein Sprite-Twist; Iso-¾ wie authored
- [x] Keine weissen/schwarzen AI-Platten (`verify_art_alpha` nur bei Art-Fallback)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. `_assert_badi` (GPS way 37106305, getter ≈ `(10277.6, −12220.2)`, d=0, Landstrasse feet d=1781 / AABB 1778, rotation 0, parent `%Props`); smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s10-badi-weiher.png` (player at `badi_world()`, zoom 0.5): Outdoor-Becken + lange gelbe Rutsche + Plansch + Hecke + Garderoben-Trakt Süd; Füße auf Gras `#3DCC5A`, nicht auf Asphalt. Wide `/tmp/s10-badi-weiher-wide.png` (zoom 0.18): Landstrasse-Asphalt `#8E8E8E` **südlich** der Anlage, Prop in der Grünfläche. Reuse-PNG; kein Art-Fallback. Campi je 3, vier Kigas, Bahnhof vorhanden; `house_n=0`.

## Art-Bedarf

- [x] Keine neuen Assets *(Default — bestehende Outdoor-PNG wiederverwenden)*
- [ ] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur diese Badi** — nur wenn Playtest Silhouette/Ausrichtung kippt (siehe Fallback)

**Warum Reuse:**

| Quelle | Silhouette |
|--------|------------|
| OSM way `37106305` | Outdoor `sports_centre` / `public_bath`, Landstrasse 26, ~169×233 m Gelände, Garderoben **südlich** der Becken |
| OSM way `37084074` | 33 m, `location=outdoor`, lange Achse **E–W** |
| Gemeinde / badi-seuzach.ch | 6 Bahnen, Nichtschwimmer+Strömung, Plansch, Sprung 1/3/5 m, 72–73 m Rutsche, Spielplatz, Hecke/Rasen |
| Ist-PNG | 1530×1006: isometrisches Freibad, 6-Bahn-Becken, Nichtschwimmer, Plansch, langer Rutschturm, Hecke, Garderoben-Trakt unten (Süd) |

Innere Becken-Kompassrose ist icon-stilisiert, Facility-Facing (Gebäude/Landstrasse = Canvas-unten = Süd) stimmt. Compact-Landmark wie Bahnhof (~13 m visuell vs. reale Anlage).

**Kein Auftrag an `comic-rettung-art` in Phase 2**, außer Playtest-Fallback:

- Rewrite **nur** `assets/art/landmark_badi_weiher.png`, gleicher Pfad
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Satellit/Street View Landstrasse 26 (nicht Thermalbad, nicht Birch-Lehrbecken)
- Stil C: Kontur, Cel; **Freibad**; 33 m E–W im Südteil der Beckengruppe; Nichtschwimmer nördlich davon; Sprung NW; Plansch östlich; Garderoben nach Süden (Landstrasse); lange Rutsche; Hecke
- **Kein** Hallenbad, keine Sauna-Kuppel, keine Burg-Spirale, keine Sportplatz-Felder als Extra-Volumen
- Iso-¾, **kein** `Sprite2D.rotation`; kein Dir-Set
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Schul-/Kiga-/Bahnhof-/Gleis-/Housing-/Wald-Art

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Badi neu platziert; Schulen + 4 Kigas + Bahnhof + Gleise bleiben; keine Bach/Wald/Housing/Sportplatz-Props
- [x] Prop auf GPS der Tabelle (±80 wu); Nord-Dorf unter `%Props`, nicht Forrenberg-Hub, nicht Ohringen; **nördlich** der Kirche und der Landstrasse
- [x] Off RoadKit-Asphalt (Landstrasse daneben); Collision wie Landmark-Props; keine Sprite-Rotation
- [x] Art: Outdoor-Badi Style C (Reuse); Facing Garderoben zur Landstrasse (Süd)
- [x] `BADI_LAT`/`LON` bleiben Facility-Zentroid way `37106305`; `badi_world()` existiert
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
