# Slices: schema-village-map

**Status:** Entwurf  
**Aufgabe:** OSM-Seuzach archivieren, Swisstopo-Karten entfernen, Live-`world_sandbox` auf ein kompaktes Schema-Dorf umstellen (nur H/V/45°-Straßen, bestehende `_ew`-Art, keine Überlappung, nicht GPS-genau).  
**Datum:** 2026-09-03  
**Zuschnitt:** S01 Prozess/Archiv als ein Thema; S02–S06 je zwei zusammengehörige spieler-sichtbare Inkremente (Netz+Spawn, Civic+Läden, zwei Schul-Campus, Nord/SE-Anker, Housing+Wald)

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-archive-drop-swisstopo.md` | OSM-Live archivieren, Swisstopo-Karten weg, Docs/Regeln + restore-stripped-landmarks überholt | — | in Arbeit |
| S02 | `S02-schema-streets-live.md` | Schema-Straßen (H/V/45°) live, Spawn Hauptstrasse, Schienen-Stub | S01 | offen |
| S03 | `S03-dorfkern-laeden.md` | Dorfkern Civic + Läden/Sport/Spielplatz, Occupancy, `_ew` | S02 | offen |
| S04 | `S04-schulen-birch-rietacker.md` | Campus Birch + Campus Rietacker inkl. zugehörige Kigas `_ew` | S03 | offen |
| S05 | `S05-bahnhof-badi-ohringen-hub.md` | Bahnhof+Gleis, Badi, St. Martin + Ohringen-Campus/Kiga, Hub+Tankstelle+Enter | S04 | offen |
| S06 | `S06-housing-wald.md` | EW-Häuser an Haupt-/Wohnstrasse, Waldrand, volle Overlap-Suite | S05 | offen |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Layout (alle Slices)

- Kompakte Welt ~**80×60 Felder**, Origin **Kirche** (0,0)
- **Hauptstrasse** EW durch (0,0), Hauptachse
- **Stationsstrasse** NS östlich des Kerns; Bahnhof/Badi nördlich
- **Ohringerstrasse** 45° SE → St. Martin, Ohringen-Campus, Hub/Tankstelle am Ende
- **Schulstrasse** EW südlich → Birch / Rietacker
- **Wohnstrasse** EW nördlich → Housing
- Nur **bestehende PNGs**, keine neue Art; Bearing **`_ew` erzwingen**
- Occupancy-AABBs: nichts überlappt
- Nicht GPS-genau; **nicht** `data/seuzach_roads_octilinear.json` als Live-Netz

## Nicht in dieser Aufgabe

- Neue Art / `_ns` aus `_ew` rotieren
- `seuzach_roads_octilinear.json` als Live-Quelle umschalten
- OSM/GPS-genaue Platzierung oder Swisstopo-QA als Ground Truth für die Live-Welt
- Review, Tests, Playtest, Git als eigene Slices
