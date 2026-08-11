# Slice: S04 — Seuzach-Kigas Bachtobel + Weid + Schneckenwiese

**Parent:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Hängt ab von:** S01 (erledigt); Pattern wie S03  
**Phase 1:** übersprungen (Stub + locked Mults ausreichend)

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Die drei Seuzach-Kindergärten Bachtobel, Weid und Schneckenwiese sind wieder korrekt ausgerichtet und grob stimmig groß gegenüber Strasse und Nachbarschaft — validiert gegen Google Maps / Street View. Drei gleiche Landmark-Typen, ein Placement-System, zusammen review-/playtestbar.

## In diesem Schritt

- Rotation/Facing und Größe für Kiga Bachtobel vs. Maps/Street View
- Dasselbe für Weid und Schneckenwiese
- Keine Änderung am Ohringen-Kiga (S03)

## Nicht (andere Feature-Schritte)

- Schul-Campi; Kiga Ohringen; Bahnhof/Badi
- Globale Scale-Konstanten (S01); neue Wohnhäuser

## Locked Mult-Tabelle

`effective = SCHOOL_SCALE (0.50) * MULT`

| Prop | MULT | Effective |
|------|------|-----------|
| `kiga_bachtobel` | **0.57** | 0.285 (~15 m) |
| `kiga_weid` | **0.55** | 0.275 (~11 m floor for readability) |
| `kiga_schneckenwiese` | **1.03** | 0.515 (~28 m twin-wing) |

Named consts: `KIGA_BACHTOBEL_SCALE_MULT`, `KIGA_WEID_SCALE_MULT`, `KIGA_SCHNECKENWIESE_SCALE_MULT`.  
`flip_h` false; GPS/Zentroide unverändert.

## Art

- nein — Rotation/Scale im Code; Art nur bei falschem Sprite-Facing

## Testplan

- Suite: drei Seuzach-Kiga-Scales (`SCHOOL_SCALE * MULT`); Position ±80 wu; `rotation == 0`; `kiga_ohringen` weiter 0.275; `house_n == 0`
- Playtest: Bachtobel, Weid, Schneckenwiese lesbar; Ausrichtung/Größe vs. Maps/Street View grob stimmig

## Akzeptanzkriterien

- [ ] Drei Props mit locked Mults; `flip_h` false; GPS unverändert
- [ ] Ohringen-Kiga / Campi / Bahnhof / Badi unberührt; globales `SCHOOL_SCALE` 0.50
- [ ] Suite grün; Review + Playtest Pass

Playtest 2026-08-12: Pass (three Seuzach kigas; Schneckenwiese largest).
