# Slices: octilinear-seuzach-gmaps

**Status:** Entwurf  
**Aufgabe:** Driveable Seuzach+Ohringen-Straßen aus Google Maps als GMaps-Trace digitalisieren und octilinear (H/V/45°) als JSON + großes SVG ausgeben — ohne Sandbox umzuschalten.  
**Datum:** 2026-08-30  
**Zuschnitt:** Zwei zusammengehörige Data/Tooling-Inkremente (Trace-Quelle → Generator+Artefakte+Docs); ein Thema, sauber trennbar

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-gmaps-road-trace.md` | GMaps-Trace Seuzach+Ohringen (WGS84, Klassen, Namen) | — | erledigt |
| S02 | `S02-octilinear-gen-svg-docs.md` | Octilinear-Generator → JSON + SVG + data/README | S01 | in Arbeit |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Review, Tests, Playtest, Commit/Push/Tag als eigene Slices
- `world_sandbox` / Spielwelt auf das neue JSON umschalten
- `data/seuzach_roads.json` oder `data/seuzach_ways.json` als Geometrie-Quelle nutzen
- CLIP / Kirche-Origin / FIELD_M / FIELD_WU neu erfinden (nur aus bestehender Welt übernehmen)
