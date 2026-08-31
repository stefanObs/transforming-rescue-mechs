# Slice: S08 — T-junction attachment + endpoint hygiene

**Status:** erledigt  
**Parent:** `docs/plans/octilinear-seuzach-gmaps/INDEX.md`  
**Hängt ab von:** S07

## Feature

Side streets end on crossing corridors (shared vertex on the host line). Lines may draw over each other in SVG (locals under mains) but geometrically meet at that vertex. No new knot clusters; phantom parallel doubles absorbed when Swiss trace agrees.

## Out

- `attach_t_junctions` after `connect_network` + re-attach after parallel/trim passes
- `trim_endpoint_overshoot` (only when endpoint overshoots past crossing)
- `prune_orphan_links` (drop redundant `link-*` when both ends are shared hubs)
- `validate_endpoint_meets` (`count_t_miss == 0`)
- Trace-backed parallel absorb (`_trace_min_dist_m` + subset guards; never gut named roads < 800 wu)
- Tests: `tests/octilinear_t_junction_test.py`
- Regenerated `data/seuzach_roads_octilinear.json` + `docs/maps/seuzach_octilinear_roads.svg` (82 roads, 95 junctions, 0 link-*, t_miss=0, near-parallel 80–400 wu = 1)

## Akzeptanz

- S06 + S07 regression tests grün
- Interior T-miss count 0 on committed JSON
- No named-road stubs; Friedenstrasse / Holderweg / key corridors keep length
- `link-*` count 0 (network connected without synthetic stubs)
