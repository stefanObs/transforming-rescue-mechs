# Slices: iso-map-interaction-not-dimensions

**Status:** Erledigt  
**Aufgabe:** `c-iso-city-map.png` gilt nur für Haus–Strasse-Interaktion; Proportionen und Spawn-Zoom wieder wie vor der Dimensions-Fehldeutung.  
**Datum:** 2026-08-11  
**Zuschnitt:** Prozess/Docs ein Thema; Kamera-Maßstab ein eigenes Gameplay-Stück

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der volle Entwicklungsablauf (Plan → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-iso-map-interaction-not-dimensions.md` | Iso-Karte = Haus–Strasse, nicht Masse/Kamera | — | erledigt |
| S02 | `S02-restore-spawn-zoom.md` | Spawn-Kamera wieder Zoom 0.9 | S01 | erledigt |

Status: `offen` → `in Arbeit` → `erledigt` (nach Phase-4-Pass + Git).

## Nicht in dieser Aufgabe

- Landmarken-/Dach-PNGs neu erzeugen oder Dachformen zurückdrehen
- Feldmaß 5,3 m / 100 wu umkehren
- Häuser setzen oder Housing
- Game-SCALE (`PROP`/`SCHOOL`/`LANDMARK`/`SPRITE`) ändern (die haben sich bei v0.24.4 nicht geändert)
