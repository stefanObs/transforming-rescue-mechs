# Slice: S01 — Civic churches + Forrenberg hub/tankstelle

**Parent:** `docs/plans/restore-stripped-landmarks/INDEX.md`  
**Überholt:** Civic kommt in `docs/plans/schema-village-map/` (S03/S05), nicht OSM-GPS.  
**Hängt ab von:** —

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Spieler sieht wieder die Dorfkern-Civic-Landmarks (Kirche Seuzach, St. Martin, Feuerwehr, Gemeindehaus) und am Forrenberg Hub-Station plus Tankstelle — an OSM-/GPS-tauglichen Positionen mit Clearance, nicht an alten stilisierten Dorfkern-Coords.

## In diesem Schritt

- `kirche_seuzach`, `kirche_st_martin`, `feuerwehr`, `gemeindehaus` als Props unter `%Props` via `_add_building_prop` (bestehende PNGs)
- `hub_station` + `tankstelle` bei Forrenberg (`SeuzachGeo.forrenberg_world()` / GPS); Spacing wie Occlusion-Test erwartet
- Positionen über `gps_to_world` oder reale Offsets von Ankern (Kirche ≈ 0,0, Forrenberg, Bahnhof, Badi) — keine Legacy-Dorfkern-`Vector2`-Skala
- Clearance: Platzierung nudgen/überleben, wenn `BUILDING_CLEAR` sonst `null` liefert
- Landmark-Tests / Occlusion-Assertions für Hub+Tankstelle und Civic-Counts anpassen (Schulen/Bahnhof/Badi-Counts nicht verwässern)

## Nicht (andere Feature-Schritte)

- Restaurants, Läden, Sportplatz, Spielplatz (S02)
- Schulen, Kigas, Bahnhof, Badi, Forests, Housing neu legen
- Neue Art generieren

## Art (optional, damit Planner übersprungen werden kann)

- nein — Assets auf Disk (`landmark_kirche_seuzach`, `landmark_kirche_st_martin`, `landmark_feuerwehr_seuzach`, `landmark_gemeindehaus_seuzach`, `hub_station`, `landmark_tankstelle_seuzach`); nur Re-Wire

## Testplan (optional, 2 Bullets)

- Landmarks-Test: alle sechs IDs vorhanden; Hub↔Tankstelle-Abstand ≥ Occlusion-Minimum; kein Crash bei Clearance-Nudge
- Playtest: Kirche/Feuerwehr/Gemeinde im Dorfkern-Quadranten lesbar; Hub+Tankstelle am Forrenberg sichtbar und betretbar/erreichbar
