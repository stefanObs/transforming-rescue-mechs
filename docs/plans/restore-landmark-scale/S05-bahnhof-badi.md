# Slice: S05 — Bahnhof + Badi Ausrichtung

**Parent:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Bahnhof Seuzach und Badi/Weiher (zwei Civic-Landmarks) haben grob korrekte Ausrichtung und Größenverhältnisse zur Strasse bzw. zueinander — validiert gegen Google Maps / Street View.

## In diesem Schritt

- Bahnhof: Rotation/Facing und Größe vs. Maps/Street View (Gleis-/Strassenbezug grob stimmig)
- Badi: Ausrichtung und Größe vs. Maps/Street View
- Bestehende Landmark-Sprites; Tracks/Wasser-Layout nicht neu bauen

## Nicht (andere Feature-Schritte)

- Schul-Campi und Kigas (S02–S04)
- Globale Scale-Konstanten (S01); Gleisnetz/Bäche neu legen; neue Wohnhäuser

## Art (optional, damit Planner übersprungen werden kann)

- nein — bevorzugt Rotation/Scale im Code; Art nur bei falschem Sprite-Facing

## Locked Mults (LANDMARK_SCALE 0.55)

| Prop | MULT | Effective |
|------|------|-----------|
| `bahnhof` | **0.79** | ~0.4345 (~35 m station; PNG oversized at 0.55) |
| `badi_weiher` | **1.01** | ~0.5555 (~45 m pool complex, nearly 1.0) |

Named consts: `BAHNHOF_SCALE_MULT`, `BADI_SCALE_MULT`.  
`LANDMARK_SCALE * MULT` in `_place_bahnhof` / `_place_badi`.  
`flip_h` false; GPS unverändert; Rotation 0 (Bahnhof south of tracks, canopy faces N authored; Badi north of Landstrasse).  
Forests stay `FOREST_SCALE` 0.24. Schulen/Kigas nicht anfassen.

## Art

- nein — Rotation/Scale im Code; Art nur bei falschem Sprite-Facing

## Testplan

- Suite: Bahnhof/Badi scales (`LANDMARK_SCALE * MULT`); Position ±80 wu; `rotation == 0`; forests 0.24; `house_n == 0`; Schulen unberührt
- Playtest: beide Civic-Landmarks lesbar; Ausrichtung/Größe vs. Maps/Street View grob stimmig

## Akzeptanzkriterien

- [ ] Zwei Props mit locked Mults; `flip_h` false; GPS unverändert; Rotation 0
- [ ] Forests `FOREST_SCALE` 0.24; Schulen/Kigas unberührt; globales `LANDMARK_SCALE` 0.55
- [ ] Suite grün; Review + Playtest Pass

Playtest 2026-08-12: Pass (Bahnhof south of tracks canopy N; Badi readable; Mults 0.79/1.01).
