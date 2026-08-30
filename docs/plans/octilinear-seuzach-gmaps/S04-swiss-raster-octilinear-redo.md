# Slice: S04 — Redo octilinear SVG from Swiss Map Raster (1072-1 + 1052-3)

**Parent:** `docs/plans/octilinear-seuzach-gmaps/INDEX.md`  
**Hängt ab von:** S03

## Feature

`docs/maps/seuzach_octilinear_roads.svg` wird neu aus dem offiziellen Swiss Map Raster 10 gebaut: Sheets **1072-1** (Dorf/Ohringen) + **1052-3** (Badi-Nord). Octilinear H/V/45°, verbundenes Netz, gleiche CLIP/Kirche-Skala. Sandbox bleibt auf `seuzach_roads.json`.

## In diesem Schritt

- Seuzach+Ohringen-Ausschnitt aus den zwei GeoTIFFs als Referenz-Mosaik
- Trace + Generator neu: Korridore an offizieller Karte ausgerichtet, verbunden, denser als S02
- Emit JSON + SVG; Docs kurz aktualisieren

## Nicht

- Sandbox umschalten
- Geometrie aus `seuzach_roads.json` kopieren
- 300+ MB TIFFs committen

## Art

- nein

## Testplan

- Referenz-Crop zeigt Seuzach/Ohringen; SVG viewBox=CLIP; 1 dominante Komponente; Winterthurer↔Stationsstrasse gap 0; ≥40 roads; nur H/V/45°
