# Slices: assets-clear-of-streets

**Status:** Entwurf  
**Aufgabe:** Placement und Ausrichtung aller Welt-Assets so, dass nichts RoadKit-Asphalt überlappt.  
**Datum:** 2026-08-12  
**Zuschnitt:** zwei verwandte Inkremente — zuerst gemeinsame Off-Road-Clearance für alle Gebäude-Props, dann Alignment-Politur inkl. Wälder/übrige Props

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-buildings-off-road.md` | Einheitliche Off-Road-Clearance für Häuser und Landmarken | — | erledigt |
| S02 | `S02-props-alignment-polish.md` | Facing/Setback-Konsistenz + Wälder/übrige Props freihalten von Strassen | S01 | offen |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- RoadKit / `seuzach_roads.json` neu zeichnen oder Asphalt-Geometrie umbauen
- Alle OSM-Landmarken weit wegschieben (nur Clearance/Setback/Footprint anpassen)
- Neue Art für alle Gebäude / komplette Housing-Welle
- Review / Tests / Playtest / Git als eigene Slices
