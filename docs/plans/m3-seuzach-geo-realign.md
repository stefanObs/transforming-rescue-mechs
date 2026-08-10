# Plan: m3-seuzach-geo-realign

**Status:** Erledigt  
**Typ:** Feature / Korrektur (Geo-Abgleich)  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/mvp.md`](mvp.md) Epic M3 · [`docs/plans/m3-seuzach-ohringen-world.md`](m3-seuzach-ohringen-world.md) · [`docs/plans/m3-hub-world-transition.md`](m3-hub-world-transition.md) · [`docs/ENTWICKLUNGSABLAUF.md`](../ENTWICKLUNGSABLAUF.md)  
**Art:** Stil C — Subagent **`comic-rettung-art`** · Refs Maps/Street View + `docs/design-refs/c-*.png`

---

## Ziel

Seuzach+Ohringen so ausrichten, dass Straßen, Wege, Gebäude, Sportplätze, Wälder, Hügel und ungefähre Proportionen gegenüber **Google Maps / Street View / OSM** wiedererkennbar und stimmig sind. **Basisstation (Hub) an Tankstelle Forrenberg (A1)**. Badi-Becken/Rutschbahn, Kirchenformen, Kigas/Schulen, Spielplätze und Turnhallen korrigieren — iterieren bis der Slice stimmt.

---

## Scope

### In

- Geo-Layout (stilisiert, ~0.85 u/m, +X Ost, +Y Süd, Ursprung Reformierte Kirche ≈ `(0,0)`):
  - Hub + Tankstelle **Forrenberg** (~`(490, 600)`)
  - Badi Weiher **Norden** (~`(460, -550)`), nicht Süden
  - Bahnhof Osten (~`(890, -130)`)
  - Birch Osten, Rietacker nahe Kirche N, Ohringen **SW**
  - Feuerwehr / Gemeindehaus / Kigas an OSM-Nähe
- Straßennetz RoadKit neu an Achsen (Dorf N–S, Bahnhof E–W, Ohringen-Zweig, Forrenberg/A1-Süd)
- Hügel erkennbar: **Kirchhügel**, Forrenberg-Erhebung, ggf. Erdbühl-Nähe Badi
- Wälder / Baumstreifen (Props oder Polygone) zwischen Ohringen↔Dorf und N-Rand
- Sportplätze + Turnhallen (Rietacker Sporthalle, Ohringen Turnhalle, Birch Turnhalle/Annex) + Spielplätze
- Hub-Enter/Spawn an Forrenberg (Clearance wie bisher)
- Art-Korrekturen: Badi (Becken + 72m-Rutsche), Kirche Seuzach (Kirchhügel-Silhouette), **St. Martin** statt fiktiver Ohringen-Kirche, fehlende Sport/Spiel/Turnhallen-Assets
- Tests + Suite anpassen; Review → Playtest → Commit/Push/Tag

### Nicht

- OSM 1:1 Meter-Genauigkeit / jedes Haus
- M4 Energie/Waffen, M5 Missionen
- Neue spielbare Charaktere

---

## Repro & RCA

### Repro (Ist-Welt vs. Maps)

1. `world_sandbox`: Badi bei `(500, 700)` = **Süden**; OSM/Maps: Schwimmbad Weiher **nördlich** der Kirche (~+640 m N).
2. Hub bei Dorfkern `(40, 300)`; User/Maps: Basis an **Tankstelle Forrenberg** (~700 m S der Kirche, A1).
3. Ohringen-Cluster NW; real Schulhaus Ohringen **SW**.
4. Birch/Rietacker E–W praktisch vertauscht (Birch real östlich nahe Bahnhof).
5. Satellit Badi: mehrere Rechteck-/Planschbecken + **lange** Rutsche; Asset: Burg-Spiralrutsche + hex Planschbecken.
6. `kirche_ohringen`: keine eigene Pfarrkirche in Ohringen (Wiki: ref. Kirche, St. Martin, FEG in Seuzach).
7. Turnhalle Ohringen-Art vorhanden, aber nicht platziert; Sporthalle Rietacker / Sportplatz / Wald / Hügel fehlen.

- [x] Repro bestätigt (Nominatim-Projektion + Google Satellit Badi + Gemeindequellen)

### RCA

- Slice-1 Layout war narrative Cluster, nicht geo-projiziert; Hub blieb im Dorfkern-Stub.
- Art-Silhouetten ohne ausreichenden Satellit-/Foto-Abgleich für Badi/Kirchen.
- **Fix:** Koordinaten-Tabelle + RoadKit-Realign; Hub→Forrenberg; Art-Nachlieferung; Tests auf neue Landmark-IDs/Metas.

### RCA (Review-Finding Spawn/Tankstelle)

- **Ursache:** Tankstelle Forrenberg zu nah an Hub-Enter/Spawn; Clearance-Test prüfte nur Hub-StaticBody.
- **Fix:** Spawn/Enter weiter südlich `(490,750)/(490,760)`; Tankstelle nach Osten `(680,600)`; Test prüft alle Forrenberg-BuildingCollisions.

---

## Geo-Tabelle (Referenz, stilisiert)

| POI | ≈ Game (x,y) | Hinweis |
|-----|--------------|---------|
| kirche_seuzach | (0, 0) | Kirchhügel |
| gemeindehaus | (230, -320) | |
| feuerwehr | (260, -360) | |
| rietacker + Sporthalle | (60, -260) / (10, -250) | |
| birch | (650, -170) | Osten |
| bahnhof | (890, -130) | |
| kiga_weid | (750, 40) | |
| kiga_bachtobel | (760, -380) | |
| kiga_schneckenwiese | (310, -100) | |
| badi_weiher + Sport | (460, -550) | N; Sportplatz N/NO |
| forrenberg hub+tank | (490, 600) | Hub-Enter S davon |
| ohringen schule+kiga+turnhalle | (−890, 520) | SW |
| unterohringen | (−750, −80) | W |
| st_martin | (~550, 250) | modern, Reutlingerstr. stilisiert |

---

## Technische Schritte

1. Plan (dieses File) + RCA.
2. Art (`comic-rettung-art`): Badi-Rewrite; St. Martin; Sportplatz; Spielplatz; Turnhalle Birch/Rietacker; optional Wald-Patches; Kirche Seuzach Feinschliff; Tankstelle Forrenberg-Look. Danach Alpha-Pipeline + Import.
3. `world_sandbox.gd`: Roads + Props + Hügel-Polygone + Hub/Spawn Forrenberg; remove/replace `kirche_ohringen`.
4. Tests: `m3_world_landmarks_test`, `m3_hub_transition_test` (Spawn/Enter bei Forrenberg).
5. Review → Playtest → Iteration (Maps-Stichproben) → Release.

---

## Testplan

- [x] Art exists inkl. neuer Assets; Alpha grün
- [x] Landmark-Positionen grob in erwarteten Quadranten (Badi Y&lt;0, Forrenberg Y&gt;400, Ohringen X&lt;−500)
- [x] Hub bei Forrenberg; Enter clear of collision
- [x] Turnhallen/Sportplatz/Spielplatz/Wald/Hügel Metas oder Nodes vorhanden
- [x] `kirche_st_martin` statt `kirche_ohringen`
- [x] Suite grün; Playtest Smoke

---

## Art-Bedarf

| Asset | Aktion |
|-------|--------|
| `landmark_badi_weiher.png` | Rewrite: 33m-Becken, Nichtschwimmer, Plansch, Sprung, **lange** 72m-Rutsche |
| `landmark_kirche_seuzach.png` | Feinschliff: weiss, grüner Spitzhelm, Uhren, Kirchhügel-Sockel ok |
| `landmark_kirche_st_martin.png` | Neu modern 1970er; `kirche_ohringen` ersetzen |
| `landmark_sportplatz.png` | Rasenplatz Tore |
| `landmark_spielplatz.png` | Öffentlicher Spielplatz |
| `landmark_turnhalle_birch.png` / `_rietacker.png` | Hallen |
| `landmark_turnhalle_ohringen.png` | Bestehend platzieren |
| `landmark_wald_a.png` / `_b.png` | Baumcluster |
| `landmark_tankstelle_seuzach.png` | Optional Forrenberg/Autobahn-Raststätte-Look |

---

## Akzeptanzkriterien

- [x] Relative Lage Seuzach+Ohringen+Forrenberg+Badi+Bahnhof stimmt grob zu Maps
- [x] Hub an Forrenberg-Tankstelle; Enter spielbar
- [x] Hügel und Wälder erkennbar
- [x] Badi Becken/Rutsche, Kirchen, Schulen/Kigas, Spielplätze/Turnhallen plausibel
- [x] Tests + Review + Playtest Pass
