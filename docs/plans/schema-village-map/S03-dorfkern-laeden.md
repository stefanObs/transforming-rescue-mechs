# Slice: S03 — Dorfkern + Läden

**Parent:** `docs/plans/schema-village-map/INDEX.md`  
**Hängt ab von:** S02

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Am Schema-Kern sitzen Kirche, Gemeindehaus und Feuerwehr ohne Überlappung; daneben Läden/Restaurants plus Sport- und Spielplatz. Alles **bestehende** `_ew`-Art, Occupancy-AABBs, nicht GPS.

## In diesem Schritt

- Kirche am Origin, Gemeinde + Feuerwehr im Dorfkern (Haupt-/Stationsstrasse-Nähe)
- Läden/Restaurants + Sportplatz + Spielplatz im Kern-Quartier, klar getrennt vom Civic
- Occupancy-AABBs einführen/nutzen, sodass nichts ineinander sitzt
- Bearing **`_ew` erzwingen** (keine `_ns`-Rotation)
- OSM-GPS-Placement für diese IDs in der Live-Welt abschalten

## Nicht (andere Feature-Schritte)

- Schulen/Kigas Birch+Rietacker (S04)
- Bahnhof, Badi, St. Martin, Ohringen, Hub (S05)
- Housing-Zeilen und Wald (S06)
- Neue Art

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehende Landmark-PNGs (`landmark_kirche_seuzach`, Gemeinde, Feuerwehr, Shops/Restaurants, Sport/Spielplatz)

## Testplan (optional, 2 Bullets)

- IDs vorhanden; Occupancy: keine AABB-Überlappung untereinander oder mit Straßenkorridor
- Playtest: Kern lesbar, alle `_ew`, nichts stapelt sich
