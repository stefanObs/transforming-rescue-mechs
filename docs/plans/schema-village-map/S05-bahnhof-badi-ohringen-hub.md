# Slice: S05 — Bahnhof/Badi + Ohringen/Hub

**Parent:** `docs/plans/schema-village-map/INDEX.md`  
**Hängt ab von:** S04

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Nördlich an der **Stationsstrasse**: Bahnhof mit Gleis-Stub und Badi. Südost an der **Ohringerstrasse** (45°): St. Martin, Ohringen-Campus + Kiga, am Ende Hub + Tankstelle inkl. Enter. Alles `_ew`, Occupancy, bestehende PNGs.

## In diesem Schritt

- Bahnhof + Track/Gleis am Nordende der Stationsstrasse; Badi nördlich daneben (kein OSM-Wasser-Vollnetz nötig)
- St. Martin an der Ohringerstrasse; Ohringen-Campus-Cluster + Kiga Ohringen weiter SE
- Hub-Station + Tankstelle am Ende der Ohringerstrasse; Hub-Enter/Transition wie bestehendes System, Schema-Coords
- Occupancy vs. S03/S04 und Straßen; `_ew` erzwingen
- OSM-GPS für diese IDs in der Live-Welt abschalten

## Nicht (andere Feature-Schritte)

- Housing-Zeilen und Wald (S06)
- Birch/Rietacker oder Dorfkern neu legen (S03/S04)
- Neue Art; GPS-genaue Ohringen-/Forrenberg-Lage

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehende Bahnhof/Badi/St.-Martin/Ohringen/Hub/Tankstellen-PNGs

## Testplan (optional, 2 Bullets)

- Bahnhof+Track, Badi, St. Martin, Ohringen-Campus+Kiga, Hub+Tankstelle vorhanden; Occupancy ohne Overlap; Hub Enter erreichbar
- Playtest: Nord-Anker Stationsstrasse und SE-Achse Ohringerstrasse lesbar, `_ew`
