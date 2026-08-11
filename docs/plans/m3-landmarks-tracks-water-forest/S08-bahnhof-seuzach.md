# Slice: S08 — Bahnhof Seuzach

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner / Phase-2 `feature-implementer`  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S08-bahnhof-seuzach.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Der **Bahnhof Seuzach** (Stationsstrasse, moderne S-Bahn) ist als Landmark in der Welt sichtbar; Gebäude-Grundriss und Ausrichtung folgen Google Maps / OSM.

## In diesem Schritt

- `landmark_bahnhof_seuzach.png` an `SeuzachGeo.bahnhof_world()` maps-getreu platzieren (Facing zum Stations-/Gleiskorridor)
- Neue Art nur wenn Silhouette/Ausrichtung zu Maps nicht passt
- Nur das Stationsgebäude (+ ggf. Perron-Masse am Gebäude), nicht die durchlaufende Strecke

## Nicht (andere Feature-Schritte)

- Bahngleise als Strecke (`S09`)
- Schul-Campi, Kindergärten, Badi, Bäche, Wälder, Wohnhäuser

## Ziel

Spieler sieht **östlich** der Kirche / **östlich** Campus Birch an der **Stationsstrasse 53** **ein** Bahnhofs-Prop — Stationsgebäude + Vordach (+ kurze Perron-1-Masse am Gebäude), Füße neben dem RoadKit-Asphalt, Collision wie andere Landmarken, **keine** Sprite-Rotation. Die durchlaufende S-Bahn-Strecke und Perron 2 bleiben **S09**. Schul-Campi (S01–S03) und alle **vier** Kindergärten (S04–S07) bleiben stehen. Keine Badi, keine Bäche, keine Wälder, keine Häuser.

## Scope

### In

- Nur **Bahnhof Seuzach**: ein Prop, Node-Name `bahnhof`
- GPS in `SeuzachGeo`: bestehende `BAHNHOF_LAT/LON` + `bahnhof_world()` auf den Nominatim-Zentroid des OSM-**Gebäudes** umstellen (way `116582470`, `building=train_station`, Stationsstrasse 53) — **nicht** den Bus-Perron, **nicht** den `railway=station`-Node
- Platzierung in `world_sandbox` via `_add_prop` (`landmark_bahnhof_seuzach.png`, `LANDMARK_SCALE` 0.24) aus `_place_landmarks()` (neues `_place_bahnhof()` oder ein Aufruf direkt nach den Kigas)
- Parent: direkt unter `%Props`, **nicht** unter `DistrictOhringen`
- Metas: `landmark_id=bahnhof`, `district=seuzach`, optional `poi_type=station`  
  **Kein** `school_cluster`, **kein** `kindergarten_id`, **kein** `district=forrenberg`
- Collision über bestehendes `_attach_building_collision` (kein Hub-Sonderpfad)
- Tests: Bahnhof **ist** platziert (`if bahnhof:` in `_assert_geo_quadrants` wird zur Pflicht); S01–S07 bleiben grün; Badi/Housing/Wälder/Bäche weiter abwesend
- Art: bestehende PNG **nicht** wiederverwenden — Rewrite Gebäude+Vordach ohne gebackene Gleise/Zug, siehe Art-Bedarf

### Nicht

- Durchlaufende Bahngleise, Perron 2 (Nord), Zug (`S09` — Slice hängt von S08 ab, baut die Strecke)
- Schul-Campi Birch / Rietacker / Ohringen (`S01`–`S03`): Getter, Cluster-Counts (=3), Off-Road der Schulen **nicht** umbauen
- Kindergärten Bachtobel, Weid, Schneckenwiese, Ohringen (`S04`–`S07`): Getter, Props, Tests **nicht entfernen**
- Badi Weiher (`S10`), Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing; Feuerwehr, Gemeindehaus, Kirchen, Läden, Tankstelle, HubEnter
- Bus-Haltestelle / Bus-Perron OSM way `315997018` *Seuzach Bahnhof* (highway=platform an der Stationsstrasse) — kein zweites Prop
- Parkplatz OSM way `128879908` *Bahnhof Seuzach* (Stadlerstrasse), Mobility-Node, avec als Extra-POI
- RoadKit / `seuzach_roads.json` ändern (Stationsstrasse existiert; Off-Road-Slack ist grün)
- `SCHOOL_SCALE` / `LANDMARK_SCALE`-Konstanten global ändern
- `Sprite2D.rotation` am Bahnhof (Iso-¾ wie authored; Lage = Maps-Ausrichtung)
- `DistrictBahnhof`-Node; **kein** Parent `DistrictOhringen`

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

| | |
|--|--|
| OSM Gebäude | way `116582470` `building=train_station`, `building:levels=1`, `roof:shape=flat`, `roof:levels=0`, `addr:housenumber=53`, `addr:street=Stationsstrasse`, `addr:city=Seuzach` — Mitglied stop_area-Relation `1613954` |
| OSM amenity / POI | node `1313973484` `railway=station` + `public_transport=station` *Seuzach* (UIC 8506020) bei **47.5356393, 8.7390219** — **nicht** als Sprite-GPS |
| OSM Vordach | way `116582472` `building=roof` (an die Nordkante des Gebäudes / Perron 1) — im selben Prop andeuten, kein zweites Sprite |
| OSM Perron 1 (Süd, Gebäude) | way `116582443` `railway=platform` `ref=1` `shelter=yes` — kurze Masse am Gebäude erlaubt |
| OSM Perron 2 (Nord) | way `116582447` `railway=platform` `ref=2` `shelter=no` — **S09** |
| OSM Gleis-Stops | node `130250360` (ref 1) und `1313973485` (ref 2) auf Bahnstrasse-Seite, **nördlich** des Gebäudes — **S09** |
| Gemeinde / SBB | **Stationsstrasse 53, 8472 Seuzach**; moderne S-Bahn (~2002), 2 Seitenperrons, 2 Gleise |
| GPS Platzierung | **47.5357159, 8.7388969** (Nominatim-Zentroid way `116582470`) |
| Welt | `bahnhof_world()` ≈ `(18113.8, −4651.7)` · Feld ≈ `(181, −46)` |
| Lage | ~247 m Nord / ~960 m Ost der Kirche; **östlich** Campus Birch (~203 m); **südlich** der Gleise |

**Ist-Konstanten sind der falsche OSM-Treffer:** `BAHNHOF_LAT/LON` 47.5354389 / 8.7393932 = Nominatim-Zentroid des **Bus-Perrons** way `315997018` (`highway=platform`, *Seuzach Bahnhof*, Stationsstrasse) → Welt ≈ `(18817.6, −4069.9)`. ~48 m südöstlich des Gebäudes. Getter-Name bleibt `bahnhof_world()`; Werte **ersetzen**.

Amenity-Node (nicht als Sprite-GPS): `47.5356393, 8.7390219` → Welt ≈ `(18291.1, −4490.8)` — ~12,7 m SO des Gebäude-Zentroids (~239 wu). Ein Getter, ein Prop: Gebäude-Zentroid wie Schulhaus-/Kiga-Props.

Nominatim `hamlet=Forrenberg` in der Adresszeile ist OSM-Hierarchie, **nicht** der A1-Hub (`forrenberg_world()` liegt südlich, `y ≈ 15124`). Guard: Bahnhof `x > 15000` und `y < 0` (Ost-Dorf, nördlich der Kirche), plus Distanz zu `forrenberg_world()` **> 8000 wu**.

Relativlage (Kartenbild, N = kleineres Y):

```
        Perron 2 + Bahnstrasse     N     ← S09
        Gleise (Winterthur SW ↔ Etzwilen NE, lokal NW–SE)
        Perron 1 + Vordach
              Bahnhofgebäude 53     ← dieser Slice (südlich der Gleise)
        Stationsstrasse S (RoadKit main)
        Birch-Campus ~200 m W
        Kirche WSW                  Kiga Bachtobel NNW
        Forrenberg-Hub weit S (nicht hier)
        Bus-Perron / Parkplatz nicht als Props
```

Gebäude **südlich** der Gleise: Stop-Position ref 1 (47.5358162) hat kleineres Y als der Gebäude-Zentroid (`dy ≈ −211 wu` ≈ 11 m Nord). Stationsstrasse liegt südlich (RoadKit-Abstand Zentroid ≈ **258 wu / 13,7 m**). Lange Gebäudeachse grob **NW–SE** (~35 m, Bearing ≈ −43°), parallel zum Gleiskorridor. OSM-BBox ~34 m N–S × ~32 m O–W; Spiel-Sprite bei `LANDMARK_SCALE=0.24` ist visuell kleiner (~13 m bei Ist-PNG 1022×696) — Landmark-Konvention, hier nicht auf reale Meter skalieren.

RoadKit: Gebäude-Zentroid vs. `seuzach_roads.json` Stationsstrasse (`class=main`, `half_w=72`): Füße ≈ 258 wu vs. Need 136 / AABB Need 86. Nächste anderen: Bachtobelstrasse ~1472 wu, Stadlerstrasse ~1691 wu, Bachwiesenstrasse ~1769 wu. Off-Road-Asserts sollen ohne JSON-Änderung grün bleiben. Bestehendes `_assert_road_near(..., "Stationsstrasse", bahnhof_world(), 900)` bleibt gültig (Ist 258).

Ist-Zustand (warum dieser Slice): `_place_landmarks()` setzt nur Schul-Cluster + vier Kigas. PNG existiert in `REQUIRED_ART`, wird aber **nicht** platziert. `_assert_geo_quadrants` prüft Hub/Badi/Bahnhof **nur falls vorhanden** (`if bahnhof:` → `x > 500`). S08 platziert **genau ein** Bahnhofs-Prop und macht die Quadranten-Prüfung zur Pflicht.

### Art-Entscheidung (Reuse vs. Rewrite)

Ist-PNG `assets/art/landmark_bahnhof_seuzach.png` (1022×696 RGBA) backt **kurzes Perron + 2 Gleise + Zugnase** in dasselbe Sprite; Gleise liegen am **unteren** Canvasrand. Im Spiel ist Canvas-unten = Füße = **Süd** (+Y). Real liegen die Gleise **nördlich** des Gebäudes → gebackene Gleise wären auf der Stationsstrasse-Seite, und S09 würde denselben Korridor noch einmal zeichnen.

**Entscheid: Rewrite** (gleicher Dateiname). Nicht wiederverwenden und S09 „daneben“ legen — das dupliziert Gleis+Zug und verdreht die Karte. S08 liefert Gebäude + Vordach + optionale kurze Perron-1-Kante nach Norden; S09 hängt die durchlaufende Strecke an diese Nordkante.

## Systeme

- `scripts/seuzach_geo.gd` — `BAHNHOF_LAT/LON` auf Gebäude-Zentroid; `bahnhof_world()` unverändert als Getter; Schul-/Kiga-/Badi-/Forrenberg-Konstanten unangetastet
- `scripts/world_sandbox.gd` — `_place_landmarks()` um Bahnhof erweitern; `_place_school_clusters()` / `_place_kindergartens()` unverändert; `_add_prop` + `_attach_building_collision` unverändert
- `tests/m3_world_landmarks_test.gd` — Bahnhof-Layout; S01–S07-Asserts bleiben; `if bahnhof:` → Pflicht; Housing/Wald/Hügel-Absents bleiben
- `tests/m3_building_occlusion_test.gd` — Sample bleibt Birch; neuer Prop mit `landmark_id` fällt unter Feet-Offset-Schleife (`>= 8` bleibt gültig)
- `tests/m2_world_test.gd` — nicht regressieren (`prop_sprites >= 1`)
- Art `assets/art/landmark_bahnhof_seuzach.png` (bestehend, Silhouette-Rewrite siehe Art-Bedarf)

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Bahnhof-PNG auf Disk, nicht platziert; GPS zeigt auf Bus-Perron; Tests prüfen Bahnhof nur falls vorhanden).

## Technische Schritte

1. **`SeuzachGeo`:** Schul-/Kiga-/Badi-/Forrenberg-Konstanten nicht ändern. `bahnhof_world()` bleibt `gps_to_world(BAHNHOF_LAT, BAHNHOF_LON)`. Werte ersetzen:
   - `BAHNHOF_LAT := 47.5357159`
   - `BAHNHOF_LON := 8.7388969`  
   Kommentar: OSM way `116582470` Stationsstrasse 53 (`building=train_station`), nicht Bus-Perron way `315997018`, nicht `railway=station` node `1313973484`, nicht Gleis-Stops `130250360` / `1313973485`.
2. **`world_sandbox.gd`:** In `_place_landmarks()` **Schulen und alle vier Kigas behalten**. Danach Bahnhof unter `%Props` (`_prop_parent = _props`):
   ```
   _add_prop(
     "landmark_bahnhof_seuzach.png",
     SeuzachGeo.bahnhof_world(),
     LANDMARK_SCALE,
     {"landmark_id": "bahnhof", "district": "seuzach", "poi_type": "station"},
     "bahnhof"
   )
   ```
   Keine `rotation`. Kein `school_cluster`. Kein `kindergarten_id`. Nicht unter `DistrictOhringen`. Kein Badi-/Gleis-/Wald-/Housing-Prop. Kommentar an `_place_landmarks` von „schools + kindergartens“ auf „+ Bahnhof“ anpassen.
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd`:
   - Neue Funktion `_assert_bahnhof(world, sprites)` aus `_run` aufrufen (nach `_assert_kiga_ohringen`, vor oder nach `_assert_geo_quadrants`).
   - Bahnhof **vorhanden:** Node `bahnhof`; Metas `landmark_id=bahnhof`, `district=seuzach`; `_find_landmark(..., "bahnhof")` nicht null; Count = 1.
   - GPS-Konstanten matchen die Tabelle (47.5357159 / 8.7388969); Getter `distance_to(Vector2(18113.8, -4651.7)) < 1.0`.
   - Position ≤ **80 wu** zum Getter.
   - Quadrant: `x > 15000` und `y < 0` (Ost-Dorf nördlich der Kirche, nicht Forrenberg-Süd, nicht Ohringen-SW).
   - Relativ: `bahnhof.position.x > birch_schulhaus_a_world().x` (östlich von Birch-a); Distanz zu `birch_world()` **> 3000** und **< 5000** wu (Ist ≈ 3830); Distanz zu `forrenberg_world()` **> 8000**; Distanz zu `kiga_ohringen_world()` **> 8000**; Distanz zu `ohringen_world()` **> 15000**.
   - Südlich der Gleis-Stops: `bahnhof.position.y > gps_to_world(47.5358162, 8.7389630).y` (Gebäude südlich Stop ref 1) — die Stop-Konstanten **nicht** in `seuzach_geo` aufnehmen, im Test inline oder als Kommentar-GPS.
   - Parent-Kette **ohne** `DistrictOhringen`.
   - `rotation == 0`; `has_building_collision`; **kein** `school_cluster` / `kindergarten_id`; `district != forrenberg`.
   - **`_assert_geo_quadrants`:** `if bahnhof:` durch Pflicht ersetzen (`bahnhof != null`, `x > 10000` oder die schärfere Guard aus `_assert_bahnhof`). Hub/Badi weiter nur falls vorhanden. Birch/Rietacker/Ohringen-Blöcke nicht umbauen.
   - **S01–S07 bleiben:** `_assert_birch_campus` / `_assert_rietacker_campus` / `_assert_ohringen_campus` / alle vier `_assert_kiga_*` weiter aufrufen. `house_n == 0`, `forest_n == 0`, keine Hill-Marker.
   - Off-Road: `_assert_schools_off_roads` **nicht** um `school_cluster` am Bahnhof erweitern. In `_assert_bahnhof` denselben Feet/AABB-Clearance gegen alle named-road-Polylines (Need = `half_w+64` / `half_w+14`) **oder** kleinen Helper, der Schulen unverändert lässt. Plus `_assert_road_near(ground, "Stationsstrasse", SeuzachGeo.bahnhof_world(), 900.0)` darf in `_assert_named_roads` stehen bleiben.
   - `_assert_named_roads`: `bahnhof_world().x > 10000` bleibt gültig (18114); GPS-Werte dort nicht hart auf den alten Bus-Perron kodieren.
4. **Occlusion / m2:** keine Sample-Umbiegung auf den Bahnhof; `m3_building_occlusion_test` Cluster-Spacing bleibt `school_cluster`; Bahnhof bekommt Feet-Offset-Checks automatisch über `landmark_id`. `m2_world_test` unverändert erwarten.
5. **Art-Gate:** Silhouette kippt (2-geschossig + Gleise+Zug am Südrand vs. 1-geschossiges Flachdach südlich der Gleise) — `comic-rettung-art` **dieser** PNG, siehe Art-Bedarf. Pipeline: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Bahnhof (Schulen/Kigas visuell nicht umbauen; keine Strecke zeichnen).

## Testplan

### Automatisiert

- [x] `bahnhof` in `world_sandbox` unter `%Props` vorhanden, Metas wie Scope; genau 1
- [x] Position ≈ `bahnhof_world()`, Toleranz 80 wu; Getter ≈ `(18113.8, −4651.7)`; Konstanten = Gebäude-Zentroid nicht Bus-Perron
- [x] Guard `x > 15000`, `y < 0`; östlich Birch-a; südlich Stop ref 1; weit von Forrenberg-Hub und Ohringen
- [x] Alle drei Schul-Campi (je 3) und alle vier Kigas **weiter platziert**
- [x] Kein Housing, kein Forest-Prop, keine Hill-Marker, kein Badi-Prop, keine Gleis-Strecke
- [x] Off-Road (Füße + AABB) inkl. Stationsstrasse ohne Road-JSON-Änderung
- [x] BuildingCollision; `rotation` 0; Parent **nicht** `DistrictOhringen`
- [x] S01–S07-Asserts und `m2_world_test` grün
- [x] Art-Datei existiert (`REQUIRED_ART` enthält `landmark_bahnhof_seuzach.png` bereits)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Ein modernes Stationsgebäude an Stationsstrasse 53 (Ost, östlich Birch), Füße auf Gras/Vorplatz **nicht** auf Asphalt; Gleiskorridor nördlich lesbar als Lücke (noch ohne S09-Strecke)
- [x] Collision blockiert das Gebäude; Spieler kann an der Fassade und zwischen Bahnhof und Stationsstrasse vorbei
- [x] Y-Sort: Spieler südlich der Fassade davor, nördlich (Gleisseite) hinter/unter dem Vordach je nach Y
- [x] Schulen und vier Kigas weiter sichtbar; keine Badi, keine Wälder, keine Häuser, **kein** durchgehendes Gleisband
- [x] Kein Sprite-Twist; Iso-¾ wie authored; **keine** gebackenen Gleise/Zug im Sprite
- [x] Keine weissen/schwarzen AI-Platten (`verify_art_alpha`)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. Bahnhof-GPS/Off-Road (Stationsstrasse feet d=258 / AABB 134; Bachtobelstrasse 1472); smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s08-bahnhof.png` (player at `bahnhof_world()`, zoom 0.5): 1-geschossige Flügel + höherer Mittelrisalit, Flachdach, Vordach/Perron-1-Kante mit gelber Linie **nördlich**; **keine** Gleise/Zug im Sprite; Füße auf grauem Vorplatz, Stationsstrasse daneben (nicht unter dem Prop). Parent `%Props`; Schulen je 3, vier Kigas platziert; house_n=0. Rewrite bestätigt (kein Zug am Südrand). Zentraler Trakt liest sich höher als OSM `building:levels=1` — Flügel 1-geschossig; Gleise/Zug weggelassen wie Slice-Fallback.

## Art-Bedarf

- [ ] Keine neuen Assets *(nicht der Default — Silhouette und Gleis-Duplikat mit S09 kippen)*
- [x] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur dieser Bahnhof** — Rewrite geliefert, Playtest bestätigt Gebäude+Vordach ohne Gleise/Zug

**Warum Rewrite:**

| Quelle | Silhouette |
|--------|------------|
| OSM way `116582470` | `building=train_station`, **1 Geschoss**, `roof:shape=flat`; Grundriss ~35×11 m gestuft, lange Achse NW–SE, **südlich** der Gleise |
| OSM way `116582472` | `building=roof` Vordach über Perron 1 (Nordkante des Hauses) |
| Maps / Street View / SBB | Moderner S-Bahn-Halt ~2002, weiss/grau, Flachdach, Vordach zu den Gleisen, avec im Gebäude; Stationsstrasse Süd, Gleise Nord |
| Ist-PNG | 1022×696: **2-geschossig** (weisser Block, roter Sockel), Vordach, **2 Gleise + Zugnase am unteren Rand** = Süd im Spiel |

Gleis+Zug im Landmark-Sprite würden S09 duplizieren und auf der **falschen** Gebäudeseite sitzen. Zweigeschossigkeit widerspricht OSM `building:levels=1`. Vordach und kurze Perron-1-Kante **bleiben** im Auftrag (Stub: „ggf. Perron-Masse am Gebäude“).

**Auftrag `comic-rettung-art` (Phase 2b):**

- Rewrite **nur** `assets/art/landmark_bahnhof_seuzach.png`, gleicher Pfad
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View / Satellit Bahnhof Seuzach Stationsstrasse 53 (nicht Winterthur HB, nicht Forrenberg-Hub)
- Stil C: Kontur, Cel; kleiner CH-S-Bahn-Halt als **1-geschossiges Flachdach** + **Vordach nach Norden** (Gleiskorridor); kurze Perron-1-Kante unter dem Vordach erlaubt (gelbe Sicherheitslinie ok)
- **Keine** Gleise, **kein** Zug, **kein** zweites Nord-Perron, kein Bus, kein P+Rail-Parkplatz als eigenes Volumen
- Iso-¾ Default-Facing: Strassen-/Südseite zum Betrachter (Canvas-unten = Stationsstrasse), Vordach/Perron zur Gleisseite (Canvas-oben = Nord). Lange Achse lesbar parallel zum Korridor. **Kein** `Sprite2D.rotation`; kein extra Dir-Set
- SBB-Rot als schmaler Akzent ok, keine Logos/Wortmarken (kein avec-Schriftzug)
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Schul-/Kiga-/Badi-/Housing-Art, kein Gleis-Tileset (S09)

Falls Playtest **2 Geschosse** am echten Haus bestätigt: Höhe im Sprite anpassen, Gleise/Zug trotzdem weglassen.

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Bahnhof-Gebäude neu platziert; Schulen + 4 Kigas bleiben; keine Gleis-Strecke, keine Badi/Bach/Wald/Housing
- [x] Prop auf GPS der Tabelle (±80 wu); Ost-Dorf unter `%Props`, nicht Forrenberg-Hub, nicht Ohringen; Gebäude **südlich** der Gleise
- [x] Off RoadKit-Asphalt (Stationsstrasse daneben); Collision wie Landmark-Props; keine Sprite-Rotation
- [x] Art: Gebäude+Vordach Style C **ohne** gebackene Gleise/Zug; Facing zum Gleiskorridor/Stationsstrasse
- [x] `BAHNHOF_LAT/LON` = OSM-Gebäude, nicht Bus-Perron
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
