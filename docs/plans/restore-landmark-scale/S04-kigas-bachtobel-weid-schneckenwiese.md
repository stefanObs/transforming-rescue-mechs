# Slice: S04 — Seuzach-Kigas Bachtobel + Weid + Schneckenwiese

**Parent:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Die drei Seuzach-Kindergärten Bachtobel, Weid und Schneckenwiese sind wieder korrekt ausgerichtet und grob stimmig groß gegenüber Strasse und Nachbarschaft — validiert gegen Google Maps / Street View. Drei gleiche Landmark-Typen, ein Placement-System, zusammen review-/playtestbar.

## In diesem Schritt

- Rotation/Facing und Größe für Kiga Bachtobel vs. Maps/Street View
- Dasselbe für Weid und Schneckenwiese
- Keine Änderung am Ohringen-Kiga (S03)

## Nicht (andere Feature-Schritte)

- Schul-Campi; Kiga Ohringen; Bahnhof/Badi
- Globale Scale-Konstanten (S01); neue Wohnhäuser

## Art (optional, damit Planner übersprungen werden kann)

- nein — bevorzugt Rotation/Scale im Code; Art nur bei falschem Sprite-Facing

## Testplan (optional, 2 Bullets)

- Suite: alle drei Kiga-Nodes vorhanden; sinnvolle Rotation/Scale-Checks
- Playtest: Bachtobel, Weid, Schneckenwiese lesbar; Ausrichtung/Größe vs. Maps/Street View grob stimmig
