# Slice: S03 — Ohringen campus + kiga house-real ratio

**Parent:** `docs/plans/school-house-real-ratio/INDEX.md`  
**Hängt ab von:** S02

Nur der **Feature-Schritt** (zwei verwandte Inkremente in derselben Ohringen-Zelle: Campus-Cluster a/b/Turnhalle + Kiga Ohringen). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Schul-Campus **Ohringen** und **Kiga Ohringen** wirken neben den Häusern gleich skaliert: platziert-Achsen-Spritebreite / OSM-Strassenfassade ≈ **1.72**. `SCHOOL_SCALE` bleibt 0.50; nur die vier Ohringen-`*_SCALE_MULT` in `scripts/world_sandbox.gd`. Turnhalle nutzt das ~28 m Gym-Ziel aus dem früheren Scale-Plan, nicht den Schulstrasse-7-Footprint.

## In diesem Schritt

- Ziel: a `_ns` Schulstrasse; b `_ns`; Turnhalle ~28 m Gym-Fassade; Kiga Ohringen gleiche Ratio 1.72
- Draft-Mults (Implementer darf auf 2 Dezimalen runden):
  - `OHRINGEN_A_SCALE_MULT` 1.35 → **1.85** (`_ns` Schulstrasse)
  - `OHRINGEN_B_SCALE_MULT` 0.83 → **1.96**
  - `OHRINGEN_TURNHALLE_SCALE_MULT` 0.75 → **1.21** (~28 m Gym-Ziel; nicht Schulstrasse-7-Footprint wiederverwenden)
  - `KIGA_OHRINGEN_SCALE_MULT` 0.55 → **0.78**
- Hof/Asphalt: wenn ein Mult Hof überlappt oder Asphalt bemalt → **diesen** Mult senken bis frei (nicht GPS/Roads)

## Nicht (andere Feature-Schritte)

- Birch (S01), Rietacker (S02), Seuzach-Kigas Bachtobel/Weid/Schneckenwiese (S04)
- `HOUSE_SCALE`, `SCHOOL_SCALE`, `FIELD_METERS`, GPS, Art-PNGs, Road-Polylines
- Bahnhof / Badi (`LANDMARK_SCALE`); Kiga in den Campus-Cluster ziehen

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehende Ohringen/Kiga `_ew`/`_ns` PNGs; nur Mult-Konstanten

## Testplan (optional, 2 Bullets)

- Suite: Asserts auf die Ohringen-Mults (1.42 / 1.28 / 1.21 / 0.78, gerundet ok); Cluster bleibt 3, Kiga ohne `school_cluster`
- Playtest: Campus + Kiga Ohringen visuell neben Häusern im selben Maß; kein Asphalt unter den vier Gebäuden, Hof frei

## Akzeptanz

- `OHRINGEN_A_SCALE_MULT` / `OHRINGEN_B_SCALE_MULT` / `OHRINGEN_TURNHALLE_SCALE_MULT` / `KIGA_OHRINGEN_SCALE_MULT` locked at **1.42 / 1.28 / 1.21 / 0.78**
- A draft **1.85** did not place (`a_ns` tall AABB vs Rebhogerstrasse; recover-south >700 wu). **1.43+** fails `a.y < gym.y - 400`. Highest green: **1.42** (effective 0.71)
- B draft **1.96** placed but west-nudge failed `b.x > gym.x + 200`. **1.29+** lands 0.02 wu west of the 200-wu line. Highest green: **1.28** (effective 0.64)
- Gym draft **1.21** placed (effective 0.605). Kiga draft **0.78** placed (effective 0.39); no `school_cluster`
- Effective scales: a 0.71, b 0.64, gym 0.605, kiga_ohringen 0.39 (`SCHOOL_SCALE` 0.50)
- `HOUSE_SCALE` 0.38 and `SCHOOL_SCALE` 0.50 unchanged; Birch Mults stay 1.68 / 1.34 / 2.22; Rietacker Mults stay 1.04 / 1.21 / 2.62
- Suite green: Ohringen Mult asserts, campus/kiga scale asserts, cluster=3, kiga without `school_cluster`, off-road clearance for the four buildings
