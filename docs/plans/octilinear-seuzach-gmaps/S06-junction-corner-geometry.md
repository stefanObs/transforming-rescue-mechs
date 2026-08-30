# Slice: S06 — Junction + corner geometry

**Status:** erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-30  
**Owner:** feature-planner → implementer  
**Parent-INDEX:** `docs/plans/octilinear-seuzach-gmaps/INDEX.md`  
**Slice-Datei:** `docs/plans/octilinear-seuzach-gmaps/S06-junction-corner-geometry.md`  
**Hängt ab von:** S05

Nur der **Feature-Schritt** (zwei verwandte Inkremente). INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Im octilinearen Seuzach+Ohringen-Netz (SVG + JSON aus dem Generator) wirken Straßen-Treffpunkte sauber (kein zerrissenes/verdrehtes Hub-Geknäuel) und Straßen-Knicke liegen nur wo die Swiss-Trace es rechtfertigt — keine sinnlosen Extra-Ecken.

## Out (nach Fix)

- Endpoint-first snap; hub pin ohne Winter-U-Turn; `clean_corners`; `prune_coincident_overlap` (kein Stations↔Winter Doppelkorridor)
- Triple-Hub `(5600,-2400)`; named reverse folds 0; REQUIRED gap 0; Ohringer EW
- Tests: `tests/octilinear_junction_corner_test.py`

## In diesem Schritt

1. **Mangled junctions:** Kreuzungen/T-Treffen und Stub-Anschlüsse so, dass Polylines an gemeinsamen Vertices sauber zusammenlaufen (Generator-Snap/Hub-Logik; Artefakte neu generieren).
2. **Nonsense corners:** überflüssige oder geometrisch unsinnige octilineare Knicke entlang bestehender Wege entfernen bzw. begradigen (sichtbar in SVG, konsistent in JSON).

## Nicht (andere Feature-Schritte)

- Zu dicht parallele Straßen (→ S07) — Abstand zwischen Parallel-Korridoren nicht anfassen
- `world_sandbox` / Spielwelt auf octilinear JSON umschalten
- `data/seuzach_roads.json` / live OSM als Geometrie-Quelle
- Swiss-Trace neu digitalisieren außer gezielter Generator-Korrektur an Treffpunkten/Knicken
- `STRAIGHT_CORRIDORS` / Ohringer-Begradigung aus S05 zurücknehmen (dürfen nur nicht wieder zerstört werden)

## Art

- nein — nur Generator + Trace-Geometrie + SVG/JSON (`comic-rettung-art` nicht nötig)

---

## Repro & RCA

### Reproduktion

- [x] Repro bestätigt (Analyse am aktuellen `data/seuzach_roads_octilinear.json`, Stand nach S05)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. `python3 scripts/gen_seuzach_octilinear_roads.py` (bereits gelaufen nach S05). 2. Winterthurerstrasse um Hub `(5600,-3000)` inspizieren. 3. Distinct-road-Count in ~800 wu um dichte Cluster messen. 4. Turn-Winkel / Segmentlängen zählen. |
| Erwartet | Winter geht durch den Triple-Hub ohne U-Turn; Treffen sind lokale, echte Kreuzungen/T; Knicke nur wo Trace es braucht; keine Spike-Micro-Segmente. |
| Tatsächlich | Winter: `… → (5400,-3200) → (5600,-3000) → (5200,-3400) …` mit **180° reverse turn** am Hub. Dense clusters: **10–16** distinct roads innerhalb ~800 wu (z. B. `(13200,-800)`, `(4600,-9000)`). **3** reverse folds (≥150°), **~76** Turns im 120–150°-Band, **~61** Segmente &lt;250 wu. |
| Umgebung | Generator `scripts/gen_seuzach_octilinear_roads.py`; Output `data/seuzach_roads_octilinear.json` + `docs/maps/seuzach_octilinear_roads.svg`; Zoom-Refs `docs/maps/seuzach_zoom_verify_*.jpg` |
| Evidenz | Parent-Analyse; lokale JSON-Messung (Winter idx 13, dense lists, fold/micro counts) |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (A) `pin_vertex` in `force_required_junctions` zieht einen **Interior**-Vertex der Winterthurerstrasse auf den Hub und repariert nur Nachbar-Legs → Spike/U-Turn. (B) `CONNECT_NEAR=3000` snappt **beliebige** nächste Vertex-Paare (auch Interior↔Interior) über große Distanz → falsche Merges + Spaghetti. (C) Erneuter CONNECT_NEAR-Pass am Ende von `connect_network` + `octilinear_leg`-Rebuild erzeugen Micro-Segmente und 135°-Zigs. (D) Kein Post-Pass entfernt Reverse-Folds / unnötige Knicke, während Shared-Junction-Vertices geschützt werden. |
| Bestätigte Ursache | Kombination **A+B+C**: S05 `force_required_junctions` / Triple-Hub-Pin erfüllt Gap-0 für REQUIRED_JUNCTIONS, hinterlässt aber Reverse-Fold an Winter; globales CONNECT_NEAR bleibt zu aggressiv und verdichtet Cluster. Fehlender Corner-Cleanup (D) lässt Micro/Zig Artefakte stehen. |
| Nicht die Ursache | Fehlende Ohringer-Begradigung (S05 ok); Sandbox/OSM-Daten; Parallel-Abstand (S07); Lattice 200 wu an sich. |
| Fix-Richtung | Snap-Policy verschärfen (Endpoint-first); Hub-Pin als T-/Through-Junction ohne U-Turn; Post-Pass `clean_corners` mit Junction-Schutz; Validierung + Regressionstests. |
| Risiken | Zu aggressives Entknicken kann echte Swiss-Knicke (z. B. Forrenberg/Kirchhügel) glätten; zu striktes CONNECT_NEAR kann Komponenten wieder trennen → Bridges (`CONNECT_MAIN`) bewusst behalten, aber gated. REQUIRED_JUNCTIONS Gap-0 und Ohringer-Straight aus S05 müssen grün bleiben. |

- [x] RCA dokumentiert (Parent-Analyse + Generator-Code bestätigt)

---

## Systeme

- `scripts/gen_seuzach_octilinear_roads.py` — Passes: `connect_network` (JUNCTION_SNAP cluster, CONNECT_NEAR, bridges, final re-snap/repair), `force_required_junctions` / `pin_vertex`, optional neuer `clean_corners`
- Artefakte: `data/seuzach_roads_octilinear.json`, `docs/maps/seuzach_octilinear_roads.svg`
- Validierung: `validate_required_junctions` (+ neue Checks)
- Tests: neue Unit-/Generator-Regressionstests (kein Godot nötig für Kern; Playtest = SVG/JSON-QA gegen Zoom-Refs)
- Refs: `docs/maps/seuzach_zoom_verify_core.jpg`, `…_ohringer.jpg`; Swiss-Raster nur visuell

---

## Technische Schritte

### A — Mangled junctions (Treffpunkte)

1. **Snap-Policy in `connect_network` (Pass 2 + final re-snap ~Z.376–608)**  
   - Interior↔Interior: nur noch innerhalb von ~`JUNCTION_SNAP`…`JUNCTION_SNAP*2` (nicht `CONNECT_NEAR=3000`).  
   - Endpoint↔Endpoint und Endpoint↔Any: längere Distanz erlaubt (bestehendes `CONNECT_NEAR` oder leicht reduziert, z. B. ≤1500–2000), damit echte Stub-Anschlüsse bleiben.  
   - Optional: wenn ein Snap einen Cluster mit &gt;N roads in Radius R erzeugen würde, Snap ablehnen (N/R als Konstante, konservativ wählen — Ziel: Artefakt-Spaghetti runter, echte Ortskerne nicht „auseinanderreißen“).  
   - `JUNCTION_SNAP`-Union: Interior geschützter Korridore weiter skippen (S05); keine Änderung an `STRAIGHT_CORRIDORS`.

2. **Hub-Pin ohne Reverse-Fold (`force_required_junctions` / `pin_vertex`)**  
   - Für Triple-Hub O/W/S und `snap_pair`: **Seitenstraße an Hauptstraße anbinden** (Ohringer/Stations-Endpunkt auf Winter-Vertex oder Segment-Projektion → Vertex **einfügen**), statt Winter-Interior weit vom Chord zum Hub zu ziehen.  
   - Wenn Winter den Hub **durchlaufen** soll: Hub-Vertex so setzen, dass vorher/nachher Bearing-Turn **&lt; ~135°** (kein ≥150° Spike). Falls Pin einen U-Turn erzeugt → Through-Path neu legen: `octilinear_leg(prev, hub) + octilinear_leg(hub, next)` nur wenn Turn ok; sonst Hub auf Chord/Segment von prev→next projizieren oder nächsten Winter-Vertex wählen, der Turn-Constraint erfüllt.  
   - Nach jedem Pin/`snap_pair`: lokaler Spike-Check am geänderten Vertex; bei Reverse-Fold sofort korrigieren (nicht erst im globalen Cleanup).

3. **REQUIRED_JUNCTIONS unverändert grün**  
   - Bestehende Paare + Gap-0-Validierung behalten. Keine neuen Pflicht-Paare in S06 nötig (außer sie sind für Fix zwingend und Swiss-klar — Default: keine Liste erweitern).

### B — Nonsense corners (Knicke)

4. **Neuer Post-Pass `clean_corners(roads)` nach `force_required_junctions` (vor Validate/Emit)**  
   Pro Polyline, Shared-Junction-Vertices (Punkt liegt auf ≥2 roads) **nicht droppen**:  
   - **Reverse folds:** Turn ≥150° → Mittelvertex entfernen oder `a→c` mit `octilinear_leg` ersetzen (wenn Shared: eher Nachbar-Micro-Vertices droppen / Legs neu, Hub behalten).  
   - **Colinear merge:** Turn ≈0° (H/V/45 durchgehend) → Zwischenvertex droppen.  
   - **Micro-Segmente:** Segmente &lt; ~250 wu (Konstante `MIN_CORNER_SEG_WU`, über `MIN_SEG_WU`) zusammenlegen, sofern kein Shared-Junction und Octilinearität erhalten bleibt.  
   - **Optional stair flatten:** einzelner 135°-Zig, wenn Shortcut `a→c` octilinear ist und Chord-Abweichung klein (Slack ~1–2 Lattice) — **keine** Parallel-Korridor-Merges (S07).

5. **Pipeline-Reihenfolge (verbindlich)**  
   Trace → octilinearize/RDP → `connect_network` (mit neuer Snap-Policy) → `force_required_junctions` (Pin-Fix) → **`clean_corners`** → `validate_*` → JSON/SVG.  
   Cleanup darf REQUIRED-Gaps nicht wieder öffnen; ggf. kurzer Re-`snap_pair` nur für Paare mit Gap≥1 nach Cleanup, dann erneut leichter Corner-Pass nur an betroffenen Roads.

6. **Artefakte regenerieren**  
   Generator laufen lassen; JSON+SVG commit-fähig. Zoom-Refs aus S05 wiederverwenden; bei Bedarf ein zusätzliches Crop der schlimmsten Cluster-Zone (nur Docs/maps, optional).

### C — Tests & Validierung

7. **Automatisierte Regressionen** (neue Testdatei unter `tests/`, pure Python gegen Generator-Helpers oder kleine Fixture-Polylines):  
   - Synthetic: Pin/Hub-Fall der Winter-U-Turn-Geometrie → nach Fix kein Turn≥150° am Hub-Vertex.  
   - Synthetic: zwei Roads mit Interior-Vertices 2000 wu auseinander → **kein** Interior-Snap; Endpoint 800 wu → Snap ok.  
   - Synthetic: 135°-Micro-Zig + Micro-Seg → Cleanup entfernt/flatten.  
   - Integration smoke: Generator-Lauf + `validate_required_junctions` + neue Metrik-Asserts (siehe Akzeptanz).

8. **Nicht anfassen**  
   - `CONNECT_MAIN`-Komponentenbrücken-Konzept (darf bleiben; nur Scoring/Häufigkeit nicht verschlimmern).  
   - Parallel-Spacing / Merge paralleler Straßen.  
   - Sandbox, CLIP/Kirche/FIELD, Trace-Koordinaten-Bulk-Edit.

---

## Testplan

### Automatisiert

- [ ] Unit: reverse-fold am Hub wird entfernt / nie erzeugt
- [ ] Unit: CONNECT_NEAR-Policy Endpoint vs Interior
- [ ] Unit: clean_corners Micro/colinear/zig (Shared-Vertex bleibt)
- [ ] Generator-Smoke: Exit 0; REQUIRED_JUNCTIONS Gap 0; Ohringer weiter nahezu EW (S05)
- [ ] Metrik-Regression (gegen Pre-S06 Baseline oder absolute Caps):  
  - reverse folds (Turn≥150°) auf named non-`link-*` roads = **0** (oder nur dokumentierte Ausnahmen)  
  - Segmente &lt;250 wu stark reduziert (Richtwert: ≪61; ideal nahe Lattice-Resten an echten Knicken)  
  - max distinct roads in 800 wu Ball deutlich unter 16 (Richtwert-Cap dokumentieren, z. B. ≤10–12 — kein hartes Swiss-Zählen bis zur Unlesbarkeit)

### Playtest / Smoke (Docs-Geometrie; kein Godot-Sandbox-Switch)

- [ ] SVG: Triple-Hub O/W/S bei ~`(5600,-3000)` — Winter **durchlaufend**, kein U-Turn-Spike
- [ ] SVG: Cluster Bahnhof/Stations / südliches Winter-Netz — Treffen lesbar, kein Spaghetti-Stern
- [ ] SVG/JSON: verdächtige Knickstellen vs `seuzach_zoom_verify_core.jpg` / `_ohringer.jpg` — Extra-Ecken weg, echte Richtungswechsel bleiben
- [ ] Keine illegalen Nicht-H/V/45°-Segmente (`validate_octilinear` bzw. bestehender Check)
- [ ] `link-*`-Stubs: keine 180°-Ping-Pong-Polylines (vgl. heutiges `link-3`)

---

## Art-Bedarf

- [x] Keine neuen Assets
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art` — n/a

---

## Akzeptanzkriterien

- [ ] Winterthurerstrasse am Triple-Hub: gemeinsamer Vertex mit Ohringer+Stations, **kein** Reverse-Fold (Turn&lt;150°) am Hub
- [ ] Alle `REQUIRED_JUNCTIONS` weiterhin Gap 0; Ohringer-Straight-Korridor aus S05 erhalten
- [ ] Snap-Policy: keine Interior↔Interior-Snaps über CONNECT_NEAR-Distanz; Endpoint-Anschlüsse funktionieren weiter
- [ ] `clean_corners` aktiv in der Pipeline; Shared-Junction-Vertices bleiben geteilt
- [ ] Regeneriertes `data/seuzach_roads_octilinear.json` + SVG; octilinear-valid
- [ ] Dense-Cluster-Spaghetti sichtbar entschärft (SVG-QA + Metrik-Cap)
- [ ] Nonsense-Micro/Zig-Corners reduziert; sinnvolle Swiss-Knicke bleiben
- [ ] Automatisierte Regressionen grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest/SVG-QA Pass
- [ ] **Nicht:** Parallel-Spacing (S07), kein Sandbox-Switch
