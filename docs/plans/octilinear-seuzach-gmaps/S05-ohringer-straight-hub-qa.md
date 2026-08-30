# S05 — Ohringerstrasse begradigen + Hub-QA

**Status:** erledigt  
**Feature:** Ohringerstrasse octilinear nahezu gerade E–W; trifft Winterthurer-/Stations-Hub; Zoom-Verifikation gegen Swiss Raster.

## In

- Ohringerstrasse: wenige lange H/45°-Beine (kein Zickzack über Kirchhügel)
- Ohringerstrasse trifft denselben Hub wie Winterthurerstrasse (+ Stationsstrasse), Gap 0 wu
- Erwartete Haupt-Junktionen korrekt (Winter↔Stations, Winter↔Kirchgasse, Winter↔Breite, Schaffhauser↔Schul)
- Zoom-Overlay `docs/maps/seuzach_zoom_verify_*.jpg` für manuelle Swiss-Raster-Prüfung

## Nicht

- Sandbox auf octilinear JSON umschalten
- Neue Straßen digitalisieren außer Korrektur Ohringer/Hub

## Repro (vor Fix)

- Ohringer endet an Stations `(5200,-2800)`, Winter Hub `(5200,-3000)` → Gap 200 wu
- Ohringer teilt Vertices mit Kirchhügelstrasse (`-800,-1800` / `200,-2800`) — falscher Snap
- Mittleres Ohringer-Segment springt auf y≈−5600 dann zurück nach −1800

## Out

- Ohringer: `(-22800,-2400) → (5600,-2400) → (5600,-3000)` (H dann kurzes V)
- Triple-Hub O/W/S bei `(5600,-3000)`, alle REQUIRED_JUNCTIONS Gap 0
- Generator: `STRAIGHT_CORRIDORS`, Interior-Schutz, `force_required_junctions`, Validierung
- Zoom: `docs/maps/seuzach_zoom_verify_core.jpg`, `..._ohringer.jpg`
