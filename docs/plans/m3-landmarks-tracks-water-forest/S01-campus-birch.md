# Slice: S01 — Campus Birch (Maps-Ausrichtung)

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner / Phase-2 `feature-implementer`  
**Parent-INDEX:** `docs/plans/m3-landmarks-tracks-water-forest/INDEX.md`  
**Slice-Datei:** `docs/plans/m3-landmarks-tracks-water-forest/S01-campus-birch.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Der Primarschul-Campus **Birch** (Osten, nahe Bahnhof) steht als Gebäudecluster in der Welt: Schulhäuser und Turnhalle mit Grundriss und Ausrichtung wie Google Maps / OSM — nicht mehr die kopierten Generic-Offsets.

## In diesem Schritt

- Cluster `schulhaus_birch_a` / `_b` + `turnhalle_birch` maps-getreu platzieren (GPS `SeuzachGeo.birch_world()`, Offsets/Facing aus Maps)
- Bestehende PNGs `landmark_schulhaus_birch_a/b.png`, `landmark_turnhalle_birch.png`; neue Art nur wenn Silhouette/Ausrichtung zu Maps nicht passt
- Mehrere Gebäude, kein Megablock

## Nicht (andere Feature-Schritte)

- Campus Rietacker / Ohringen
- Kindergärten, Bahnhof, Gleise, Badi, Bäche, Wälder
- Wohnhäuser

## Ziel

Spieler sieht am Ostrand von Seuzach (Bachwiesenstrasse, westlich des Bahnhofs) **drei getrennte** Schul-Props: Haupt-Schulhaus, West-Trakt und Turnhalle in der realen Relativlage (OSM-Gebäude-Zentroide). Der Campus ist ein Cluster, kein Megablock; Gebäude stehen **neben** RoadKit-Asphalt, mit derselben BuildingCollision wie die anderen Schul-Props.

## Scope

### In

- Nur Campus **Birch**: Nodes `schulhaus_birch_a`, `schulhaus_birch_b`, `turnhalle_birch`
- Anker bleibt `SeuzachGeo.birch_world()` = Nominatim-Zentroid der Schul**anlage** (OSM way `128882898` *Primarschule Birch*, `BIRCH_LAT/LON` unverändert)
- Drei Gebäude-Zentroide aus OSM (nicht die Generic-Offsets `+(280,0)` / `+(-164.8, 226.4)` / `+(-86.1, -266.4)`, die auch Rietacker/Ohringen kopieren)
- Metas unverändert in der Semantik: `school_cluster=birch`, `district=birch`; a/b `landmark_id=schulhaus_birch`; Turnhalle `landmark_id=turnhalle_birch`, `poi_type=gym`
- Collision über bestehendes `_attach_building_collision` (kein Sonderpfad)
- Tests: Birch-Layout-Asserts; bestehendes Off-Road und Cluster-Spacing; **Rietacker/Ohringen-Offsets nicht anfassen**
- Art: Dateinamen unter `assets/art/` behalten; Style-C-Rewrite **nur Birch-Silhouette**, siehe Art-Bedarf

### Nicht

- Campus Rietacker (`S02`), Ohringen (`S03`) — inkl. deren copy-paste Offsets
- Kindergärten (`S04`–`S07`), Bahnhof (`S08`), Gleise (`S09`), Badi (`S10`), Bäche (`S11`), Wälder (`S12`)
- Wohnhäuser / Housing
- Viertes OSM-Gebäude Bachwiesenstrasse **2a** (way `131661988`, SE-Trakt) — Slice hat drei Props
- Lehrschwimmbecken, Hartplatz, 100 m-Bahn, Pitches (OSM `leisure=pitch`)
- RoadKit / `seuzach_roads.json` verlängern (Bachwiesenstrasse-Polyline reicht im JSON nicht bis ans Schulhaus — anderes Thema)
- `SCHOOL_SCALE` global ändern (gilt für alle Campi)
- `Sprite2D.rotation` an Gebäuden (Iso-¾ wie authored; Lage = Maps-Ausrichtung)

### Raster / GPS / Zuordnung

Koordinaten: `SeuzachGeo` (+X Ost, +Y Süd, Kirche = Ursprung, `FIELD_WU=100` = 5,3 m, `UNITS_PER_METER ≈ 18.868`).

Campus-Anker (unverändert):

| | |
|--|--|
| OSM | way `128882898` amenity=school *Primarschule Birch* |
| GPS | 47.5353419, 8.7362524 |
| Welt | `birch_world()` ≈ `(14363.7, -3866.2)` · Feld ≈ `(143, −39)` |

Gebäude (Nominatim-Zentroide der building-ways, Stand OSM 2024-09):

| Prop | OSM / Adresse | GPS | Offset von `birch_world()` | Offset Meter | Felder |
|------|----------------|-----|----------------------------|--------------|--------|
| `schulhaus_birch_a` | way `131661989` *Primarschulhaus Birch*, Bachwiesenstr. **2** | 47.5352696, 8.7368319 | `Vector2(821.8, 151.9)` | +43,6 m Ost, +8,0 m Süd | +8,22 / +1,52 |
| `schulhaus_birch_b` | way `131661983`, Bachwiesenstr. **2b** | 47.5351495, 8.7362716 | `Vector2(27.2, 404.1)` | +1,4 m Ost, +21,4 m Süd | +0,27 / +4,04 |
| `turnhalle_birch` | way `131661984` *Turnhalle*, Bachwiesenstr. **2c** | 47.5354751, 8.7362554 | `Vector2(4.3, -279.8)` | +0,2 m Ost, **14,8 m Nord** | +0,04 / −2,80 |

Gemeinde Seuzach: Trakt A, Trakt B, Spezialtrakt, Turnhallentrakt (Sanierung 2022–24). Mapping dieses Slices: **a** = benanntes Primarschulhaus (Osten, Richtung Bahnhof/Bachwiesenstrasse), **b** = West-Trakt 2b, **Turnhalle** = 2c Norden. 2a = weggelassener vierter Trakt.

Relativlage (Kartenbild, N = kleineres Y):

```
        Turnhalle 2c  (≈ gleiche X wie Anker, nördlich)
              |
    2b West   |           Primarschulhaus 2  (östlich, leicht südlich)
   (birch_b)  |                (birch_a)
              +-- Anker birch_world()
         Birchstrasse W/NW          Bachwiesenstrasse / Bahnhof Osten
```

Paar-Abstände (Zentroide): a↔b ≈ 834 wu (44 m), a↔Turnhalle ≈ 924 wu (49 m), b↔Turnhalle ≈ 684 wu (36 m). Alle ≫ `MIN_CLUSTER_SEP` 160.

OSM-Grundrisse: alle drei `building=school`, **Flachdach** (`building:roof=flat` bzw. Turnhalle `roof:shape=flat`). Baujahr Anlage/Turnhalle **1966**. Lange Achse grob: a leicht N–S, b E–W, Turnhalle N–S. Längste Kante ~22–40 m; Spiel-Sprites bei `SCHOOL_SCALE=0.22` sind ~11–16 m visuell — bestehende Konvention, hier nicht skalieren.

Ist-Bug (warum dieser Slice): `_place_school_clusters()` setzt Birch mit denselben Dummy-Offsets wie Rietacker/Ohringen (~15 m Dreieck um den Anker). Real spannt der Campus ~45–75 m zwischen den drei gewählten Gebäuden; `birch_a` sitzt ~44 m östlich des Anlagen-Zentroids.

RoadKit: OSM-Lagen liegen ≥ ~50 m von den nächsten Polylines (`Birchstrasse`, `Obstgartenstrasse`, `Stadlerstrasse`, `Bachwiesenstrasse`). Off-Road-Asserts (`half_w + 14` AABB, `half_w + 64` feet) sollen grün bleiben. Keine Strassen zeichnen/verlängern.

## Systeme

- `scripts/seuzach_geo.gd` — Birch-Gebäude-GPS → Welt (Getter, Anker unangetastet)
- `scripts/world_sandbox.gd` `_place_school_clusters()` — nur die drei Birch-`_add_prop`-Positionen
- `tests/m3_world_landmarks_test.gd` — Birch-Layout; 800 wu-Nähe nur anpassen soweit Birch sonst rot wird
- `tests/m3_building_occlusion_test.gd` — Cluster-Spacing Birch bleibt gültig
- `tests/m2_world_test.gd` — nicht regressieren
- Art `assets/art/landmark_schulhaus_birch_{a,b}.png`, `landmark_turnhalle_birch.png`

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature; Ist-Zustand: Generic-Offsets, siehe Scope).

## Technische Schritte

1. **`SeuzachGeo`:** `BIRCH_LAT/LON` und `birch_world()` nicht ändern. GPS-Konstanten + Getter nur für Birch-Gebäude, z. B. `birch_schulhaus_a_world()`, `birch_schulhaus_b_world()`, `birch_turnhalle_world()` via `gps_to_world` der Tabelle oben. Keine Rietacker-/Ohringen-Getter in diesem Slice.
2. **`world_sandbox.gd`:** In `_place_school_clusters()` die drei Birch-Positionen auf diese Getter umstellen. Rietacker/Ohringen weiter `+ Vector2(280,0)` / `+ Vector2(-164.8, 226.4)` / `+ Vector2(-86.1, -266.4)`. Keine `rotation` an den Sprites. `_add_prop` + Collision unverändert.
3. **Tests zuerst/mit:** In `tests/m3_world_landmarks_test.gd` Birch-spezifisch:
   - Nodes `schulhaus_birch_a` / `_b` / `turnhalle_birch` existieren
   - Position je ≤ **80 wu** (~4,2 m) zum passenden `SeuzachGeo`-Getter
   - Relativ: `a.position.x > b.position.x + 400`; `turnhalle.position.y < min(a.y, b.y) - 200` (Turnhalle nördlich)
   - Cluster `birch` hat genau **3** Props (weiter ≥2 für rietacker/ohringen)
   - Alle Birch-Cluster-Mitglieder: Distanz zu `birch_world()` **< 1400 wu** (~74 m; deckt a bei ~836 wu). Den bestehenden Check `birch.distance_to(birch_world()) < 800` **nicht** auf das erste `schulhaus_birch` (das ist a) anwenden — sonst Fail. Rietacker/Ohringen-800 wu unverändert.
   - Guard: Rietacker-a bleibt `rietacker_world() + (280, 0)` (Distanz < 1 wu); analog Ohringen — beweist, dass dieser Slice die anderen Campi nicht „mitrepariert“
   - Off-Road-Schleife für `school_cluster` bleibt; Birch soll ohne Road-JSON-Änderung grün sein
4. **Occlusion:** `m3_building_occlusion_test` Cluster `birch` min. Trennung ≥ 160 — Soll ~684 wu. Sample `schulhaus_birch` + Player-südlich weiter gültig.
5. **Art-Gate (Phase 2b, nur dieser Campus):** OSM/1966 Flachdach vs. bestehende Giebel-Sprites — siehe Art-Bedarf. Nach PNG: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`.
6. Suite `./scripts/run_tests.sh`. Playtest nur Birch-Cluster.

## Testplan

### Automatisiert

- [x] `schulhaus_birch_a` / `_b` / `turnhalle_birch` in `world_sandbox` vorhanden, Metas wie Scope
- [x] Positionen ≈ OSM-Getter, Toleranz 80 wu
- [x] Relativlage: a östlich von b; Turnhalle nördlich von a und b
- [x] Birch-Cluster = 3 Gebäude; min. Abstand ≥ 160 wu (`m3_building_occlusion_test`)
- [x] Jedes Birch-Mitglied < 1400 wu von `birch_world()`; `birch_world()` selbst unverändert
- [x] Birch östlich von Rietacker (`a.x` bzw. Cluster vs. Rietacker)
- [x] Rietacker- und Ohringen-Placement **bitgleich** zu den Generic-Offsets (Guard)
- [x] `_assert_schools_off_roads` grün (Birch nicht auf Asphalt)
- [x] BuildingCollision an den drei Birch-Props (`has_building_collision`)
- [x] `m2_world_test`, übrige Landmark-Asserts (Kigas/Bahnhof **nicht** platzieren) grün
- [x] Art-Dateien existieren (`REQUIRED_ART` / `GEO_ART` unverändert vom Dateinamen)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Campus Birch: drei getrennte Gebäude, Hof/Lücke dazwischen, kein zusammengeklebter Klotz
- [x] Turnhalle nördlich, Haupt-Schulhaus östlich (Richtung Bahnhof), 2b westlich/südlich des Ankers
- [x] Füße nicht auf RoadKit-Asphalt; Spieler kann zwischen den Trakten durch
- [x] Collision blockiert wie andere Schulhäuser
- [x] Y-Sort: Spieler südlich der Fassade davor, nördlich dahinter (`m3_building_occlusion` analog)
- [x] Keine neuen Rietacker-/Ohringen-/Kiga-/Bahnhof-Props
- [x] Keine weissen/schwarzen AI-Platten an Birch-Sprites (Alpha-Pipeline)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. Birch-OSM-Layout; smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s01-birch-campus.png` (player at `birch_world()`, zoom 0.5): Turnhalle N Flachdach, Schulhaus a O 3-geschossig Flachdach, 2b S/W; Hof dazwischen; Füße auf Gras, Asphalt nur NW am Rand.

## Art-Bedarf

- [ ] Keine neuen Assets *(nur wenn Silhouette nach Maps-Check reicht — hier nicht der Fall für a + Turnhalle)*
- [x] Neue Grafiken/Animationen → Subagent **`comic-rettung-art`** (Stil C) **nur dieser Campus**

**Warum:** OSM taggt alle drei Birch-Gebäude als Flachdach; Anlage/Turnhalle 1966 (sportstaetten.ch / Gemeinde). Bestehende Art:

| Datei | Ist-Silhouette | OSM/Maps |
|-------|----------------|----------|
| `landmark_schulhaus_birch_a.png` (930×929) | historisches **Ziegel-Giebel**-Schulhaus, Portikus | Primarschulhaus 2: `building:roof=flat`, modernes 1960er-Schulhaus |
| `landmark_schulhaus_birch_b.png` (885×584) | L-Trakt, **Flachdach**, gestaffelt | 2b: Flachdach, komplexer Grundriss E–W — **wiederverwenden** |
| `landmark_turnhalle_birch.png` (1400×992) | Halle mit **Giebel**, Eingang Schmalseite | Turnhalle 2c: `roof:shape=flat`, längliche N–S-Halle |

**Auftrag `comic-rettung-art` (Phase 2b):**

- Rewrite **nur** `landmark_schulhaus_birch_a.png` und `landmark_turnhalle_birch.png` (gleiche Pfade, kein Megablock)
- `landmark_schulhaus_birch_b.png` behalten
- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View Bachwiesenstrasse 2 / Satellit Campus Birch (nicht Rietacker/Ohringen)
- Stil C: Kontur, Cel; 1960er CH-Schule (Hellputz, Bandfenster, Flachdach); Turnhalle als niedrige Sporthalle mit Flachdach, nicht Kirchen-/Schulhaus-Giebel
- Iso-¾ Default-Facing (kein extra Dir-Set); lange Seite der Turnhalle lesbar als N–S-Halle
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün); Walk-Pad entfällt
- Keine Seuzach-Housing-, Ohringen- oder Rietacker-Art

## Akzeptanzkriterien

- [x] Grenzen eingehalten: nur Birch-Cluster; kein 2a, kein Kiga/Bahnhof/Gleise/Badi/Bach/Wald/Housing; Rietacker/Ohringen-Offsets unberührt
- [x] Drei Props auf OSM-Zentroiden (±80 wu) relativ zu unverändertem `birch_world()`
- [x] Relativlage maps-getreu (Turnhalle N, Haupt-Schulhaus O, 2b W/S); kein Megablock
- [x] Off RoadKit-Asphalt; Collision wie andere Schul-Props
- [x] Art: Birch-a und Turnhalle Flachdach-Silhouette Style C **oder** dokumentierter Playtest-Entscheid, dass bestehende PNGs reichen (Gate in Art-Bedarf); Dateinamen unverändert
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
