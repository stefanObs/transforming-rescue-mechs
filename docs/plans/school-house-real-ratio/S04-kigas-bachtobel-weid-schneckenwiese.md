# Slice: S04 — Seuzach kigas Bachtobel + Weid + Schneckenwiese house-real ratio

**Parent:** `docs/plans/school-house-real-ratio/INDEX.md`  
**Hängt ab von:** S03

Nur der **Feature-Schritt** (drei verwandte Dorf-Kigas desselben Typs auf dasselbe Spiel-zu-Real-Verhältnis wie Häuser). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Die drei Seuzach-Kigas **Bachtobel**, **Weid** und **Schneckenwiese** wirken neben den Häusern gleich skaliert: platziert-Achsen-Spritebreite / OSM-Strassenfassade ≈ **1.72**. `SCHOOL_SCALE` bleibt 0.50; nur die drei Kiga-`*_SCALE_MULT` in `scripts/world_sandbox.gd`. Weid ist heute ~2.2× real und muss etwas kleiner werden.

## In diesem Schritt

- Ziel: drei Dorf-Kigas, Ratio 1.72 wie Häuser
- Draft-Mults (Implementer darf auf 2 Dezimalen runden):
  - `KIGA_BACHTOBEL_SCALE_MULT` 0.57 → **1.00**
  - `KIGA_WEID_SCALE_MULT` 0.55 → **0.43** (heute 2.2× real; Matching Häuser = etwas kleiner)
  - `KIGA_SCHNECKENWIESE_SCALE_MULT` 1.03 → **1.12**
- Hof/Asphalt: wenn ein Mult Hof überlappt oder Asphalt bemalt → **diesen** Mult senken bis frei (nicht GPS/Roads)

## Nicht (andere Feature-Schritte)

- Birch (S01), Rietacker (S02), Ohringen + Kiga Ohringen (S03)
- `HOUSE_SCALE`, `SCHOOL_SCALE`, `FIELD_METERS`, GPS, Art-PNGs, Road-Polylines
- Bahnhof / Badi (`LANDMARK_SCALE`)

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehende Kiga `_ew`/`_ns` PNGs; nur Mult-Konstanten

## Testplan (optional, 2 Bullets)

- Suite: Asserts auf die neuen Kiga-Mults (1.00 / 0.43 / 1.12, gerundet ok); `SCHOOL_SCALE` 0.50 und `HOUSE_SCALE` 0.38 unverändert
- Playtest: drei Kigas visuell neben Häusern im selben Maß; kein Asphalt unter den Sprites
