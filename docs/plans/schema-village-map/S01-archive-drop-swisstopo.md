# Slice: S01 — Archiv + Swisstopo weg

**Parent:** `docs/plans/schema-village-map/INDEX.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Die bisherige OSM-Live-Geometrie liegt unter `archive/seuzach-osm/` (wiederherstellbar). Swisstopo-Raster und zugehörige QA-JPGs sind entfernt; Docs/Regeln beschreiben die Karten nicht mehr als aktive Referenz. `docs/plans/restore-stripped-landmarks/` ist als **überholt** markiert (OSM-Re-Wire gilt nicht für die Schema-Welt).

## In diesem Schritt

- OSM-Live-Daten nach `archive/seuzach-osm/` kopieren (u. a. `data/seuzach_roads.json`, `seuzach_ways.json`, Rails/Water/Forests-OSM-JSONs und was `world_sandbox` heute lädt)
- Swisstopo-Raster-TIFFs und committed QA-JPGs/Mosaics unter `docs/maps/` löschen (lokal + im Repo, soweit vorhanden)
- `docs/maps/SWISS-RASTER-REF.md`, Regel `swiss-raster-maps`, Agent-Hinweise: nicht mehr als Live-/QA-Ground-Truth für die Spielwelt; optional Archiv-Hinweis
- `docs/plans/restore-stripped-landmarks/INDEX.md` (und ggf. Stub-Kopf) **superseded** durch diese Aufgabe

## Nicht (andere Feature-Schritte)

- Schema-JSON, Spawn, `world_sandbox`-Load-Pfad (S02)
- Landmarken/Housing/Wald neu legen (S03–S06)
- `data/seuzach_roads_octilinear.json` als Live-Netz
- Neue Art

## Art (optional, damit Planner übersprungen werden kann)

- nein — nur Archiv, Löschen, Docs

## Testplan (optional, 2 Bullets)

- Archiv enthält die bisherigen OSM-Live-Dateien; `docs/maps/` ohne Raster-TIFFs/QA-JPGs; Docs/Regel ohne „use 1072-1+1052-3 for live QA“
- Docs-only: `python3 tests/schema_archive_s01_test.py` plus Suite; **kein Godot-Playtest** (kein sichtbares Gameplay in S01)

## Akzeptanz

- `archive/seuzach-osm/` enthält die OSM-Live-JSONs und `seuzach_geo.gd`
- `docs/maps/` ohne `*.tif` und ohne Swiss-QA-JPGs
- Regel `swiss-raster-maps.mdc` weg; `restore-stripped-landmarks` als überholt markiert
