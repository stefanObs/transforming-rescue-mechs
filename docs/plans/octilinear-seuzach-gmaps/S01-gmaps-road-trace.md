# Slice: S01 — GMaps road trace (Seuzach+Ohringen)

**Parent:** `docs/plans/octilinear-seuzach-gmaps/INDEX.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Es gibt eine eigenständige Digitalisierungsquelle `data/seuzach_roads_gmaps_trace.json`: befahrbare Straßenkorridore Seuzach+Ohringen aus Google Maps als WGS84-Waypoints, mit Straßennamen und Klasse (`motorway` / `main` / `collector` / `local`). Keine Geometrie aus den alten Road-JSONs.

## In diesem Schritt

- Driveable Korridore Seuzach+Ohringen aus Google Maps digitalisieren
- `data/seuzach_roads_gmaps_trace.json` mit lat/lon-Waypoints, named roads, class
- Geometrie **nicht** aus `data/seuzach_roads.json` oder `data/seuzach_ways.json` ableiten

## Nicht (andere Feature-Schritte)

- Octilinear-Skript, World-Unit-Konversion, Validierung (S02)
- Emit von `seuzach_roads_octilinear.json` / SVG (S02)
- `data/README.md`-Doku (S02)
- Sandbox auf neues Netz umschalten (out of scope)

## Art

- nein — reine Digitization/Data, keine Style-C-Assets

## Testplan

- Trace-Datei vorhanden; Roads haben Name + class + ≥2 WGS84-Waypoints; Ohringen-Korridore enthalten
- Spot-Check: Stichproben-Waypoints passen zu GMaps-Lage (nicht zu alter `seuzach_roads.json`-Geometrie als Quelle)
