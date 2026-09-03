# Slices: restore-stripped-landmarks

**Status:** Überholt  
**Abgelöst durch:** [`docs/plans/schema-village-map/`](../schema-village-map/INDEX.md) (Schema-Dorf, nicht OSM-Re-Wire). Civic/Läden/Sport kommen in den Schema-Slices S03–S05, nicht hier.

**Aufgabe:** Nach dem Street-Map-Strip fehlende Landmark-Sprites (Civic, Hub/Tankstelle, Läden/Restaurants, Sport-/Spielplätze) wieder in die OSM-Welt verdrahten — Schulen/Kigas/Bahnhof/Badi/Housing/Wälder bleiben.  
**Datum:** 2026-08-13  
**Zuschnitt:** zwei verwandte Landmark-Gruppen (Civic+Forrenberg; Shops+Play); Art bereits auf Disk

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-civic-churches-forrenberg.md` | Kirchen, Feuerwehr, Gemeindehaus + Hub/Tankstelle Forrenberg | — | überholt |
| S02 | `S02-shops-sport-spielplatz.md` | Restaurants/Läden + Sportplätze + Spielplätze | S01 | überholt |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Schulen, Kigas, Bahnhof, Badi, Forests, Housing neu platzieren (bereits via SeuzachGeo / `_place_landmarks`)
- Neue Art erzeugen (PNGs existieren; kein Stil-A/B)
- Strassennetz, Spawn, Feldmaß / Kamera neu erfinden
- Alte stilisierten Dorfkern-`Vector2`-Koordinaten 1:1 übernehmen (falsche Skala) — GPS/`SeuzachGeo` oder Offsets von bekannten Ankern
