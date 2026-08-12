# Slice: S01 — Buildings off RoadKit asphalt

**Parent:** `docs/plans/assets-clear-of-streets/INDEX.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht Häuser **und** Landmarken (Schulen, Kigas, Bahnhof, Badi, Feuerwehr) klar neben dem RoadKit-Asphalt — keine Sprite-Füße oder BuildingCollision auf der Fahrbahn. Gemeinsamer Clearance-Helper; Setback/Footprint nur so weit anheben, wie visuelle Überlappung es verlangt.

## In diesem Schritt

- Shared off-road clearance helper für alle Building-Props (Häuser + Landmarken/Kigas/Bahnhof/Badi/Feuerwehr)
- Setback / footprint bump nur wo Sprites optisch auf Asphalt sitzen (bestehende HOUSE_SCALE 0.38, SCHOOL/LANDMARK scales, setback slack 24 als Ausgang)
- Asserts: Häuser **und** Landmarken ohne Street-Overlap (Feet + AABB vs. named RoadKit polylines)

## Nicht (andere Feature-Schritte)

- Wälder, Bäche, Schienen-Props freiräumen oder neu platzieren (→ S02)
- Facing-/Flip-/Setband-Konsistenz-Politur über alle Korridore (→ S02)
- RoadKit-Geometrie oder OSM-Koordinaten massiv verschieben; neue Gebäude-Art

## Art

- nein — Placement/Clearance nur; keine neuen Sprites

## Testplan

- Houses und Landmarken (school_cluster / kindergarten_id / bahnhof / badi): Feet + AABB Clearance gegen named roads grün (visual clear 0.55/0.35 + EDGE_MARGIN 28)
- Keine Regression an bestehendem side-aware Flip / street-facing Housing
- BuildingCollision Walk-Footprint bleibt 0.20/0.10

## Akzeptanz

- Shared `_sprite_clears_named_roads` / `_nudge_off_named_roads` in `world_sandbox.gd`
- Häuser setzen Setback aus visual clear half-width; Landmarken werden bei Asphalt-Overlap senkrecht genudgt (≤400 wu)
- `./scripts/run_tests.sh` grün; house counts bleiben sinnvoll (≥15 total, spawn viewport ≥3)

Playtest 2026-08-12: Pass — spawn houses and Bahnhof/Birch clear of asphalt (visual clear).
