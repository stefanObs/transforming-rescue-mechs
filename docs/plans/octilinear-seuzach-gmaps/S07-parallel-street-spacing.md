# Slice: S07 — Parallel street spacing

**Parent:** `docs/plans/octilinear-seuzach-gmaps/INDEX.md`  
**Hängt ab von:** S06

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Im octilinearen Netz liegen parallele Straßen nicht mehr unnatürlich dicht beieinander: doppelte/nahe Parallel-Spuren sind zusammengeführt oder klar getrennt, so dass das SVG lesbar bleibt und dem Swiss-Trace entspricht.

## In diesem Schritt

- Zu dichte Parallel-Paare im Generator-Output erkennen (sichtbar im SVG als doppelte/nahe Bänder)
- Auflösen: entweder Merge/Dedup zu einer Trace-Straße oder ausreichender Abstand — beides dort, wo die Swiss-Quelle es vorgibt; JSON + SVG neu erzeugen

## Nicht (andere Feature-Schritte)

- Junction-/Corner-Geometrie (→ S06)
- `world_sandbox` / Spielwelt auf octilinear JSON umschalten
- `data/seuzach_roads.json` / live OSM als Geometrie-Quelle
- Ganz Seuzach neu tracen oder neue Quartiere digitalisieren

## Art

- nein — nur Generator + Trace-Geometrie + SVG/JSON

## Testplan

- SVG: ehemalige zu-dichte Parallel-Stellen lesen als eine Straße oder klar getrennte Paare, nicht als doppeltes Band
- JSON: keine nahe Parallel-Segmente unter dem gewählten Mindestabstand (außer bewusst getrennte echte Doppelspuren laut Trace)
