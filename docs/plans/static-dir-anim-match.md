# Plan: Animationen = statische Richtungsansichten

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-10  
**Owner:** Hauptagent

## Ziel

Bewegungs-Sprites sehen aus wie die statisch generierten Richtungsbilder — ohne Lean/Turn-Pose-Verfremdung; Mechs auch diagonal korrekt.

## Repro & RCA

- [x] Repro bestätigt
- [x] RCA dokumentiert

| Feld | Inhalt |
|------|--------|
| Problem | Mit 8-Dir-Art dreht Lean die Sprites; Turn-Pose ersetzt Dir-Art; Robot-Diagonalen fehlen → Fallback auf S/E; Walk SE nutzt `walk_s` (falsche Silhouette) |
| Erwartet | SE-Fahrt zeigt exakt `*_vehicle_se.png` wie generiert; Mech analog |
| Fix | Lean=0 wenn Dir-Art; kein Turn-Pose-Swap bei Dir-Art; Robot `ne/se/sw/nw` Art; Diagonal-Walk: statische Dir-Pose (+ leichter Bob) statt falschem `walk_s` |

## Scope

- In: player.gd lean/texture/walk-Auswahl; Robot-Diagonal-Art; Tests (texture path = facing)
- Nicht: volle 8-Dir Walk-Cycle-Frames (optional später)

## Schritte

1. `_apply_turn_visuals`: rotation 0 wenn `uses_dir_textures()`
2. `_texture_for`: nie Turn-Pose wenn Facing-Dir-Textur gesetzt
3. Art: `{bolt,marina,rush}_robot_{ne,se,sw,nw}.png`
4. Walk: nur N/E/S/W mit Walk-Cycles; Diagonal → RobotSprite mit Dir-Textur (kein WalkSprite)
5. Test: je Facing Vehicle/Robot texture path endet auf `_{suffix}.png`

## Akzeptanz

- [x] Kein Lean auf Dir-Sprites
- [x] SE/SW/… Texture = Asset-Suffix
- [x] Robot-Diagonalen vorhanden
- [x] Suite + Playtest → Tag
