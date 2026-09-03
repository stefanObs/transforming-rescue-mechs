# Slice: S04 — Schulen Birch + Rietacker

**Parent:** `docs/plans/schema-village-map/INDEX.md`  
**Hängt ab von:** S03

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

An der **Schulstrasse** (EW südlich des Kerns) stehen zwei Campus-Cluster: **Birch** und **Rietacker** (je a/b + Turnhalle) plus die zugehörigen Kigas, `_ew`, Occupancy ohne Überlappung mit dem Dorfkern.

## In diesem Schritt

- Campus Birch als Cluster an Schulstrasse (bestehende Schul-PNGs, `_ew`)
- Campus Rietacker als zweiter Cluster derselben Strasse, klarer Abstand zu Birch
- Zugehörige Kigas (Seuzach-Schulstrasse-Kigas, z. B. Bachtobel/Weid/Schneckenwiese soweit dem Schema zugeordnet — nicht Ohringen) `_ew` neben den Campus
- Occupancy-AABBs vs. S03-Civic/Shops und Straßenkorridor
- OSM-GPS-Schulplacement in der Live-Welt abschalten

## Nicht (andere Feature-Schritte)

- Ohringen-Campus, Kiga Ohringen, St. Martin (S05)
- Bahnhof/Badi/Hub (S05)
- Housing/Wald (S06)
- Neue Art; `_ns` aus `_ew` rotieren

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehende Campus- und Kiga-PNGs

## Testplan (optional, 2 Bullets)

- Beide Cluster + Kigas vorhanden; Occupancy ohne Overlap; Facing `_ew`
- Playtest: Schulstrasse südlich, zwei getrennte Campus lesbar, Kern bleibt frei
