# Slice: S02 — Strassen im Start-Viewport sichtbar

**Status:** Playtest / Erledigt  
**Typ:** Bugfix  
**Parent:** `docs/plans/m3-spawn-winterthurer-roads-visible/INDEX.md`  
**Datum:** 2026-08-11  
**Hängt ab von:** S01

Dieses File ist der **Schritt**. Phase 1 (`feature-planner`) füllt es zum vollständigen Plan; Phase 2–4 gelten nur für **diesen** Slice.

## Ziel

Vom Start auf der Winterthurerstrasse (WINT-KERN) ist das **Strassennetz im Viewport lesbar** — nicht ein Grasfeld mit einem dünnen Streifen und nicht „nur Grün“.

## Grenzen

- In:
  - Player-`Camera2D` in `scenes/world_sandbox.tscn` (Zoom / Smoothing)
  - Regression: Start-Viewport deckt Winterthurer **plus** mindestens zwei weitere benannte OSM-Strassen
- Nicht:
  - Spawn-Position (S01)
  - Housing, Ohringen, Forrenberg-Hub, neue Art, Half-Width-Klassen umbauen
- Raster: Abnahme in **WINT-KERN** vom S01-Spawn `(3861.9, −101.0)`

## Systeme

Kamera `world_sandbox`; RoadKit nur als Lage-Referenz.

## Repro & RCA

### Reproduktion

- [x] Repro bestätigt

| Feld | Inhalt |
|------|--------|
| Schritte | 1. World starten nach S01. 2. Screenshot Spawn, zoom 0.9, 1280×720. |
| Erwartet | Mehrere Strassen (Winterthurer + Nachbarachsen) im Bild. |
| Tatsächlich | Eine N–S-Asphaltbahn, Rest Vollgrün. Vor S01 (Forrenberg): A1 749 wu ausserhalb der 400 wu halben Viewporthöhe → **nur Grün**. |
| Umgebung | Godot 4.4.1, `world_sandbox`, Camera zoom 0.9 |
| Evidenz | `/tmp/spawn_view.png`: Center asphalt `(162,162,165)`, L/R grass `(61,204,90)`. Samples grass=12527 gray=1374. Nächste andere Strasse Kirchgasse 1361 wu; halbe Viewportbreite bei 0.9 ≈ 711 wu. JSON lädt; Spawn in Winterthurer-Polygon; Z-Order ok. |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | JSON fehlt; Gras überdeckt; Half-W zu dünn; Zoom zu nah; Spawn neben Fahrbahn. |
| Bestätigte Ursache | **Kamera zoom 0.9** zeigt nur ~79 m Höhe / ~1422 wu Breite. Nachbarstrassen (Kirchgasse 1361 wu) liegen ausserhalb. Vor S01 lag A1 komplett ausserhalb → nur Gras. |
| Nicht die Ursache | JSON (113 roads); Spawn (auf Polyline, S01); Half-W 72 wu (~130 px, Streifen ist da); Gras-z (Asphalt z=−40 über Gras). Zwei OSM-Ways triangulieren nicht, aber nicht Winterthurer und nicht im Start-Viewport. |
| Fix-Richtung | Zoom auf **0.22** (halbe Höhe ≈ 1636 wu): Kirchgasse (N), Seebühlstrasse (S), Eibenstrasse (O) im Bild. `position_smoothing` aus, damit Frame 0 am Spawn ist. |
| Risiken | Figur kleiner auf dem Bildschirm (~27 px). Keine Half-W-Änderung → Width-Tests unverändert. |

- [x] RCA dokumentiert

## Technische Schritte

1. `Camera2D` zoom `Vector2(0.22, 0.22)`; `position_smoothing_enabled = false`.
2. Tests: Zoom; Viewport um Spawn schneidet ≥3 benannte Strassen inkl. Winterthurerstrasse.
3. Probe-Scripts nicht committen.

## Testplan

### Automatisiert

- [x] Player-Kamera zoom ≈ 0.22
- [x] ≥3 `road_name` Polylines schneiden das Start-Viewport (1280×720 / zoom)
- [x] Winterthurerstrasse eine davon
- [x] Spawn unverändert S01
- [x] Suite grün

### Playtest / Smoke

- [x] Start zeigt Winterthurer + Nachbarstrassen, nicht Grün-Vollbild
- [x] Kein Housing, Spawn bleibt Feld 38,−2

## Art-Bedarf

- [x] Keine neuen Assets

## Akzeptanzkriterien

- [x] Grenzen eingehalten
- [x] Tests grün
- [x] Review ohne Critical/High
- [x] Playtest Pass
- [ ] Git für diesen Slice
