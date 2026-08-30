# Slice: S07 — Parallel street spacing

**Status:** erledigt  
**Parent:** `docs/plans/octilinear-seuzach-gmaps/INDEX.md`  
**Hängt ab von:** S06

## Feature

Im octilinearen Netz liegen parallele Straßen nicht mehr unnatürlich dicht beieinander: doppelte/nahe Parallel-Spuren sind zusammengeführt oder klar getrennt.

## Out

- `resolve_near_parallels` nach `clean_corners`: absorb nur bei hoher Subset-Fraktion / link-*; named roads nie zu Stubs
- Near-parallel 80–400 wu: ~27 → ~5; colinear 0–80: 0
- Named corridors (Bruggackerweg, Friedenstrasse, …) behalten Länge
- Tests: `tests/octilinear_parallel_spacing_test.py`
- Unit: `tests/octilinear_parallel_spacing_test.py` — synthetisches Absorb (link-/local vs main) + Separate (zwei Locals → ≥ PARALLEL_MIN_GAP); Winter pinned
- Regression: bestehende S06-Tests (REQUIRED hubs, Ohringer EW, no reverse folds, no Stations↔Winter coincident) bleiben grün
- Metric: `count_near_parallel_pairs(..., lo=80, hi=400)` vor/nach Resolve melden

## Akzeptanz

- Generator-Post-Pass `resolve_near_parallels` nach `clean_corners`, vor `validate_*`
- `validate_octilinear` + `validate_required_junctions` grün; kein Sandbox-Switch
- Zu dichte Artifact-Doubles (<~250 wu) absorbiert; echte Paare (250–500 wu) auf ≥~PARALLEL_MIN_GAP getrennt
- Pinned: Winterthurerstrasse / Ohringerstrasse / Stationsstrasse / A1 werden nicht verschoben, wenn die andere Straße bewegen kann
