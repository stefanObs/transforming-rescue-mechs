# Plan: windows-figures-visible

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-10  
**Owner:** Hauptagent

## Ziel

Spielerfiguren (Bolt/Marina/Rush) sind unter Windows wieder zuverlässig sichtbar — gleicher Startpfad wie Linux/macOS (kein veralteter Export).

## Scope

- In:
  - `play-windows.bat` — Stale-Export-Skip wie Linux/macOS
  - `scripts/world_sandbox.gd` — Actor-`z_index` bereits in `_ready` setzen
  - Regressionstest: Sandbox-Player hat sichtbares RobotSprite mit Texture
- Nicht: neue Art; Renderer-Wechsel; Windows-Export-Preset (optional Follow-up)

## Systeme

Play-Scripts, World Z-Order, Player-Visual Smoke

## Repro & RCA (Pflicht bei Typ = Bugfix)

### Reproduktion

- [x] Repro bestätigt (Code-Pfad + Plattform-Differenz; Linux-Screenshot: Figuren sichtbar)
- [ ] Nicht reproduzierbar

| Feld | Inhalt |
|------|--------|
| Schritte | 1. Auf Windows Repo öffnen 2. `play-windows.bat` wenn `build\windows\*.exe` existiert (oder nach altem Export) 3. Sandbox starten |
| Erwartet | Mech/Fahrzeug-Sprite sichtbar an Spawn |
| Tatsächlich | Figuren fehlen / wirken unsichtbar (Nutzer Windows) |
| Umgebung | Windows, `play-windows.bat`; Linux-Kontrolllauf: Figuren sichtbar (`godot --path`) |
| Evidenz | `play-linux.sh` / `play-macos.sh` kommentieren explizit: „Stale exports are skipped so current sprites are visible.“ `play-windows.bat` startet **jeden** existierenden Export ohne Altersprüfung |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) Veralteter Windows-Export ohne aktuelle Sprites/Z-Order (2) Actor-z erst ab erstem `_process` (3) Texturen/Alpha kaputt |
| Bestätigte Ursache | (1) Primär: Windows-Starter bevorzugt Export **ohne** Stale-Check → alter Stand kann Figuren unter Boden / ohne Art zeigen. Linux-Projektmodus zeigt Figuren (Screenshot + Headless: RobotSprite vis+texture). (2) Härten: z sofort in `_ready`. (3) Widerlegt lokal (opaque Art, Tests grün) |
| Nicht die Ursache | Fehlende Diagonal-Art im Repo; Kreisel-Parameter |
| Fix-Richtung | Stale-Export-Skip in `play-windows.bat`; Actor-z in `_ready`; Test auf visible+texture |
| Risiken | Frischer Export weiterhin bevorzugt; Hinweis-Text wenn Export übersprungen wird |

- [x] RCA dokumentiert und reviewed

## Technische Schritte

1. `play-windows.bat`: Export nur starten wenn neuer als `project.godot` und neueste Datei unter `assets/art`; sonst Hinweis + Godot `--path`.
2. `world_sandbox.gd`: `_ready` setzt `_player.z_index = compute_actor_z(...)`.
3. Test erweitern (`m2_world_test` oder `m2_player_visual_test`): nach Laden von `world_sandbox.tscn` → RobotSprite `visible` und `texture != null`.
4. Review → Playtest → Release.

## Testplan

### Automatisiert

- [x] Sandbox-Player: RobotSprite sichtbar + Texture
- [x] Bestehende Visual-/Facing-/Walk-Tests grün

### Playtest / Smoke

- [x] `godot --path .` — Figur sichtbar
- [x] Art-Alpha verify grün
- [x] Suite grün

## Art-Bedarf

- [x] Keine neuen Assets

## Akzeptanzkriterien

- [x] Windows-Starter überspringt veralteten Export
- [x] Actor-z ab `_ready` korrekt
- [x] Regressionstest Sichtbarkeit
- [x] Review ohne Critical/High
- [x] Playtest Pass
