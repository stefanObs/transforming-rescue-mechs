# Slice: S02 — Props alignment & non-building clearance

**Parent:** `docs/plans/assets-clear-of-streets/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht konsistente Strassen-Ausrichtung der Bebauung (Facing/Setback) und Wälder sowie andere Nicht-Gebäude-Props, die den RoadKit-Asphalt nicht überdecken. Nach S01-Gebäude-Clearance: Alignment-Politur + Off-Road für Forests/übrige Props wo nötig.

## In diesem Schritt

- Facing / setback Konsistenz entlang Housing-Korridoren (side-aware Flip, stabile Curb-Distanz) nach S01-Clearance-Änderungen
- Forests und andere Nicht-Gebäude-Props prüfen und freiräumen, falls sie Asphalt überlappen (Streams/Rails nur anfassen wenn sichtbar auf der Fahrbahn)
- Sichtbare Strassenkorridore bleiben lesbar — Props säumen, überdecken nicht

## Nicht (andere Feature-Schritte)

- Gebäude-Clearance-Helper / Haus+Landmark-Overlap-Fixes (→ S01)
- RoadKit neu zeichnen; alle Wälder neu generieren; neue Landmarken-Art
- Spawn-Zoom oder globale Scale-Rewrites ohne Overlap-Bedarf

## Art

- nein — Placement/Alignment nur; Art nur wenn ein Prop ohne Code-Shift unrettbar auf Asphalt sitzt (dann minimal, Style C)

## Testplan

- Nach Placement: Forests (und betroffene Props) nicht auf named RoadKit asphalt; Housing facing/setback weiterhin konsistent
- Playtest: Korridore lesbar, keine Prop-Platten auf der Fahrbahn
