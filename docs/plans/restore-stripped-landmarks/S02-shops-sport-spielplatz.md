# Slice: S02 — Shops, restaurants, sport & spielplatz

**Parent:** `docs/plans/restore-stripped-landmarks/INDEX.md`  
**Überholt:** Läden/Sport kommen in `docs/plans/schema-village-map/S03-dorfkern-laeden.md`.  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht wieder kommerzielle Props (Restaurants a/b, Läden a/b/c) sowie Sportplätze und Spielplätze an realen Ankern (u. a. Badi, Schneckenwiese, Ohringen / Rolli) — gleiche Placement-/Clearance-Patterns wie S01.

## In diesem Schritt

- `restaurant_a`, `restaurant_b`, `laden_a`, `laden_b`, `laden_c` platzieren (bestehende PNGs)
- `sportplatz` (mind. Rolli + Badi-Kontext) und `spielplatz` (Badi / Schneckenwiese / Ohringen) platzieren
- GPS/`SeuzachGeo`-Offsets von bekannten Ankern (`badi_world`, `kiga_*`, Bahnhof, Kirche); Clearance-Nudge wie S01
- Tests: bisheriges `assert NO sportplatz` und optionale Shops umdrehen; Counts/IDs explizit; bestehende Civic/Hub aus S01 bleiben

## Nicht (andere Feature-Schritte)

- Kirchen, Feuerwehr, Gemeindehaus, Hub, Tankstelle (S01)
- Schulen, Kigas, Bahnhof, Badi, Forests, Housing neu legen
- Neue Art generieren

## Art (optional, damit Planner übersprungen werden kann)

- nein — Assets auf Disk (`landmark_restaurant_{a,b}`, `landmark_laden_{a,b,c}`, `landmark_sportplatz`, `landmark_spielplatz`); nur Re-Wire

## Testplan (optional, 2 Bullets)

- Landmarks-Test: alle Shop-/Play-IDs vorhanden; Sport-/Spielplatz nicht mehr verboten; Clearance liefert keine stillen Drops
- Playtest: mind. ein Laden/Restaurant und ein Sport-/Spielplatz an Badi- bzw. Kiga-Nähe sichtbar und kollisionsfähig
