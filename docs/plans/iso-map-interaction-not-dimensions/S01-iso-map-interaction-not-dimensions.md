# Plan: iso-map-interaction-not-dimensions / Slice S01

**Status:** Playtest / Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-11  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/iso-map-interaction-not-dimensions/INDEX.md`  
**Slice-Datei:** `docs/plans/iso-map-interaction-not-dimensions/S01-iso-map-interaction-not-dimensions.md`  
**Hängt ab von:** —

Nur der **Feature-Schritt**. Plan, Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

## Ziel

Prozess- und Style-C-Dokumente behandeln `docs/design-refs/c-iso-city-map.png` nur noch als Moodboard dafür, **wie Häuser und Strassen zusammenwirken**: Bebauung **entlang** der Straßenbänder, Strassen als **lesbare Korridore zwischen Häusern**. Das Bild bleibt in `reference_image_paths` für Welt/Karte/Häuser/Landmarken verdrahtet (wie v0.24.4). **Nicht** aus diesem Bild übernehmen: Blockmasse, Kamerawinkel, chunky Spielzeugstadt-Maßstab, Gebäude-/Straßen-/Spielergröße. Größe und Proportionen kommen von `c-umgebung.png`, `c-basis.png` und den **bestehenden** Style-C-Assets (vor der Iso-Karten-Fehldeutung).

## Scope

### In

- Wording-Korrektur der **lebenden** Art-Prozess-Dateien (kein PNG, kein Godot-Maßstab):
  - `.cursor/agents/comic-rettung-art.md`
  - `.cursor/rules/comic-rettung-art.mdc`
  - `docs/STYLE-BIBLE-C.md` (Absatz **Iso-Stadt-Karte**, Tabellenzeile nur falls die Rollenbezeichnung „Orientierung“ irreführt)
  - `docs/ENTWICKLUNGSABLAUF.md` (Iso-Map-Erwähnung in Phase 2)
  - `docs/design-refs/c-iso-city-map.source.md`
- Optional: `.cursor/agents/feature-implementer.md` **nur**, wenn dort Iso-Karte als Maßstab/Kamera/Größe genannt wird (Stand Plan: **kein Treffer** — dann unverändert lassen)
- Bildpfad und Pflicht, `c-iso-city-map.png` **weiter** in `GenerateImage` → `reference_image_paths` zu übergeben (zusammen mit `c-umgebung` / `c-basis`, nie statt C)
- Prompts/Docs explizit: Interaktion Haus–Strasse **ja**; Maße/Proportionen aus `c-umgebung`, `c-basis`, bestehenden C-Assets

### Nicht

- Spawn-Kamera / Zoom 0.22 → 0.9 (`S02`)
- `c-iso-city-map.png` neu laden, umbenennen oder regenerieren
- Irgendwelche `assets/art/`-PNGs (Landmarken, Dächer, Häuser, Tiles) neu erzeugen
- Feldmaß 5,3 m / 100 wu, `FIELD_WU`, `UNITS_PER_METER`
- Game-SCALE (`PROP` / `SCHOOL` / `LANDMARK` / `SPRITE`)
- Häuser setzen, Housing, Rasterzellen, RoadKit-Geometrie
- Historische Slice-Files unter `docs/plans/art-ref-isometric-city-map/` umschreiben (erledigte Aufgabe; Korrektur nur in den **aktuellen** Agent/Bible/Regel-Texten)
- Landmark-Satz „chunky comic silhouettes“ in `comic-rettung-art.md` (Street-View-Stylize, **nicht** Iso-Blockmasse) — nur anfassen, wenn er Iso-Karten-Maßstab meint
- Stil A/B, `docs/KONZEPT.md`, `docs/DESIGN-VORSCHLAEGE.md`

## Systeme

Art-Prozess: Style-Bible C, Subagent `comic-rettung-art`, Cursor-Regel Art-Delegation, Phase-2-Hinweis in `ENTWICKLUNGSABLAUF.md`, Quellen-Sidecar der Ref. Kein Runtime-Code, keine Godot-Scenes.

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Prozess-Feature: Fehldeutung in Docs/Agent-Prompts, kein Runtime-Bug)

## Technische Schritte

1. **`docs/STYLE-BIBLE-C.md`** — Absatz **Iso-Stadt-Karte** umschreiben. Heute: „¾-Iso-Übersicht, chunky Gebäude, … Übernehmen: Blockmasse, Rasterlesbarkeit …“. Neu sinngemäß:
   - **Übernehmen:** Häuser sitzen an Straßenbändern; Strassen sind klare, lesbare Korridore zwischen der Bebauung; Stadtstruktur bleibt als Karte lesbar.
   - **Nicht übernehmen:** Blockmasse, Kamerawinkel, chunky Toy-City-Klötze, Gebäude-/Straßen-/Spielergröße oder sonstige Proportionen aus diesem Bild; fotorealistisches 3D, AR-32-Rohlook, weiche Plastik-Städte, Verzicht auf Kontur/Cel.
   - **Proportionen:** `c-umgebung.png`, `c-basis.png`, bestehende Style-C-Sprites. Charaktere weiter Mech-/Fahrzeug-Refs.
   - Tabellenzeile darf „Iso-Stadt / Karte / Gebäude“ bleiben; Rolle von „Orientierung (Masse/Kamera)“ auf **Haus–Strasse-Interaktion** schärfen, ohne die Datei aus der Primärquellen-Tabelle zu streichen.
2. **`.cursor/agents/comic-rettung-art.md`**
   - Locked-style-Tabelle: Rolle z. B. „Iso city / street–house layout (not scale)“.
   - Workflow Schritt 2: „orients layout and block mass“ ersetzen durch Interaktion-only; explizit: Größe/Kamera **nicht** aus der Iso-Karte.
   - Schritt 4 (Prompts): bei Welt/Karte/Häusern/Landmarken im Prompt festhalten: street–house layout from iso map; size/proportions from `c-umgebung`, `c-basis`, existing Style C assets.
   - Schritt 5: `c-iso-city-map.png` **weiter** in `reference_image_paths` (mit umgebung/basis).
   - Godot-oriented output: „same ¾-iso readability as `c-iso-city-map.png` (chunky blocks, street ribbons)“ ersetzen: ¾-Kamera und Sprite-Maß weiter **C-Refs** (`c-umgebung` / `c-basis` / bestehende Assets); Iso-Karte nur Bänder + Bebauung entlang der Achse.
   - Handoff „References used“: Datei weiter listen, plus Kurzhinweis Interaktion ≠ Masse.
3. **`.cursor/rules/comic-rettung-art.mdc`** — Punkt 2: „Iso-Stadt-Orientierung: Blockmasse, Straßenbänder, lesbare Karte“ ersetzen durch Haus–Strasse-Interaktion; Proportionen aus `c-umgebung`/`c-basis`/bestehenden C-Assets; Bild **weiter** mitgeben; Stil C führend.
4. **`docs/ENTWICKLUNGSABLAUF.md`** — Phase-2-Satz mit `c-iso-city-map.png`: nicht nur „für Welt/Karte/Gebäude“ nennen, sondern **Interaktion Haus–Strasse**, nicht Masse/Kamera/Größe.
5. **`docs/design-refs/c-iso-city-map.source.md`** — Rolle/Motiv: Moodboard für **wie** Häuser an Strassen sitzen; explizit **kein** Maßstab, keine Kamera-Vorlage, keine Sprite-Größe. Stil C bleibt verbindlich. URL/Original unverändert.
6. **`feature-implementer.md`:** `rg iso-city-map|Blockmasse` — bei Treffer gleichen Satz nachziehen; sonst keine Änderung.
7. Keine `GenerateImage`-Aufrufe, keine Diffs unter `assets/art/`, keine Kamera-/SCALE-/Feldmaß-Änderungen.

## Testplan

### Automatisiert

- [x] `rg` in den fünf Pflicht-Dateien: `c-iso-city-map` kommt weiter vor; `reference_image_paths` / „zusammen mit `c-umgebung`/`c-basis`“ bleibt für Welt/Karte/Häuser
- [x] In denselben Dateien (Iso-Kontext): **kein** Copy-Ziel „Blockmasse“, „chunky blocks“ als Maßstab, Kamera/Zoom aus der Iso-Karte, Spieler-/Gebäudegröße aus `c-iso-city-map`
- [x] Positiv: Formulierungen zu Straßenbändern / Korridoren / Bebauung entlang der Achse **und** Proportionen aus `c-umgebung` / `c-basis` / bestehenden C-Assets
- [x] `git diff -- assets/art/` leer; `c-iso-city-map.png` Binary unverändert
- [x] Bestehende Suite unverändert grün (`./scripts/run_tests.sh`) — **keine** neuen GDScript-Tests (Docs-only); Python-Check `tests/iso_map_interaction_docs_test.py`

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error (keine Gameplay-Änderung in diesem Slice)
- [x] Reviewer kann anhand Bible + Art-Agent sagen: Iso-Karte = Haus–Strasse-Layout; Größe = C-Umgebung/Basis/bestehende Assets
- [x] Kein sichtbarer Art-/Kamera-Wechsel gegenüber Pre-Slice (Zoom bleibt S02)

## Art-Bedarf

- [x] Keine neuen Assets
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  
  Details: **Keine** Generierung in S01. Nur Prozess-Wording. Spätere Art-Slices nutzen weiterhin `c-iso-city-map.png` in `reference_image_paths`, aber mit der korrigierten Prompt-Regel.

## Akzeptanzkriterien

- [x] Grenzen eingehalten: kein S02-Zoom, keine PNG-Regen, kein Feldmaß/SCALE/Housing
- [x] Fünf Pflicht-Dateien (plus Implementer nur bei Bedarf) beschreiben Iso-Karte als Haus–Strasse-Interaktion, nicht als Dimensions-/Kamera-Vorlage
- [x] `c-iso-city-map.png` bleibt Pflicht-Ref in `reference_image_paths` für Welt/Karte/Häuser/Landmarken, zusammen mit `c-umgebung`/`c-basis`
- [x] Prompts/Docs weisen Größe/Proportionen an `c-umgebung`, `c-basis`, bestehende Style-C-Assets
- [x] Automatisierte Checks (rg + leeres `assets/art/`-Diff) grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass (Smoke)
