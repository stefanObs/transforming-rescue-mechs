# Slice: S02 — Campus Rietacker an Ohringerstrasse

**Parent:** `docs/plans/schools-kigas-street-side/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (Campus-Cluster an Ohringerstrasse + Turnhalle an Turnerstrasse). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Campus **Rietacker** sitzt **nördlich** der Ohringerstrasse (Südfassade zur Strasse); die Turnhalle steht westlich an der Turnerstrasse. Sprites street-aligned wie Birch (`_ew`/`_ns` + Helper-`flip_h`), nicht Iso-Diamant.

## In diesem Schritt

- S01-Helper wiederverwenden (Bearing, GPS-Strassenseite, Flip, Setback) — nur die drei Rietacker-Props verdrahten
- `schulhaus_rietacker_a` / `_b`: GPS-Bank **north** of Ohringerstrasse halten; Fassade süd zur Strasse
- `turnhalle_rietacker`: westlich an Turnerstrasse (lange Achse zur lokalen Tangente)
- Style-C `_ew`/`_ns` nur für Rietacker; `_ns` nie aus `_ew` rotieren; `rotation == 0`
- RoadKit nur anfassen, wenn eine Rietacker-Polyline den Campus nicht erreicht (Default: Ohringer/Turner reichen)

## Nicht (andere Feature-Schritte)

- Campus Birch (S01), Ohringen + Kiga (S03), Seuzach-Kigas (S04)
- Wohnhäuser, Bahnhof/Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz; globales `SCHOOL_SCALE`; `Sprite2D.rotation`

## Art

- ja — nur Rietacker, Style C street-aligned:
  - `landmark_schulhaus_rietacker_a_ew.png` / `landmark_schulhaus_rietacker_a_ns.png`
  - `landmark_schulhaus_rietacker_b_ew.png` / `landmark_schulhaus_rietacker_b_ns.png`
  - `landmark_turnhalle_rietacker_ew.png` / `landmark_turnhalle_rietacker_ns.png`

## Testplan

- Suite: drei Rietacker-Props; a/b nördlich Ohringerstrasse, Turnhalle westlich Turnerstrasse; Bearing + Flip; Birch-S01 und Ohringen/Kigas unverändert
- Playtest: Schulhaus-Fassade zur Ohringerstrasse, Sporthalle zur Turnerstrasse, Hof zwischen den Trakten, keine Iso-Ecke
