# Slices: restore-landmark-scale

**Status:** In Arbeit  
**Aufgabe:** Landmark-Gebäude nach Feld-/Kamera-Skalierung wieder sichtbar und korrekt proportioniert einsetzen; Ausrichtung und Grössenverhältnisse per Google Maps/Street View prüfen.  
**Datum:** 2026-08-12  
**Zuschnitt:** zuerst ein globaler Scale-Pass für alle Landmarks; danach ~zwei verwandte Landmark-Gruppen (Campi/Kigas/Civic) mit Maps/Street-View-Ausrichtung

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-global-landmark-scale.md` | Landmark-/Prop-Scale vs. Strasse/Spieler wieder lesbar | — | erledigt |
| S02 | `S02-campus-birch-rietacker.md` | Campus Birch + Rietacker: Ausrichtung & Relativgrößen | S01 | erledigt |
| S03 | `S03-ohringen-campus-kiga.md` | Campus Ohringen + Kiga Ohringen: Ausrichtung & Relativgrößen | S01 | offen |
| S04 | `S04-kigas-bachtobel-weid-schneckenwiese.md` | Kigas Bachtobel + Weid + Schneckenwiese: Ausrichtung & Relativgrößen | S01 | offen |
| S05 | `S05-bahnhof-badi.md` | Bahnhof + Badi: Ausrichtung & Relativgrößen | S01 | offen |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Neue Wohnhäuser / Housing (Gebäude = bestehende Landmarks, die nach Scale unsichtbar/zu klein wurden)
- Feuerwehr, Gemeindehaus, Kirchen, Läden, Tankstelle, HubEnter/Forrenberg
- Strassennetz neu zeichnen; Spawn ändern; Feldmaß `FIELD_METERS` / Kamera-Zoom als Weltmaß neu erfinden (nur Landmarks an bestehendes Maß anpassen)
- Tracks, Bäche, Wälder neu legen (außer indirekt betroffen durch gemeinsame Scale-Konstanten in S01)
- Gesamte Art-Bibliothek neu generieren; ganze Karte neu bauen
