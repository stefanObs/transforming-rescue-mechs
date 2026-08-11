# Plan: restore-landmark-scale / Slice S02

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-12  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Slice-Datei:** `docs/plans/restore-landmark-scale/S02-campus-birch-rietacker.md`  
**Hängt ab von:** S01 (erledigt, `v0.30.0`: `SCHOOL_SCALE=0.50`, `LANDMARK_SCALE=0.55`, `FOREST_SCALE=0.24`)

Neue Aufgaben: INDEX + Feature-Stubs vom `task-slicer`. `feature-planner` füllt dieses Template **nur wenn nötig**. Tests/Review/Git bleiben der Ablauf, keine Extra-Slices. INDEX trägt `offen` → `in Arbeit` → `erledigt` — dieses File nicht durch Phasen jagen.

## Ziel

Die beiden Seuzach-Schul-Campi **Birch** und **Rietacker** wirken wieder mit grob korrekten **Gebäude-Größenverhältnissen** (visuelle Footprint-Länge ≈ OSM-längste Kante, ±30 %) und **Ausrichtung** gegenüber Strasse/Hof — validiert gegen Google Maps (Satellit) und Street View. Positionen bleiben OSM-Zentroide; globale `SCHOOL_SCALE` bleibt 0.50.

## Scope

- In:
  - Per-building scale multipliers **auf** `SCHOOL_SCALE` für die **sechs** Props `schulhaus_birch_{a,b}`, `turnhalle_birch`, `schulhaus_rietacker_{a,b}`, `turnhalle_rietacker`
  - Facing ohne willkürliche `Sprite2D.rotation` (Iso-¾ authored): bei Bedarf `flip_h` und/oder gezielte Art-Regen **nur** für das betroffene Gebäude
  - Optional: `_add_prop` um optionale kwargs (`flip_h`, ggf. expliziter Scale) erweitern — Signatur rückwärtskompatibel
  - Hof-Lücken sichtbar halten (kein Megablock); Occlusion `MIN_CLUSTER_SEP` grün
  - Suite: per-building Scales + Position ±80 wu + Guards (Ohringen/Kigas/Bahnhof unberührt, `house_n=0`, Off-Road, `rotation==0`)
  - Playtest: Screenshots an `birch_world()` / `rietacker_world()` vs. Maps/Street-View-Refs
- Nicht:
  - `SCHOOL_SCALE` / `LANDMARK_SCALE` / `FOREST_SCALE` / `SPRITE_SCALE` / `FIELD_METERS` / Kamera-Zoom erneut ändern (S01)
  - Ohringen-Campus, Kigas, Bahnhof, Badi (S03–S05)
  - GPS-Getter / OSM-Zentroide verschieben (außer dokumentierter Notfall für Collision — prefer Scale/footprint)
  - Neue Wohnhäuser; Feuerwehr/Kirche/Läden; RoadKit neu zeichnen
  - Gesamte Art-Bibliothek; Art-Regen nur wenn `flip_h`/Scale Facing vs. Street View nicht retten

## Systeme

- `scripts/world_sandbox.gd` — Named Mult-Konstanten (oder explizite `Vector2`-Scales in `_place_school_clusters` nur für die sechs Props); optional `_add_prop(..., flip_h:=false)`
- `scripts/seuzach_geo.gd` — **unverändert** (Positionen, Meter↔wu)
- Tests: `tests/m3_world_landmarks_test.gd` (`_assert_landmark_scales`, `_assert_birch_campus`, `_assert_rietacker_campus`), `tests/m3_building_occlusion_test.gd`
- Art (nur Gate): `assets/art/landmark_schulhaus_birch_{a,b}.png`, `landmark_turnhalle_birch.png`, `landmark_schulhaus_rietacker_{a,b}.png`, `landmark_turnhalle_rietacker.png`
- Play: `scenes/world_sandbox.tscn`

## Kontext / Diagnose

S01 hat alle Schul-Props einheitlich auf `SCHOOL_SCALE=0.50` gesetzt. Relative OSM-Footprints unterscheiden sich (~22–48 m längste Kante), die PNGs bei 0.50 aber nicht proportional:

| Prop | Tex (px) | Visuell @0.50 | ≈ m |
|------|----------|---------------|-----|
| birch_a | 947×939 | 474×470 wu | ~25.1 |
| birch_b | 885×584 | 442×292 wu | ~23.5 |
| turnhalle_birch | 1457×992 | 728×496 wu | ~38.6 |
| rietacker_a | 936×953 | 468×476 wu | ~25.3 |
| rietacker_b | 836×803 | 418×402 wu | ~22.2 |
| turnhalle_rietacker | 1384×939 | 692×470 wu | ~36.7 |

`UNITS_PER_METER = 100/5.3 ≈ 18.868`. Iso-¾ mischt Grundriss und Höhe im Sprite — „längste visuelle Kante“ ist Annäherung an OSM-Grundrisslänge, nicht exakte Ortho-Messung.

**Fix-Richtung:** `effective_scale = SCHOOL_SCALE * MULT` pro Gebäude; Facing über authored Achse + optional `flip_h`; kein globales Scale-Rework.

## Maps / Street View Refs (Facing)

Koordinaten: +X Ost, +Y Süd. Keine `Sprite2D.rotation` als Default.

### Birch — Bachwiesenstrasse 2 / Birchstrasse

Refs: Google Maps Satellit *Primarschule Birch*; Street View Bachwiesenstrasse Richtung Westen auf Trakt **2**; ggf. Birchstrasse von W/NW.

| Prop | OSM-Lage | Lange Achse (OSM) | Erwartetes Facing im Spiel |
|------|----------|-------------------|----------------------------|
| `schulhaus_birch_a` | Osten, Bachwiesenstr. **2** | leicht **N–S** | Hauptfassade Richtung **Bachwiesenstrasse / Bahnhof (Ost)**; Flachdach 1966 |
| `schulhaus_birch_b` | West/Süd, **2b** | **E–W** | Lange Seite E–W; Hof zum Anker; Flachdach |
| `turnhalle_birch` | Norden, **2c** | **N–S** | Halle nördlich des Hofs; lange Seite N–S lesbar |

Relativ (Kartenbild): Turnhalle N, a O, b W/S — Zentroide bereits korrekt; Slice ändert Scale/Facing, nicht Position.

### Rietacker — Ohringerstrasse 16 / Turnerstrasse 2 / Püntenstrasse

Refs: Satellit *Primarschule Rietacker*; Street View Ohringerstrasse auf Schulhaus **16**; Turnerstrasse auf Sporthalle **2**.

| Prop | OSM-Lage | Lange Achse (OSM) | Erwartetes Facing im Spiel |
|------|----------|-------------------|----------------------------|
| `schulhaus_rietacker_a` | SO, Ohringerstr. **16** | ~**33 m N–S**, Giebel 2-geschossig | Fassade zur **Ohringerstrasse** (Südseite Campus); 1933er Giebel |
| `schulhaus_rietacker_b` | NO, Püntenstrasse | 1-geschossig, komplex | Kleinerer Trakt NE; Giebel; nicht größer wirken als a |
| `turnhalle_rietacker` | Westen, Turnerstr. **2** | ~**48 m E–W** | Lange Hallenachse **E–W** (Iso-¾ authored — **nicht** per Rotation „drehbar“); West-Lage bleibt |

**Facing-Regel:** Wenn authored Sprite-Langachse zur OSM-Langachse/Street-View-Fassade spiegelt → zuerst `flip_h`. Nur wenn Silhouette/Achse fundamental falsch → `comic-rettung-art` **nur** diese Datei.

## Draft Mult-Tabelle (lock für Implement; Playtest ±15 %)

Ziel: `visuelle_längste_Kante_m ≈ OSM_längste (±30 %)`.  
`effective = 0.50 * MULT`. Implementer legt Named Constants an, z. B. `BIRCH_A_SCALE_MULT`, oder übergibt `SCHOOL_SCALE * Vector2(m, m)` nur an den sechs Call-Sites.

| Prop | OSM längste Kante (Quelle) | Ist @0.50 | Draft MULT | Effective scale | Soll-visuell |
|------|----------------------------|-----------|------------|-----------------|--------------|
| `schulhaus_birch_a` | ~30 m (geschätzt; Band 22–40, Haupttrakt) | ~25.1 m | **1.20** | 0.60 | ~30.1 m |
| `schulhaus_birch_b` | ~28 m (E–W-Flügel, geschätzt) | ~23.5 m | **1.20** | 0.60 | ~28.2 m |
| `turnhalle_birch` | ~40 m (N–S, oberes Band) | ~38.6 m | **1.00** | 0.50 | ~38.6 m |
| `schulhaus_rietacker_a` | **~33 m** N–S (alt-Plan dokumentiert) | ~25.3 m | **1.30** | 0.65 | ~32.9 m |
| `schulhaus_rietacker_b` | ~28 m (1-gesch.; bbox 42×55 ≠ eine Kante — bewusst unter a halten) | ~22.2 m | **1.25** | 0.625 | ~27.7 m |
| `turnhalle_rietacker` | **~48 m** E–W (alt-Plan dokumentiert) | ~36.7 m | **1.30** | 0.65 | ~47.7 m |

**Hof-Guard:** Zentroid-Abstände a↔b Birch ≈ 834 wu, Rietacker ≈ 942 wu; a↔Turnhalle Birch ≈ 924, Rietacker ≈ 1589. Nach Mults Half-Footprints addiert ≪ Abstand → Cluster bleibt lesbar. Falls Overlap im Playtest: Mults **senken** (nicht Positionen), bis Hof sichtbar und `MIN_CLUSTER_SEP` (160) grün.

**Toleranz-Asserts:** `scale.is_equal_approx(SCHOOL_SCALE * Vector2(MULT, MULT))` mit Float-Eps; oder assert `abs(scale.x / 0.50 - MULT) < 0.02`. Visuelle Meter-Prüfung optional/locker (±30 %).

## Technische Schritte

1. **Konstanten** in `world_sandbox.gd` (Namen frei, Werte = Draft-Tabelle):
   - `BIRCH_A_SCALE_MULT := 1.20`, `BIRCH_B_SCALE_MULT := 1.20`, `BIRCH_TURNHALLE_SCALE_MULT := 1.00`
   - `RIETACKER_A_SCALE_MULT := 1.30`, `RIETACKER_B_SCALE_MULT := 1.25`, `RIETACKER_TURNHALLE_SCALE_MULT := 1.30`
2. **`_place_school_clusters`:** nur die sechs Birch/Rietacker-`_add_prop`-Aufrufe auf `SCHOOL_SCALE * Vector2(mult, mult)` umstellen. Ohringen + alle Kigas weiter reines `SCHOOL_SCALE`.
3. **`_add_prop`:** optional Parameter `flip_h: bool = false` (Default). Wenn true: `spr.flip_h = true` nach Texture-Assign. Keine Breaking Change für bestehende Call-Sites. **Keine** `spr.rotation` setzen (bleibt 0), außer Plan später explizit eine Mini-Ausnahme dokumentiert — Default: verboten.
4. **Facing-Pass (Code zuerst):** Playtest/Maps-Check; bei Spiegelung `flip_h` an der betroffenen Call-Site. Art-Gate nur bei Fail (siehe Art-Bedarf).
5. **Tests anpassen:**
   - `_assert_landmark_scales`: Birch/Rietacker-Gebäude **nicht** mehr pauschal `== SCHOOL_SCALE`; statt dessen Expected = `SCHOOL_SCALE * mult` (Konstanten aus Script lesen oder Expected-Tabelle im Test). Ohringen (3) + Kigas (4) weiter `SCHOOL_SCALE`. Sample `birch_a` visual height: Band anpassen (bei MULT 1.20: ~470×1.2 ≈ 564 wu → weiter ~400–700 oder explizit `tex_h * effective`).
   - Campus-Asserts: Position ±80 wu, Relativlage, `rotation == 0`, `house_n == 0` behalten; neu: Scale-Asserts pro der sechs Nodes.
   - Off-Road / Occlusion: Suite grün; bei Collision-Fail zuerst Mults/Hof prüfen, `footprint_h` nur wenn S01-Pfad nötig — **keine** RoadKit-Änderung.
6. Suite `./scripts/run_tests.sh`. Playtest beide Campi.

## Testplan

### Automatisiert

- [ ] Sechs Named Mults (oder äquivalente effektive Scales) matchen Draft-Tabelle (±0.02 auf Mult)
- [ ] `schulhaus_birch_{a,b}`, `turnhalle_birch`, `schulhaus_rietacker_{a,b}`, `turnhalle_rietacker`: Position ≤ **80 wu** zum jeweiligen `SeuzachGeo.*_world()` Getter
- [ ] Relativlage unverändert maps-getreu (Birch: Turnhalle N, a O von b; Rietacker: Turnhalle W, b N von a)
- [ ] `rotation == 0` auf allen sechs (kein silent rotation)
- [ ] Ohringen a/b/Turnhalle + 4 Kigas weiter exakt `SCHOOL_SCALE`; Bahnhof/Badi `LANDMARK_SCALE`; `FOREST_SCALE` unberührt
- [ ] `house_n == 0`
- [ ] `_assert_schools_off_roads` grün
- [ ] `m3_building_occlusion_test`: Cluster birch/rietacker `MIN_CLUSTER_SEP` ≥ 160
- [ ] Bestehende Campus-GPS-Konstanten / Yard-Offsets unverändert

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Teleport `birch_world()`: Screenshot; Satellit mental: Turnhalle N, a Richtung Bachwiesenstrasse O, b W/S; Hof sichtbar; Größen a/b/Halle relativ stimmig; Street View Fassaden-Cue Bachwiesenstr. 2
- [ ] Teleport `rietacker_world()`: Screenshot; Turnhalle W (Turnerstr.), a SO (Ohringerstr. 16), b NE; Hof; a größer/höher als b; Halle länglich
- [ ] Kein Megablock; Spieler zwischen Trakten; Füße nicht auf Asphalt
- [ ] Ohringen/Kigas/Bahnhof optisch unverändert (Smoke kurz oder Suite-Guard)
- [ ] Keine weissen/schwarzen AI-Platten (nur wenn Art angefasst → Alpha-Pipeline)

## Art-Bedarf

- [x] Keine neuen Assets *(Default / Prefer — PNGs wiederverwenden)*
- [ ] Neue Grafiken → Subagent **`comic-rettung-art`** (Stil C) **nur bei Facing-Fail**

**Gate:** Code-`flip_h` + Mults reichen nicht, weil authored Langachse/Fassade Street View widerspricht (nicht nur gespiegelt).

Dann nur die beanstandete Datei, gleiche Pfade:

- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` + Maps/Street View der betroffenen Adresse (Birch: Bachwiesenstrasse; Rietacker: Ohringer-/Turnerstrasse)
- Iso-¾ Default-Facing; **kein** Dir-Set; Proportionen an Mult-Ziel anlehnen
- Pipeline: `process_art_alpha.py` → `verify_art_alpha.py`; ggf. `godot --headless --path . --import`
- Keine Ohringen-/Kiga-/Housing-Art

## Akzeptanzkriterien

- [ ] Sechs Birch/Rietacker-Props mit per-building Scales ≈ Draft-Mults (±15 % nach Playtest ok, dokumentiert im Handoff)
- [ ] Visuelle Footprint-Längen grob OSM (±30 %); Hof sichtbar; kein Megablock
- [ ] Facing maps/Street-View-stimmig **ohne** willkürliche `Sprite2D.rotation` (`flip_h` und/oder gezielte Art ok)
- [ ] Positionen weiter OSM (±80 wu); `SCHOOL_SCALE` global 0.50; S03–S05-Landmarks unberührt; `house_n == 0`
- [ ] Automatisierte Tests grün (Scales, Off-Road, Occlusion, rotation 0)
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass (Screenshots beider Campi vs. Maps)

Playtest 2026-08-12: Pass (Birch/Rietacker teleports + wide shots; Mults 1.20/1.20/1.00 and 1.30/1.25/1.30; Maps asphalt at campus edge).
