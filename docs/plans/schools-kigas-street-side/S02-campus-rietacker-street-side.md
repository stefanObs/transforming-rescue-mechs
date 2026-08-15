# Plan: schools-kigas-street-side / Slice S02

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-15  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/schools-kigas-street-side/INDEX.md`  
**Slice-Datei:** `docs/plans/schools-kigas-street-side/S02-campus-rietacker-street-side.md`  
**Hängt ab von:** S01 (erledigt, v0.36.0 — Helper `_add_school_street_prop` existiert; Birch verdrahtet)

Nur der **Feature-Schritt** (Campus-Cluster an Ohringerstrasse + Turnhalle an Turnerstrasse). Plan nötig (Bug → Phase-0 RCA + Art + Multi-System: Placement-Helper wiederverwenden, Test-Bank Nord/Ost, Style-C `_ew`/`_ns`). Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Campus **Rietacker** sitzt **nördlich** der Ohringerstrasse (Südfassade zur Strasse); die Turnhalle steht am Westcampus **östlich** der Turnerstrasse. Sprites street-aligned wie Birch (`_ew`/`_ns` + Helper-`flip_h`), nicht Iso-Diamant.

## In diesem Schritt

- S01-Helper wiederverwenden (Bearing, GPS-Strassenseite, Flip, Setback) — nur die drei Rietacker-Props verdrahten
- `schulhaus_rietacker_a` / `_b`: GPS-Bank **north** of Ohringerstrasse halten; Fassade süd zur Strasse
- `turnhalle_rietacker`: westlich an Turnerstrasse (lange Achse zur lokalen Tangente)
- Style-C `_ew`/`_ns` nur für Rietacker; `_ns` nie aus `_ew` rotieren; `rotation == 0`
- RoadKit nur anfassen, wenn eine Rietacker-Polyline den Campus nicht erreicht (Default: Ohringer/Turner reichen)

## Nicht (andere Feature-Schritte)

- Campus Birch (S01), Ohringen + Kiga (S03), Seuzach-Kigas (S04)
- Wohnhäuser, Bahnhof/Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz; globales `SCHOOL_SCALE`; `Sprite2D.rotation`

## Ziel

Campus **Rietacker** (Schulhäuser a/b + Turnhalle) sitzt **nördlich** der sichtbaren Ohringerstrasse; Südfassade von a (Ohringerstr. 16) zur Strasse. Die Turnhalle (Turnerstr. 2) steht am **Westcampus**, **östlich** der sichtbaren Turnerstrasse (nicht westlich der Ribbon, nicht südlich der Ohringerstrasse). Sprites sind street-aligned (`_ew`/`_ns` + seitenbewusstes `flip_h` via S01-Helper), nicht mehr Iso-Diamant. Kein zweiter Placement-Helper.

## Scope

### In

- S01-Helper **wiederverwenden**, nicht forken: `_add_school_street_prop(base_without_suffix, pos, scale, metas, node_name, target_road_name)` in `world_sandbox.gd`. Die drei Rietacker-`_add_building_prop`-Calls (unprefixed) ersetzen. Housing-Call-Sites und `_nudge_off_named_roads(prefer_away)` unverändert.
- Ziel-Strassen (Default):
  - **a + b → `Ohringerstrasse`** (Nordbank: `spr.y < closest.y` weil +Y Süd; Fassade Süd zur Strasse)
  - **gym → `Turnerstrasse`** (Ostbank der NS-Strecke: `spr.x > closest.x`; Westcampus, lange Achse zur lokalen Tangente)
- Fallback **nur b:** wenn nach Verdrahtung b noch **>~800 wu** von Ohringer liegt (GPS heute d≈1291, Helper zieht nicht zur Ribbon) **und** Tests eine named Polyline im Setback-Band brauchen: **b → `Püntenstrasse`** (NE-Trakt; b südlich des Stubs). Nur dann Pünten-Extend, siehe Technische Schritte. Nicht den Campus auf die Südseite der Ohringerstrasse klappen.
- GPS-Getter in `seuzach_geo.gd` **unverändert**. Kleines Curb-Setback zur Ziel-Ribbon OK (Helper schiebt nur wenn `d_feet < need`). Cluster halten: a süd-ost vs b nord-ost; gym west von a/b (`gym.x < min(a.x,b.x) - 800`, `b.y < a.y - 400`). Bestehende Offset-Asserts vs yard **behalten**; 720-wu-GPS-Drift darf äußere Schranke bleiben, Side/Bearing zusätzlich; Setback-Band straffen wo der Helper sie bewegt.
- Per-Building Scales **locked:** `RIETACKER_A_SCALE_MULT` 1.30, `B` 1.25, `TURNHALLE` 1.30 auf `SCHOOL_SCALE` 0.50 → **0.65 / 0.625 / 0.65**. Globales `SCHOOL_SCALE` nicht ändern.
- RoadKit: Default **nicht** verlängern. Ohringer (class=main, `half_w=72`, 17-pt Hauptpolyline) und Turner (class=local, `half_w=36`, 18 pts) **reichen bereits** zu a (d≈414 Nord) und gym (d≈697 Ost). Nur extendieren, wenn nach Helper-Wiring a/b/gym noch **>~800 wu** vom Target oder auf Asphalt sitzen. Bestehende Vertices behalten. **Kein** Ohringer-Nord-Durchstich durch den Hof, um b näher an Ohringer zu holen.
- Style-C `_ew`/`_ns` **nur für Rietacker** via `comic-rettung-art`; `_ns` nie aus `_ew` rotieren (`ROTATE_90`/`270` verboten); Fassade EW unten / NS links vertikal; `rotation == 0`. Unprefixed `landmark_schulhaus_rietacker_{a,b}.png` / `landmark_turnhalle_rietacker.png` dürfen als Legacy auf Disk bleiben; Placement muss `_ew`/`_ns` laden.
- Tests in `tests/m3_world_landmarks_test.gd`: REQUIRED_ART sechs Rietacker-Paare; Nordbank Ohringer für a (und b falls Target Ohringer); gym ost von Turner (oder weiter west-of-campus wie gelockt); `street_bearing` / `faces_street` / `flip_h`; `rotation == 0`; Birch-S01-Asserts bleiben grün; Ohringen/Kigas weiter unprefixed, **keine** neuen Facing-Metas Pflicht.
- Test-Helper: `_assert_school_street_prop(world, spr, road, west_of_road)` kennt nur West/Ost (`x`). Für Rietacker **erweitern** oder `north_of`-Variante: Nordbank EW-Ohringer (`spr.y < closest.y`); gym Ost von NS-Turner (`west_of_road=false`). Birch West/Ost-Asserts nicht brechen. `_assert_rietacker_campus` braucht `world` (wie Birch). `_assert_texture_unprefixed` von den drei Rietacker-Sprites **entfernen**.

### Nicht

- Campus Birch (S01) umbauen — Asserts müssen grün bleiben; Helper-Signatur nicht in einen zweiten Wrapper spalten
- Ohringen + Kiga Ohringen (S03), Seuzach-Kigas Bachtobel/Weid/Schneckenwiese (S04)
- Wohnhäuser / Housing-Art (`house_street_*`), Bahnhof, Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz neu zeichnen; globales `SCHOOL_SCALE`; `Sprite2D.rotation` als Facing
- GPS auf die **Südseite** der Ohringerstrasse klappen
- `HOUSE_CLEAR_*` / Housing-Nudge-Reihenfolge / Housing-Call-Sites ändern
- S01/S03/S04-Gebäude-Art oder -Placement

## Systeme

| System | Rolle in diesem Slice |
|--------|------------------------|
| `scripts/world_sandbox.gd` — `_add_school_street_prop` (S01, nicht forken) | Drei Rietacker-Calls: Ziel-Strasse, Bearing-Datei, GPS-Bank, Flip, Metas |
| `scripts/world_sandbox.gd` — `_place_school_clusters` | Unprefixed `_add_building_prop` für a/b/gym ersetzen; Birch/Ohringen-Calls unangetastet |
| `scripts/seuzach_geo.gd` | GPS-Getter **unverändert** (`rietacker_schulhaus_{a,b}_world`, `rietacker_turnhalle_world`) |
| `data/seuzach_roads.json` — `Ohringerstrasse` (class=main, `half_w=72`, 17-pt + Nebenstücke) | Default unverändert; erste named Polyline = 17-pt Campus-Ribbon |
| `data/seuzach_roads.json` — `Turnerstrasse` (class=local, `half_w=36`, 18 pts) | Default unverändert; NS-Stretch westlich der Halle |
| `data/seuzach_roads.json` — `Püntenstrasse` (class=local, 3-pt Stub y≈-6907) | Nur falls b nicht Ohringer-Setback-Band erreicht |
| `assets/art/landmark_schulhaus_rietacker_{a,b}_{ew,ns}.png`, `landmark_turnhalle_rietacker_{ew,ns}.png` | Style-C street-aligned; Iso-Diamant-Legacy bleibt ungenutzt |
| `comic-rettung-art` + `process_art_alpha.py` / `verify_art_alpha.py` + `godot --import` | Phase-2 Art nur dieser Campus |
| `tests/m3_world_landmarks_test.gd` | REQUIRED_ART-Paare, Nord/Ost-Bank, Bearing/Flip, Cluster; Birch grün; Ohringen/Kigas unprefixed |

## Repro & RCA (Pflicht bei Typ = Bugfix)

Vor Phase 2 ausfüllen. **Repro bestätigt** (Code + RoadKit-JSON + GPS, 2026-08-15). S01 (Birch) ist erledigt und **nicht** die Ursache dieses Slices.

### Reproduktion

- [x] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. `world_sandbox` laden. 2. Zu Campus Rietacker teleportieren / `SeuzachGeo.rietacker_world()` (~1442, -5844) bzw. `rietacker_schulhaus_a_world()` (~1781, -5414). 3. Ohringerstrasse-Ribbon, Turnerstrasse-Ribbon und die drei Schul-Sprites vergleichen (Birch/`house_street_*_{ew,ns}` als Facing-Referenz). |
| Erwartet | a und b **nördlich** der sichtbaren Ohringerstrasse; Südfassade von a zur Strasse (Ohringerstr. 16). Turnhalle am Westcampus, **östlich** der Turnerstrasse (Turnerstr. 2), lange Halle parallel zum Band. Sprites street-aligned (`_ew`/`_ns`), Tür zur Curb, Hof zwischen den Trakten — nicht iso-verdreht neben den Häusern. |
| Tatsächlich | Placement lädt unprefixed Iso-Diamant (`landmark_schulhaus_rietacker_a.png` etc.), `flip_h=false`, kein `street_bearing`/`faces_street`. S01-Helper ist **nicht** verdrahtet (weiter `_add_building_prop`). Füße GPS-clear, aber Art steht schief zur Ribbon; User: Schulen „not placed properly“ / „wrong side“. |
| Umgebung | Godot 4, Scene `world_sandbox`, Branch aktuell nach S01 v0.36.0; Input n/a (Placement deterministisch). |
| Evidenz | GPS (`SeuzachGeo`, +X Ost +Y Süd): **a** (1781, -5414) OSM 47.5360788, 8.7273791 — Soll **north** of Ohringerstrasse, Fassade Süd, SO, Ohringerstr. 16, ~33 m N–S Giebel 1933. **b** (2036, -6320) — NE, Püntenstrasse, kleiner 1-geschossig. **gym** (196, -5526) — Westen, Turnerstr. 2, ~48 m E–W-Halle. RoadKit **reicht** (anders als Birch): Ohringerstrasse class=main `half_w=72`, 17 pts, bbox x=-23212..5147 y=-5526..-1806; a d≈414 **Nordbank**; gym d≈681 nord von Ohringer, d≈697 **ost** von Turner (NS-Stretch); b d≈1291 nord von Ohringer, d≈899 süd des Pünten-Stubs (3 pts y≈-6907). Turnerstrasse class=local `half_w=36`, 18 pts; gym d≈697 ost, a d≈1845. Code: `_place_school_clusters` Zeilen Rietacker = `_add_building_prop` unprefixed; Birch bereits `_add_school_street_prop`. Tests: `_assert_rietacker_campus` ruft `_assert_texture_unprefixed`, **keine** Street-Metas. |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) `_nudge_off_named_roads` schiebt Rietacker über die Fahrbahn / auf die Südseite der Ohringerstrasse. (2) Iso-Diamant-Art ohne `_ew`/`_ns` liest schief neben street-aligned Häusern und Birch. (3) RoadKit-Polylines enden vor dem Campus (Birch-Muster). (4) `flip_h` fehlt / Tür zeigt von der Curb weg. (5) GPS-Konstanten in `seuzach_geo.gd` falsch. (6) S01-Helper nicht verdrahtet. (7) `_named_road_by_name` first-match trifft ein Ohringer-Nebenstück statt der 17-pt-Hauptpolyline. |
| Bestätigte Ursache | **(6) + (2) + (4).** Rietacker nutzt noch `_add_building_prop` (unprefixed, `flip_h` default false, kein `street_bearing`). Iso-Diamant neben street-aligned Birch/Häusern wirkt „falsche Seite“. Helper existiert seit S01, ist für Rietacker nicht angeschlossen. |
| Nicht die Ursache | **(1) Nudge als Hauptbug:** GPS-Füße clearen heute Asphalt (`_nudge_off_named_roads` gibt `pos` unverändert zurück). **(3) Ribbon-Lücke analog Birch:** Ohringer/Turner **erreichen** a und gym (d≈414 / d≈697 < 800). b ist 1291 wu nördlich Ohringer — das ist Abstand zum **Süd**-Band, nicht fehlendes Band vor a. **(5)** GPS matcht OSM (Tests asserten LAT/LON + Offsets vs `rietacker_world()`). **(7)** noch nicht bestätigt: JSON-erste `Ohringerstrasse` **ist** die 17-pt-Hauptpolyline; nach Wiring verifizieren, dass `_named_road_by_name` genau die campus-nahe Ribbon nimmt (Birch-Namen sind eindeutig). |
| Fix-Richtung | Drei Rietacker-Calls auf `_add_school_street_prop` umstellen. Art `_ew`/`_ns` nur Rietacker. Default a/b → Ohringer Nord, gym → Turner Ost. RoadKit default unverändert. Wenn b nach Wiring noch >~800 von Ohringer: **nicht** Ohringer durch den Hof nach Norden ziehen; b auf Püntenstrasse (NE) und Stub nur dann nach Süden verlängern. Test-Helper um Nordbank erweitern. Scales locked. |
| Risiken | `_named_road_by_name` first-match: vier `Ohringerstrasse`-Stücke; falls Reihenfolge wechselt, Bearing/Setback falsch — ggf. im **bestehenden** Helper nearest-same-name wählen (kein zweiter Wrapper). Ohringer `half_w=72` → `need` größer als Birch-local 36; a d≈414 kann nach Art-AABB knapp werden — Helper schiebt **nord** (away), nicht über die Fahrbahn. Pünten-Fallback: `_assert_school_street_prop` `d < 800` und `d >= need-12` — Stub d≈899 braucht Extend **oder** b bleibt auf Ohringer ohne Setback-Band (dann Test würde rot). Iso-Legacy darf auf Disk bleiben, darf nicht mehr geladen werden. S03/S04 dürfen durch den Helper nicht plötzlich `_ew`/`_ns` verlangen. Birch-Asserts (`west_of_road`) nicht umbiegen. |

- [x] RCA dokumentiert und reviewed (kurz vom Hauptagenten ok)

## Technische Schritte

### 1. Placement — S01-Helper verdrahten (kein Fork)

In `_place_school_clusters` die drei Rietacker-`_add_building_prop`-Blöcke ersetzen durch `_add_school_street_prop`. Signatur unverändert:

```
_add_school_street_prop(base_without_suffix, pos, scale, metas, node_name, target_road_name)
```

| Node | `base_without_suffix` | GPS | Scale | `target_road_name` (Default) |
|------|------------------------|-----|-------|------------------------------|
| `schulhaus_rietacker_a` | `landmark_schulhaus_rietacker_a` | `rietacker_schulhaus_a_world()` | `SCHOOL_SCALE * 1.30` | `Ohringerstrasse` |
| `schulhaus_rietacker_b` | `landmark_schulhaus_rietacker_b` | `rietacker_schulhaus_b_world()` | `SCHOOL_SCALE * 1.25` | `Ohringerstrasse` (Fallback `Püntenstrasse`, Schritt 2) |
| `turnhalle_rietacker` | `landmark_turnhalle_rietacker` | `rietacker_turnhalle_world()` | `SCHOOL_SCALE * 1.30` | `Turnerstrasse` |

Metas **behalten** (`landmark_id` / `school_cluster` / `district` / `poi_type=gym` an der Halle). Helper setzt zusätzlich `street_side`, `street_bearing`, `faces_street`, `street_name`.

Kommentar in `_place_school_clusters` aktualisieren: Rietacker street-aligned wie Birch; Ohringen/Kigas bleiben unprefixed (S03/S04).

`seuzach_geo.gd` Getter und LAT/LON nicht ändern. `RIETACKER_*_SCALE_MULT` nicht ändern.

Helper-Ablauf (bereits S01, hier nur Call-Sites):

1. Tangent am nächsten Segment der **Ziel**-Polyline (nicht nearest-any-named-road).
2. Datei `…_{ew\|ns}.png` aus `|tx| >= |ty|` → `ew`.
3. GPS-Seite halten: `away = pos - closest`; Setback entlang `away` nur wenn `d_feet < need` (`need ≈ half_w + street_facing_half(BUILDING_CLEAR-Größe, bearing) + BUILDING_CLEAR_EDGE_MARGIN + HOUSE_CURB_SLACK`).
4. Nudge erste Richtung = GPS-`away` (Nord von Ohringer / Ost von Turner), nicht `+perp` durch die Fahrbahn.
5. `flip_h` Tür zur Curb; `Sprite2D.rotation == 0`.

**`_named_road_by_name`:** Ohringerstrasse hat **vier** JSON-Polylines; erste = 17-pt Campus-Ribbon (bbox reicht an a/gym). Wenn first-match **nicht** das campus-nahe Stück ist: im **bestehenden** Helper / `_named_road_by_name` nearest-same-name wählen (Birch-Namen bleiben eindeutig). Kein zweiter Schul-Wrapper.

### 2. RoadKit — Default nicht anfassen

**Nicht** extendieren, solange nach Schritt 1 gilt:

- a → Ohringer d < ~800 und Nordbank, nicht auf Asphalt
- gym → Turner d < ~800 und Ostbank, nicht auf Asphalt
- b → gewähltes Target d < ~800, richtige Bank, nicht auf Asphalt

Heute: a d≈414 Nord Ohringer (OK). gym d≈697 Ost Turner (OK). b d≈1291 Nord Ohringer (**über** 800). Der Helper **zieht Gebäude nicht zur Ribbon**.

**Verboten:** Ohringerstrasse nach **Norden durch den Hof** (zwischen a y≈-5414 und b y≈-6320) verlängern, um b in ein Ohringer-Setback-Band zu holen. Campus nicht auf die Südseite klappen. Bestehende Vertices nicht löschen.

**Wenn b nach Wiring noch >~800 von Ohringer** (erwartet):

1. Target von b auf **`Püntenstrasse`** stellen (OSM NE-Trakt). Bank: **südlich** des Stubs (`spr.y > closest.y`; Fassade Nord zur Pünten).
2. Heute d≈899 zum 3-pt-Stub `(2717.8, -6906.9) → (4049.2, -6839.7) → (5108.5, -6872.0)` — b liegt west/süd des Ost-Stubs. Wenn d weiter >~800 oder Füße auf Asphalt: Stub **nach Westen/Süden Richtung b** verlängern, bestehende 3 Punkte behalten; neue Punkte **nördlich** von b (y < b.y, z. B. y≈-6400…-6500, x knapp nördlich/östlich von b x=2036), **nicht** durch den Trakt. class=local `half_w=36` belassen.
3. Tests müssen die **named** Pünten-Polyline im Setback-Band asserten (`d < 800`, `d >= need-12`).

Ohringer/Turner nur anfassen, wenn a oder gym nach Wiring + Art-AABB auf Asphalt sitzen oder >~800 vom Target — dann Vertices **anhängen**, Campus-Bank halten.

### 3. Tests (`tests/m3_world_landmarks_test.gd`)

Regression bildet die Repro ab (zuerst rot: unprefixed + keine Street-Metas; nach Fix grün):

- **REQUIRED_ART:** sechs Rietacker-Paare Pflicht:
  - `landmark_schulhaus_rietacker_a_{ew,ns}.png`
  - `landmark_schulhaus_rietacker_b_{ew,ns}.png`
  - `landmark_turnhalle_rietacker_{ew,ns}.png`  
  Unprefixed `landmark_schulhaus_rietacker_{a,b}.png` und GEO_ART `landmark_turnhalle_rietacker.png` dürfen als Legacy-Exists bleiben. Placement darf unprefixed **nicht** mehr laden.
- **`_assert_rietacker_campus(world, sprites)`:** `world` durchreichen (Call-Site heute nur `all_sprites`). `_assert_texture_unprefixed` für a/b/gym **entfernen**. GPS-Konstanten, yard-Offsets `(339.1, 429.5)` / `(594.9, -476.6)` / `(-1245.6, 317.2)`, Cluster=3, Metas, Scales 0.65 / 0.625 / 0.65, Relativlage gym west / b nördlich a / a+b ost der Halle, 720 wu GPS, 1600 wu yard, `rotation == 0` **behalten**. Bei Setback Relativ-Asserts nur straffen, nicht kippen.
- **Street-Asserts** (nach Helper-Erweiterung):
  - a: Target `Ohringerstrasse`, **Nordbank** (`spr.y < closest.y`), Bearing/Flip/`faces_street`/`street_name`, Suffix matcht Tangent (Ohringer am Campus ≈ EW → `_ew`)
  - b: Default dieselben Ohringer-Nord-Asserts; bei Pünten-Fallback Target `Püntenstrasse` und **Südbank** (`spr.y > closest.y`) plus Setback-Band
  - gym: Target `Turnerstrasse`, **Ostbank** (`spr.x > closest.x` = bestehendes `west_of_road=false`), Turner NS-Stretch → `_ns`
- **`_assert_school_street_prop`:** Birch `west_of_road=true/false` (x-Vergleich) **nicht brechen**. Erweiterung z. B. optionales `bank` `"west"|"east"|"north"|"south"` **oder** `north_of`-Variante, die y vergleicht. Unprefixed-Verbot von Birch-Dateinamen analog auf Rietacker-Basen erweitern wenn der Helper Rietacker prüft. `d < 800` und `d >= need-12` gelten für die **Ziel**-Polyline.
- Optional: `_assert_ns_house_art_not_rotate_of_ew` um die drei Rietacker-Basen ergänzen.
- **Birch S01** bleibt grün (`_assert_birch_campus` + West/Ost-Bank Bachwiesen/Birchstrasse).
- **Ohringen/Kigas:** weiter unprefixed, keine neuen `street_*` Metas Pflicht, `flip_h false` dort unverändert.

### 4. Art (Phase 2 — nur dieser Slice)

Siehe Art-Bedarf. Implementer beauftragt `comic-rettung-art`; danach Alpha-Pipeline + Godot-Import **bevor** Tests `ResourceLoader.exists` erwarten. Ohne die sechs PNGs gibt der Helper `null` zurück (Campus verschwindet).

## Testplan

### Automatisiert

- [ ] `tests/m3_world_landmarks_test.gd`: sechs Rietacker `_ew`/`_ns` existieren; Placement lädt Prefixed (nicht unprefixed)
- [ ] rietacker_a nördlich nächster Ohringerstrasse-y; Distanz im Setback-Band (nicht Iso-only)
- [ ] rietacker_b: Nord von Ohringer **oder** (Fallback) Süd von Pünten im Setback-Band; named Target-Polyline
- [ ] turnhalle_rietacker östlich nächster Turnerstrasse-x; weiter west of campus vs a/b (>800 wu)
- [ ] Rietacker `street_bearing` matcht Ziel-Tangent; Dateisuffix matcht; `faces_street`; `street_side` ±1; `flip_h` zur Curb; `rotation == 0`
- [ ] Cluster-Geometrie: gym west, b nördlich a >400 wu, a+b ost der Halle; GPS-Getter unverändert; Scales 0.65 / 0.625 / 0.65
- [ ] Visual clear / off-road grün (`BUILDING_CLEAR` Paint + bearing street-half); Ohringer `half_w=72` berücksichtigen
- [ ] Birch-S01-Asserts grün (Westbank Bachwiesen, Eastbank Birchstrasse, Prefixed)
- [ ] Ohringen / Kigas: unprefixed Art, keine neuen Facing-Metas Pflicht
- [ ] Optional: NS-Rietacker-Art nicht `ROTATE_90/270` von EW
- [ ] Bei Bugfix: Regressionstest bildet die Repro ab (zuerst rot, nach Fix grün)

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Teleport Campus Rietacker: a/b **nördlich** der **sichtbaren** Ohringerstrasse; a Südfassade zum Band (Ohringerstr. 16); kein Gebäude südlich der Ohringerstrasse
- [ ] Turnhalle am Westcampus, Fassade zur **sichtbaren** Turnerstrasse (nicht iso-Ecke); lange Halle parallel
- [ ] Hof zwischen den drei Trakten; kein Asphalt unter Schul-Paint
- [ ] NS-Trakte aufrecht (Dach oben, Fassade links bzw. nach Flip rechts) — nicht aus EW rotiert
- [ ] Birch unverändert westlich Bachwiesenstrasse; Ohringen/Kigas alte PNGs/Lage — nur visuell spotten, nicht umbauen
- [ ] Bei Bugfix: manuelle Repro-Schritte schlagen nach Fix nicht mehr fehl

## Art-Bedarf

- [ ] Keine neuen Assets
- [x] Neue Grafiken/Animationen → Subagent `comic-rettung-art`

Details (nur Campus **Rietacker**, Style **C — Comic-Rettung**):

| Datei | Rolle |
|-------|--------|
| `assets/art/landmark_schulhaus_rietacker_a_ew.png` | Schulhaus 1933, Ohringerstr. 16, EW |
| `assets/art/landmark_schulhaus_rietacker_a_ns.png` | dasselbe, NS |
| `assets/art/landmark_schulhaus_rietacker_b_ew.png` | kleiner 1-geschossiger NE-Trakt, EW |
| `assets/art/landmark_schulhaus_rietacker_b_ns.png` | dasselbe, NS |
| `assets/art/landmark_turnhalle_rietacker_ew.png` | Sporthalle Turnerstr. 2, lange E–W-Halle, EW |
| `assets/art/landmark_turnhalle_rietacker_ns.png` | dasselbe, NS |

- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` (**nur** Haus–Strasse-Layout, keine Maße/Kamera) **plus** Street View / Maps **Ohringerstrasse 16** und **Turnerstrasse 2**. Unprefixed `landmark_schulhaus_rietacker_{a,b}.png` / `landmark_turnhalle_rietacker.png` als Farb-/Masse-Refs, nicht als Iso-Diamant-Vorlage für Facing. Proportionen aus C-Refs und bestehenden Style-C-Schul-Sprites, nicht aus der Iso-Karte.
- Silhouette (Art, **nicht** Dateisuffix): **a** 1933er Giebel, tan, Rundbogenfenster, zentraler Eingang, ~33 m N–S; **b** kleiner 1-geschossiger Giebel, nicht größer als a; **gym** lange E–W-Halle ~48 m. Dateisuffix kommt von der **Strassen-Tangent**, nicht von der OSM-Gebäudeachse (a an EW-Ohringer → oft `_ew`; gym an NS-Turner → oft `_ns`).
- **EW:** lange Fassade + Tür am Canvas-**BOTTOM**. **NS:** aufrecht, Dach **TOP**, lange Fassade + Tür an der **linken** vertikalen Kante. **Niemals** `_ns` aus `_ew` per `ROTATE_90`/`270`.
- Kein Asphalt in die PNG; Fußkante frei. Cel + dicke `#1A1A1A`-Kontur; kein 3D-Plastik.
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün) → `godot --headless --path . --import`.
- Unprefixed Legacy-PNGs nicht löschen müssen; nicht mehr im Rietacker-Placement verwenden.
- **Nicht** in diesem Slice: Birch, Ohringen, Kigas, Häuser.

## Akzeptanzkriterien

- [ ] Repro + RCA erledigt (Rietacker nördlich sichtbarer Ohringerstrasse / Turnhalle ost von Turner; Ursache = Helper nicht verdrahtet + Iso-Art + kein Flip)
- [ ] Drei Props über `_add_school_street_prop` (kein zweiter Helper); Ziel a→Ohringer Nord, gym→Turner Ost; b Ohringer Nord oder dokumentierter Pünten-Fallback im Setback-Band
- [ ] RoadKit default unverändert; Extend nur bei Need; kein Ohringer-Durchstich durch den Hof; keine Südseite-Klappung
- [ ] Sechs Style-C `_ew`/`_ns` Rietacker-Assets; Placement nutzt sie; `rotation == 0`; Mults 1.30 / 1.25 / 1.30
- [ ] Cluster-Relativlage und GPS-Getter gehalten; Scales 0.65 / 0.625 / 0.65
- [ ] Tests grün inkl. Nord/Ost-Bank / Bearing / Flip / REQUIRED_ART-Paare; Birch S01 grün; Ohringen/Kigas ohne neue Facing-Pflicht
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass
