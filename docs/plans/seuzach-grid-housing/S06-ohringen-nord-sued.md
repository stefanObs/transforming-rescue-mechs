# Slice: S06 — Ohringen Nord + Ohringen Süd

**Parent:** `docs/plans/seuzach-grid-housing/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht Wohnbebauung in den **eigenen Ohringen-Rasterzellen** **OHR-NORD** und **OHR-SUED** entlang Ohringer-/Wohnachsen — Campus und Kiga Ohringen bleiben, Wohnzeilen füllen maps-plausible Lücken.

## In diesem Schritt

- Housing-Zellen **OHR-NORD** und **OHR-SUED** (zwei verwandte Ohringen-Zellen)
- Straßenbindung: Ohringerstrasse / Schulstrasse / lokale Ohringen-Wohnwege laut RoadKit
- Clearance zu Campus Ohringen + Kiga Ohringen; keine fiktive Ohringen-Kirche

## Nicht (andere Feature-Schritte)

- Seuzach-Dorfkern / Landstrasse / Bahnhof-Housing (S01–S05)
- Ohringen-Campus oder Kiga neu skalieren/setzen
- Forrenberg-/A1-Wohnsiedlung

## Art

- nein — bestehende House-Assets (Art nur wenn Slice nachweislich neue Varianten braucht)

## Testplan

### Automatisiert

- [ ] Registry enthält `OHR-NORD` + `OHR-SUED` (Bounds ≈ INDEX ±10) neben S01–S05; `active_ids` = 12
- [ ] ≥4 Häuser mit `housing_quartier == "OHR-NORD"` und Zell-Index im Rect (±1); analog OHR-SUED
- [ ] S01–S05-Asserts bleiben grün (≥4 je Quartier, Spawn-Viewport ≥3)
- [ ] Shared `placed[]`: keine Doppel-Stacks (min pairwise sep ≥ min_house_sep)
- [ ] Corridor-Meta `ohr-nord` / `ohr-sued` mappt auf Quartier-IDs
- [ ] Housing hält Clearance zu Campus Ohringen (a/b + Turnhalle) + Kiga Ohringen; Landmark-Counts bleiben
- [ ] Off-Road / Facing weiter grün (E–W-Samples inkl. ohr-nord/ohr-sued)
- [ ] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [ ] Teleport Ohringen: beide Zellen mit Wohnzeilen, off-road, Fassade // Band
- [ ] Campus/Kiga-Footprints frei; F1-Feldindizes im Ohringen-Bereich
- [ ] Keine neuen Assets; S01–S05 Seuzach-Kernquartiere unverändert

## Akzeptanzkriterien

- [ ] OHR-NORD und OHR-SUED in der Quartier-Registry mit Ohringerstrasse / Schulstrasse (+ lokale Ohringen-Wohnwege) aus `seuzach_roads.json`
- [ ] Placement über `_place_housing_in_quarter` / shared `placed[]` mit S01–S05 — kein Doppel-Stack
- [ ] Maps-plausible Wohnzeilen in den Ohringen-SW-Zellen; Campus + Kiga bleiben Landmarken
- [ ] S01–S05-Quartiere und Suite-Garantien bleiben grün; kein Art-Import; kein Forrenberg-/A1-Housing
