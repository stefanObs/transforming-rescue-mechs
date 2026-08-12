# Slice: S01 — Seitenbewusstes Strassen-Facing + Setback

**Parent:** `docs/plans/houses-street-aligned/INDEX.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (zwei zusammengehörige spieler-sichtbare Inkremente: (1) Fassaden zur Strasse auf **beiden** Seiten, (2) realistischer Abstand/Spacing ohne Asphalt/Stacking — über die bestehenden Winterthurer- + Kirche-/Schneckenwiese-Korridore). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Entlang der bereits platzierten Wohnzeilen lesen sich Häuser wie an Strassenbändern: lange/vordere Fassade zur Strasse (beide Seiten), Häuser sitzen im Band neben dem Asphalt — nicht drauf, nicht chaotisch gestapelt, nicht zufällig gespiegelt.

## In diesem Schritt

- `_place_housing_along_roads`: seitenbewusstes Facing (`flip_h` / Side-Meta aus Tangent+Perp), **kein** dekoratives `house_i % 3`-Flip; **kein** `Sprite2D.rotation` das Iso bricht
- Setback/Spacing/Footprint so, dass Häuser klar neben dem RoadKit-Band stehen (off-road, kein Überlappen/Stacking) auf Spawn- und Nahkorridoren
- Bestehende `house_*.png` und Korridor-Abdeckung behalten; nur Placement/Facing/Abstand

## Nicht (andere Feature-Schritte)

- Neue Haus-Art / Facing-Varianten regenerieren (→ S02, nur wenn Code nicht reicht)
- Weitere Strassen mit Housing füllen; Landmark-Scales; Voll-Seuzach

## Art

- nein — Placement/Facing mit vorhandenen Assets; Art erst in S02 wenn Playtest zeigt, dass Fronts iso-seitig falsch bleiben

## Ziel

Wohnzeilen an Winterthurer-/Kirche-/Schneckenwiese-Korridoren: beide Seiten mit Fassade zur Strasse (`flip_h` aus Tangent+Perp), stabiler Setback neben dem Asphalt, Meta `street_side` / `faces_street`.

## Akzeptanz

- [ ] Kein dekoratives `(house_i % 3)`-Flip; kein `Sprite2D.rotation` an Häusern
- [ ] `flip_h` maximiert Door-Dir · toward_road (authored SW / mirrored SE)
- [ ] Stabiles Setback-Slack (konstant, z. B. 24); off-road Clearance bleibt
- [ ] Meta: `street_side` ±1, `faces_street` true; `housing_corridor` / `house_variant` unverändert
- [ ] Suite: Spawn-Corridor hat beide `street_side`; je Seite Mehrheit `flip_h` konsistent; Counts/Viewport/off-road grün
- [ ] HOUSE_SCALE / Landmark-Scales / Spawn unverändert; keine neuen PNGs

## Testplan

- Suite: Housing-Counts/Corridor-Metas und off-road-Clears bleiben grün; Assertions zu side-aware `flip_h` / Meta (kein Random-Flip)
- Play: Spawn + kurze Kirche-/Schneckenwiese-Fahrt — beide Straßenseiten mit Fassade zur Strasse, Häuser im Band neben Asphalt

Playtest 2026-08-12: Pass — side-aware flip + setback; residual iso needs S02 art.
