# Slice: S03 — Stationsstrasse West + Bahnhof-Wohnzeilen

**Parent:** `docs/plans/seuzach-grid-housing/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht Wohnzeilen entlang **Stationsstrasse** vom Zentrumsrand (**STAT-WEST**) bis in die **Bahnhof-Nachbarschaft** (**STAT-BHF**) — Strasse bleibt lesbarer Korridor, Bahnhofsgebäude/Gleise unangetastet.

## In diesem Schritt

- Housing-Zellen **STAT-WEST** und **STAT-BHF** (Feldspannen INDEX, ±10 ok)
- Straßenbindung: Stationsstrasse; Strehlgasse / Stadlerstrasse nur wo sie die Rects schneiden
- S01-Quartier-API + shared `placed[]` mit S01/S02; Landmark-Clearance zu Bahnhof, Gleisband, Birch-Campus

## Nicht (andere Feature-Schritte)

- Bahnhof-Sprite, Gleise, Perron neu; Birch-Campus
- Reutlinger, Breite/Seebühl, Ohringen, Landstrasse-Nord bis Badi

## Art

- nein — bestehende House-Assets

## Testplan

### Automatisiert

- [ ] Registry enthält `STAT-WEST` + `STAT-BHF` (Bounds ≈ INDEX) neben S01/S02; `active_ids` = 6
- [ ] ≥4 Häuser mit `housing_quartier == "STAT-WEST"` und Zell-Index im Rect (±1); analog STAT-BHF
- [ ] S01/S02-Asserts bleiben grün (≥4 je Quartier, Spawn-Viewport ≥3)
- [ ] Shared `placed[]`: keine Doppel-Stacks (min pairwise sep ≥ min_house_sep)
- [ ] Corridor-Meta `stat-west` / `stat-bhf` mappt auf Quartier-IDs; Off-Road / Facing weiter grün
- [ ] Housing hält Clearance zum Bahnhof-Landmark (min_landmark_sep); Bahnhof-Count bleibt 1
- [ ] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [ ] Teleport/Drive: Wohnprops entlang Stationsstrasse in STAT-WEST und STAT-BHF, off-road
- [ ] Keine Housing-Props auf Bahnhof-/Gleis-/Birch-Footprints
- [ ] Bahnhof-Landmark unverändert; keine neuen Assets

## Akzeptanzkriterien

- [ ] STAT-WEST und STAT-BHF in der Quartier-Registry mit Stationsstrasse (+ lokale Schnitte Strehlgasse/Stadler) aus `seuzach_roads.json`
- [ ] Placement über `_place_housing_in_quarter` / shared `placed[]` mit S01/S02 — kein Doppel-Stack
- [ ] Maps-plausible Wohnzeilen an Stationsstrasse; Bahnhof bleibt Landmark, nicht neu gebaut
- [ ] S01/S02-Quartiere und Suite-Garantien bleiben grün; kein Art-Import
