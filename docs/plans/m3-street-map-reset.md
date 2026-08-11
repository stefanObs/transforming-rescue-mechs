# Plan: m3-street-map-reset

**Status:** Erledigt  
**Typ:** Bug / Korrektur  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/m3-roads-housing-realism.md`](m3-roads-housing-realism.md) · Google Maps Seuzach · OSM named highways  
**Art:** keine neue Art

---

## Ziel

Wohnbebauung zurücksetzen (keine Häuser). Zuerst eine **Straßenkarte**, die Seuzach+Ohringen gegen Google Maps reproduziert — mit **unterschiedlichen Straßenbreiten** (Autobahn / Hauptstrasse / Sammler / Quartier). Keine Fusswege.

---

## Repro & RCA

### Repro

1. World laden: Häuser stapeln sich (gleiche Sort-Y / zu enge Blöcke / grosse Sprites).
2. Strassen: eine schräge N–S-Mischung, Breiten fast gleich (`half_w` 78 / 0.85 / 0.72).

- [x] Repro bestätigt (Code + User)

### RCA

- Housing-Blöcke ohne Strassen-Offset/Parzellenraster → Überlagerung.
- RoadKit nutzte fast eine Breite; Achsen vereinfacht statt Maps-Polylinien.
- **Fix:** alle `house_*`-Props entfernen; Polylinien + 4 Breitenklassen aus Maps/OSM.

### RCA (Review: Kreisel)

- Kreisel `(260, -400)` sass auf Landstrasse/Welsikoner-Vertices → Straights durch die Insel.
- **Fix:** Kreisel in diesem Slice weglassen (keine Fusswege/Ring-Clips); Achsen bleiben Maps-treu.

---

## Scope

### In

- `_place_housing_blocks` entfernen / no-op
- `_add_continuous_roads` als Polylinien mit `road_class` + `half_w`
- Marker: `road_name`, `road_class` ∈ {motorway, main, collector, local}
- Tests: 0 Häuser; ≥4 Breitenklassen; Maps-Namen; Winterthurer westlich von Stationsstrasse
- Landmarks (Kirche, Schulen, Hub …) bleiben

### Nicht

- Neue Häuser, Fusswege, OSM-1:1-Kurven jedes Quartierwegs

---

## Maps-Netz ( +X Ost, +Y Süd, Kirche ≈ 0 )

Google Maps (Satellit + Roadmap, 2026-08-11) + Nominatim, Kirche = Ursprung:

| Klasse | half_w | Strassen |
|--------|--------|----------|
| motorway | 110 | A1 (S, E–W, westlich bis Ohringen-Anschluss, Forrenberg) |
| main | 72 | Winterthurerstrasse (N–S, x≈−125), Ohringerstrasse (E–W nördlich Kirchhügel → Ohringen SW), Stationsstrasse (Ost/Bahnhof), Welsikonerstrasse (NO), Schaffhauserstrasse (N–S Ohringen/H15) |
| collector | 52 | Landstrasse (N, Badi), Reutlingerstrasse (Ost), Stadlerstrasse (Bahnhof), Hettlingerstrasse (N), Forrenbergstrasse (S → Hub/A1) |
| local | 36 | Kirchgasse, Strehlgasse, Bachwiesenstrasse, Weiherstrasse, Breitestrasse, Schulstrasse, Seebühlstrasse, Weidstrasse |

Kein footway. Junction `J_KERN` ≈ Winterthurer × Ohringer. Wälder südlich der A1 versetzt, damit die Autobahn frei bleibt.

---

## Testplan

- [x] Keine Sprite mit `house_variant`
- [x] ≥4 `road_class` und ≥3 distinkte `half_w`
- [x] Pflicht-Namen: Winterthurerstrasse, Landstrasse, Ohringerstrasse, Stationsstrasse, Reutlingerstrasse, A1, Welsikonerstrasse
- [x] Winterthurer-Marker x < Stationsstrasse-Marker x
- [x] Ohringerstrasse erreicht Ohringen (x&lt;−900, y&gt;200); A1 reicht westlich (x&lt;−800)
- [x] Suite grün

---

## Akzeptanzkriterien

- [x] Keine Häuser in der World
- [x] Strassennetz Maps-plausibel, klar unterschiedliche Breiten
- [x] Review + Playtest Pass
