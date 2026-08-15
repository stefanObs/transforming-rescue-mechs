# Plan: schools-kigas-street-side / Slice S03

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-15  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/schools-kigas-street-side/INDEX.md`  
**Slice-Datei:** `docs/plans/schools-kigas-street-side/S03-ohringen-campus-kiga-street-side.md`  
**Hängt ab von:** S01 (erledigt, v0.36.0 — Helper `_add_school_street_prop`); S02 erledigt v0.36.1 (`_named_road_by_name` nearest-same-name; `_assert_school_street_prop` bank west/east/north/south)

Nur der **Feature-Schritt** (zwei verwandte Inkremente in derselben Ohringen-Zelle: Campus-Cluster + Kiga Ohringen). Plan nötig (Bug → Phase-0 RCA + Art + Multi-System: Placement-Helper wiederverwenden, Kiga über denselben Wrapper, Style-C `_ew`/`_ns`). Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Schul-Campus **Ohringen** und **Kiga Ohringen** sitzen **westlich** der Schulstrasse (NS); Fassaden zur Strasse. Die Turnhalle steht nördlich der Schaffhauserstrasse. Sprites street-aligned (`_ew`/`_ns` + S01-Helper), eigene Rasterzellen bleiben.

## In diesem Schritt

- S01-Helper wiederverwenden — vier Props: `schulhaus_ohringen_a` / `_b`, `turnhalle_ohringen`, `kiga_ohringen`
- a/b/kiga: GPS-Bank **west** of Schulstrasse halten; Fassade ost zur Strasse
- Turnhalle: **north** of Schaffhauserstrasse, Fassade süd zur Strasse
- Cluster-Count Campus = 3; Kiga ohne `school_cluster`; Parent `DistrictOhringen`
- Style-C `_ew`/`_ns` nur für diese vier Gebäude; `_ns` nie aus `_ew` rotieren; `rotation == 0`

## Nicht (andere Feature-Schritte)

- Campus Birch (S01), Rietacker (S02), Seuzach-Kigas Bachtobel/Weid/Schneckenwiese (S04)
- Wohnhäuser, Bahnhof/Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz; globales `SCHOOL_SCALE`; `Sprite2D.rotation`

## Ziel

Campus **Ohringen** (Schulhäuser a/b + Turnhalle) sitzt **westlich** der sichtbaren Schulstrasse; Ostfassade von a/b zur Strasse (Schulstrasse 9 / 1985er Flügel). Die Turnhalle (Schulstrasse 7) steht **nördlich** der sichtbaren Schaffhauserstrasse, Südfassade zum Band. **Kiga Ohringen** (Schulstrasse 5) sitzt in derselben Zelle **westlich** der Schulstrasse, südöstlich vom Campus als eigenes Gebäude unter `DistrictOhringen`, **ohne** `school_cluster`. Sprites street-aligned (`_ew`/`_ns` + seitenbewusstes `flip_h` via S01-Helper), nicht mehr Iso-Diamant. Kein zweiter Placement-Helper; Kiga nutzt **denselben** Wrapper.

## Scope

### In

- S01-Helper **wiederverwenden**, nicht forken: `_add_school_street_prop(base_without_suffix, pos, scale, metas, node_name, target_road_name)` in `world_sandbox.gd`. Die drei Ohringen-Campus-`_add_building_prop`-Calls **und** den `kiga_ohringen`-Call (heute in `_place_kindergartens`) ersetzen. Housing-Call-Sites und `_nudge_off_named_roads(prefer_away)` unverändert. Signatur nicht spalten — Kiga ist derselbe Wrapper.
- Ziel-Strassen:
  - **a + b + kiga → `Schulstrasse`** (Westbank: `spr.x < closest.x`; Fassade Ost zur Strasse). Schulstrasse ist NS-lokal (`half_w` = `ROAD_HW_LOCAL` 36) → erwartetes Suffix `_ns`.
  - **gym → `Schaffhauserstrasse`** (Nordbank: `spr.y < closest.y`; Fassade Süd zur Strasse). Schaffhauserstrasse ist main EW (`half_w` = `ROAD_HW_MAIN` 72) → erwartetes Suffix `_ew`. Nicht Schulstrasse als Target (gym d≈827 west of Schulstrasse, knapp über dem 800-wu-Setback-Band).
- Kiga **nicht** auf `Rundstrasse` umbiegen (GPS süd der Rundstrasse d≈582) — Target bleibt Schulstrasse West. Parent bleibt `DistrictOhringen` (`_prop_parent = district` vor dem Call). Metas **ohne** `school_cluster`; `kindergarten_id` / `landmark_id` / `district` behalten.
- GPS-Getter in `seuzach_geo.gd` **unverändert**. Kleines Curb-Setback zur Ziel-Ribbon OK (Helper schiebt nur wenn `d_feet < need`). Cluster halten: a nördlich b (≥150 wu); gym südlich a/b; b östlich gym (>200 wu); kiga östlich von b/gym und südlich von a/b. Offset-Asserts vs yard **behalten**; 720-wu-GPS-Drift äußere Schranke, Side/Bearing zusätzlich.
- Per-Building Scales **locked:** `OHRINGEN_A_SCALE_MULT` 1.35, `B` 0.83, `TURNHALLE` 0.75, `KIGA_OHRINGEN` 0.55 auf `SCHOOL_SCALE` 0.50 → **0.675 / 0.415 / 0.375 / 0.275**. Globales `SCHOOL_SCALE` nicht ändern.
- RoadKit: Default **nicht** verlängern. Schulstrasse (class=local, 10-pt) und Schaffhauserstrasse (class=main, 17-pt Campus-Ribbon) **reichen bereits** (a d≈367 west, b d≈393 west, kiga d≈359 west, gym d≈532 nord). Nur extendieren, wenn nach Helper-Wiring ein Prop noch **>~800 wu** vom Target oder auf Asphalt sitzt. Bestehende Vertices behalten. **Kein** Schulstrasse-Durchstich durch den Hof; Campus nicht auf die Ostseite klappen; gym nicht auf die Südseite der Schaffhauserstrasse.
- `_named_road_by_name` nearest-same-name **nicht umbauen** (S02, mehrere `Schaffhauserstrasse`-Polylines). Kein zweiter Schul-Wrapper.
- Style-C `_ew`/`_ns` **nur für diese vier Gebäude** via `comic-rettung-art`; `_ns` nie aus `_ew` rotieren (`ROTATE_90`/`270` verboten); Fassade EW unten / NS links vertikal; `rotation == 0`. Unprefixed `landmark_schulhaus_ohringen_{a,b}.png` / `landmark_turnhalle_ohringen.png` / `landmark_kiga_ohringen.png` dürfen als Legacy auf Disk bleiben; Placement muss `_ew`/`_ns` laden.
- Tests in `tests/m3_world_landmarks_test.gd`: REQUIRED_ART acht Ohringen-Paare; Westbank Schulstrasse für a/b/kiga; gym Nord von Schaffhauser; campus `school_cluster` = 3; kiga **kein** `school_cluster`; `street_bearing` / `faces_street` / `flip_h`; `rotation == 0`; Birch/Rietacker bleiben prefixed; Seuzach-Kigas Bachtobel/Weid/Schneckenwiese weiter unprefixed, **keine** neuen Facing-Metas Pflicht.
- Test-Helper: `_assert_school_street_prop` kennt bereits `bank` `"west"|"east"|"north"|"south"` — **nicht** neu erfinden. `_assert_ohringen_campus` braucht `world` (wie Birch/Rietacker). `_assert_texture_unprefixed` von den vier Ohringen-Sprites **entfernen**. Unprefixed-Verbot im Street-Helper um Ohringen-Basen erweitern.

### Nicht

- Campus Birch (S01) / Rietacker (S02) umbauen — Asserts müssen grün bleiben; Helper-Signatur nicht in einen zweiten Wrapper spalten
- Seuzach-Kigas Bachtobel/Weid/Schneckenwiese (S04)
- Wohnhäuser / Housing-Art (`house_street_*`), Bahnhof, Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz neu zeichnen; globales `SCHOOL_SCALE`; `Sprite2D.rotation` als Facing
- GPS auf die **Ostseite** der Schulstrasse oder die **Südseite** der Schaffhauserstrasse klappen
- Kiga in den Campus-Cluster ziehen (`school_cluster`) oder aus `DistrictOhringen` herauslösen
- Kiga-Target auf `Rundstrasse` umbiegen
- `HOUSE_CLEAR_*` / Housing-Nudge-Reihenfolge / Housing-Call-Sites ändern
- S01/S02/S04-Gebäude-Art oder -Placement

## Systeme

| System | Rolle in diesem Slice |
|--------|------------------------|
| `scripts/world_sandbox.gd` — `_add_school_street_prop` (S01, nicht forken) | Vier Calls: Ziel-Strasse, Bearing-Datei, GPS-Bank, Flip, Metas; Kiga gleicher Wrapper |
| `scripts/world_sandbox.gd` — `_named_road_by_name` (S02 nearest-same-name) | Schaffhauserstrasse: campus-nahe 17-pt-Ribbon, nicht ein Fernfragment |
| `scripts/world_sandbox.gd` — `_place_school_clusters` / `_place_kindergartens` | Unprefixed `_add_building_prop` für a/b/gym + kiga ersetzen; `_prop_parent` DistrictOhringen für alle vier; Birch/Rietacker/Seuzach-Kigas unangetastet |
| `scripts/seuzach_geo.gd` | GPS-Getter **unverändert** (`ohringen_schulhaus_{a,b}_world`, `ohringen_turnhalle_world`, `kiga_ohringen_world`) |
| `data/seuzach_roads.json` — `Schulstrasse` (class=local, `half_w=36`, 10 pts) | Default unverändert; NS-Ribbon östlich von a/b/kiga |
| `data/seuzach_roads.json` — `Schaffhauserstrasse` (class=main, `half_w=72`, mehrere Polylines) | Default unverändert; EW-Hauptpolyline südlich der Turnhalle |
| `data/seuzach_roads.json` — `Rundstrasse` | Nicht Target; Kiga bleibt südlich, west of Schulstrasse |
| `assets/art/landmark_schulhaus_ohringen_{a,b}_{ew,ns}.png`, `landmark_turnhalle_ohringen_{ew,ns}.png`, `landmark_kiga_ohringen_{ew,ns}.png` | Style-C street-aligned; Iso-Diamant-Legacy bleibt ungenutzt |
| `comic-rettung-art` + `process_art_alpha.py` / `verify_art_alpha.py` + `godot --import` | Phase-2 Art nur dieser Zelle (Campus 3 + Kiga) |
| `tests/m3_world_landmarks_test.gd` | REQUIRED_ART-Paare, West/Nord-Bank, Bearing/Flip, Cluster=3, kiga ohne cluster; Birch/Rietacker prefixed; Seuzach-Kigas unprefixed |

## Repro & RCA (Pflicht bei Typ = Bugfix)

Vor Phase 2 ausfüllen. **Repro bestätigt** (Code + RoadKit-JSON + GPS, 2026-08-15). S01 (Birch) und S02 (Rietacker) sind erledigt und **nicht** die Ursache dieses Slices.

### Reproduktion

- [x] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. `world_sandbox` laden. 2. Zu Campus Ohringen teleportieren / `SeuzachGeo.ohringen_world()` bzw. `ohringen_schulhaus_a_world()` (~-19532, 10824). 3. Schulstrasse-Ribbon, Schaffhauserstrasse-Ribbon, Rundstrasse und die vier Sprites (a/b/gym/kiga) vergleichen (Birch/Rietacker/`house_street_*_{ew,ns}` als Facing-Referenz). |
| Erwartet | a, b und Kiga **westlich** der sichtbaren Schulstrasse; Ostfassade zur Strasse. Turnhalle **nördlich** der Schaffhauserstrasse, Südfassade zum Band. Kiga südöstlich vom Campus als eigenes Gebäude, kein viertes Cluster-Mitglied. Sprites street-aligned (`_ew`/`_ns`), Tür zur Curb, Hof zwischen den Trakten — nicht iso-verdreht neben den Häusern. |
| Tatsächlich | Placement lädt unprefixed Iso-Diamant (`landmark_schulhaus_ohringen_a.png` etc.), `flip_h=false`, kein `street_bearing`/`faces_street`. S01-Helper ist **nicht** verdrahtet (weiter `_add_building_prop`). Füße GPS-clear, aber Art steht schief zur Ribbon; User: Schulen „not placed properly“ / „wrong side“. |
| Umgebung | Godot 4, Scene `world_sandbox`, Branch aktuell nach S02 v0.36.1; Input n/a (Placement deterministisch). |
| Evidenz | GPS (`SeuzachGeo`, +X Ost +Y Süd): **a** (-19532, 10824) Schulstrasse d≈367 **west** ns. **b** (-19313, 11344) Schulstrasse d≈393 west. **gym** (-19657, 11629) Schaffhauserstrasse d≈532 **north** ew; auch west of Schulstrasse d≈827. **kiga** (-19060, 11796) Schulstrasse d≈359 west; Rundstrasse d≈582 south. RoadKit **reicht** (anders als Birch). Code: `_place_school_clusters` Ohringen = `_add_building_prop` unprefixed; `_place_kindergartens` `kiga_ohringen` = `_add_building_prop` unprefixed unter `DistrictOhringen`. Tests: `_assert_ohringen_campus` / `_assert_kiga_ohringen` rufen `_assert_texture_unprefixed` + `flip_h false`, **keine** Street-Metas. Cluster-Count = 3; kiga `not has_meta("school_cluster")`. |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) `_nudge_off_named_roads` schiebt Ohringen über die Fahrbahn / auf die Ostseite der Schulstrasse. (2) Iso-Diamant-Art ohne `_ew`/`_ns` liest schief neben street-aligned Häusern, Birch und Rietacker. (3) RoadKit-Polylines enden vor dem Campus (Birch-Muster). (4) `flip_h` fehlt / Tür zeigt von der Curb weg. (5) GPS-Konstanten in `seuzach_geo.gd` falsch. (6) S01-Helper nicht verdrahtet. (7) `_named_road_by_name` first-match trifft ein Schaffhauser-Fernfragment. (8) Kiga sitzt im Campus-Cluster / falscher Parent. |
| Bestätigte Ursache | **(6) + (2) + (4).** Ohringen-Campus und Kiga nutzen noch `_add_building_prop` (unprefixed, `flip_h` default false, kein `street_bearing`). Iso-Diamant neben street-aligned Birch/Rietacker/Häusern wirkt „falsche Seite“. Helper existiert seit S01, nearest-same-name und Bank-Asserts seit S02 — Call-Sites fehlen. |
| Nicht die Ursache | **(1) Nudge als Hauptbug:** GPS-Füße clearen heute Asphalt (`_nudge_off_named_roads` gibt `pos` unverändert zurück). **(3) Ribbon-Lücke analog Birch:** Schulstrasse/Schaffhauserstrasse **erreichen** a/b/kiga/gym (d≈367 / 393 / 359 / 532, alle < 800). **(5)** GPS matcht OSM (Tests asserten LAT/LON + Offsets vs `ohringen_world()` / kiga-Centroid). **(7)** seit S02 nearest-same-name; gym d≈532 zur campus-nahen Schaffhauser-Hauptpolyline. **(8)** Kiga ist bereits unter `DistrictOhringen` ohne `school_cluster`; Campus-Count = 3. |
| Fix-Richtung | Vier Calls auf `_add_school_street_prop` umstellen (Kiga gleicher Wrapper). Art `_ew`/`_ns` nur diese Zelle. a/b/kiga → Schulstrasse West; gym → Schaffhauserstrasse Nord. RoadKit default unverändert. GPS-Getter und Scales locked. Tests: West/Nord-Bank, Cluster=3, kiga ohne cluster; Birch/Rietacker prefixed; Seuzach-Kigas unprefixed. |
| Risiken | Schaffhauser `half_w=72` → `need` größer als Schulstrasse-local 36; gym d≈532 sollte reichen — Helper schiebt **nord** (away), nicht über die Fahrbahn. Gym **nicht** auf Schulstrasse targeten (d≈827 ≥ 800-Band). Kiga-AABB vs Rundstrasse: Nudge erste Richtung = GPS-away von Schulstrasse (west), nicht süd durch Rundstrasse oder ost über Schulstrasse. Ohne die acht PNGs gibt der Helper `null` zurück (Campus/Kiga verschwinden). Iso-Legacy darf auf Disk bleiben, darf nicht mehr geladen werden. S04 darf durch den Helper nicht plötzlich `_ew`/`_ns` verlangen. Birch/Rietacker-Asserts nicht umbiegen. |

- [x] RCA dokumentiert und reviewed (kurz vom Hauptagenten ok)

## Technische Schritte

### 1. Placement — S01-Helper verdrahten (kein Fork)

In `_place_school_clusters` die drei Ohringen-`_add_building_prop`-Blöcke ersetzen durch `_add_school_street_prop`. In `_place_kindergartens` denselben Wrapper für `kiga_ohringen` (nicht `_add_building_prop`). Signatur unverändert:

```
_add_school_street_prop(base_without_suffix, pos, scale, metas, node_name, target_road_name)
```

`_prop_parent` bleibt `DistrictOhringen` für alle vier (Campus-Block setzt den Node; Kiga holt ihn via `get_node_or_null("DistrictOhringen")`).

| Node | `base_without_suffix` | GPS | Scale | `target_road_name` |
|------|------------------------|-----|-------|--------------------|
| `schulhaus_ohringen_a` | `landmark_schulhaus_ohringen_a` | `ohringen_schulhaus_a_world()` | `SCHOOL_SCALE * 1.35` | `Schulstrasse` |
| `schulhaus_ohringen_b` | `landmark_schulhaus_ohringen_b` | `ohringen_schulhaus_b_world()` | `SCHOOL_SCALE * 0.83` | `Schulstrasse` |
| `turnhalle_ohringen` | `landmark_turnhalle_ohringen` | `ohringen_turnhalle_world()` | `SCHOOL_SCALE * 0.75` | `Schaffhauserstrasse` |
| `kiga_ohringen` | `landmark_kiga_ohringen` | `kiga_ohringen_world()` | `SCHOOL_SCALE * 0.55` | `Schulstrasse` |

Metas **behalten:** Campus `landmark_id` / `school_cluster` / `district` / `poi_type=gym` an der Halle. Kiga: `landmark_id` / `kindergarten_id` / `district` — **kein** `school_cluster`. Helper setzt zusätzlich `street_side`, `street_bearing`, `faces_street`, `street_name`.

Kommentar in `_place_school_clusters` aktualisieren: Ohringen street-aligned wie Birch/Rietacker; Seuzach-Kigas bleiben unprefixed (S04). Kommentar in `_place_kindergartens`: nur `kiga_ohringen` street-aligned; Bachtobel/Weid/Schneckenwiese unprefixed.

`seuzach_geo.gd` Getter und LAT/LON nicht ändern. `OHRINGEN_*_SCALE_MULT` / `KIGA_OHRINGEN_SCALE_MULT` nicht ändern.

Helper-Ablauf (bereits S01, hier nur Call-Sites):

1. Tangent am nächsten Segment der **Ziel**-Polyline via `_named_road_by_name` (nearest-same-name, nicht nearest-any-named-road).
2. Datei `…_{ew\|ns}.png` aus `|tx| >= |ty|` → `ew`.
3. GPS-Seite halten: `away = pos - closest`; Setback entlang `away` nur wenn `d_feet < need` (`need ≈ half_w + street_facing_half(BUILDING_CLEAR-Größe, bearing) + BUILDING_CLEAR_EDGE_MARGIN + HOUSE_CURB_SLACK`).
4. Nudge erste Richtung = GPS-`away` (West von Schulstrasse / Nord von Schaffhauserstrasse), nicht `+perp` durch die Fahrbahn.
5. `flip_h` Tür zur Curb; `Sprite2D.rotation == 0`.

### 2. RoadKit — Default nicht anfassen

**Nicht** extendieren, solange nach Schritt 1 gilt:

- a/b/kiga → Schulstrasse d < ~800 und Westbank, nicht auf Asphalt
- gym → Schaffhauserstrasse d < ~800 und Nordbank, nicht auf Asphalt

Heute: a d≈367, b d≈393, kiga d≈359 west Schulstrasse (OK). gym d≈532 nord Schaffhauser (OK). Der Helper **zieht Gebäude nicht zur Ribbon**.

**Verboten:** Schulstrasse nach Westen durch den Hof ziehen; Campus auf die Ostseite klappen; gym auf die Südseite der Schaffhauserstrasse klappen; Kiga auf Rundstrasse retargeten. Bestehende Vertices nicht löschen.

Schulstrasse/Schaffhauserstrasse nur anfassen, wenn nach Wiring + Art-AABB ein Prop auf Asphalt sitzt oder >~800 vom Target — dann Vertices **anhängen**, Campus-Bank halten.

### 3. Tests (`tests/m3_world_landmarks_test.gd`)

Regression bildet die Repro ab (zuerst rot: unprefixed + keine Street-Metas; nach Fix grün):

- **REQUIRED_ART:** acht Ohringen-Paare Pflicht:
  - `landmark_schulhaus_ohringen_a_{ew,ns}.png`
  - `landmark_schulhaus_ohringen_b_{ew,ns}.png`
  - `landmark_turnhalle_ohringen_{ew,ns}.png`
  - `landmark_kiga_ohringen_{ew,ns}.png`  
  Unprefixed `landmark_schulhaus_ohringen_{a,b}.png`, GEO/REQUIRED `landmark_turnhalle_ohringen.png` / `landmark_kiga_ohringen.png` dürfen als Legacy-Exists bleiben. Placement darf unprefixed **nicht** mehr laden.
- **`_assert_ohringen_campus(world, sprites)`:** `world` durchreichen (Call-Site heute nur `all_sprites`). `_assert_texture_unprefixed` für a/b/gym **entfernen**. `flip_h false` **entfernen** (Helper darf zur Curb flippen). GPS-Konstanten, yard-Offsets `(308.0, -607.8)` / `(527.7, -88.0)` / `(183.4, 196.8)`, Cluster=3, Metas, Scales 0.675 / 0.415 / 0.375, Relativlage a nördlich b / gym süd / b ost der Halle, 720 wu GPS, 1400 wu yard, SW-Zellen `x < -15000` `y > 8000`, `rotation == 0` **behalten**.
- **`_assert_kiga_ohringen`:** `_assert_texture_unprefixed` und `flip_h false` **entfernen**. `not has_meta("school_cluster")`, Parent `DistrictOhringen`, Scale 0.275, Relativlage SE vom Campus, 720 wu GPS **behalten**. Street-Assert Westbank Schulstrasse.
- **Street-Asserts** (bestehender Helper, `bank` schon west/east/north/south):
  - a, b, kiga: Target `Schulstrasse`, **Westbank** (`bank="west"` bzw. `west_of_road=true`), Suffix matcht Tangent (Schulstrasse am Campus ≈ NS → `_ns`)
  - gym: Target `Schaffhauserstrasse`, **Nordbank** (`bank="north"`), Schaffhauser EW → `_ew`
- **`_assert_school_street_prop`:** Unprefixed-Verbot um Ohringen-Basen erweitern (`landmark_schulhaus_ohringen_{a,b}.png`, `landmark_turnhalle_ohringen.png`, `landmark_kiga_ohringen.png`). Birch/Rietacker-Calls unverändert. `d < 800` und `d >= need-12` gelten für die **Ziel**-Polyline.
- Optional: `_assert_ns_house_art_not_rotate_of_ew` um die vier Ohringen-Basen ergänzen (`landmark_schulhaus_ohringen_{a,b}`, `landmark_turnhalle_ohringen`, `landmark_kiga_ohringen`).
- **Birch S01 / Rietacker S02** bleiben grün (prefixed + Bank-Asserts).
- **Seuzach-Kigas** Bachtobel/Weid/Schneckenwiese: weiter unprefixed, keine neuen `street_*` Metas Pflicht, `flip_h false` dort unverändert.

### 4. Art (Phase 2 — nur dieser Slice)

Siehe Art-Bedarf. Implementer beauftragt `comic-rettung-art`; danach Alpha-Pipeline + Godot-Import **bevor** Tests `ResourceLoader.exists` erwarten. Ohne die acht PNGs gibt der Helper `null` zurück (Campus/Kiga verschwinden).

## Testplan

### Automatisiert

- [ ] `tests/m3_world_landmarks_test.gd`: acht Ohringen `_ew`/`_ns` existieren; Placement lädt Prefixed (nicht unprefixed)
- [ ] ohringen_a / `_b` / `kiga_ohringen` westlich nächster Schulstrasse-x; Distanz im Setback-Band
- [ ] `turnhalle_ohringen` nördlich nächster Schaffhauserstrasse-y; Distanz im Setback-Band
- [ ] Ohringen `street_bearing` matcht Ziel-Tangent; Dateisuffix matcht; `faces_street`; `street_side` ±1; `flip_h` zur Curb; `rotation == 0`
- [ ] Cluster-Geometrie: `school_cluster` ohringen == 3; a nördlich b; gym süd; b ost der Halle; GPS-Getter unverändert; Scales 0.675 / 0.415 / 0.375 / 0.275
- [ ] `kiga_ohringen` kein `school_cluster`; Parent `DistrictOhringen`; SE vom Campus
- [ ] Visual clear / off-road grün (`BUILDING_CLEAR` Paint + bearing street-half); Schaffhauser `half_w=72` berücksichtigen
- [ ] Birch/Rietacker-Asserts grün (prefixed)
- [ ] Seuzach-Kigas Bachtobel/Weid/Schneckenwiese: unprefixed Art, keine neuen Facing-Metas Pflicht
- [ ] Optional: NS-Ohringen-Art nicht `ROTATE_90/270` von EW
- [ ] Bei Bugfix: Regressionstest bildet die Repro ab (zuerst rot, nach Fix grün)

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Teleport Campus Ohringen: a/b **westlich** der **sichtbaren** Schulstrasse; Ostfassade zum Band (Schulstrasse 9 / 1985er Flügel); kein Gebäude östlich der Schulstrasse
- [ ] Turnhalle **nördlich** der **sichtbaren** Schaffhauserstrasse, Südfassade zum Band (nicht iso-Ecke); lange Halle parallel
- [ ] Kiga südöstlich vom Campus als eigenes Gebäude (Schulstrasse 5, Spielplatz), westlich Schulstrasse; Hof-Lücke zum Campus bleibt; kein viertes Cluster-Gebäude
- [ ] Hof zwischen den drei Campus-Trakten; kein Asphalt unter Schul-/Kiga-Paint
- [ ] NS-Trakte aufrecht (Dach oben, Fassade links bzw. nach Flip rechts) — nicht aus EW rotiert; kein lesbarer Text in den Sprites
- [ ] Birch westlich Bachwiesenstrasse; Rietacker nördlich Ohringer; Seuzach-Kigas alte PNGs/Lage — nur visuell spotten, nicht umbauen
- [ ] Bei Bugfix: manuelle Repro-Schritte schlagen nach Fix nicht mehr fehl

## Art-Bedarf

- [ ] Keine neuen Assets
- [x] Neue Grafiken/Animationen → Subagent `comic-rettung-art`

Details (nur Campus **Ohringen** + **Kiga Ohringen**, Style **C — Comic-Rettung**):

| Datei | Rolle |
|-------|--------|
| `assets/art/landmark_schulhaus_ohringen_a_ew.png` | Historisches Schulhaus 9, EW |
| `assets/art/landmark_schulhaus_ohringen_a_ns.png` | dasselbe, NS |
| `assets/art/landmark_schulhaus_ohringen_b_ew.png` | Schultrakt 1985, EW |
| `assets/art/landmark_schulhaus_ohringen_b_ns.png` | dasselbe, NS |
| `assets/art/landmark_turnhalle_ohringen_ew.png` | Turnhalle Schulstrasse 7, EW |
| `assets/art/landmark_turnhalle_ohringen_ns.png` | dasselbe, NS |
| `assets/art/landmark_kiga_ohringen_ew.png` | Kindergarten Schulstrasse 5 + Spielplatz, EW |
| `assets/art/landmark_kiga_ohringen_ns.png` | dasselbe, NS |

- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` (**nur** Haus–Strasse-Layout, keine Maße/Kamera) **plus** Street View / Maps **Schulstrasse 9 / 7 / 5**, Oberohringen. Unprefixed `landmark_schulhaus_ohringen_{a,b}.png` / `landmark_turnhalle_ohringen.png` / `landmark_kiga_ohringen.png` als Farb-/Masse-Refs, nicht als Iso-Diamant-Vorlage für Facing. Proportionen aus C-Refs und bestehenden Style-C-Schul-Sprites, nicht aus der Iso-Karte.
- Silhouette (Art, **nicht** Dateisuffix): **a** historisches Schulhaus 9 (Giebel, älteres benanntes Haus); **b** Schultrakt **1985** (Flachdach, Hellputz, Bandfenster — nicht Giebel-Häuschen); **gym** Turnhalle Schulstrasse 7 (niedrige Flachdach-Halle); **kiga** Schulstrasse 5 mit **Spielplatz**, kleiner als die Schulhäuser. Dateisuffix kommt von der **Strassen-Tangent**, nicht von der OSM-Gebäudeachse (a/b/kiga an NS-Schulstrasse → oft `_ns`; gym an EW-Schaffhauser → oft `_ew`).
- **EW:** lange Fassade + Tür am Canvas-**BOTTOM**. **NS:** aufrecht, Dach **TOP**, lange Fassade + Tür an der **linken** vertikalen Kante. **Niemals** `_ns` aus `_ew` per `ROTATE_90`/`270`.
- Kein Asphalt in die PNG; Fußkante frei. Cel + dicke `#1A1A1A`-Kontur; kein 3D-Plastik. **Kein lesbarer Text** (kein „Schulhaus“, keine Hausnummer).
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün) → `godot --headless --path . --import`.
- Unprefixed Legacy-PNGs nicht löschen müssen; nicht mehr im Ohringen-Placement verwenden.
- **Nicht** in diesem Slice: Birch, Rietacker, Seuzach-Kigas Bachtobel/Weid/Schneckenwiese, Häuser.

## Akzeptanzkriterien

- [ ] Repro + RCA erledigt (Ohringen westlich sichtbarer Schulstrasse / Turnhalle nord von Schaffhauser / Kiga west Schulstrasse; Ursache = Helper nicht verdrahtet + Iso-Art + kein Flip)
- [ ] Vier Props über `_add_school_street_prop` (kein zweiter Helper; Kiga gleicher Wrapper); Ziel a/b/kiga→Schulstrasse West, gym→Schaffhauser Nord
- [ ] RoadKit default unverändert; Extend nur bei Need; kein Hof-Durchstich; keine Ost-/Südseite-Klappung; Kiga nicht auf Rundstrasse
- [ ] Acht Style-C `_ew`/`_ns` Ohringen-Assets; Placement nutzt sie; `rotation == 0`; Mults 1.35 / 0.83 / 0.75 / 0.55
- [ ] Cluster-Count = 3; Kiga ohne `school_cluster` unter `DistrictOhringen`; GPS-Getter gehalten; Scales 0.675 / 0.415 / 0.375 / 0.275
- [ ] Tests grün inkl. West/Nord-Bank / Bearing / Flip / REQUIRED_ART-Paare; Birch/Rietacker prefixed; Seuzach-Kigas ohne neue Facing-Pflicht
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass
