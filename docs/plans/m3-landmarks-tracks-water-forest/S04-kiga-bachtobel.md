# Slice: S04 — Kindergarten Bachtobel

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner / Phase-2 `feature-implementer`  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S04-kiga-bachtobel.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Der **Kindergarten Bachtobel** ist in der Welt sichtbar: Lage und Ausrichtung nach Maps/OSM (Bachtobelstrasse), nicht ein generischer Schul-Offset.

## In diesem Schritt

- `landmark_kiga_bachtobel.png` maps-getreu platzieren; GPS-Helfer in `seuzach_geo` ergänzen
- Facing/Grundriss an Google Maps / OSM; neue Art nur wenn Silhouette/Ausrichtung falsch ist

## Nicht (andere Feature-Schritte)

- Die anderen drei Kindergärten
- Schul-Campi, Bahnhof, Gleise, Badi, Bäche, Wälder, Wohnhäuser

## Ziel

Spieler sieht im **Nordosten** von Seuzach (Bachtobelstrasse 17, 8472 Seuzach; Primarschule Seuzach) **ein** Kindergarten-Prop neben der RoadKit-Bachtobelstrasse — nicht am Campus Birch, nicht am Forrenberg-Hub. Collision wie Schul-Props; **keine** Sprite-Rotation. Die anderen drei Kigas bleiben unplatziert.

## Scope

### In

- Nur **Kindergarten Bachtobel**: ein Prop, Node-Name `kiga_bachtobel`
- GPS + Getter in `SeuzachGeo`: `KIGA_BACHTOBEL_LAT/LON` + `kiga_bachtobel_world()` = Nominatim-Zentroid des OSM-**Gebäudes** (way `142728231`)
- Platzierung in `world_sandbox` via `_add_prop` (`landmark_kiga_bachtobel.png`, `SCHOOL_SCALE` 0.22 wie Schulen)
- Metas: `landmark_id=kiga_bachtobel`, `kindergarten_id=kiga_bachtobel`, `district=bachtobel`  
  **Kein** `school_cluster` (sonst zählen Birch/Rietacker/Ohringen-Asserts und die Schul-Off-Road-Schleife den Kiga mit)
- Parent: direkt unter `%Props` (wie Birch), **nicht** unter `DistrictOhringen`
- Collision über bestehendes `_attach_building_collision` (kein Sonderpfad)
- Tests: Bachtobel **ist** platziert; Weid, Schneckenwiese, Ohringen-Kiga **bleiben abwesend**; Schul-Campus-Asserts (S01–S03) unangetastet
- Art: bestehende PNG behalten (Silhouette passt) — siehe Art-Bedarf

### Nicht

- Kindergarten Weid (`S05`), Schneckenwiese (`S06`), Ohringen (`S07`)
- Schul-Campi Birch / Rietacker / Ohringen (`S01`–`S03` erledigt — Getter, Cluster-Counts, Off-Road der Schulen nicht umbauen)
- Bahnhof (`S08`), Gleise (`S09`), Badi (`S10`), Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing
- Separates Spielplatz-Prop (Slide/Sandkasten stecken schon in der PNG)
- 2018er Garderoben-Anbau als zweites Gebäude (Gemeinde-Umbau intern; ein Prop)
- RoadKit / `seuzach_roads.json` ändern (Bachtobelstrasse existiert; Off-Road-Slack ist grün)
- `SCHOOL_SCALE` global ändern
- `Sprite2D.rotation` am Kiga (Iso-¾ wie authored; Lage = Maps-Ausrichtung)
- `DistrictBachtobel`-Node (Meta reicht); **kein** `district=forrenberg` (A1-Hub)

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

| | |
|--|--|
| OSM amenity | node `9947071082` amenity=kindergarten *Kindergarten Bachtobel*, check_date 2024-08-30 |
| OSM Gebäude | way `142728231` `building=school`, `building:levels=2`, `roof:levels=1`, `roof:shape=gabled`, `addr:housenumber=17` |
| Gemeinde | Primarschule Seuzach, **Bachtobelstrasse 17, 8472 Seuzach** (zwei Abteilungen) |
| GPS Platzierung | **47.5376225, 8.7380927** (Nominatim-Zentroid way `142728231`) |
| Welt | `kiga_bachtobel_world()` ≈ `(16973.4, −8656.3)` · Feld ≈ `(170, −87)` |
| Lage | ~459 m Nord / ~900 m Ost der Kirche; NE-Dorf, **nördlich** Campus Birch |

Amenity-Node (nicht als Sprite-GPS verwenden): `47.5375438, 8.7380225` → Welt ≈ `(16873.8, −8491.0)` — ~10 m SW des Gebäude-Zentroids (~189 wu). Ein Getter, ein Prop: Gebäude-Zentroid wie Schulhaus-Props.

Nominatim `hamlet=Forrenberg` in der Adresszeile ist OSM-Hierarchie, **nicht** der A1-Hub (`forrenberg_world()` liegt südlich, `y > 0`). Guard: Kiga `x > 15000` und `y < −8000`.

Relativlage (Kartenbild, N = kleineres Y):

```
        Herbstackerstrasse N
                    Kiga Bachtobel 17
                         |
        Bachtobelstrasse (lokal, SW des Props in RoadKit)
                         |
              Campus Birch S  (~254 m / 4790 wu südlich)
              Bahnhof / Stationsstrasse weiter SO
    Kirche W                A1-Forrenberg weit S (nicht hier)
```

OSM-Grundriss way `142728231` (Stand 2026-08-11): bbox ~35 m N–S × ~27 m O–W, unregelmässig/gestuft; längste Kante ~15 m, grob **NW–SE** (~48° westlich von N). Spiel-Sprite bei `SCHOOL_SCALE=0.22` ist visuell ~11,5 m (990×991 px) — bestehende Schul-Konvention, hier nicht skalieren.

RoadKit: Gebäude-Zentroid vs. `seuzach_roads.json` Bachtobelstrasse (lokal, `half_w=36`): Füße ≈ 576 wu, AABB ≈ 473 wu vs. Need 100 / 50. Nächste anderen: Herbstackerstrasse ~662 wu. Off-Road-Asserts sollen ohne JSON-Änderung grün bleiben.

Ist-Zustand (warum dieser Slice): `_place_landmarks()` setzt nur Schul-Cluster. `KIGA_IDS` und `_has_kindergarten` existieren in `tests/m3_world_landmarks_test.gd`, werden aber **nicht** für Abwesenheit der Dorf-Kigas genutzt — nur `kiga_ohringen` ist in `_assert_ohringen_campus` explizit verboten. S04 platziert **nur** Bachtobel und lockt die anderen drei auf Abwesenheit.

## Systeme

- `scripts/seuzach_geo.gd` — GPS-Konstanten + `kiga_bachtobel_world()` (Schul-Getter unangetastet)
- `scripts/world_sandbox.gd` — `_place_landmarks()` / neues `_place_kindergartens()` nur Bachtobel; `_add_prop` + `_attach_building_collision` unverändert
- `tests/m3_world_landmarks_test.gd` — Bachtobel-Layout; andere Kigas abwesend; Schul-Asserts bleiben
- `tests/m3_building_occlusion_test.gd` — Sample bleibt Birch; neuer Prop NE darf Occlusion nicht kippen
- `tests/m2_world_test.gd` — nicht regressieren
- Art `assets/art/landmark_kiga_bachtobel.png` (bestehend)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Kiga nicht platziert, siehe Scope).

## Technische Schritte

1. **`SeuzachGeo`:** Schul-/Bahnhof-/Badi-/Forrenberg-Konstanten nicht ändern. Neu:
   - `KIGA_BACHTOBEL_LAT := 47.5376225`
   - `KIGA_BACHTOBEL_LON := 8.7380927`
   - `kiga_bachtobel_world() -> gps_to_world(...)`  
   Kommentar: OSM way `142728231` Bachtobelstrasse 17, nicht amenity-Node, nicht Forrenberg-Hub.
2. **`world_sandbox.gd`:** Nach `_place_school_clusters()` ( `_prop_parent` ist wieder `_props`) `_place_kindergartens()` aufrufen. Darin **nur**:
   ```
   _add_prop(
     "landmark_kiga_bachtobel.png",
     SeuzachGeo.kiga_bachtobel_world(),
     SCHOOL_SCALE,
     {"landmark_id": "kiga_bachtobel", "kindergarten_id": "kiga_bachtobel", "district": "bachtobel"},
     "kiga_bachtobel"
   )
   ```
   Keine `rotation`. Kein Weid/Schneckenwiese/Ohringen-Kiga. Kein `school_cluster`.
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd`:
   - `KIGA_IDS` **nutzen** (heute tot): neue Funktion `_assert_kiga_bachtobel(sprites)` aus `_run` aufrufen (nach den Campus-Asserts).
   - Bachtobel **vorhanden:** Node `kiga_bachtobel`; Metas `landmark_id` / `kindergarten_id` / `district` wie Scope; `_has_kindergarten(..., "kiga_bachtobel")` true.
   - GPS-Konstanten matchen die Tabelle; Getter `distance_to(Vector2(16973.4, -8656.3)) < 1.0`.
   - Position ≤ **80 wu** zum Getter.
   - Quadrant: `x > 15000` und `y < -8000` (NE-Dorf, nicht SW-Ohringen, nicht Forrenberg-Süd).
   - Relativ: `kiga.position.y < birch_world().y - 4000` (nördlich Birch); `kiga.position.x > birch_world().x` (östlich Birch); Distanz zu `ohringen_world()` und `forrenberg_world()` jeweils **> 8000 wu**.
   - Parent-Kette enthält **nicht** `DistrictOhringen`.
   - `rotation == 0`; `has_building_collision`.
   - **Andere drei Kigas abwesend:** für jedes `id` in `KIGA_IDS` ausser `kiga_bachtobel`: `not _has_kindergarten` und `_find_named(..., id) == null`. Ohringen-Guard in `_assert_ohringen_campus` darf stehen bleiben (doppelt ok).
   - Off-Road: die Schleife in `_assert_schools_off_roads` um Sprites mit `kindergarten_id` erweitern (gleiche Need-Formel `half_w+14+50` Füße / `half_w+14` AABB). **Nicht** `school_cluster` am Kiga setzen.
   - Optional in `_assert_kiga_bachtobel`: `_assert_road_near(ground, "Bachtobelstrasse", SeuzachGeo.kiga_bachtobel_world(), 900.0)` — Marker existiert schon, nicht die globale Required-Road-Liste anfassen.
   - Birch-/Rietacker-/Ohringen-OSM-Blöcke, Cluster-Counts (=3), `kiga_ohringen not placed (S07)` **nicht** umbauen.
4. **Occlusion / m2:** keine Sample-Umbiegung auf den Kiga; `m2_world_test` unverändert erwarten.
5. **Art-Gate:** bestehende PNG behalten — siehe Art-Bedarf. `comic-rettung-art` nur wenn Playtest Silhouette kippt. Pipeline dann: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Bachtobel (Schul-Campi visuell nicht umbauen).

## Testplan

### Automatisiert

- [x] `kiga_bachtobel` in `world_sandbox` unter `%Props` vorhanden, Metas wie Scope
- [x] Position ≈ `kiga_bachtobel_world()`, Toleranz 80 wu; Getter ≈ `(16973.4, −8656.3)`
- [x] NE-Guard `x > 15000`, `y < −8000`; nördlich und östlich von Birch; weit von Ohringen- und Forrenberg-Ankern
- [x] `kiga_weid`, `kiga_schneckenwiese`, `kiga_ohringen` **nicht** platziert (`KIGA_IDS`)
- [x] Kein `school_cluster` am Kiga; Birch/Rietacker/Ohringen bleiben je genau 3
- [x] Off-Road (Füße + AABB) inkl. Bachtobelstrasse ohne Road-JSON-Änderung
- [x] BuildingCollision; `rotation` 0; nicht unter `DistrictOhringen`
- [x] S01–S03 Campus-Asserts und `m2_world_test` grün
- [x] Art-Datei existiert (`REQUIRED_ART` enthält `landmark_kiga_bachtobel.png` bereits)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Ein Kindergarten-Gebäude an Bachtobelstrasse 17 (NE, nördlich Birch), Füße auf Gras nicht auf Asphalt
- [x] Collision blockiert wie Schulhäuser; Spieler kann an der Fassade vorbei
- [x] Y-Sort: Spieler südlich der Fassade davor, nördlich dahinter
- [x] Keine Weid-/Schneckenwiese-/Ohringen-Kiga-Props; Schul-Cluster unverändert
- [x] Kein Sprite-Twist; Iso-¾ wie authored
- [x] Keine weissen/schwarzen AI-Platten (`verify_art_alpha`)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. Bachtobel-GPS/Off-Road; smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s04-kiga-bachtobel.png` (player at `kiga_bachtobel_world()`, zoom 0.55): ein Giebel-Kiga, Rutsche+Sandkasten lesbar, Füße auf Gras; Bachtobelstrasse SW am Rand, nicht unter dem Prop. Keine anderen Kigas. Bestehende PNG behalten.

## Art-Bedarf

- [x] Keine neuen Assets *(Default: bestehende `landmark_kiga_bachtobel.png` 990×991 RGBA)*
- [ ] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur dieser Kiga** — **nur wenn** Playtest/Street View die Silhouette kippt

**Warum behalten (anders als S01/S03 Flachdach-Rewrites):**

| Quelle | Silhouette |
|--------|------------|
| OSM way `142728231` | `building:levels=2`, `roof:shape=gabled`, `roof:levels=1` |
| Gemeinde 2018 (Umbau Bachtobelstrasse) | Obergeschoss (Garderobe → Gruppenraum) — zweigeschossig bestätigt |
| Ist-PNG | 2-geschossiges **Giebel**-Häuschen, Lachsputz, Vordach, Hecke, Rutsche + Sandkasten — lesbarer Kiga, Iso-¾ |

Kein Giebel/Flachdach-Konflikt. Farbe/Spielgeräte sind Style-C-Kiga-Sprache, kein zweites Gebäude. Weid-PNG ist bereits eine andere Variante (grün, Schaukel) — nicht verwechseln, nicht ersetzen.

**Falls Playtest kippt** (langes Pavillon, dominanter Flachdach-Anbau, falsches Facing vs. Street View Bachtobelstrasse 17): Rewrite **nur** `assets/art/landmark_kiga_bachtobel.png`, gleicher Pfad.

**Auftrag `comic-rettung-art` nur dann:**

- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View Bachtobelstrasse 17 Seuzach
- Stil C: Kontur, Cel; kleiner CH-Kiga, Giebel 2 Geschosse, Spielbereich erlaubt
- Iso-¾ Default-Facing; **kein** `Sprite2D.rotation`; kein extra Dir-Set
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Weid-/Schneckenwiese-/Ohringen-Kiga-Art, keine Schul- oder Housing-Art

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Bachtobel-Kiga; keine anderen Kigas; keine Campus-/Bahnhof-/Gleis-/Badi-/Bach-/Wald-/Housing-Änderungen
- [x] Prop auf GPS der Tabelle (±80 wu); NE-Dorf, nicht Forrenberg-Hub
- [x] Off RoadKit-Asphalt; Collision wie Schul-Props; keine Sprite-Rotation
- [x] Art: bestehende Giebel-PNG **oder** dokumentierter Playtest-Rewrite nur dieser Datei
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
