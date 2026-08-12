# Slices: buildings-visible-at-play

**Status:** Erledigt  
**Aufgabe:** Beim Spielen Wohnbebauung entlang der Strassen am Winterthurer-Spawn sichtbar machen (nicht „nur Strassen und Grün“).  
**Datum:** 2026-08-12  
**Zuschnitt:** zwei verwandte Housing-Korridore um den Spawn; bestehende `house_*.png`; Landmarks/Scale unangetastet

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-winterthurer-spawn-housing.md` | Wohnzeilen an Winterthurerstrasse + Nahstrassen im Spawn-Viewport | — | erledigt |
| S02 | `S02-near-spawn-corridor-housing.md` | Housing entlang Kirche-/Schneckenwiese-Nahkorridoren | S01 | erledigt |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Gesamtes Seuzach mit Housing füllen / alle Wohnstrassen
- Neue Haus-Art regenerieren (bestehende `house_*.png` nutzen)
- Landmarken zum Spawn ziehen oder `SCHOOL_SCALE` / `LANDMARK_SCALE` global zurück auf 0.22
- Spawn von Winterthurerstrasse wegverlegen (nur Mini-Nudge falls eine Hauszeile ihn braucht — Häuser zum Spawn bevorzugen)
- Review / Tests / Playtest / Git als eigene Slices
