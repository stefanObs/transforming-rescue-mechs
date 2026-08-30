# Slices: octilinear-seuzach-gmaps

**Status:** In Arbeit  
**Aufgabe:** Driveable Seuzach+Ohringen-Straßen aus Google Maps / Swiss-Raster als Trace digitalisieren und octilinear (H/V/45°) als JSON + großes SVG ausgeben — Geometrie-QA (Junctions, Knicke, Parallel-Abstand) ohne Sandbox umzuschalten.  
**Datum:** 2026-08-30  
**Zuschnitt:** Zwei zusammengehörige Data/Tooling-Inkremente pro Slice; S06+ = Geometrie-Qualität am Generator-Output

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-gmaps-road-trace.md` | GMaps-Trace Seuzach+Ohringen (WGS84, Klassen, Namen) | — | erledigt |
| S02 | `S02-octilinear-gen-svg-docs.md` | Octilinear-Generator → JSON + SVG + data/README | S01 | erledigt |
| S03 | `S03-connect-dense-octilinear.md` | Verbundenes Netz + dichtere GMaps-Coverage | S02 | erledigt |
| S04 | `S04-swiss-raster-octilinear-redo.md` | Octilinear-SVG neu aus Swiss Raster 1072-1+1052-3 | S03 | erledigt |
| S05 | `S05-ohringer-straight-hub-qa.md` | Ohringer begradigen + korrekte Hubs + Zoom-QA | S04 | erledigt |
| S06 | `S06-junction-corner-geometry.md` | Saubere Treffpunkte + sinnvolle Straßen-Knicke | S05 | erledigt |
| S07 | `S07-parallel-street-spacing.md` | Zu dichte Parallel-Straßen mergen oder trennen | S06 | erledigt |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Review, Tests, Playtest, Commit/Push/Tag als eigene Slices
- `world_sandbox` / Spielwelt auf das neue JSON umschalten
- `data/seuzach_roads.json` oder `data/seuzach_ways.json` als Geometrie-Quelle nutzen
- CLIP / Kirche-Origin / FIELD_M / FIELD_WU neu erfinden (nur aus bestehender Welt übernehmen)
