# Plan: m3-field-scale-maps

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** F1-Raster · Google Maps / OSM Seuzach  
**Art:** keine neuen Assets

---

## Ziel

Seuzach-Dorf (ohne Ohringen-Messung, Ohringen bleibt im Spiel) auf die gemessene Feldgrösse bringen und das **Strassennetz an Maps** ausrichten.

- 1 Feld = **5,3 m × 5,3 m** = 100 Welt-Einheiten (F1-Raster bleibt)
- Dorf N–S ≈ **317 Felder** (47.528351 → 47.543536)
- Dorf E–W ≈ **291 Felder** (8.725788 → 8.746202)
- Ursprung Kirche; +X Ost, +Y Süd; Ohringen SW bei gleicher Skala

---

## Scope

### In

- Geo-Projektion `seuzach_geo.gd` (Kirche, 100 wu / 5,3 m)
- OSM/Maps-Polylinien für benannte Achsen (kein Footway)
- Schulen an Nominatim-Lage, neben den Bändern
- Hub/Spawn Forrenberg (SOCAR) in neuer Skala
- Gras/Sky/F1-Bounds; z-Index an grosse Y-Werte anpassen (`floor(y/20)`)
- Tests: Feld-Ausdehnung, Bahnhof Osten, Ohringen SW

### Nicht

- Wohnbebauung, neue Art, Footways

---

## Technische Schritte

1. `seuzach_geo.gd` + `data/seuzach_roads.json` aus OSM-Geom.
2. `world_sandbox` lädt JSON; Schulen/Hub per GPS.
3. Debug-Grid: Linien jedes Feld, Labels nur 10er-Felder.
4. Tests + Review + Playtest.

---

## Testplan

### Automatisiert

- [x] N–S Felder ≈ 317 (±10), E–W ≈ 291 (±10)
- [x] Bahnhof x>10000, Ohringen x<−5000 y>2000
- [x] Named roads inkl. A1 / Winterthurer / Stations
- [x] Schulen off-road; Hub-Spawn Forrenberg
- [x] actor_z in 0…4096 für Extreme-Y
- [x] Suite grün

### Playtest

- [x] Scene startet; F1-Raster deckt das Dorf
- [x] Strassen folgen Maps-Silhouette

---

## Art-Bedarf

- [x] Keine neuen Assets

---

## Akzeptanzkriterien

- [x] Dorfmasse stimmen zu den Messungen
- [x] Strassenlayout Maps/OSM
- [x] Ohringen an gleicher Skala SW
- [x] Tests, Review, Playtest Pass
