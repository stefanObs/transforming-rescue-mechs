# Slice: S01 — Fast world build (load)

**Parent:** `docs/plans/world-performance/INDEX.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Die Welt baut in Sekunden statt Minuten auf (`world_sandbox` `_ready`), bei gleicher Kartenoptik und weiterhin **allen** Quartieren/Häusern. Spieler merkt: Start ist spielbar schnell; Map sieht aus wie zuvor.

## In diesem Schritt

- Spatial road index für clearance/nudge (nur lokale Roads pro Kandidat, nicht alle ~Straßen pro Haus)
- Texture cache für House-Varianten (kein wiederholtes Laden derselben Textur)
- Cheaper nudge (größerer Step, feet early-out)
- Timing-Splits in `_ready` + Messung (Bottlenecks sichtbar)
- Alle Quartiere weiterhin in diesem Slice platzieren (Streaming erst S02, hitch-light)

## Nicht (andere Feature-Schritte)

- Quarter lazy-load / nur near-spawn Housing beim Start (S02)
- Dash-Merge in `road_kit` / weniger Polygon2Ds (S02)
- HUD `_refresh_status` nur on change (S02)
- Texture import `size_limit` für Houses/Landmarks (S02)

## Art

- nein — reine Runtime-/Build-Optimierung, keine neuen Assets

## Testplan

- `_ready`-Dauer messbar stark unter ~153s (Ziel: Sekunden-Bereich); Timing-Splits zeigen Index/Cache/Nudge statt Full-Road-Scans
- Visuell: gleiche Housing-/Straßenoptik, alle Quartiere weiterhin vorhanden
- Algorithmisch: Spatial-Index-Clearance ≡ Full-Road-Scan auf Fixture-Positionen (`tests/m3_road_spatial_index_test.gd`)

## Akzeptanz

- Spatial road index + local clearance/nudge; Texture-Cache; Nudge-Step ~28; `_ready` Timing-Splits geloggt
- Alle Quartiere weiterhin platziert (keine Density-Änderung)
- Suite inkl. Index-Äquivalenz-Test grün

## Repro & RCA

**Repro:** Headless instantiate `world_sandbox.tscn` — `_ready` ~153s; ~826 houses.

**RCA:** `_sprite_clears_named_roads` / `_nudge_off_named_roads` iterate every named road/segment per candidate (and per nudge step 8 wu × ≤700). Texture `load()` repeats for 8 house variants. Algorithmic cost dominates, not asset I/O alone.

**Fix direction:** Spatial road cell index → local queries; texture cache; larger nudge step + feet early-out; `_ready` msec splits.
