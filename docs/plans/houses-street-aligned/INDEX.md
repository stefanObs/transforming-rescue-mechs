# Slices: houses-street-aligned

**Status:** Entwurf  
**Aufgabe:** Bestehende Wohnzeilen (S01/S02 Housing) realistischer an Strassenbänder ausrichten; neue Style-C-Art nur soweit nötig.  
**Datum:** 2026-08-12  
**Zuschnitt:** zwei verwandte Inkremente — zuerst Placement/Facing per Code, dann Art-Varianten nur wenn authored Fronts nicht passen

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-side-aware-street-facing.md` | Seitenbewusstes Ausrichten + Setback an bestehenden Housing-Korridoren | — | in Arbeit |
| S02 | `S02-street-facing-house-art.md` | Style-C Facing-Varianten / korrigierte Haus-Fronts für Strassen-Ausrichtung | S01 | offen |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Neue Housing-Welle / gesamtes Seuzach neu befüllen
- Landmarken-Scales (`SCHOOL_SCALE` / `LANDMARK_SCALE`) oder Spawn-Zoom ändern
- Ein Art-File pro Haus als eigener Slice; Review / Tests / Playtest / Git als eigene Slices
