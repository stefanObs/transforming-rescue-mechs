# Plan: seuzach-grid-housing / Slice S01

**Status:** Entwurf  
**Typ:** Feature  
**Datum:** 2026-08-29  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/seuzach-grid-housing/INDEX.md`  
**Slice-Datei:** `docs/plans/seuzach-grid-housing/S01-quartier-raster-kirche-wint-west.md`  
**Hängt ab von:** —

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Ziel

Housing hängt an **benannten F1-Quartier-Zellen** (Feld-Rechtecke, Kirche = Ursprung, 100 wu) statt an ad-hoc Radius-Zentren. Spieler sieht maps-plausible Wohnzeilen in **KIRCHE-KERN** und **WINT-WEST**; das bisherige Spawn-/Kirche-Korridor-Housing aus `buildings-visible-at-play` ist in dieselbe Logik überführt — **ohne Doppel-Stacks** am Spawn-Band.

## Scope

### In

- **Quartier-Registry / Placement-API:** benannte Zellen mit Feld-`ix`/`iy`-Bounds + Straßenband-Namen; Filter über bestehendes F1 (`SeuzachGeo.FIELD_WU` / `DebugGrid.world_to_cell`) — **kein** zweites Koordinatensystem
- **Migration** von `_place_spawn_housing()`: Spawn- und Kirche-Radius-Calls → Quartier-Placement für `KIRCHE-KERN` + `WINT-WEST`; gemeinsames `placed[]` über alle Housing-Passes
- Wohnzeilen **KIRCHE-KERN** (Kirchgasse / Kirchhügelstrasse / Winterthurer-Kern im Zell-Rechteck) und **WINT-WEST** (Winterthurerstrasse westlich-zentral inkl. Spawn-Flanke)
- Bestehende Style-C `house_street_*_{ew,ns}`; Off-Road, Landmark-Clearance, street-aligned Bearing / `flip_h` wie heute — **kein** `Sprite2D.rotation`
- Feldspannen laut INDEX (±10 Felder ok, solange Paar + Straßenbindung klar bleiben)
- Suite: Quartier-Felder haben Wohnprops; bestehende Spawn-/Facing-/Bearing-Garantien bleiben grün (Meta ggf. erweitert)

### Nicht

- WINT-NORD, LAND-MITTE, STAT-*, REUT-*, BREITE, SEEBUEHL, OHR-* (S02–S06)
- Schulen / Kigas / Bahnhof / Badi / Civic / Shops neu setzen oder verschieben
- Neue Haus-Art (`comic-rettung-art` nicht)
- Autobahn-/Forrenberg-Wohnsiedlung; Vollflächen-Fill ohne Straßenband
- Schneckenwiese-/Reutlinger-**Quartier** als neue Zelle (→ später REUT-Slices); siehe Technische Schritte für **Interim**-Erhalt

## Systeme

| System | Rolle |
|--------|--------|
| `scripts/world_sandbox.gd` | Registry + `_place_spawn_housing` → Quartier-API; `_place_housing_along_roads` um Feld-Rect-Filter erweitern oder Wrapper |
| `scripts/seuzach_geo.gd` | `FIELD_WU=100`, Kirche-Ursprung, `WINTERTHURER_SPAWN` (unverändert) |
| `scripts/debug_grid.gd` | `world_to_cell` / Zell-Semantik wiederverwenden (kein Parallel-Grid) |
| `%Ground` RoadKit-Marker | `road_name` / `road_points` / `half_w` — Namen aus `data/seuzach_roads.json` |
| `assets/art/house_street_*_{ew,ns}.png` | Bestehende Varianten; Zyklus unverändert |
| `tests/m3_world_landmarks_test.gd` | Spawn-/Corridor-/Facing-/Bearing-Asserts anpassen (Quartier-Meta, keine Doppel-Props) |

### Straßenbindung (Datenstand)

| Quartier | Feld-Rect (INDEX, ±10 ok) | Named roads (Schnitt mit Rect) |
|----------|---------------------------|--------------------------------|
| KIRCHE-KERN | ix −15..25, iy −30..25 | `Kirchgasse`, `Kirchhügelstrasse`, `Winterthurerstrasse` (nur Segmente/Samples im Rect) |
| WINT-WEST | ix 20..50, iy −35..40 | `Winterthurerstrasse` (inkl. Spawn ~Feld 38,−2) |

Überlapp ix 20..25: nur **ein** Prop pro Spot via shared `placed` + `min_house_sep`.

## Technische Schritte

1. **Quartier-Registry** (Konstante/Dict in `world_sandbox.gd` oder kleines `scripts/housing_quarters.gd` — erweiterbar für S02+):  
   Pro Eintrag: `id`, `ix_min`/`ix_max`/`iy_min`/`iy_max`, `roads: Array[String]`.  
   S01-Inhalt nur `KIRCHE-KERN` + `WINT-WEST` mit INDEX-Spannen.  
   Hilfsfunktion `quarter_contains_world(id, pos) -> bool` via `floor(pos / FIELD_WU)` bzw. `DebugGrid.world_to_cell`.

2. **Placement-API**  
   - Bevorzugt: `_place_housing_along_roads` um optionalen **Feld-Bounds-Filter** erweitern (Sample-Punkt muss in Rect liegen; Radius-Parameter entfällt oder wird `INF`/unused wenn Bounds gesetzt).  
   - Oder Wrapper `_place_housing_in_quarter(quarter_id, …)` der Roads aus der Registry nimmt und Samples verwirft, wenn `world_to_cell` außerhalb.  
   - Unverändert lassen: Spacing (~250), Setback/`HOUSE_CURB_SLACK`, Bearing-Pick, Facing, Meta `house_variant` / `street_side` / `faces_street` / `street_name` / `street_bearing`, `HOUSE_SCALE`.

3. **Migration `_place_spawn_housing()`**  
   - Ersetzen der drei Radius-Zentren durch:  
     a) Schleife über Registry-Quartiere S01 → Placement mit Meta `housing_quartier` = Zell-ID.  
     b) **Doppel-Stack-Schutz:** ein gemeinsames `placed: Array[Vector2]` über alle Quartiere (+ Interim unten).  
   - Mapping Alt → Neu (für Meta/Tests):  
     - früher `housing_corridor == "spawn"` ⊂ **WINT-WEST** (Winterthurer nahe Spawn)  
     - früher `"kirche"` ⊂ **KIRCHE-KERN** (Kirchgasse/Kirchhügel + Winterthurer im Kern-Rect)  
   - `housing_corridor`: entweder ableiten (`spawn`/`kirche` aus Quartier+Nähe) **oder** Suite auf `housing_quartier` umstellen und alte Corridor-Counts ersetzen. Ziel: bestehende Facing-/Bearing-Logik bleibt gültig; **keine** zwei Props am gleichen Spawn-Curb.

4. **Interim Schneckenwiese** (bis REUT-Slices)  
   - Heutiger dritter Call (`schneckenwiese`, Reutlinger/Schneckenwiesen/Winterthurer-Nord) ist **kein** neues S01-Quartier.  
   - **Behalten** als einen Legacy-Corridor-Pass mit demselben `placed[]`, damit Viewport-Ost und Suite `schn_n` nicht regressieren — **oder** Counts in Tests bewusst absenken und Lücke dokumentieren (nur wenn Legacy-Pass die Quartier-API verkompliziert). Default: Legacy-Pass behalten, klar kommentiert „temporary until S04“.  
   - Keine neue Dichte / keine REUT-Zellen-Registry in S01.

5. **Meta**  
   - Neu: `housing_quartier` ∈ {`KIRCHE-KERN`,`WINT-WEST`} für Quartier-Props; Legacy-Schneckenwiese ohne Quartier-ID oder mit leerem/kein Key.  
   - Landmark-Clearance, Spawn-Sep, Off-Road-Nudge unverändert.

6. **Tests (`m3_world_landmarks_test.gd`)**  
   - Neu/angepasst: Props mit `housing_quartier` in KIRCHE-KERN- bzw. WINT-WEST-Feld-Rect (`world_to_cell` in Bounds); je Quartier sinnvolle Untergrenze (Richtwert ≥4–6).  
   - Spawn-Viewport @ Zoom 0.9 weiterhin ≥3 Häuser; `HOUSE_SCALE` / Landmark-Scales / Spawn unverändert.  
   - **Keine Doppel-Stacks:** keine zwei `house_variant`-Props mit Distanz ≪ `min_house_sep` (z. B. Assert min pairwise sep unter tagged houses, oder Count-Stabilität vs. Pre-Migration).  
   - `_assert_corridor_housing` / `_roads_for_housing_sprite`: Corridor-IDs erweitern oder auf Quartier+`street_name` umbiegen; unexpected-meta-Whitelist aktualisieren.  
   - Facing/Bearing-Asserts weiter grün (`rotation == 0`, street-facing).  
   - Globale `house_n`-Untergrenzen nicht absenken unter Status quo ohne Begründung.

7. **Suite einmal grün**; kein Art-Import / Alpha-Pipeline.

## Testplan

### Automatisiert

- [ ] Registry enthält genau die S01-Zellen `KIRCHE-KERN` + `WINT-WEST` (Bounds ≈ INDEX)
- [ ] ≥N Häuser mit `housing_quartier == "KIRCHE-KERN"` und Zell-Index im Rect; analog WINT-WEST
- [ ] WINT-WEST deckt Spawn-Flanke: Viewport Zoom 0.9 ∩ Häuser ≥3
- [ ] Keine Doppel-Props am Spawn-Band (shared sep / kein zweiter Stack aus Alt-Radius + Quartier)
- [ ] Off-Road, `HOUSE_SCALE` 0.38, `SCHOOL_SCALE`/`LANDMARK_SCALE` unverändert, Spawn `(3861.9, -101.0)`
- [ ] Street-facing / bearing-aligned Asserts grün; `rotation == 0`
- [ ] Interim `schneckenwiese` (falls behalten) weiterhin ≥4 **oder** Testplan explizit angepasst
- [ ] `./scripts/run_tests.sh` grün

### Playtest / Smoke

- [ ] Default-Spawn Zoom 0.9: Winterthurer-Wohnzeilen lesbar, Strasse als Korridor, keine Doppel-Häuser übereinander
- [ ] Fahrt Richtung Kirche: Kirchgasse / Kirchhügel / Kern-Winterthurer bewohnt im KIRCHE-KERN-Band
- [ ] Landmarken/Schulen unverändert; Spieler startet nicht in BuildingCollision
- [ ] Keine neuen AI-Platten (bestehende Assets)

## Art-Bedarf

- [x] Keine neuen Assets  
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  

Nur bestehende `house_street_*_{ew,ns}.png`. Phase 2: **kein** `comic-rettung-art`.

## Akzeptanzkriterien

- [ ] Housing-Placement läuft über benannte F1-Quartier-Zellen (Kirche-Ursprung, 100 wu); kein zweites Grid
- [ ] KIRCHE-KERN und WINT-WEST haben maps-plausible Wohnzeilen an den genannten Straßenbändern
- [ ] Spawn-/Kirche-Alt-Korridore sind in die Quartier-Logik überführt; keine Doppel-Stacks
- [ ] Nur diese zwei Quartiere neu in der Registry; S02–S06 unberührt; Landmarks nicht neu gesetzt
- [ ] Suite grün inkl. Spawn-Viewport, Off-Road, Facing/Bearing; Code Review ohne Critical/High; Playtest Pass
