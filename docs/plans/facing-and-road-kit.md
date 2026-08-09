# Plan: 4-Richtungs-Facing + Dorf-Straßenkit

**Status:** Erledigt  
**Typ:** Feature  
**Datum:** 2026-08-09  
**Owner:** Hauptagent

## Ziel

1. Fahrzeuge und Mechs zeigen die korrekte Ansicht je Fahrtrichtung (oben=hinten, rechts=Seite, …).  
2. Dorf-Straßenbau: gerade + schräge Segmente, Schweizer Mittellinien-Streifen, Trottoir, Kreisel.

## Scope

- In:
  - Player: 4 Facing-Richtungen N/E/S/W aus Velocity; Art je Char×Form×Richtung
  - `scripts/road_kit.gd`: Straight, Diagonal, Centerline (gestrichelt CH-weiß), Trottoir, Kreisel
  - Sandbox nutzt Road-Kit für Demo-Dorfkreuz + Kreisel + Trottoir
  - Tests
- Nicht: echte Seuzach-TileMap (M3); 8-Dir Walk-Cycles; Navigation/AI

## Systeme

Player-Visuals, World/Ground, Art Style C

## Repro & RCA (Review-Finding: Facing)

- [x] Repro bestätigt
- [x] RCA dokumentiert

| Feld | Inhalt |
|------|--------|
| Schritte | Taste oben (W/↑) — Erwartung Heckansicht (N) |
| Tatsächlich | Seitenansicht E, weil Facing aus post-iso Velocity `(1,-0.5)` |
| Ursache | `facing_from_velocity` auf iso-transformierte Velocity |
| Fix | Facing aus **pre-iso Input**; Bewegung weiter iso |

## Technische Schritte

### A — Facing

1. Facing-Enum N/E/S/W aus **pre-iso Input** (dominante Achse; −y = N)
2. Texturen: `{id}_{robot|vehicle}_{n|e|s|w}.png`; bestehende Idle = Fallback für `s`/`e`
3. Bei Bewegung Texture je Facing; `flip_h` nur noch Fallback wenn Side gespiegelt
4. Kurven-Lean optional kurz beim Facing-Wechsel behalten
5. Tests: facing_from_velocity + Asset-Existenz

### B — Road Kit

1. `RoadKit` baut unter Parent-Node2D:
   - `add_straight(a, b, half_w, opts)` — Fahrbahn + optional Trottoir beiderseits + gestrichelte Mittellinie
   - `add_diagonal` = straight mit iso-Schräge (gleiche API)
   - `add_roundabout(center, radius, ring_half_w)` — Ring + Insel + Mittellinie
2. Farben: Road `#8E8E8E`, Sidewalk `#C8C8C8`, Stripe weiß `#F5F5F5` gestrichelt
3. Sandbox: Hauptstraße + Querbalken + ein Diagonalstück + Kreisel + Trottoir
4. Tests: Kit erzeugt Road-/Stripe-/Sidewalk-Polygone; Line2D-Verbot für Tile-Gitter bleibt (Streifen als kurze Polys OK)

## Art-Bedarf

- [x] `comic-rettung-art`: je bolt/marina/rush × robot/vehicle × n/e/s/w  
  - **n** = Heckansicht (von hinten)  
  - **s** = Front/¾-Front  
  - **e** = rechte Seite  
  - **w** = linke Seite (oder e + flip; lieber eigenes Asset für Lesbarkeit)  
  Referenzen: Idle-Sprites + Style-C Moodboards. Alpha-Pipeline Pflicht.

## Testplan

- [x] Facing-Assets (mind. n/e/s/w je Form) existieren bzw. Fallback dokumentiert
- [x] `facing_from_velocity`: up→N, right→E, …
- [x] RoadKit: straight + roundabout + sidewalk + dash count > 0
- [x] Suite + Playtest

## Akzeptanzkriterien

- [x] Alle 3 Chars, Robot+Fahrzeug: Richtungsansichten korrekt
- [x] Gerade + schräge Straße, CH-Mittellinie, Trottoir, Kreisel in Sandbox
- [x] Review + Playtest Pass → Release
