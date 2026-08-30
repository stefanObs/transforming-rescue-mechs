# Slice: S03 — Connect octilinear network + denser GMaps coverage

**Parent:** `docs/plans/octilinear-seuzach-gmaps/INDEX.md`  
**Hängt ab von:** S02

## Feature

Das octilineare SVG ist ein **zusammenhängendes** befahrbares Netz (Arrow-Key H/V/45°): Hauptkorridore treffen sich an Junctions; genug Nebenstrassen, dass Seuzach+Ohringen auf Google Maps wiedererkennbar wirkt — ohne Sandbox-Umschaltung.

## Repro & RCA

**Repro:** `docs/maps/seuzach_octilinear_roads.svg` öffnen — viele isolierte Polylines; Winterthurer↔Stationsstrasse ~1400 wu Lücke; nur 26 Roads / ~20 Komponenten.

**RCA:**
1. Octilinear/RDP/Lattice verschiebt Endpunkte so, dass sich Kreuzungen nicht mehr treffen.
2. Trace zu dünn (nur ausgewählte Namen) → viele GMaps-Strassen fehlen.
3. Generator hat kein Post-Pass „near-miss → shared junction / connector“.

## In diesem Schritt

- Trace um weitere driveable GMaps-Korridore in CLIP verdichten
- Generator: Junction-Snap + kurze octilineare Connectoren zwischen Near-Miss-Korridoren
- Regenerieren JSON + SVG; ein grosses verbundenes Kernnetz

## Nicht

- `world_sandbox` auf octilinear umstellen
- Geometrie aus `seuzach_roads.json` kopieren

## Art

- nein

## Testplan

- ≤3 grosse Vertex-Komponenten im Kern (oder 1 dominante); Winterthurer trifft Stationsstrasse (Abstand 0 / shared junction)
- Mehr Roads als S02 (≥40); SVG viewBox weiterhin CLIP; nur H/V/45°
