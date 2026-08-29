# Slices: seuzach-grid-housing

**Status:** In Arbeit  
**Aufgabe:** Wohnbebauung rasterweise über die wichtigen Seuzach-Wohnquartiere legen — maps-plausibel, am bestehenden F1-100-wu-Feld gebunden.  
**Datum:** 2026-08-29  
**Zuschnitt:** zwei verwandte Wohnquartiere / Straßenband-Paare pro Slice; S01 = Quartier-Raster-Konzept + erste zwei Zellen

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Raster (F1, Kirche = Ursprung)

1 Feld = 100 wu = 5,3 m. Housing an **benannte Quartier-Zellen** (Feld-Rechtecke), nicht an ein zweites Koordinatensystem. Bestehendes Spawn-Korridor-Housing (`buildings-visible-at-play`) bleibt gültig und wird in die Quartier-Logik überführt/ergänzt — nicht doppelt stapeln.

| Zelle | Felder (ix, iy) ca. | Inhalt kurz |
|-------|---------------------|-------------|
| KIRCHE-KERN | −15..25, −30..25 | Dorfkern / Kirchgasse / Kirchhügel-Wohnzeilen |
| WINT-WEST | 20..50, −35..40 | Winterthurerstrasse westlich-zentral (Spawn-Flanke + Westseite) |
| WINT-NORD | 25..55, −90..−30 | Winterthurerstrasse nordwärts Richtung Landstrasse-Knoten |
| LAND-MITTE | 40..120, −130..−50 | Landstrasse Wohnband Mitte (Kern↔Badi-Korridor; Badi selbst nicht neu) |
| STAT-WEST | 80..160, −70..−20 | Stationsstrasse westlich (Zentrum → Bahnhof) |
| STAT-BHF | 155..210, −70..−25 | Stationsstrasse / Bahnhof-Wohnzeilen (Gebäude Bahnhof bleibt Landmark) |
| REUT-MITTE | 45..95, −45..10 | Reutlingerstrasse Mitte / Schneckenwiese-Nahband |
| REUT-SE | 70..120, −20..40 | Reutlinger SE + angrenzende Wohnstiche |
| BREITE | 70..140, −55..15 | Breitestrasse Wohn-/Zentrumsrand |
| SEEBUEHL | 100..160, −50..20 | Seebühlstrasse-Stich (Birch–Reutlinger-Band) |
| OHR-NORD | −230..−170, 80..130 | Ohringen Nord (Ohringer-/Wohnachsen; Campus/Kiga nicht neu) |
| OHR-SUED | −230..−170, 125..175 | Ohringen Süd / Schulstrasse-Wohnzeilen |

Feldspannen sind Orientierungsrahmen (Maps/OSM); Implementierung darf ±10 Felder justieren, solange Quartier-Paare und Straßenbindung klar bleiben.

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-quartier-raster-kirche-wint-west.md` | Quartier-Raster für Housing + KIRCHE-KERN + WINT-WEST | — | erledigt |
| S02 | `S02-wint-nord-landstrasse-mitte.md` | WINT-NORD + LAND-MITTE | S01 | offen |
| S03 | `S03-stationsstrasse-bahnhof.md` | STAT-WEST + STAT-BHF | S01 | offen |
| S04 | `S04-reutlinger-se.md` | REUT-MITTE + REUT-SE | S01 | offen |
| S05 | `S05-breitestrasse-seebuehl.md` | BREITE + SEEBUEHL | S01 | offen |
| S06 | `S06-ohringen-nord-sued.md` | OHR-NORD + OHR-SUED | S01 | offen |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Ganz Seuzach zellenweise / jede 100er-Zelle als eigener Slice
- Schulen, Kigas, Bahnhof, Badi, Feuerwehr, Shops neu erfinden (`restore-stripped-landmarks` bleibt getrennt)
- Zweites paralleles Koordinatensystem neben F1
- Autobahn-/Forrenberg-Wohnsiedlung oder reine Landwirtschaftsflächen vollbauen
- Review / Tests / Playtest / Git als eigene Slices
