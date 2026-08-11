# Slice: S02 — Spawn-Kamera wieder Zoom 0.9

**Parent:** `docs/plans/iso-map-interaction-not-dimensions/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Feature

Am Spawn auf der Winterthurerstrasse sieht die Welt wieder in **lesbarer Nähe** aus (Kamera `Vector2(0.9, 0.9)`), nicht als Stadtplan-Übersicht mit winziger Figur (~19 px bei Zoom 0.22). Die Startstrasse bleibt erkennbar; kein Iso-Karten-Überblick.

## In diesem Schritt

- `scenes/world_sandbox.tscn`: Camera2D-Zoom `0.22` → `0.9`
- Tests (`tests/m3_road_debug_test.gd`): Zoom == 0.9; Abnahme = Spawnstrasse lesbar, nicht ≥3 Strassen im Stadtplan-Viewport
- Spawn bleibt Winterthurerstrasse; Strassen existieren weiter

## Nicht (andere Feature-Schritte)

- Docs/Agent-Korrektur Iso-Karte (`S01`)
- Landmarken-Art neu, Feldmaß 5,3 m, Häuser, SCALE-Konstanten
