# Plan: player-faster-movement / Slice S01

**Status:** Playtest / Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/player-faster-movement/INDEX.md`  
**Slice-Datei:** `docs/plans/player-faster-movement/S01-raise-player-speeds.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Ziel

Die Spielfigur bewegt sich spürbar schneller über die große Seuzach-Karte — Roboter, normales Fahrzeug und Rush-Fahrzeug in **einer** Abstimmung. Heute: Roboter 140 wu/s, Fahrzeug 260, Rush 360. Bei Kamera-Zoom 0.9 und Viewport ~1422×800 wu braucht der Roboter ~5,7 s für die Bildschirmhöhe; Seuzach N–S ~31700 wu ≈ 4 min zu Fuß. Kinder-Rettungsspiel: Fortbewegung soll nicht mehr zäh wirken, aber steuerbar bleiben. Relationen bleiben: Fahrzeug klar schneller als Roboter; Rush (Charakter 3) das schnellste Fahrzeug.

Gewählte Werte (~2,5×, Relationen unverändert):

| Konstante | Heute | Neu |
|-----------|-------|-----|
| `SPEED_ROBOT` | 140.0 | **350.0** |
| `SPEED_VEHICLE` | 260.0 | **650.0** |
| `SPEED_VEHICLE_RUSH` | 360.0 | **900.0** |
| `WALK_FPS` | 9.0 | **14.0** |

Relationen nachher: Fahrzeug/Roboter = 650/350 ≈ 1,86 (wie 260/140); Rush/Fahrzeug = 900/650 ≈ 1,38 (wie 360/260); Rush > Bolt/Marina-Fahrzeug. `WALK_FPS` 9→14 ist ein **moderater** Mitzieher in diesem Slice, damit der 4-Frame-Walk nicht stark moonwalkt. Kein neues Walk-Art, keine PNG-Regenerierung. Volle Schrittraten-Anpassung (~22,5 FPS bei 2,5×) wäre zu hektisch und ist Nicht-Scope.

## Scope

### In

- `scripts/player.gd`: die vier Konstanten oben (nur Zahlen, gleiche Namen)
- `_physics_process` / `_vehicle_speed()` / `set_moving_for_test` bleiben logisch unverändert (sie lesen die Konstanten bereits)
- `WALK_FPS` nur als Zahl 9.0 → 14.0; `_load_walk_frames` setzt `set_animation_speed(anim, WALK_FPS)` weiter so
- Tests: `tests/m2_test.gd` erweitern (Rush-Assert 360 → 900 plus die drei Speeds und Rush > Bolt/Marina). Kein neues Test-Framework, keine neue Testdatei, kein `run_tests.sh`-Eintrag

### Nicht

- Kamera-Zoom (Spawn 0.9 bleibt), `position_smoothing`, Viewport
- Feldmaß / Karten-Scale (`FIELD_METERS` / `FIELD_WU` / `UNITS_PER_METER` / RoadKit-`half_w`)
- Walk-PNGs, `pad_walk_frames.py`, Art-Pipeline, Subagent `comic-rettung-art`
- `WALK_FPS` als eigenes Feature oder als 2,5×-Match (~22,5)
- Häuser, Housing, Landmarken, Map-Layout, RoadKit-Geometrie
- `SPRITE_SCALE` / `TRANSFORM_SPRITE_SCALE` / Lean / Facing / Transform-Lockout
- Neue Player-API, Input-Map, Character-IDs
- INDEX-Status ändern (S01 bleibt `offen` bis Phase-4-Pass + Git)

## Systeme

Spieler-Lokomotion in `scripts/player.gd` (`CharacterBody2D`): `_physics_process` wählt `SPEED_ROBOT` vs `_vehicle_speed()` (Rush → `SPEED_VEHICLE_RUSH`, sonst `SPEED_VEHICLE`). Walk-Cycle-Tempo über `WALK_FPS` in `_load_walk_frames`. Regression in bestehendem `tests/m2_test.gd` (Suite: `./scripts/run_tests.sh`). Keine Scene-Änderungen, keine Welt-/Kamera-Dateien.

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature: Tempo-Tuning, kein Runtime-Bugfix).

Kurz zur Herkunft: User-Intent „Figur schneller; aktuell sehr langsam.“ Die Ist-Werte (140/260/360) stammen aus der M2-Lokomotion und passen nicht zur Seuzach-Feldgröße bei Zoom 0.9.

## Technische Schritte

1. **`scripts/player.gd`** — nur die Konstanten-Literale (Zeilen ~10–16):
   - `SPEED_ROBOT := 140.0` → `350.0`
   - `SPEED_VEHICLE := 260.0` → `650.0`
   - `SPEED_VEHICLE_RUSH := 360.0` → `900.0`
   - `WALK_FPS := 9.0` → `14.0`
   - `_vehicle_speed()`, `_physics_process`-Speed-Wahl, `set_moving_for_test` (nutzt `SPEED_ROBOT` als Dummy-Velocity), `_load_walk_frames` **nicht** umbauen.
2. **`tests/m2_test.gd`** — denselben bereits instantiierten Player nutzen (kein neues Framework):
   - Bestehenden Assert nach `set_character("rush")` anpassen: `_vehicle_speed` **360.0 → 900.0** (Meldung z. B. `"rush vehicle speed bonus"` beibehalten oder auf `"rush vehicle speed == 900"` schärfen).
   - Ergänzen (gleiche `_run`-Funktion, nach dem Player-Instantiate):
     - `SPEED_ROBOT == 350.0` via Instanz-Property / `get("SPEED_ROBOT")` (`is_equal_approx`)
     - `SPEED_VEHICLE == 650.0`
     - `SPEED_VEHICLE_RUSH == 900.0`
     - `set_character("bolt")` → `_vehicle_speed() == 650.0`
     - `set_character("marina")` → `_vehicle_speed() == 650.0`
     - `set_character("rush")` → `_vehicle_speed() == 900.0`
     - Rush-Fahrzeug **>** Bolt- und Marina-Fahrzeug (z. B. `rush_v > bolt_v` und `rush_v > marina_v`)
   - Optional, gleicher Test: `WALK_FPS == 14.0` — kein Muss, verhindert Drift.
   - Keine Physik-Simulation der Bildschirmquerung nötig; Konstanten + `_vehicle_speed` reichen.
3. **Nicht anfassen:** `scenes/world_sandbox.tscn` (Kamera), `scripts/world_sandbox.gd`, `scripts/seuzach_geo.gd`, `scripts/road_kit.gd`, `assets/art/**`, `m2_walk_test.gd` (kein FPS-Assert heute), `run_tests.sh`.
4. Suite: `./scripts/run_tests.sh` (enthält `tests/m2_test.gd`). `m2_walk_test` muss ohne Art-Änderungen grün bleiben.

## Testplan

### Automatisiert

- [x] `m2_test.gd`: `SPEED_ROBOT == 350.0`, `SPEED_VEHICLE == 650.0`, `SPEED_VEHICLE_RUSH == 900.0`
- [x] `m2_test.gd`: Bolt und Marina `_vehicle_speed == 650.0`; Rush `_vehicle_speed == 900.0` (alter 360-Assert ersetzt)
- [x] `m2_test.gd`: Rush-Fahrzeug-Speed > Bolt- und Marina-Fahrzeug-Speed
- [x] Kein Assert mehr auf `360.0` als Rush-Speed
- [x] `git diff` ohne Treffer in Kamera-Zoom, `FIELD_*`, `assets/art/`, Housing/Landmarken
- [x] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Roboter: spürbar schneller als 140 wu/s (Bildschirmhöhe grob ~2,3 s statt ~5,7 s bei Zoom 0.9)
- [x] Fahrzeug klar schneller als Roboter; Rush klar das schnellste Fahrzeug
- [x] Tempo steuerbar (Kinder-Rettung: nicht unspielbar/unlenkbar)
- [x] Walk-Cycle ohne starken Moonwalk (FPS 14, bestehende 4 Frames; keine neuen PNGs)
- [x] Kamera-Zoom 0.9 unverändert; Weltmaß unverändert

## Art-Bedarf

- [x] Keine neuen Assets
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  
  Details: **Nicht** beauftragen. Keine Walk-PNGs, kein `GenerateImage`, kein Alpha/Pad. `WALK_FPS` ist nur eine Zahl in `player.gd`.

## Akzeptanzkriterien

- [x] `SPEED_ROBOT = 350.0`, `SPEED_VEHICLE = 650.0`, `SPEED_VEHICLE_RUSH = 900.0`, `WALK_FPS = 14.0` in `scripts/player.gd`
- [x] Relationen: Fahrzeug > Roboter, Rush > Bolt/Marina-Fahrzeug; `_vehicle_speed()`-Logik unverändert
- [x] `m2_test.gd` prüft die drei Speeds und Rush-Bonus (900, nicht 360)
- [x] Keine Kamera-, Feldmaß-, Art-PNG-, Housing-Änderungen
- [x] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [x] Playtest Pass (spürbar schneller, Relationen lesbar, Walk akzeptabel)
