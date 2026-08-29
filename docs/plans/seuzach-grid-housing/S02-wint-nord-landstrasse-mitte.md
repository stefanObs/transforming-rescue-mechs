# Slice: S02 — Winterthurer-Nord + Landstrasse-Mitte

**Parent:** `docs/plans/seuzach-grid-housing/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht Wohnbebauung entlang **Winterthurerstrasse nordwärts** (**WINT-NORD**) und dem verbundenen **Landstrasse-Mitte**-Band (**LAND-MITTE**) — maps-plausibel Richtung Badi-Korridor, ohne die Badi neu zu bauen.

## In diesem Schritt

- Housing-Zellen **WINT-NORD** und **LAND-MITTE** (Feldspannen INDEX)
- Straßenbindung: Winterthurerstrasse (Nordsegment) + Landstrasse (Mitte); lokale Nebenachsen nur wenn sie das Band schneiden
- S01-Quartier-API nutzen; Clearance zu Landmarken (Badi, Campi) einhalten

## Nicht (andere Feature-Schritte)

- Stationsstrasse / Bahnhof, Reutlinger, Breite/Seebühl, Ohringen
- Badi-Gebäude oder Sport-Landmarken
- KIRCHE-KERN / WINT-WEST nochmal umbauen (nur Anbindung)

## Art

- nein — bestehende House-Assets

## Testplan

- Teleport/Drive: Häuser in WINT-NORD und LAND-MITTE sichtbar, off-road, entlang der Bänder
- Keine Housing-Props auf Badi-/Campus-Footprints
