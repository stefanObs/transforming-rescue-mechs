# Plan: m3-street-map-only

**Status:** Erledigt (Playtest Pass)  
**Typ:** Korrektur  
**Datum:** 2026-08-11  
**Owner:** Projekt / Agent-Workflow  
**Bezug:** [`docs/plans/m3-street-map-reset.md`](m3-street-map-reset.md)  
**Art:** keine neue Art

---

## Ziel

Die World zeigt **nur das Strassennetz** (Seuzach+Ohringen, vier Breiten). Alles, was keine Strasse ist — Landmarken, Wälder, Hügel, Hub/Tankstelle, Schulen — runter, damit die Karte lesbar bleibt.

---

## Repro & RCA

### Repro

1. World laden nach v0.17.0: Strassen sind da, aber Kirchen, Schulen, Wälder, Hub liegen noch auf der Karte.

- [x] Repro bestätigt (Code + User: „remove everything from the map that is not a street“)

### RCA

- Street-map-reset hat nur Häuser entfernt; `_place_landmarks` und Hügel/Wald-Polygone blieben absichtlich.
- **Fix:** Props leeren; Hügel/Wald/Gras-Kleckse weglassen; flaches Gras + RoadKit. Unsichtbares `HubEnter` am Spawn bleibt für M3-Transition.

---

## Scope

### In

- `_place_landmarks` → keine Sprites
- `_build_flat_ground` → nur Basisgras + Strassen (keine Hügel/Wald/Patches)
- Tests: 0 Landmark-/Haus-Sprites, 0 hill markers, Strassen-Assertions bleiben
- Hub-Test: keine Hub-Fassade; Enter-Zone + Spawn bleiben

### Nicht

- Häuser zurück, Fusswege, Hub-Gebäude, neue Art

---

## Testplan

- [x] 0 `landmark_id` / `house_variant` Sprites in `%Props`
- [x] 0 `terrain=hill` Marker
- [x] Named roads + 4 Klassen unverändert
- [x] HubEnter unsichtbar am Forrenberg-Spawn
- [x] Suite grün

---

## Akzeptanzkriterien

- [x] Karte = Gras + Strassen
- [x] Review + Playtest Pass
