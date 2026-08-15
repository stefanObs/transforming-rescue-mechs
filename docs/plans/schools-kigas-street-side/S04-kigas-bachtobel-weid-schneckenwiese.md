# Slice: S04 — Seuzach-Kigas Bachtobel + Weid + Schneckenwiese

**Parent:** `docs/plans/schools-kigas-street-side/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (drei gleiche Landmark-Typen, ein Placement-System). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Die drei Seuzach-Kindergärten sitzen an der richtigen Strassenseite mit street-aligned Fassade: Bachtobel **östlich** der Bachtobelstrasse (NS), Weid **südlich** der Weidstrasse (EW), Schneckenwiese **westlich** der Schneckenwiesenstrasse / nördlich der Reutlingerstrasse.

## In diesem Schritt

- S01-Helper wiederverwenden für `kiga_bachtobel`, `kiga_weid`, `kiga_schneckenwiese`
- GPS-Bank je Strasse halten (nicht über den Asphalt auf die Gegenbank)
- Schneckenwiese: an sichtbarer Strasse ausrichten (2-Punkt-Stub `Schneckenwiesenstrasse` und/oder Reutlingerstrasse-Nordbank) — Stub nur verlängern wenn der Kiga sonst nicht neben Asphalt sitzt
- Style-C `_ew`/`_ns` nur für diese drei Kigas; `_ns` nie aus `_ew` rotieren; `rotation == 0`

## Nicht (andere Feature-Schritte)

- Schul-Campi Birch/Rietacker/Ohringen; Kiga Ohringen (S03)
- Wohnhäuser, Bahnhof/Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz; globales `SCHOOL_SCALE`; `Sprite2D.rotation`

## Art

- ja — nur die drei Seuzach-Kigas, Style C street-aligned:
  - `landmark_kiga_bachtobel_ew.png` / `landmark_kiga_bachtobel_ns.png`
  - `landmark_kiga_weid_ew.png` / `landmark_kiga_weid_ns.png`
  - `landmark_kiga_schneckenwiese_ew.png` / `landmark_kiga_schneckenwiese_ns.png`

## Testplan

- Suite: drei Kiga-Props; Bachtobel ost von Bachtobelstrasse, Weid süd von Weidstrasse, Schneckenwiese west/nord der lokalen Strasse; Bearing + Flip; Campi + `kiga_ohringen` unverändert
- Playtest: jeder Kiga neben seinem Band, Fassade zur Strasse (nicht Iso-Ecke), Spielplatz/Eingang zur Curb lesbar
