# Plan: faster-dev-loop / Slice S01

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-12  
**Owner:** feature-planner  
**Parent-INDEX:** `docs/plans/faster-dev-loop/INDEX.md`  
**Slice-Datei:** `docs/plans/faster-dev-loop/S01-pack-and-dedup-dev-loop.md`  
**Hängt ab von:** —

Neue Aufgaben: INDEX + kurze Feature-Stubs vom `task-slicer`. Dieses Template füllt `feature-planner` **in dieselbe Slice-Datei** (Tests/Review/Git bleiben der Ablauf, keine Extra-Slices). Alte flache `docs/plans/<name>.md` nur historisch.

## Ziel

Den Entwicklungsablauf so anpassen, dass der Slicer **ca. 2× so viel** zusammengehörige, spieler-sichtbare Arbeit in **einen** Slice packt (weniger Plan→Review→Playtest→Git-Schleifen) und **bekannte Doppelarbeit** wegfällt — ohne Code-Review, Playtest, RCA oder Git-pro-Slice für spielsichtbare Arbeit aufzugeben. Agents und Ablauf-Docs sagen dasselbe; eine Docs-Regression sichert Packing/Dedup-Wording und lässt die Iso-Karten-Sätze in `ENTWICKLUNGSABLAUF.md` unangetastet.

## Scope

- In:
  - **2×-Packing** als Slicer-Default: zwei verwandte / zwei zusammengehörige spieler-sichtbare Inkremente pro Slice, wenn sie Systeme teilen und zusammen review-/playtestbar sind
  - **Planner-Skip** bei offensichtlichen Änderungen (Stub hat Feature+In+Nicht)
  - **Playtest ohne Suite-Doppel** + Docs-only-Pfad (kein Godot, kein Art-Alpha)
  - **INDEX-Status nur:** `offen` → `in Arbeit` → `erledigt` (kein Slice-File-Phasen-Churn)
  - Lebende Prozess-Dateien + Plan-Vorlagen + Docs-Regressionstest verdrahtet in `scripts/run_tests.sh`
- Nicht:
  - Godot-Gameplay, Art-PNGs, Kamera, Feldmaß ändern
  - Code-Review oder Playtest für spielsichtbare Slices abschaffen oder zusammenlegen
  - Git-pro-Slice abschaffen; RCA bei Bugs streichen; Implementer-Tests streichen
  - Historische erledigte Slice-Files unter `docs/plans/m3-*` umschreiben
  - Packing und Dedup in zwei Slices trennen
  - Slicer-Beispiele so grob, dass ganze Karte / alle Schulen / ganz Seuzach ein Slice wären

## Systeme

- Prozess-Docs: `docs/ENTWICKLUNGSABLAUF.md`
- Cursor-Rule: `.cursor/rules/entwicklungsablauf.mdc`
- Agents: `task-slicer`, `feature-planner`, `feature-implementer`, `godot-playtester`; `code-reviewer` nur falls noch „ein Haus“/„eine Rasterzelle“ als Default ohne 2×-Regel
- Plan-Vorlagen: `docs/plans/_SLICE.md`, `_SLICE_INDEX.md`, `_TEMPLATE.md`
- Tests: neuer Docs-Regressionstest + `scripts/run_tests.sh`

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Typ = Feature)

## Technische Schritte

1. **`docs/ENTWICKLUNGSABLAUF.md` — Packing (Phase S)**  
   Default-Zuschnitt von „ein Haus / eine Rasterzelle“ auf **zwei verwandte / zwei zusammengehörige** spieler-sichtbare Inkremente pro Slice, wenn Systeme geteilt und gemeinsam review-/playtestbar. Explizit nennen (~2 / zwei verwandte / zwei zusammengehörige). Beispiele: zwei Häuser derselben Strasse; zwei benachbarte Rasterzellen; zwei Kigas desselben Typs; Spawn + sichtbare Strassen als **eine** User-Beschwerde; ein Docs-Thema (Bible+Agent+Regel zusammen). Campus (bereits 3-Gebäude-Cluster) = weiterhin **ein** Slice. Ohringen = eigene Zellen, Slice darf **zwei** verwandte Ohringen-Zellen. Zu groß unverändert: ganze Karte, alles Housing, alle Schulen, ganz Seuzach. **Verboten als Slices** unverändert: Review, Tests, Playtest, Git, RCA, Datei-anlegen vs. verdrahten.

2. **`docs/ENTWICKLUNGSABLAUF.md` — Planner-Skip (Phase 1)**  
   Phase 1 / `feature-planner` **überspringen**, wenn Stub bereits Feature + In + Nicht hat **und** die Änderung offensichtlich ist (Docs-Wording, Konstanten, Single-File). Implementer/Parent darf Testplan/Akzeptanz in dieselbe Datei nachziehen. **Planner behalten** bei Bugs/RCA, art-lastig, Multi-System, unklarem Scope. Mermaid/Flow: optionaler Skip-Pfad dokumentieren, ohne Phase 0/3/4/Git zu streichen.

3. **`docs/ENTWICKLUNGSABLAUF.md` — Playtest-Dedup (Phase 4) + Status**  
   Playtest **läuft nicht** erneut `./scripts/run_tests.sh` oder `verify_art_alpha.py`, wenn Implementer in **diesem** Slice grün gemeldet hat **und** Review keine weiteren Code-/Art-Änderungen verlangt hat. Immer (spielsichtbar): einzigartiger Godot-Smoke + slice-spezifisch visuell. Art-Alpha nur wenn `assets/art` geändert. **Docs-only: kein Godot, kein Art-Alpha** — nur Docs-Tests / Read-through. Fehlt Handoff oder Review hat Fixes verlangt → Implementer re-runs Suite; Playtest skippt doppelte Suite trotzdem, sofern Handoff nach Fix wieder grün ist. INDEX-Status nur: `offen` → `in Arbeit` (Implement-Start) → `erledigt` (nach Pass+Git). Slice-File: kein Phasen-Churn (`Entwurf`/`In Umsetzung`/`Review`/`Playtest`); **Erledigt** nach Pass+Git. Qualitätstore: Code-Review + Playtest getrennt für spielsichtbar; RCA bei Bugs; Git nach jedem Slice; Tests vom Implementer.

   **Iso-Karten-Sätze BEHALTEN** (Regression `iso_map_interaction_docs_test.py`): `c-iso-city-map.png` = Haus–Strasse-Interaktion, **nicht** Masse/Kamera/Größe; Proportionen aus `c-umgebung`/`c-basis`.

4. **`.cursor/rules/entwicklungsablauf.mdc`**  
   Gleiche Packing-Sprache (~2 / zwei verwandte / zwei zusammengehörige), Skip-Planner-Hinweis, Status-Modell, Playtest-Dedup-Kern; weiterhin Review/Test/Git **keine** Slices; weiterhin Phase 3+4 Pflicht für spielsichtbar.

5. **`.cursor/agents/task-slicer.md`**  
   Default: zwei verwandte Inkremente; Beispiele wie oben; Campus/Ohringen-Regeln; Denylist: Default nur „ein Haus“ / „eine Rasterzelle“ **ohne** 2×-Regel. Stub darf optional Art ja/nein + 2-Bullet-Testplan enthalten (damit Skip-Planner greift). Weiterhin keine Review/Test/Git/RCA-Slices.

6. **`.cursor/agents/feature-planner.md`**  
   Skip-Bedingungen dokumentieren (wann nicht aufrufen / früh abbrechen). Grenzen-Text an 2×-Packing anpassen (nicht mehr „only one house / one raster cell“ als hartes Default). Bei Skip: Parent/Implementer füllt Testplan/Akzeptanz nach.

7. **`.cursor/agents/feature-implementer.md`**  
   INDEX `in Arbeit` beim Start; Suite/Art-Alpha laufen und im Handoff melden (grün/fehlend); Slice-File nicht durch Phasen-Status jagen; bei Skip-Planner fehlende Testplan/Akzeptanz-Checkboxen in derselben Datei ergänzen.

8. **`.cursor/agents/godot-playtester.md`**  
   Keine doppelte volle Suite / kein Art-Alpha-Wiederholen unter den Dedup-Bedingungen; Docs-only-Pfad ohne Godot; immer einzigartiger Smoke + slice-spezifisch visuell bei spielsichtbar; Status nur INDEX/`Erledigt` nach Pass (kein `Playtest`-Phasen-Ping-Pong im Slice-File).

9. **`.cursor/agents/code-reviewer.md`**  
   Nur anfassen, wenn dort noch „ein Haus“ / „eine Rasterzelle“ als Slice-Default ohne 2×-Regel steht — dann an Packing angleichen. Review selbst bleibt Pflicht für spielsichtbar.

10. **Vorlagen** `docs/plans/_SLICE.md`, `_SLICE_INDEX.md`, `_TEMPLATE.md`  
    Packing-Hinweis / Zuschnitt-Beispiele (~2); Status-Hinweis INDEX-only; Planner optional; Stub darf Art ja/nein + kurzer 2-Bullet-Testplan; `_TEMPLATE.md` Status-Zeile entlasten (kein Pflicht-Churn durch Phasen).

11. **Tests** `tests/entwicklungsablauf_docs_test.py` + Wire in `scripts/run_tests.sh` (neben bestehendem `iso_map_interaction_docs_test.py`):
    - **Require packing** (~2 / zwei verwandte / zwei zusammengehörige) in: `docs/ENTWICKLUNGSABLAUF.md`, `.cursor/agents/task-slicer.md`, `.cursor/rules/entwicklungsablauf.mdc`
    - **Require skip-planner** Bedingungen in: `docs/ENTWICKLUNGSABLAUF.md`, `.cursor/agents/feature-planner.md`
    - **Require playtest no-duplicate-suite / docs-only no Godot** in: `.cursor/agents/godot-playtester.md`, `docs/ENTWICKLUNGSABLAUF.md`
    - **Denylist:** Slicer (und Regel/Ablauf-Default) darf nicht nur „ein Haus“ / „eine Rasterzelle“ als Default ohne 2×-Regel stehen lassen
    - **Must still forbid** Review/Test/Git als Slices (ENTWICKLUNGSABLAUF + task-slicer + rule)
    - **Must still require** code-review + playtest (nicht als übersprungen für spielsichtbar markiert)
    - Iso-Sätze in `ENTWICKLUNGSABLAUF.md` nicht regressieren (Haus–Strasse / nicht Masse/Kamera/Größe / c-umgebung / c-basis) — bestehende `iso_map_interaction_docs_test.py` bleibt grün

## Testplan

### Automatisiert

- [x] `tests/entwicklungsablauf_docs_test.py` neu: Phrasen-Checks wie in Schritt 11 (Packing, Skip-Planner, Playtest-Dedup, Denylist ein-Haus-Default, Forbid Review/Test/Git-Slices, Keep Review+Playtest)
- [x] In `scripts/run_tests.sh` verdrahtet; Docs-Tests grün (`entwicklungsablauf_docs_test.py`, `iso_map_interaction_docs_test.py`)
- [x] `tests/iso_map_interaction_docs_test.py` bleibt grün (Iso-Sätze in ENTWICKLUNGSABLAUF unangetastet)

### Playtest / Smoke

- [x] **Docs-only:** kein Godot-Start, kein `verify_art_alpha.py`
- [x] Read-through: ENTWICKLUNGSABLAUF + task-slicer + feature-planner + godot-playtester + entwicklungsablauf.mdc konsistent zu den Concrete Rules
- [x] Stichprobe: ein fiktives „zwei Häuser derselben Strasse“-Beispiel liest sich als **ein** erlaubter Slice; „ganz Seuzach“ weiterhin zu groß; Review/Playtest weiterhin Phasen, keine Slices

Playtest 2026-08-12 (docs-only): `entwicklungsablauf_docs_test.py` + `iso_map_interaction_docs_test.py` exit 0; kein Godot, kein Art-Alpha, keine volle Suite. INDEX blieb `in Arbeit` bis Git.

## Art-Bedarf

- [x] Keine neuen Assets
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  
  Details: —

## Akzeptanzkriterien

- [x] Slicer-Default dokumentiert: ~2× / zwei verwandte / zwei zusammengehörige spieler-sichtbare Inkremente pro Slice inkl. Beispiele und „zu groß“/Campus/Ohringen
- [x] Verbotene Slices (Review/Tests/Playtest/Git/RCA) weiterhin explizit
- [x] Skip-Planner-Bedingungen in ENTWICKLUNGSABLAUF + feature-planner.md
- [x] Playtest: keine doppelte Suite wenn Implementer grün + Review ohne Folgeänderungen; Docs-only ohne Godot/Art-Alpha
- [x] INDEX-Status nur offen → in Arbeit → erledigt; kein Slice-File-Phasen-Churn
- [x] Qualitätstore bleiben: Code-Review + Playtest getrennt (spielsichtbar), RCA bei Bugs, Git pro Slice, Implementer-Tests
- [x] Lebende Dateien aus Scope aktualisiert; code-reviewer nur bei Bedarf
- [x] `tests/entwicklungsablauf_docs_test.py` + `run_tests.sh` verdrahtet; Docs-Tests grün; Iso-Docs-Test weiterhin grün
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass (Docs-only-Pfad)
