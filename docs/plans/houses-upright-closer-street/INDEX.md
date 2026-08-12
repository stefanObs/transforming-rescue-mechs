# Slices: houses-upright-closer-street

**Status:** Entwurf  
**Aufgabe:** Häuser stehen wieder aufrecht (NS nicht mehr 90°-gedreht) und sitzen enger an der Strasse, ohne Asphalt zu übermalen.  
**Datum:** 2026-08-12  
**Zuschnitt:** eine User-Beschwerde = zwei verwandte Inkremente in einem Slice (NS-Art aufrecht + engeres Setback)

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-ns-upright-tighter-setback.md` | NS-Haus-Art aufrecht (Fassade links) + engere Street-Clearance ohne Asphalt-Overlap | — | erledigt |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- RoadKit / `seuzach_roads.json` neu; Iso-Kamera drehen
- Alle Landmarken / Schulen / ganz Seuzach neu befüllen
- EW-Haus-Art von Grund auf neu (nur retuschieren wenn nötig)
- Review / Tests / Playtest / Git als eigene Slices
- Ersetzt nicht: `sprites-clear-street-aligned` (S01 Clearance + S02 Bearing-Wiring bleiben Basis; dieser Slice korrigiert NS-Art-Fehler und zu weites Setback)
