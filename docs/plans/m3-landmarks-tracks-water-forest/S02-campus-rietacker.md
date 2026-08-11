# Slice: S02 — Campus Rietacker (Maps-Ausrichtung)

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner / Phase-2 `feature-implementer`  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S02-campus-rietacker.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Der Primarschul-Campus **Rietacker** (nordwestlich der Kirche) steht als eigenes Gebäudecluster mit maps-getreuem Grundriss und Facing — nicht dieselben Offsets wie Birch.

## In diesem Schritt

- Cluster `schulhaus_rietacker_a` / `_b` + `turnhalle_rietacker` an `SeuzachGeo.rietacker_world()` maps-getreu (Gebäudeabstände und Ausrichtung aus Maps/OSM)
- Bestehende PNGs; neue Art nur wenn Silhouette/Ausrichtung falsch ist
- Mehrere Gebäude, kein Megablock

## Nicht (andere Feature-Schritte)

- Campus Birch / Ohringen
- Kindergärten, Bahnhof, Gleise, Badi, Bäche, Wälder
- Wohnhäuser

## Ziel

Spieler sieht nördlich der Kirche (Ohringerstrasse / Turnerstrasse; NW-Schulstandort gegenüber Birch Osten) **drei getrennte** Schul-Props: historisches Schulhaus, Nordost-Trakt und Sporthalle in der realen Relativlage (OSM-Gebäude-Zentroide). Der Campus ist ein Cluster, kein Megablock; Gebäude stehen **neben** RoadKit-Asphalt, mit derselben BuildingCollision wie die anderen Schul-Props.

## Scope

### In

- Nur Campus **Rietacker**: Nodes `schulhaus_rietacker_a`, `schulhaus_rietacker_b`, `turnhalle_rietacker`
- Anker bleibt `SeuzachGeo.rietacker_world()` = Nominatim-Zentroid der Schul**anlage** (OSM way `128882899` *Primarschule Rietacker*, `RIETACKER_LAT/LON` unverändert)
- Drei Gebäude-Zentroide aus OSM (nicht die Generic-Offsets `+(280,0)` / `+(-164.8, 226.4)` / `+(-86.1, -266.4)`, die Ohringen noch kopiert)
- Metas unverändert in der Semantik: `school_cluster=rietacker`, `district=rietacker`; a/b `landmark_id=schulhaus_rietacker`; Turnhalle `landmark_id=turnhalle_rietacker`, `poi_type=gym`
- Collision über bestehendes `_attach_building_collision` (kein Sonderpfad)
- Tests: Rietacker-OSM-Layout-Asserts; die drei Rietacker-Generic-Guards aus S01 **ersetzen**; **Ohringen-Generic-Offsets und Birch-OSM-Getter nicht anfassen**
- Art: Dateinamen unter `assets/art/` behalten; bestehende PNGs wiederverwenden (Silhouette passt zu OSM), siehe Art-Bedarf

### Nicht

- Campus Birch (`S01` erledigt — `birch_*_world()` / Birch-Tests bleiben)
- Campus Ohringen (`S03`) — inkl. copy-paste Generic-Offsets
- Kindergärten (`S04`–`S07`), Bahnhof (`S08`), Gleise (`S09`), Badi (`S10`), Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing
- Viertes OSM-Gebäude way `128910659` (`building=yes`, Annex am Nordost-Trakt) — Slice hat drei Props
- Hartplätze, Spielplatz, Pitches (OSM `leisure=pitch`)
- **Projekt Rietacker Neubau** (Gemeindeabstimmung 2026) — aktueller OSM-Bestand, nicht der künftige Grundriss
- RoadKit / `seuzach_roads.json` ändern (Ohringerstrasse / Turnerstrasse / Püntenstrasse reichen; Off-Road-Slack ist grün)
- `SCHOOL_SCALE` global ändern (gilt für alle Campi)
- `Sprite2D.rotation` an Gebäuden (Iso-¾ wie authored; Lage = Maps-Ausrichtung)
- Birch-S01-Art oder Ohringen-Art

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

Campus-Anker (unverändert):

| | |
|--|--|
| OSM | way `128882899` amenity=school *Primarschule Rietacker* |
| GPS | 47.5362833, 8.7271400 |
| Welt | `rietacker_world()` ≈ `(1441.5, -5843.5)` · Feld ≈ `(14, −58)` |
| Lage | ~310 m Nord / ~76 m Ost der Kirche; Gemeindeadresse Ohringerstrasse 16 |

Gebäude (Nominatim-Zentroide der building-ways, Stand OSM 2025):

| Prop | OSM / Adresse | GPS | Offset von `rietacker_world()` | Offset Meter | Felder |
|------|----------------|-----|----------------------------|--------------|--------|
| `schulhaus_rietacker_a` | way `128910664` *Schulhaus Rietacker*, Ohringerstr. **16** | 47.5360788, 8.7273791 | `Vector2(339.1, 429.5)` | +18,0 m Ost, +22,8 m Süd | +3,39 / +4,30 |
| `schulhaus_rietacker_b` | way `128910501` *Primarschule Rietacker* (Püntenstrasse) | 47.5365102, 8.7275595 | `Vector2(594.9, -476.6)` | +31,5 m Ost, **25,3 m Nord** | +5,95 / −4,77 |
| `turnhalle_rietacker` | way `128910661` *Sporthalle Rietacker*, Turnerstr. **2** | 47.5361323, 8.7262616 | `Vector2(-1245.6, 317.2)` | **66,0 m West**, +16,8 m Süd | −12,46 / +3,17 |

Gemeinde Seuzach: Schulhaus Rietacker **Baujahr 1933** (Sanierung/Neubau geplant, nicht dieser Slice). Mapping: **a** = benanntes 2-geschossiges Schulhaus an der Ohringerstrasse (Südost), **b** = 1-geschossiger Nordost-Trakt Richtung Püntenstrasse, **Turnhalle** = Sporthalle an der Turnerstrasse (Westen). Annex `128910659` = weggelassenes viertes Gebäude.

Relativlage (Kartenbild, N = kleineres Y):

```
        b Nordost-Trakt  (östlich+nördlich des Ankers, Püntenstrasse)
              |
              |                 a Schulhaus 16  (östlich+südlich, Ohringerstrasse)
              +-- Anker rietacker_world()
    Turnhalle 2 W                 Kirche ~310 m Süd
   (Turnerstrasse)
```

Paar-Abstände (Zentroide): a↔b ≈ 942 wu (50 m), a↔Turnhalle ≈ 1589 wu (84 m), b↔Turnhalle ≈ 2004 wu (106 m). Alle ≫ `MIN_CLUSTER_SEP` 160.

OSM-Grundrisse:

| Prop | Tags | Lange Achse (längste Kante) |
|------|------|-----------------------------|
| a | `building=school`, `building:levels=2`, `roof:shape=gabled` | ~33 m, grob **N–S** |
| b | `building=school`, `building:levels=1`, `roof:shape=gabled` | komplexer 20-Node-Grundriss, bbox ~42×55 m |
| Turnhalle | `building=sports_hall`, `leisure=sports_hall`, 1 Geschoss + UG | ~48 m, grob **E–W** |

Spiel-Sprites bei `SCHOOL_SCALE=0.22` sind ~10–16 m visuell — bestehende Konvention, hier nicht skalieren. a und b teilen in OSM zwei Nodes (angrenzend); im Spiel bleibt eine Hof-Lücke wegen Sprite-Maßstab — gewollt, kein Megablock.

Ist-Zustand (warum dieser Slice): `_place_school_clusters()` setzt Rietacker mit denselben Dummy-Offsets wie Ohringen (~15 m Dreieck um den Anker). Real sitzt die Sporthalle ~66 m **westlich** des Anlagen-Zentroids; der Nordost-Trakt ~32 m östlich / 25 m nördlich. S01-Tests **locken** die drei Rietacker-Props auf die Generic-Offsets — diese Guards müssen weg.

RoadKit: OSM-Lagen vs. `seuzach_roads.json` (Füße): a↔Ohringerstrasse ≈ 414 wu Slack vs. Need 136; Turnhalle↔Ohringerstrasse ≈ 681 / Turnerstrasse ≈ 697 wu. Off-Road-Asserts (`half_w + 14` AABB, `half_w + 14 + 50` feet) sollen ohne JSON-Änderung grün bleiben.

## Systeme

- `scripts/seuzach_geo.gd` — Rietacker-Gebäude-GPS → Welt (Getter, Anker unangetastet; Birch-Getter bleiben)
- `scripts/world_sandbox.gd` `_place_school_clusters()` — nur die drei Rietacker-`_add_prop`-Positionen
- `tests/m3_world_landmarks_test.gd` — Rietacker-Layout; 800 wu-Nähe anpassen soweit Rietacker sonst rot wird; Ohringen-Generic-Guards behalten
- `tests/m3_building_occlusion_test.gd` — Cluster-Spacing Rietacker bleibt gültig (≥ 160)
- `tests/m2_world_test.gd` — nicht regressieren
- Art `assets/art/landmark_schulhaus_rietacker_{a,b}.png`, `landmark_turnhalle_rietacker.png`

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Generic-Offsets, siehe Scope).

## Technische Schritte

1. **`SeuzachGeo`:** `RIETACKER_LAT/LON` und `rietacker_world()` nicht ändern. `BIRCH_*` / Birch-Getter nicht ändern. GPS-Konstanten + Getter nur für Rietacker-Gebäude: `rietacker_schulhaus_a_world()`, `rietacker_schulhaus_b_world()`, `rietacker_turnhalle_world()` via `gps_to_world` der Tabelle oben. Keine Ohringen-Gebäude-Getter in diesem Slice.
2. **`world_sandbox.gd`:** In `_place_school_clusters()` die drei Rietacker-Positionen auf diese Getter umstellen (Kommentar „Rietacker/Ohringen keep generic“ nur noch Ohringen). Ohringen weiter `+ Vector2(280,0)` / `+ Vector2(-164.8, 226.4)` / `+ Vector2(-86.1, -266.4)`. Birch bleibt auf OSM-Gettern. Keine `rotation` an den Sprites. `_add_prop` + `_attach_building_collision` unverändert.
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd`:
   - Die drei `_assert_generic_campus_offset(...)` für `schulhaus_rietacker_a` / `_b` / `turnhalle_rietacker` **entfernen** (S01-Lock). Ohringen-Analogie **behalten**.
   - Neue Asserts analog `_assert_birch_campus` (eigene Funktion oder klarer Block):
     - Nodes `schulhaus_rietacker_a` / `_b` / `turnhalle_rietacker` existieren
     - `RIETACKER_LAT/LON` unverändert `47.5362833` / `8.7271400`
     - Gebäude-GPS-Konstanten matchen die Tabelle; Getter-Offset vs. Yard `< 1 wu` zu `(339.1, 429.5)` / `(594.9, -476.6)` / `(-1245.6, 317.2)`
     - Position je ≤ **80 wu** (~4,2 m) zum passenden `SeuzachGeo`-Getter
     - Relativ: `gym.position.x < min(a.x, b.x) - 800` (Turnhalle westlich); `b.position.y < a.position.y - 400` (b nördlich von a); `a.position.x > gym.position.x` und `b.position.x > gym.position.x` (beide Schulhäuser östlich der Halle)
     - Cluster `rietacker` hat genau **3** Props (weiter ≥2 für ohringen; birch bleibt 3)
     - Alle Rietacker-Mitglieder: Distanz zu `rietacker_world()` **< 1600 wu** (~85 m; deckt Turnhalle bei ~1285 wu). Den Check `rietacker.distance_to(rietacker_world()) < 800` in `_assert_geo_quadrants` **nicht** auf das erste `schulhaus_rietacker` beschränken, falls Placement-Reihenfolge wechselt — auf **1600 wu** anheben (wie Birch 1400). Birch-1400 und Ohringen-800 unverändert.
     - Guard: Ohringen-a bleibt `ohringen_world() + (280, 0)` (Distanz < 1 wu); analog b/Turnhalle — beweist, dass dieser Slice Ohringen nicht „mitrepariert“
     - Birch-OSM-Asserts unangetastet; `birch.x > rietacker.x` bleibt wahr
     - Off-Road-Schleife für `school_cluster` bleibt; Rietacker soll ohne Road-JSON-Änderung grün sein
     - `rotation == 0`; `has_building_collision` an den drei Props
4. **Occlusion:** `m3_building_occlusion_test` Cluster `rietacker` min. Trennung ≥ 160 — Soll min. ~942 wu (a↔b). Sample-Player-südlich weiter Birch (nicht umbiegen).
5. **Art-Gate:** bestehende drei PNGs behalten, sofern Playtest Silhouette akzeptiert — siehe Art-Bedarf. Nur bei Fail: `comic-rettung-art` **nur Rietacker**. Nach PNG: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Rietacker-Cluster (Birch-Regression visuell nicht umbauen).

## Testplan

### Automatisiert

- [x] `schulhaus_rietacker_a` / `_b` / `turnhalle_rietacker` in `world_sandbox` vorhanden, Metas wie Scope
- [x] Positionen ≈ OSM-Getter, Toleranz 80 wu
- [x] Relativlage: Turnhalle westlich von a und b; b nördlich von a; beide Schulhäuser östlich der Halle
- [x] Rietacker-Cluster = 3 Gebäude; min. Abstand ≥ 160 wu (`m3_building_occlusion_test`)
- [x] Jedes Rietacker-Mitglied < 1600 wu von `rietacker_world()`; `rietacker_world()` selbst unverändert
- [x] Birch östlich von Rietacker (`a.x` bzw. Cluster vs. Rietacker) — Regression
- [x] Ohringen-Placement **bitgleich** zu den Generic-Offsets (Guard); Birch-OSM-Asserts weiterhin grün
- [x] `_assert_schools_off_roads` grün (Rietacker nicht auf Asphalt)
- [x] BuildingCollision an den drei Rietacker-Props (`has_building_collision`); `rotation` 0
- [x] `m2_world_test`, übrige Landmark-Asserts (Kigas/Bahnhof **nicht** platzieren) grün
- [x] Art-Dateien existieren (`REQUIRED_ART` / `GEO_ART` unverändert vom Dateinamen)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Campus Rietacker: drei getrennte Gebäude, Hof/Lücke dazwischen, kein zusammengeklebter Klotz
- [x] Turnhalle westlich (Turnerstrasse), Haupt-Schulhaus südöstlich (Ohringerstrasse 16), 1-geschossiger Trakt nordöstlich
- [x] Füße nicht auf RoadKit-Asphalt (Ohringerstrasse / Turnerstrasse / Püntenstrasse); Spieler kann zwischen den Trakten durch
- [x] Collision blockiert wie andere Schulhäuser
- [x] Y-Sort: Spieler südlich der Fassade davor, nördlich dahinter (`m3_building_occlusion` analog)
- [x] Keine neuen Ohringen-/Kiga-/Bahnhof-Props; Birch-Cluster unverändert
- [x] Keine weissen/schwarzen AI-Platten an Rietacker-Sprites (Alpha-Pipeline)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. Rietacker-OSM-Layout; smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s02-rietacker-campus.png` (player at `rietacker_world()`, zoom 0.4): Turnhalle W Giebel, Schulhaus a SE 2-geschossig Giebel, b NE 1-geschossig; Hof dazwischen; Füße auf Gras, Asphalt nur am Südrand. Bestehende PNGs akzeptiert.

## Art-Bedarf

- [x] Keine neuen Assets *(Default: OSM-Silhouette passt zu den drei bestehenden PNGs)*
- [ ] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur dieser Campus** — **nur wenn** Playtest die Silhouette als falsch wertet

**Warum kein Pflicht-Rewrite (anders als S01 Birch):** OSM taggt a/b als **Giebel**; a 2 Geschosse / b 1 Geschoss. Bestehende Art:

| Datei | Ist-Silhouette | OSM/Maps |
|-------|----------------|----------|
| `landmark_schulhaus_rietacker_a.png` (936×953) | 2-geschossiges Giebel-Schulhaus, Portikus, Ziegel | Schulhaus 16: `building:levels=2`, `roof:shape=gabled`, Baujahr 1933 — **wiederverwenden** |
| `landmark_schulhaus_rietacker_b.png` (836×803) | kleiner 1-geschossiger Giebel-Trakt | way `128910501`: 1 Geschoss, Giebel, größerer Grundriss — Dach/Geschoss ok; Maßstab = `SCHOOL_SCALE`-Konvention |
| `landmark_turnhalle_rietacker.png` (1384×939) | Sporthalle, Giebel, Schriftzug SPORTHALLE RIETACKER | `building=sports_hall`, 1 Geschoss, lange Achse E–W; kein `roof:shape` — Halle lesbar, **wiederverwenden** |

**Kein `Sprite2D.rotation`**, auch wenn die Turnhalle OSM-seitig E–W liegt: Iso-¾ wie authored.

**Falls Playtest Silhouette kippt** (Auftrag `comic-rettung-art`, Phase 2b, nur dann):

- Rewrite **nur** die beanstandete(n) Datei(en) unter denselben Pfaden, kein Megablock
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View Ohringerstrasse 16 / Turnerstrasse 2 / Satellit Campus Rietacker (nicht Birch/Ohringen)
- Stil C: Kontur, Cel; 1933er CH-Schulhaus (a), 1-geschossiger Schultrakt (b), Sporthalle
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Seuzach-Housing-, Ohringen- oder Birch-Art

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Rietacker-Cluster; kein Annex `128910659`, kein Kiga/Bahnhof/Gleise/Badi/Bach/Wald/Housing; Birch-OSM unberührt; Ohringen-Offsets unberührt
- [x] Drei Props auf OSM-Zentroiden (±80 wu) relativ zu unverändertem `rietacker_world()`
- [x] Relativlage maps-getreu (Turnhalle W, Schulhaus SE, Trakt NE); kein Megablock
- [x] Off RoadKit-Asphalt; Collision wie andere Schul-Props; keine Sprite-Rotation
- [x] Art: bestehende Rietacker-PNGs **oder** dokumentierter Playtest-Entscheid + Style-C-Rewrite nur dieses Campus
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
