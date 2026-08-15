# Plan: schools-kigas-street-side / Slice S04

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-15  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/schools-kigas-street-side/INDEX.md`  
**Slice-Datei:** `docs/plans/schools-kigas-street-side/S04-kigas-bachtobel-weid-schneckenwiese.md`  
**Hängt ab von:** S01 (erledigt, v0.36.0 — Helper `_add_school_street_prop`); S02 erledigt v0.36.1 (`_named_road_by_name` nearest-same-name; `_assert_school_street_prop` bank west/east/north/south); S03 erledigt v0.36.2 (`kiga_ohringen` bereits street-aligned)

Nur der **Feature-Schritt** (drei gleiche Landmark-Typen, ein Placement-System). Plan nötig (Bug → Phase-0 RCA + Art + Multi-System: S01-Helper wiederverwenden, drei Seuzach-Kigas, Style-C `_ew`/`_ns`, Schneckenwiese-Stub nur bei Need). Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Die drei Seuzach-Kindergärten sitzen an der richtigen Strassenseite mit street-aligned Fassade: Bachtobel **östlich** der Bachtobelstrasse (NS), Weid **südlich** der Weidstrasse (EW), Schneckenwiese **westlich** der Schneckenwiesenstrasse / nördlich der Reutlingerstrasse.

## In diesem Schritt

- S01-Helper wiederverwenden für `kiga_bachtobel`, `kiga_weid`, `kiga_schneckenwiese`
- GPS-Bank je Strasse halten (nicht über den Asphalt auf die Gegenbank)
- Schneckenwiese: an sichtbarer Strasse ausrichten (2-Punkt-Stub `Schneckenwiesenstrasse` und/oder Reutlingerstrasse-Nordbank) — Stub nur verlängern wenn der Kiga sonst nicht neben Asphalt sitzt
- Style-C `_ew`/`_ns` nur für diese drei Kigas; `_ns` nie aus `_ew` rotieren; `rotation == 0`

## Nicht (andere Feature-Schritte)

- Schul-Campi Birch/Rietacker/Ohringen; Kiga Ohringen (S03)
- Wohnhäuser, Bahnhof/Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz; globales `SCHOOL_SCALE`; `Sprite2D.rotation`

## Ziel

Die drei Seuzach-Kindergärten sitzen an der sichtbaren RoadKit-Strasse, GPS-Bank gehalten, Fassade zur Curb: **Bachtobel** östlich der Bachtobelstrasse (NS), **Weid** südlich der Weidstrasse (EW), **Schneckenwiese** westlich der Schneckenwiesenstrasse — Fallback nur wenn nach Wiring das Setback-Band / die sichtbare Asphaltkante nicht hält: nördlich der Reutlingerstrasse. Sprites street-aligned (`_ew`/`_ns` + seitenbewusstes `flip_h` via S01-Helper), nicht mehr Iso-Diamant. Kein zweiter Placement-Helper; die drei Calls nutzen **denselben** Wrapper wie Birch/Rietacker/Ohringen. Campi und `kiga_ohringen` bleiben unverändert.

## Scope

### In

- S01-Helper **wiederverwenden**, nicht forken: `_add_school_street_prop(base_without_suffix, pos, scale, metas, node_name, target_road_name)` in `world_sandbox.gd`. Die drei unprefixed `_add_building_prop`-Calls in `_place_kindergartens` ersetzen. `kiga_ohringen` (bereits `_add_school_street_prop` → `Schulstrasse`) **nicht anfassen**. Housing-Call-Sites und `_nudge_off_named_roads(prefer_away)` unverändert. Signatur nicht spalten.
- Ziel-Strassen / GPS-Banken (`SeuzachGeo`, +X Ost +Y Süd):
  - **`kiga_bachtobel` → `Bachtobelstrasse`** (Ostbank: `spr.x > closest.x`; Fassade West zur Strasse). Bachtobelstrasse ist lokal (`half_w` = `ROAD_HW_LOCAL` 36), am Kiga **NS** → erwartetes Suffix `_ns`. GPS (16973.4, -8656.3), d≈576.
  - **`kiga_weid` → `Weidstrasse`** (Südbank: `spr.y > closest.y`; Fassade Nord zur Strasse). Weidstrasse lokal EW → erwartetes Suffix `_ew`. GPS (16723.8, 929.0), d≈544.
  - **`kiga_schneckenwiese` → bevorzugt `Schneckenwiesenstrasse`** (Westbank: `spr.x < closest.x`; Fassade Ost zur Strasse). Stub lokal, am nächsten Punkt **NS** → `_ns`. GPS (6994.6, -2628.6), d≈558. **Fallback** nur wenn nach Wiring der Prop **nicht** im Setback-Band (`d < 800` und `d >= need-12`) **oder** nicht neben sichtbarem Asphalt sitzt: `Reutlingerstrasse` Nordbank (`spr.y < closest.y`; heute d≈1142, collector). Nicht beide Targets gleichzeitig.
- Parent bleibt `%Props` (nicht `DistrictOhringen`). Metas **ohne** `school_cluster`; `kindergarten_id` / `landmark_id` / `district` behalten.
- GPS-Getter in `seuzach_geo.gd` **unverändert**. Kleines Curb-Setback zur Ziel-Ribbon OK (Helper schiebt nur wenn `d_feet < need`). Relativlage vs Birch / einander / Ohringen **behalten**. Offset-Asserts 720-wu-GPS-Drift äußere Schranke; Side/Bearing zusätzlich.
- Per-Building Scales **locked:** `KIGA_BACHTOBEL_SCALE_MULT` 0.57, `KIGA_WEID_SCALE_MULT` 0.55, `KIGA_SCHNECKENWIESE_SCALE_MULT` 1.03 auf `SCHOOL_SCALE` 0.50 → **0.285 / 0.275 / 0.515**. Globales `SCHOOL_SCALE` nicht ändern.
- RoadKit: Bachtobelstrasse und Weidstrasse **reichen** (d≈576 / 544, beide < 800). **Schneckenwiesenstrasse** ist ein 2-Punkt-Stub `(7543.4, -3738.7) → (7450.4, -2950.4)` (class=local, `half_w=36`). Closest zum Kiga = Süd-Endpunkt; Kiga liegt westlich (und etwas südlich) davon. Default **nicht** verlängern, solange nach Helper-Wiring der Prop im Setback-Band **und** neben sichtbarem Asphalt sitzt. Nur dann Vertices **anhängen** (bestehende 2 Punkte behalten, nicht ersetzen), sodass das NS-Band **östlich** des Kigas vorbeiläuft. Reutlingerstrasse default nicht anfassen (d≈1142 liegt ausserhalb des 800-wu-Bands — nicht nord durch das Grundstück stanzen).
- `_named_road_by_name` nearest-same-name **nicht umbauen**. Kein zweiter Schul-Wrapper.
- Style-C `_ew`/`_ns` **nur für diese drei Kigas** via `comic-rettung-art`; `_ns` nie aus `_ew` rotieren (`ROTATE_90`/`270` verboten); Fassade EW unten / NS links vertikal; Spielplatz/Eingang zur Curb (EW Canvas-BOTTOM / NS linke vertikale Kante); `rotation == 0`. Unprefixed `landmark_kiga_{bachtobel,weid,schneckenwiese}.png` dürfen als Legacy auf Disk bleiben; Placement muss `_ew`/`_ns` laden.
- Tests in `tests/m3_world_landmarks_test.gd`: REQUIRED_ART sechs Seuzach-Kiga-Paare; Ostbank Bachtobelstrasse; Südbank Weidstrasse; Schneckenwiese Westbank Schneckenwiesenstrasse **oder** Nordbank Reutlingerstrasse; `street_bearing` / `faces_street` / `flip_h`; `rotation == 0`; Campi + `kiga_ohringen` bleiben prefixed (S01–S03); Unprefixed-Verbot im Street-Helper um die drei Kiga-Basen erweitern.

### Nicht

- Schul-Campi Birch (S01) / Rietacker (S02) / Ohringen (S03) umbauen — Asserts müssen grün bleiben; Helper-Signatur nicht in einen zweiten Wrapper spalten
- **Kiga Ohringen** (S03) — bleibt `_add_school_street_prop` → Schulstrasse West unter `DistrictOhringen`
- Wohnhäuser / Housing-Art (`house_street_*`), Bahnhof, Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz neu zeichnen; globales `SCHOOL_SCALE`; `Sprite2D.rotation` als Facing
- GPS auf die **Westseite** der Bachtobelstrasse, die **Nordseite** der Weidstrasse oder die **Ostseite** der Schneckenwiesenstrasse / **Südseite** der Reutlingerstrasse klappen
- Die drei Kigas in einen `school_cluster` ziehen oder unter `DistrictOhringen` hängen
- Schneckenwiesenstrasse-Stub **ersetzen** (bestehende 2 Vertices löschen) oder Reutlingerstrasse nach Norden durch das Grundstück ziehen, nur um d unter 800 zu drücken, wenn der Stub-Extend reicht
- `HOUSE_CLEAR_*` / Housing-Nudge-Reihenfolge / Housing-Call-Sites ändern
- S01/S02/S03-Gebäude-Art oder -Placement

## Systeme

| System | Rolle in diesem Slice |
|--------|------------------------|
| `scripts/world_sandbox.gd` — `_add_school_street_prop` (S01, nicht forken) | Drei Calls: Ziel-Strasse, Bearing-Datei, GPS-Bank, Flip, Metas |
| `scripts/world_sandbox.gd` — `_named_road_by_name` (S02 nearest-same-name) | Ziel-Polyline, nicht nearest-any-named (Bachtobel: nicht Herbstackerstrasse) |
| `scripts/world_sandbox.gd` — `_place_kindergartens` | Unprefixed `_add_building_prop` für Bachtobel/Weid/Schneckenwiese ersetzen; `kiga_ohringen` und `_place_school_clusters` unangetastet |
| `scripts/seuzach_geo.gd` | GPS-Getter **unverändert** (`kiga_{bachtobel,weid,schneckenwiese}_world`) |
| `data/seuzach_roads.json` — `Bachtobelstrasse` / `Weidstrasse` (class=local, `half_w=36`) | Default unverändert; NS östlich Bachtobel / EW nördlich Weid |
| `data/seuzach_roads.json` — `Schneckenwiesenstrasse` (class=local, 2 pts) | Default unverändert; Extend **nur** wenn Kiga sonst nicht neben Asphalt; bestehende Vertices behalten |
| `data/seuzach_roads.json` — `Reutlingerstrasse` (class=collector) | Nur Fallback-Target (Nordbank); default nicht verlängern |
| `assets/art/landmark_kiga_{bachtobel,weid,schneckenwiese}_{ew,ns}.png` | Style-C street-aligned; Iso-Diamant-Legacy bleibt ungenutzt |
| `comic-rettung-art` + `process_art_alpha.py` / `verify_art_alpha.py` + `godot --import` | Phase-2 Art nur dieser drei Kigas (6 PNGs) |
| `tests/m3_world_landmarks_test.gd` | REQUIRED_ART-Paare, Ost/Süd/West-oder-Nord-Bank, Bearing/Flip; Campi + `kiga_ohringen` prefixed |

## Repro & RCA (Pflicht bei Typ = Bugfix)

Vor Phase 2 ausfüllen. **Repro bestätigt** (Code + RoadKit-JSON + GPS, 2026-08-15). S01–S03 sind erledigt und **nicht** die Ursache dieses Slices (`kiga_ohringen` bereits street-aligned).

### Reproduktion

- [x] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. `world_sandbox` laden. 2. Nacheinander zu `SeuzachGeo.kiga_bachtobel_world()` (~16973, -8656), `kiga_weid_world()` (~16724, 929), `kiga_schneckenwiese_world()` (~6995, -2629) teleportieren. 3. Bachtobelstrasse- / Weidstrasse- / Schneckenwiesenstrasse- bzw. Reutlingerstrasse-Ribbon und die drei Sprites vergleichen (Birch/Rietacker/Ohringen/`house_street_*_{ew,ns}` als Facing-Referenz). |
| Erwartet | Bachtobel **östlich** der sichtbaren Bachtobelstrasse, Westfassade zur Strasse. Weid **südlich** der Weidstrasse, Nordfassade zum Band. Schneckenwiese **westlich** der sichtbaren Schneckenwiesenstrasse (sonst nördlich Reutlingerstrasse), Fassade zur Curb. Sprites street-aligned (`_ew`/`_ns`), Spielplatz/Eingang zur Curb — nicht iso-verdreht neben den Häusern. |
| Tatsächlich | Placement lädt unprefixed Iso-Diamant (`landmark_kiga_bachtobel.png` etc.), `flip_h=false`, kein `street_bearing`/`faces_street`. S01-Helper ist für diese drei **nicht** verdrahtet (weiter `_add_building_prop`). Füße GPS-clear, aber Art steht schief zur Ribbon; User: Schulen/Kigas „not placed properly“ / „wrong side“. |
| Umgebung | Godot 4, Scene `world_sandbox`, Branch aktuell nach S03 v0.36.2; Input n/a (Placement deterministisch). |
| Evidenz | GPS (`SeuzachGeo`, +X Ost +Y Süd): **bachtobel** (16973.4, -8656.3) Bachtobelstrasse d≈576 **east** ns (`spr.x > closest.x`). **weid** (16723.8, 929.0) Weidstrasse d≈544 **south** ew (`spr.y > closest.y`). **schneckenwiese** (6994.6, -2628.6) Schneckenwiesenstrasse 2-pt-Stub d≈558 **west** (`spr.x < closest.x`); Reutlingerstrasse d≈1142 **north** (`spr.y < closest.y`). Stub-Punkte `(7543.4, -3738.7) → (7450.4, -2950.4)` — Südende ~322 wu nördlich des Kigas; Closest = Endpunkt. Code: `_place_kindergartens` Bachtobel/Weid/Schneckenwiese = `_add_building_prop` unprefixed unter `%Props`; `kiga_ohringen` bereits `_add_school_street_prop`. Tests: `_assert_kiga_{bachtobel,weid,schneckenwiese}` rufen `_assert_texture_unprefixed` + `flip_h false`, **keine** Street-Metas. Scales 0.285 / 0.275 / 0.515. |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) `_nudge_off_named_roads` schiebt die Kigas über die Fahrbahn / auf die Gegenbank. (2) Iso-Diamant-Art ohne `_ew`/`_ns` liest schief neben street-aligned Häusern und S01–S03-Schulen. (3) RoadKit-Polylines enden vor dem Kiga (Birch-/Schneckenwiese-Muster). (4) `flip_h` fehlt / Tür/Spielplatz zeigt von der Curb weg. (5) GPS-Konstanten in `seuzach_geo.gd` falsch. (6) S01-Helper nicht verdrahtet. (7) `_named_road_by_name` / nearest-any träfe Herbstackerstrasse (Bachtobel d≈662) statt Bachtobelstrasse. (8) Schneckenwiese sitzt visuell an Reutlingerstrasse, Stub ist zu kurz. |
| Bestätigte Ursache | **(6) + (2) + (4).** Die drei Seuzach-Kigas nutzen noch `_add_building_prop` (unprefixed, `flip_h` default false, kein `street_bearing`). Iso-Diamant neben street-aligned Birch/Rietacker/Ohringen/Häusern wirkt „falsche Seite“. Helper existiert seit S01, Bank-Asserts seit S02 — Call-Sites für diese drei fehlen. **(3) nur Schneckenwiese-Risiko:** Stub endet nördlich des Props; d≈558 liegt trotzdem im 800-wu-Band über den Endpunkt — visuell evtl. nicht „neben Asphalt“. |
| Nicht die Ursache | **(1) Nudge als Hauptbug:** GPS-Füße clearen heute Asphalt (`_nudge_off_named_roads` gibt `pos` unverändert zurück). **Bachtobel/Weid-Ribbon:** d≈576 / 544, beide < 800 — analog Ohringen, kein Birch-Lücken-Fix. **(5)** GPS matcht OSM (Tests asserten LAT/LON + World-Punkte). **(7)** Helper targetet den Namen, nicht nearest-any; Herbstacker ist nicht das Call-Target. **Campi / `kiga_ohringen`:** S01–S03 erledigt, bereits prefixed. |
| Fix-Richtung | Drei Calls auf `_add_school_street_prop` umstellen. Art `_ew`/`_ns` nur diese drei Kigas. bachtobel → Bachtobelstrasse Ost; weid → Weidstrasse Süd; schneckenwiese → Schneckenwiesenstrasse West wenn nach Wiring Setback-Band + sichtbarer Asphalt, sonst Reutlingerstrasse Nord. Stub nur verlängern (2 Vertices behalten) wenn nötig. GPS-Getter und Scales locked. Tests: Ost/Süd/West-oder-Nord; Campi + Ohringen-Kiga prefixed. |
| Risiken | Ohne die sechs PNGs gibt der Helper `null` zurück (Kigas verschwinden). Schneckenwiese `SCALE_MULT` 1.03 → größere AABB / `need`; Helper schiebt **west** (away), nicht über die Fahrbahn. Stub-Closest = Endpunkt: nach Extend weiter NS → `_ns`. Reutlinger-Fallback d≈1142 würde `d < 800` **failen**, solange die collector-Ribbon nicht näher kommt — deshalb Stub-Extend bevorzugen, nicht Reutlinger nach Norden durchs Grundstück. Bachtobel-Nudge vs Herbstackerstrasse (GPS-Ostseite): Bank-Recovery im Helper sucht along-away, nicht across. Iso-Legacy darf auf Disk bleiben, darf nicht mehr geladen werden. Campi/`kiga_ohringen` dürfen durch den Helper nicht umgebogen werden. |

- [x] RCA dokumentiert und reviewed (kurz vom Hauptagenten ok)

## Technische Schritte

### 1. Placement — S01-Helper verdrahten (kein Fork)

In `_place_kindergartens` die drei Seuzach-`_add_building_prop`-Blöcke ersetzen durch `_add_school_street_prop`. `kiga_ohringen`-Call **unverändert** lassen (S03). Signatur unverändert:

```
_add_school_street_prop(base_without_suffix, pos, scale, metas, node_name, target_road_name)
```

`_prop_parent` bleibt `%Props` für Bachtobel/Weid/Schneckenwiese (DistrictOhringen nur für den bestehenden Ohringen-Kiga-Call).

| Node | `base_without_suffix` | GPS | Scale | `target_road_name` | Bank |
|------|------------------------|-----|-------|--------------------|------|
| `kiga_bachtobel` | `landmark_kiga_bachtobel` | `kiga_bachtobel_world()` | `SCHOOL_SCALE * 0.57` | `Bachtobelstrasse` | east |
| `kiga_weid` | `landmark_kiga_weid` | `kiga_weid_world()` | `SCHOOL_SCALE * 0.55` | `Weidstrasse` | south |
| `kiga_schneckenwiese` | `landmark_kiga_schneckenwiese` | `kiga_schneckenwiese_world()` | `SCHOOL_SCALE * 1.03` | `Schneckenwiesenstrasse` (Fallback `Reutlingerstrasse`) | west (Fallback north) |

Metas **behalten:** `landmark_id` / `kindergarten_id` / `district` — **kein** `school_cluster`. Helper setzt zusätzlich `street_side`, `street_bearing`, `faces_street`, `street_name`.

Kommentar in `_place_kindergartens` aktualisieren: alle vier Kigas street-aligned; Seuzach drei unter `%Props`, Ohringen unter `DistrictOhringen`. Kommentar in `_place_school_clusters` (heute „Seuzach kigas stay unprefixed (S04)“) anpassen: Campi unverändert, Kigas in `_place_kindergartens`.

`seuzach_geo.gd` Getter und LAT/LON nicht ändern. `KIGA_*_SCALE_MULT` nicht ändern.

Helper-Ablauf (bereits S01, hier nur Call-Sites):

1. Tangent am nächsten Segment der **Ziel**-Polyline via `_named_road_by_name` (nearest-same-name, nicht nearest-any-named-road).
2. Datei `…_{ew\|ns}.png` aus `|tx| >= |ty|` → `ew`.
3. GPS-Seite halten: `away = pos - closest`; Setback entlang `away` nur wenn `d_feet < need` (`need ≈ half_w + street_facing_half(BUILDING_CLEAR-Größe, bearing) + BUILDING_CLEAR_EDGE_MARGIN + HOUSE_CURB_SLACK`).
4. Nudge erste Richtung = GPS-`away` (Ost von Bachtobelstrasse / Süd von Weidstrasse / West von Schneckenwiesenstrasse), nicht `+perp` durch die Fahrbahn.
5. `flip_h` Tür/Spielplatz zur Curb; `Sprite2D.rotation == 0`.

### 2. RoadKit — Default Bachtobel/Weid nicht anfassen; Schneckenwiese nur bei Need

**Nicht** extendieren, solange nach Schritt 1 gilt:

- bachtobel → Bachtobelstrasse d < ~800 und Ostbank, nicht auf Asphalt
- weid → Weidstrasse d < ~800 und Südbank, nicht auf Asphalt
- schneckenwiese → Schneckenwiesenstrasse d < ~800 und Westbank **und** neben sichtbarem Asphalt

Heute: Bachtobel d≈576 east, Weid d≈544 south (OK). Schneckenwiese d≈558 west über Stub-Endpunkt (Setback-Zahl OK; sichtbare Ribbon endet ~322 wu nördlich). Der Helper **zieht Gebäude nicht zur Ribbon**.

**Schneckenwiese-Entscheidung (nach Wiring + Art-AABB, Playtest-sichtbar):**

1. Prefer `Schneckenwiesenstrasse` West, wenn der Prop im Setback-Band sitzt **und** das NS-Band östlich vorbeiläuft (nicht nur Endpunkt-Luftlinie).
2. Sonst Stub **verlängern**: bestehende 2 Vertices behalten, Punkt(e) **anhängen** nach Süden, x so dass das Band **östlich** von ~6995 bleibt (Trend des Stubs: Δx≈−93, Δy≈+788). Keine Vertices löschen; kein neues Road-Objekt.
3. Nur wenn 1–2 den Prop trotzdem nicht ins Band / an sichtbaren Asphalt bringen: Target auf `Reutlingerstrasse` Nord wechseln. **Nicht** Reutlinger nach Norden durchs Grundstück stanzen, nur um d unter 800 zu zwingen, wenn ein Stub-Extend reicht.

**Verboten:** Bachtobel auf Westbank klappen; Weid auf Nordbank; Schneckenwiese auf Ostbank / Reutlinger-Südbank; Stub ersetzen statt anhängen; Campi-Polylines anfassen.

### 3. Tests (`tests/m3_world_landmarks_test.gd`)

Regression bildet die Repro ab (zuerst rot: unprefixed + keine Street-Metas; nach Fix grün):

- **REQUIRED_ART:** sechs Seuzach-Kiga-Paare Pflicht:
  - `landmark_kiga_bachtobel_{ew,ns}.png`
  - `landmark_kiga_weid_{ew,ns}.png`
  - `landmark_kiga_schneckenwiese_{ew,ns}.png`  
  Unprefixed `landmark_kiga_{bachtobel,weid,schneckenwiese}.png` dürfen als Legacy-Exists bleiben. Placement darf unprefixed **nicht** mehr laden.
- **`_assert_kiga_bachtobel` / `_weid` / `_schneckenwiese`:** `_assert_texture_unprefixed` und `flip_h false` **entfernen**. GPS-Konstanten, 720 wu GPS, District **nicht** Ohringen, `not has_meta("school_cluster")`, Relativlage vs Birch/einander, Scales 0.285 / 0.275 / 0.515, `rotation == 0`, `_assert_road_near` **behalten**.
- **Street-Asserts** (bestehender Helper, `bank` schon west/east/north/south — **nicht** neu erfinden):
  - bachtobel: Target `Bachtobelstrasse`, **Ostbank** (`bank="east"`), Suffix matcht Tangent (am Kiga ≈ NS → `_ns`)
  - weid: Target `Weidstrasse`, **Südbank** (`bank="south"`), Weid EW → `_ew`
  - schneckenwiese: **West of Schneckenwiesenstrasse oder Nord of Reutlingerstrasse** — ein Target, passend zu `street_name`. Pattern analog S02 `rietacker_b` (if/else auf Target), nicht beide Bänke gleichzeitig.
- **`_assert_school_street_prop`:** Unprefixed-Verbot um Seuzach-Kiga-Basen erweitern (`landmark_kiga_bachtobel.png`, `landmark_kiga_weid.png`, `landmark_kiga_schneckenwiese.png`). Birch/Rietacker/Ohringen-Calls unverändert. `d < 800` und `d >= need-12` gelten für die **Ziel**-Polyline.
- Optional: `_assert_ns_house_art_not_rotate_of_ew` um die drei Basen ergänzen (`landmark_kiga_bachtobel`, `landmark_kiga_weid`, `landmark_kiga_schneckenwiese`).
- **`_assert_kiga_ohringen`:** bleibt prefixed, Westbank Schulstrasse (S03) — **nicht** umbauen.
- **Birch S01 / Rietacker S02 / Ohringen S03** bleiben grün (prefixed + Bank-Asserts). Campus-Cluster-Counts unverändert.

### 4. Art (Phase 2 — nur dieser Slice)

Siehe Art-Bedarf. Implementer beauftragt `comic-rettung-art`; danach Alpha-Pipeline + Godot-Import **bevor** Tests `ResourceLoader.exists` erwarten. Ohne die sechs PNGs gibt der Helper `null` zurück (Kigas verschwinden).

## Testplan

### Automatisiert

- [ ] `tests/m3_world_landmarks_test.gd`: sechs Seuzach-Kiga `_ew`/`_ns` existieren; Placement lädt Prefixed (nicht unprefixed)
- [ ] `kiga_bachtobel` östlich nächster Bachtobelstrasse-x; Distanz im Setback-Band
- [ ] `kiga_weid` südlich nächster Weidstrasse-y; Distanz im Setback-Band
- [ ] `kiga_schneckenwiese` westlich nächster Schneckenwiesenstrasse-x **oder** nördlich nächster Reutlingerstrasse-y; Distanz im Setback-Band des gewählten Targets
- [ ] Drei Kigas: `street_bearing` matcht Ziel-Tangent; Dateisuffix matcht; `faces_street`; `street_side` ±1; `flip_h` zur Curb; `rotation == 0`
- [ ] GPS-Getter unverändert; Scales 0.285 / 0.275 / 0.515; kein `school_cluster`; Parent nicht `DistrictOhringen`
- [ ] Visual clear / off-road grün (`BUILDING_CLEAR` Paint + bearing street-half); local `half_w=36`
- [ ] Birch/Rietacker/Ohringen-Campus-Asserts grün (prefixed); `kiga_ohringen` Westbank Schulstrasse prefixed
- [ ] Optional: NS-Kiga-Art nicht `ROTATE_90/270` von EW
- [ ] Bei Bugfix: Regressionstest bildet die Repro ab (zuerst rot, nach Fix grün)

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Teleport Bachtobel: Kiga **östlich** der **sichtbaren** Bachtobelstrasse; Westfassade zum Band (Bachtobelstrasse 17); Spielplatz zur Curb; nicht iso-Ecke
- [ ] Teleport Weid: Kiga **südlich** der **sichtbaren** Weidstrasse; Nordfassade zum Band (Weidstrasse 16); Spielplatz zur Curb
- [ ] Teleport Schneckenwiese: Kiga **westlich** der **sichtbaren** Schneckenwiesenstrasse (oder nördlich Reutlingerstrasse, falls Fallback); Fassade zur Curb (Reutlingerstrasse 15); Asphalt neben dem Prop lesbar, nicht unter den Füßen
- [ ] NS-Kigas aufrecht (Dach oben, Fassade links bzw. nach Flip rechts) — nicht aus EW rotiert; kein lesbarer Text in den Sprites
- [ ] Campi Birch/Rietacker/Ohringen und Kiga Ohringen unverändert (West/Nord wie S01–S03)
- [ ] Bei Bugfix: manuelle Repro-Schritte schlagen nach Fix nicht mehr fehl

## Art-Bedarf

- [ ] Keine neuen Assets
- [x] Neue Grafiken/Animationen → Subagent `comic-rettung-art`

Details (nur die **drei Seuzach-Kigas**, Style **C — Comic-Rettung** — 6 PNGs):

| Datei | Rolle |
|-------|--------|
| `assets/art/landmark_kiga_bachtobel_ew.png` | Freundlicher kleiner Kiga Bachtobelstrasse 17 + Spielplatz zur Curb, EW |
| `assets/art/landmark_kiga_bachtobel_ns.png` | dasselbe, NS |
| `assets/art/landmark_kiga_weid_ew.png` | Freundlicher kleiner Kiga Weidstrasse 16 + Spielplatz zur Curb, EW |
| `assets/art/landmark_kiga_weid_ns.png` | dasselbe, NS |
| `assets/art/landmark_kiga_schneckenwiese_ew.png` | Freundlicher kleiner Kiga Reutlingerstrasse 15 / Schneckenwiesenstrasse + Spielplatz zur Curb, EW |
| `assets/art/landmark_kiga_schneckenwiese_ns.png` | dasselbe, NS |

- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` (**nur** Haus–Strasse-Layout, keine Maße/Kamera) **plus** Street View / Maps **Bachtobelstrasse 17**, **Weidstrasse 16**, **Reutlingerstrasse 15** Seuzach. Unprefixed `landmark_kiga_{bachtobel,weid,schneckenwiese}.png` als Farb-/Masse-Refs, nicht als Iso-Diamant-Vorlage für Facing. Proportionen aus C-Refs und bestehenden Style-C-Kiga/Schul-Sprites (inkl. `landmark_kiga_ohringen_{ew,ns}.png`), nicht aus der Iso-Karte.
- Silhouette (Art, **nicht** Dateisuffix): drei **verschiedene** freundliche kleine Kigas, jeweils mit **Spielplatz zur Curb** (nicht Schulhaus-Cluster). **Bachtobel:** Giebel, Bachtobelstrasse 17 (zwei Abteilungen). **Weid:** Flachdach-Pavillon, Weidstrasse 16. **Schneckenwiese:** zwei Walm-Flügel + mittleres Flachdach, Reutlingerstrasse 15. Dateisuffix kommt von der **Strassen-Tangent**, nicht von der OSM-Gebäudeachse (Bachtobel/Schneckenwiese an NS → oft `_ns`; Weid an EW → oft `_ew`).
- **EW:** lange Fassade + Tür/Spielplatz am Canvas-**BOTTOM**. **NS:** aufrecht, Dach **TOP**, lange Fassade + Tür/Spielplatz an der **linken** vertikalen Kante. **Niemals** `_ns` aus `_ew` per `ROTATE_90`/`270`.
- Kein Asphalt in die PNG; Fußkante frei. Cel + dicke `#1A1A1A`-Kontur; kein 3D-Plastik. **Kein lesbarer Text** (kein „Kindergarten“, keine Hausnummer).
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün) → `godot --headless --path . --import`.
- Unprefixed Legacy-PNGs nicht löschen müssen; nicht mehr im Seuzach-Kiga-Placement verwenden.
- **Nicht** in diesem Slice: Birch, Rietacker, Ohringen-Campus, **Kiga Ohringen**, Häuser.

## Akzeptanzkriterien

- [ ] Repro + RCA erledigt (Bachtobel ost / Weid süd / Schneckenwiese west-oder-nord; Ursache = Helper nicht verdrahtet + Iso-Art + kein Flip)
- [ ] Drei Props über `_add_school_street_prop` (kein zweiter Helper); Ziel bachtobel→Bachtobelstrasse Ost, weid→Weidstrasse Süd, schneckenwiese→Schneckenwiesenstrasse West (sonst Reutlinger Nord)
- [ ] RoadKit Bachtobel/Weid default unverändert; Schneckenwiesenstrasse-Stub nur bei Need verlängern (2 Vertices behalten); keine Gegenbank-Klappung; Campi/`kiga_ohringen` unangetastet
- [ ] Sechs Style-C `_ew`/`_ns` Seuzach-Kiga-Assets; Placement nutzt sie; `rotation == 0`; Mults 0.57 / 0.55 / 1.03
- [ ] Kein `school_cluster`; Parent `%Props`; GPS-Getter gehalten; Scales 0.285 / 0.275 / 0.515
- [ ] Tests grün inkl. Ost/Süd/West-oder-Nord-Bank / Bearing / Flip / REQUIRED_ART-Paare; Campi + `kiga_ohringen` prefixed
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass
