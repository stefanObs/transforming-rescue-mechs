# Slices: <kurzname>

**Status:** Entwurf | In Arbeit | Erledigt  
**Aufgabe:** <User-Ziel in einem Satz>  
**Datum:** YYYY-MM-DD  
**Raster / Zuschnitt:** <z. B. F1 10er-Blöcke; ein Haus pro Slice; n/a>

Der Hauptagent arbeitet **nur den nächsten offenen Slice** mit dem vollen Ablauf (Plan → Implement → Review → Playtest → Git) ab. Kein Überspringen, kein Parallel-Merge mehrerer Slices in einen Commit.

## Raster (falls Karte)

| Zelle | Felder (ix, iy) | Inhalt kurz |
|-------|-----------------|-------------|
| … | z. B. 0..9, −10..−1 | … |

## Reihenfolge

| ID | Datei | Titel | Hängt ab von | Status |
|----|-------|-------|----------------|--------|
| S01 | `S01-<slug>.md` | … | — | offen |
| S02 | `S02-<slug>.md` | … | S01 | offen |

Status je Slice: `offen` → `in Arbeit` → `erledigt` (nach Phase-4-Pass + Git-Tag).

## Nicht in dieser Aufgabe

- …
