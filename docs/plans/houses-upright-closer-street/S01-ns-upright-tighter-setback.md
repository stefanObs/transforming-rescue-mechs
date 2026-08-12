# Plan: houses-upright-closer-street / Slice S01

**Status:** Entwurf  
**Typ:** Bugfix + Art  
**Datum:** 2026-08-12  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/houses-upright-closer-street/INDEX.md`  
**Slice-Datei:** `docs/plans/houses-upright-closer-street/S01-ns-upright-tighter-setback.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (zwei zusammengehörige spieler-sichtbare Inkremente: (1) NS-Haus-Art aufrecht autorisieren, (2) Housing-Setback straffen ohne Asphalt-Overlap). Plan nötig (Bug → Phase-0 RCA + Art + Multi-System Clearance). Tests, Review, Playtest und Git sind der normale Ablauf — keine Extra-Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Ziel

An N–S-Strassen (v. a. Winterthurer Spawn-Korridor) stehen Häuser wieder **aufrecht** (Dach oben, Schwerkraft unten; lange Straßenfassade + Tür an der **linken** vertikalen Canvas-Kante — keine liegenden ROTATE_270-Sprites). Gleichzeitig rücken Corridor-Häuser **sichtbar näher an die Asphaltkante**, ohne RoadKit-Asphalt zu übermalen. EW-Art und Bearing-/Flip-Wiring bleiben.

## Scope

### In

- Alle vier `house_street_*_ns.png` neu autorisieren (Style C): aufrecht; Straßenfassade = vertikale **linke** Kante; **niemals** EW um 90° drehen
- Learning in `.cursor/agents/comic-rettung-art.md`: explizites Verbot ROTATE_90/270 EW→NS
- Housing-Setback straffen: house-spezifische Clear-/Margin-/Slack-Konstanten + curb-orientiertes `need` (street-facing Achse statt `max(w,h)/2`); visuelle Clear vs. Named Roads bleibt grün
- Placement/Bearing-Pick/Flip aus `sprites-clear-street-aligned` S02 behalten (`rotation == 0`)
- Tests: Konstanten asserten; visual-clear; Bearing-Match; optional Pixel-/Orientierungs-Guard gegen „NS == ROTATE_270(EW)“

### Nicht

- Neue Housing-Korridore / Voll-Seuzach / Schul-Campus-Art
- RoadKit / `seuzach_roads.json` neu; Iso-Kamera; `HOUSE_SCALE` ändern
- EW-Haus-Art von Grund auf neu (nur retuschieren wenn NS-Refs es erzwingen — Default: `*_ew.png` belassen)
- Landmark-/Schul-Clearance abschwächen (dürfen near-full `BUILDING_CLEAR_*` behalten oder teilen nur wenn Asserts es erlauben)
- `Sprite2D.rotation` als Facing-Ersatz

## Systeme

| System | Rolle |
|--------|--------|
| `assets/art/house_street_{a,b,flachdach,reihen}_ns.png` | defekte / zu ersetzende NS-Art |
| `comic-rettung-art` + Alpha-Pipeline + Godot-Import | Phase-2 Art |
| `scripts/world_sandbox.gd` — `_place_housing_along_roads`, `_building_clear_size`, `_sprite_clears_named_roads`, nudge | Setback + Clear |
| `tests/m3_world_landmarks_test.gd` | Clear-Konstanten, off-road, bearing, rotation |
| `.cursor/agents/comic-rettung-art.md` | Art-Learning |

## Repro & RCA (Pflicht bei Typ = Bugfix)

### Reproduktion

- [x] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. Haupt-Scene / Sandbox starten, Spawn an Winterthurerstrasse. 2. N–S-Nahstrasse entlangschauen (Corridor-Häuser mit `street_bearing=ns` / Variante `*_ns`). 3. Optional: PNGs `house_street_*_ns.png` vs `*_ew.png` pixelvergleichen (`PIL Image.ROTATE_270`). |
| Erwartet | Häuser stehen aufrecht (Dach oben); lange Fassade vertikal parallel zum N–S-Band; Tür zur Strasse (links bzw. nach `flip_h` rechts). Curb-Abstand lesbar eng, Fassade nicht auf Asphalt. |
| Tatsächlich | Die meisten Spawn-Corridor-Häuser liegen auf der Seite (Dach vertikal, „Schwerkraft“ nach links). Ursache Art: NS-Dateien sind (fast) 90°-Drehungen der EW-Dateien. Zusätzlich wirkt der Abstand zur Asphaltkante zu groß (weite Graslücke). |
| Umgebung | Godot 4 · Branch aktuell · Scene `world_sandbox` · Keyboard · 2026-08-12 |
| Evidenz | Pixel-Audit: `house_street_a_ns` / `flachdach_ns` / `reihen_ns` = **exakt** `ROTATE_270` der jeweiligen `_ew` (0 differing px). `house_street_b_ns` Größen-Mismatch nach Rotate, aber weiterhin falsche Orientierung (kein upright-authored NS). Placement: Winterthurer = `class=main` N–S → Bearing `ns` → Mehrheit der Spawn-Häuser nutzt `_ns`. Setback-Code: `need = half_w + max(clear)/2 + EDGE_MARGIN(40) + slack(24)` bei Fracs 0.95/0.88. |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) NS-Art wurde als Rotate der EW-PNG geliefert statt neu autorisiert. (2) Engine rotiert EW-Sprites um 90° — **falsch** (`rotation == 0`, Bearing wählt Datei). (3) Setback zu konservativ durch `max(w,h)/2` + große Margin/Slack bei near-full Clear. |
| Bestätigte Ursache | **Art:** Drei von vier `*_ns.png` sind byte-identisch zu `EW.transpose(ROTATE_270)`; das vierte (`b`) ist nicht upright-authored. Vertrag „NS = linke vertikale Fassade, Dach oben“ wurde verletzt. **Placement:** Housing `need` nutzt isotropes `max(clear_w,clear_h)/2` plus `BUILDING_CLEAR_EDGE_MARGIN=40` und `slack=24` bei Clear-Fracs 0.95/0.88 → übertrieben großer Curb-Abstand; Assert/`_nudge_off_named_roads` erzwingen denselben Near-Full-Puffer. |
| Nicht die Ursache | RoadKit-Breiten; `HOUSE_SCALE`; Side-aware Flip-Logik an sich; fehlende `_ns`-Dateien (Dateien existieren, Inhalt falsch). |
| Fix-Richtung | (1) Vier NS-PNGs neu zeichnen (upright, Fassade links) — nie Rotate. Learning aktualisieren. (2) House-spezifische engere Clear-/Curb-Konstanten + street-axis `need`; Landmarken dürfen stärkere Clear behalten. Tests Konstanten + Clear + optional Anti-Rotate-Guard. |
| Risiken | Zu aggressive Fracs → Paint auf Asphalt (Assert/Playtest müssen fangen). Landmark-Asserts brechen, wenn globale `BUILDING_CLEAR_*` mitgesenkt werden — deshalb **house-scoped** Konstanten bevorzugen. Nach NS-Regen können Clear-AABBs schmaler/höher sein → Placement neu kalibrieren. |

- [x] RCA dokumentiert und reviewed (kurz vom Hauptagenten ok)

## Ansatz / Technische Schritte

### Phase 0 erledigt — Repro + RCA oben

### A — Art (`comic-rettung-art`)

1. Style **C**; Refs `c-umgebung` / `c-basis` + `c-iso-city-map` (Layout only). Proportionen aus bestehenden Style-C-`*_ew` / `house_*`.
2. **Art-Vertrag NS (verbindlich):**
   - Canvas: Gebäude **aufrecht** (Dach / First **oben**, Boden / Sockel **unten**).
   - Lange Straßenfassade ≈ **vertikal an der linken** Canvas-Kante; Tür/Stufen auf dieser linken Kante.
   - Milder Style-C-¾-Volume ok; **kein** Iso-Diamant; **kein** `ROTATE_90` / `ROTATE_270` / Engine-Rotation aus EW.
   - `flip_h` spiegelt Fassade für die Ostbank — Art default = West-Facing ohne Flip.
   - Nie Asphalt in die PNG; Fußkante freilassen.
3. Ersetzen (exakte Namen):
   - `assets/art/house_street_a_ns.png`
   - `assets/art/house_street_b_ns.png`
   - `assets/art/house_street_flachdach_ns.png`
   - `assets/art/house_street_reihen_ns.png`
4. `*_ew.png` belassen (bereits Bottom-Fassade / aufrecht).
5. Alpha: `process_art_alpha.py` → `verify_art_alpha.py` grün → `godot --headless --path . --import`.
6. Learning in `.cursor/agents/comic-rettung-art.md` unter Building/street alignment ergänzen: **Never** produce `_ns` by rotating `_ew` (or any 90° transform). Author upright NS with left-edge façade separately.

### B — Setback / Clearance (`feature-implementer`)

7. **Vorgeschlagene Konstanten** (house-scoped; Landmarken behalten near-full):

| Konstante | Ist (global / housing) | Soll (Housing) | Hinweis |
|-----------|------------------------|----------------|---------|
| Clear W-Frac | `BUILDING_CLEAR_W_FRAC = 0.95` | `HOUSE_CLEAR_W_FRAC = 0.70` | Cover street-facing paint; nicht full-canvas |
| Clear H-Frac | `BUILDING_CLEAR_H_FRAC = 0.88` | `HOUSE_CLEAR_H_FRAC = 0.55` | Höhe weniger dominant für Curb |
| Edge margin | `BUILDING_CLEAR_EDGE_MARGIN = 40` | `HOUSE_CLEAR_EDGE_MARGIN = 12` | Visuell eng am Bordstein |
| Curb slack | `slack = 24` (lokal in Placement) | `HOUSE_CURB_SLACK = 6` | Stabiler Mindestspalt |
| Landmark clear | dieselben 0.95 / 0.88 / 40 | **unverändert** `BUILDING_CLEAR_*` | Schulen/Landmarks behalten stärkeren Puffer |
| Nudge cap | `700` | unverändert | nur falls nötig nachziehen |

8. **Placement-Formel** in `_place_housing_along_roads` (statt isotropem `max`):

```gdscript
var clear_sz := _house_clear_size(tex, HOUSE_SCALE)  ## HOUSE_CLEAR_* fracs
## Street-facing half-extent: NS → clear.x (Fassade links); EW → clear.y (Fassade unten)
var street_half := (clear_sz.x if bearing == "ns" else clear_sz.y) * 0.5
var need := half_w + street_half + HOUSE_CLEAR_EDGE_MARGIN + HOUSE_CURB_SLACK
```

   Grobe Erwartung Winterthurer (`half_w≈72`, tex≈0.38×~900–1000px): Curb-Gap (`need − half_w`) von ~240 wu runter auf ~100–140 wu-Bereich — sichtbar enger, weiterhin off asphalt.

9. `_sprite_clears_named_roads` / nudge / AABB für **Housing** auf `HOUSE_CLEAR_*` umstellen (oder Scale-/Meta-Zweig: `HOUSE_SCALE` → house clear). Landmark-/Schul-Pfade weiter `BUILDING_CLEAR_*`.
10. `need_feet` / `need_aabb` in world_sandbox **und** Spiegel in `tests/m3_world_landmarks_test.gd` anpassen (heute hardcodiert 0.95/0.88/40).
11. Bearing-Pick, `flip_h`, Meta (`street_bearing`, `faces_street`), `rotation == 0` unverändert lassen.

### C — Tests

12. Assert neue `HOUSE_CLEAR_*` / Slack-Konstanten (nicht mehr 0.95/0.88/40 für Housing).
13. Visual-clear vs. named roads für Corridor-Häuser grün.
14. Bearing-Match + `rotation == 0` bleiben.
15. Optional Regression: für jedes Paar `*_ew`/`*_ns` — **nicht** pixelgleich zu `ROTATE_270(ew)` (bzw. Orientierungs-Heuristik Dach-oben).

## Testplan

### Automatisiert

- [ ] `HOUSE_CLEAR_W_FRAC ≈ 0.70`, `HOUSE_CLEAR_H_FRAC ≈ 0.55`, `HOUSE_CLEAR_EDGE_MARGIN ≈ 12`, `HOUSE_CURB_SLACK ≈ 6` (oder final gewählte Werte) in Script + Test
- [ ] `BUILDING_CLEAR_*` für Landmarken weiter 0.95 / 0.88 / 40 (oder dokumentiert geteilt)
- [ ] Corridor-Häuser: feet/AABB clear vs. Named Roads grün
- [ ] `street_bearing` Match; `rotation == 0`
- [ ] Optional: NS ≠ ROTATE_270(EW) Guard
- [ ] Suite einmal grün (Implementer-Handoff)

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Winterthurer N–S: Häuser aufrecht, Fassade // Band, Tür zur Kante
- [ ] E–W-Korridore (Kirchgasse/Reutlinger o. ä.): weiterhin lesbar aufrecht, Bottom-Fassade
- [ ] Curb-Lücke sichtbar enger als vor dem Fix; **kein** Asphalt-Overpaint
- [ ] Alpha: keine weißen/schwarzen AI-Platten an den vier NS-PNGs

## Art-Bedarf

- [x] Neue Grafiken → Subagent `comic-rettung-art`  
  Details: vier NS-PNGs ersetzen laut Art-Vertrag oben; EW belassen; Alpha + Import; Learning „never rotate EW→NS“.

## Akzeptanzkriterien

- [ ] Repro + RCA erledigt
- [ ] Vier `house_street_*_ns.png` upright (Dach oben); linke vertikale Straßenfassade + Tür; nachweislich **nicht** ROTATE_270 der EW
- [ ] `comic-rettung-art` Learning aktualisiert
- [ ] Housing näher am Curb (`HOUSE_CLEAR_*` + street-axis `need`); visuelle Clear grün; Landmark-Clear nicht regressiv abgeschwächt ohne Absicht
- [ ] `rotation == 0`; Bearing-/Flip-Verhalten erhalten
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass (N–S aufrecht + engerer Curb, kein Asphalt-Paint)

## Dateien (erwartet)

| Pfad | Änderung |
|------|----------|
| `assets/art/house_street_*_ns.png` (×4) | neu autorisieren |
| `.cursor/agents/comic-rettung-art.md` | Learning: never rotate EW→NS |
| `scripts/world_sandbox.gd` | `HOUSE_CLEAR_*`, street-axis `need`, house clear in assert/nudge |
| `tests/m3_world_landmarks_test.gd` | Konstanten + clear-Spiegel + optional Anti-Rotate |
| `docs/plans/houses-upright-closer-street/INDEX.md` | Status S01 |
