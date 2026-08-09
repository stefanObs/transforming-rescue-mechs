# Plan: Flacher Boden statt gekachelter 3D-Gras-Sprites

## Ziel / User-Nutzen

Die Sandbox-Welt soll wie Stil C (Comic-Rettung) wirken: klarer Cel-Boden, lesbare Straße, Landmarken als Props — ohne störende „3D-Block“-Kacheln.

## Repro & RCA

- [x] Repro bestätigt
- [x] Root Cause benannt

### Repro

1. `godot --path .` bzw. `./play-linux.sh` → Scene `world_sandbox.tscn`
2. Boden: aneinandergereihte `tile_grass.png` / `tile_road.png` als Sprite2D
3. Erwartung: flacher Iso-/Cel-Boden wie Moodboard C
4. Ist: perspektivische Block-Sprites stoßen sich an den Kanten; Welt wirkt nicht wie Konzept

### Root Cause

`tile_grass` / `tile_road` sind **Hero-/Perspektiv-Sprites** (sichtbare Höhe/Schatten), keine flachen Fill-Tiles. Beim Tiling kollidiert der 3D-Effekt. Landmarken (Haus/Kirche) waren fälschlich als Bodentextur-Ersatz mitgenutzt.

**Nicht Ursache:** Alpha/weiße Hintergründe (bereits behoben); fehlende Charakter-Art.

### Fix-Richtung

Durchgehende Grasfläche + flache Straßen-Polygone (Cel-Farben, Outline) + Haus/Kirche/Hub nur als einzelne Props. Keine `tile_grass`/`tile_road` unter `%Ground`.

## Scope

- In: `world_sandbox` Ground/Props, Style-Bible / Art-Agent-Hinweis, Regressionstest
- Nicht: echte Seuzach-TileMap (M3), neue Boden-Art-Assets

## Schritte

1. Ground per Polygon2D bauen (Gras-Fill + Straßenband mit Outline)
2. Props: nur Landmarken, beabstandet
3. `m2_world_test`: Ground ohne Sprite2D-Tiles; Props ≠ grass/road
4. Docs: Style-C Regel „keine 3D-Boden-Kacheln“

## Testplan

- [x] `./scripts/run_tests.sh` inkl. `m2_world_test`
- [x] Playtest: Scene lädt, keine Script-Fehler
- [ ] Manuell: Gras ohne Block-Kanten, Straße lesbar, Props erkennbar

## Art

Nein (procedural polygons). Bestehende Hero-Tiles bleiben Assets, werden nicht gekachelt.

## Akzeptanzkriterien

- [x] `%Ground` hat 0 Sprite2D
- [x] Keine `tile_grass`/`tile_road` als Props
- [x] Style-Bible dokumentiert Flat-Ground-Regel
- [x] Tests grün
