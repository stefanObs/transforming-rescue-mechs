# Plan: rush-vehicle-dir-scale

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-11  
**Owner:** Hauptagent

## Ziel

Rush (und analog andere Mechs) in der Fahrzeugform behalten über alle 8 Fahrtrichtungen eine stabile Bildschirmgröße — kein Schrumpfen bei Seitenansicht (E/W).

## Scope

- In:
  - `scripts/player.gd`: Anzeige-Skalierung aus Texturhöhe normalisieren (Vehicle + Robot/Walk konsistent)
  - Regressionstest: Rush vehicle E vs S → ähnliche On-Screen-Höhe (`scale.y * tex_height`)
- Nicht:
  - Neue Vehicle-Art neu zeichnen (optional Follow-up)
  - Bewegungs-/Facing-Logik ändern

## Systeme

Player-Visuals (`SPRITE_SCALE`, `_ground_align`, Dir-Texturen)

## Repro & RCA (Pflicht bei Typ = Bugfix)

### Reproduktion

- [x] Repro bestätigt (Messung + Code)
- [ ] Nicht reproduzierbar

| Feld | Inhalt |
|------|--------|
| Schritte | 1. Char Rush (3) 2. Transform → Auto 3. E/W vs N/S bewegen |
| Erwartet | Fahrzeug wirkt gleich groß |
| Tatsächlich | Seitenansicht deutlich kleiner als Front/Heck/Diagonal |
| Umgebung | Godot 4, Sandbox |
| Evidenz | `rush_vehicle_e.png` content h≈380; `rush_vehicle_s.png` h≈687; uniform `SPRITE_SCALE=0.085` → Screen-h ≈32 vs ≈58 px |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) Unterschiedliche Textur-/Content-Höhen × feste Scale (2) Flip skaliert (3) Bob/Offset |
| Bestätigte Ursache | (1): feste `SPRITE_SCALE` auf Dir-Texturen mit stark schwankender Höhe (Supersport-Seitenansicht flach). Padding allein ändert Content-Höhe nicht. |
| Nicht die Ursache | flip_h; Transform-Lock; Z-Order |
| Fix-Richtung | Pro Textur uniforme Scale so wählen, dass `tex_height * scale` ≈ Referenzhöhe (z. B. `SPRITE_REF_HEIGHT` oder Max der Dir-Texturen). Vehicle + Robot/Walk gleiches Schema. |
| Risiken | Sehr breite Seitenansichten; Label-Offset; Walk-Frames schon padded — Normalisierung nach Höhe bleibt korrekt |

- [x] RCA dokumentiert und reviewed

## Technische Schritte

1. Konstante Referenzhöhe (z. B. 700–1000 px Art-Höhe) oder aus Idle/max Dir ableiten.
2. `_sprite_scale_for(tex) -> Vector2`: `s = SPRITE_SCALE.y * (REF / tex.get_height())`, clamp sinnvoll.
3. Anwenden bei Load und bei jedem Texture-Wechsel (Robot/Vehicle/Walk/Transform).
4. Test: Rush vehicle facing E und S → `|h_e - h_s| / max(h) < 0.08` (o.ä.).
5. Review → Playtest → Release.

## Testplan

### Automatisiert

- [x] Rush vehicle E vs S screen height within tolerance
- [x] Marina/Bolt vehicle smoke optional
- [x] Suite grün

### Playtest

- [x] Rush Auto: E/W/N/S Größe stabil
- [x] Robot-Form nicht kaputt
- [x] Transform weiterhin ok

## Art-Bedarf

- [x] Keine Pflicht-Art (Code-Normalisierung). Optional später: Rush E/W Vehicle neu mit konsistenterer Iso-Silhouette.

## Akzeptanzkriterien

- [x] Repro + RCA
- [x] Rush Fahrzeuggröße richtungsstabil
- [x] Tests + Review + Playtest Pass
