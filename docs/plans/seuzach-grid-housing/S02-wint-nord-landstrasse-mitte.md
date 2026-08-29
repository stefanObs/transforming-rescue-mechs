# Slice: S02 — Winterthurer-Nord + Landstrasse-Mitte

**Parent:** `docs/plans/seuzach-grid-housing/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht Wohnbebauung entlang **Winterthurerstrasse nordwärts** (**WINT-NORD**) und dem verbundenen **Landstrasse-Mitte**-Band (**LAND-MITTE**) — maps-plausibel Richtung Badi-Korridor, ohne die Badi neu zu bauen.

## In diesem Schritt

- Housing-Zellen **WINT-NORD** und **LAND-MITTE** (Feldspannen INDEX)
- Straßenbindung: Winterthurerstrasse (Nordsegment) + Landstrasse (Mitte); lokale Nebenachsen nur wenn sie das Band schneiden
- S01-Quartier-API nutzen; Clearance zu Landmarken (Badi, Campi) einhalten

## Nicht (andere Feature-Schritte)

- Stationsstrasse / Bahnhof, Reutlinger, Breite/Seebühl, Ohringen
- Badi-Gebäude oder Sport-Landmarken
- KIRCHE-KERN / WINT-WEST nochmal umbauen (nur Anbindung)

## Art

- nein — bestehende House-Assets

## Testplan

### Automatisiert

- [ ] Registry enthält `WINT-NORD` + `LAND-MITTE` (Bounds ≈ INDEX) neben S01-Zellen; `active_ids` = 4
- [ ] ≥4 Häuser mit `housing_quartier == "WINT-NORD"` und Zell-Index im Rect (±1); analog LAND-MITTE
- [ ] S01-Asserts bleiben grün: ≥4 KIRCHE-KERN, ≥4 WINT-WEST, Spawn-Viewport ≥3
- [ ] Shared `placed[]`: keine Doppel-Stacks (min pairwise sep ≥ min_house_sep)
- [ ] Corridor-Meta `wint-nord` / `land-mitte` mappt auf Quartier-IDs; Off-Road / Facing weiter grün
- [ ] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [ ] Teleport/Drive: Häuser in WINT-NORD und LAND-MITTE sichtbar, off-road, entlang der Bänder
- [ ] Keine Housing-Props auf Badi-/Campus-Footprints
- [ ] KIRCHE-KERN / WINT-WEST unverändert lesbar; keine neuen Assets

## Akzeptanzkriterien

- [ ] WINT-NORD und LAND-MITTE in der Quartier-Registry mit korrekten Road-Namen aus `seuzach_roads.json`
- [ ] Placement über `_place_housing_in_quarter` / shared `placed[]` mit S01 — kein Doppel-Stack
- [ ] Maps-plausible Wohnzeilen an Winterthurer-Nord und Landstrasse-Mitte; Badi/Campi nicht neu gebaut
- [ ] S01-Quartiere und Suite-Garantien bleiben grün; kein Art-Import
