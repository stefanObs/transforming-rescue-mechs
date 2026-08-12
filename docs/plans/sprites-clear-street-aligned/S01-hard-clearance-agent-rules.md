# Slice: S01 — Harte Clearance + Agent-Regeln

**Parent:** `docs/plans/sprites-clear-street-aligned/INDEX.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (zwei zusammengehörige Inkremente: (1) harte visuelle Freihaltung aller Building-Props vom Asphalt, (2) dauerhafte Subagent-Regeln dagegen). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht Häuser **und** Schulen/Kigas/Bahnhof/Badi/Feuerwehr klar neben dem RoadKit-Asphalt — Comic-Sprites übermalen die Fahrbahn nicht mehr. Subagenten (Implementer, Playtester, comic-rettung-art, ggf. Planner) kennen die Regel „nie auf RoadKit-Asphalt malen“ und street-aligned Art-Erwartungen.

## In diesem Schritt

- Visual clearance für **alle** Building-Props (Häuser + school_cluster / Kigas / Bahnhof / Badi / Feuerwehr) auf **nahe voller Sprite-Bounds** (deutlich stärker als v0.33 `BUILDING_CLEAR_W/H_FRAC` 0.55/0.35) + stärkeres Setback/Nudge senkrecht zur Strasse
- Tests an die neuen Fracs/Margins anpassen; BuildingCollision-Walk-Footprint (0.20/0.10) unangetastet
- Subagent-Docs updaten: `.cursor/agents/feature-implementer.md`, `godot-playtester.md`, `comic-rettung-art.md`, ggf. `feature-planner.md` — „never paint on RoadKit asphalt“ + street-aligned building art (lange Fassade // lokale Strasse; `c-iso-city-map` nur Layout)

## Nicht (andere Feature-Schritte)

- Neue Bearing-Varianten / Placement per Road-Tangent (→ S02)
- RoadKit-Geometrie umbauen; alle Landmark-PNGs regenerieren; Iso→Top-Down

## Art

- nein — Placement/Clearance + Docs; Art erst in S02

## Testplan

- Suite: visual clear (nahe Sprite-AABB) für Häuser **und** Landmarken vs. named RoadKit-Polylines grün; Counts/Viewport unverändert sinnvoll
- Play: Spawn + Birch/Bahnhof — Sprite-Farbe nicht auf Asphalt; Collision-Fuß wie bisher

## Akzeptanz

- [ ] `BUILDING_CLEAR_*` nahe voller Sprite (0.95/0.88 + margin 40); nudge max 700
- [ ] Häuser + Landmarken off named roads (AABB); BuildingCollision 0.20/0.10 unangetastet
- [ ] Spawn ≥3 Häuser; `house_n >= 12` wenn möglich
- [ ] Subagenten/Regel: nie Asphalt übermalen; street-aligned bearing (keine Gebäude-Rotation)
- [ ] `./scripts/run_tests.sh` grün

## Review-Fixes (Approve with fixes)

- Clear-AABB auf visuellen Body zentriert (`visual_center_y = -tex_h·|scale.y|·0.5`), nicht `feet_y = -clear.y·0.25`
- Housing nach Nudge: Sep/Landmark/Spawn erneut prüfen; `street_side`/`flip_h` aus genudgter Position vs. nächster Strasse
- `_add_building_prop`: bei weiter fehlender Clearance → `null` (kein Asphalt-Place)