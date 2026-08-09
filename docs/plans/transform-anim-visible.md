# Plan: Transform-Animation Bolt & Marina sichtbar

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-09  
**Owner:** Hauptagent

## Ziel

Space/Transform zeigt für **Bolt (1)** und **Marina (2)** eine klare Zwischen-Animation wie bei Rush — kein Instant-Swap.

## Scope

- In: Transform-Art Marina; ggf. Bolt-Frames prüfen; `player.gd` Playback; Regressionstest
- Nicht: Neue Charaktere; 8-Dir-Laufcycles

## Systeme

Player-Visuals, Art (`assets/art/*_transform_*.png`)

## Repro & RCA

- [x] Repro bestätigt
- [x] RCA dokumentiert

### Reproduktion

| Feld | Inhalt |
|------|--------|
| Schritte | 1. Sandbox starten 2. Taste `1` (Bolt) bzw. `2` (Marina) 3. Space/Transform |
| Erwartet | Mehrere Zwischenframes Robot↔Fahrzeug sichtbar |
| Tatsächlich | Marina: Instant-Swap (keine Frames). Bolt: Frames existieren & spielen im Headless, wirken im Spiel leicht übersehbar / Nutzer meldet „nicht sichtbar“; Rush (3) ok |
| Umgebung | Godot 4.4.1, `world_sandbox`, Keys 1/2/Space |
| Evidenz | `marina_transform_01..06` **fehlen**; Headless: `marina has_anim=false`; `bolt has_anim=true frames=6` |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (A) Marina-Art fehlt (B) Playback-Bug (C) Animation zu schnell/klein |
| Bestätigte Ursache | **(A)** Marina: `toggle_form` skippt `_play_transform` weil `has_animation("to_vehicle")` false. **(C/teilweise)** Bolt: Assets da, Playback startet; bei Scale 0.085 + 12 FPS leicht zu übersehen — Playback härten + Tempo/Scale für Transform anheben |
| Nicht die Ursache | Fehlende Input-Action; Rush-Sondercode |
| Fix-Richtung | Marina 6 Transform-Frames (Style C); Test erzwingt Frames für bolt+marina+rush; Playback: frame 0, play, Guard auf `animation_finished`; Transform etwas langsamer/größer |
| Risiken | Art-Qualität; Anim-Dauer vs. Lockout |

## Technische Schritte

1. Regressionstest: alle drei Chars ≥4 Transform-Frames; nach toggle `_transforming` und `TransformSprite.visible`
2. `comic-rettung-art`: `marina_transform_01`…`06` (Robot→Hovercraft), Alpha-Pipeline
3. `player.gd`: robustes `_play_transform` (animation setzen, frame 0, play); FPS ~8; optional leicht größerer Transform-Scale; Lockout ≥ Anim-Dauer; Finished-Guard
4. Review + Playtest

## Testplan

### Automatisiert

- [ ] Asset-Existenz marina_transform_01 + _06
- [ ] set_character bolt/marina/rush → has to_vehicle, count ≥ 4
- [ ] toggle → transforming + visible (für alle drei)

### Playtest

- [ ] Key 1 + Space: Zwischenframes sichtbar
- [ ] Key 2 + Space: Zwischenframes sichtbar
- [ ] Key 3 unverändert ok

## Art-Bedarf

- [x] Neue Grafiken → `comic-rettung-art`  
  Details: Marina Transform 01–06, Referenzen `docs/design-refs/c-*.png` + `marina_robot.png` / `marina_vehicle.png`

## Akzeptanzkriterien

- [ ] Repro + RCA erledigt
- [ ] Marina hat Transform-Art
- [ ] Bolt & Marina zeigen Animation im Spiel
- [ ] Tests + Review + Playtest Pass
