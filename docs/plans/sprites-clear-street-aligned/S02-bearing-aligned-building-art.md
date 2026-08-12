# Slice: S02 — Bearing-aligned Gebäude-Art + Placement

**Parent:** `docs/plans/sprites-clear-street-aligned/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (zwei zusammengehörige Inkremente: (1) Style-C street-aligned Haus- und ggf. Schul-Varianten für Haupt-Bearings, (2) Placement wählt Variante per Road-Tangent). Plan empfohlen (Art + Multi-System); Tests, Review, Playtest und Git sind der normale Ablauf — keine Extra-Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Gebäude stehen nicht mehr schräg/iso-verdreht zur lokalen Strasse: lange Fassade parallel zum Straßenband (E–W- und N–S-Hauptbearings). Placement wählt die passende Variante aus der Road-Tangent; Side-aware Flip bleibt; kein willkürliches `Sprite2D.rotation`.

## In diesem Schritt

- Style-C Art (comic-rettung-art): street-aligned Haus-Varianten für **E–W** und **N–S** (lange Fassade // Strasse; Eingänge an der Straßenkante; kein Iso-Skew relativ zur lokalen Tangente). Schul-/Campus-Varianten nur soweit nötig, damit Campi denselben Eindruck haben
- Refs: `c-umgebung` / `c-basis` + `c-iso-city-map` (**nur** Haus–Strasse-Layout, keine Maße/Kamera); Alpha-Pipeline + Import
- Placement: Variante anhand Road-Tangent / Bearing wählen (binär oder grob E–W vs N–S); bestehende Corridor-Metas / Clearance aus S01 behalten; **kein** dekoratives Random-Facing

## Nicht (andere Feature-Schritte)

- Clearance-Fracs / Agent-Docs (→ S01)
- Jede Landmark neu; RoadKit neu; alle alten `house_*` löschen; Top-Down-Kamera

## Art

- ja — neue street-aligned PNGs (Häuser mind. E–W + N–S; Schulen nur wenn Placement sonst schräg bleibt); Style C; danach `process_art_alpha` / `verify_art_alpha`

## Testplan

- Suite: Varianten existieren; Placement-Mehrheit nutzt Bearing-Match; visual clear aus S01 bleibt grün; kein `Sprite2D.rotation` an Gebäuden
- Play: Winterthurer (nahe E–W) und eine N–S-Nahstrasse — Fassaden parallel zum Band, nicht diagonal dazu; Schulen ohne Asphalt-Übermalung
