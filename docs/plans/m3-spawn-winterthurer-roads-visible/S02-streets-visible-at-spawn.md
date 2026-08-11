# Slice: S02 — Strassen im Start-Viewport sichtbar

**Status:** Slice-Entwurf  
**Typ:** Bugfix  
**Parent:** `docs/plans/m3-spawn-winterthurer-roads-visible/INDEX.md`  
**Datum:** 2026-08-11  
**Hängt ab von:** S01

Dieses File ist der **Schritt**. Phase 1 (`feature-planner`) füllt es zum vollständigen Plan; Phase 2–4 gelten nur für **diesen** Slice.

## Ziel

Vom Start auf der Winterthurerstrasse (WINT-KERN, nach S01) sind **Asphalt-Strassen klar sichtbar** — kein Playtest mehr mit „nur Grün“.

## Grenzen

- In:
  - Sichtbarkeit der RoadKit-Strassen **im Start-Viewport** (Kamera am Player, zoom 0.9 auf `world_sandbox`)
  - Nur die per Phase-0 bestätigte Ursache: z. B. Half-Widths unskaliert (36–110 wu bei 5,3 m/Feld), JSON `data/seuzach_roads.json` lädt nicht, Gras-Z-Order überdeckt Asphalt, Zeichenfehler, oder Kamera zeigt kein Asphalt
  - Winterthurerstrasse (main) in WINT-KERN als Pflicht-Prüfpunkt; andere Klassen nur soweit nötig, damit das Netz am Spawn lesbar ist
- Nicht (andere Slices / Rest der Aufgabe):
  - Spawn-Position (S01)
  - Housing, Ohringen-Zellen, Forrenberg-Hub, neue Art
  - Komplette Karte neu tracen / alle Nebenstrassen umbauen
  - Kamerazoom als separates Feature, ausser RCA bestätigt Zoom als Ursache — dann Fix *hier*, nicht als dritter Slice
- Raster / Felder / GPS / Asset-Namen:
  - Abnahme in **WINT-KERN** `30..45, −15..10` vom S01-Spawn
  - OSM: `res://data/seuzach_roads.json`, Loader `scripts/world_sandbox.gd` (`ROADS_JSON`, `_add_continuous_roads`)
  - Half-Widths heute: Motorway 110 / Main 72 / Collector 52 / Local 36 wu

## Systeme

RoadKit / `world_sandbox` Ground-Polygone, optional Kamera in `scenes/world_sandbox.tscn`, `SeuzachGeo` nur falls Viewport/Bounds die Ursache sind.

## Repro & RCA (Pflicht bei Typ = Bugfix)

Vor Phase 2 ausfüllen. Bei Features: Abschnitt weglassen oder „n/a“.

### Reproduktion

- [ ] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. Nach S01 World starten. 2. Ohne zu laufen: Viewport am Spawn (zoom 0.9). 3. Prüfen ob Winterthurer-Asphalt vs. nur `COLOR_GRASS`. 4. Optional F1 / Road-Debug-Namen. |
| Erwartet | Grauer/Asphalt-Streifen Winterthurerstrasse unter/neben der Figur; Netz im Viewport lesbar. |
| Tatsächlich | Playtest vor Fix: **nur Grün**. Hypothesen: Spawn war Gras (S01) **und/oder** Strassen zeichnen nicht / zu dünn / JSON fehlt / Gras überdeckt / Kamera ohne Asphalt. |
| Umgebung | Godot 4, `world_sandbox`, Player-Kamera `zoom = (0.9, 0.9)`, Gras = `WORLD_BOUNDS` |
| Evidenz | Screenshot Start-Viewport; Log-Warnings `Missing/Cannot read seuzach_roads.json`; Ground-Kinder mit `road_name` |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) Half-Widths 36–110 wu nicht an 5,3 m/Feld skaliert — unwahrscheinlich allein bei zoom 0.9 (Main ≈ 144 wu breit). (2) JSON lädt nicht / `roads` leer. (3) Gras-Polygon z_index über RoadKit. (4) Kamera/Bounds zeigen kein Asphalt. (5) S01 unvollständig: Spawn noch neben der Fahrbahn. |
| Bestätigte Ursache | … |
| Nicht die Ursache | Housing; Ohringen; Spawn-Koordinaten (S01), sofern Figur bereits auf der Polyline steht. |
| Fix-Richtung | Nur die bestätigte Ursache; keine Blind-Width-und-Kamera-und-JSON-Änderungen in einem Rutsch ohne RCA. |
| Risiken | Strassen unproportional breit; Dash/Junction-Radien; Tests auf feste `half_w`-Werte (`m3_world_landmarks_test` Width-Klassen). |

- [ ] RCA dokumentiert

## Technische Schritte

1. Phase 0 vom S01-Spawn: Repro „nur Grün“ ja/nein; Hypothesen (JSON, Z-Order, Breite, Kamera, Offset zur Polyline) gezielt widerlegen.
2. Regressionstest, der die bestätigte Ursache rot macht (z. B. Winterthurer-`half_w` sichtbar relativ zum Viewport; JSON `roads.size`; Ground-Road-Nodes; Spawn auf Asphalt-Polygon).
3. Minimalfix nur für bestätigte Ursache.
4. Playtest: Start-Viewport zeigt Winterthurer-Asphalt, kein Grün-Vollbild.

## Testplan

### Automatisiert

- [ ] `seuzach_roads.json` lädt; Winterthurerstrasse-Punkte vorhanden
- [ ] RoadKit-Nodes für Winterthurerstrasse in WINT-KERN (Marker/`road_name`)
- [ ] Regression zur bestätigten Ursache (Breite und/oder Z-Order und/oder Load und/oder Kamera-Coverage des Spawn-Punkts)
- [ ] Suite grün

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Am Spawn: Winterthurerstrasse als Asphalt sichtbar, nicht nur Grün
- [ ] Keine weissen/schwarzen AI-Platten (Art unverändert)
- [ ] Nur dieser Slice: kein Housing, Spawn-Lage nicht zurück nach Forrenberg

## Art-Bedarf

- [ ] Keine neuen Assets
- [ ] Neue Grafiken → `comic-rettung-art` **nur** für die Assets dieses Slices  
  Details: n/a (bestehendes RoadKit)

## Akzeptanzkriterien

- [ ] Grenzen eingehalten (nichts aus Nachbar-Slices)
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass
- [ ] Git: Commit + Push + Tag für **diesen** Slice
