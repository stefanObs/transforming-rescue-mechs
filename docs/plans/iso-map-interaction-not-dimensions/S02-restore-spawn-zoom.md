# Plan: iso-map-interaction-not-dimensions / Slice S02

**Status:** Playtest / Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/iso-map-interaction-not-dimensions/INDEX.md`  
**Slice-Datei:** `docs/plans/iso-map-interaction-not-dimensions/S02-restore-spawn-zoom.md`  
**Hängt ab von:** S01 (erledigt, Tag `v0.27.0`)

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Ziel

Am Spawn auf der Winterthurerstrasse sieht die Welt wieder in **lesbarer Nähe**: Player-`Camera2D` `zoom = Vector2(0.9, 0.9)` (Stand vor v0.24.2). Einheitlicher Kamerazoom ist, wie der Spieler relative Größe von Figur, Strasse und Landmarken wahrnimmt. Kein Stadtplan-Überblick mit winziger Figur (~19 px bei Zoom 0.22). Die Startstrasse bleibt im Viewport erkennbar; Nachbarachsen müssen **nicht** mit ins Bild.

## Scope

### In

- `scenes/world_sandbox.tscn`: Node `Player/Camera2D`, Property `zoom` von `Vector2(0.22, 0.22)` auf `Vector2(0.9, 0.9)`
- `tests/m3_road_debug_test.gd` → `_assert_spawn_viewport_shows_streets`: Abnahme an **lesbarer Nähe** (Zoom 0.9 + Winterthurerstrasse im 1280×720-Spawn-Viewport), nicht an Stadtplan-Übersicht
- `position_smoothing_enabled` bleibt **false** (wie heute; nicht den Pre-v0.24.2-Wert `true` zurückholen)
- Spawn bleibt Winterthurer-Vertex `Vector2(3861.9, -101.0)` / Feld 38,−2

### Nicht

- `PROP_SCALE` / `SCHOOL_SCALE` / `LANDMARK_SCALE` / `SPRITE_SCALE` / `TRANSFORM_SPRITE_SCALE` / `HUB_SCALE` — **Achtung:** `PROP_SCALE` und `SCHOOL_SCALE` sind ebenfalls `Vector2(0.22, 0.22)`; das ist **Sprite-Maß**, nicht Kamera. Nicht anfassen.
- `FIELD_METERS` 5.3 / `FIELD_WU` / `UNITS_PER_METER` / RoadKit-`half_w`-Klassen
- Landmarken-/Dach-PNGs, Art-Pipeline, Häuser setzen, Housing
- Subagent `comic-rettung-art` (keine Assets)
- `scenes/hub_station.tscn` Kamera (`zoom` 0.95, Smoothing an)
- S01-Docs (Iso-Karte = Haus–Strasse, nicht Masse) — bereits `v0.27.0`
- Spawn-Position, Road-JSON, F1-Debug, Gras-/Asphalt-Farben
- Historisches Slice-File `docs/plans/m3-spawn-winterthurer-roads-visible/S02-streets-visible-at-spawn.md` umschreiben (erledigt; nur Kontext)

## Systeme

Player-Kamera in `world_sandbox` (Scene-Property). Regression in `m3_road_debug_test.gd` (Suite: `./scripts/run_tests.sh`). Kein `world_sandbox.gd`-SCALE, kein Geo-Feldmaß.

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature: Pre-Iso-Map-Kamera wiederherstellen, kein Runtime-Bugfix).

Kurz zur Herkunft: Zoom **0.22** kam mit **v0.24.2** (`a0aef86`, Plan `m3-spawn-winterthurer-roads-visible/S02`): bei 0.9 passten Nachbarstrassen (Kirchgasse ~1361 wu) nicht in den 1280×720-Viewport (halbe Breite ≈ 711 wu), also Stadtplan-Übersicht + Assert ≥3 benannte Strassen. Das war die **Dimensions-Fehldeutung** (Kamera als Übersichtskarte). `c-iso-city-map.png` gilt nur für Haus–Strasse-Interaktion (S01). S02 stellt den Zoom **0.9** wieder her und streicht die Übersicht-Abnahme.

## Technische Schritte

1. **`scenes/world_sandbox.tscn`** — unter `[node name="Camera2D" type="Camera2D" parent="Player"]`:
   - `zoom = Vector2(0.22, 0.22)` → `zoom = Vector2(0.9, 0.9)`
   - Keine `position_smoothing_enabled`-Zeile ergänzen (Default = aus; Test fordert `false`)
   - `Player.position` unverändert `Vector2(3861.9, -101.0)`
2. **`tests/m3_road_debug_test.gd`** — nur `_assert_spawn_viewport_shows_streets` (heute Zeilen ~204–223):
   - **Entfernen:** `cam.zoom.x <= 0.24 and cam.zoom.y <= 0.24` (Übersicht-Schwelle)
   - **Ersetzen:** `is_equal_approx(..., 0.22)` → `is_equal_approx(..., 0.9)` für x und y; Meldung `spawn camera zoom == (0.9, 0.9)`
   - **Behalten:** Camera2D existiert; `not cam.position_smoothing_enabled`; `_spawn_viewport_rect` + `_polyline_hits_rect`; `names.has("Winterthurerstrasse")`
   - **Entfernen:** `names.size() >= 3` (Übersicht-Abnahme; bei 0.9 liegen Kirchgasse/Seebühlstrasse typisch außerhalb)
   - Rest der Datei unverändert (Spawn-Vertex, Feld 38,−2, F1, A1 existiert weltweit, …)
3. Keine Änderungen an `scripts/world_sandbox.gd`, `scripts/player.gd`, `scripts/seuzach_geo.gd`, `scripts/road_kit.gd`, `assets/art/`, Docs/Agent-Prompts.
4. Suite: `./scripts/run_tests.sh` (enthält `tests/m3_road_debug_test.gd`).

## Testplan

### Automatisiert

- [x] `m3_road_debug_test.gd`: Player-Kamera `zoom == (0.9, 0.9)` (`is_equal_approx`)
- [x] Dieselbe Funktion: **kein** Assert `zoom <= 0.24`, **kein** Assert `names.size() >= 3`
- [x] Start-Viewport (1280×720 / Zoom 0.9 um Spawn) schneidet Winterthurerstrasse-Polyline
- [x] `position_smoothing_enabled == false`
- [x] Spawn unverändert `Vector2(3861.9, -101.0)` / `winterthurer_spawn()` / Feld 38,−2
- [x] `git diff` ohne Treffer in SCALE-Konstanten, `FIELD_METERS`/`FIELD_WU`, `half_w`, `assets/art/`
- [x] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Spawn: Figur und Winterthurer-Asphaltband **lesbar nah** (kein Stadtplan; Figur nicht ~19 px)
- [x] Relative Größe Figur vs. Strasse vs. ggf. sichtbare Props wirkt wie vor der Iso-Map-Zoom-Änderung
- [x] Startstrasse erkennbar; **kein** Fail, wenn nur eine benannte Achse im Bild ist
- [x] Kamera klebt am Spieler (kein Smoothing-Lag Frame 0)

Playtest 2026-08-11: `verify_art_alpha` 181 PNGs; `./scripts/run_tests.sh` green inkl. `m3_road_debug_test` (zoom `(0.9, 0.9)`, smoothing aus, Winterthurerstrasse im 1280×720-Spawn-Viewport, Spawn `(3861.9, -101.0)` / Feld 38,−2); smoke `godot --path . --quit-after 5` exit 0. Shot `/tmp/s02-spawn-zoom-0.9.png`: Bolt ~73 px auf Winterthurer-Asphaltband, keine Nachbarachsen. Compare `/tmp/s02-spawn-zoom-0.22-compare.png`: Figur ~17 px, mehrere Strassen im Frame (Übersicht). `git diff` nur tscn-Zoom + Test + Slice-Docs.

## Art-Bedarf

- [x] Keine neuen Assets
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  
  Details: **Nicht** beauftragen. Keine PNGs, kein Alpha/Pad, kein `GenerateImage`.

## Akzeptanzkriterien

- [x] `world_sandbox` Player-Camera2D: `zoom = Vector2(0.9, 0.9)`
- [x] Tests: Zoom 0.9; Winterthurerstrasse im Spawn-Viewport; keine ≥3-Strassen-Pflicht; Smoothing aus
- [x] Spawn `Vector2(3861.9, -101.0)` unverändert
- [x] Keine SCALE-/Feldmaß-/Half-Width-/Art-/Housing-Diffs
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass (lesbare Nähe, nicht Übersicht)
