# Slice: S03 — Ohringen Campus + Kiga an Schulstrasse

**Parent:** `docs/plans/schools-kigas-street-side/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (zwei verwandte Inkremente in derselben Ohringen-Zelle: Campus-Cluster + Kiga Ohringen). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Schul-Campus **Ohringen** und **Kiga Ohringen** sitzen **westlich** der Schulstrasse (NS); Fassaden zur Strasse. Die Turnhalle steht nördlich der Schaffhauserstrasse. Sprites street-aligned (`_ew`/`_ns` + S01-Helper), eigene Rasterzellen bleiben.

## In diesem Schritt

- S01-Helper wiederverwenden — vier Props: `schulhaus_ohringen_a` / `_b`, `turnhalle_ohringen`, `kiga_ohringen`
- a/b/kiga: GPS-Bank **west** of Schulstrasse halten; Fassade ost zur Strasse
- Turnhalle: **north** of Schaffhauserstrasse, Fassade süd zur Strasse
- Cluster-Count Campus = 3; Kiga ohne `school_cluster`; Parent `DistrictOhringen`
- Style-C `_ew`/`_ns` nur für diese vier Gebäude; `_ns` nie aus `_ew` rotieren; `rotation == 0`

## Nicht (andere Feature-Schritte)

- Campus Birch (S01), Rietacker (S02), Seuzach-Kigas Bachtobel/Weid/Schneckenwiese (S04)
- Wohnhäuser, Bahnhof/Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz; globales `SCHOOL_SCALE`; `Sprite2D.rotation`

## Art

- ja — nur Ohringen Campus + Kiga, Style C street-aligned:
  - `landmark_schulhaus_ohringen_a_ew.png` / `landmark_schulhaus_ohringen_a_ns.png`
  - `landmark_schulhaus_ohringen_b_ew.png` / `landmark_schulhaus_ohringen_b_ns.png`
  - `landmark_turnhalle_ohringen_ew.png` / `landmark_turnhalle_ohringen_ns.png`
  - `landmark_kiga_ohringen_ew.png` / `landmark_kiga_ohringen_ns.png`

## Testplan

- Suite: drei Campus-Props + `kiga_ohringen` unter `DistrictOhringen`; westlich Schulstrasse (Turnhalle nördlich Schaffhauserstrasse); Bearing + Flip; Birch/Rietacker/Seuzach-Kigas unverändert
- Playtest: Ohringen-Zelle, Fassaden zur Schulstrasse, Kiga südöstlich vom Campus als eigenes Gebäude, keine Iso-Ecke
