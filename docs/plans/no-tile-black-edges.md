# Plan: Keine schwarzen Kachel-Ränder am Boden

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-09  
**Owner:** Hauptagent

## Ziel

Boden (Gras/Straße) ohne Gitter aus schwarzen Iso-Kanten — weiche Cel-Flächen, Straße nur durch Farbe getrennt.

## Repro & RCA

- [x] Repro bestätigt
- [x] RCA dokumentiert

### Reproduktion

| Feld | Inhalt |
|------|--------|
| Schritte | Sandbox starten, Straßenkreuzung ansehen |
| Erwartet | Flache Cel-Straße/Gras ohne schwarzes Kachelgitter |
| Tatsächlich | Jede Straßen-Raute hat `Line2D` Outline `#1A1A1A` Breite 3 → sichtbares schwarzes Gitternetz |
| Umgebung | `world_sandbox`, `scripts/world_sandbox.gd` `_add_road_outline` |
| Evidenz | Code: Loop über alle Road-Zellen mit `Line2D` closed diamond |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Bestätigte Ursache | Per-Kachel-Outlines für Style-C-„Outline“ fälschlich auf **repeating ground** angewendet; bei aneinanderliegenden Rauten entsteht ein Raster |
| Nicht die Ursache | Charakter-Sprite-Outlines; Prop-Art |
| Fix-Richtung | `_add_road_outline` entfernen; Boden nur Polygon-Füllungen; Style-Bible: Outline für Characters/Props, nicht pro Bodenkachel |
| Risiken | Straße etwas weniger konturiert — Farbkontrast Gras/Straße reicht |

## Scope

- In: `world_sandbox.gd`, Style-Bible Hinweis, `m2_world_test`
- Nicht: Neue Art; Charakter-Outlines

## Technische Schritte

1. Road-Outline-Loop entfernen / nicht aufrufen
2. Test: Ground hat 0 `Line2D`
3. STYLE-BIBLE: Boden ohne Per-Tile-Schwarzrand

## Testplan

- [x] `m2_world_test`: keine Line2D unter Ground
- [x] Suite grün; Playtest: kein schwarzes Gitter

## Art-Bedarf

- [x] Keine neuen Assets

## Akzeptanzkriterien

- [x] Keine schwarzen Ränder um Bodenkacheln
- [x] Tests + Review + Playtest Pass
