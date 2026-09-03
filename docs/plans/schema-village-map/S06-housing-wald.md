# Slice: S06 — Housing + Wald

**Parent:** `docs/plans/schema-village-map/INDEX.md`  
**Hängt ab von:** S05

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

EW-Häuser stehen entlang **Hauptstrasse** und **Wohnstrasse** (nördlich), Waldrand schließt die kompakte Welt. Volle Overlap-Suite: nichts überlappt Straßen, Civic, Schulen, Bahnhof/Ohringen oder andere Häuser.

## In diesem Schritt

- Housing `_ew` an Hauptstrasse (Kern-Korridor) und Wohnstrasse (EW nördlich)
- Waldrand / Forest-Props am Weltrand (bestehende Forest-Art), nicht OSM-Polygone 1:1
- Occupancy-AABBs für alle Live-Props; Overlap-Suite vollständig (Gebäude↔Gebäude, Gebäude↔Straße)
- OSM-Housing/Forest-Live-Placement abschalten

## Nicht (andere Feature-Schritte)

- Landmarken aus S03–S05 neu setzen
- Neue Haus- oder Wald-Art; `_ns`-Varianten
- GPS-genaue Siedlungsfüllung

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehende `house_street_*_ew` und Forest-PNGs

## Testplan (optional, 2 Bullets)

- Housing an beiden EW-Strassen; Forest am Rand; Overlap-Suite grün (keine AABB-Kollisionen)
- Playtest: Zeilen `_ew` entlang der Bänder, Wald als Kante, Landmarken unverdeckt und ohne Stacking
