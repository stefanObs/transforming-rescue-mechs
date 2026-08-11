# Slice: S03 — Ohringen Campus + Kiga Ausrichtung

**Parent:** `docs/plans/restore-landmark-scale/INDEX.md`  
**Hängt ab von:** S01 (erledigt); Pattern wie S02  
**Phase 1:** übersprungen (Stub + S02-Pattern ausreichend)

Nur der **Feature-Schritt** (zwei verwandte spieler-sichtbare Inkremente: Ohringen-Campus + Kiga Ohringen). INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Ziel

Schul-Campus Ohringen und Kindergarten Ohringen (gleiche Ortsteil-Zelle) haben grob korrekte **Gebäude-Größenverhältnisse** (Maps/OSM-Footprint-Ratios auf `SCHOOL_SCALE`) und Ausrichtung (`flip_h` false, `rotation` 0). GPS/Zentroide unverändert.

## Feature / In diesem Schritt

- Ohringen-Campus: per-building Scale-Mults für `schulhaus_ohringen_{a,b}`, `turnhalle_ohringen`
- Kiga Ohringen: Scale-Mult relativ zu Campus/Strasse (Floor 0.55 für Lesbarkeit)
- Ohringen bleibt eigene Rasterzellen; keine Seuzach-Kiga-Änderungen

## Nicht (andere Feature-Schritte)

- Birch/Rietacker (S02); Bachtobel/Weid/Schneckenwiese (S04); Bahnhof/Badi (S05)
- Globale `SCHOOL_SCALE` / `LANDMARK_SCALE` / `FOREST_SCALE` (S01); neue Wohnhäuser
- GPS-Getter verschieben

## Locked Mult-Tabelle

`effective = SCHOOL_SCALE (0.50) * MULT`

| Prop | MULT | Effective |
|------|------|-----------|
| `schulhaus_ohringen_a` | **1.35** | 0.675 (historic main ~30 m) |
| `schulhaus_ohringen_b` | **0.83** | 0.415 (1985 wing ~22 m) |
| `turnhalle_ohringen` | **0.75** | 0.375 (~28 m gym; PNG oversized) |
| `kiga_ohringen` | **0.55** | 0.275 (~12 m real; floor Mult 0.55) |

Named consts: `OHRINGEN_A_SCALE_MULT`, `OHRINGEN_B_SCALE_MULT`, `OHRINGEN_TURNHALLE_SCALE_MULT`, `KIGA_OHRINGEN_SCALE_MULT`.

## Art

- nein — Rotation/Scale im Code; Art nur bei falschem Sprite-Facing

## Testplan

- Suite: vier Ohringen-Scales (`SCHOOL_SCALE * MULT`); Position ±80 wu; `rotation == 0`; Birch/Rietacker-Mults unverändert; Seuzach-Kigas weiter `SCHOOL_SCALE`; `house_n == 0`
- Playtest: Campus + Kiga in Ohringen lesbar; Relativgröße vs. Maps/Street View grob stimmig

## Akzeptanzkriterien

- [ ] Vier Props mit locked Mults; `flip_h` false; GPS unverändert
- [ ] Birch/Rietacker/Seuzach-Kigas/Bahnhof/Badi unberührt; globales `SCHOOL_SCALE` 0.50
- [ ] Suite grün; Review + Playtest Pass

Playtest 2026-08-12: Pass (Ohringen campus + kiga teleports; Mults 1.35/0.83/0.75/0.55).
