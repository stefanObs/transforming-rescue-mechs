# Slice: S06 — Kindergarten Schneckenwiese

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner / Phase-2 `feature-implementer`  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S06-kiga-schneckenwiese.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Der **Kindergarten Schneckenwiese** ist in der Welt sichtbar: Lage und Ausrichtung nach Maps/OSM (Schneckenwiesenstrasse).

## In diesem Schritt

- `landmark_kiga_schneckenwiese.png` maps-getreu platzieren; GPS-Helfer in `seuzach_geo` ergänzen
- Facing/Grundriss an Google Maps / OSM; neue Art nur wenn Silhouette/Ausrichtung falsch ist

## Nicht (andere Feature-Schritte)

- Die anderen drei Kindergärten *(Bachtobel und Weid bleiben wie S04/S05 platziert — nicht entfernen, nicht umbauen; Ohringen-Kiga bleibt unplatziert)*
- Schul-Campi, Bahnhof, Gleise, Badi, Bäche, Wälder, Wohnhäuser

## Ziel

Spieler sieht im **Dorfzentrum** von Seuzach (Reutlingerstrasse 15, 8472 Seuzach; Primarschule Seuzach) **ein** Kindergarten-Prop neben der RoadKit-Schneckenwiesenstrasse — westlich Campus Birch, nördlich der Reutlingerstrasse, nicht am Campus, nicht am Forrenberg-Hub, nicht in Ohringen. Collision wie Schul-Props; **keine** Sprite-Rotation. Kindergarten Bachtobel und Weid bleiben stehen. Ohringen-Kiga bleibt unplatziert.

## Scope

### In

- Nur **Kindergarten Schneckenwiese**: ein Prop, Node-Name `kiga_schneckenwiese`
- GPS + Getter in `SeuzachGeo`: `KIGA_SCHNECKENWIESE_LAT/LON` + `kiga_schneckenwiese_world()` = Nominatim-Zentroid des OSM-**Gebäudes** (way `140785850`; amenity und building sind derselbe Way)
- Platzierung in `world_sandbox` via `_add_prop` in bestehendem `_place_kindergartens()` (`landmark_kiga_schneckenwiese.png`, `SCHOOL_SCALE` 0.22 wie Schulen) **zusätzlich** zu Bachtobel und Weid
- Metas: `landmark_id=kiga_schneckenwiese`, `kindergarten_id=kiga_schneckenwiese`, `district=schneckenwiese`  
  **Kein** `school_cluster` (sonst zählen Birch/Rietacker/Ohringen-Asserts den Kiga mit)
- Parent: direkt unter `%Props` (wie Bachtobel/Weid), **nicht** unter `DistrictOhringen`
- Collision über bestehendes `_attach_building_collision` (kein Sonderpfad)
- Tests: Schneckenwiese **ist** platziert; Bachtobel **und** Weid **bleiben** platziert; Ohringen-Kiga **bleibt abwesend**; Schul-Campus-Asserts (S01–S03) unangetastet
- Art: bestehende PNG nur behalten, wenn Silhouette zu OSM/Satellit passt — hier **Mismatch** (Einzel-Giebel vs. Doppel-Walm + Flachdach) → Rewrite nur dieser Datei, siehe Art-Bedarf

### Nicht

- Kindergarten Ohringen (`S07`)
- Kindergarten Bachtobel (`S04` erledigt) und Weid (`S05` erledigt): Getter, Prop, Tests **nicht entfernen / nicht umbauen** ausser die Abwesenheits-Schleifen (Schneckenwiese darf nicht mehr als „absent“ gelten)
- Schul-Campi Birch / Rietacker / Ohringen (`S01`–`S03` erledigt — Getter, Cluster-Counts, Off-Road der Schulen nicht umbauen)
- Bahnhof (`S08`), Gleise (`S09`), Badi (`S10`), Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing
- OSM-Schulhof way `1071502860` (`amenity=school`, ~82×51 m) als zweites Prop oder als Sprite-GPS
- Kindertagesstätte / Hort **Haus Süd** (Alterszentrum an der Reutlingerstrasse, Hinder Kalberer 2016–2021) — anderes Gebäude, teilt nur den Spielplatz-Namen
- RoadKit / `seuzach_roads.json` ändern (Schneckenwiesenstrasse und Reutlingerstrasse existieren; Off-Road-Slack ist grün)
- `SCHOOL_SCALE` global ändern
- `Sprite2D.rotation` am Kiga (Iso-¾ wie authored; Lage = Maps-Ausrichtung)
- `DistrictSchneckenwiese`-Node (Meta reicht); **kein** `district=forrenberg` und **kein** `district=ohringen` (Nominatim-Hierarchie-Falle)

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

| | |
|--|--|
| OSM amenity+Gebäude | way `140785850` `amenity=kindergarten`, `building=kindergarten`, `name=Kindergarten Schneckenwiese`, `addr:housenumber=15`, `addr:street=Reutlingerstrasse` — **kein** `roof:shape` / `building:levels` |
| OSM Schulhof (nicht GPS) | way `1071502860` `amenity=school`, `name=Kindergarten Schneckenwiese`, Zentroid 47.5345985, 8.7310212 → Welt ≈ `(6945.4, −2304.7)` (~17 m / 328 wu südlich des Gebäudes) |
| Gemeinde | Primarschule Seuzach, **Reutlingerstrasse 15, 8472 Seuzach** (drei Abteilungen); Lage an der **Schneckenwiesenstrasse** |
| GPS Platzierung | **47.5347527, 8.7310559** (Nominatim-Zentroid way `140785850`) |
| Welt | `kiga_schneckenwiese_world()` ≈ `(6994.6, −2628.6)` · Feld ≈ `(70, −26)` |
| Lage | ~371 m Ost / ~139 m Nord der Kirche; Dorfkern, **westlich** Campus Birch |

Kein separater amenity-Node: Way `140785850` ist Gebäude **und** POI. Ein Getter, ein Prop: Gebäude-Zentroid wie Schulhaus-Props und S04/S05. Den Schulhof-Way nicht als GPS verwenden.

Nominatim `hamlet=Forrenberg` / `village=Oberohringen` in der Adresszeile ist OSM-Hierarchie, **nicht** der A1-Hub (`forrenberg_world()` liegt weit südlich, `y ≈ 15124`) und **nicht** Campus Ohringen (`ohringen_world()` liegt SW, `x ≈ −19840`). Guard: Kiga `4000 < x < 12000` und `-5000 < y < 0`.

Relativlage (Kartenbild, N = kleineres Y):

```
        Kiga Bachtobel weit NE
        Campus Birch O  (~391 m / 7369 wu östlich, etwas nördlich)
                         |
        Schneckenwiesenstrasse (RoadKit, N des Props, d ≈ 558 wu)
                         |
              Kiga Schneckenwiese 15
                         |
        Reutlingerstrasse (collector, S des Props, d ≈ 1142 wu)
        Kirche WSW              A1-Forrenberg weit S (nicht hier)
        Kiga Weid weit OSO
```

OSM-Grundriss way `140785850` (Stand 2026-08-11): bbox ~18 m N–S × ~30 m O–W, gestuft an der Südseite (Eingang `entrance=main` node `3537255601`); längste Kante Nordfassade ~28 m, grob **O–W** (Bearing ~101°). SWISSIMAGE/Esri: zwei südliche Walm-/Pyramidendächer + mittleres begrüntes Flachdach, Spielplatz südlich (roter Fallschutz). Spiel-Sprite bei `SCHOOL_SCALE=0.22` ist visuell ~11,8 m (1014×975 px) — bestehende Schul-Konvention, hier nicht skalieren.

RoadKit: Gebäude-Zentroid vs. `seuzach_roads.json` Schneckenwiesenstrasse (`class=local`, `half_w=36`, 2 Punkte): Füße ≈ 558 wu vs. Need 100 / 50. Nächste anderen: Reutlingerstrasse ~1142 wu (collector), Breitestrasse ~1179 wu, Eibenstrasse ~1189 wu. Off-Road-Asserts sollen ohne JSON-Änderung grün bleiben. `_assert_road_near(..., "Schneckenwiesenstrasse", ..., 900)` passt; Reutlingerstrasse **nicht** als 900-wu-Pflicht (d ≈ 1142).

Ist-Zustand (warum dieser Slice): `_place_kindergartens()` setzt Bachtobel + Weid. `KIGA_IDS` listet Schneckenwiese; `_assert_kiga_bachtobel` und `_assert_kiga_weid` fordern Schneckenwiese **abwesend**. S06 platziert **nur** Schneckenwiese dazu und lockt Ohringen-Kiga weiter auf Abwesenheit. Bachtobel- und Weid-Asserts bleiben; Abwesenheits-Schleifen müssen Schneckenwiese ausnehmen.

## Systeme

- `scripts/seuzach_geo.gd` — GPS-Konstanten + `kiga_schneckenwiese_world()` (Bachtobel-/Weid- und Schul-Getter unangetastet)
- `scripts/world_sandbox.gd` — `_place_kindergartens()` um Schneckenwiese erweitern; Bachtobel- und Weid-Aufrufe bleiben; `_add_prop` + `_attach_building_collision` unverändert
- `tests/m3_world_landmarks_test.gd` — Schneckenwiese-Layout; Bachtobel und Weid weiter vorhanden; Ohringen-Kiga abwesend; Schul-Asserts bleiben
- `tests/m3_building_occlusion_test.gd` — Sample bleibt Birch; neuer Prop westlich Birch darf Occlusion nicht kippen
- `tests/m2_world_test.gd` — nicht regressieren
- Art `assets/art/landmark_kiga_schneckenwiese.png` (bestehend, Silhouette-Rewrite siehe Art-Bedarf)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Schneckenwiese-Kiga nicht platziert, siehe Scope).

## Technische Schritte

1. **`SeuzachGeo`:** Schul-/Bachtobel-/Weid-/Bahnhof-/Badi-/Forrenberg-Konstanten nicht ändern. Neu:
   - `KIGA_SCHNECKENWIESE_LAT := 47.5347527`
   - `KIGA_SCHNECKENWIESE_LON := 8.7310559`
   - `kiga_schneckenwiese_world() -> gps_to_world(...)`  
   Kommentar: OSM way `140785850` Reutlingerstrasse 15 / Schneckenwiesenstrasse (Gebäude=POI), nicht Schulhof-Way `1071502860`, nicht Forrenberg-Hub, nicht Ohringen.
2. **`world_sandbox.gd`:** In `_place_kindergartens()` **Bachtobel und Weid behalten** und **Schneckenwiese hinzufügen**:
   ```
   _add_prop(
     "landmark_kiga_schneckenwiese.png",
     SeuzachGeo.kiga_schneckenwiese_world(),
     SCHOOL_SCALE,
     {"landmark_id": "kiga_schneckenwiese", "kindergarten_id": "kiga_schneckenwiese", "district": "schneckenwiese"},
     "kiga_schneckenwiese"
   )
   ```
   Keine `rotation`. Kein Ohringen-Kiga. Kein `school_cluster`. Kommentar S04+S05 anpassen (Ohringen-Kiga später).
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd`:
   - Neue Funktion `_assert_kiga_schneckenwiese(sprites)` aus `_run` aufrufen (nach `_assert_kiga_weid`).
   - Schneckenwiese **vorhanden:** Node `kiga_schneckenwiese`; Metas `landmark_id` / `kindergarten_id` / `district` wie Scope; `_has_kindergarten(..., "kiga_schneckenwiese")` true.
   - GPS-Konstanten matchen die Tabelle; Getter `distance_to(Vector2(6994.6, -2628.6)) < 1.0`.
   - Position ≤ **80 wu** zum Getter.
   - Quadrant: `x > 4000` und `x < 12000` und `-5000 < y < 0` (Dorfkern, nicht NE-Bachtobel, nicht O-Weid, nicht SW-Ohringen, nicht Forrenberg-Süd).
   - Relativ: `kiga.position.x < birch_world().x - 4000` (westlich Birch); `kiga.position.y > birch_world().y` (südlich Birch, nur ~65 m / 1238 wu — **kein** +3000-Threshold wie Weid); `kiga.position.y > kiga_bachtobel_world().y + 4000` (südlich Bachtobel); `kiga.position.x < kiga_weid_world().x - 4000` und `kiga.position.y < kiga_weid_world().y` (westlich und nördlich Weid); Distanz zu `ohringen_world()` und `forrenberg_world()` jeweils **> 8000 wu**.
   - Parent-Kette enthält **nicht** `DistrictOhringen`.
   - `rotation == 0`; `has_building_collision`.
   - **Bachtobel und Weid bleiben:** `_assert_kiga_bachtobel` und `_assert_kiga_weid` weiter aufrufen; in deren Abwesenheits-Schleifen `kiga_schneckenwiese` **nicht** mehr als absent fordern (Bachtobel-Skip: `kiga_bachtobel` **und** `kiga_weid` **und** `kiga_schneckenwiese`; Weid-Absent-Liste nur noch `kiga_ohringen`). Ohringen-Guard in `_assert_ohringen_campus` darf stehen bleiben.
   - **Ohringen-Kiga abwesend:** `not _has_kindergarten` und `_find_named(..., id) == null` für `kiga_ohringen`.
   - Off-Road: `_assert_schools_off_roads` deckt bereits `kindergarten_id` ab — Schneckenwiese fällt automatisch unter Schneckenwiesenstrasse/Reutlingerstrasse. **Nicht** `school_cluster` am Kiga setzen. Road-JSON nicht anfassen.
   - Optional in `_assert_kiga_schneckenwiese`: `_assert_road_near(ground, "Schneckenwiesenstrasse", SeuzachGeo.kiga_schneckenwiese_world(), 900.0)` — Marker existiert schon, nicht die globale Required-Road-Liste anfassen. Reutlingerstrasse nicht als Pflicht-Nähe (d ≈ 1142 wu).
   - Birch-/Rietacker-/Ohringen-OSM-Blöcke, Cluster-Counts (=3), Bachtobel-/Weid-GPS/Guards **nicht** umbauen.
4. **Occlusion / m2:** keine Sample-Umbiegung auf den Kiga; `m2_world_test` unverändert erwarten.
5. **Art-Gate:** Silhouette kippt (Satellit Doppel-Walm+Flachdach vs. Ist-Einzelgiebel) — `comic-rettung-art` **dieser** PNG, siehe Art-Bedarf. Pipeline: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Schneckenwiese (Bachtobel, Weid und Schul-Campi visuell nicht umbauen).

## Testplan

### Automatisiert

- [x] `kiga_schneckenwiese` in `world_sandbox` unter `%Props` vorhanden, Metas wie Scope
- [x] Position ≈ `kiga_schneckenwiese_world()`, Toleranz 80 wu; Getter ≈ `(6994.6, −2628.6)`
- [x] Guard `4000 < x < 12000`, `-5000 < y < 0`; westlich und südlich von Birch; südlich von Bachtobel; westlich und nördlich von Weid; weit von Ohringen- und Forrenberg-Ankern
- [x] `kiga_bachtobel` **und** `kiga_weid` **weiter platziert** (S04/S05-Asserts bleiben grün)
- [x] `kiga_ohringen` **nicht** platziert
- [x] Kein `school_cluster` am Kiga; Birch/Rietacker/Ohringen bleiben je genau 3
- [x] Off-Road (Füße + AABB) inkl. Schneckenwiesenstrasse ohne Road-JSON-Änderung
- [x] BuildingCollision; `rotation` 0; nicht unter `DistrictOhringen`
- [x] S01–S05 Campus-/Kiga-Asserts und `m2_world_test` grün
- [x] Art-Datei existiert (`REQUIRED_ART` enthält `landmark_kiga_schneckenwiese.png` bereits)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Ein Kindergarten-Gebäude an Schneckenwiesenstrasse / Reutlingerstrasse 15 (Dorfkern, westlich Birch), Füße auf Gras nicht auf Asphalt
- [x] Collision blockiert wie Schulhäuser; Spieler kann an der Fassade vorbei
- [x] Y-Sort: Spieler südlich der Fassade davor, nördlich dahinter
- [x] Bachtobel-Kiga weiter im NE, Weid-Kiga weiter im O sichtbar; kein Ohringen-Kiga-Prop; Schul-Cluster unverändert
- [x] Kein Sprite-Twist; Iso-¾ wie authored
- [x] Keine weissen/schwarzen AI-Platten (`verify_art_alpha`)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. Schneckenwiese-GPS/Off-Road (Schneckenwiesenstrasse feet d=558 / AABB 380; Reutlingerstrasse 1142); smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s06-kiga-schneckenwiese.png` (player at `kiga_schneckenwiese_world()`, zoom 0.55): zwei Walm-Flügel + mittleres Flachdach, Rutsche+Sandkasten lesbar, Füße auf Gras; Schneckenwiesenstrasse nur am Rand, nicht unter dem Prop. Bachtobel und Weid bleiben platziert; Ohringen-Kiga abwesend. Rewrite-PNG bestätigt (kein Einzelgiebel).

## Art-Bedarf

- [ ] Keine neuen Assets *(nicht der Default — Silhouette kippte)*
- [x] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur dieser Kiga** — Rewrite geliefert, Playtest bestätigt Doppel-Walm+Flachdach

**Warum Rewrite (wie S05 Weid / S01 Birch-a, anders als S04 Bachtobel):**

| Quelle | Silhouette |
|--------|------------|
| OSM way `140785850` | `building=kindergarten`, **kein** `roof:shape` / `building:levels`; Grundriss ~30×18 m O–W, Südseite gestuft |
| SWISSIMAGE + Esri (BBOX Gebäude, 2026-08-11) | **zwei** südliche graue **Walm-/Pyramidendächer** + mittleres **begrüntes Flachdach** mit Oberlicht; Spielplatz südlich (roter Fallschutz, Rutsche) |
| Gemeinde | Reutlingerstrasse 15; Kita/Hort Haus Süd ist ein **anderes** Volumen — nicht in diesem Prop |
| Ist-PNG | 1014×975 RGBA, 2-geschossiges **Einzel-Giebel**-Häuschen (gelb, Gaube, Schnecken-Spirale im Sand) — lesbarer Kiga, aber **Giebel ≠ Doppel-Walm+Flachdach** |

Giebel/Walm-Konflikt. Farbe/Spielgeräte (gelb, Rutsche, Schnecken-Motiv im Hof) sind Style-C-Kiga-Sprache und dürfen bleiben — Dach und Baukörper nicht. Bachtobel-PNG nicht anfassen (lachs, Einzelgiebel — passt dort zu OSM `roof:shape=gabled`). Weid-PNG nicht anfassen (mint, ein Flachdach-Pavillon).

**Auftrag `comic-rettung-art` (Phase 2b):**

- Rewrite **nur** `assets/art/landmark_kiga_schneckenwiese.png`, gleicher Pfad
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View / SWISSIMAGE Reutlingerstrasse 15 Seuzach / Satellit Kindergarten Schneckenwiese
- Stil C: Kontur, Cel; kleiner CH-Kiga, **zwei Walm-Flügel + mittleres Flachdach** (kein Einzelgiebel, keine Gaube, kein Alterszentrum-Kubus)
- Spielbereich südlich erlaubt (Rutsche, Fallschutz, optionales Schnecken-Motiv im Hof — nicht als Haus-Silhouette)
- Iso-¾ Default-Facing; **kein** `Sprite2D.rotation`; kein extra Dir-Set
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Bachtobel-/Weid-/Ohringen-Kiga-Art, keine Schul- oder Housing-Art, keine Kita-Haus-Süd-Art

Falls Playtest/Street View **Einzelgiebel** bestätigt (Satellit falsch gelesen): PNG behalten und hier dokumentieren — Default ist Rewrite.

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Schneckenwiese-Kiga neu; Bachtobel und Weid bleiben; kein Ohringen-Kiga; keine Campus-/Bahnhof-/Gleis-/Badi-/Bach-/Wald-/Housing-Änderungen
- [x] Prop auf GPS der Tabelle (±80 wu); Dorfkern, nicht Forrenberg-Hub, nicht Ohringen
- [x] Off RoadKit-Asphalt; Collision wie Schul-Props; keine Sprite-Rotation
- [x] Art: Doppel-Walm+Flachdach-Silhouette Style C **oder** dokumentierter Playtest-Entscheid, dass die Giebel-PNG reicht
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
