# Slice: S02 — Housing Kirche-/Schneckenwiese-Nahkorridore

**Parent:** `docs/plans/buildings-visible-at-play/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (zwei zusammengehörige spieler-sichtbare Inkremente: Korridor Richtung Kirche + Korridor Richtung Schneckenwiese / benachbarte Hauptachsen nahe Spawn). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Vom Winterthurer-Spawn aus liest sich die Umgebung **weiter bewohnt**, wenn der Spieler entlang der nahen Hauptkorridore fährt (Richtung Kirche und Richtung Schneckenwiese / verbindende Achsen) — nicht nur ein bewohnter Spawn-Fleck und danach leeres Grün.

## In diesem Schritt

- Wohnzeilen entlang des **Kirche-Nahkorridors** (z. B. Kirchgasse / Achsen Richtung Kirchen-Ursprung), die vom Spawn aus erreichbar/sichtbar anschließen
- Wohnzeilen entlang des **Schneckenwiese-/Ost-Nahkorridors** (Richtung Kiga Schneckenwiese bzw. verbindende Straßenbänder), ohne den Kiga selbst zu verschieben
- Dieselbe Placement-Regeln wie S01 (bestehende `house_*.png`, Bänder entlang Strassen, Spacing/Occlusion); Dichte Maps-/Street-View-plausibel, kein Voll-Seuzach
- Landmarken bleiben an OSM-Positionen und map-Größe; optional kurze „bewohnte Route“ bis man eine Landmarke ahnt — Schwerpunkt bleibt Housing, nicht Landmark-Teleport

## Nicht (andere Feature-Schritte)

- Gesamte Siedlung / Ohringen / Bahnhof-/Badi-Umkreis als Housing-Welle
- Neue Haus-Art; `SCHOOL_SCALE`/`LANDMARK_SCALE`-Rollback; Spawn verlegen
- S01-Spawn-Viewport neu erfinden (dort schon bewohnt)

## Art

- nein — bestehende Haus-Assets; Placement erweitern

## Testplan

- Suite: `./scripts/run_tests.sh` — `house_n >= 20`; Meta `housing_corridor` ∈ {kirche, schneckenwiese} mit je ≥4 Props; S01-Spawn-Viewport ≥3 Häuser; Landmark-Counts/Scales unverändert; neue Häuser off-road
- Play: kurze Fahrt vom Spawn Richtung Kirche und Richtung Schneckenwiese — Häuser entlang der Strasse, kein leeres Grünband

## Akzeptanz

- [ ] Shared `_place_housing_along_roads` (oder Erweiterung) platziert Kirche- und Schneckenwiese-Nahkorridore
- [ ] Kirchgasse (+ Winterthurer-Anbindung) und Reutlinger-/Schneckenwiesen-/Winterthurer-Nord bewohnt im ersten ~1,2–2 km
- [ ] `HOUSE_SCALE` 0.38; keine Landmark-/Spawn-/Zoom-Verschiebung; kein Voll-Seuzach
- [ ] Suite grün inkl. S01-Spawn-Viewport und S02-Corridor-Metas

Playtest 2026-08-12: Pass — spawn/kirche/schneckenwiese corridor shots; 68 houses total.
