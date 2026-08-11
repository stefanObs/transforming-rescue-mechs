# Slices: art-ref-isometric-city-map

**Status:** Erledigt  
**Aufgabe:** Iso-Stadt-Kartenbild als zusätzliche Grafik-Orientierung ablegen und in Stil-C-Workflow (Bible, Art-Subagent, Regeln) verdrahten — ohne Bestands-Art neu zu erzeugen.  
**Datum:** 2026-08-11  
**Raster / Zuschnitt:** n/a (Prozess/Art-Referenz; keine Karten- oder Häuser-Slices)

Der Hauptagent arbeitet **nur den nächsten offenen Slice** mit dem vollen Ablauf (Plan → Implement → Review → Playtest → Git) ab. Kein Überspringen, kein Parallel-Merge mehrerer Slices in einen Commit.

## Raster (falls Karte)

| Zelle | Felder (ix, iy) | Inhalt kurz |
|-------|-----------------|-------------|
| — | n/a | Keine Weltzellen. Lieferumfang = Design-Ref-PNG + Prozess-Docs. |

## Reihenfolge

| ID | Datei | Titel | Hängt ab von | Status |
|----|-------|-------|----------------|--------|
| S01 | `S01-save-iso-city-map-ref.md` | Iso-Stadt-Kartenbild unter `docs/design-refs/` speichern | — | erledigt |
| S02 | `S02-wire-iso-city-ref-into-c.md` | Ref in Style-Bible C, Art-Subagent und Cursor-Regel verdrahten | S01 | erledigt |

Status je Slice: `offen` → `in Arbeit` → `erledigt` (nach Phase-4-Pass + Git-Tag).

## Nicht in dieser Aufgabe

- Häuser, Landmarken, Tiles, Walk/Transform-Frames neu zeichnen oder alle `assets/art/`-PNGs regenerieren
- Stil A/B wiederbeleben oder Stil C als verbindlichen Look ersetzen (die Iso-Stadt-Karte **orientiert** Welt/Karte/Gebäude; sie **ist nicht** die neue Style-Bible)
- Seuzach-/Ohringen-Raster, RoadKit, Housing, Spawn
- `docs/KONZEPT.md` / `docs/DESIGN-VORSCHLAEGE.md` umschreiben
