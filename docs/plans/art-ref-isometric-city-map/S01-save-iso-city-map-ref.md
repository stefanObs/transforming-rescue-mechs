# Slice: S01 — Iso-Stadt-Kartenbild unter `docs/design-refs/` speichern

**Status:** Erledigt  
**Typ:** Art  
**Parent:** `docs/plans/art-ref-isometric-city-map/INDEX.md`  
**Datum:** 2026-08-11  
**Hängt ab von:** —

Dieses File ist der **Schritt**. Phase 1 (`feature-planner`) füllt es zum vollständigen Plan; Phase 2–4 gelten nur für **diesen** Slice.

## Ziel

Das User-Referenzbild (isometrische 3D-Stadt-Game-Map, AR-32-Look über Magnific / Brave-CDN) liegt **lokal** unter `docs/design-refs/` als Moodboard, unabhängig von CDN, und ist im Repo auffindbar. Keine Style-Bible-/Agent-Verdrahtung (das ist S02).

## Grenzen

- In:
  - Bilddatei: `docs/design-refs/c-iso-city-map.png` (oder `.jpg` nur falls das Original kein PNG ist — dann Endung anpassen, **ein** kanonischer Dateiname)
  - Kurzer Quellenhinweis **an der Datei** (z. B. Sidecar `docs/design-refs/c-iso-city-map.source.md` **oder** Kommentarblock nur in diesem Slice-File, wenn Sidecar vermieden werden soll — Phase 1 entscheidet **eine** Variante)
  - Download der User-URL bzw. des Magnific-Originals ins Repo; Bild muss das Iso-Stadt-Kartenmotiv sein (Gebäudeblöcke, Straßenraster, ¾-Iso-Stadt), nicht ein anderes Magnific-Asset
- Nicht (andere Slices / Rest der Aufgabe):
  - `docs/STYLE-BIBLE-C.md`, `.cursor/agents/comic-rettung-art.md`, `.cursor/rules/comic-rettung-art.mdc`, `docs/ENTWICKLUNGSABLAUF.md` (**S02**)
  - Neue oder regenerierte Spiel-Sprites unter `assets/art/`
  - `process_art_alpha.py` / `verify_art_alpha.py` auf dieses Moodboard (Platten dürfen bleiben, analog andere `docs/design-refs/`-Moodboards)
  - Häuser, Karte, Godot-Scenes, Tests an Gameplay
- Raster / Felder / GPS / Asset-Namen:
  - n/a Weltzellen
  - Asset: `docs/design-refs/c-iso-city-map.png` (Prefix `c-` = Style-C-Kontext; Rolle = Iso-Stadt/Karte/Gebäude-Orientierung)
  - Quelle (User): Brave-CDN-Wrapper auf Magnific `isometric-3d-city-game-map` / AR-32-style; Original-Host `img.magnific.com`

## Systeme

Design-Refs / Moodboards (`docs/design-refs/`). Kein Runtime-Code.

## Repro & RCA (Pflicht bei Typ = Bugfix)

n/a (Feature / Art-Referenz, kein Bugfix)

## Technische Schritte

1. Datei von der User-URL (bzw. Magnific-Direktlink, falls CDN fehlschlägt) nach `docs/design-refs/c-iso-city-map.png` speichern. Kein Godot-Import, kein Alpha-Strip.
2. Visuell prüfen (Image-Read): isometrische Stadt-Game-Map, nicht leer/Fehlerseite/Captcha.
3. Quelle dokumentieren (URL + Motivname + Hinweis: Moodboard, nicht Spiel-Sprite). Keine Secrets.
4. Bestehende `c-umgebung.png` / `c-basis.png` / `c-mech.png` / `c-fahrzeug.png` **nicht** überschreiben oder löschen.

## Testplan

### Automatisiert

- [x] Datei existiert am kanonischen Pfad (`test -f docs/design-refs/c-iso-city-map.png` bzw. gewählte Endung); Größe > 0
- [x] Keine neuen Dateien unter `assets/art/` in diesem Slice
- [x] Bestehende `docs/design-refs/c-{umgebung,basis,mech,fahrzeug}.*` unverändert

### Playtest / Smoke

- [x] Haupt-Scene startet ohne Error (keine Scene-Änderung erwartet)
- [x] Bild im Repo öffenbar; Motiv = Iso-Stadt-Karte
- [x] Nur dieser Slice sichtbar/prüfbar (keine stillen Extra-Lieferungen: keine Bible-/Agent-Edits)

## Art-Bedarf

- [x] Keine neuen **Spiel**-Assets
- [ ] Neue Grafiken → `comic-rettung-art` **nur** für die Assets dieses Slices  
  Details: **Kein GenerateImage.** Bestehendes Referenzfoto **kopieren/speichern**, nicht neu zeichnen. Moodboard, keine Plate-Removal.

## Akzeptanzkriterien

- [x] Grenzen eingehalten (nichts aus Nachbar-Slices)
- [x] `docs/design-refs/c-iso-city-map.png` (oder dokumentierte Endung) liegt im Repo, Motiv stimmt, Quelle notiert
- [x] Automatisierte Tests grün (Datei-Existenz; Gameplay-Suite unverändert)
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass (Bild lesbar; World-Scene unverändert startbar)
- [ ] Git: Commit + Push + Tag für **diesen** Slice
