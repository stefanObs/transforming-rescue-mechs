# Plan: m3-roads-housing-realism

**Status:** Erledigt  
**Typ:** Feature / Korrektur  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/m3-seuzach-geo-realign.md`](m3-seuzach-geo-realign.md) · Google Maps Satellit Seuzach · [`docs/ENTWICKLUNGSABLAUF.md`](../ENTWICKLUNGSABLAUF.md)  
**Art:** Stil C — `comic-rettung-art` / GenerateImage + Alpha-Pipeline

---

## Ziel

Straßennetz stilisiert an **Google Maps** (Hauptachsen) anbinden; Wohnbebauung mengenmäßig realistischer und typologisch korrekt: **Mehrfamilienhäuser**, **Flachdach**, **Reihenhäuser** neben bestehenden EFH/Farm.

---

## Repro & RCA

### Repro (Ist)

1. RoadKit: eine schräge N–S-Achse statt getrennter **Winterthurerstrasse** (W) + **Landstrasse** (Mitte).
2. Wenige Wohnprops (~8) nur Varianten a–d + farm — keine MFH/Flachdach/Reihen.
3. Satellit: dichtes Wohnnetz S/O vom Kern, MFH eher Bahnhof/Schulen, Flachdach Gewerbe/A1-Nähe, Reihen im Siedlungsgebiet.

- [x] Repro bestätigt (Maps-Screenshot + Code)

### RCA

- Geo-Slice priorisierte Landmarken; Straßen/Häuser blieben Stub-Dichte.
- **Fix:** Achsen laut Maps; neue Haus-Art; dichtere Platzierung entlang Straßen mit Spacing-Regeln (Occlusion).

---

## Scope

### In

- RoadKit: Winterthurerstrasse, Landstrasse, Ohringerstrasse, Stationsstrasse, Reutlinger-/Forrenbergstrasse, Kirchgasse, Landstrasse→Badi, A1, Wohn-/Nebenstraßen-Stichproben
- Neue Art: `house_mfh.png`, `house_flachdach.png`, `house_reihen.png` (+ optional zweite Reihen-/MFH-Variante)
- Mehr Häuser in Districts mit `house_variant` / `roof_type` Metas
- Tests: Straßen-Marker oder Segment-Count; Pflicht-Varianten mfh/flachdach/reihen; Mindestanzahl Häuser
- Review → Playtest → Tag

### Nicht

- Jede Wohnstrasse 1:1; OSM-Import-Engine

### RCA (Review-Finding doppelte Housing-Platzierung)

- **Ursache:** `_place_housing_blocks()` wurde zweimal aufgerufen (früh + nach DistrictOhringen).
- **Fix:** nur einmal nach District-Erstellung; Test auf doppelte Haus-Positionen.

---

## Maps-Achsen (stilisiert, +X Ost +Y Süd, Kirche≈0)

| Achse | Rolle | ≈ Game |
|-------|--------|--------|
| Winterthurerstrasse | N–S West | x≈−120, y −700…700 |
| Landstrasse | N–S Mitte | x≈180, y −700…650 |
| Ohringerstrasse | E–W → Ohringen | y≈−40, x −1000…400 |
| Stationsstrasse | → Bahnhof | y≈−100, x 400…950 |
| Reutlinger/Forrenberg | SE → A1/Hub | Diagonale 150,100 → 490,600 |
| Kirchgasse | zum Kirchhügel | kurz W von Landstrasse |
| A1 | S | y≈780 E–W |
| Wohnstich | Breitestrasse / Seebühl | kurze E–W Äste |

---

## Technische Schritte

1. Plan (dieses File)
2. Art MFH / Flachdach / Reihen (+ Alpha)
3. `_add_continuous_roads` neu; `_place_housing_blocks`
4. Tests erweitern
5. Review / Playtest / Release

---

## Testplan

- [x] ≥3 house_variant in {mfh, flachdach, reihen}
- [x] ≥20 Wohnprops (house_*)
- [x] Road segments: Winterthurer + Landstrasse als getrennte N–S
- [x] Suite grün

---

## Akzeptanzkriterien

- [x] Hauptachsen Maps-plausibel
- [x] MFH, Flachdach, Reihenhäuser sichtbar und häufiger als Stub
- [x] Occlusion/Spacing weiter ok
- [x] Review + Playtest Pass
