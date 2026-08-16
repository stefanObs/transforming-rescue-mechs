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

- Suite: Asserts auf die neuen Ohringen-Mults (1.85 / 1.96 / 1.21 / 0.78, gerundet ok); Cluster bleibt 3, Kiga ohne `school_cluster`
- Playtest: Campus + Kiga Ohringen visuell neben Häusern im selben Maß; kein Asphalt unter den vier Gebäuden, Hof frei
