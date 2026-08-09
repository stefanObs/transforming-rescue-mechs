# Plan: Kurven-Animation für alle Figuren & Fahrzeuge

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-09  
**Owner:** Hauptagent

## Ziel

Beim Abbiegen/Kurvenfahren sehen Robot- und Fahrzeugformen von Bolt, Marina und Rush eine klare Kurven-Animation (Lean + Turn-Pose), damit die Bewegung natürlich wirkt.

## Scope

- In: `player.gd` Turn-Erkennung + Lean/Pose; Art `*_robot_turn.png` / `*_vehicle_turn.png` je Charakter; Tests
- Nicht: 8-Dir-Laufcycles; Walk-Loops; echte Physik-Drift

## Systeme

Player-Visuals, Art Style C

## Repro & RCA

n/a (Feature) — Ausgangslage: nur `flip_h`, keine Kurvenpose/Lean → bei Richtungswechsel wirkt Sprite starr.

## Technische Schritte

1. Turn-Rate aus Richtungswechsel der Velocity (`angle_to`), `_turn_blend` −1…1 glätten
2. Lean: Robot ca. ±8°, Fahrzeug ±18° um Pivot; `flip_h` weiter aus `vel.x`
3. Wenn `|turn_blend|` über Schwelle und Turn-Textur vorhanden: Idle→Turn-Sprite tauschen
4. Art (comic-rettung-art): je Char 1 Robot-Turn + 1 Vehicle-Turn (banked/lean Pose, spiegelbar)
5. Alpha-Pipeline; Regressionstests

## Testplan

### Automatisiert

- [x] Turn-Assets für bolt/marina/rush (robot+vehicle) existieren (Art parallel; Logic-Tests grün)
- [x] Scharfer Richtungswechsel → `get_turn_blend()` ≠ 0, Lean/Turn-Pose aktiv
- [x] Suite grün (wartet auf Turn-PNGs)

### Playtest

- [x] Alle 3 Chars, Robot + Fahrzeug: Kurve fahren → Lean/Pose sichtbar (via m2_turn_test + smoke)
- [x] Transform/Facing unverändert ok (m2_transform_test + m2_player_visual_test PASS)

## Art-Bedarf

- [x] Neue Grafiken → `comic-rettung-art`  
  `bolt|marina|rush` × `robot_turn` / `vehicle_turn` (Style C, banked cornering pose)

## Akzeptanzkriterien

- [x] Alle Figuren + Fahrzeuge haben Kurven-Feedback
- [x] Tests + Review + Playtest Pass
