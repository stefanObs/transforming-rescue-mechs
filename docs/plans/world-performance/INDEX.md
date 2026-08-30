# Slices: world-performance

**Status:** Erledigt  
**Aufgabe:** World-Load und FPS so verbessern, dass das Spiel in Sekunden statt Minuten startet und flüssiger läuft — gleiche Kartenoptik.  
**Datum:** 2026-08-30  
**Zuschnitt:** Zwei verwandte spieler-sichtbare Inkremente (schneller Build aller Quartiere → Streaming + Runtime-Glättung)

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-fast-world-build.md` | Schneller World-Build (Load in Sekunden, volle Karte) | — | erledigt |
| S02 | `S02-stream-map-smoother-play.md` | Lazy Housing + weniger Nodes/HUD-Last für bessere FPS | S01 | erledigt |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Review, Tests, Playtest, Commit/Push/Tag als eigene Slices
- Kartenoptik / Layout / Housing-Platzierung ändern (nur Performance)
- Streaming vor dem schnellen Full-Build (S01 legt alle Quartiere, damit S02 hitch-light bleibt)
