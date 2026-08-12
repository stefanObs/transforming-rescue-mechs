# Plan: sprites-clear-street-aligned / Slice S02

**Status:** Entwurf  
**Typ:** Art + Feature  
**Datum:** 2026-08-12  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/sprites-clear-street-aligned/INDEX.md`  
**Slice-Datei:** `docs/plans/sprites-clear-street-aligned/S02-bearing-aligned-building-art.md`  
**Hängt ab von:** S01 (erledigt, v0.34.0 — near-full visual clearance, body-centered AABB, post-nudge facing, Agent-Regeln: asphalt clear + street-aligned bearing art, kein `Sprite2D.rotation`)

Nur der **Feature-Schritt** (zwei zusammengehörige Inkremente: (1) Style-C street-aligned Haus-Varianten E–W **und** N–S, (2) Placement wählt Variante per Road-Tangent). Plan nötig (Art + Multi-System). Tests, Review, Playtest und Git sind der normale Ablauf — keine Extra-Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen. (INDEX bereits `in Arbeit`.)

## Ziel

Aktuelle `house_street_{a,b,flachdach,reihen}.png` haben lange Fassade + Türen am **Canvas-Boden** — liest korrekt entlang **E–W**-Straßenbändern, wirkt aber schräg/iso-verdreht an **N–S**-Bändern. Gebäude sollen mit der langen Fassade **parallel zur lokalen Strasse** stehen: Style-C **EW- + NS-Varianten**; Placement wählt anhand Road-Tangent `|tx|` vs `|ty|`. Side-aware `flip_h` bleibt; **kein** dekoratives Random-Facing und **kein** `Sprite2D.rotation` an Gebäuden. S01 Clearance/Nudge/Agent-Regeln bleiben.

## Scope

### In

- Style-C Art (`comic-rettung-art`): street-aligned Haus-Varianten für **E–W** und **N–S** (lange Fassade // Strasse; Eingänge an der Straßenkante; kein Iso-Skew relativ zur lokalen Tangente)
- Refs: `c-umgebung` / `c-basis` + `c-iso-city-map` (**nur** Haus–Strasse-Layout, keine Maße/Kamera); Alpha-Pipeline + Godot-Import
- Placement in `_place_housing_along_roads`: Variante anhand Segment-Tangent wählen (`|tx| >= |ty|` → EW, sonst NS); bestehende Corridor-Metas / Clearance aus S01 behalten
- Side-aware `flip_h` + `street_side` / `faces_street` beibehalten (Door-Dirs pro Bearing anpassen)
- Schul-/Campus-Varianten **nur wenn nötig** (Playtest/Audit: Campus wirkt sonst weiterhin schräg zur lokalen Tangente) — Default: **Häuser zuerst**, Schulen optionaler Nachzug im selben Slice nur bei nachgewiesenem Need
- Tests: Varianten existieren; Placement-Mehrheit Bearing-Match; S01 visual clear grün; `rotation == 0` an Gebäuden

### Nicht

- Clearance-Fracs / Agent-Docs (→ S01, schon shipped)
- Jede Landmark neu; RoadKit / `seuzach_roads.json` neu; Top-Down-Kamera
- Alle alten `house_*` / unprefixed `house_street_*` von Disk löschen (Migration: umbenennen/ersetzen laut Art-Namen unten; Legacy-Refs dürfen auf Disk bleiben, Corridor nutzt nur Bearing-Paare)
- Neue Housing-Korridore / Voll-Seuzach neu befüllen; `HOUSE_SCALE` / `SCHOOL_SCALE` / Spawn-Zoom ändern
- `Sprite2D.rotation` als Facing-Ersatz; Random-Facing

## Systeme

| System | Rolle in diesem Slice |
|--------|------------------------|
| `comic-rettung-art` | Erzeugt Style-C EW- + NS-Haus-PNGs (Schulen nur bei Need) |
| `scripts/process_art_alpha.py` / `verify_art_alpha.py` | Transparenz-Pipeline |
| `godot --headless --path . --import` | Import bevor `ResourceLoader.exists` |
| `scripts/world_sandbox.gd` → `_place_spawn_housing` / `_place_housing_along_roads` | Bearing-Pick aus Sample-/Post-Nudge-Tangent; Flip; Meta |
| S01 Clearance (`BUILDING_CLEAR_*`, body-centered AABB, nudge, null-on-fail) | unverändert lassen |
| `tests/m3_world_landmarks_test.gd` | Exists ×8; Bearing-Match; facing/flip; clear; counts |
| `HOUSE_SCALE` `Vector2(0.38, 0.38)` | unverändert |

## Repro & RCA

n/a (Feature/Art — kein Bugfix). Sichtbares Problem: gleiche Bottom-Facade-Art an N–S-Tangenten wirkt schräg zur Strasse.

## Ansatz / Technische Schritte

### Art-Autorregeln (Phase 2 — `comic-rettung-art`)

1. Style **C — Comic-Rettung**; Cel + Kontur; kein 3D-Plastik; kein Lean/Turn-Overlay.
2. Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` (Layout only). Proportionen aus bestehenden Style-C-Häusern (`house_street_*` / `house_a` etc.).
3. **EW (long axis horizontal):** lange Straßenfassade + Eingang(en) am **unteren** Canvas-Rand (wie heutige `house_street_*`). Authored Default ohne Flip: primärer Eingang eher links/unten → Door-Dirs SW `(-1,1)` / SE `(1,1)` bleiben gültig.
4. **NS (long axis vertical):** lange Straßenfassade + Eingang(en) entlang einer **vertikalen** Canvas-Kante (Default: **linke** Kante = West-Facing ohne Flip). Nach `flip_h` spiegelt die Fassade auf die rechte Kante. Door-Dirs für Flip-Logik: W `(-1,0)` / E `(1,0)` (leichtes Y-Bias ok, wenn es dem Style-C ¾-Look hilft, aber lange Achse bleibt vertikal).
5. Nie Asphalt in die PNG malen; Fuß/Bordstein-Kante freilassen (S01 Clearance räumt Placement, Art darf nicht „auf die Strasse“ gezeichnet sein).
6. **Dateinamen (exakt, 4 Stile × 2 Bearings = 8 PNGs):**

| Stil | E–W | N–S |
|------|-----|-----|
| Giebel A | `house_street_a_ew.png` | `house_street_a_ns.png` |
| Giebel B | `house_street_b_ew.png` | `house_street_b_ns.png` |
| Flachdach | `house_street_flachdach_ew.png` | `house_street_flachdach_ns.png` |
| Reihen | `house_street_reihen_ew.png` | `house_street_reihen_ns.png` |

7. Migration der heutigen vier Bottom-Facade-Files: Inhalt entspricht EW → als `*_ew.png` übernehmen (Rename/Copy + ggf. leichte Retusche ok) **oder** frisch als `_ew` neu autorisieren; vier `*_ns` neu erzeugen. Unprefixed `house_street_*.png` dürfen als Legacy auf Disk bleiben, dürfen aber **nicht** mehr im Corridor-Zyklus stehen.
8. Schulen: **Default skip.** Nur wenn nach Housing-Wiring Playtest/Audit zeigt, dass Campus-Sprites an N–S (oder EW) weiterhin schräg zur lokalen Tangente lesen — dann minimal: nur die betroffenen Campus-Gebäude mit `_ew`/`_ns` (Cluster dieses Slices, nicht ganz Seuzach). Sonst keine Schul-Art in diesem Slice.

### Alpha + Import

9. `python3 scripts/process_art_alpha.py`  
10. `python3 scripts/verify_art_alpha.py` (grün)  
11. `godot --headless --path . --import`

### Placement (Phase 2 — `feature-implementer`)

12. In `_place_housing_along_roads` (nach Sample, **und erneut nach Nudge** mit Tangent des nächsten Segments auf demselben Corridor-Road):

```gdscript
## Binary bearing from road tangent (+X east, +Y south).
var t: Vector2 = tangent.normalized() ## nach Nudge: Segment-Tangent am closest point
var bearing := "ew" if absf(t.x) >= absf(t.y) else "ns"
var base := variants[variant_i % variants.size()] ## z.B. "house_street_a" (ohne Bearing-Suffix)
var variant := "%s_%s" % [base, bearing]       ## "house_street_a_ew" | "…_ns"
var file_name := "%s.png" % variant
```

13. `variants`-Liste in `_place_spawn_housing` = Basis-IDs ohne Suffix:

```gdscript
var variants: Array[String] = [
  "house_street_a",
  "house_street_b",
  "house_street_flachdach",
  "house_street_reihen",
]
```

14. **Flip:** EW wie S01 (Door SW/SE vs `toward_road`). NS: Door-Dirs W/E analog wählen (`door_no_flip` / `door_flip`), damit die vertikale Fassade zur Asphaltkante zeigt. Meta `street_side` / `faces_street` / `housing_corridor` / `house_variant` (voller String inkl. `_ew`/`_ns`) beibehalten.
15. **Kein** `Sprite2D.rotation`; Clearance/Nudge/null-on-fail / Spacing / Scales **nicht** anfassen außer Dateiname + Bearing-Pick + NS-Door-Dirs.
16. Optional Meta `street_bearing`: `"ew"` | `"ns"` — hilfreich für Tests; nicht Pflicht wenn aus `house_variant` Suffix ableitbar.

### Tests

17. `tests/m3_world_landmarks_test.gd`:
    - `REQUIRED_ART` um alle 8 `house_street_*_{ew,ns}.png` erweitern
    - Corridor-Häuser: `house_variant` matcht `house_street_*_(ew|ns)`; **kein** unprefixed `house_street_a` mehr im Zyklus
    - **Bearing-Match:** für Mehrheit (≥80%) der corridor houses: Suffix `_ew` wenn `|tx|>=|ty|` am nearest corridor segment, sonst `_ns` (Tangent aus Road-Meta / World-Helper)
    - `_assert_street_facing_housing`: `faces_street`, side-aware `flip_h`, `rotation == 0` bleibt
    - S01 visual-clear Assertions bleiben grün; House-Count-Schwellen (≥3 spawn view, corridor counts) bleiben
18. Suite einmal grün → Review → Playtest (Winterthurer ≈ E–W + eine klare N–S-Nahstrasse, z. B. Kirchgasse-/Reutlinger-Abschnitt).

## Dateien

| Pfad | Änderung |
|------|----------|
| `assets/art/house_street_*_ew.png` (×4) | neu oder aus heutigen `house_street_*.png` migriert |
| `assets/art/house_street_*_ns.png` (×4) | neu (comic-rettung-art) |
| `scripts/world_sandbox.gd` | Bearing-Pick + Variant-Dateiname; NS Flip-Dirs; Meta |
| `tests/m3_world_landmarks_test.gd` | REQUIRED_ART, Prefix/Suffix-Asserts, Bearing-Match-Majorität |
| optional: unprefixed `house_street_*.png` | Legacy belassen oder nach Migration ungenutzt |

## Risiken

| Risiko | Mitigation |
|--------|------------|
| NS-Art mit „Fuß unten“ bricht Ground-Align / Clear-AABB | Lange Achse vertikal, aber Gebäudefuß weiter canvas-unten; Clearance bleibt body-centered wie S01 |
| Flip-Logik EW auf NS angewandt → Türen von der Strasse weg | Eigene Door-Dirs W/E für `_ns`; Tests + Playtest beide Straßenbanken |
| Diagonale Segmente flippen ständig EW↔NS | Binär `|tx|>=|ty|`; nach Nudge Tangent am **closest** Segment; keine Diagonal-Art in diesem Slice |
| Count-Drops wenn `_ns` fehlt / Import vergessen | Art+Import vor Suite; missing file → skip wie heute, aber Test fordert Exists ×8 |
| Schulen ohne Bearing wirken inkonsistent | Default skip; nur bei nachgewiesenem Skew nachziehen — Scope nicht auf alle Landmarken aufblasen |
| Rename bricht alte Assertions auf `house_street_` ohne Suffix | Tests auf `_ew`/`_ns` umstellen; unprefixed nicht mehr im Zyklus |

## Testplan

### Automatisiert

- [ ] `ResourceLoader.exists` für alle 8 `house_street_{a,b,flachdach,reihen}_{ew,ns}.png`
- [ ] `verify_art_alpha.py` grün
- [ ] Corridor-Häuser: `house_variant` endet auf `_ew` oder `_ns`; Basis aus den vier Stilen
- [ ] ≥80% Bearing-Match: Suffix stimmt mit `|tx|` vs `|ty|` der lokalen Corridor-Tangent
- [ ] `_assert_street_facing_housing`: `faces_street`, `street_side` ±1, side-aware `flip_h`, `rotation == 0`
- [ ] S01 visual clear (Häuser + Landmarken vs named roads) weiterhin grün
- [ ] House-Count-Thresholds (spawn ≥3 in view, kirche/schn ≥4, total tagged ≥15, ≥2 distinct variants) grün
- [ ] `./scripts/run_tests.sh` einmal grün

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Winterthurer (nahe E–W): lange Fassade // Band, Türen zur Asphaltkante, beide Banken
- [ ] Eine N–S-Nahstrasse (z. B. Kirchgasse / Reutlinger-Abschnitt): Fassade parallel zum Band, **nicht** diagonal/bottom-only-Skew
- [ ] Keine AI-Platten / Transparenz-Fehler; kein Asphalt-Übermalen (S01)
- [ ] Schulen: nur prüfen ob Skew bleibt — wenn ja, optional NS/EW Campus-Art nachziehen; sonst Pass ohne Schul-Art
- [ ] Kein Iso-Break durch Rotation

## Art-Bedarf

- [ ] Neue Grafiken → Subagent **`comic-rettung-art`** (Phase 2 Pflicht für Häuser)  
  Details:
  - Style C; Refs `c-umgebung`, `c-basis`, `c-iso-city-map` (Layout only)
  - Exact filenames: `house_street_{a,b,flachdach,reihen}_{ew,ns}.png` (8 Files)
  - EW: long facade + doors along **bottom**; NS: long facade + doors along **left** (flip → right)
  - Nach Lieferung: `process_art_alpha` → `verify_art_alpha` → `godot --import`
  - Schulen: nur bei Need; Seuzach-Regeln nur innerhalb Slice-Grenzen

## Akzeptanzkriterien

- [ ] Acht Style-C PNGs unter `assets/art/` mit exakten Namen oben; Alpha-Verify grün; Import erledigt
- [ ] Placement wählt `_ew` wenn `|tx| >= |ty|`, sonst `_ns` (Sample + post-nudge Segment-Tangent); Corridor nutzt nur Bearing-Paare
- [ ] Side-aware `flip_h` + `faces_street` / `street_side` wirksam (EW: SW/SE; NS: W/E); **kein** `Sprite2D.rotation`
- [ ] S01 Clearance/Nudge/null-on-fail unverändert wirksam
- [ ] Tests: exists ×8; Bearing-Match-Majorität; facing/flip/rotation 0; clear + counts grün
- [ ] Playtest: E–W- und N–S-Bänder lesen Fassaden parallel zur Strasse
- [ ] Schulen: entweder unverändert OK oder minimal bearing-aligned nachgezogen — kein Asphalt-Übermalen
- [ ] Code Review ohne offene Critical/High
- [ ] Nach Phase-4-Pass: Commit, Push, Tag (`git-release`)
