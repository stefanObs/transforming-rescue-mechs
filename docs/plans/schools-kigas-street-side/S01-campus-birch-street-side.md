# Plan: schools-kigas-street-side / Slice S01

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-15  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/schools-kigas-street-side/INDEX.md`  
**Slice-Datei:** `docs/plans/schools-kigas-street-side/S01-campus-birch-street-side.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt** (Campus-Cluster + sichtbare Strasse davor; Helper für die Folge-Slices). Plan nötig (Bug → Phase-0 RCA + Art + Multi-System: RoadKit-Polyline, Placement-Helper, Style-C `_ew`/`_ns`). Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Ziel

Campus **Birch** (Schulhäuser a/b + Turnhalle) sitzt **westlich** der sichtbaren Bachwiesenstrasse, Fassade zur Strasse (Ostfassade Richtung Bahnhof). Sprites sind street-aligned (`_ew`/`_ns` + seitenbewusstes `flip_h`), nicht mehr Iso-Diamant neben den Häusern. Der Shared Placement-Helper (Bearing aus **Ziel**-Strassen-Tangent, GPS-Bank behalten) wird hier verdrahtet, damit S02–S04 ihn wiederverwenden können — Nachbar-Campi bleiben in diesem Slice auf alten unprefixed PNGs und altem Placement.

## Scope

### In

- Shared Placement-Helper in `_add_building_prop` / Schul-Pfad (Wrapper bevorzugen, kein neues globales System): Bearing-Pick aus der Tangent der **Ziel-Strasse** (`|tx| >= |ty|` → `ew`, sonst `ns`); GPS-Strassenseite behalten (nicht `+perp` durch die Fahrbahn laufen); `flip_h` so dass die autorisierte Tür zur Curb zeigt; Setback mit house-ähnlicher street-facing half (nicht isotropes `BUILDING_CLEAR.y / 2` als einzige Strassenachse). Häuser nutzen `HOUSE_CLEAR` 0.70/0.55; Landmark-Paint-Clear darf `BUILDING_CLEAR` 0.95/0.88/40 bleiben.
- RoadKit: **nur** `Bachwiesenstrasse` und/oder `Birchstrasse` in `data/seuzach_roads.json` **bis an den Campus verlängern** (bestehende Vertices behalten; Punkte anfügen/voranstellen bzw. am campus-nahen Stretch ergänzen — nicht das ganze Netz neu zeichnen). Heute reicht Bachwiesenstrasse nicht bis `schulhaus_birch_a` (≈1425 wu / ~75 m Lücke). Ziel: sichtbares N–S- (oder lokales) Band **östlich von birch_a**; Campus bleibt Westbank. birch_a muss innerhalb ~eines House-Setbacks am neuen Bachwiesenstrasse-Segment sitzen.
- Drei Birch-Props: GPS-Bank **west** of Bachwiesenstrasse halten; Cluster-Relativlage beibehalten — a ost/bahnhofseitig von b (>400 wu), Turnhalle nördlich von a/b (>200 wu). GPS-Getter in `seuzach_geo.gd` bleiben; kleines Curb-Setback zur neuen Ribbon ist OK (720-wu-Test für Birch straffen).
- Style-C `_ew`/`_ns` **nur für Birch** via `comic-rettung-art`; `_ns` nie aus `_ew` rotieren (`ROTATE_90`/`270` verboten); Fassade EW unten / NS links vertikal; `rotation == 0`. Unprefixed `landmark_schulhaus_birch_*.png` / `landmark_turnhalle_birch.png` dürfen als Legacy auf Disk bleiben; Placement muss `_ew`/`_ns` laden.
- Per-Building `SCHOOL_SCALE`-Mults unverändert: `BIRCH_A_SCALE_MULT` 1.20, `BIRCH_B_SCALE_MULT` 1.20, `BIRCH_TURNHALLE_SCALE_MULT` 1.00.
- Tests in `tests/m3_world_landmarks_test.gd`: REQUIRED_ART Birch-Paare; Birch `street_side` / `street_bearing` / `faces_street`; Westbank Bachwiesenstrasse; Distanz zur Polyline in engem Band; visual/off-road clear; `rotation == 0`; Rietacker/Ohringen/Kigas weiter unprefixed und **keine** neuen Facing-Metas.

### Nicht

- Campus Rietacker (S02), Ohringen + Kiga Ohringen (S03), Seuzach-Kigas Bachtobel/Weid/Schneckenwiese (S04)
- Wohnhäuser / Housing-Art (`house_street_*`), Bahnhof, Badi, Civic `restore-stripped-landmarks`
- RoadKit-Gesamtnetz neu zeichnen; globales `SCHOOL_SCALE`; `Sprite2D.rotation` als Facing
- GPS auf die **Ostseite** der Bachwiesenstrasse klappen
- `HOUSE_CLEAR_*` / Housing-Nudge-Reihenfolge ändern (außer bewusst geteilte Helper, deren Housing-Call-Sites unverändert bleiben)

## Systeme

| System | Rolle in diesem Slice |
|--------|------------------------|
| `data/seuzach_roads.json` — `Bachwiesenstrasse` (class=local, `half_w` = `ROAD_HW_LOCAL` 36) | Polyline bis Campus verlängern; N–S östlich von birch_a |
| `data/seuzach_roads.json` — `Birchstrasse` | Nur soweit nötig: West-Campus-Band westlich von gym/b, ohne Asphalt unter den Füßen |
| `scripts/world_sandbox.gd` — `_place_school_clusters`, `_add_building_prop`, Housing-Facing-Helpers | Wrapper: Ziel-Strasse, Bearing-Datei, GPS-seitiges Nudge, `flip_h`, Metas |
| `scripts/seuzach_geo.gd` | GPS-Getter **unverändert** (`birch_schulhaus_{a,b}_world`, `birch_turnhalle_world`) |
| `assets/art/landmark_schulhaus_birch_{a,b}_{ew,ns}.png`, `landmark_turnhalle_birch_{ew,ns}.png` | Style-C street-aligned; Iso-Diamant-Legacy bleibt ungenutzt |
| `comic-rettung-art` + `process_art_alpha.py` / `verify_art_alpha.py` + `godot --import` | Phase-2 Art nur dieser Campus |
| `tests/m3_world_landmarks_test.gd` | REQUIRED_ART-Paare, Westbank, Bearing/Flip, Cluster, keine Facing-Regression S02–S04 |

## Repro & RCA (Pflicht bei Typ = Bugfix)

Vor Phase 2 ausfüllen. **Repro bestätigt** (Code + RoadKit-JSON + GPS, 2026-08-15).

### Reproduktion

- [x] Repro bestätigt
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. `world_sandbox` laden. 2. Zu Campus Birch teleportieren / `SeuzachGeo.birch_schulhaus_a_world()` (~15185, -3714). 3. Bachwiesenstrasse-Ribbon und die drei Schul-Sprites vergleichen (Häuser daneben als Referenz: `house_street_*_{ew,ns}`, seitenbewusstes Flip). |
| Erwartet | Drei Trakte **westlich** der sichtbaren Bachwiesenstrasse; Ostfassade von a zur Strasse/Bahnhof; lange Fassade parallel zum Band (`_ew`/`_ns`); Hof zwischen a/b/Turnhalle; Sprites nicht iso- verdreht neben den Häusern. |
| Tatsächlich | Campus sitzt ~75 m neben der sichtbaren Ribbon (birch_a ≈1425 wu von Bachwiesenstrasse). Sprites sind Iso-Diamant (`landmark_schulhaus_birch_a.png` etc.), `flip_h=false`, Clearance `BUILDING_CLEAR` 0.95/0.88. Wirkt falsch platziert / an der falschen Seite. |
| Umgebung | Godot 4, Scene `world_sandbox`, Branch aktuell; Input n/a (Placement ist deterministisch). |
| Evidenz | GPS (`SeuzachGeo`, +X Ost +Y Süd): birch_a (15185, -3714) OSM 47.5352696, 8.7368319 — Soll **west** of Bachwiesenstrasse, Ostfassade Richtung Bahnhof; birch_b (14391, -3462); birch_gym (14368, -4146) nördlich von a/b. Bachwiesenstrasse in `data/seuzach_roads.json` (class=local, 4 Punkte) erreicht den Campus nicht: `(15306.1, -1001.9) → (16027.9, -2348.2) → (16520.9, -3170.9) → (16769.6, -3502.4)`. Closest zu birch_a ≈ (16408, -2982), d≈1425 wu. Polyline-BBox x=15306..16770 y=-3502..-1002. Nächste andere named road: Stadlerstrasse d≈994 (teilt den Endpunkt `(16769.6, -3502.4)`). Birchstrasse (7 Punkte) BBox max x=14388, erreicht birch_a (x=15185) nicht; Gym nearest Birchstrasse d≈984, Ostbank. Code: `_place_school_clusters` lädt unprefixed PNGs, `flip_h` Default false; `_add_building_prop` nudgt nur wenn Clear failt. |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) `_nudge_off_named_roads` schiebt Schulen über die Fahrbahn / auf die falsche Seite. (2) Iso-Diamant-Art ohne `_ew`/`_ns` liest schief neben street-aligned Häusern. (3) Bachwiesenstrasse-/Birchstrasse-Polylines enden vor dem Campus → sichtbare Lücke, Schule „hängt“ im Gras. (4) `flip_h` fehlt / Tür zeigt von der Curb weg. (5) GPS-Konstanten in `seuzach_geo.gd` falsch. (6) Housing-Pfad (`HOUSE_CLEAR`, Bearing) ist kaputt und steckt Schulen an. |
| Bestätigte Ursache | **(3) + (2) + fehlendes Street-Facing-Wiring.** Bachwiesenstrasse endet am Stadlerstrasse-Knoten ~1,4 km-wu östlich/nördlich der Schul-Füße — die Ribbon liegt nicht vor dem Campus. Schulen nutzen Iso-Diamant, `flip_h=false`, kein `street_bearing`/`faces_street`; `_add_building_prop` kennt kein Ziel-Strassen-Bearing. Clearance bleibt isotrop `BUILDING_CLEAR.y/2`. |
| Nicht die Ursache | **(1) Nudge als Haupt-Cross-Street-Bug:** GPS-Füße clearen heute Asphalt (`_sprite_clears_named_roads` true → `_nudge_off_named_roads` gibt `pos` unverändert zurück). Tests erlauben bereits 720 wu GPS-Drift — das kaschiert die 1425-wu-Lücke nicht als Fail, erklärt aber nicht die falsche Seite visuell. **(5)** GPS-Konstanten matchen OSM (Tests asserten LAT/LON + Offsets vs `birch_world()`). **(6)** Housing-Pfad ist street-aligned und side-aware; Schulen teilen ihn nicht. |
| Fix-Richtung | Polyline Bachwiesenstrasse (und Birchstrasse nur soweit nötig) OSM-nah bis Campus verlängern, **ohne** bestehende Vertices zu löschen. Shared Helper: Bearing von der **Ziel**-Tangent, GPS-Bank, Flip zur Curb, street-axis Setback. Birch lädt `_*_{ew\|ns}.png`. Style-C-Art nur Birch, 1966-Flachdach. |
| Risiken | Zu weit westlich gesetztes N–S-Band → Asphalt durch den Hof / unter a. Zu weit östlich → Lücke bleibt. `+perp`-first Nudge nach dem Extend kann a auf die Ostbank schieben — deshalb **zuerst weg von der Strasse** (GPS-Seite). Isotropes `BUILDING_CLEAR.y/2` nach dem Extend würde GPS nicht mehr clearen und hart wegschieben — street-facing half nutzen. Birchstrasse-Extend darf gym/b nicht auf Asphalt setzen. S02–S04 dürfen durch den Helper nicht plötzlich `_ew`/`_ns` oder Facing-Metas verlangen. |

- [x] RCA dokumentiert und reviewed (kurz vom Hauptagenten ok)

## Technische Schritte

### 1. RoadKit — Bachwiesenstrasse (Pflicht)

Bestehende 4 Punkte **behalten und in dieser Reihenfolge lassen**:

```
(15306.1, -1001.9) → (16027.9, -2348.2) → (16520.9, -3170.9) → (16769.6, -3502.4)
```

Letzter Punkt = Knoten mit Stadlerstrasse. Nicht das restliche Netz anfassen.

**Zielgeometrie (verifizieren gegen OSM: Strasse östlich der Schule, Schule westlich):** ein sichtbares N–S-Lokalband knapp **östlich** von birch_a.

| Constraint | Soll |
|------------|------|
| N–S-x | ≈ **15380–15500** (Beispiel **15440–15460**) |
| y-Spanne | gym → b, etwa **-4250 … -3360** |
| Westbank | `birch_a.x` < closest-point-x auf Bachwiesenstrasse |
| Abstand birch_a → Segment | House-Setback-Band: `half_w` (36) + street-facing-half + edge — **nicht** 1425 wu |
| Campus nicht übermalen | neue Segmente mit x **> birch_a.x + ~150**; nicht zwischen a und b bei x < ~15200 durch den Hof |

**Konkrete Extra-Vertices** (wu, +X Ost +Y Süd; Implementer ±50 wu im Playtest feinjustieren, Reihenfolge an den letzten bestehenden Punkt **anhängen**, kein Double-Back auf derselben x-Achse als Spitze):

```
# bestehend … (16769.6, -3502.4)
(15920.0, -3480.0)   # west vom Stadler-Knoten, östlich des Campus
(15460.0, -3480.0)   # auf die N–S-Linie östlich von birch_a (x=15185)
(15460.0, -4250.0)   # nach Norden an gym vorbei (gym y≈-4146)
```

Connector bei y≈-3480 bleibt **östlich** von a; b (14391, -3462) liegt weit westlich dieses Segments (kein Hof-Asphalt). Süd-Coverage von b kommt über denselben x-Wert am Connector (b nur ~20 wu südlich von y=-3480, aber ~1070 wu west — Birchstrasse ist dort die West-Strasse).

Nach dem Edit: JSON-Polyline laden, Distanz birch_a → Bachwiesenstrasse messen; Assert-Ziel «enges Band», nicht 1425.

### 2. RoadKit — Birchstrasse (nur wenn nötig)

Gym/b sollen entlang einer **West-Campus-Strasse** sitzen, ohne auf Asphalt zu stehen. Heute: Birchstrasse max x=14388, gym nearest d≈984.

Wenn nach Schritt 1 gym/b die **Bachwiesenstrasse** als nearest-any-road nehmen würden oder visuell ohne West-Band dastehen: bestehende 7 Vertices behalten; am campus-nahen Stretch **zusätzliche** Punkte (Campus liegt mittig in der Polyline — Append am Südende würde ein U erzeugen). Sinnvoller Insert **nach** `(13128.7, -3976.6)`, ohne bestehende Punkte zu löschen, Beispiel:

```
# bestehend (13128.7, -3976.6)
(14220.0, -4100.0)   # ostwärts, westlich von gym x=14368
(14220.0, -3400.0)   # entlang Westcampus (b y≈-3462)
# bestehend (14235.9, -5868.7) … Rest unverändert
```

Nicht extenden, wenn gym/b mit **expliziter Ziel-Strasse** `Birchstrasse` schon im Setback-Band westlich der Füße liegen und nicht auf Asphalt sitzen. Nie GPS von gym/b auf die Westseite von Birchstrasse klappen (Campus = Ostbank von Birchstrasse = Westbank von Bachwiesenstrasse).

### 3. Shared Helper (Housing spiegeln, Schul-Wrapper)

Bestehende Bausteine wiederverwenden, nicht ein zweites Facing-System:

- `_street_bearing_from_tangent` — `|tx| >= |ty|` → `"ew"` sonst `"ns"`
- `_housing_facing_on_corridor` (oder extrahiert `_street_facing_on_road(pos, target_road)`) — `side` / `perp` / `bearing` aus Pos vs **dieser** Polyline
- Door-Dirs wie Housing: NS Tür W `(-1,0)` / E `(1,0)`; EW Tür SW `(-1,1)` / SE `(1,1)`; `flip = door_flip.dot(toward_road) > door_no_flip.dot(toward_road)`
- `_house_street_half(clear, bearing)` — NS → `clear.x/2` (linke Fassade), EW → `clear.y/2` (untere Fassade)

**Bevorzugt:** ` _add_building_prop` um optionale Ziel-Strasse + street-aligned Datei-Wahl erweitern **oder** schmaler Wrapper z. B. `_add_school_street_prop(base_file_without_suffix, pos, scale, metas, node_name, target_road_name)`. Rietacker/Ohringen/Kigas weiter über den alten Pfad (unprefixed, `flip_h=false`, kein Facing-Meta-Zwang).

Ablauf Birch (nach Helper):

1. Ziel-Strasse: **a → Bachwiesenstrasse**; **b + gym → Birchstrasse**.
2. Tangent am nächsten Segment der **Ziel**-Polyline (nicht nearest-any-named-road).
3. Datei: `landmark_schulhaus_birch_a_{ew|ns}.png` bzw. `_b_` / `landmark_turnhalle_birch_{ew|ns}.png`.
4. GPS-Seite halten: `away = pos - closest`; Setback entlang `away` (zur Curb hin, nie durch die Fahrbahn). `need ≈ half_w + street_facing_half(BUILDING_CLEAR-Größe, bearing) + BUILDING_CLEAR_EDGE_MARGIN` (+ optional kleines Slack analog `HOUSE_CURB_SLACK` 6 — **keine** neuen globalen Clear-Fracs, `HOUSE_CLEAR_*` unangetastet).
5. Nudge: **erste** Richtung = weg von der Strasse (GPS-`away`), nicht immer `+perp`. `_sprite_clears_named_roads` / `_nudge_off_named_roads`: wenn `street_bearing` gesetzt, street-half wie Häuser (Achse), Paint-AABB weiter `BUILDING_CLEAR_*`. Housing-Call-Sites unverändert (`house_mode=true`).
6. Metas **zusätzlich** zu bestehenden `landmark_id` / `school_cluster` / `district` / `poi_type`: `street_side` (±1), `street_bearing` (`ew`/`ns`), `faces_street` true, sinnvoll `street_name`.
7. `Sprite2D.rotation` bleibt 0; Scale = `SCHOOL_SCALE * BIRCH_*_SCALE_MULT`.

`seuzach_geo.gd` Getter und LAT/LON-Konstanten nicht ändern.

### 4. Tests (`tests/m3_world_landmarks_test.gd`)

Regression bildet die Repro ab (zuerst rot, nach Fix grün):

- **REQUIRED_ART:** die sechs Birch-Paare Pflicht. Unprefixed `landmark_schulhaus_birch_{a,b}.png` dürfen in REQUIRED/GEO als Legacy-Exists bleiben; `GEO_ART` `landmark_turnhalle_birch.png` darf Legacy bleiben. Placement darf unprefixed **nicht** mehr laden.
- **`_assert_birch_campus`:** Westbank `birch_a.x < closest Bachwiesenstrasse x`. Distanz birch_a → Bachwiesenstrasse in engem Band (`half_w + setback`, nicht 1425). 720 wu GPS-Drift darf als äußere Schranke bleiben, **zusätzlich** Side/Bearing; für Birch straffen (Setback-Größenordnung, nicht 720 als einziges Distanzmaß).
- Texture-Pfad / Dateiname endet auf `_{street_bearing}.png`; `street_bearing` matcht Ziel-Tangent (`|tx|>=|ty|` → ew).
- `flip_h` matcht Door-vs-`toward_road` (wie Housing).
- `faces_street == true`, `street_side` ±1, `rotation == 0`.
- Cluster: a.x > b.x + 400; gym.y < min(a.y,b.y) - 200; GPS-Getter-Konstanten unverändert; Scales 0.60 / 0.60 / 0.50.
- Visual/off-road: `_street_half_for` für Birch mit `street_bearing` achsenbewusst (nicht pauschal `aabb.size.y/2` wenn Meta gesetzt); weiter `BUILDING_CLEAR` 0.95/0.88/40 für Landmark-AABB.
- Optional: NS-Birch-Art nicht `ROTATE_90/270` von EW (analog `_assert_ns_house_art_not_rotate_of_ew`, nur Birch-Basen).
- **Nicht** in diesem Slice: Rietacker/Ohringen/Kigas REQUIRED_ART unprefixed; keine neuen `street_*` Metas required; `flip_h false` dort unverändert.

### 5. Art (Phase 2 — nur dieser Slice)

Siehe Art-Bedarf. Implementer beauftragt `comic-rettung-art`; danach Alpha-Pipeline + Godot-Import **bevor** Tests `ResourceLoader.exists` erwarten.

## Testplan

### Automatisiert

- [ ] `tests/m3_world_landmarks_test.gd`: sechs Birch `_ew`/`_ns` existieren; Placement lädt Prefixed
- [ ] birch_a westlich nächster Bachwiesenstrasse-x; Distanz im Setback-Band (nicht ~1425 wu)
- [ ] Birch `street_bearing` matcht Ziel-Tangent; Dateisuffix matcht; `faces_street`; `street_side` ±1
- [ ] `flip_h` zur Curb; `rotation == 0`
- [ ] Cluster-Geometrie a östlich b >400 wu, gym nördlich a/b >200 wu; GPS-Konstanten unverändert; Scales unverändert
- [ ] Visual clear / off-road grün (`BUILDING_CLEAR` Paint + bearing street-half)
- [ ] Rietacker / Ohringen / Kigas: unprefixed Art, keine neuen Facing-Metas Pflicht, bisherige flip_h-false-Asserts
- [ ] Bei Bugfix: Regressionstest bildet die Repro ab (zuerst rot, nach Fix grün)

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Teleport Campus Birch: drei Trakte westlich neben **sichtbarer** Bachwiesenstrasse; a Ostfassade zum Band/Bahnhof; lange Fassade parallel (kein Iso-Diamant-Ecke zum Viewer); Hof zwischen den drei Trakten
- [ ] Kein Asphalt unter Schul-Paint; kein Gebäude östlich der Bachwiesenstrasse
- [ ] NS-Trakte aufrecht (Dach oben, Fassade links bzw. nach Flip rechts) — nicht aus EW rotiert
- [ ] Rietacker/Ohringen/Kigas unverändert (alte PNGs, alte Lage) — nur visuell spotten, nicht umbauen
- [ ] Bei Bugfix: manuelle Repro-Schritte schlagen nach Fix nicht mehr fehl

## Art-Bedarf

- [ ] Keine neuen Assets
- [x] Neue Grafiken/Animationen → Subagent `comic-rettung-art`

Details (nur Campus Birch, Style **C — Comic-Rettung**):

| Datei | Rolle |
|-------|--------|
| `assets/art/landmark_schulhaus_birch_a_ew.png` | Primarschulhaus 2 (Bachwiesenstr. 2), EW |
| `assets/art/landmark_schulhaus_birch_a_ns.png` | dasselbe, NS |
| `assets/art/landmark_schulhaus_birch_b_ew.png` | Trakt 2b, EW |
| `assets/art/landmark_schulhaus_birch_b_ns.png` | dasselbe, NS |
| `assets/art/landmark_turnhalle_birch_ew.png` | Turnhalle 2c, EW |
| `assets/art/landmark_turnhalle_birch_ns.png` | dasselbe, NS |

- Refs: `docs/design-refs/c-umgebung.png`, `c-basis.png`, `c-iso-city-map.png` (**nur** Haus–Strasse-Layout, keine Maße/Kamera) **plus** Street View / Maps Bachwiesenstrasse **2 / 2b / 2c**. Proportionen aus C-Refs und bestehenden Style-C-Schul-Sprites, nicht aus der Iso-Karte.
- OSM-Masse (Art-Silhouette, **nicht** Dateisuffix): a leicht N–S, b E–W, gym N–S; **1966-Flachdächer**, keine Giebel-Wohnhäuser. Dateisuffix kommt von der **Strassen-Tangent**, nicht von der OSM-Gebäudeachse.
- **EW:** lange Fassade + Tür am Canvas-**BOTTOM**. **NS:** aufrecht, Dach **TOP**, lange Fassade + Tür an der **linken** vertikalen Kante. **Niemals** `_ns` aus `_ew` per `ROTATE_90`/`270`.
- Kein Asphalt in die PNG; Fußkante frei. Cel + dicke `#1A1A1A`-Kontur; kein 3D-Plastik.
- Pipeline: `python3 scripts/process_art_alpha.py` → `python3 scripts/verify_art_alpha.py` (grün) → `godot --headless --path . --import`.
- Unprefixed Legacy-PNGs nicht löschen müssen; nicht mehr im Birch-Placement verwenden.
- **Nicht** in diesem Slice: Rietacker, Ohringen, Kigas, Häuser.

## Akzeptanzkriterien

- [ ] Repro + RCA erledigt (Birch westlich sichtbarer Bachwiesenstrasse; Ursache = fehlende Ribbon-Reichweite + Iso-Art + kein Street-Facing)
- [ ] Bachwiesenstrasse (und Birchstrasse nur bei Need) verlängert; bestehende Vertices erhalten; Campus Westbank; birch_a im Setback-Band
- [ ] Shared Helper verdrahtet für Birch (Ziel-Tangent, GPS-Seite, Flip, street-half); S02–S04 Call-Sites unverändert
- [ ] Sechs Style-C `_ew`/`_ns` Birch-Assets; Placement nutzt sie; `rotation == 0`; Mults 1.20 / 1.20 / 1.00
- [ ] Cluster-Relativlage und GPS-Getter gehalten
- [ ] Tests grün inkl. Westbank / Bearing / Flip / REQUIRED_ART-Paare; Nachbarn ohne neue Facing-Pflicht
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass
