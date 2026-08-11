# Slice: S05 — Bahnhof + Badi Ausrichtung

**Parent:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Bahnhof Seuzach und Badi/Weiher (zwei Civic-Landmarks) haben grob korrekte Ausrichtung und Größenverhältnisse zur Strasse bzw. zueinander — validiert gegen Google Maps / Street View.

## In diesem Schritt

- Bahnhof: Rotation/Facing und Größe vs. Maps/Street View (Gleis-/Strassenbezug grob stimmig)
- Badi: Ausrichtung und Größe vs. Maps/Street View
- Bestehende Landmark-Sprites; Tracks/Wasser-Layout nicht neu bauen

## Nicht (andere Feature-Schritte)

- Schul-Campi und Kigas (S02–S04)
- Globale Scale-Konstanten (S01); Gleisnetz/Bäche neu legen; neue Wohnhäuser

## Art (optional, damit Planner übersprungen werden kann)

- nein — bevorzugt Rotation/Scale im Code; Art nur bei falschem Sprite-Facing

## Testplan (optional, 2 Bullets)

- Suite: Bahnhof- und Badi-Nodes vorhanden; sinnvolle Rotation/Scale-Checks
- Playtest: beide Civic-Landmarks lesbar; Ausrichtung/Größe vs. Maps/Street View grob stimmig
