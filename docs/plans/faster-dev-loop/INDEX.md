# Slices: faster-dev-loop

**Status:** Erledigt  
**Aufgabe:** Entwicklungsloop beschleunigen: ~2× Feature-Arbeit pro Slice und doppelte Arbeit streichen, ohne merkbaren Qualitätsverlust.  
**Datum:** 2026-08-12  
**Zuschnitt:** Prozess/Docs ein Thema = ein Slice (Packing + Dedup zusammen)

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der volle Entwicklungsablauf (Plan → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-pack-and-dedup-dev-loop.md` | Gröbere Slices + weniger Doppelarbeit im Loop | — | erledigt |

Status: `offen` → `in Arbeit` → `erledigt` (nach Phase-4-Pass + Git).

## Nicht in dieser Aufgabe

- Godot-Gameplay, Art-PNGs, Kamera, Feldmaß
- Code-Review oder Playtest für spielsichtbare Slices abschaffen oder zusammenlegen
- Git-pro-Slice abschaffen
- Historische erledigte Slice-Files unter `docs/plans/m3-*` umschreiben
