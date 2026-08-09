# Plan: Organischer Boden + erkennbare Straßen

**Status:** Erledigt  
**Typ:** Bugfix / Visual Polish  
**Datum:** 2026-08-09  
**Owner:** Hauptagent

## Ziel

Sandbox-Boden wie Moodboard C: durchgehendes Gras ohne Schachbrett, klar erkennbare durchgehende Straßenbänder (kein Diamond-Raster).

## Repro & RCA

- [x] Repro bestätigt
- [x] RCA dokumentiert

### Reproduktion

| Feld | Inhalt |
|------|--------|
| Schritte | Sandbox öffnen, Boden betrachten |
| Erwartet | Organisches Gras, klare Straßen wie `c-umgebung.png` |
| Tatsächlich | Gras-Alt-Rauten im Schachbrettmuster; Straße aus gleichen Iso-Diamanten → wirkt gekachelt, Straße kaum als Band lesbar |
| Umgebung | `world_sandbox.gd` `_build_flat_ground` |
| Evidenz | Checker-Loop `(x+y)%2`; `_add_road_cells` pro Zelle |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Ursache | Checker-Akzente + Straßen als einzelne Iso-Zellen gleicher Größe → Raster-Look; nach Outline-Entfernung Straße nur noch fragmentiert |
| Nicht Ursache | Fehlende Textur-Assets; Kamera |
| Fix | Kein Checker; große weiche Gras-Blobs; Straße als **durchgehende** Polygon-Bänder (helleres Grau, ggf. Mittelstreifen) |
| Risiken | Zu simple Blobs; Iso-Ausrichtung der Straße beachten |

## Scope

- In: `world_sandbox.gd`, Style-Hinweis, `m2_world_test`
- Nicht: echte TileMap/Seuzach-Kurve (M3); neue Art-PNGs

## Technische Schritte

1. Checker-Loop entfernen
2. Organische Gras-Patches (unregelmäßige Polygone)
3. Vertikale + horizontale Straßen als kontinuierliche Iso-Ribbons; helleres Straßen-Grau; optional heller Mittelstreifen (Polygon, kein schwarzes Kachel-Outline)
4. Tests: 0 Line2D; Road-Polygon vorhanden; Polygon-Anzahl begrenzt (kein Diamond-Flood)

## Testplan

- [x] Suite inkl. erweiterter `m2_world_test`
- [x] Playtest: Straße als Band erkennbar, kein Schachbrett

## Art-Bedarf

- [x] Keine neuen Assets (procedural)

## Akzeptanzkriterien

- [x] Kein Schachbrett-Gras
- [x] Straße klar als Band lesbar
- [x] Review + Playtest Pass
