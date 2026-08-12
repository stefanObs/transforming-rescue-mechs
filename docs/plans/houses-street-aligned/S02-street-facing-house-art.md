# Plan: houses-street-aligned / Slice S02

**Status:** Erledigt  
**Typ:** Art + Feature  
**Datum:** 2026-08-12  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/houses-street-aligned/INDEX.md`  
**Slice-Datei:** `docs/plans/houses-street-aligned/S02-street-facing-house-art.md`  
**Hängt ab von:** S01 (erledigt, v0.32.0 — side-aware `flip_h` + Setback 24)

Nur der **Feature-Schritt** (zwei zusammengehörige spieler-sichtbare Inkremente: (1) Style-C street-ribbon Haus-Art mit langer Front am Canvas-Boden, (2) Placement-Zyklus auf den bestehenden Housing-Korridoren auf diese Varianten). Tests, Review, Playtest und Git sind der normale Ablauf — keine Extra-Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Ziel

S01 Flip+Setback reicht nicht: alte `house_*` haben die Tür am SW-Eck, nicht entlang des Straßenbands. Neue Style-C-Assets (**street-ribbon houses**) mit **langer Fassade + Eingang(en) am unteren Canvas-Rand** (Straßenkante / Kamera-unten). Side-aware `flip_h` verschiebt die Tür entlang dieser Straßenkante auf der Gegenbank — liest weiterhin als Asphalt-Facing. Placement auf Spawn-/Kirche-/Schneckenwiese-Korridoren nutzt primär diese vier Varianten.

## Scope

### In

- **4 neue PNGs** unter `assets/art/` (Minimal-Set, nicht alle 8 alten regenerieren):
  1. `house_street_a.png` — CH-Giebel-Dorfhaus, Traufe parallel zur Straße, Tür(en) an langer unterer Fassade
  2. `house_street_b.png` — andere Farbe/Variante, gleiche Regeln
  3. `house_street_flachdach.png` — modernes Flachdach, Straßenfront unten
  4. `house_street_reihen.png` — 2–3 Einheiten Reihenhaus, alle Türen an langer unterer Fassade
- Alpha-Pipeline + Godot-Import für die vier Files
- `_place_spawn_housing` Variantenliste: **primary = nur die 4 `house_street_*`** für alle drei Korridore (cleaner alignment); alte `house_*` nicht im Corridor-Zyklus
- S01-Logik beibehalten: side-aware `flip_h`, Setback-Slack **24**, Meta `street_side` / `faces_street` / `housing_corridor` / `house_variant`; **kein** `Sprite2D.rotation`

### Nicht

- S01 Placement/Facing neu erfinden; Setback/Spacing/Footprint-Formeln ändern
- Neue Housing-Korridore / Voll-Seuzach neu befüllen
- Alle acht alten Häuser regenerieren; Landmarken-Art oder `HOUSE_SCALE` / `SCHOOL_SCALE` / `LANDMARK_SCALE` / Spawn-Zoom
- Ein Slice pro einzelner PNG; Rotation als Facing-Ersatz
- Alte `house_a`…`house_reihen` löschen (bleiben auf Disk für andere Refs/Tests; nur Corridor-Zyklus wechselt)

## Systeme

| System | Rolle in diesem Slice |
|--------|------------------------|
| `comic-rettung-art` | Erzeugt die 4 Style-C street-ribbon PNGs |
| `scripts/process_art_alpha.py` / `verify_art_alpha.py` | Transparenz-Pipeline |
| `godot --headless --path . --import` | Import bevor `ResourceLoader.exists` |
| `scripts/world_sandbox.gd` → `_place_spawn_housing` | Variantenzyklus → `house_street_*` |
| `_place_housing_along_roads` | unverändert (Flip/Setback/Meta) |
| `tests/m3_world_landmarks_test.gd` | Exists + Placement-Majorität + faces_street/flip + Counts |
| `HOUSE_SCALE` `Vector2(0.38, 0.38)` | unverändert |

## Technische Schritte

1. **Art (Phase 2 — `comic-rettung-art`)**  
   - Style **C — Comic-Rettung** (`docs/STYLE-BIBLE-C.md`).  
   - Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` (**nur Layout**: Bebauung entlang Straßenbändern — **nicht** Iso-Spielzeugmaßstab/Kamera).  
   - Proportion-Refs: bestehende `house_a.png`, `house_flachdach.png`, `house_reihen.png` (~ähnliche Canvas-Höhe).  
   - **Autorregel street-ribbon:** lange Straßenfassade mit Eingang(en) läuft am **unteren** Bildrand; Traufe parallel zur Straße; Giebel/Seitenwände links/rechts. Authored Default ohne Flip: Tür(en) entlang der unteren Kante (primärer Eingang eher links/unten, damit bestehende Door-Dirs SW `(-1,1)` / SE `(1,1)` nach `flip_h` weiter gelten).  
   - Kein Lean/Turn-Overlay; Cel + Kontur; kein 3D-Plastik.  
   - Dateinamen exakt:
     - `assets/art/house_street_a.png`
     - `assets/art/house_street_b.png`
     - `assets/art/house_street_flachdach.png`
     - `assets/art/house_street_reihen.png`

2. **Alpha + Import**  
   - `python3 scripts/process_art_alpha.py`  
   - `python3 scripts/verify_art_alpha.py` (muss grün)  
   - `godot --headless --path . --import` (damit Tests `ResourceLoader.exists` sehen)

3. **Placement** in `scripts/world_sandbox.gd` → `_place_spawn_housing`  
   - Variantenliste ersetzen durch:
     ```gdscript
     var variants: Array[String] = [
       "house_street_a",
       "house_street_b",
       "house_street_flachdach",
       "house_street_reihen",
     ]
     ```
   - Gilt für alle drei Korridor-Aufrufe (`spawn`, `kirche`, `schneckenwiese`) — gleicher `variants`-Array.  
   - Flip/Setback/`_place_housing_along_roads` **nicht** anfassen außer falls Meta-`house_variant`-Strings in Assertions angepasst werden müssen.  
   - Node-Namen bleiben `house_%s_%s_%d` mit `variant.trim_prefix("house_")` → z. B. `street_a`.

4. **Tests** in `tests/m3_world_landmarks_test.gd` (und ggf. Alpha-Suite unverändert)  
   - `REQUIRED_ART` (oder gleichwertige Liste) um die 4 `house_street_*.png` erweitern; `ResourceLoader.exists` grün.  
   - Assertion: unter Props mit `house_variant` und `housing_corridor` nutzen **alle** (oder klar Mehrheit — Ziel: **alle**, da Zyklus nur street-Varianten) Varianten mit Prefix `house_street_`.  
   - `_assert_street_facing_housing` bleibt grün (`faces_street`, side-aware `flip_h`, rotation 0).  
   - House-Count-Schwellen (`house_n >= 20` spawn+corridor, corridor-spezifische ≥6, variety ≥2 distinct variants) bleiben erfüllt (4 street-Varianten → variety ok).  
   - Alte `house_a`… in `REQUIRED_ART` dürfen bleiben (Assets bleiben auf Disk).

5. **Suite einmal** grün; Handoff an Review → Playtest (beide Korridor-Achsen, beide Straßenbank-Seiten: Fassade/Tür zur Asphaltkante).

## Testplan

### Automatisiert

- [x] `ResourceLoader.exists` für  
  `house_street_a.png`, `house_street_b.png`, `house_street_flachdach.png`, `house_street_reihen.png`
- [x] Corridor-Häuser: alle (oder Majority) `house_variant` beginnt mit `house_street_`
- [x] `_assert_street_facing_housing`: `faces_street`, `street_side` ±1, `flip_h`-Regel, `rotation == 0`
- [x] House-Count-Thresholds weiterhin grün (≥20 total corridor housing; corridor slices ≥6 wo vorhanden; ≥2 distinct variants)
- [x] `HOUSE_SCALE` / Landmark-Scales unverändert
- [x] `python3 scripts/verify_art_alpha.py` grün

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Spawn-Winterthurer: beide Seiten, lange Front/Tür zur Straße (nicht nur SW-Eck-Tür trotz Flip)
- [ ] Kirche- und Schneckenwiese-Korridor: gleiches Lesen
- [ ] Keine AI-Platten / Transparenz-Fehler an den neuen PNGs
- [ ] Kein Iso-Break durch Rotation

## Art-Bedarf

- [x] Neue Grafiken → Subagent **`comic-rettung-art`** (Phase 2 Pflicht)  
  Details:
  - Style C; Refs `c-umgebung`, `c-basis`, `c-iso-city-map` (Layout only), Proportionen aus bestehenden Style-C-Häusern
  - Exact filenames: `house_street_a.png`, `house_street_b.png`, `house_street_flachdach.png`, `house_street_reihen.png`
  - Street-ribbon: long facade + entrance(s) along **bottom** of canvas
  - Nach Lieferung: `process_art_alpha` → `verify_art_alpha` → `godot --import`
  - Seuzach-Regeln nur innerhalb Slice-Grenzen (keine neuen Landmarken/Campus)

## Akzeptanzkriterien

- [x] Vier neue Style-C PNGs unter `assets/art/` mit exakten Namen oben; Alpha-Verify grün
- [x] Corridor-Zyklus in `_place_spawn_housing` = nur die 4 `house_street_*` Varianten
- [x] S01 side-aware `flip_h` + Setback 24 + `faces_street` unverändert wirksam; kein Rotation-Facing
- [x] Tests: exists ×4; placed houses street-variant; facing/flip grün; counts grün
- [ ] Playtest: auf beiden Achsen und beiden Seiten lesen Fronts zur Straße
- [ ] Code Review ohne offene Critical/High
- [ ] Nach Phase-4-Pass: Commit, Push, Tag (`git-release`)

Playtest 2026-08-12: Pass — street-ribbon houses doors to curb both banks; art-alpha 185.
