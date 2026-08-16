# Slice: S02 — Campus Rietacker house-real ratio

**Parent:** `docs/plans/school-house-real-ratio/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (Campus Rietacker: drei Trakte a / b / Turnhalle auf dasselbe Spiel-zu-Real-Verhältnis wie Häuser). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Campus **Rietacker** (Schulhäuser a/b + Turnhalle) wirkt neben den Häusern gleich skaliert: platziert-Achsen-Spritebreite / OSM-Strassenfassade ≈ **1.72**. `SCHOOL_SCALE` bleibt 0.50; nur die drei Rietacker-`*_SCALE_MULT` in `scripts/world_sandbox.gd`. a ist heute stärker aufgeblasen als Häuser und muss schrumpfen; die Turnhalle ist heute zu klein (~0.78× real).

## In diesem Schritt

- Ziel: placed-axis Spritebreite / OSM-Strassenfassade ≈ 1.72
- Draft-Mults (Implementer darf auf 2 Dezimalen runden):
  - `RIETACKER_A_SCALE_MULT` 1.30 → **1.04** (`_ew` Ohringerstrasse; heute stärker inflated als Häuser)
  - `RIETACKER_B_SCALE_MULT` 1.25 → **1.21**
  - `RIETACKER_TURNHALLE_SCALE_MULT` 1.30 → **2.89** (`_ns` Turnerstrasse; 48 m Halle heute 0.78× real)
- Hof/Asphalt: wenn ein Mult Hof überlappt oder Asphalt bemalt → **diesen** Mult senken bis frei (nicht GPS/Roads)

## Nicht (andere Feature-Schritte)

- Birch (S01), Ohringen + Kiga Ohringen (S03), Seuzach-Kigas (S04)
- `HOUSE_SCALE`, `SCHOOL_SCALE`, `FIELD_METERS`, GPS, Art-PNGs, Road-Polylines
- Bahnhof / Badi (`LANDMARK_SCALE`)

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehende Rietacker `_ew`/`_ns` PNGs; nur Mult-Konstanten

## Testplan (optional, 2 Bullets)

- Suite: Asserts auf die Rietacker-Mults (1.04 / 1.21 / 2.62, gerundet ok); Birch-Mults aus S01 und `HOUSE_SCALE` 0.38 unverändert
- Playtest: Campus Rietacker visuell neben Häusern im selben Maß; kein Asphalt unter den drei Trakten, Hof frei

## Akzeptanz

- `RIETACKER_A_SCALE_MULT` / `RIETACKER_B_SCALE_MULT` / `RIETACKER_TURNHALLE_SCALE_MULT` locked at **1.04 / 1.21 / 2.62**
- Gym draft **2.89** did not place (asphalt / missing prop); **2.64+** exceeds Turnerstrasse setback `d < 800`. Highest green: **2.62** (effective 1.31)
- Effective scales: a 0.52, b 0.605, gym 1.31 (`SCHOOL_SCALE` 0.50)
- `HOUSE_SCALE` 0.38 and `SCHOOL_SCALE` 0.50 unchanged; Birch Mults stay 1.68 / 1.34 / 2.22
- Suite green: Rietacker Mult asserts, campus scale asserts, off-road clearance for the three Rietacker tracts
