# Plan: windows-run-figures

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/windows-figures-visible.md`](windows-figures-visible.md)  
**Art:** keine neuen Assets

---

## Ziel

`Run_windows.bat` / `play-windows.bat` zeigt die **aktuellen Figuren** (Bolt/Marina/Rush), nicht einen unsichtbaren oder veralteten Stand.

---

## Repro & RCA

### Reproduktion

- [x] Repro bestätigt (Starter-Pfad + fehlender Alias; Linux-Projektmodus zeigt Figuren)
- [ ] Nicht reproduzierbar

| Feld | Inhalt |
|------|--------|
| Schritte | 1. Windows: `Run_windows.bat` oder `play-windows.bat` 2. Sandbox |
| Erwartet | Mech am Spawn sichtbar |
| Tatsächlich | Keine Figuren |
| Umgebung | Windows; kein Windows-Export-Preset im Repo |
| Evidenz | Stale-Check nur `project.godot` + `assets/art`; Export wird trotzdem zuerst gestartet. `Run_windows.bat` existierte nicht. `.godot/` ist gitignored → ohne `--import` kann `ResourceLoader.exists` auf einem Frisch-Clone fehlschlagen (leeres Sprite). |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) Alter Export trotz Skip (2) Alias fehlt (3) Kein Import auf Windows-Clone (4) z_index |
| Bestätigte Ursache | (1) Stale-Check ignoriert `scripts/`/`scenes/`; kopierte Exe mit frischem mtime gilt als „frisch“. Starter **bevorzugt** Export. Kein Windows-Preset → jede `build\windows\*.exe` ist inoffiziell. (2) Nutzer startet `Run_windows.bat` — Datei fehlte. (3) Ohne `.godot/imported` keine Texturen. |
| Nicht die Ursache | Fehlende PNG im Repo (Linux-Tests: RobotSprite texture+visible) |
| Fix-Richtung | Projektmodus Standard; `--import` beim ersten Start; `Run_windows.bat` Alias; Export nur mit `PLAY_USE_EXPORT=1` |
| Risiken | Erster Start etwas länger (Import) |

- [x] RCA dokumentiert

---

## Scope

### In

- `play-windows.bat`: immer Godot `--path` (aktuelle Sprites); Import wenn `.godot\imported` fehlt
- `Run_windows.bat` ruft denselben Starter auf
- Export nur bei `PLAY_USE_EXPORT=1` und nicht stale (`scripts`, `scenes`, `assets`, `project.godot`)
- Regressionstests auf die Starter-Dateien

### Nicht

- Linux/macOS-Starter umbauen, Windows-Export-Preset, neue Art

---

## Technische Schritte

1. `play-windows.bat` umbauen (Projektmodus zuerst, Import, optionales Export).
2. `Run_windows.bat` Alias.
3. Tests: Alias existiert, `--path`/`--import`, Export nicht default.
4. README-Zeile.

---

## Testplan

### Automatisiert

- [x] `Run_windows.bat` existiert und ruft `play-windows.bat` auf
- [x] `play-windows.bat` enthält `--path` und `--import`
- [x] Export-Start ist an `PLAY_USE_EXPORT` gebunden
- [x] World: RobotSprite sichtbar + Texture (bestehend)

### Playtest / Smoke

- [x] Suite grün; Scene startet

---

## Art-Bedarf

- [x] Keine neuen Assets

---

## Akzeptanzkriterien

- [x] `Run_windows.bat` und `play-windows.bat` starten den Projektstand mit Figuren (Linux: Dateien + `--path`-Default verifiziert; Windows Doppelklick manuell)
- [x] Kein stilles Starten eines veralteten Windows-Exports (`PLAY_USE_EXPORT=1` Pflicht)
- [x] Tests grün, Review ohne Critical/High, Playtest Pass

---

## Playtest (2026-08-11)

Pass. Art alpha 181 PNGs; `play_windows_launcher_test` + Suite grün; RobotSprite visible+texture, `z_as_relative=false`. Smoke `godot --path . --quit-after 5` exit 0. Verbleibend: Doppelklick der `.bat` auf einem Windows-PC.
