# Plan: Spieler-Skalierung, Z-Order, Blickrichtung

**Status:** Erledigt  
**Typ:** Bugfix  
**Datum:** 2026-08-09  
**Owner:** Hauptagent

## Ziel

Figur wirkt im Verhältnis zur Welt stimmig (nicht hausgroß), verschwindet nicht hinter Bodenflächen, und zeigt klar Bewegungs-/Fahrtrichtung.

## Scope

- In: `player.gd` / `player.tscn`, `world_sandbox.gd` (z_index), Regressionstests
- Nicht: Neue Richtungs-Sprites / 8-Dir-Art; echte Seuzach-Map

## Systeme

Player-Visuals, World Y-/Z-Sortierung

## Repro & RCA

- [x] Repro bestätigt
- [x] RCA dokumentiert

### Reproduktion

| Feld | Inhalt |
|------|--------|
| Schritte | 1. `godot --path .` → Sandbox 2. Figur anschauen vs. Haus/Straße 3. Nach „oben“ (negatives Y) laufen |
| Erwartet | Figur kleiner als Gebäude; immer vor dem Boden; Blick/Front in Laufrichtung |
| Tatsächlich | Figur ~gleich groß wie Haus (~200px bei Scale 0.2); bei negativem Y hinter Gras-/Straßen-Polygonen; Sprite zeigt feste Pose |
| Umgebung | Godot 4.4.1, `world_sandbox.tscn`, main |
| Evidenz | `SPRITE_SCALE=0.2` bei ~1000px Art; `z_index = 10 + int(y)` → bei y&lt;−40 unter Ground (−50…−34) |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) Scale zu groß (2) z_index kollidiert mit Ground (3) kein Facing |
| Bestätigte Ursache | (1)+(2)+(3): Art ~1000px × 0.2 ≈ Charakter = Haus; Actor-z = 10+y wird negativ und liegt unter Boden-Polygonen; kein `flip_h`/Facing aus Velocity |
| Nicht die Ursache | Fehlende Texturen; Kamera-Zoom allein |
| Fix-Richtung | Kleinerer `SPRITE_SCALE`; Actor-z mit großem Offset über Ground (BASE unter Godot-Max 4096); Facing per `flip_h` aus Velocity.x |
| Risiken | Collision/Label-Offsets; volle Sprite-Rotation bei ¾-Art vermeiden |

## Technische Schritte

1. Regressionstest: Scale-Obergrenze; z_index-Formel immer &gt; Ground-Max; Facing bei Velocity
2. `SPRITE_SCALE` ≈ `0.08`–`0.09`; Offsets/Label anpassen
3. World: Player/Props `z_index = BASE + int(y)` mit BASE ≫ 0 (3000 / 2000; Godot z-max 4096)
4. Player: bei Bewegung Facing aus `velocity` setzen (`flip_h` aus `velocity.x`; Fahrzeug `rotation` aus `velocity.angle()` oder nur flip)
5. Tests + Review + Playtest

## Testplan

### Automatisiert

- [x] Player-Scale ≤ Schwelle (sichtbare Höhe ≪ Haus)
- [x] `actor_z(y)` für y in [−500, 700] stets &gt; −30
- [x] Nach gesetzter Velocity: `flip_h` bzw. Facing stimmt
- [x] Suite grün

### Playtest

- [ ] Figur klar kleiner als Haus/Kirche
- [ ] Nach Norden laufen: Figur vor Gras/Straße
- [ ] Links/Rechts: Spiegelung sichtbar; Fahrzeug zeigt Fahrtrichtung

## Art-Bedarf

- [x] Keine neuen Assets (nur Flip/Scale/Rotation)

## Akzeptanzkriterien

- [ ] Repro + RCA erledigt
- [ ] Figur deutlich kleiner als Landmarken
- [ ] Nie hinter Boden-Polygonen
- [ ] Bewegungsrichtung erkennbar
- [ ] Tests + Review + Playtest Pass
