# Slice: S01 — Spawn auf Winterthurerstrasse (Dorfkern)

**Status:** Playtest / Erledigt  
**Typ:** Bugfix  
**Parent:** `docs/plans/m3-spawn-winterthurer-roads-visible/INDEX.md`  
**Datum:** 2026-08-11  
**Hängt ab von:** —

Dieses File ist der **Schritt**. Phase 1 (`feature-planner`) füllt es zum vollständigen Plan; Phase 2–4 gelten nur für **diesen** Slice.

## Ziel

Beim World-Start (`world_sandbox`, kein gespeicherter Spawn) steht die Spielfigur **auf der Winterthurerstrasse** in Zelle **WINT-KERN** (Dorfkern, Kirche-Ost) — nicht mehr im Gras südlich der SOCAR Forrenberg. Die Kamera folgt dem Player; der Startpunkt liegt auf einem OSM-Vertex der Polyline (Abstand ~0).

## Grenzen

- In:
  - `SeuzachGeo.default_world_spawn()` als einzige Quelle für den Default-World-Spawn
  - Leser/Kommentare: `game_state.gd`, `world_sandbox.gd`, `hub_station.gd`, `scenes/world_sandbox.tscn` (Player-`position` + passender Editor-`z_index`)
  - Spawn-Punkt **auf** der OSM-Polyline `Winterthurerstrasse` in WINT-KERN (Vertex, nicht daneben ins Gras)
  - Tests: `tests/m3_road_debug_test.gd` (Feld + Polyline-Abstand); Hub-Tests nur Kommentare / explizite HubEnter-Forrenberg-Asserts, **keine** HubEnter-Koordinatenänderung
- Nicht (andere Slices / Rest der Aufgabe):
  - Strassenzeichnung, Half-Widths, JSON-Load, Z-Order, Kamerazoom (`S02`)
  - `hub_enter_pos()` / `HUB_ENTER_SOUTH_WU` / Forrenberg-Hub-Transition
  - Ohringen, Housing, Landmarken-Art, neue Grafiken
  - Gesamtes Strassennetz, zweite Winterthurer-Teilstrecke (Nord, y≈−5400)
- Raster / Felder / GPS / Asset-Namen:
  - Zelle **WINT-KERN**: Felder `ix 30..45`, `iy −15..10` (inklusiv)
  - Kirche = Ursprung `(0,0)`; 1 Feld = 100 wu
  - Gewählter Punkt: `Vector2(3861.9, -101.0)` → Feld `(38, −2)`
  - Ist-Bug: `forrenberg_world() + (0, SPAWN_SOUTH_WU)` ≈ `(13032.7, 15324.4)` = Feld `(130, 153)`

## Systeme

World-Spawn, `SeuzachGeo`, `GameState.world_spawn_position`, World-Sandbox Player-Start, Hub-Return **nur** wenn kein gespeicherter Spawn (`has_world_spawn == false`). RoadKit / `seuzach_roads.json` nur als **Lage-Referenz** (keine Zeichen-Änderungen).

## Repro & RCA (Pflicht bei Typ = Bugfix)

### Reproduktion

- [x] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. `scenes/world_sandbox.tscn` starten (kein `GameState.has_world_spawn`). 2. Player-`global_position` bzw. F1-Statusfeld notieren. 3. Abstand zur nächsten benannten OSM-Strasse und zur Winterthurer-Polyline messen. |
| Erwartet | Start **auf der Karte**, auf Winterthurerstrasse in WINT-KERN (Asphalt-Lage; Sichtbarkeit des Asphalts = S02). |
| Tatsächlich | Spawn = `SeuzachGeo.default_world_spawn()` = `forrenberg_world() + (0, 200)` ≈ `(13032.7, 15324.4)` = Feld `(130, 153)`. Nächste benannte OSM-Strasse: **A1** bei ~749 wu (Player auf Gras, nicht Asphalt). Winterthurerstrasse führt **nicht** am Forrenberg vorbei. User-Playtest: nur Grün; Wunsch: Start auf Winterthurerstrasse. |
| Umgebung | Godot 4, `world_sandbox`, Player-Kamera `zoom = (0.9, 0.9)`, Gras = `SeuzachGeo.WORLD_BOUNDS`, HubEnter unverändert Forrenberg |
| Evidenz | Code: `scripts/seuzach_geo.gd` `default_world_spawn`; `scenes/world_sandbox.tscn` Player `position = Vector2(13033, 15324)`; OSM `data/seuzach_roads.json` Winterthurer-Vertex `(3861.9, -101.0)` liegt in WINT-KERN, Forrenberg nicht. |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) Spawn fest auf SOCAR Forrenberg + `SPAWN_SOUTH_WU` — ausserhalb WINT-KERN, abseits Winterthurerstrasse. (2) Road-JSON/Half-Widths/Z-Order/Zoom machen den Start-Viewport leer. (3) HubEnter und World-Spawn sind dieselbe Konstante. |
| Bestätigte Ursache | `default_world_spawn()` ist hardwired auf `forrenberg_world() + Vector2(0, SPAWN_SOUTH_WU)`. Der Punkt liegt ausserhalb WINT-KERN und nicht auf der Winterthurer-Polyline. Die Kamera (Child des Players) zeigt deshalb leeres Gras. |
| Nicht die Ursache | Road-JSON, Half-Widths, Z-Order, Kamerazoom — ausser dass der **Spawn-Ort** die Kamera auf Gras richtet (Sichtbarkeit am *richtigen* Spawn = **S02**). HubEnter ist **nicht** die Spawn-Quelle. |
| Fix-Richtung | `default_world_spawn()` gibt den Winterthurer-Vertex in WINT-KERN zurück. `hub_enter_pos()` bleibt Forrenberg. Leser, die `default_world_spawn()` aufrufen, ziehen automatisch mit (inkl. Hub-Return ohne gespeicherten Spawn — gewollt). |
| Risiken | Tests/Kommentare, die Default-Spawn mit Forrenberg gleichsetzen (`m3_hub_transition_test` Kommentar; `hub_station` Kommentar). Spieler startet nicht mehr neben HubEnter (gewollt). `SPAWN_SOUTH_WU` wird tot, wenn Spawn nicht mehr davon abhängt. Editor-tscn-Position vs. Runtime-`_ready`. |

- [x] RCA dokumentiert

## Technische Schritte

1. **Regression zuerst (rot):** In `tests/m3_road_debug_test.gd` nach dem bestehenden Spawn-Feld-Check ergänzen:
   - `spawn` in WINT-KERN: `ix ∈ [30, 45]`, `iy ∈ [−15, 10]`
   - Abstand Spawn → Winterthurerstrasse-Polyline (Ground-`road_points` / `_nearest_segment_tangent_dist`) **≤ 40 wu** (Main-`half_w` = 72; Vertex-Soll ~0)
   - Spawn **nicht** gleich `forrenberg_world() + Vector2(0, 200)` (bzw. alte `SPAWN_SOUTH_WU`-Formel)
   - Status nach F1 enthält `Feld 38,-2` (Raster 100)
2. **`SeuzachGeo`:** Konstante z. B. `WINTERTHURER_SPAWN := Vector2(3861.9, -101.0)` (OSM-Vertex der ersten `Winterthurerstrasse`-Polyline in `data/seuzach_roads.json`, Index 12: nächstliegender Sample zur Kirche). `default_world_spawn()` gibt genau diesen Punkt zurück. Kommentar Forrenberg-Spawn ersetzen. `SPAWN_SOUTH_WU` entfernen, falls danach unbenutzt. **`hub_enter_pos()` / `HUB_ENTER_SOUTH_WU` nicht anfassen.**
3. **Kommentare der Leser** (Verhalten kommt schon über den Getter):
   - `scripts/autoload/game_state.gd`: Default-Kommentar nicht mehr „Forrenberg / A1“
   - `scripts/hub_station.gd`: `DEFAULT_WORLD_SPAWN` bleibt `SeuzachGeo.default_world_spawn()`; Kommentar nicht mehr „Tankstelle Forrenberg“. `exit_to_world_for_test()` setzt nur bei `not has_world_spawn` diesen Default — Return-ohne-Save landet auf Winterthurer (**gewollt**). Mit gespeichertem Spawn (Enter vom Forrenberg-HubEnter) bleibt Return am gespeicherten Punkt.
   - `scripts/world_sandbox.gd`: Kommentar trennen — HubEnter Forrenberg, Default-Spawn Winterthurer/WINT-KERN. `_ready` weiter `DEFAULT_WORLD_SPAWN` wenn kein Save.
4. **`scenes/world_sandbox.tscn`:** Player `position` auf `Vector2(3861.9, -101.0)` (nicht `13033, 15324`). Editor-`z_index` an `compute_actor_z(-101)` anpassen: `2000 + floor(-101/20) + 1 = 1995` (`_ready` überschreibt zur Laufzeit, TSCN soll nicht Forrenberg vortäuschen).
5. **Hub-Tests:** `HUB_ENTER_POS` / Assert „HubEnter centered at HUB_ENTER_POS“ behalten. Kommentar „defaults (Forrenberg, south of hub)“ korrigieren: Default-**World**-Spawn ≠ HubEnter. Spawn-Capsule vs. Forrenberg-Gebäude bleibt gültig (Spawn ist dann weit weg). Keine Road-Drawing-Änderungen.
6. Suite `./scripts/run_tests.sh`; Playtest nur Lage (S02 darf Asphalt noch unsichtbar lassen).

## Testplan

### Automatisiert

- [x] Bei Bugfix: Regressionstest bildet die Repro ab (zuerst rot: Forrenberg-Spawn nicht in WINT-KERN / Abstand Winterthurer ≫ 40; nach Fix grün)
- [x] `default_world_spawn` = `Vector2(3861.9, -101.0)` (oder `is_equal_approx` / Distanz 0 zum Vertex)
- [x] Spawn-Feld `(38, −2)` via `DebugGrid.world_to_cell(..., 100)`
- [x] Spawn in WINT-KERN (`30..45`, `−15..10`)
- [x] Abstand Spawn → Winterthurerstrasse-Polyline **≤ 40 wu**
- [x] Spawn ∈ `SeuzachGeo.WORLD_BOUNDS`
- [x] Spawn ist **nicht** `forrenberg_world() + (0, 200)`
- [x] Player in `world_sandbox` ohne Save steht auf dem Default-Spawn (bestehender Feld-Check in `m3_road_debug_test`)
- [x] HubEnter bleibt `SeuzachGeo.hub_enter_pos()` / Forrenberg (`m3_hub_transition_test`)
- [x] `GameState.reset_for_new_game` stellt `world_spawn_position` auf den **neuen** Default
- [x] Suite grün; keine Änderungen an Road-Width-/JSON-/Zoom-Asserts

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error
- [x] Bei Bugfix: manuelle Repro schlägt nicht mehr fehl — Startfeld ist WINT-KERN / Winterthurerstrasse, nicht Forrenberg `(130, 153)`
- [x] F1: Status `Feld 38,-2` (Raster 100); Figur steht auf der Winterthurer-Trasse (Koordinaten/Debug-Name), auch wenn Asphalt visuell noch „nur Grün“ ist (**S02**)
- [x] HubEnter unsichtbar am Forrenberg; Hub-Enter/Exit mit gespeichertem Spawn unverändert
- [x] Nur dieser Slice: keine Road-Width-, JSON-, Z-Order- oder Kamera-Fixes

## Art-Bedarf

- [x] Keine neuen Assets
- [ ] Neue Grafiken → `comic-rettung-art` **nur** für die Assets dieses Slices  
  Details: n/a — nur Spawn-Koordinaten. Style C / Alpha-Pipeline / Seuzach-Housing nicht betroffen.

## Akzeptanzkriterien

- [x] Grenzen eingehalten (nichts aus Nachbar-Slices, insbesondere kein S02-Road-Fix)
- [x] Bei Bugfix: Repro + RCA erledigt (bestätigt)
- [x] `default_world_spawn` auf Winterthurer-Vertex `(3861.9, -101.0)` in WINT-KERN; Abstand zur Polyline ≤ 40 wu
- [x] `hub_enter_pos` unverändert Forrenberg
- [x] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [x] Playtest Pass (Lage; Asphalt-Sichtbarkeit darf S02 sein)
- [ ] Git: Commit + Push + Tag für **diesen** Slice
