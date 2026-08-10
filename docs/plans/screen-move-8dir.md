# Plan: Screen-Steuerung + 8-Dir Fahrzeuge (schräg unten)

**Status:** Erledigt  
**Typ:** Bugfix + Feature  
**Datum:** 2026-08-10  
**Owner:** Hauptagent

## Ziel

Pfeiltasten = Bildschirmrichtungen (unten = wirklich nach unten). Fahrzeuge korrekt ausgerichtet inkl. schräg-unten (SE/SW). Level-Straßen an Achsen ausrichten.

## Repro & RCA

- [x] Repro bestätigt
- [x] RCA dokumentiert

| Feld | Inhalt |
|------|--------|
| Schritte | Nur ↓ : Figur läuft schräg links-unten; ↓+→ ergibt senkrecht unten |
| Erwartet | ↓ = senkrecht nach unten auf dem Screen |
| Ursache | `_cartesian_to_iso`: `(0,1)→(-1,0.5)`; `(1,1)→(0,1)` |
| Facing | 4-Dir reicht nicht für Schrägen; aktuelles S bei schräger Bewegung falsch |
| Fix | Screen-space Movement; 8-Dir Facing; SE/SW(/NE/NW) Vehicle-Art; Straßen horizontal/vertikal |

## Scope

- In: `player.gd` movement + 8-dir facing; Vehicle-Art se/sw/ne/nw; Sandbox-Straßen axis-aligned; Tests
- Nicht: komplette 8-Dir Walk-Cycles (Walk fallback n/e/s); Mech-Diagonal-Art optional mit Fallback

## Technische Schritte

1. Velocity = `input_vec` (kein Iso für Bewegung); Facing aus `atan2` → 8 Sektoren
2. Enum: N,NE,E,SE,S,SW,W,NW; Suffixe `n,ne,e,se,s,sw,w,nw`
3. Bestehende n/e/s/w behalten; neu: vehicle `se,sw,ne,nw` (3 Chars)
4. Robot: Fallback SE→S/E, SW→S/W, …
5. Sandbox: RoadKit Hauptstraße vertikal, Querstraße horizontal, eine Diagonale, Kreisel
6. Tests aktualisieren

## Art

- [x] comic-rettung-art: `{bolt,marina,rush}_vehicle_{se,sw,ne,nw}.png`  
  SE = ¾ Front-rechts (schräg unten-rechts); SW = ¾ Front-links; NE/NW Heck-schräg

## Akzeptanz

- [x] ↓ allein = Screen-unten; Sprite S (Front) — Tests + Screen-velocity
- [x] ↓+→ = SE-Sprite; ↓+← = SW-Sprite — `m2_facing_test`
- [x] Straßen H/V lesbar zu den Pfeilen — Sandbox screen-axis RoadKit
- [x] Tests + Review + Playtest → Tag
