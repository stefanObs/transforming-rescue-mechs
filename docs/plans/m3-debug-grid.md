# Plan: m3-debug-grid

**Status:** Erledigt (Playtest Pass)  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/m3-road-debug-names.md`](m3-road-debug-names.md)  
**Art:** keine neuen Assets

---

## Ziel

**F1** zeigt neben den Strassennamen ein **Koordinatenraster**, damit Positionen als **Felder** angegeben werden können (z. B. „Feld 7,−5“ statt Rohpixel).

---

## Scope

### In

- Dieselbe F1-Toggle wie Strassennamen (an = Namen + Raster, aus = beides weg)
- Achsenkreuz bei Kirche `(0,0)`; +X Ost, +Y Süd
- Zellen 100×100 Welt-Einheiten; Index `floor(pos / 100)`
- Feld-Labels in den Zellen; Statuszeile mit aktuellem Spieler-Feld
- Zeichnen per `_draw()` (kein Line2D auf `%Ground`)

### Nicht

- Eigenes F2, persistentes Flag, Raster im Hub, Art, Gameplay-Snap

---

## Systeme

World-Debug-Overlay, neuer `scripts/debug_grid.gd`

---

## Technische Schritte

1. `DebugGrid`: `_draw` Linien + Zelltexte; `world_to_cell` / `cell_center`.
2. Overlay baut Grid mit den Namen; Status `Raster 100 | Feld ix,iy`.
3. Tests: Mapping, Default aus, F1 an/aus, Zelle 100, Kirche in Bounds, kein Ground-Line2D.

---

## Testplan

### Automatisiert

- [x] `(50,50)→(0,0)`, `(-1,-1)→(−1,−1)`, `(100,0)→(1,0)`
- [x] Debug aus: kein `road_debug_grid`
- [x] Debug an: Grid-Node, `cell_size=100`, Bounds enthalten `(0,0)`
- [x] Spawn-Feld zu `(490,750)` passt
- [x] Toggle aus entfernt Grid
- [x] `%Ground` bleibt ohne Line2D

### Playtest / Smoke

- [x] F1: Raster + Namen sichtbar, Felder ablesbar
- [x] F1 aus blendet Raster
- [x] Scene startet ohne Error

---

## Art-Bedarf

- [x] Keine neuen Assets

---

## Akzeptanzkriterien

- [x] F1 schaltet Raster mit Feldkoordinaten
- [x] Angaben über Feld-Indizes sind eindeutig (100er-Raster, Ursprung Kirche)
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass

---

## Playtest (2026-08-11)

Pass. Art alpha 181 PNGs; suite green. Default kein Raster; F1 → 100er-Gitter um Kirche `(0,0)`, Status `Raster 100 | Feld 4,7` am Spawn; `_draw` ohne Line2D; zweites F1 räumt Namen und Raster. Smoke `godot --path . --quit-after 5` exit 0.
