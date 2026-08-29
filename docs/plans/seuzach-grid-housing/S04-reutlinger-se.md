# Slice: S04 — Reutlinger Mitte + Reutlinger SE

**Parent:** `docs/plans/seuzach-grid-housing/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht Wohnbebauung an **Reutlingerstrasse Mitte** (**REUT-MITTE**, inkl. Schneckenwiese-Nahband) und dem **südöstlichen Reutlinger-Band** (**REUT-SE**).

## In diesem Schritt

- Housing-Zellen **REUT-MITTE** und **REUT-SE**
- Straßenbindung: Reutlingerstrasse (+ Schneckenwiesenstrasse / lokale Stiche nur im Band)
- Clearance zu Kiga Schneckenwiese und bestehenden Spawn-Korridor-Häusern (keine Doppel-Stacks)
- S01-Interim-Radius-Korridor `schneckenwiese` entfernen — Housing kommt nur noch aus REUT-*

## Nicht (andere Feature-Schritte)

- Breite/Seebühl, Stationsstrasse, Ohringen, Landstrasse
- Kiga-/Campus-Neuplatzierung

## Art

- nein — bestehende House-Assets

## Testplan

### Automatisiert

- [ ] Registry enthält `REUT-MITTE` + `REUT-SE` (Bounds ≈ INDEX ±10) neben S01–S03; `active_ids` = 8
- [ ] ≥4 Häuser mit `housing_quartier == "REUT-MITTE"` und Zell-Index im Rect (±1); analog REUT-SE
- [ ] S01–S03-Asserts bleiben grün (≥4 je Quartier, Spawn-Viewport ≥3)
- [ ] Shared `placed[]`: keine Doppel-Stacks (min pairwise sep ≥ min_house_sep)
- [ ] Corridor-Meta `reut-mitte` / `reut-se` mappt auf Quartier-IDs; kein Legacy-`schneckenwiese`-Corridor mehr
- [ ] Housing hält Clearance zu Kiga Schneckenwiese (min_landmark_sep); Kiga-Count bleibt 1
- [ ] Off-Road / Facing weiter grün (E–W-Samples inkl. reut-* statt interim)
- [ ] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [ ] Teleport/Drive: Wohnprops entlang Reutlingerstrasse in REUT-MITTE und REUT-SE, off-road
- [ ] Kiga Schneckenwiese-Footprint frei; keine Duplikate mit altem Radius-Korridor
- [ ] Keine neuen Assets

## Akzeptanzkriterien

- [ ] REUT-MITTE und REUT-SE in der Quartier-Registry mit Reutlingerstrasse (+ Schneckenwiesenstrasse / lokale Schnitte) aus `seuzach_roads.json`
- [ ] Placement über `_place_housing_in_quarter` / shared `placed[]` mit S01–S03 — kein Doppel-Stack
- [ ] Interim `schneckenwiese`-Radius-Call aus `_place_spawn_housing` entfernt
- [ ] Maps-plausible Wohnzeilen am Reutlinger-Band; Kiga bleibt Landmark
- [ ] S01–S03-Quartiere und Suite-Garantien bleiben grün; kein Art-Import
