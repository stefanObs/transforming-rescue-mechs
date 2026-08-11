# Slices: m3-spawn-winterthurer-roads-visible

**Status:** In Arbeit  
**Aufgabe:** Startpunkt auf die Karte / Winterthurerstrasse legen und Strassen im Start-Viewport sichtbar machen (Playtest: nur Grün).  
**Datum:** 2026-08-11  
**Raster / Zuschnitt:** Benanntes Quartier WINT-KERN (F1 10er-Nähe); kein Housing; Ohringen/Forrenberg nicht anfassen

Der Hauptagent arbeitet **nur den nächsten offenen Slice** mit dem vollen Ablauf (Plan → Implement → Review → Playtest → Git) ab. Kein Überspringen, kein Parallel-Merge mehrerer Slices in einen Commit.

## Raster (falls Karte)

| Zelle | Felder (ix, iy) | Inhalt kurz |
|-------|-----------------|-------------|
| WINT-KERN | 30..45, −15..10 | Winterthurerstrasse Dorfkern, Kirche-Ost. OSM-Sample ≈ (3862, −101) → Feld (38, −2). Spawn-Ziel und Sichtbarkeits-Viewport. |
| — | Forrenberg ≈ (130, 153) | Nur Ist-Spawn (SOCAR); kein Slice-Lieferumfang |
| — | Ohringen | Nicht in dieser Aufgabe |

Kirche = Ursprung (0, 0). 1 Feld = 100 wu = 5,3 m. Gras = `SeuzachGeo.WORLD_BOUNDS`.

## Reihenfolge

| ID | Datei | Titel | Hängt ab von | Status |
|----|-------|-------|----------------|--------|
| S01 | `S01-spawn-winterthurerstrasse.md` | Spawn auf Winterthurerstrasse (Dorfkern) | — | erledigt |
| S02 | `S02-streets-visible-at-spawn.md` | Strassen im Start-Viewport sichtbar | S01 | offen |

Status je Slice: `offen` → `in Arbeit` → `erledigt` (nach Phase-4-Pass + Git-Tag).

## Nicht in dieser Aufgabe

- Häuser, Schulen, Landmarken-Art, Ohringen-Zellen
- HubEnter/SOCAR Forrenberg verschieben oder Hub-Transition ändern
- Gesamtes Strassennetz neu zeichnen / alle Breiten „überall“ ohne Bezug zum Start-Viewport
- Kamerazoom als eigenes Feature (nur falls S02-RCA es als Ursache bestätigt, dann *in* S02)
