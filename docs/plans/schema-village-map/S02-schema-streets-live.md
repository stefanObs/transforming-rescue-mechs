# Slice: S02 — Schema-Straßen live

**Parent:** `docs/plans/schema-village-map/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

`world_sandbox` fährt ein **neues** kompaktes Schema-Netz (~80×60 Felder, Kirche-Origin): nur Horizontal / Vertikal / 45°. Spawn auf der **Hauptstrasse** (EW durch 0,0). Schienen nur als Stub (kein volles OSM-Gleisnetz). Spieler sieht ein lesbares Dorf-Gitter, nicht die GPS-OSM-Welt.

## In diesem Schritt

- Neues H/V/45°-JSON (eigene Datei, **nicht** Live-`seuzach_roads_octilinear.json`): Hauptstrasse EW durch (0,0); Stationsstrasse NS östlich des Kerns; Ohringerstrasse 45° SE; Schulstrasse EW südlich; Wohnstrasse EW nördlich
- `world_sandbox` lädt dieses Netz statt `data/seuzach_roads.json` (OSM bleibt nur im Archiv)
- Spawn auf Hauptstrasse nahe Kirche/Origin
- Rails-Stub (Platzhalter-Polylinie oder leeres/minimales JSON), keine OSM-Rails live
- CLIP/Weltgröße an ~80×60 Felder anpassen, soweit nötig fürs Netz

## Nicht (andere Feature-Schritte)

- Civic, Läden, Schulen, Bahnhof, Housing, Wald (S03–S06)
- GPS-genaue Traces oder Swisstopo-Abgleich
- Neue Straßen-Art / neue Gebäude-PNGs

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehendes RoadKit; keine neuen PNGs

## Testplan (optional, 2 Bullets)

- Welt lädt das Schema-JSON; Segmente nur H/V/45°; Spawn auf Hauptstrasse; octilinear-OSM-JSON nicht der Load-Pfad
- Playtest: lesbare Haupt-/Stations-/Ohringer-/Schul-/Wohnstrasse; kompakter Kern um (0,0); keine OSM-Weite
