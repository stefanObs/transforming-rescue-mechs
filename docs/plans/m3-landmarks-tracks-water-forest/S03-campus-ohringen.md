# Slice: S03 — Campus Ohringen (Maps-Ausrichtung)

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner / Phase-2 `feature-implementer`  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S03-campus-ohringen.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Der Primarschul-Campus **Ohringen** (SW, eigene Rasterzellen, gehört zu Seuzach) steht als Gebäudecluster mit maps-getreuem Grundriss und Facing — nicht die Generic-Offsets der Dorf-Campi.

## In diesem Schritt

- Cluster `schulhaus_ohringen_a` / `_b` + `turnhalle_ohringen` an `SeuzachGeo.ohringen_world()` maps-getreu im District Ohringen
- Bestehende PNGs; neue Art nur wenn Silhouette/Ausrichtung falsch ist
- Mehrere Gebäude, kein Megablock; Ohringen bleibt eigene Zellen

## Nicht (andere Feature-Schritte)

- Campus Birch / Rietacker
- Kindergarten Ohringen (`S07`) und die drei Dorf-Kigas
- Bahnhof, Gleise, Badi, Bäche, Wälder, Wohnhäuser

## Ziel

Spieler sieht im SW von Seuzach (Oberohringen, Schulstrasse 9 / 7; eigene Rasterzellen, Gemeinde Seuzach) **drei getrennte** Schul-Props: historisches Schulhaus, Schultrakt 1985 und Turnhalle in der realen Relativlage. Der Campus ist ein Cluster unter `DistrictOhringen`, kein Megablock; Gebäude stehen **neben** RoadKit-Asphalt, mit derselben BuildingCollision wie die anderen Schul-Props. Ohringen bleibt SW (`x < -15000`, `y > 8000` bei Feld-Massstab).

## Scope

### In

- Nur Campus **Ohringen**: Nodes `schulhaus_ohringen_a`, `schulhaus_ohringen_b`, `turnhalle_ohringen` unter bestehendem `DistrictOhringen`
- Anker bleibt `SeuzachGeo.ohringen_world()` = Nominatim-Zentroid der Schul**anlage** (OSM way `917552680` amenity=school *Schulhaus Ohringen*, `OHRINGEN_LAT/LON` unverändert `47.5280584` / `8.7121325`)
- Drei Gebäude-Lagen aus OSM/Gemeinde (nicht die Generic-Offsets `+(280,0)` / `+(-164.8, 226.4)` / `+(-86.1, -266.4)`, die S02 für Ohringen noch lockt)
- Metas unverändert in der Semantik: `school_cluster=ohringen`, `district=ohringen`; a/b `landmark_id=schulhaus_ohringen`; Turnhalle `landmark_id=turnhalle_ohringen`, `poi_type=gym`
- Collision über bestehendes `_attach_building_collision` (kein Sonderpfad)
- Tests: Ohringen-OSM-Layout-Asserts; die drei Ohringen-Generic-Guards in `_assert_birch_campus` **ersetzen**; **Birch- und Rietacker-OSM-Asserts nicht anfassen**
- Art: Dateinamen unter `assets/art/` behalten; Style-C-Rewrite **nur** wo Giebel/Flachdach kippt (wie Birch), siehe Art-Bedarf

### Nicht

- Campus Birch (`S01` erledigt — `birch_*_world()` / Birch-Tests bleiben)
- Campus Rietacker (`S02` erledigt — `rietacker_*_world()` / Rietacker-Tests bleiben)
- Kindergarten Ohringen (`S07`) — OSM way `52373683` *Kindergarten Ohringen*, Schulstrasse **5** (amenity=kindergarten). Nicht als `schulhaus_ohringen_b` missbrauchen, nicht platzieren
- Die drei Dorf-Kigas (`S04`–`S06`), Bahnhof (`S08`), Gleise (`S09`), Badi (`S10`), Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing
- Hartplatz OSM way `136492025` (`leisure=pitch`, soccer westlich der Gebäude)
- Vordächer/Sheds: ways `727214863` / `727214864` (`building=roof`), `727214865` (~5×6 m `building=yes`)
- RoadKit / `seuzach_roads.json` ändern (Schulstrasse / Schaffhauserstrasse / Rundstrasse / Rebhogerstrasse reichen; Off-Road-Slack ist grün)
- `SCHOOL_SCALE` global ändern (gilt für alle Campi)
- `Sprite2D.rotation` an Gebäuden (Iso-¾ wie authored; Lage = Maps-Ausrichtung)
- Birch-S01-Art oder Rietacker-S02-Art

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

Campus-Anker (unverändert):

| | |
|--|--|
| OSM | way `917552680` amenity=school *Schulhaus Ohringen* (operator Primarschule Seuzach, grades 0–6, check_date 2025-01-30) |
| GPS | 47.5280584, 8.7121325 |
| Welt | `ohringen_world()` ≈ `(−19840.5, 11431.9)` · Feld ≈ `(−198, 114)` |
| Lage | ~606 m Süd / ~1052 m West der Kirche; Gemeindeadresse Schulstrasse 9, 8472 Oberohringen |

OSM hat nur **zwei** `building=school`-Ways plus den Kiga (S07). Gemeinde Seuzach trennt trotzdem drei Volumen: historisches Schulhaus 9, **Schultrakt 1985** (Flachdächer, Kredit 2022) und **Turnhalle Oberohringen** Schulstrasse 7 (Flachdach + PV 2022). Way `52373583` (Schulstrasse 7) ist ein L-Grundriss ~40×44 m, der Trakt und Halle **zusammenfasst** — dieser Slice splittet das L (kein erfundenes GPS ausserhalb des Ways).

Gebäude (Stand OSM 2026-08-11 + Gemeinde):

| Prop | OSM / Adresse | GPS | Offset von `ohringen_world()` | Offset Meter | Felder |
|------|----------------|-----|----------------------------|--------------|--------|
| `schulhaus_ohringen_a` | way `52373582` *Schulhaus Ohringen*, Schulstr. **9** (Nominatim-Zentroid) | 47.5283478, 8.7123497 | `Vector2(308.0, -607.8)` | +16,3 m Ost, **32,2 m Nord** | +3,08 / −6,08 |
| `schulhaus_ohringen_b` | NE-Flügel von way `52373583` (1985er Schultrakt; grenzt südlich an #9 bei lat 47.5281911) | 47.5281003, 8.7125046 | `Vector2(527.7, -88.0)` | **28,0 m Ost**, 4,7 m Nord | +5,28 / −0,88 |
| `turnhalle_ohringen` | Nominatim way `52373583`, Schulstr. **7** (Gemeinde: Turnhalle Oberohringen; Zentroid sitzt im West-Schenkel ~12×28 m ≈ 12×24-Halle) | 47.5279647, 8.7122618 | `Vector2(183.4, 196.8)` | +9,7 m Ost, **10,4 m Süd** | +1,83 / +1,97 |

**b-GPS (reproduzierbar):** arithmetisches Mittel der vier OSM-Ecken des Ost-Schenkels von way `52373583`:

- N (Stoss an #9): `47.5281911, 8.7124802`
- O: `47.5281339, 8.7126320`
- S: `47.5279949, 8.7125169`
- W (Taille des L): `47.5280811, 8.7123891`

Nicht Nominatim des ganzen Ways — das wäre fast identisch mit der Turnhalle (~2 m, Megablock).

Relativlage (Kartenbild, N = kleineres Y):

```
        a Schulhaus 9  (nördlich, Schulstrasse 9)
              |
              |                 b Schultrakt 1985  (östlich, an #9)
              +-- Anker ohringen_world()
    Turnhalle 7 S                 Kiga 5 SO = S07, nicht platzieren
   (West-Schenkel #7)
         Schaffhauserstrasse SW     Rundstrasse O     Schulstrasse W/NW
```

Paar-Abstände (Zentroide): a↔b ≈ 564 wu (30 m), a↔Turnhalle ≈ 814 wu (43 m), b↔Turnhalle ≈ 447 wu (24 m). Alle ≫ `MIN_CLUSTER_SEP` 160.

OSM-Grundrisse:

| Prop | Tags | Lange Achse (längste Kante) |
|------|------|-----------------------------|
| a | `building=school`, name *Schulhaus Ohringen*, kein `roof:shape` | bbox ~32×37 m; längste Kante ~21 m, grob **ENE** (59°) |
| b | kein eigener Way — Ost-Schenkel von `52373583` `building=school` | Gemeinde: Schultrakt **1985**, **Flachdächer** (Sanierung 2022) |
| Turnhalle | Nominatim von `52373583` (West-Parallelogramm ~28×12 m, Kante 29° NNE) | Gemeinde: Turnhalle Oberohringen Schulstr. 7, **Flachdach** + PV 2022; kein `leisure=sports_hall`-Tag |

Spiel-Sprites bei `SCHOOL_SCALE=0.22` sind ~10–12 m visuell — bestehende Konvention, hier nicht skalieren. a und b teilen in OSM eine Kante (angrenzend); im Spiel bleibt eine Hof-Lücke wegen Sprite-Maßstab — gewollt, kein Megablock.

Ist-Zustand (warum dieser Slice): `_place_school_clusters()` setzt Ohringen mit denselben Dummy-Offsets wie vor S01/S02 (~15 m Dreieck um den Anker). Real sitzt das Schulhaus ~32 m **nördlich** des Anlagen-Zentroids; die Turnhalle ~10 m **südlich**; der 1985er Trakt ~28 m östlich. S02-Tests **locken** die drei Ohringen-Props auf die Generic-Offsets — diese Guards müssen weg.

RoadKit: OSM-Lagen vs. `seuzach_roads.json` (Füße / AABB, bestehende PNGs @ 0.22): a↔Schulstrasse Slack ≈ 267 / 158 wu vs. Need 100 / 50; b↔Rundstrasse ≈ 325 / 262; Turnhalle↔Schaffhauserstrasse ≈ 396 / 391. Off-Road-Asserts (`half_w + 14` AABB, `half_w + 14 + 50` feet) sollen ohne JSON-Änderung grün bleiben.

## Systeme

- `scripts/seuzach_geo.gd` — Ohringen-Gebäude-GPS → Welt (Getter, Anker unangetastet; Birch- und Rietacker-Getter bleiben)
- `scripts/world_sandbox.gd` `_place_school_clusters()` — nur die drei Ohringen-`_add_prop`-Positionen; `DistrictOhringen`-Node bleibt
- `tests/m3_world_landmarks_test.gd` — Ohringen-Layout; 800 wu-Nähe anpassen soweit Ohringen sonst rot wird; Birch- und Rietacker-OSM-Asserts behalten
- `tests/m3_building_occlusion_test.gd` — Cluster-Spacing Ohringen bleibt gültig (≥ 160)
- `tests/m2_world_test.gd` — nicht regressieren
- Art `assets/art/landmark_schulhaus_ohringen_{a,b}.png`, `landmark_turnhalle_ohringen.png`

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Generic-Offsets, siehe Scope).

## Technische Schritte

1. **`SeuzachGeo`:** `OHRINGEN_LAT/LON` und `ohringen_world()` nicht ändern. `BIRCH_*` / `RIETACKER_*` und deren Getter nicht ändern. GPS-Konstanten + Getter nur für Ohringen-Gebäude: `ohringen_schulhaus_a_world()`, `ohringen_schulhaus_b_world()`, `ohringen_turnhalle_world()` via `gps_to_world` der Tabelle oben.
2. **`world_sandbox.gd`:** In `_place_school_clusters()` die drei Ohringen-Positionen auf diese Getter umstellen (Kommentar „Ohringen keeps generic“ entfernen). Birch und Rietacker bleiben auf OSM-Gettern. Props weiter Kind von `DistrictOhringen` (`position = Vector2.ZERO` am District). Keine `rotation` an den Sprites. `_add_prop` + `_attach_building_collision` unverändert. **Kein** `kiga_ohringen`.
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd`:
   - Die drei `_assert_generic_campus_offset(...)` für `schulhaus_ohringen_a` / `_b` / `turnhalle_ohringen` **entfernen** (stehen derzeit am Ende von `_assert_birch_campus`). Birch-/Rietacker-OSM-Blöcke **behalten**.
   - Neue Asserts analog `_assert_rietacker_campus` (eigene Funktion `_assert_ohringen_campus`):
     - Nodes `schulhaus_ohringen_a` / `_b` / `turnhalle_ohringen` existieren; Parent-Kette enthält `DistrictOhringen`
     - `OHRINGEN_LAT/LON` unverändert `47.5280584` / `8.7121325`
     - Gebäude-GPS-Konstanten matchen die Tabelle; Getter-Offset vs. Yard `< 1 wu` zu `(308.0, -607.8)` / `(527.7, -88.0)` / `(183.4, 196.8)`
     - Position je ≤ **80 wu** (~4,2 m) zum passenden `SeuzachGeo`-Getter
     - Relativ: `a.position.y < b.position.y - 400` (a nördlich von b); `gym.position.y > max(a.y, b.y)` (Turnhalle südlich beider Schulhäuser); `b.position.x > gym.position.x + 200` (b östlich der Halle); `a.position.x > gym.position.x` (Schulhaus 9 östlich der Halle, knapp)
     - Cluster `ohringen` hat genau **3** Props (birch und rietacker bleiben 3)
     - Alle Ohringen-Mitglieder: Distanz zu `ohringen_world()` **< 900 wu** (~48 m; deckt a bei ~681 wu + 80 Placement). Den Check `ohringen.distance_to(ohringen_world()) < 800` in `_assert_geo_quadrants` auf **900 wu** anheben. Birch-1400 und Rietacker-1600 unverändert.
     - SW-Guard bleibt: erstes `schulhaus_ohringen` (a) `x < -15000` und `y > 8000` (a ≈ `(−19533, 10824)`)
     - Guard: Birch-OSM-Asserts und Rietacker-OSM-Asserts unangetastet (kein Generic-Lock mehr auf Ohringen)
     - `kiga_ohringen` weiterhin **nicht** in der Scene (S07)
     - Off-Road-Schleife für `school_cluster` bleibt; Ohringen soll ohne Road-JSON-Änderung grün sein
     - `rotation == 0`; `has_building_collision` an den drei Props
   - `_assert_generic_campus_offset` ist nach diesem Slice tot — Helper entfernen, falls unbenutzt.
4. **Occlusion:** `m3_building_occlusion_test` Cluster `ohringen` min. Trennung ≥ 160 — Soll min. ~447 wu (b↔Turnhalle). Sample-Player-südlich weiter Birch (nicht umbiegen).
5. **Art-Gate (Phase 2b, nur dieser Campus):** 1985-Flachdach vs. bestehende Giebel-Sprites für **b** und Turnhalle — siehe Art-Bedarf. Nach PNG: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Ohringen-Cluster (Birch/Rietacker visuell nicht umbauen).

## Testplan

### Automatisiert

- [x] `schulhaus_ohringen_a` / `_b` / `turnhalle_ohringen` in `world_sandbox` unter `DistrictOhringen` vorhanden, Metas wie Scope
- [x] Positionen ≈ OSM-Getter, Toleranz 80 wu
- [x] Relativlage: a nördlich von b; Turnhalle südlich von a und b; b östlich der Halle; a östlich der Halle
- [x] Ohringen-Cluster = 3 Gebäude; min. Abstand ≥ 160 wu (`m3_building_occlusion_test`)
- [x] Jedes Ohringen-Mitglied < 900 wu von `ohringen_world()`; `ohringen_world()` selbst unverändert
- [x] Ohringen bleibt SW (`x < -15000`, `y > 8000`)
- [x] Birch-OSM-Asserts und Rietacker-OSM-Asserts weiterhin grün (Getter, Relativlage, Offsets)
- [x] `kiga_ohringen` nicht platziert
- [x] `_assert_schools_off_roads` grün (Ohringen nicht auf Asphalt)
- [x] BuildingCollision an den drei Ohringen-Props (`has_building_collision`); `rotation` 0
- [x] `m2_world_test`, übrige Landmark-Asserts (Kigas/Bahnhof **nicht** platzieren) grün
- [x] Art-Dateien existieren (`REQUIRED_ART` / `GEO_ART` unverändert vom Dateinamen)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Campus Ohringen: drei getrennte Gebäude, Hof/Lücke dazwischen, kein zusammengeklebter Klotz
- [x] Historisches Schulhaus nördlich (Schulstrasse 9), 1985er Trakt östlich, Turnhalle südlich (Schulstrasse 7)
- [x] Füße nicht auf RoadKit-Asphalt (Schulstrasse / Schaffhauserstrasse / Rundstrasse); Spieler kann zwischen den Trakten durch
- [x] Collision blockiert wie andere Schulhäuser
- [x] Y-Sort: Spieler südlich der Fassade davor, nördlich dahinter (`m3_building_occlusion` analog)
- [x] Keine neuen Birch-/Rietacker-/Kiga-/Bahnhof-Props; Birch- und Rietacker-Cluster unverändert
- [x] Kein Kindergarten-Gebäude am Campus (Schulstrasse 5 = S07)
- [x] Keine weissen/schwarzen AI-Platten an Ohringen-Sprites (Alpha-Pipeline)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. Ohringen-OSM-Layout; smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s03-ohringen-campus.png` (player at `ohringen_world()`, zoom 0.5): Schulhaus a N Giebel, b O 1985er Flachdach, Turnhalle S Flachdach+PV; Hof dazwischen; Füße auf Gras, Asphalt nur am Rand (Schaffhauserstrasse SW, Rundstrasse O). Kein Kiga. a-PNG behalten.

## Art-Bedarf

- [x] Keine neuen Assets *(nur a: historisches Giebel-Schulhaus passt — Playtest bestätigt Giebel N)*
- [x] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur dieser Campus** — **b + Turnhalle** (Giebel/Flachdach wie S01 Birch)

**Warum Pflicht-Rewrite (wie S01 Birch, anders als S02 Rietacker):** OSM taggt kein `roof:shape`, aber Gemeinde Seuzach 2022 dokumentiert **Flachdächer des Schultrakts von 1985** und **Flachdach der Turnhalle** (PV-Anlage). Bestehende Art:

| Datei | Ist-Silhouette | OSM/Maps/Gemeinde |
|-------|----------------|-------------------|
| `landmark_schulhaus_ohringen_a.png` (835×798) | 2-geschossiges **Giebel**-Schulhaus, Rundbogenfenster, Portikus | Schulhaus 9: älteres benanntes Schulhaus, vom 1985er Flachdach-Trakt getrennt — **wiederverwenden** (kein Giebel/Flach-Konflikt) |
| `landmark_schulhaus_ohringen_b.png` (896×855) | kleines 1-geschossiges **Giebel**-Häuschen | Schultrakt **1985**, Flachdächer — **Rewrite** |
| `landmark_turnhalle_ohringen.png` (984×731) | Sporthalle mit **Giebel**, Eingang Schmalseite | Turnhalle Oberohringen: Flachdach + PV — **Rewrite** |

**Auftrag `comic-rettung-art` (Phase 2b):**

- Rewrite **nur** `landmark_schulhaus_ohringen_b.png` und `landmark_turnhalle_ohringen.png` (gleiche Pfade, kein Megablock)
- `landmark_schulhaus_ohringen_a.png` behalten
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View Schulstrasse 9 / 7 Oberohringen / Satellit Campus Ohringen (nicht Birch/Rietacker, nicht Kiga Schulstrasse 5)
- Stil C: Kontur, Cel; 1985er CH-Schultrakt (Hellputz, Bandfenster, Flachdach); Turnhalle als niedrige 12×24-Halle mit Flachdach (PV höchstens angedeutet, kein Technik-Lego), nicht Kirchen-/Schulhaus-Giebel
- Iso-¾ Default-Facing (kein extra Dir-Set); lange Seite der Turnhalle lesbar (OSM-Halle grob NNE–SSW)
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Seuzach-Housing-, Birch-, Rietacker- oder Kiga-Art
- **Kein `Sprite2D.rotation`**, auch wenn die Halle OSM-seitig nicht E–W liegt: Iso-¾ wie authored

Falls Playtest a als Flachdach-1960er-Kasten wertet (unwahrscheinlich, Gemeinde trennt 1985er Trakt): dann a nachziehen — Default ist behalten.

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Ohringen-Schul-Cluster; kein Kiga `52373683`, kein Pitch/Shed/Vordach, kein Bahnhof/Gleise/Badi/Bach/Wald/Housing; Birch-OSM unberührt; Rietacker-OSM unberührt
- [x] Drei Props auf den GPS der Tabelle (±80 wu) relativ zu unverändertem `ohringen_world()`
- [x] Relativlage maps-getreu (Schulhaus N, Trakt O, Turnhalle S); kein Megablock; eigene SW-Zellen (`x < -15000`, `y > 8000`)
- [x] Off RoadKit-Asphalt; Collision wie andere Schul-Props; keine Sprite-Rotation
- [x] Art: Ohringen-b und Turnhalle Flachdach-Silhouette Style C; a bestehendes Giebel-Schulhaus **oder** dokumentierter Playtest-Entscheid
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
