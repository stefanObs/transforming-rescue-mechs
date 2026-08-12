# Slices: sprites-clear-street-aligned

**Status:** Entwurf  
**Aufgabe:** Gebäude-/Schul-Sprites nicht mehr über RoadKit-Asphalt malen; hart freiräumen und strassen-ausgerichtete Style-C-Art (keine Schräge zur lokalen Strasse).  
**Datum:** 2026-08-12  
**Zuschnitt:** zwei verwandte Inkremente — zuerst harte Visual-Clearance + Agent-Regeln, dann Bearing-Art + Placement-Auswahl

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-hard-clearance-agent-rules.md` | Harte Visual-Clearance aller Building-Props + Subagent-Regeln (nie Asphalt übermalen; street-aligned Art) | — | erledigt |
| S02 | `S02-bearing-aligned-building-art.md` | Style-C street-aligned Haus-/Schul-Varianten für Haupt-Bearings + Placement per Road-Tangent | S01 | erledigt |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- RoadKit / `seuzach_roads.json` neu zeichnen; Iso komplett auf Top-Down drehen
- Jede Landmark-PNG regenerieren; komplette Housing-Welle / ganz Seuzach
- Review / Tests / Playtest / Git als eigene Slices
- Ersetzt nicht: `assets-clear-of-streets` / `houses-street-aligned` (v0.33.x Clearance 0.55×0.35 + street-ribbon reichte nicht)
