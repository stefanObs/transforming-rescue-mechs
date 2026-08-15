# Slices: schools-kigas-street-side

**Status:** Erledigt  
**Aufgabe:** Schulen und Kindergärten sitzen an der falschen Strassenseite / schief zur sichtbaren RoadKit-Strasse — Placement und street-aligned Facing (`_ew`/`_ns` + `flip_h`) korrigieren.  
**Datum:** 2026-08-15  
**Zuschnitt:** ein Campus (3-Gebäude-Cluster) = ein Slice; Ohringen-Campus + Kiga Ohringen in derselben Zelle; drei Seuzach-Kigas als ein Placement-System

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-campus-birch-street-side.md` | Campus Birch westlich an Bachwiesenstrasse + street-aligned Facing (Helper) | — | erledigt |
| S02 | `S02-campus-rietacker-street-side.md` | Campus Rietacker nördlich an Ohringerstrasse / Turnhalle Turnerstrasse | S01 | erledigt |
| S03 | `S03-ohringen-campus-kiga-street-side.md` | Campus Ohringen + Kiga Ohringen westlich an Schulstrasse | S01 | erledigt |
| S04 | `S04-kigas-bachtobel-weid-schneckenwiese.md` | Kigas Bachtobel + Weid + Schneckenwiese an ihrer Strasse | S01 | erledigt |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- Wohnhäuser / Housing-Art (`house_street_*`)
- Bahnhof, Badi
- Civic/Shops `restore-stripped-landmarks`
- RoadKit-Gesamtnetz neu zeichnen (Birch: nur Polylines bis Campus in S01)
- Globales `SCHOOL_SCALE`
- `Sprite2D.rotation` als Facing
- Alle Schulen in einem Slice
