# Plan: Bodenkontakt + Mech-Laufanimation

**Status:** Erledigt  

**Typ:** Feature  
**Datum:** 2026-08-09  
**Owner:** Hauptagent

## Ziel

Figuren wirken auf der Straße „auf dem Asphalt“ (Füße/Reifen am Boden, Schatten). Mechs bekommen eine Laufanimation beim Gehen.

## Scope

- In:
  - Sprite-Pivot/Offset: Kontaktpunkt unten (Füße/Reifen am Origin)
  - Kontakt-Schatten unter Player
  - Robot-Walk: 4 Frames × Richtungen N/E/S/W (W kann Flip von E sein)
  - Vehicle: Bodenkontakt + leichter Fahr-Bob (keine Walk-Frames)
  - Tests
- Nicht: Fahrzeug-Rad-Spin-Art; 8-Dir; neue Straßen

## Systeme

Player-Visuals, Art Style C

## Technische Schritte

1. `_align_sprite_to_ground(sprite, tex)` — Offset so Unterkante ≈ Origin (y≈0)
2. `Shadow` Polygon2D/Ellipse unter Player (grau, leicht transparent)
3. Walk-Art: `{id}_robot_walk_{n|e|s}_{01..04}.png`; W = Flip E
4. `AnimatedSprite2D` oder Frame-Cycle auf RobotSprite beim Laufen; Idle = dir-Textur Frame 0 / still
5. Vehicle: ground align + `sin`-Bob wenn moving
6. Tests: Walk-Assets; moving robot advances walk frame; shadow exists; ground offset ≈ feet

## Art-Bedarf

- [x] comic-rettung-art: je bolt/marina/rush × walk n/e/s × 01–04 (12 PNGs/Char)  
  W-Profil: im Code Flip von E. Transparent, Füße unten, Style C.

## Testplan

- [x] Walk-Assets existieren (n/e/s × 01–04 × 3 chars)
- [x] Robot moving → walk playing / frame changes
- [x] Stop → idle dir texture
- [x] Shadow node present
- [x] Suite (`./scripts/run_tests.sh` PASS); Playtest PASS

## Akzeptanzkriterien

- [x] Mechs laufen sichtbar
- [x] Füße/Reifen am Boden, Schatten
- [x] Review + Playtest → Release
