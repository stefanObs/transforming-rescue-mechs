# Slices: school-house-real-ratio

**Status:** Entwurf  
**Aufgabe:** Schul-Campus und Kindergärten auf dasselbe Spiel-zu-Real-Verhältnis bringen wie die Häuser (`HOUSE_TO_REAL_RATIO ≈ 1.72`), nur über bestehende `*_SCALE_MULT` in `scripts/world_sandbox.gd`.  
**Datum:** 2026-08-16  
**Zuschnitt:** ein Campus (3-Gebäude-Cluster) = ein Slice; Ohringen-Campus + Kiga Ohringen in derselben Zelle; drei Seuzach-Kigas als ein Scale-System

Feature-Schritte, keine Prozess-Schritte. Pro Zeile folgt der Ablauf (Plan nur wenn nötig → Implement inkl. Tests → Review → Playtest → Git).

## Reihenfolge

| ID | Datei | Feature | Hängt ab von | Status |
|----|-------|---------|----------------|--------|
| S01 | `S01-campus-birch-house-ratio.md` | Campus Birch: Sprite-Fassade / OSM-Strassenfassade ≈ 1.72 | — | erledigt |
| S02 | `S02-campus-rietacker-house-ratio.md` | Campus Rietacker: Sprite-Fassade / OSM-Strassenfassade ≈ 1.72 | S01 | erledigt |
| S03 | `S03-ohringen-campus-kiga-house-ratio.md` | Campus Ohringen + Kiga Ohringen: Sprite-Fassade / OSM ≈ 1.72 | S02 | erledigt |
| S04 | `S04-kigas-bachtobel-weid-schneckenwiese.md` | Kigas Bachtobel + Weid + Schneckenwiese: Sprite-Fassade / OSM ≈ 1.72 | S03 | offen |

Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Phase-4-Pass + Git). Kein Slice-File-Phasen-Churn.

## Nicht in dieser Aufgabe

- `HOUSE_SCALE` (bleibt 0.38); Häuser / Housing-Art
- `SCHOOL_SCALE` (bleibt 0.50); `FIELD_METERS`; GPS / `seuzach_geo.gd`
- Art-PNGs neu erzeugen oder ersetzen
- RoadKit-Polylines / Strassennetz (Hof/Asphalt: **Mult senken**, nicht GPS/Roads)
- Bahnhof, Badi (`LANDMARK_SCALE` / `BAHNHOF_SCALE_MULT` / `BADI_SCALE_MULT`)
- Civic, Shops, Feuerwehr, Kirchen, Forests
