# Slice: S05 — Breitestrasse + Seebühl-Stich

**Parent:** `docs/plans/seuzach-grid-housing/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht Wohnzeilen an **Breitestrasse** (**BREITE**) und dem verbundenen **Seebühlstrasse-Stich** (**SEEBUEHL**) — Zentrumsrand / Birch–Reutlinger-Band, maps-plausibel.

## In diesem Schritt

- Housing-Zellen **BREITE** und **SEEBUEHL**
- Straßenbindung: Breitestrasse + Seebühlstrasse (+ Birchstrasse nur wo Wohnzeilen maps-plausibel und Campus-frei)
- Clearance zu Campus Birch und ggf. Shop-Landmarken (wenn schon verdrahtet)

## Nicht (andere Feature-Schritte)

- Birch-Campus / Turnhalle neu; Shops/Civic (`restore-stripped-landmarks`)
- Ohringen, Reutlinger-Hauptband (S04), Stationsstrasse

## Art

- nein — bestehende House-Assets

## Testplan

### Automatisiert

- [ ] Registry enthält `BREITE` + `SEEBUEHL` (Bounds ≈ INDEX ±10) neben S01–S04; `active_ids` = 10
- [ ] ≥4 Häuser mit `housing_quartier == "BREITE"` und Zell-Index im Rect (±1); analog SEEBUEHL
- [ ] S01–S04-Asserts bleiben grün (≥4 je Quartier, Spawn-Viewport ≥3)
- [ ] Shared `placed[]`: keine Doppel-Stacks (min pairwise sep ≥ min_house_sep)
- [ ] Corridor-Meta `breite` / `seebuehl` mappt auf Quartier-IDs
- [ ] Housing hält Clearance zu Campus Birch (schulhaus_a/b + Turnhalle; min_landmark_sep); Birch-Counts bleiben
- [ ] Off-Road / Facing weiter grün (E–W-Samples inkl. breite/seebuehl)
- [ ] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [ ] Teleport/Drive: Wohnprops entlang Breitestrasse und Seebühlstrasse-Stich, off-road
- [ ] Campus Birch-Footprint frei von Housing-Überdeckung
- [ ] Keine neuen Assets; Reutlinger-Hauptband (S04) unverändert

## Akzeptanzkriterien

- [ ] BREITE und SEEBUEHL in der Quartier-Registry mit Breitestrasse / Seebühlstrasse (+ Birchstrasse campus-clear) aus `seuzach_roads.json`
- [ ] Placement über `_place_housing_in_quarter` / shared `placed[]` mit S01–S04 — kein Doppel-Stack
- [ ] Maps-plausible Wohnzeilen am Breite-/Seebühl-Band; Birch-Campus bleibt Landmark-Cluster
- [ ] S01–S04-Quartiere und Suite-Garantien bleiben grün; kein Art-Import; S04 REUT-* nicht neu gebaut
