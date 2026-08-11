# Slice: S07 — Kindergarten Ohringen

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner / Phase-2 `feature-implementer`  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S07-kiga-ohringen.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Der **Kindergarten Ohringen** steht in den Ohringen-Zellen (Gemeinde Seuzach), maps-getreu zu Maps/OSM — eigenes Gebäude, nicht Teil des Schul-Megablocks.

## In diesem Schritt

- `landmark_kiga_ohringen.png` maps-getreu in District Ohringen platzieren; GPS-Helfer in `seuzach_geo` ergänzen
- Facing/Grundriss an Google Maps / OSM; neue Art nur wenn Silhouette/Ausrichtung falsch ist

## Nicht (andere Feature-Schritte)

- Campus Ohringen (`S03`) und die drei Dorf-Kigas
- Bahnhof, Gleise, Badi, Bäche, Wälder, Wohnhäuser

## Ziel

Spieler sieht im **SW** von Seuzach (Oberohringen, **Schulstrasse 5**, 8472 Oberohringen; Primarschule Seuzach) **ein** Kindergarten-Prop in den eigenen Ohringen-Rasterzellen — südöstlich des Schul-Campus, unter `DistrictOhringen`, nicht als viertes Campus-Gebäude. Collision wie Schul-Props; **keine** Sprite-Rotation. Kindergarten Bachtobel, Weid und Schneckenwiese bleiben stehen. Schul-Campi (S01–S03) bleiben unverändert.

## Scope

### In

- Nur **Kindergarten Ohringen**: ein Prop, Node-Name `kiga_ohringen`
- GPS + Getter in `SeuzachGeo`: `KIGA_OHRINGEN_LAT/LON` + `kiga_ohringen_world()` = Nominatim-Zentroid des OSM-**Gebäudes** (way `52373683`; amenity und building sind derselbe Way)
- Platzierung in `world_sandbox` via `_add_prop` in bestehendem `_place_kindergartens()` (`landmark_kiga_ohringen.png`, `SCHOOL_SCALE` 0.22 wie Schulen) **zusätzlich** zu Bachtobel, Weid und Schneckenwiese
- Parent: Kind von bestehendem `DistrictOhringen` (wie die drei S03-Schul-Props; District `position = Vector2.ZERO`, deshalb Weltkoordinaten am Sprite). **Nicht** direkt unter `%Props`. Temporär `_prop_parent` auf den District setzen, danach wieder `_props` — **nicht** in `_place_school_clusters()` einhängen
- Metas: `landmark_id=kiga_ohringen`, `kindergarten_id=kiga_ohringen`, `district=ohringen`  
  **Kein** `school_cluster` (sonst zählt `_assert_ohringen_campus` den Kiga als viertes Campus-Gebäude)
- Collision über bestehendes `_attach_building_collision` (kein Sonderpfad)
- Tests: Ohringen-Kiga **ist** platziert (Abwesenheits-Asserts aus S03–S06 **umdrehen**); Bachtobel, Weid **und** Schneckenwiese **bleiben** platziert; Schul-Campus-Asserts (S01–S03) unangetastet ausser die `kiga_ohringen not placed (S07)`-Zeilen
- Art: bestehende PNG nur behalten, wenn Silhouette zu OSM/Satellit passt — hier **Mismatch** (Giebel-Häuschen vs. Modul-Flachdach + PV + Gründach) → Rewrite nur dieser Datei, siehe Art-Bedarf

### Nicht

- Campus Ohringen (`S03` erledigt): Getter `ohringen_*_world()`, Cluster-Count **= 3**, Off-Road der Schulen, `OHRINGEN_LAT/LON` **nicht** umbauen; Kiga nicht als `schulhaus_ohringen_b` missbrauchen
- Campus Birch / Rietacker (`S01`–`S02`)
- Kindergarten Bachtobel (`S04`), Weid (`S05`), Schneckenwiese (`S06`): Getter, Prop, Tests **nicht entfernen / nicht umbauen** ausser die Abwesenheits-Schleifen (Ohringen-Kiga darf nicht mehr als „absent“ gelten). Dorf-Kigas bleiben **ohne** `DistrictOhringen`-Parent
- Bahnhof (`S08`), Gleise (`S09`), Badi (`S10`), Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing
- Hartplatz OSM way `136492025`; Vordächer/Sheds `727214863` / `727214864` / `727214865` (S03-Nicht-Scope bleibt)
- Separates Spielplatz-Prop oder zweites Volumen für den SW-Schuppen neben dem Kiga (ein Prop)
- Tagesstrukturen-Neubau Schaffhauserstrasse 72 (Gemeinde-Plan, anderes Grundstück)
- RoadKit / `seuzach_roads.json` ändern (Schulstrasse / Rundstrasse / Friedenstrasse / Schaffhauserstrasse existieren; Off-Road-Slack ist grün)
- `SCHOOL_SCALE` global ändern
- `Sprite2D.rotation` am Kiga (Iso-¾ wie authored; Lage = Maps-Ausrichtung)
- Neuen `DistrictOhringen`-Node erzeugen (existiert schon aus S03)

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

| | |
|--|--|
| OSM amenity+Gebäude | way `52373683` `amenity=kindergarten`, `building=kindergarten`, `name=Kindergarten Ohringen`, `addr:housenumber=5`, `addr:street=Schulstrasse`, `addr:city=Oberohringen`, `check_date=2025-01-30` — **kein** `roof:shape` / `building:levels` |
| Gemeinde | Primarschule Seuzach, **Schulstrasse 5, 8472 Oberohringen** (Kindergarten Ohringen; nicht Schulhaus 9 / Turnhalle 7) |
| GPS Platzierung | **47.5278851, 8.7126832** (Nominatim-Zentroid way `52373683`) |
| Welt | `kiga_ohringen_world()` ≈ `(−19059.5, 11795.9)` · Feld ≈ `(−191, 118)` |
| Lage | ~625 m Süd / ~1010 m West der Kirche; **südöstlich** Campus-Anker `ohringen_world()` |

Kein separater amenity-Node: Way `52373683` ist Gebäude **und** POI. Ein Getter, ein Prop: Gebäude-Zentroid wie Schulhaus-Props und S04–S06.

Offset von `ohringen_world()` `(−19840.5, 11431.9)`: `Vector2(780.9, 364.0)` ≈ **41,4 m Ost, 19,3 m Süd**. Paar-Abstände (Zentroide): Kiga↔b ≈ 518 wu (27 m), Kiga↔Turnhalle ≈ 621 wu (33 m), Kiga↔a ≈ 1081 wu (57 m), Kiga↔Anker ≈ 862 wu (46 m). Alle ≫ `MIN_CLUSTER_SEP` 160 — eigener Baukörper, kein Megablock.

Nominatim `hamlet=Rainbuck` / `village=Oberohringen` ist OSM-Hierarchie und **diesmal** der richtige District (`district=ohringen`, Parent `DistrictOhringen`). **Nicht** der A1-Hub (`forrenberg_world()` liegt weit östlich, `d ≈ 32264` wu). Guard: Kiga `x < -15000` und `y > 8000` (dieselben SW-Zellen wie S03), plus Nähe zum Campus-Anker `< 1200` wu.

Relativlage (Kartenbild, N = kleineres Y):

```
        a Schulhaus 9  (N)
              |
              |                 b Schultrakt 1985  (O)
              +-- Anker ohringen_world()
    Turnhalle 7 S
                         Kiga 5 SO  ← dieser Slice
        Schaffhauserstrasse SW     Rundstrasse O     Schulstrasse W/NW
        Friedenstrasse weiter S
        Kirche NE               A1-Forrenberg weit O (nicht hier)
        Dorf-Kigas weit O/NE (Bachtobel/Weid/Schneckenwiese)
```

OSM-Grundriss way `52373683` (Stand 2026-08-11): bbox ~27 m N–S × ~20 m O–W, gestuft an der Ostseite; längste Kante ~12 m, grob **WNW–ESE** (Bearing ~119°). Spiel-Sprite bei `SCHOOL_SCALE=0.22` ist visuell ~12 m (1024×956 px) — bestehende Schul-Konvention, hier nicht skalieren.

SWISSIMAGE (LV95 ~2695943/1264906, 2026-08-11): **kein Giebel**. Modularer Flachdach-Cluster: NW-Flügel mit **PV-Raster** (SKGS 2016, 100 m² / 17 kWp), SO-Flügel **Gründach** mit Oberlichtern, rosa/orange Röhrenrutsche von der Südterrasse, roter Fallschutz südlich. Siehe Art-Bedarf.

RoadKit: Gebäude-Zentroid vs. `seuzach_roads.json` Schulstrasse (`class=local`, `half_w=36`): Füße ≈ 359 wu vs. Need 100 / 50. Nächste anderen: Rundstrasse ~582 wu, Friedenstrasse ~768 wu, Schaffhauserstrasse ~794 wu (main). Off-Road-Asserts sollen ohne JSON-Änderung grün bleiben. `_assert_road_near(..., "Schulstrasse", ..., 900)` passt.

Ist-Zustand (warum dieser Slice): `_place_kindergartens()` setzt Bachtobel + Weid + Schneckenwiese. `KIGA_IDS` listet Ohringen; `_assert_ohringen_campus`, `_assert_kiga_weid` und `_assert_kiga_schneckenwiese` (plus Bachtobel-Skip-Schleife) fordern `kiga_ohringen` **abwesend**. S07 platziert **nur** den Ohringen-Kiga dazu und **kehrt** diese Absents um. Campus-Cluster bleibt genau 3.

## Systeme

- `scripts/seuzach_geo.gd` — GPS-Konstanten + `kiga_ohringen_world()` (Bachtobel-/Weid-/Schneckenwiese- und Schul-Getter unangetastet)
- `scripts/world_sandbox.gd` — `_place_kindergartens()` um Ohringen-Kiga erweitern unter `DistrictOhringen`; Dorf-Kiga-Aufrufe bleiben unter `%Props`; `_place_school_clusters()` und `_add_prop` + `_attach_building_collision` unverändert
- `tests/m3_world_landmarks_test.gd` — Ohringen-Kiga-Layout; Bachtobel, Weid und Schneckenwiese weiter vorhanden; Schul-Asserts bleiben (Cluster = 3); Absents für `kiga_ohringen` entfernen
- `tests/m3_building_occlusion_test.gd` — Sample bleibt Birch; Cluster-Spacing zählt nur `school_cluster` (Kiga ohne dieses Meta); neuer Prop SW darf Occlusion nicht kippen
- `tests/m2_world_test.gd` — nicht regressieren
- Art `assets/art/landmark_kiga_ohringen.png` (bestehend, Silhouette-Rewrite siehe Art-Bedarf)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Ohringen-Kiga nicht platziert, Tests fordern Abwesenheit, siehe Scope).

## Technische Schritte

1. **`SeuzachGeo`:** Schul-/Bachtobel-/Weid-/Schneckenwiese-/Bahnhof-/Badi-/Forrenberg-Konstanten nicht ändern. `OHRINGEN_LAT/LON` unverändert. Neu:
   - `KIGA_OHRINGEN_LAT := 47.5278851`
   - `KIGA_OHRINGEN_LON := 8.7126832`
   - `kiga_ohringen_world() -> gps_to_world(...)`  
   Kommentar: OSM way `52373683` Schulstrasse 5 Oberohringen (Gebäude=POI), nicht Campus-Ways `52373582` / `52373583` / `917552680`, nicht Forrenberg-Hub.
2. **`world_sandbox.gd`:** In `_place_kindergartens()` **Bachtobel, Weid und Schneckenwiese behalten** (Parent weiter `_props`) und **Ohringen-Kiga hinzufügen** als Kind von `DistrictOhringen` (Node existiert nach `_place_school_clusters()`):
   ```
   var district := _props.get_node_or_null("DistrictOhringen")
   _prop_parent = district if district else _props
   _add_prop(
     "landmark_kiga_ohringen.png",
     SeuzachGeo.kiga_ohringen_world(),
     SCHOOL_SCALE,
     {"landmark_id": "kiga_ohringen", "kindergarten_id": "kiga_ohringen", "district": "ohringen"},
     "kiga_ohringen"
   )
   _prop_parent = _props
   ```
   Keine `rotation`. Kein `school_cluster`. Kommentar „Ohringen-Kiga comes later“ entfernen. `_place_school_clusters()` nicht um den Kiga erweitern.
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd`:
   - Neue Funktion `_assert_kiga_ohringen(sprites)` aus `_run` aufrufen (nach `_assert_kiga_schneckenwiese`).
   - Ohringen-Kiga **vorhanden:** Node `kiga_ohringen`; Metas `landmark_id` / `kindergarten_id` / `district` wie Scope; `_has_kindergarten(..., "kiga_ohringen")` true.
   - GPS-Konstanten matchen die Tabelle; Getter `distance_to(Vector2(-19059.5, 11795.9)) < 1.0`.
   - Position ≤ **80 wu** zum Getter.
   - Quadrant: `x < -15000` und `y > 8000` (SW-Ohringen-Zellen, nicht Dorfkern, nicht Forrenberg-Südost).
   - Nähe Campus: Distanz zu `ohringen_world()` **< 1200 wu** (Ist ≈ 862).
   - Relativ: `kiga.position.x > ohringen_schulhaus_b_world().x` (östlich von b); `kiga.position.x > ohringen_turnhalle_world().x` (östlich der Halle); `kiga.position.y > ohringen_schulhaus_a_world().y` und `> ohringen_schulhaus_b_world().y` (südlich von a und b). Distanz zu `birch_world()`, `forrenberg_world()`, `kiga_bachtobel_world()`, `kiga_weid_world()`, `kiga_schneckenwiese_world()` jeweils **> 8000 wu**.
   - Parent-Kette enthält **`DistrictOhringen`** (Gegenteil der Dorf-Kigas).
   - `rotation == 0`; `has_building_collision`; **kein** `school_cluster`.
   - **Campus bleibt 3:** `_assert_ohringen_campus` weiter aufrufen; Zeilen `kiga_ohringen not placed (S07)` / `no kiga_ohringen node` **entfernen** (nicht durch Cluster-Count-4 ersetzen). Birch-/Rietacker-OSM-Blöcke, Relativlage a/b/Halle, `OHRINGEN_*`-Konstanten **nicht** umbauen.
   - **Dorf-Kigas bleiben:** `_assert_kiga_bachtobel` / `_assert_kiga_weid` / `_assert_kiga_schneckenwiese` weiter aufrufen. Abwesenheits-Schleifen umdrehen:
     - Bachtobel-Skip: alle vier `KIGA_IDS` skippen (oder die „later slice“-Schleife streichen — alle Kigas sind platziert).
     - Weid: `for absent_id in ["kiga_ohringen"]` **löschen**.
     - Schneckenwiese: `not _has_kindergarten(..., "kiga_ohringen")` und `no kiga_ohringen node` **löschen**.
     - Dorf-Kigas behalten `parent chain excludes DistrictOhringen`.
   - Off-Road: `_assert_schools_off_roads` deckt bereits `kindergarten_id` ab — Ohringen-Kiga fällt automatisch unter Schulstrasse/Rundstrasse. **Nicht** `school_cluster` am Kiga setzen. Road-JSON nicht anfassen.
   - Optional in `_assert_kiga_ohringen`: `_assert_road_near(ground, "Schulstrasse", SeuzachGeo.kiga_ohringen_world(), 900.0)` — Marker existiert schon, nicht die globale Required-Road-Liste anfassen.
4. **Occlusion / m2:** keine Sample-Umbiegung auf den Kiga; `m3_building_occlusion_test` Cluster-Spacing bleibt `school_cluster=ohringen` (3 Props); `m2_world_test` unverändert erwarten.
5. **Art-Gate:** Silhouette kippt (Satellit Modul-Flachdach+PV+Gründach vs. Ist-Giebelhäuschen) — `comic-rettung-art` **dieser** PNG, siehe Art-Bedarf. Pipeline: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Ohringen-Kiga (Dorf-Kigas und Schul-Campi visuell nicht umbauen).

## Testplan

### Automatisiert

- [x] `kiga_ohringen` in `world_sandbox` unter `DistrictOhringen` vorhanden, Metas wie Scope
- [x] Position ≈ `kiga_ohringen_world()`, Toleranz 80 wu; Getter ≈ `(−19059.5, 11795.9)`
- [x] Guard `x < -15000`, `y > 8000`; < 1200 wu vom Campus-Anker; östlich von b und Turnhalle; südlich von a und b; weit von Birch, Forrenberg und den drei Dorf-Kigas
- [x] `kiga_bachtobel`, `kiga_weid` **und** `kiga_schneckenwiese` **weiter platziert** (S04–S06-Asserts bleiben grün)
- [x] Kein `school_cluster` am Kiga; Birch/Rietacker/Ohringen bleiben je genau 3
- [x] Off-Road (Füße + AABB) inkl. Schulstrasse ohne Road-JSON-Änderung
- [x] BuildingCollision; `rotation` 0; Parent **ist** `DistrictOhringen`
- [x] S01–S06 Campus-/Kiga-Asserts und `m2_world_test` grün
- [x] Art-Datei existiert (`REQUIRED_ART` enthält `landmark_kiga_ohringen.png` bereits)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Ein Kindergarten-Gebäude an Schulstrasse 5 (SW, südöstlich des Schul-Campus), Füße auf Gras nicht auf Asphalt; Hof-Lücke zu a/b/Turnhalle bleibt
- [x] Collision blockiert wie Schulhäuser; Spieler kann an der Fassade vorbei und zwischen Kiga und Campus durch
- [x] Y-Sort: Spieler südlich der Fassade davor, nördlich dahinter
- [x] Bachtobel-, Weid- und Schneckenwiese-Kiga weiter im Dorf sichtbar; Schul-Cluster unverändert (drei Gebäude, kein Megablock mit dem Kiga)
- [x] Kein Sprite-Twist; Iso-¾ wie authored
- [x] Keine weissen/schwarzen AI-Platten (`verify_art_alpha`)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. Ohringen-Kiga-GPS/Off-Road (Schulstrasse feet d=359 / AABB 185; Rundstrasse 582; Friedenstrasse 768; Schaffhauserstrasse 794); smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s07-kiga-ohringen.png` (player at `kiga_ohringen_world()`, zoom 0.42): modularer Flachdach-Cluster (PV-NW + Gründach-SO), Röhrenrutsche+Fallschutz südlich, Füße auf Gras; Schulstrasse/Rundstrasse nur am Rand. Campus-Cluster bleibt 3 (`school_cluster ohringen` got 3); b und Turnhalle im Frame NW, a knapp nördlich ausserhalb. Parent `DistrictOhringen`; Bachtobel/Weid/Schneckenwiese weiter platziert. Rewrite-PNG bestätigt (kein Giebel).

## Art-Bedarf

- [ ] Keine neuen Assets *(nicht der Default — Silhouette kippte)*
- [x] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur dieser Kiga** — Rewrite geliefert, Playtest bestätigt Flachdach-Modul + PV + Gründach

**Warum Rewrite (wie S05 Weid / S06 Schneckenwiese, anders als S04 Bachtobel):**

| Quelle | Silhouette |
|--------|------------|
| OSM way `52373683` | `building=kindergarten`, **kein** `roof:shape` / `building:levels`; Grundriss ~27×20 m gestuft |
| SWISSIMAGE (BBOX Gebäude, 2026-08-11) | **modulares Flachdach**: NW-Flügel dunkles **PV-Raster**, SO-Flügel **Gründach** mit Oberlichtern; rosa/orange Röhrenrutsche von der Südterrasse; roter Fallschutz südlich |
| SKGS / Gemeinde | PV Kindergarten Oberohringen Juli 2016, 100 m² / 17 kWp — bestätigt grosse, flache Dachebene |
| Ist-PNG | 1024×956 RGBA, 2-geschossiges **Giebel**-Häuschen (lavendel, Kamin, Wippe, Sandkasten) — lesbarer Kiga, aber **Giebel ≠ Flachdach-Modul + PV** |

Giebel/Flachdach-Konflikt. Spielgeräte (Rutsche, Hof) sind Style-C-Kiga-Sprache und dürfen bleiben — Dach und Baukörper nicht. Bachtobel-PNG nicht anfassen (lachs, Einzelgiebel). Weid-PNG nicht anfassen (mint, ein Flachdach-Pavillon). Schneckenwiese-PNG nicht anfassen (zwei Walm-Flügel + Flachdach). Campus-Ohringen-Art nicht anfassen (a Giebel-Schulhaus, b/Halle Flachdach).

**Auftrag `comic-rettung-art` (Phase 2b):**

- Rewrite **nur** `assets/art/landmark_kiga_ohringen.png`, gleicher Pfad
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View / SWISSIMAGE Schulstrasse 5 Oberohringen / Satellit Kindergarten Ohringen (nicht Schulhaus 9 / Turnhalle 7 als dasselbe Volumen)
- Stil C: Kontur, Cel; kleiner CH-Kiga als **modularer Flachdach-Cluster** (PV höchstens angedeutet, kein Technik-Lego; Gründach als bräunlich-grüne Fläche ok); Spielbereich südlich erlaubt (Röhrenrutsche, Fallschutz) — kein 2-geschossiges Giebelhaus, kein Kamin
- Iso-¾ Default-Facing; **kein** `Sprite2D.rotation`; kein extra Dir-Set
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Bachtobel-/Weid-/Schneckenwiese-Kiga-Art, keine Schul- oder Housing-Art, kein zweites Shed-Prop

Falls Playtest/Street View **Giebel** bestätigt (Satellit falsch gelesen): PNG behalten und hier dokumentieren — Default ist Rewrite.

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Ohringen-Kiga neu; Bachtobel, Weid und Schneckenwiese bleiben; Campus Ohringen bleibt drei Gebäude; keine Bahnhof-/Gleis-/Badi-/Bach-/Wald-/Housing-Änderungen
- [x] Prop auf GPS der Tabelle (±80 wu); SW-Ohringen-Zellen unter `DistrictOhringen`, nicht Forrenberg-Hub, nicht Dorfkern
- [x] Off RoadKit-Asphalt; Collision wie Schul-Props; keine Sprite-Rotation; kein `school_cluster`
- [x] Art: Flachdach-Modul-Silhouette Style C **oder** dokumentierter Playtest-Entscheid, dass die Giebel-PNG reicht
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
