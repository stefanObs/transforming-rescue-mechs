# Plan: roundabout-wider-no-centerline

**Status:** Done  

**Typ:** Bugfix  
**Datum:** 2026-08-10  
**Owner:** feature-planner → implementer

## Ziel

Kreisel-Ring in der Sandbox deutlich breiter/substanzieller machen und die gestrichelte Mittellinie auf dem Kreiselfahrbahn-Ring entfernen (CH-Realismus: Kreisel ohne Ring-Mittellinie). Gerade Straßen behalten die gestrichelte CH-Mittellinie.

## Scope

- In:
  - `scripts/road_kit.gd` — Default/`centerline` für `add_roundabout`
  - `scripts/world_sandbox.gd` — größere `radius` / `ring_half_w`, Position mit Clearance zu Geraden, kein `centerline: true` am Kreisel
  - `tests/m2_road_kit_test.gd` — Default ohne Centerline-Streifen am Roundabout; Gerade weiterhin mit Stripes
- Nicht:
  - Neue Art-Assets
  - Umbau gerader Straßen / anderer RoadKit-Primitives
  - Geometrie-Redesign der Insel jenseits der Parameteränderung

## Systeme

- RoadKit (`road_kit.gd`) — `add_roundabout`, `_add_dashed_circle`
- Sandbox-Welt (`world_sandbox.gd`) — Kreisel bei `(-400, 450)`, radius 170 / half_w 78
- Headless-Test `m2_road_kit_test.gd`

## Repro & RCA (Pflicht bei Typ = Bugfix)

### Reproduktion

- [x] Repro bestätigt (Code-Pfad + User-Feedback; Playtest bestätigt in Phase 4)
- [ ] Nicht reproduzierbar (kein Fix ohne weitere Daten)

| Feld | Inhalt |
|------|--------|
| Schritte | 1. `./play-linux.sh` starten 2. Kamera/Blick auf Kreisel nahe `(-280, 280)` |
| Erwartet | Breite Kreiselfahrbahn; keine gestrichelte Mittellinie auf dem Ring |
| Tatsächlich | Ring wirkt schmal; gestrichelte weiße Mittellinie auf dem Ring |
| Umgebung | Godot 4, Sandbox-Scene via `play-linux.sh`, Linux |
| Evidenz | User-Feedback; Code: `add_roundabout(..., 95.0, 30.0, { "centerline": true })` |

### Root-Cause-Analyse

| Feld | Inhalt |
|------|--------|
| Hypothesen | (1) Sandbox-Parameter `radius`/`ring_half_w` zu klein (2) Roundabout defaultet Centerline an / Sandbox setzt es explizit |
| Bestätigte Ursache | `add_roundabout` default `opts.centerline = true` und ruft `_add_dashed_circle` auf; Sandbox übergibt ebenfalls `"centerline": true` sowie moderate Maße `95.0` / `30.0` |
| Nicht die Ursache | Gerade-Straßen-Centerline-Logik; fehlende Texturen |
| Fix-Richtung | Default `centerline` für Roundabouts auf `false`; Sandbox Centerline weglassen/aus; Ring-Parameter erhöhen |
| Risiken | Tests zählen aktuell Roundabout-Stripes mit (`centerline: true` im Test) — Assertion anpassen; explizites Debug-`centerline: true` weiterhin erlaubt |

### Review-Finding (Phase 3) — Overlap

| Feld | Inhalt |
|------|--------|
| Repro | `radius=170`, `ring_half_w=78` bei `(-280, 280)` → `r_outer=248`; E–W-Achse `(-280, 80)` liegt im Ring |
| Ursache | Verbreiterung ohne Verschiebung: Clearance zur Querstraße negativ |
| Fix | Center nach `(-400, 450)` (weiter SW); Maße beibehalten |
| Clearance | V-Straße ~60 px; H-Straße ~42 px (inkl. Trottoir) |

- [x] RCA dokumentiert und reviewed (kurz vom Hauptagenten ok)

## Technische Schritte

1. **`road_kit.gd`:** In `add_roundabout` Default von `opts.get("centerline", true)` → `false`. Kommentar/Docstring anpassen (Ring ohne Mittellinie; opt-in nur für Debug). ✅
2. **`world_sandbox.gd`:** Kreisel-Call vergrößern (z. B. deutlich höheres `radius` und/oder `ring_half_w` — so dass der Ring visuell substanziell wirkt) und `"centerline": true` entfernen bzw. nicht setzen. ✅
3. **`m2_road_kit_test.gd`:**
   - Roundabout-Call ohne Centerline (Default); assertieren, dass nach alleinigem Roundabout-Call **keine** `stripe`-Metas entstehen (oder Stripe-Count nur von der Gerade stammt). ✅
   - Gerade mit `centerline: true` weiterhin Stripes ≥ 1. ✅
   - Optional: Roundabout mit explizitem `centerline: true` smoke-testen, falls opt-in bleiben soll. ✅
4. Phase 3 Code Review → Phase 4 Playtest (Kreisel visuell + keine Ring-Mittellinie).

## Testplan

### Automatisiert

- [x] `m2_road_kit_test.gd`: Roundabout default → keine Centerline-`stripe`-Pieces vom Ring
- [x] Gerade Straße mit Centerline → Stripes weiterhin vorhanden
- [x] Bei Bugfix: Regressionstest bildet die Repro ab (zuerst rot bzgl. Default-Centerline-Annahme, nach Fix grün)

### Playtest / Smoke

- [x] Haupt-Scene / Sandbox startet ohne Error
- [x] Kreisel bei `(-400, 450)`: Ring deutlich breiter, keine Überlappung mit N–S/E–W
- [x] Keine gestrichelte Mittellinie auf dem Kreiselring
- [x] Gerade Straßen behalten gestrichelte CH-Mittellinie
- [x] Bei Bugfix: manuelle Repro-Schritte schlagen nach Fix nicht mehr fehl

**Playtest 2026-08-10 (Positions-Fix):** PASS — `add_roundabout(-400, 450, 170, 78)` ohne `centerline`; Clearance N–S ≈60 px / E–W ≈42 px (Ring-Fahrbahn zu Geraden inkl. deren Trottoir); Suite + Smoke grün.

## Art-Bedarf

- [x] Keine neuen Assets
- [ ] Neue Grafiken/Animationen → Subagent `comic-rettung-art`  
  Details: n/a

## Akzeptanzkriterien

- [x] Roundabout-Ring in der Sandbox sichtbar breiter/substanzieller
- [x] Keine gestrichelte Mittellinie auf dem Kreiselring (Default; Sandbox aktiviert sie nicht)
- [x] Gerade Straßen behalten CH-gestrichelte Mittellinie
- [x] `m2_road_kit_test` grün
- [x] Repro + RCA erledigt
- [x] Code Review ohne offene Critical/High
- [x] Playtest Pass (nach Positions-Fix erneut)
