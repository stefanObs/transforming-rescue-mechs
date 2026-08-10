# Plan: m3-building-occlusion

**Status:** Erledigt  
**Typ:** Bug  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/m3-seuzach-geo-realign.md`](m3-seuzach-geo-realign.md) · [`docs/ENTWICKLUNGSABLAUF.md`](../ENTWICKLUNGSABLAUF.md)

---

## Ziel

Figur zwischen Gebäuden sichtbar halten (korrektes Vor/Hinter); Landmarken nicht unnatürlich übereinander stapeln.

---

## Repro & RCA

### Repro

1. World laden (Forrenberg/Dorfkern/Schulcluster).
2. Figur südlich nahe eines Landmark-Props positionieren (Screen: „vor“ dem Gebäude).
3. Ist: Gebäude deckt Figur oft ab; Cluster (Schulen, Forrenberg Hub+Tank) stapeln sich flächig.

- [x] Repro bestätigt (Geometrie + Code)

### RCA

- Props nutzen festes `offset = (0, -80)` bei `centered` + großen Texturen (~1000px × 0.26–0.34).
- Visuelles Unterkante liegt ~100–180px **südlich** des Sort-Y (`z = BASE + int(pos.y)`).
- Spieler mit `y` knapp unter Prop-Y hat niedrigeres `z_index`, obwohl er visuell vor der Fassade steht → Verdecken.
- Enge Cluster (Abstand ≪ visuelle Höhe) überlagern sich unnatürlich.

**Fix:** Offset so setzen, dass Fußlinie ≈ Prop-Origin (`offset.y ≈ -tex_h/2`); leichte Actor-z-Bias; Cluster-Abstände vergrößern; Collision-Footprint an neue Offset-Logik; Regressionstest.

---

## Scope

### In

- `world_sandbox.gd` `_add_prop` / `_attach_building_collision` / Cluster-Positionen
- Optional leichter Actor-z-Bias
- Tests für Feet-Offset und Sort-Erwartung

### Nicht

- Neue Art; OSM-Neuvermessung

---

## Technische Schritte

1. Feet-Pivot-Offset aus Texture-Höhe
2. Collision nahe local y≈0
3. Schul-/Forrenberg-/Kiga-Cluster auseinanderrücken
4. Tests + Review + Playtest

---

## Testplan

- [x] Prop `offset.y` ≈ `-texture.get_height()/2` (Toleranz)
- [x] Visuelle Unterkante nahe `position.y` (Rechnung)
- [x] Actor südlich von Prop → höheres z_index
- [x] Suite grün

---

## Akzeptanzkriterien

- [x] Figur vor Gebäuden (südlich der Fußlinie) nicht verdeckt
- [x] Cluster ohne starke Flächen-Überlagerung
- [x] Review + Playtest Pass
