# Slice: S01 — Campus Birch house-real ratio

**Parent:** `docs/plans/school-house-real-ratio/INDEX.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (Campus Birch: drei Trakte a / b / Turnhalle auf dasselbe Spiel-zu-Real-Verhältnis wie Häuser). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Campus **Birch** (Schulhäuser a/b + Turnhalle) wirkt neben den Häusern gleich skaliert: platziert-Achsen-Spritebreite / OSM-Strassenfassade ≈ **1.72** (`HOUSE_TO_REAL_RATIO`, Referenz `house_street_a_ns` 16.62 m vs Winterthurerstrasse 29 OSM 9.64 m). `SCHOOL_SCALE` bleibt 0.50; nur die drei Birch-`*_SCALE_MULT` in `scripts/world_sandbox.gd`.

## In diesem Schritt

- Ziel: placed `_ns` an Bachwiesenstrasse / Birchstrasse; Fassaden-Ratio ≈ 1.72
- Draft-Mults (Implementer darf auf 2 Dezimalen runden):
  - `BIRCH_A_SCALE_MULT` 1.20 → **1.68** (OSM-Fassade ~22.5 m)
  - `BIRCH_B_SCALE_MULT` 1.20 → **1.34** (N–S-Strassenfassade ~14.2 m, nicht der 40 m E–W-Flügel)
  - `BIRCH_TURNHALLE_SCALE_MULT` 1.00 → **2.22** (Fassade ~25.7 m; heute zu klein)
- Hof/Asphalt: wenn ein Mult Hof überlappt oder Asphalt bemalt → **diesen** Mult senken bis frei

## Nicht (andere Feature-Schritte)

- Rietacker (S02), Ohringen + Kiga Ohringen (S03), Seuzach-Kigas (S04)
- `HOUSE_SCALE`, `SCHOOL_SCALE`, `FIELD_METERS`, GPS, Art-PNGs, Road-Polylines
- Bahnhof / Badi (`LANDMARK_SCALE`)

## Art (optional, damit Planner übersprungen werden kann)

- nein — bestehende Birch `_ew`/`_ns` PNGs; nur Mult-Konstanten

## Testplan (optional, 2 Bullets)

- Suite: Asserts auf die neuen Birch-Mults (1.68 / 1.34 / 2.22, gerundet ok); `SCHOOL_SCALE` 0.50 und `HOUSE_SCALE` 0.38 unverändert; Birch-a visual height = `tex_h * SCHOOL_SCALE * BIRCH_A_SCALE_MULT` ±15%
- Playtest: Campus Birch visuell neben Häusern im selben Maß; kein Asphalt unter den drei Trakten, Hof frei

## Akzeptanz

- `BIRCH_A_SCALE_MULT` / `BIRCH_B_SCALE_MULT` / `BIRCH_TURNHALLE_SCALE_MULT` locked at **1.68 / 1.34 / 2.22** (lower only if asphalt/Hof overlap; document actuals here)
- `HOUSE_SCALE` 0.38 and `SCHOOL_SCALE` 0.50 unchanged; neighbor campus Mults unchanged
- Suite green: Birch Mult asserts, Birch-a visual height, off-road clearance for the three Birch tracts
