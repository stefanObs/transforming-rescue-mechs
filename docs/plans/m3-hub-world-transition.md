# Plan: m3-hub-world-transition

**Status:** Erledigt  
**Typ:** Feature (+ Review-Bugfix)  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/mvp.md`](mvp.md) Epic M3 · [`docs/plans/m3-seuzach-ohringen-world.md`](m3-seuzach-ohringen-world.md) (Slice 1 Done, Hub↔World deferred) · [`docs/KONZEPT.md`](../KONZEPT.md) §4/§15 · [`docs/ENTWICKLUNGSABLAUF.md`](../ENTWICKLUNGSABLAUF.md)  
**Art:** Stil C — [`docs/STYLE-BIBLE-C.md`](../STYLE-BIBLE-C.md) · bestehende `hub_station.png` bevorzugen

---

## Ziel

M3 abschließen: begehbare **Erdstation-Hub**-Scene, bidirektionaler Scene-Wechsel **Hub ↔ World** mit stabilem Spawn nahe `hub_station`, sowie **Gebäude-Kollision** auf den großen Landmark-/Haus-Props — damit Seuzach+Ohringen inkl. Hub spielbar und erkundbar ist.

---

## Scope

### In

- **Hub-Scene** `scenes/hub_station.tscn` + Script: Style-C Innenhof/Hof mit bestehendem `assets/art/hub_station.png` (optional einfacher Polygon-Boden); Player instanziieren/bewegen; klare Exit-Zone/Trigger zurück zur World
- **World → Hub:** am Prop `hub_station` eine interaktive Enter-Zone (`Area2D`, Action `interact` und/oder Auto-Enter bei klarer Zone) → `change_scene` zur Hub; Spawn-Position in World merken
- **Hub → World:** Exit → zurück zu `world_sandbox.tscn` (oder aktueller Main-World); Spieler spawnt an der gemerkten Position (Fallback: Offset neben `hub_station` im Dorfkern)
- **Gebäude-Kollision:** `StaticBody2D` (+ `CollisionShape2D`, z. B. Rectangle/Capsule approximiert am Footprint) an major Landmark-/House-Props, sodass der Player nicht durch Bahnhof, Feuerwehr, Kirchen, Schulen, Häuser etc. läuft
- Physics-Layer konsistent: Layer 1 `world` (wie `player.tscn`: `collision_layer = 1`, `collision_mask = 1`)
- **Tests:** headless Scene-Wechsel Hub↔World; Spawn nach Exit; mind. ein Gebäude-Prop hat `StaticBody2D`; Suite grün (`scripts/run_tests.sh`)
- Playtest-Checks laut MVP-M3: Karte erkundbar, Hub erreichbar

### Nicht

- Neues Hub-Interior-Art-Set (Garage-UI, Werkbank-Sprites, Multi-Room) — nur wenn Prop+Polygone wirklich nicht reichen; Default: **keine** neue Art
- Missionen / Dispatcher (M5), Save-Slots (M6), Energie-Stop / Waffen (M4)
- Vollständiger TileMap-Rewrite; OSM-Genauigkeit
- Collision auf jedem kleinen Deko-Prop / jedem RoadKit-Stück
- Online, andere Orte, neue spielbare Charaktere
- Ändern der Landmark-Layout-Koordinaten aus Slice 1 (außer minimal für Enter-Zone / Spawn-Offset)

---

## Systeme

| System | Rolle |
|--------|--------|
| Hub | Neu: `scenes/hub_station.tscn` + `scripts/hub_station.gd` — Player, Boden, Exit-Trigger, Hint-UI |
| World | `scenes/world_sandbox.tscn` + `scripts/world_sandbox.gd` — Enter-Zone am `hub_station`-Prop; Spawn nach Rückkehr; Collision an Props |
| GameState | Autoload erweitern: z. B. `world_spawn_position: Vector2` / `pending_world_spawn` + Helper `set_world_spawn` / `consume_world_spawn` (kein Persistenz-Zwang in M3) |
| Player | Bestehende `scenes/player.tscn` / `scripts/player.gd` wiederverwenden; Layer 1; `interact` bereits in Input-Map |
| Props | `_add_prop` erweitern oder Follow-up: nach Sprite-Create optional Collision-Child; Enter-Zone als Sibling/Child am Hub-Prop |
| Physics | `project.godot` Layer 1 = `world` — StaticBodies und Player darauf halten |
| Tests | Neu: `tests/m3_hub_transition_test.gd` (+ Suite-Eintrag in `scripts/run_tests.sh`); bestehende `m3_world_landmarks_test` weiter grün |
| Art | Default: `hub_station.png` wiederverwenden; optional `comic-rettung-art` nur bei echtem Interior-Backdrop-Bedarf |

---

## Repro & RCA

**Finding:** Code-Review nach Hub↔World-Implementierung (Critical): HubEnter / Default-Spawn überlappen `hub_station` BuildingCollision.

### Repro

1. World laden; Hub-Prop bei `(40, 300)` mit BuildingCollision (~y 287–345, w≈134).
2. HubEnter bei `(40, 360)`, Größe `120×70` → Enter-y ≈ 325–395.
3. Player-Capsule: r=14, h=40, Offset `(0,-12)` → bei Position Y reicht die Capsule von `Y−32` bis `Y+8`.
4. An Enter-Zentrum `(40, 360)` schneidet die Capsule das StaticBody; freier Streifen nur ~y 392–395 (~4px). Default-Spawn `(40, 340)` liegt im Solid.

**Erwartet:** Enter-Zentrum und Default-Spawn mit Capsule klar südlich der Hub-Kollision; nutzbare Enter-Fläche ≫ Capsule.

**Ist:** Enter praktisch blockiert; Fallback-Spawn im Solid.

- [x] Repro bestätigt (Geometrie-Rechnung + Review)

### RCA

- **Ursache:** Enter/Spawn wurden relativ zum Visual-Ursprung gewählt, ohne Capsule-Extent gegen den berechneten Hub-Footprint zu prüfen.
- **Nicht Ursache:** Layer-Mask, Scene-Wechsel-API, fehlende Area2D.
- **Fix-Richtung:** `HUB_ENTER_POS` / `DEFAULT_WORLD_SPAWN` weiter südlich; Regressionstest Capsule-AABB vs. Hub-Collision; optional Hub-Footprint leicht verkleinern.
- **Risiko:** Spawn etwas weiter vom Gebäude — UX ok wenn Hint/Enter klar bleiben.

---

## Technische Schritte

1. **GameState-Handoff**  
   Felder für World-Spawn (Position, optional Character/Form wenn nötig) + klare API: vor Hub-Enter speichern; beim World-`_ready` anwenden und zurücksetzen. Kein SaveService-Zwang.

2. **Hub-Scene bauen**  
   - `hub_station.tscn`: Node2D/Root, einfacher Ground (Polygon2D Farbe Style-C Gras/Hof), großes Hub-Sprite (`hub_station.png`), `Player`-Instanz, Kamera-Follow (wie World oder einfach), Status/Hint-Label  
   - Exit: `Area2D` (Name/Meta z. B. `hub_exit`) + sichtbarer Marker oder Hint „E / A — Zurück zur Welt“  
   - Bei Exit: `GameState` Spawn setzen falls noch nicht gesetzt → `get_tree().change_scene_to_file("res://scenes/world_sandbox.tscn")`  
   - Bewegung: gleiche Input-Actions wie World; Pause optional stub

3. **World Enter-Zone**  
   - Am `hub_station`-Prop (Dorfkern, ~`(40, 300)`): `Area2D` Enter-Trigger (vor dem Gebäude / neben Spawn-Offset, nicht mit StaticBody blockierend überlappend)  
   - On `interact` (und optional body_entered + Prompt): aktuelle Player-Position (+ Offset vor Hub) in `GameState` speichern → Scene-Wechsel zu Hub  
   - World `_ready`: wenn pending Spawn gesetzt, Player dorthin setzen; sonst Default-Spawn beibehalten

4. **Gebäude-Kollision**  
   - In `_add_prop` (oder Helper `_attach_building_collision(spr)`): für Landmarken / Houses / Kirchen / Schulen / Hub-Prop einen `StaticBody2D` mit `collision_layer = 1`, `collision_mask = 1` und approximiertem Shape (Rectangle skaliert an Texture-Größe × Sprite-Scale; Footprint eher unten am Offset)  
   - Major props: Bahnhof, Feuerwehr, Badi, Kirchen, Gemeindehaus, Schulen, Kigas, Tankstelle, Restaurants, Läden, Houses, `hub_station`  
   - Enter-Zone des Hub **nicht** durch Building-Collision unbenutzbar machen (Zone vor dem Gebäude oder Collision etwas kleiner als Visual)  
   - Keine RoadKit-Mittellinien-Kollision

5. **Hints / UX**  
   - World-Hint nahe Hub: „Erdstation betreten“ wenn in Zone  
   - Hub-Hint: Exit-Hinweis  
   - Status-Zeile darf Scene nennen (Hub vs. Seuzach)

6. **Tests + Suite**  
   - Siehe Testplan; neuen Test in `scripts/run_tests.sh` eintragen

7. **Review → Playtest**  
   - `code-reviewer` → `godot-playtester`  
   - Nach Pass: MVP-M3-Checkboxen in `mvp.md` aktualisieren (Collision, Hub Ein-/Ausfahrt, Tests, Playtest, Akzeptanz)

8. **Abschluss**  
   - Commit / Push / Tag laut Repo-Regeln (nach Phase-4-Pass)

---

## Testplan

### Automatisiert

- [x] `hub_station.tscn` und `world_sandbox.tscn` laden ohne Error
- [x] Headless: World → Hub Scene-Wechsel (Enter-API oder direkte `change_scene` + Hub lädt mit Player)
- [x] Headless: Hub → World; nach Rückkehr Player-Position ≈ gespeicherter Spawn (Toleranz) bzw. nahe `hub_station`-Prop
- [x] Mindestens ein Landmark-/House-Prop hat Kind `StaticBody2D` (bzw. Meta `has_building_collision`); ideal: Stichprobe mehrerer Major-IDs (`bahnhof`, `feuerwehr`, House)
- [x] Player `collision_layer`/`mask` und Building-StaticBody beide Layer 1 (`world`)
- [x] Bestehende Suite inkl. `m3_world_landmarks_test` bleibt grün

### Playtest / Smoke

- [x] Main-World startet ohne Fatal Error
- [x] Spieler läuft/fährt zu Erdstation, betritt Hub, bewegt sich im Hub, verlässt Hub, erscheint neben Station
- [x] Karte weiter zwischen Districts erkundbar
- [x] Spieler kann nicht durch Bahnhof / Feuerwehr / typisches Haus laufen
- [x] Hub-Enter nicht durch eigene Building-Collision blockiert
- [x] Keine Regression: Transform, Facing, RoadKit, Y-Sort plausibel

---

## Art-Bedarf

- [x] **Keine neuen Assets (Default)** — `assets/art/hub_station.png` + einfache Polygone für Hub-Boden/Hof reichen
- [ ] Nur falls Playtest/Review Interior unleserlich: Backdrop via Subagent **`comic-rettung-art`** (Stil C), Naming z. B. `hub_interior_yard.png`; danach Alpha-Pipeline (`process_art_alpha.py` / `verify_art_alpha.py`) und ggf. `godot --headless --import`

---

## Akzeptanzkriterien

- [x] Hub-Scene spielbar (bewegen + Exit)
- [x] Bidirektionaler Wechsel Hub ↔ World mit stabilem Spawn nahe Erdstation
- [x] Major Landmark-/House-Props blockieren Player (Layer 1)
- [x] Automatisierte Tests für Transition, Spawn, StaticBody grün; volle Suite grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass: Karte erkundbar, Hub erreichbar
- [x] MVP M3: Open-World Seuzach + Hub spielbar (Checkboxen in `mvp.md` auf Erledigt / Fortschritt 8/8)

---

## Hinweise für Implementer

- Hub↔World war bewusst aus `m3-seuzach-ohringen-world.md` deferred — Layout/Art der World nicht neu erfinden.
- `interact` ist bereits gemappt (`InputSetup`: E / Joy A).
- Collision-Shapes grob ok für MVP; perfekte Iso-Footprints nicht nötig.
- M4 „Kollisions-Stop + Energie“ bleibt separat; hier nur physisches Blockieren ohne Energie-Kosten.
