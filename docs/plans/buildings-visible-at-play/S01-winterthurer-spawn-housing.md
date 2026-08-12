# Plan: buildings-visible-at-play / Slice S01

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-12  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/buildings-visible-at-play/INDEX.md`  
**Slice-Datei:** `docs/plans/buildings-visible-at-play/S01-winterthurer-spawn-housing.md`  
**Hängt ab von:** —

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Ziel

Beim Start auf der Winterthurerstrasse (WINT-KERN, Spawn `Vector2(3861.9, -101.0)`, Zoom 0.9) sieht der Spieler **Wohngebäude** entlang der Straßenbänder — nicht nur Asphalt und Gras. Die Strassenkarte wirkt bewohnt im Start-Viewport (Haus–Strasse-Interaktion à la `c-iso-city-map`: Bebauung entlang der Bänder, Strassen als lesbare Korridore).

## Scope

### In

- Wohnprops aus bestehenden `assets/art/house_*.png` (`house_a`…`house_d`, `house_farm`, `house_mfh`, `house_flachdach`, `house_reihen`) entlang der **Winterthurerstrasse** im Spawn-Nahbereich platzieren
- Dieselbe Platzierungslogik auf **unmittelbare Nebenachsen**, sofern sie den Start-Viewport / eine knappe Spawn-Nachbarschaft schneiden (Datenstand: nur Winterthurerstrasse schneidet den Zoom-0.9-Frame; Kirchgasse ≈1361 wu → **S02**). Praktisch: beide Strassenseiten + sichtbares Winterthurer-Segment (N/S vom Spawn) als die zwei verwandten Inkremente
- Dedizierte Konstante **`HOUSE_SCALE`** (nicht `SCHOOL_SCALE` / `LANDMARK_SCALE` anfassen)
- Off-Road-Clearance wie Schulen (Füße/AABB vs. named-road Polylines)
- Variety: Varianten rotieren / mixen — nicht ein einziges Haus überall
- Spawn bleibt `SeuzachGeo.WINTERTHURER_SPAWN` / `default_world_spawn()`; bei Konflikt lieber Kandidat verwerfen als Spawn verschieben (Mini-Nudge nur als letzter Ausweg)
- Tests: bisheriges `house_n == 0` → Häuser erwartet; Spawn-Viewport schneidet ≥1 Haus

### Nicht

- Housing Richtung Kirche / Schneckenwiese-Korridor außerhalb des engeren Spawn-Frames (→ **S02**)
- Ganz Seuzach / alle Hauptachsen / Megablocks
- Neue Landmark-Art oder `SCHOOL_SCALE` / `LANDMARK_SCALE` global ändern; Landmarken verschieben
- Hub-Fassade / SOCAR-Spawn; neue PNGs
- Zoom ändern

## Systeme

| System | Rolle |
|--------|--------|
| `scripts/world_sandbox.gd` | `_place_landmarks()` → neues `_place_spawn_housing()`; `HOUSE_SCALE`; `_add_prop` + BuildingCollision + `compute_prop_z` |
| `%Ground` road markers | `road_name`, `road_points`, `half_w` (Winterthurer `class=main` → `ROAD_HW_MAIN` = 72) |
| `assets/art/house_*.png` | Bestehende Style-C-Häuser (REQUIRED_ART schon gelistet) |
| `tests/m3_world_landmarks_test.gd` | `house_n`-Asserts umdrehen; neue Spawn-Viewport- / Off-Road- / Scale-Asserts |
| `SeuzachGeo` | Spawn unverändert `(3861.9, -101.0)` |

## Repro & RCA (Sichtbarkeits-RCA — bestätigt; Typ bleibt Feature)

Die leere Spawn-Ansicht ist kein fehlendes Landmark-Asset und kein Scale-Bug der Schulen — es gibt schlicht **keine Wohnprops**. Fix ist Housing entlang der Strasse, nicht Landmark-Teleport/Scale-Rollback.

### Reproduktion

- [x] Repro bestätigt
- [ ] Nicht reproduzierbar

| Feld | Inhalt |
|------|--------|
| Schritte | 1. Spiel / `world_sandbox` starten (Default-Spawn Winterthurer). 2. Zoom 0.9, Viewport typ. 1280×720 → halbe Welt ≈ 711×400 wu. 3. Sicht prüfen; Suite `house_n`. |
| Erwartet | Bewohnte Strassenränder im Start-Frame (Häuser neben Asphalt/Gras). |
| Tatsächlich | Nur Strassen + Grün. Nächste Landmarken: Kiga Schneckenwiese ~4025 wu (~213 m), Rietacker ~5700 wu — außerhalb des Frames. Code: „No houses/hub facade.“; `house_n == 0`. |
| Umgebung | Godot headless/play; Branch aktuell; Scene `world_sandbox.tscn` |
| Evidenz | RCA Parent/User; `tests/m3_world_landmarks_test.gd` asserts `house_n == 0`; `_place_landmarks()` platziert nur Schulen/Kigas/Bahnhof/Badi/Wälder |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (A) Landmarken zu klein/weit. (B) Keine Wohnprops am Spawn-Korridor. (C) Spawn falsch. |
| Bestätigte Ursache | **(B)** — Placement setzt bewusst keine Häuser; Tests zementieren `house_n == 0`. Landmarken existieren, liegen aber außerhalb des Zoom-0.9-Viewports. |
| Nicht die Ursache | Fehlende Landmark-Art; globaler `SCHOOL_SCALE`/`LANDMARK_SCALE` zu klein; falscher Spawn (Winterthurer ist korrekt). |
| Fix-Richtung | `_place_spawn_housing()`: Polylines am Spawn-Korridor sampeln, senkrecht off-road offsetten, bestehende `house_*.png` mit `HOUSE_SCALE`, Meta `house_variant`, Collision via `_add_prop`. |
| Risiken | Off-Road-Asserts bei großem Footprint; Spawn blockiert; zu dichte „Megablocks“; Tests an 5 Stellen noch auf `house_n == 0`. |

- [x] RCA dokumentiert (Sichtbarkeit bestätigt)

## Technische Schritte

1. **`HOUSE_SCALE` in `world_sandbox.gd`**  
   Neue Konstante, empfohlen **`Vector2(0.38, 0.38)`** (Band 0.35–0.40). Begründung: ~1000px-Art → Höhe ≈ 340–380 wu ≈ **18–20 m** visuell — lesbar vs. Spieler (`SPRITE_SCALE` 0.085) und Road-`half_w`, ohne Schul-/Landmark-Größe (`SCHOOL_SCALE` 0.50 / `LANDMARK_SCALE` 0.55). `house_mfh`/`house_reihen` am selben Scale lesen sich als größere Dorfbauten (~25–28 m), ok für CH-Dorf. **Nicht** `SCHOOL_SCALE` wiederverwenden.

2. **`_place_spawn_housing()`** (oder gleichwertig) aus `_place_landmarks()` aufrufen (nach Schulen/Landmarks ok; vor oder nach Forest — Häuser unter `%Props`, Meta `house_variant`). Kommentar „No houses/…“ anpassen.

3. **Road-Quellen**  
   Aus `%Ground`-Markern Polylines mit `road_name` + `road_points` + `half_w` lesen. Primär **`Winterthurerstrasse`**. Zusätzlich nur Named Roads, deren Segment die Spawn-Nachbarschaft schneidet (Viewport-AABB ± kleinem Pad, z. B. half 711×400 + ~150–250 wu). Aktuell: nur Winterthurer — beide Seiten + N/S-Segment reichen für S01. Kirchgasse/Seebühl etc. **nicht** erzwingen (S02).

4. **Sampling & Offset**  
   - Entlang der Polyline im Spawn-Korridor in Abständen ~**200–320 wu** (~10–17 m) sampeln (Dorfzeile, keine geschlossene Megablock-Wand).  
   - Senkrechter Offset: `±(half_w + slack + footprint_half)`; Slack so, dass Schule-ähnliche Clearance greift (`need_feet ≈ half_w+64`, `need_aabb ≈ half_w+14` — Placement konservativ genug, dass Asserts grün werden).  
   - Beide Seiten der Strasse; leichte Längs-Jitter ok.  
   - Kandidaten verwerfen bei: zu nah an anderem Haus, zu nah an Landmark-Prop, zu nah am Spawn-Punkt (Spieler startet nicht in Collision), auf Asphalt.  
   - Keine `rotation` an Sprites (wie Schulen); optional `flip_h` für Abwechslung.

5. **Props**  
   `_add_prop(file, pos, HOUSE_SCALE, {"house_variant": "<id>", "district": "seuzach"}, node_name)` → Y-Sort `compute_prop_z`, BuildingCollision. Variantenzyklus über alle 8 Files.

6. **Dichte-Ziel**  
   Genug Häuser, dass Zoom 0.9 am Spawn **mehrere** Häuser im Frame zeigt (Richtwert: ≥4–8 im Korridor, Suite mindestens `house_n >= 1` und Viewport-Schnitt ≥1). CH-Dorf entlang Winterthurer — nicht Stadtblock.

7. **Tests (`m3_world_landmarks_test.gd`)**  
   Alle fünf `house_n == 0`-Stellen umstellen auf `house_n >= 1` (bzw. sinnvolle Untergrenze). Neu:  
   - `HOUSE_SCALE == Vector2(0.38, 0.38)` (oder gewählter Wert)  
   - `SCHOOL_SCALE` / `LANDMARK_SCALE` unverändert (0.50 / 0.55)  
   - Spawn unverändert `(3861.9, -101.0)`  
   - Mind. 1 House-Sprite schneidet Spawn-Viewport-Rect (center = spawn, half ≈ 711×400 bei Zoom 0.9)  
   - Houses off named roads (Reuse `_assert_sprite_off_named_roads` oder gleiche Formel)  
   - Landmark-Counts/Positionen unverändert  
   - Variety: ≥2 unterschiedliche `house_variant`-Werte

8. **Suite einmal grün**; kein neues Art-Pipeline (keine neuen PNGs).

## Testplan

### Automatisiert

- [ ] `house_n >= 1` (alle bisherigen Negativ-Asserts geflippt)
- [ ] Spawn-Viewport (Zoom 0.9, half ≈ 711×400 wu um `default_world_spawn()`) schneidet ≥1 Prop mit `house_variant`
- [ ] Houses sitzen off-road (feet/AABB vs. Winterthurer + andere named roads)
- [ ] `HOUSE_SCALE` wie gewählt; `SCHOOL_SCALE`/`LANDMARK_SCALE` unverändert
- [ ] Landmarken unverschoben; Spawn unverschoben
- [ ] ≥2 verschiedene `house_variant`
- [ ] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [ ] Default-Spawn Zoom 0.9: mehrere Häuser neben Asphalt/Gras lesbar, Strasse als Korridor
- [ ] Keine weiße/schwarze AI-Platten; Transparenz ok (bestehende Assets)
- [ ] Spieler startet nicht in BuildingCollision; Bewegung entlang Winterthurer möglich
- [ ] Keine Landmarken „zum Spawn gerutscht“

## Art-Bedarf

- [x] Keine neuen Assets  
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  

Bestehende Style-C-Häuser unter `assets/art/`. Layout-Regel aus `c-iso-city-map` (entlang Bändern) ist Placement-Code, keine neuen PNGs. **Kein** `comic-rettung-art` für diesen Slice.

## Akzeptanzkriterien

- [ ] Am Winterthurer-Spawn (Zoom 0.9) sind Wohngebäude entlang der Strasse im Frame sichtbar
- [ ] `HOUSE_SCALE` ≈ 0.35–0.40 (Ziel **0.38**); Schulen/Landmark-Scales und -Positionen unverändert
- [ ] Spawn bleibt `(3861.9, -101.0)`; Häuser off asphalt; Varianten gemischt
- [ ] Suite: `house_n > 0`, Viewport ∩ house ≥ 1; Regression Off-Road/Landmarks grün
- [ ] RCA (leerer Spawn = fehlende Wohnprops) adressiert — nicht durch Landmark-Move
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass

Playtest 2026-08-12: Pass — spawn zoom 0.9 shows 10 houses along Winterthurer (shot /tmp/s01-winterthurer-spawn-housing.png).
