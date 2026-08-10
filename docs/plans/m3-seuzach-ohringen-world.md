# Plan: m3-seuzach-ohringen-world

**Status:** Erledigt  

**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/mvp.md`](mvp.md) Epic M3 · [`docs/KONZEPT.md`](../KONZEPT.md) §4/§15 · [`docs/ENTWICKLUNGSABLAUF.md`](../ENTWICKLUNGSABLAUF.md)  
**Art:** Stil C — [`docs/STYLE-BIBLE-C.md`](../STYLE-BIBLE-C.md) · Subagent **`comic-rettung-art`**

---

## Ziel

Erste spielbare **M3-Slice**: begeh-/befahrbare stilisierte Welt, die die Gemeinde **Seuzach inklusive Ohringen** (Unter-/Oberohringen) abdeckt — mit wiedererkennbaren Landmarken (Bahnhof, Feuerwehr, Badi Weiher, Schul-Cluster Birch/Rietacker/Ohringen), genug **verschiedenen** Häusern und Straßenachsen dazwischen. Bestehende Sandbox-Locomotion (screen-space, RoadKit) und Y-Sort bleiben; Hub-Prop Erdstation bleibt sichtbar. Volle Hub↔World-Transition kann auf einen späteren M3-Schritt verschoben werden.

---

## Scope

### In

- District-Layout (stilisiert, nicht OSM-1:1):
  - **Seuzach Dorfkern** (Kirche / Kirchgasse-Nähe) + `hub_station` + **Gemeindehaus**
  - **Bahnhof** Seuzach (Stationsstrasse, moderne S-Bahn)
  - **Feuerwehr** Seuzach (Strehlgasse 1–5, Feuerwehr-/Werkgebäude)
  - **Schwimmbad Weiher** (Landstrasse 26, Outdoor-Badi)
  - **Schulen** als Cluster einzelner Gebäude: Primarschule **Birch**, **Rietacker**, **Ohringen**
  - **Kindergärten** (Primarschule Seuzach): **Bachtobel**, **Weid**, **Schneckenwiese**, **Ohringen**
  - **Ohringen**-Quartier (Wohnen/Farmen, eigene Kirche, klar als District)
  - **POIs Alltag:** Restaurants, **Tankstelle**, **Läden** (mind. 2 Varianten)
- RoadKit-Straßen, die die Districts verbinden (screen-axis H/V + ggf. Diagonale/Kreisel wo sinnvoll)
- Landmark- und Haus-Art (Style C) unter `assets/art/`
- Bestehende Player-Bewegung / Transform / Kamera-Follow in der World-Scene beibehalten
- Y-Sort über bestehendes `z = BASE + y` für Props/Actors
- Optional Labels (District/Landmark-Namen) — nice-to-have
- Automatisierte Tests für Scene-Load, Landmarken, Haus-Vielfalt, Ohringen-District, Kigas/POIs
- Plan-File (dieses Dokument)

### Nicht

- Vollständige OSM-/Karten-1:1-Vermessung
- Missionen / Dispatcher (M5)
- Energie, harte Gebäude-Kollision als Pflicht (M4) — Collision optional wenn Zeit
- Vollständiger TileMap-Rewrite, wenn RoadKit + flat ground + Props für die Slice reichen
- Volle **Hub↔World Scene-Transition** / Spawn-Handoff (späterer M3-Schritt; Erdstation-Prop bleibt)
- Online, andere Orte (Winterthur etc.), neue spielbare Charaktere

---

## Systeme

| System | Rolle in dieser Slice |
|--------|------------------------|
| World | `scenes/world_sandbox.tscn` + `scripts/world_sandbox.gd` **erweitern** (bevorzugt) — oder neue World-Scene als `run/main_scene`, wenn Layout klar getrennt wird; Locomotion/RoadKit nicht neu erfinden |
| RoadKit | `scripts/road_kit.gd` — Straßengerüst zwischen Districts |
| Props / Landmarks | Sprite2D unter `%Props`; Meta oder Node-Namen für Tests (`landmark_*`, `district_ohringen`, `house_*`) |
| Hub | Bestehendes `hub_station.png` im Dorfkern; keine Pflicht-Transition |
| Art | Stil C via **`comic-rettung-art`**; Refs `docs/design-refs/c-*.png` + Street-View/Foto-Silhouetten (stilisiert) |
| Y-Sort | `compute_prop_z` / `compute_actor_z` (bereits vorhanden) |
| Tests | Neuer `tests/m3_*_test.gd` (+ bestehende World-Smoke weiter grün) |

---

## Repro & RCA

n/a (Typ = Feature)

---

## Technische Schritte

1. **Layout skizzieren (Screen-Space-Koordinaten)**  
   Relative Positionen der Districts festhalten (z. B. Dorfkern Zentrum, Bahnhof eine Achse, Feuerwehr/Badi/Schulen/Ohringen an verbundenen Straßen). Referenz: Konzept-Zonen + reale Ortslage nur als Silhouetten-Hilfe — stilisieren.

2. **Art-Lieferung (`comic-rettung-art`)**  
   Style C, Street-View/reale Refs für Silhouette; danach:
   - `python3 scripts/process_art_alpha.py`
   - `python3 scripts/verify_art_alpha.py` (grün)
   - ggf. `godot --headless --path . --import` bevor Tests `ResourceLoader.exists` erwarten

3. **World erweitern**  
   In `world_sandbox.gd` (oder Nachfolger-Scene):
   - RoadKit: Achsen zwischen Districts statt Demo-Kreuz allein
   - `_place_landmarks()`: Landmark-Props + Haus-Varianten platzieren
   - Props mit **identifizierbaren** `name` und/oder `set_meta("landmark_id"|"district"|"house_variant", …)`
   - Schulen: je Standort **Cluster** (≥2 Einzelgebäude: `*_a` + `*_b`; Turnhalle optional)
   - Ohringen: eigener District-Marker/Node-Gruppe (Häuser/Farm dort, nicht nur Label)
   - Kirche (`tile_church.png`) + `hub_station.png` im Dorfkern behalten
   - Collision auf Gebäuden: optional `StaticBody2D` — nicht blockierend für Slice-Done

4. **Main-Scene**  
   Weiter `world_sandbox.tscn` als Main, sofern Layout dort lebt; sonst neue Scene verdrahten und alte Tests/Play-Scripts anpassen.

5. **Tests**  
   Siehe Testplan — Regression: bestehende `m2_world_test` weiterhin sinnvoll (kein Rückfall auf Tile-Sprites als Ground).

6. **Review → Playtest**  
   `code-reviewer` → `godot-playtester` (Scene startet, Landmarken lesbar, Alpha grün, kein AI-Platten-Look).

---

## Testplan

### Automatisiert

- [x] Scene lädt (`world_sandbox.tscn` bzw. neue Main-World) ohne Error
- [x] Landmarken vorhanden (per Meta und/oder Node-Name):  
      `bahnhof`, `feuerwehr`, `badi_weiher`, `gemeindehaus`, `tankstelle`,  
      Kirchen `kirche_seuzach` / `kirche_ohringen`,  
      Schul-Cluster `birch` / `rietacker` / `ohringen` (je ≥2 Gebäude-Props),  
      Kindergärten `kiga_bachtobel` / `kiga_weid` / `kiga_schneckenwiese` / `kiga_ohringen`,  
      mind. 1 Restaurant + 2 Läden
- [x] Haus-Vielfalt: mindestens **4** verschiedene House-Variant-Textures/IDs in der Scene (nicht nur `tile_house` × N)
- [x] District **Ohringen** existiert (Meta/Node/Gruppe nachweisbar; mind. 1 Prop dort)
- [x] Art-Dateien unter `res://assets/art/` für die gelisteten Landmark-/House-PNGs `ResourceLoader.exists`
- [x] Bestehende Ground/RoadKit-Guards aus `m2_world_test` bleiben grün (kein Sprite2D-Boden-Flood)

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Fatal Error
- [x] Spieler kann zwischen Districts entlang der Straßen fahren/laufen
- [ ] Bahnhof, Feuerwehr, Badi, Schul-Cluster und Ohringen visuell unterscheidbar *(manual)*
- [x] Häuser wirken abwechslungsreich (nicht ein Sprite überall)
- [x] `hub_station` + Kirche im Dorfkern sichtbar
- [x] `verify_art_alpha.py` grün; keine weißen/schwarzen AI-Platten um Props
- [ ] Y-Sort: Props/Player überdecken sich plausibel nach Y *(manual)*

---

## Art-Bedarf

- [x] Neue Grafiken → Subagent **`comic-rettung-art`** (Stil C; Street View / reale Refs für Silhouette, stilisiert)

Konkrete Ziel-PNGs unter `assets/art/` (Naming laut Agent-Konventionen; Schulen als Einzelgebäude):

| Asset | Dateiname |
|-------|-----------|
| Bahnhof Seuzach | `landmark_bahnhof_seuzach.png` |
| Feuerwehr Seuzach | `landmark_feuerwehr_seuzach.png` |
| Badi Weiher | `landmark_badi_weiher.png` |
| Schulhaus Birch | `landmark_schulhaus_birch_a.png`, `landmark_schulhaus_birch_b.png` |
| Schulhaus Rietacker | `landmark_schulhaus_rietacker_a.png`, `landmark_schulhaus_rietacker_b.png` |
| Schulhaus Ohringen | `landmark_schulhaus_ohringen_a.png`, `landmark_schulhaus_ohringen_b.png` |
| Turnhalle (optional) | `landmark_schulhaus_*_turnhalle.png` oder `landmark_turnhalle_{birch\|rietacker\|ohringen}.png` |
| Wohnen / Farm | `house_a.png`, `house_b.png`, `house_c.png`, `house_d.png`, `house_farm.png` |
| Kindergarten Bachtobel | `landmark_kiga_bachtobel.png` |
| Kindergarten Weid | `landmark_kiga_weid.png` |
| Kindergarten Schneckenwiese | `landmark_kiga_schneckenwiese.png` |
| Kindergarten Ohringen | `landmark_kiga_ohringen.png` |
| Gemeindehaus | `landmark_gemeindehaus_seuzach.png` |
| Kirche Seuzach | `landmark_kirche_seuzach.png` (ersetzt/ergänzt `tile_church.png` im Dorfkern) |
| Kirche Ohringen | `landmark_kirche_ohringen.png` |
| Tankstelle | `landmark_tankstelle_seuzach.png` |
| Restaurant | `landmark_restaurant_a.png`, `landmark_restaurant_b.png` |
| Läden | `landmark_laden_a.png`, `landmark_laden_b.png`, `landmark_laden_c.png` |
| Bestehend behalten | `hub_station.png` (Dorfkern); `tile_church.png` optional Fallback |

Pipeline nach Lieferung: `process_art_alpha.py` → `verify_art_alpha.py` → Import bei Bedarf.  
Hinweise: Feuerwehr = CH Werk-/Garagenbau (Strehlgasse), nicht US-Firehouse; Badi = Outdoor-Freibad; Schulen = Cluster, kein Megablock; Kigas klein/freundlich; Ohringen gehört zur Gemeinde; Tankstelle CH-Dorfstil; Läden/Restaurants lesbare Schilder-Silhouetten ohne lesbaren Markentext.

---

## Akzeptanzkriterien

- [x] World deckt **Seuzach und Ohringen** als lesbare Districts ab
- [x] Landmarken Bahnhof, Feuerwehr, Badi Weiher, Gemeindehaus, Tankstelle, Kirchen, Restaurants, Läden platziert und stilistisch C
- [x] Drei Schulstandorte als **Gebäude-Cluster** (Birch, Rietacker, Ohringen)
- [x] Vier Kindergärten (Bachtobel, Weid, Schneckenwiese, Ohringen)
- [x] Mindestens vier Haus-Varianten (+ Farm wo sinnvoll) in der Welt
- [x] Straßen verbinden die Districts; bestehende Locomotion funktioniert
- [x] Kirche + Erdstation-Prop im Dorfkern (`landmark_kirche_seuzach` mit Fallback `tile_church`)
- [x] Y-Sort über bestehendes BASE+y
- [x] Automatisierte Tests grün (Landmarken, Variety, Ohringen, Load)
- [ ] Code Review ohne offene Critical/High
- [x] Playtest Pass
- [x] Hub↔World-Transition **nicht** blockierend für Done dieser Slice (explizit deferred)

---

## Hinweise für Implementer / Review

- Prefer **extend sandbox** over TileMap rewrite for this shippable slice.
- Meta/Node-Namen stabil halten — Tests hängen daran.
- Keine Stil-A/B-Assets; Facing/Lean-Learnings betreffen Player, nicht Landmark-Props.
- Nach Phase-4-Pass: Commit, Push, SemVer-Tag (`git-release`).

---

## Changelog

| Datum | Änderung |
|-------|----------|
| 2026-08-11 | Erstentwurf: M3 first playable slice Seuzach+Ohringen (Feature, Status Entwurf) |
| 2026-08-11 | Erweiterung: Kindergärten, Restaurants, Tankstelle, Gemeindehaus, Kirchen, Läden |
| 2026-08-11 | Implement: world layout + RoadKit + metas + m3_world_landmarks_test → Status Review |
| 2026-08-11 | Extend: Kindergärten + POIs (Gemeindehaus, Kirchen, Tankstelle, Restaurants, Läden) wired; tests erweitert |
| 2026-08-11 | Playtest Pass: verify_art_alpha (171 PNGs), TEST SUITE PASSED inkl. m3_world_landmarks_test, godot --quit-after 5 → Status Erledigt |
