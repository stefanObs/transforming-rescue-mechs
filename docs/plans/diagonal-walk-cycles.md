# Plan: diagonal-walk-cycles

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-10  
**Owner:** Hauptagent

## Ziel

Beim diagonalen Laufen (NE/SE/SW/NW) soll der Mech wie bei den Kardinalrichtungen einen sichtbaren Walk-Cycle abspielen — nicht nur die statische Dir-Pose. NW/SW nutzen Spiegelungen von NE/SE (analog W = Flip von E).

## Scope

- In:
  - Style-C Walk-Art `ne` und `se` (4 Frames) für bolt, marina, rush
  - `pad_walk_frames.py` / Alpha-Pipeline um `ne`/`se` erweitern
  - `player.gd`: Walk auch für Diagonalen; Anim-Mapping + `flip_h` für W/NW/SW
  - Regression in `tests/m2_walk_test.gd`
- Nicht:
  - Fahrzeug-Walk / Rad-Spin
  - Neue NW/SW-Quell-PNGs (nur Flip im Code)
  - Änderung der 8-Dir-Bewegungslogik selbst
  - Transform- oder Idle-Art

## Systeme

Player-Locomotion-Visuals (`scripts/player.gd`), Robot-Walk-Assets unter `assets/art/`, Art-Pipeline (`process_art_alpha.py`, `verify_art_alpha.py`, `pad_walk_frames.py`), Test `tests/m2_walk_test.gd`

## Repro & RCA (Pflicht bei Typ = Bugfix)

### Reproduktion

- [x] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. Sandbox starten (`world_sandbox`). 2. Robot-Form. 3. Diagonal bewegen (Pfeil-Kombos NE/SE/SW/NW). |
| Erwartet | `WalkSprite` spielt passende Diagonal-Walk-Animation; `RobotSprite` verborgen. |
| Tatsächlich | `WalkSprite` bleibt aus; statische `{id}_robot_{ne\|se\|…}`-Dir-Art auf `RobotSprite`. |
| Umgebung | Godot 4, Branch aktuell, Tastatur, Scene `world_sandbox` |
| Evidenz | Code-Gate seit v0.12.3: `_facing_is_cardinal()` in `_update_locomotion_visuals` / `_start_walk`; `WALK_DIRS` nur `n/e/s`; keine `*_robot_walk_{ne\|se}_*.png` |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (A) Absichtliches Cardinal-Only-Gate. (B) Fehlende Diagonal-Walk-Assets. (C) Facing/Input liefert keine Diagonalen. |
| Bestätigte Ursache | Bewusst in v0.12.3: `WALK_DIRS := ["n","e","s"]`; `_update_locomotion_visuals` und `_start_walk` verlangen `_facing_is_cardinal()`, damit Diagonalen nicht fälschlich `walk_s` nutzen. Keine `{id}_robot_walk_{ne\|se}_*.png`. |
| Nicht die Ursache | 8-Dir-Input/Facing (funktioniert; Idle-Dir-Art für Diagonalen ist vorhanden). Vehicle-Pfad (korrekt ohne Walk). |
| Fix-Richtung | Echte NE/SE-Walk-Zyklen + Code-Mapping inkl. Flip für NW/SW; Cardinal-Gate entfernen. |
| Risiken | Flip-Konsistenz mit static Dir-Art; Frame-Padding/Bodenkontakt; `_apply_facing_visuals` setzt `flip_h` heute nur bei `Facing.W` — muss NW/SW einschließen. |

- [x] RCA dokumentiert und reviewed (kurz vom Hauptagenten ok)

## Technische Schritte

1. **Art (Phase 2b, `comic-rettung-art`, Style C):**  
   Für `bolt`, `marina`, `rush` je 8 PNGs:  
   `{id}_robot_walk_ne_{01..04}.png`, `{id}_robot_walk_se_{01..04}.png`.  
   Referenz: static `{id}_robot_{ne|se}.png` + bestehende `walk_n` / `walk_e` / `walk_s`. Füße unten, transparent, gleicher Walk-Stil. Keine NW/SW-Assets (Code-Flip).
   → ✅ 24 PNGs geliefert, Alpha + Pad
2. **Pipeline:** `python3 scripts/process_art_alpha.py` → `verify_art_alpha.py` (grün) → `pad_walk_frames.py` mit `DIRS` um `"ne"`, `"se"` erweitern und ausführen.
   → ✅ `verify_art_alpha.py` OK (143 PNGs); pad inkl. `ne`/`se`
3. **`scripts/player.gd`:** ✅
   - `WALK_DIRS` → `["n", "e", "s", "ne", "se"]` (lädt `walk_ne` / `walk_se` über bestehendes `_load_walk_frames`).
   - Cardinal-Only-Gate in `_update_locomotion_visuals` und `_start_walk` entfernen (Walk bei jeder Facing-Richtung wenn moving + `_has_walk`).
   - `_walk_anim_name`: N→`walk_n`, S→`walk_s`, E/W→`walk_e`, NE/NW→`walk_ne`, SE/SW→`walk_se`.
   - `flip_h` für W, NW, SW via `_walk_flip_h` (in `_start_walk` und `_apply_facing_visuals`).
4. **Tests `tests/m2_walk_test.gd`:** ✅ `WALK_DIRS` um `ne`/`se`; Asserts: SE/NE moving → `is_walk_playing`, korrekte Anim (`walk_se`/`walk_ne`); SW/NW → gleiche Anim + `flip_h`; Vehicle weiterhin ohne Walk.
5. Review → Playtest (Sandbox Diagonal-Walk) → erst dann Commit/Push/Tag laut Projektregel.
   → ✅ Playtest Pass (2026-08-11)

## Testplan

### Automatisiert

- [x] Assets: je Char `ne`/`se` × 01–04 existieren, Alpha-Ecken, shared Canvas-Größe
- [x] Regression: SE moving → walk playing, anim `walk_se`; NE → `walk_ne`
- [x] SW → `walk_se` + `flip_h`; NW → `walk_ne` + `flip_h`
- [x] Bestehende Kardinal-Walk- und Vehicle-„kein Walk“-Asserts bleiben
- [x] Bei Bugfix: Regressionstest bildet die Repro ab (zuerst rot ohne Assets/Gate-Fix, nach Fix grün)

### Playtest / Smoke

- [x] Haupt-Scene / Sandbox startet ohne Error (`godot --path . --quit-after 5`)
- [x] Robot: N/E/S/W Walk unverändert (Suite / `m2_walk_test`)
- [x] Robot: NE/SE/SW/NW Walk sichtbar, korrekte Spiegelung West-Diagonalen (headless `m2_walk_test`)
- [x] Stop → Idle-Dir-Art; Vehicle moving → kein Walk
- [x] Bei Bugfix: manuelle Repro-Schritte schlagen nach Fix nicht mehr fehl (automatisierte Regression)

## Art-Bedarf

- [x] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  
  Details: Style Bible C (`docs/STYLE-BIBLE-C.md`); Refs `docs/design-refs/c-*.png` + static `{id}_robot_{ne|se}.png` und vorhandene Walk-Frames. 3 Chars × 2 Dirs × 4 Frames = **24 PNGs**. Nach Lieferung Alpha-Process/Verify + Pad. Kein Stil A/B.

## Akzeptanzkriterien

- [x] Repro + RCA erledigt
- [x] Diagonal moving zeigt Walk-Cycle (NE/SE Quell-Art; NW/SW Flip)
- [x] Kein Vehicle-Walk
- [x] Automatisierte Tests grün (`m2_walk_test` + Suite)
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass
