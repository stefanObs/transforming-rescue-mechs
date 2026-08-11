# Slice: S02 — Ref in Style-Bible C, Art-Subagent und Cursor-Regel verdrahten

**Status:** Slice-Entwurf  
**Typ:** Feature  
**Parent:** `docs/plans/art-ref-isometric-city-map/INDEX.md`  
**Datum:** 2026-08-11  
**Hängt ab von:** S01

Dieses File ist der **Schritt**. Phase 1 (`feature-planner`) füllt es zum vollständigen Plan; Phase 2–4 gelten nur für **diesen** Slice.

## Ziel

Zukünftige Grafiken — **besonders Welt, Karte, Gebäudeblöcke** — orientieren sich zusätzlich am Iso-Stadt-Karten-Moodboard aus S01. Stil **C Comic-Rettung bleibt verbindlich**; die neue Datei ist Orientierung (Kamera, chunky Stadtblöcke, Iso-Kartenlesbarkeit), kein Stilwechsel und keine Massen-Regeneration.

## Grenzen

- In:
  - `docs/STYLE-BIBLE-C.md` — Tabelle „Referenzbilder“ um Zeile Iso-Stadt-Karte; kurzer Absatz: was **übernehmen** (Iso-Übersicht, Blockmasse, Straßen als Bänder, lesbare Stadtstruktur) vs. **nicht** (fotorealistisches 3D, AR-32-Rohlook, weiche Plastik-Städte, Verwerfen von dicken Konturen/Cel)
  - `.cursor/agents/comic-rettung-art.md` — Locked-style-Tabelle + Workflow Schritt 2/5: bei Welt/Karte/Gebäude/`GenerateImage` zusätzlich `docs/design-refs/c-iso-city-map.png` in `reference_image_paths`; Handoff „References used“
  - `.cursor/rules/comic-rettung-art.mdc` — Punkt zu `c-*.png` ergänzen: Iso-Stadt-Karte für World/Map/Buildings, C bleibt führend
  - Optional, nur wenn ein Satz nötig: `docs/ENTWICKLUNGSABLAUF.md` (Art-Refs erwähnen die neue Datei explizit, nicht nur `c-*.png`-Glob)
- Nicht (andere Slices / Rest der Aufgabe):
  - Bild erneut laden oder umbenennen (**S01**)
  - Alle oder einzelne `assets/art/`-PNGs neu generieren, Häuser/Landmarken/Tiles ersetzen
  - Stil A/B, `docs/DESIGN-VORSCHLAEGE.md`, `docs/KONZEPT.md`
  - Godot-Gameplay, RoadKit, Rasterzellen Seuzach/Ohringen
- Raster / Felder / GPS / Asset-Namen:
  - n/a Weltzellen
  - Pflicht-Ref: `docs/design-refs/c-iso-city-map.png` (Pfad aus S01; bei abweichender Endung denselben kanonischen Namen verwenden)
  - Primär-Refs bleiben: `c-umgebung.png`, `c-basis.png`, `c-mech.png`, `c-fahrzeug.png` — Charaktere weiter mech+fahrzeug; **Umgebung/Gebäude/Karte** zusätzlich Iso-Stadt-Karte

## Systeme

Art-Prozess: Style-Bible C, Subagent `comic-rettung-art`, Cursor-Regel Art-Delegation. Kein Runtime-Code.

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Prozess-Feature)

## Technische Schritte

1. In `STYLE-BIBLE-C.md` die Iso-Stadt-Karte als **zusätzliche** Primärquelle für Welt/Karte/Gebäude eintragen. Klarstellen: C-Regeln (Kontur, Cel, Kind 6–8, keine 3D-Block-Hero-Böden) gelten weiter; die Map-Ref steuert **Orientierung** der Stadtgrafik, nicht den Shading-Stil.
2. `comic-rettung-art.md`: Locked-style-Tabelle um Rolle z. B. „Iso city / world map (orientation)“; Workflow: bei World/Base/Buildings/Map die Datei **lesen** und in `reference_image_paths` übergeben (zusammen mit `c-umgebung` / `c-basis`, nicht statt C). Handoff-Liste aktualisieren.
3. `.cursor/rules/comic-rettung-art.mdc`: denselben Satz für den Hauptagenten (Delegations-Checkliste).
4. Keine `GenerateImage`-Aufrufe in diesem Slice. Keine Änderungen unter `assets/art/`.
5. Kurz prüfen, dass `c-*.png`-Globs die neue Datei mitabdecken und nirgends nur die alten vier Pfade als „vollständige Liste“ stehen bleiben (Agent, Bible, Regel).

## Testplan

### Automatisiert

- [ ] `rg` / Datei-Check: `c-iso-city-map` kommt in `docs/STYLE-BIBLE-C.md`, `.cursor/agents/comic-rettung-art.md` und `.cursor/rules/comic-rettung-art.mdc` vor
- [ ] Keine Diffs unter `assets/art/`
- [ ] Bestehende Test-Suite unverändert grün (keine Pflicht-neuen GDScript-Tests)

### Playtest / Smoke

- [ ] Haupt-Scene startet ohne Error
- [ ] Nur dieser Slice: Docs/Agent/Regel nennen die Ref; Spielgrafik unverändert
- [ ] Reviewer kann anhand Bible-Absatz sagen, was von der Magnific-Karte übernommen wird und was nicht (C bleibt)

## Art-Bedarf

- [x] Keine neuen Assets
- [ ] Neue Grafiken → `comic-rettung-art` **nur** für die Assets dieses Slices  
  Details: **Keine** Generierung. Nur Prozess verdrahten, damit **spätere** Slices die Datei nutzen.

## Akzeptanzkriterien

- [ ] Grenzen eingehalten (nichts aus Nachbar-Slices; keine Art-Regeneration)
- [ ] Bible + Art-Agent + Cursor-Regel nennen `c-iso-city-map` und den Vorrang von Stil C
- [ ] Automatisierte Tests grün
- [ ] Code Review ohne offene Critical/High
- [ ] Playtest Pass (Smoke: Scene startet; Prozess-Doku stimmig)
- [ ] Git: Commit + Push + Tag für **diesen** Slice
