# Slice: S03 — Ohringen Campus + Kiga Ausrichtung

**Parent:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Schul-Campus Ohringen und Kindergarten Ohringen (gleiche Ortsteil-Zelle) haben grob korrekte Ausrichtung und Größenverhältnisse zueinander und zur lokalen Strasse — validiert gegen Google Maps / Street View.

## In diesem Schritt

- Ohringen-Campus: Rotation/Facing und relative Trakt-Größen vs. Maps/Street View
- Kiga Ohringen: Ausrichtung und Größe relativ zu Campus/Strasse vs. Maps/Street View
- Ohringen bleibt eigene Rasterzellen; keine Seuzach-Kiga-Änderungen

## Nicht (andere Feature-Schritte)

- Birch/Rietacker (S02); Bachtobel/Weid/Schneckenwiese (S04); Bahnhof/Badi (S05)
- Globale Scale-Konstanten (S01); neue Wohnhäuser

## Art (optional, damit Planner übersprungen werden kann)

- nein — bevorzugt Rotation/Scale im Code; Art nur bei falschem Sprite-Facing

## Testplan (optional, 2 Bullets)

- Suite: Ohringen-Campus-Cluster und Kiga-Ohringen vorhanden; sinnvolle Rotation/Scale-Checks
- Playtest: beide Landmarks in Ohringen lesbar; Ausrichtung/Relativgröße vs. Maps/Street View grob stimmig
