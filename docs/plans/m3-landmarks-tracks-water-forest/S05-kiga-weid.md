# Slice: S05 — Kindergarten Weid

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner / Phase-2 `feature-implementer`  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S05-kiga-weid.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Der **Kindergarten Weid** ist in der Welt sichtbar: Lage und Ausrichtung nach Maps/OSM (Weidstrasse / In der Weid).

## In diesem Schritt

- `landmark_kiga_weid.png` maps-getreu platzieren; GPS-Helfer in `seuzach_geo` ergänzen
- Facing/Grundriss an Google Maps / OSM; neue Art nur wenn Silhouette/Ausrichtung falsch ist

## Nicht (andere Feature-Schritte)

- Die anderen drei Kindergärten *(Bachtobel bleibt wie S04 platziert — nicht entfernen, nicht umbauen)*
- Schul-Campi, Bahnhof, Gleise, Badi, Bäche, Wälder, Wohnhäuser

## Ziel

Spieler sieht im **Osten** von Seuzach (Weidstrasse 16, 8472 Seuzach; Primarschule Seuzach) **ein** Kindergarten-Prop neben der RoadKit-Weidstrasse — südöstlich Campus Birch, nicht am Campus, nicht am Forrenberg-Hub, nicht in Ohringen. Collision wie Schul-Props; **keine** Sprite-Rotation. Kindergarten Bachtobel bleibt stehen. Schneckenwiese und Ohringen-Kiga bleiben unplatziert.

## Scope

### In

- Nur **Kindergarten Weid**: ein Prop, Node-Name `kiga_weid`
- GPS + Getter in `SeuzachGeo`: `KIGA_WEID_LAT/LON` + `kiga_weid_world()` = Nominatim-Zentroid des OSM-**Gebäudes** (way `131647378`; amenity und building sind derselbe Way)
- Platzierung in `world_sandbox` via `_add_prop` in bestehendem `_place_kindergartens()` (`landmark_kiga_weid.png`, `SCHOOL_SCALE` 0.22 wie Schulen) **zusätzlich** zu Bachtobel
- Metas: `landmark_id=kiga_weid`, `kindergarten_id=kiga_weid`, `district=weid`  
  **Kein** `school_cluster` (sonst zählen Birch/Rietacker/Ohringen-Asserts den Kiga mit)
- Parent: direkt unter `%Props` (wie Bachtobel), **nicht** unter `DistrictOhringen`
- Collision über bestehendes `_attach_building_collision` (kein Sonderpfad)
- Tests: Weid **ist** platziert; Bachtobel **bleibt** platziert; Schneckenwiese und Ohringen-Kiga **bleiben abwesend**; Schul-Campus-Asserts (S01–S03) unangetastet
- Art: bestehende PNG nur behalten, wenn Silhouette zu OSM passt — hier **Mismatch** (Giebel vs. Flachdach) → Rewrite nur dieser Datei, siehe Art-Bedarf

### Nicht

- Kindergarten Schneckenwiese (`S06`), Ohringen (`S07`)
- Kindergarten Bachtobel (`S04` erledigt): Getter, Prop, Tests **nicht entfernen / nicht umbauen** ausser die Abwesenheits-Schleife (Weid darf nicht mehr als „absent“ gelten)
- Schul-Campi Birch / Rietacker / Ohringen (`S01`–`S03` erledigt — Getter, Cluster-Counts, Off-Road der Schulen nicht umbauen)
- Bahnhof (`S08`), Gleise (`S09`), Badi (`S10`), Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing
- Hort-Provisorium / Tagesstrukturen Weid (Gemeinde 2023, Kredit Hort-Räume) als zweites Gebäude
- RoadKit / `seuzach_roads.json` ändern (Weidstrasse und In der Weid existieren; Off-Road-Slack ist grün)
- `SCHOOL_SCALE` global ändern
- `Sprite2D.rotation` am Kiga (Iso-¾ wie authored; Lage = Maps-Ausrichtung)
- `DistrictWeid`-Node (Meta reicht); **kein** `district=forrenberg` und **kein** `district=ohringen` (Nominatim-Hierarchie-Falle)

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

| | |
|--|--|
| OSM amenity+Gebäude | way `131647378` `amenity=kindergarten`, `building=kindergarten`, `building:roof=flat`, `education=kindergarten`, `name=Kindergarten Weid`, `addr:housenumber=16` |
| Gemeinde | Primarschule Seuzach, **Weidstrasse 16, 8472 Seuzach** (zwei Abteilungen) |
| GPS Platzierung | **47.5330589, 8.7379167** (Nominatim-Zentroid way `131647378`) |
| Welt | `kiga_weid_world()` ≈ `(16723.8, 929.0)` · Feld ≈ `(167, 9)` |
| Lage | ~887 m Ost / ~49 m Süd der Kirche; O-Dorf, **südöstlich** Campus Birch |

Kein separater amenity-Node: Way ist Gebäude **und** POI. Ein Getter, ein Prop: Gebäude-Zentroid wie Schulhaus-Props und S04.

Nominatim `hamlet=Forrenberg` / `village=Oberohringen` in der Adresszeile ist OSM-Hierarchie, **nicht** der A1-Hub (`forrenberg_world()` liegt weit südlich, `y ≈ 15124`) und **nicht** Campus Ohringen (`ohringen_world()` liegt SW, `x ≈ −19840`). Guard: Kiga `x > 15000` und `-2000 < y < 4000`.

Relativlage (Kartenbild, N = kleineres Y):

```
        Campus Birch N  (~254 m / 4795 wu nördlich)
        Bahnhof NE
                         |
        Weidstrasse (RoadKit, NW des Props)
                         |
              Kiga Weid 16
                         |
        In der Weid weiter SO
        Kirche W                A1-Forrenberg weit S (nicht hier)
        Kiga Bachtobel weit N (gleiche Ostlage, ~508 m / 9588 wu nördlich)
```

OSM-Grundriss way `131647378` (Stand 2026-08-11): bbox ~24 m N–S × ~25 m O–W, gestuft/unregelmässig (Pavillon); längste Kante ~11 m, grob **SW–NE** (~215° / 35°). Spiel-Sprite bei `SCHOOL_SCALE=0.22` ist visuell ~11 m (951×964 px) — bestehende Schul-Konvention, hier nicht skalieren.

RoadKit: Gebäude-Zentroid vs. `seuzach_roads.json` Weidstrasse (`class=local`, `half_w=36`): Füße ≈ 544 wu, AABB (Sprite reicht nach N) bleibt ≫ Need 100 / 50. Nächste anderen: Blumenweg ~863 wu, Birkenweg ~1046 wu, In der Weid ~2077 wu. Off-Road-Asserts sollen ohne JSON-Änderung grün bleiben.

Ist-Zustand (warum dieser Slice): `_place_kindergartens()` setzt nur Bachtobel. `KIGA_IDS` listet Weid; `_assert_kiga_bachtobel` fordert Weid **abwesend**. S05 platziert **nur** Weid dazu und lockt Schneckenwiese + Ohringen-Kiga weiter auf Abwesenheit. Bachtobel-Assert bleibt, Abwesenheits-Schleife muss Weid ausnehmen.

## Systeme

- `scripts/seuzach_geo.gd` — GPS-Konstanten + `kiga_weid_world()` (Bachtobel- und Schul-Getter unangetastet)
- `scripts/world_sandbox.gd` — `_place_kindergartens()` um Weid erweitern; Bachtobel-Aufruf bleibt; `_add_prop` + `_attach_building_collision` unverändert
- `tests/m3_world_landmarks_test.gd` — Weid-Layout; Bachtobel weiter vorhanden; Schneckenwiese/Ohringen-Kiga abwesend; Schul-Asserts bleiben
- `tests/m3_building_occlusion_test.gd` — Sample bleibt Birch; neuer Prop O darf Occlusion nicht kippen
- `tests/m2_world_test.gd` — nicht regressieren
- Art `assets/art/landmark_kiga_weid.png` (bestehend, Silhouette-Rewrite siehe Art-Bedarf)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Weid-Kiga nicht platziert, siehe Scope).

## Technische Schritte

1. **`SeuzachGeo`:** Schul-/Bachtobel-/Bahnhof-/Badi-/Forrenberg-Konstanten nicht ändern. Neu:
   - `KIGA_WEID_LAT := 47.5330589`
   - `KIGA_WEID_LON := 8.7379167`
   - `kiga_weid_world() -> gps_to_world(...)`  
   Kommentar: OSM way `131647378` Weidstrasse 16 (Gebäude=POI), nicht Forrenberg-Hub, nicht Ohringen.
2. **`world_sandbox.gd`:** In `_place_kindergartens()` **Bachtobel behalten** und **Weid hinzufügen**:
   ```
   _add_prop(
     "landmark_kiga_weid.png",
     SeuzachGeo.kiga_weid_world(),
     SCHOOL_SCALE,
     {"landmark_id": "kiga_weid", "kindergarten_id": "kiga_weid", "district": "weid"},
     "kiga_weid"
   )
   ```
   Keine `rotation`. Kein Schneckenwiese/Ohringen-Kiga. Kein `school_cluster`. Kommentar S04-only entfernen/anpassen.
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd`:
   - Neue Funktion `_assert_kiga_weid(sprites)` aus `_run` aufrufen (nach `_assert_kiga_bachtobel`).
   - Weid **vorhanden:** Node `kiga_weid`; Metas `landmark_id` / `kindergarten_id` / `district` wie Scope; `_has_kindergarten(..., "kiga_weid")` true.
   - GPS-Konstanten matchen die Tabelle; Getter `distance_to(Vector2(16723.8, 929.0)) < 1.0`.
   - Position ≤ **80 wu** zum Getter.
   - Quadrant: `x > 15000` und `-2000 < y < 4000` (O-Dorf, nicht NE-Bachtobel, nicht SW-Ohringen, nicht Forrenberg-Süd).
   - Relativ: `kiga.position.y > birch_world().y + 3000` (südlich Birch); `kiga.position.x > birch_world().x` (östlich Birch); `kiga.position.y > kiga_bachtobel_world().y + 4000` (südlich Bachtobel); Distanz zu `ohringen_world()` und `forrenberg_world()` jeweils **> 8000 wu**.
   - Parent-Kette enthält **nicht** `DistrictOhringen`.
   - `rotation == 0`; `has_building_collision`.
   - **Bachtobel bleibt:** `_assert_kiga_bachtobel` weiter aufrufen; in dessen Abwesenheits-Schleife `kiga_weid` **nicht** mehr als absent fordern (skip `kiga_bachtobel` **und** `kiga_weid`). Ohringen-Guard in `_assert_ohringen_campus` darf stehen bleiben.
   - **Schneckenwiese + Ohringen-Kiga abwesend:** `not _has_kindergarten` und `_find_named(..., id) == null` für `kiga_schneckenwiese` und `kiga_ohringen`.
   - Off-Road: `_assert_schools_off_roads` deckt bereits `kindergarten_id` ab — Weid fällt automatisch unter Weidstrasse/In der Weid. **Nicht** `school_cluster` am Kiga setzen. Road-JSON nicht anfassen.
   - Optional in `_assert_kiga_weid`: `_assert_road_near(ground, "Weidstrasse", SeuzachGeo.kiga_weid_world(), 900.0)` — Marker existiert schon, nicht die globale Required-Road-Liste anfassen. In der Weid nicht als Pflicht-Nähe (d ≈ 2077 wu).
   - Birch-/Rietacker-/Ohringen-OSM-Blöcke, Cluster-Counts (=3), Bachtobel-GPS/NE-Guards **nicht** umbauen.
4. **Occlusion / m2:** keine Sample-Umbiegung auf den Kiga; `m2_world_test` unverändert erwarten.
5. **Art-Gate:** Silhouette kippt (OSM Flachdach vs. Ist-Giebel) — `comic-rettung-art` **dieser** PNG, siehe Art-Bedarf. Pipeline: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Weid (Bachtobel und Schul-Campi visuell nicht umbauen).

## Testplan

### Automatisiert

- [x] `kiga_weid` in `world_sandbox` unter `%Props` vorhanden, Metas wie Scope
- [x] Position ≈ `kiga_weid_world()`, Toleranz 80 wu; Getter ≈ `(16723.8, 929.0)`
- [x] O-Guard `x > 15000`, `-2000 < y < 4000`; südlich und östlich von Birch; südlich von Bachtobel; weit von Ohringen- und Forrenberg-Ankern
- [x] `kiga_bachtobel` **weiter platziert** (S04-Asserts bleiben grün)
- [x] `kiga_schneckenwiese`, `kiga_ohringen` **nicht** platziert
- [x] Kein `school_cluster` am Kiga; Birch/Rietacker/Ohringen bleiben je genau 3
- [x] Off-Road (Füße + AABB) inkl. Weidstrasse ohne Road-JSON-Änderung
- [x] BuildingCollision; `rotation` 0; nicht unter `DistrictOhringen`
- [x] S01–S04 Campus-/Bachtobel-Asserts und `m2_world_test` grün
- [x] Art-Datei existiert (`REQUIRED_ART` enthält `landmark_kiga_weid.png` bereits)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Ein Kindergarten-Gebäude an Weidstrasse 16 (O, südöstlich Birch), Füße auf Gras nicht auf Asphalt
- [x] Collision blockiert wie Schulhäuser; Spieler kann an der Fassade vorbei
- [x] Y-Sort: Spieler südlich der Fassade davor, nördlich dahinter
- [x] Bachtobel-Kiga weiter im NE sichtbar; keine Schneckenwiese-/Ohringen-Kiga-Props; Schul-Cluster unverändert
- [x] Kein Sprite-Twist; Iso-¾ wie authored
- [x] Keine weissen/schwarzen AI-Platten (`verify_art_alpha`)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. Weid-GPS/Off-Road (Weidstrasse feet d=544 / AABB 340); smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s05-kiga-weid.png` (player at `kiga_weid_world()`, zoom 0.55): ein Flachdach-Pavillon, Rutsche+Sandkasten lesbar, Füße auf Gras; Weidstrasse nur am Rand, nicht unter dem Prop. Bachtobel bleibt platziert; Schneckenwiese/Ohringen-Kiga abwesend. Rewrite-PNG bestätigt (kein Giebel).

## Art-Bedarf

- [ ] Keine neuen Assets *(nicht der Default — Silhouette kippte)*
- [x] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur dieser Kiga** — Rewrite geliefert, Playtest bestätigt Flachdach

**Warum Rewrite (wie S01 Birch-a / S03 Ohringen-b, anders als S04 Bachtobel):**

| Quelle | Silhouette |
|--------|------------|
| OSM way `131647378` | `building=kindergarten`, **`building:roof=flat`**, kein `building:levels`, Pavillon-Grundriss ~25×24 m gestuft |
| Gemeinde | Weidstrasse 16; Hort-Anbau 2023 ist ein **anderes** Volumen — nicht in diesem Prop |
| Ist-PNG | 951×964 RGBA, 2-geschossiges **Giebel**-Häuschen, Gaube, Minzputz, Schaukel + Kletterwürfel — lesbarer Kiga, aber **Giebel ≠ Flachdach** |

Giebel/Flachdach-Konflikt. Farbe/Spielgeräte (grün, Schaukel) sind Style-C-Kiga-Sprache und dürfen bleiben — Dach und Geschosszahl nicht. Bachtobel-PNG nicht anfassen (lachs, Rutsche, Giebel — passt dort zu OSM `roof:shape=gabled`).

**Auftrag `comic-rettung-art` (Phase 2b):**

- Rewrite **nur** `assets/art/landmark_kiga_weid.png`, gleicher Pfad
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View Weidstrasse 16 Seuzach / Satellit Kindergarten Weid
- Stil C: Kontur, Cel; kleiner CH-Kiga, **Flachdach-Pavillon** (1970er-Gemeindebau), Spielbereich (Schaukel/Sand) erlaubt; kein 2-geschossiges Giebelhaus, keine Gaube
- Iso-¾ Default-Facing; **kein** `Sprite2D.rotation`; kein extra Dir-Set
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Bachtobel-/Schneckenwiese-/Ohringen-Kiga-Art, keine Schul- oder Housing-Art

Falls Playtest/Street View **Giebel** bestätigt (OSM-Tag falsch): PNG behalten und hier dokumentieren — Default ist Rewrite.

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Weid-Kiga neu; Bachtobel bleibt; keine Schneckenwiese-/Ohringen-Kigas; keine Campus-/Bahnhof-/Gleis-/Badi-/Bach-/Wald-/Housing-Änderungen
- [x] Prop auf GPS der Tabelle (±80 wu); O-Dorf, nicht Forrenberg-Hub, nicht Ohringen
- [x] Off RoadKit-Asphalt; Collision wie Schul-Props; keine Sprite-Rotation
- [x] Art: Flachdach-Silhouette Style C **oder** dokumentierter Playtest-Entscheid, dass die Giebel-PNG reicht
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
