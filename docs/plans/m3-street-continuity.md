# Plan: m3-street-continuity

**Status:** Erledigt
**Typ:** Bugfix  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/m3-street-map-only.md`](m3-street-map-only.md) · Google Maps Seuzach  
**Art:** bestehende Schulhaus-Art (keine neue)

---

## Ziel

Strassenkarte **vervollständigen** (Seuzach+Ohringen): durchgängige Bänder ohne Gras-Keile in den Ecken, keine unsinnigen Überlappungen, Schulhäuser Birch / Rietacker / Ohringen an Maps-Lage zur Orientierung.

---

## Repro & RCA

### Repro

1. World laden: Netz wirkt lückenhaft (kurze Stummel, fehlende Quartierachsen).
2. An Knicken: Gras in den Ecken (Rechteck-Segmente).
3. An Kreuzungen: Trottoirs schneiden die andere Fahrbahn; Bänder liegen übereinander.
4. Keine Schulhäuser → keine Ortsorientierung.

- [x] Repro bestätigt (RoadKit `add_straight` pro Kante; User)

### RCA

| Feld | Inhalt |
|------|--------|
| Ursache | Jede Polylinie = N unabhängige Rechtecke → Lücken an Mitern; Kreuzungen ohne Füllung; wenige Stummel-Locals |
| Nicht | Fehlende Art; Y-Sort |
| Fix | `add_polyline` mit Miter; Junction-Pads; mehr Maps-Achsen an gekoppelten Junctions; Schul-Cluster |

### RCA (Review: Schulen auf der Fahrbahn)

- Rietacker B lag auf `j_station`; Birch-Turnhalle auf Weidstrasse.
- Erster Nudge unzureichend: Füße-Abstand zu 6 Junctions war grün, Fassaden lagen weiter auf Hettlinger / Welsikoner / Münzer (`rietacker_a` d=65 vs need 116).
- Ursache: Test mass nur `spr.position` (Füße) plus +50-Puffer, kleiner als halbe Schulhaus-Breite (~90–154 px). Rietacker-Kern (~90,−190) ist zu dicht für die Sprite-AABB.
- **Fix:** Cluster in Gras-Taschen (Rietacker zwischen Hettlinger/Welsikoner N; Birch N von Stations; Ohringen O von Schulstrasse). Test: Füße ≥ half_w+14+50 **und** Fassaden-AABB ≥ half_w+14 gegen jede Named-Polylinie.

- [x] RCA dokumentiert

---

## Scope

### In

- RoadKit: `add_polyline` (Miter) + `add_junction`
- `_add_named_road` nutzt Polylinie; Junctions an T/Kreuz
- Weitere benannte Quartier-/Sammlerachsen (kein Footway)
- Schulhäuser Birch, Rietacker, Ohringen (Cluster, Maps-Quadrate)

### Nicht

- Wohnbebauung, Fusswege, Hub-Fassade, neue Art

---

## Testplan

- [x] L-Knick: Innenecke liegt im Road-Polygon (kein Gras-Keil)
- [x] `add_polyline` erzeugt 1 road-Poly (nicht N Segmente)
- [x] 3 Schul-Cluster ≥2 Props, Quadranten Maps
- [x] Named roads inkl. neuer Achsen; 4 Breiten
- [x] Suite grün

---

## Akzeptanzkriterien

- [x] Strassen durchgängig, Ecken asphaltiert
- [x] Kreuzungen ohne Trottoir-Streifen durch die Fahrbahn (Pad)
- [x] Schulhäuser orientierbar
- [x] Review + Playtest Pass

---

## Playtest (2026-08-11)

Pass. Art alpha 181 PNGs; `./scripts/run_tests.sh` green; High review PASS (school AABBs off carriageways). `world_sandbox` instantiate: player at `(490, 750)`, RobotSprite visible, move-right dx≈100. 16 junction pads (asphalt z=−38); 0 grass samples in miter elbows. Schools Birch `(720,-460)/(900,-360)/(800,-640)`, Rietacker `(140,-640)/(240,-800)/(80,-920)`, Ohringen `(−740,400)/(−560,520)/(−640,680)`; no `house_variant`. Smoke: `godot --path . --quit-after 5` exit 0.
