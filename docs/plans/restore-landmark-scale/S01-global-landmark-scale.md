# Plan: restore-landmark-scale / Slice S01

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-12  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Slice-Datei:** `docs/plans/restore-landmark-scale/S01-global-landmark-scale.md`  
**Hängt ab von:** —

Neue Aufgaben: INDEX + Feature-Stubs vom `task-slicer`. `feature-planner` füllt dieses Template **nur wenn nötig**. Tests/Review/Git bleiben der Ablauf, keine Extra-Slices. INDEX trägt `offen` → `in Arbeit` → `erledigt` — dieses File nicht durch Phasen jagen.

## Ziel

Ein gemeinsamer Scale-Pass für Schul-/Kiga-/Civic-Landmarks, sodass Schulen, Kindergärten, Bahnhof und Badi wieder **grob realistisch groß** gegenüber Strasse und Spieler wirken und am Ort **lesbar** sind (nicht „verschwunden“/Spielzeug-klein). Positionen bleiben OSM-Weltkoordinaten; keine Rotation, kein Housing.

## Scope

- In:
  - `SCHOOL_SCALE` und `LANDMARK_SCALE` in `scripts/world_sandbox.gd` auf Zielwerte setzen (Schulen + Kigas bzw. Bahnhof + Badi)
  - `FOREST_SCALE` einführen und Wald-Silhouetten darauf umstellen (Bäume nicht mit Civic mitwachsen)
  - `PROP_SCALE`: ungenutzt lassen (kein Call-Site); Kommentar aktualisieren, dass Gebäude `SCHOOL_SCALE`/`LANDMARK_SCALE` nutzen
  - Suite: Konstanten asserten; alle 15 Gebäude-Landmark-Props vorhanden mit erwartetem Scale; `house_n == 0`; visuelle Höhe in wu ~ `tex_h * scale.y`
  - Playtest: Teleport/Drive zu mind. einem Campus, einem Kiga, Bahnhof, Badi — Gebäude groß genug auf dem Screen
  - Bei Off-Road-/Collision-Fails: `footprint_h`-Faktor in `_attach_building_collision` prüfen/anpassen (nicht Positionen verschieben, wenn vermeidbar)
- Nicht:
  - Per-Landmark-Rotation / Relativgrößen innerhalb Campi oder Kiga-Paare (S02–S05)
  - `SPRITE_SCALE` (Spieler), `FIELD_METERS` / `FIELD_WU`, Kamera-Zoom 0.9, RoadKit-`half_w`
  - Neue Residential-Housing-Platzierung; Feuerwehr/Gemeindehaus/Kirchen/Läden/Tankstelle
  - Tracks/Wasser/Wälder neu layouten; neue Art-PNGs (nur wenn Scale allein unbrauchbar — dann `comic-rettung-art`)
  - Strassenbreiten anpassen (separates Risiko; nur dokumentieren/testen)

## Systeme

- `scripts/world_sandbox.gd` — Scale-Konstanten, `_add_prop`, `_attach_building_collision`, `_add_forest_silhouette` / `_place_forest_silhouettes`
- `scripts/seuzach_geo.gd` — unverändert (Positionen, `FIELD_METERS=5.3`); nur Referenz für Meter↔wu
- Tests: `tests/m3_world_landmarks_test.gd`, `tests/m3_building_occlusion_test.gd` (ggf. Kommentar MIN_CLUSTER_SEP / Scale-Hardcodes)
- Play: `scenes/world_sandbox.tscn`, Kamera Zoom 0.9, optional F1/HUD

## Kontext / Diagnose (Feature — warum „verschwunden“)

Landmarks sitzen weiterhin an OSM-GPS-Weltkoordinaten und sind im Scene-Tree. Zwei Effekte erzeugen den Eindruck „weg“:

1. **Viewport:** Kamera-Zoom wieder 0.9 → Spawn-Viewport ~711×400 wu; nächster Campus (Rietacker) ~5700 wu vom Winterthurer-Spawn → off-screen.
2. **Maßstab:** Nach `FIELD_METERS=5.3` sind Weltabstände reale Meter, aber `SCHOOL_SCALE`/`LANDMARK_SCALE` blieben 0.22/0.24 → visueller Footprint ~11–12 m für ~1000px-Sprite (~220 wu). Reale Schulflügel oft 20–40 m. Road-`half_w` lokal ~36 wu ≈ 1.9 m Hälfte — Gebäude wirken Spielzeug-klein und schwer zu spotten, wenn man sie erreicht.

**Fix-Richtung dieses Slices:** nur gemeinsame Gebäude-Scales anheben; Wälder auf altem Maß halten; Positionen/Zoom/Feldmaß unangetastet.

## Technische Schritte

1. **Konstanten locken** in `scripts/world_sandbox.gd` (nur ändern, wenn Mathematik klar dagegen spricht):

   | Konstante | Ist | Soll | Nutzung |
   |-----------|-----|------|---------|
   | `SCHOOL_SCALE` | `Vector2(0.22, 0.22)` | `Vector2(0.50, 0.50)` | Schulen + Turnhallen + alle Kigas |
   | `LANDMARK_SCALE` | `Vector2(0.24, 0.24)` | `Vector2(0.55, 0.55)` | Bahnhof, Badi |
   | `FOREST_SCALE` | *(fehlt; Wälder nutzten `LANDMARK_SCALE`)* | `Vector2(0.24, 0.24)` | `_add_forest_silhouette` |
   | `PROP_SCALE` | `Vector2(0.22, 0.22)` ungenutzt | **unverändert lassen** + kurzer Kommentar „unused; buildings use SCHOOL_/LANDMARK_SCALE“ | kein Call-Site |

   **Math-Anker:** Ziel-Schullänge ~25–30 m ≈ 470–570 wu bei `UNITS_PER_METER = 100/5.3 ≈ 18.87` → Scale ≈ **0.50** für ~1000px-Art. Civic leicht größer (0.55). **Entscheidung:** `FOREST_SCALE := 0.24` — S01 bläst keine Bäume auf; Wälder außerhalb Gebäude-Scope.

2. **Code:** `_add_forest_silhouette` von `LANDMARK_SCALE` auf `FOREST_SCALE` umstellen. `_place_*` für Schulen/Kigas/Bahnhof/Badi unverändert (nutzen bereits die Konstanten).

3. **Collision / Off-Road:** `_attach_building_collision` baut AABB aus `tex * scale` (`footprint_h := tex_h * 0.22` für Non-Hub). Größerer Scale → größeres BuildingCollision → Risiko für `_assert_schools_off_roads` / verwandte Fuß-Abstands-Asserts. Reihenfolge:
   - Suite laufen lassen (`m3_world_landmarks_test`, Occlusion).
   - Bei Fail: zuerst `footprint_h`-Faktor (~`0.12/0.22`) leicht anpassen, damit Fußabdruck nicht proportional zur vollen Sprite-Höhe wächst; Positionen nur nudgen wenn unvermeidbar (prefer not).
   - Road-`half_w` in S01 **nicht** ändern — Overlap-Risiko nur notieren.

4. **Nicht anfassen:** `SPRITE_SCALE`, `HUB_SCALE`, `FIELD_METERS`, Kamera-Zoom, Spawn, Geo-Positionen, Housing.

5. **Tests aktualisieren** (siehe Testplan): Konstanten-Asserts; visuelle Höhe; keine Hardcodes `0.22` für Gebäude-Scale.

## Testplan

### Automatisiert

- [ ] Assert `SCHOOL_SCALE == Vector2(0.50, 0.50)`, `LANDMARK_SCALE == Vector2(0.55, 0.55)`, `FOREST_SCALE == Vector2(0.24, 0.24)` (via geladenem `world_sandbox.gd` Script)
- [ ] Alle **15** Gebäude-Landmark-Props vorhanden und mit erwartetem Scale:
  - 9 Campus (Birch a/b + Turnhalle, Rietacker a/b + Turnhalle, Ohringen a/b + Turnhalle) → `SCHOOL_SCALE`
  - 4 Kigas (Bachtobel, Weid, Schneckenwiese, Ohringen) → `SCHOOL_SCALE`
  - Bahnhof + Badi → `LANDMARK_SCALE`
- [ ] `house_n == 0` unverändert
- [ ] Screen/world size sanity: Schul-Sprite `tex_h * scale.y` grob **400–600 wu** bei ~1000px-Höhe (Toleranz für abweichende PNG-Maße)
- [ ] Wald-Silhouetten weiter `FOREST_SCALE` 0.24; ohne `BuildingCollision`
- [ ] Bestehende Off-Road- / Collision-Asserts in `m3_world_landmarks_test` grün; Occlusion (`m3_building_occlusion_test`) grün — ggf. Kommentar „~200px tall“ an neues Scale anpassen, Schwellen nur wenn begründet
- [ ] Keine Hardcodes `0.22` als erwarteter Gebäude-Scale in Tests

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] **Nicht nur Winterthurer-Spawn:** Teleport/Drive zu mind. einem Campus (`birch_world` / `rietacker_world` o. ä.), einem Kiga, Bahnhof, Badi
- [ ] Gebäude am Ziel **klar sichtbar** und groß genug: Schulflügel bei Zoom 0.9 grob **≥150 px** Screen-Höhe
- [ ] Optional: HUD / F1 weiterhin nutzbar
- [ ] Kein neues Housing; Wälder nicht „Megabäume“

## Art-Bedarf

- [x] Keine neuen Assets (Scale-Konstanten reichen erwartet)
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  
  Details: nur nachziehen, wenn bei korrektem Scale Artefakte/Unbrauchbarkeit (z. B. extreme Pixelierung) — Style C, Alpha-Pipeline. **Nicht** Standardpfad für S01.

## Akzeptanzkriterien

- [ ] `SCHOOL_SCALE = (0.50, 0.50)`, `LANDMARK_SCALE = (0.55, 0.55)`, `FOREST_SCALE = (0.24, 0.24)` im Code
- [ ] Alle 15 Gebäude-Landmarks vorhanden, Positionen unverändert (OSM), Scales wie oben; `house_n == 0`
- [ ] Wälder nicht auf Civic-Scale mitgewachsen
- [ ] Automatisierte Tests grün (inkl. Off-Road/Collision oder dokumentierter `footprint_h`-Tweak)
- [ ] Playtest: Campus + Kiga + Bahnhof + Badi vor Ort lesbar und ≥~150 px Schulflügel-Höhe bei Zoom 0.9
- [ ] Keine Rotation / keine S02–S05-Ausrichtung; kein `FIELD_METERS`-/Zoom-/`half_w`-/Spieler-Scale-Change
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass

Playtest 2026-08-12: Pass (teleport Birch/Kiga/Bahnhof/Badi; Birch wing ~423 px @ zoom 0.9; scales 0.50/0.55/0.24; suite dedup).
