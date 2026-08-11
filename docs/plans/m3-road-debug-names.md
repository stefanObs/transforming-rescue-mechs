# Plan: m3-road-debug-names

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/m3-street-continuity.md`](m3-street-continuity.md)  
**Art:** keine neuen Assets

---

## Ziel

Mit **F1** einen Debug-Modus umschalten, der auf den Fahrbahnen die **Strassennamen** zeigt. Die Labels folgen der **Tangentenrichtung** der Polylinie (lesbar, nicht auf dem Kopf).

---

## Scope

### In

- Input-Action `debug_overlay` (F1), Toggle an/aus, Standard aus
- Welt-Overlay: Labels aus Named-Road-Markern (`road_name` + `road_points`)
- Rotation = Tangentenwinkel, geklappt auf ±90° damit Text lesbar bleibt
- Mehrere Labels auf langen Achsen; mindestens eines pro benannter Strasse

### Nicht

- Gamepad-Binding, Minimap, POI-Labels, neue Art
- Persistenz des Debug-Flags

---

## Systeme

World (`world_sandbox`), InputSetup / InputGlyphs, RoadKit (Rotation + Sample-Punkte)

---

## Technische Schritte

1. `debug_overlay` in `input_setup.gd` (KEY_F1); Glyph `F1`.
2. RoadKit: `readable_label_rotation(tangent)`, `label_samples(points, spacing)`.
3. World: Toggle F1 (auch in Pause); Overlay-Node mit Labels auf den Bändern; Hint-Zeile.
4. Tests: Rotation-Kanten, Default aus, F1/API an → Namen + Ausrichtung, Toggle aus.

---

## Testplan

### Automatisiert

- [x] `readable_label_rotation`: Ost ≈ 0, West ≈ 0 (geklappt), Süd ≈ +π/2
- [x] `label_samples`: horizontales Band, Tangent ≈ (1,0)
- [x] World: 0 Debug-Labels default; nach Toggle ≥1 Label je Named Road; Text = Name
- [x] A1-Label |rotation| klein (Ost-West); Winterthurer |rotation| nahe π/2
- [x] Toggle aus räumt Labels
- [x] InputMap `debug_overlay` = F1; Glyph F1

### Playtest / Smoke

- [x] F1 zeigt Namen auf Asphalt, gedreht mit der Strasse
- [x] F1 erneut blendet aus
- [x] Haupt-Scene startet ohne Error

---

## Art-Bedarf

- [x] Keine neuen Assets

---

## Akzeptanzkriterien

- [x] F1 schaltet Debug-Strassennamen
- [x] Namen folgen der Strassenrichtung und sind lesbar
- [x] Automatisierte Tests grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass

---

## Playtest (2026-08-11)

Pass. Art alpha 181 PNGs; suite green inkl. `m3_road_debug_test`. Default 0 Labels; F1 → 51 Namen (A1 rot≈−0.12, Winterthurer ≈−1.50); zweites F1 räumt; F1 auch in Pause; Hint erwähnt F1. Smoke `godot --path . --quit-after 5` exit 0.
