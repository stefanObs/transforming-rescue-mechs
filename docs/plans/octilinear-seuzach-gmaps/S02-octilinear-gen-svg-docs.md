# Slice: S02 — Octilinear generator, SVG, docs

**Parent:** `docs/plans/octilinear-seuzach-gmaps/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Aus dem GMaps-Trace erzeugt `scripts/gen_seuzach_octilinear_roads.py` ein octilineares Straßennetz (nur H/V/45°) in World Units und ein großes SVG zur Inspektion; Schema wie `seuzach_roads.json`, Skala/CLIP/Kirche aus der bestehenden Welt; dokumentiert in `data/README.md`. Sandbox bleibt unverändert.

## In diesem Schritt

- Script `scripts/gen_seuzach_octilinear_roads.py`: Trace laden → WU via bestehendem CLIP ≈ (-25000,-24000)–(32000,18000), Kirche-Origin (`seuzach_geo`), FIELD_M/FIELD_WU
- Octilinearize (H/V/45° only, für 8-dir Arrow-Key-Driving), validate
- Emit `data/seuzach_roads_octilinear.json` (Schema wie `seuzach_roads.json`)
- Emit `docs/maps/seuzach_octilinear_roads.svg` (viewBox=CLIP)
- Kurz dokumentieren in `data/README.md`

## Nicht (andere Feature-Schritte)

- Trace-Digitalisierung / GMaps-Quelle anlegen (S01)
- `world_sandbox` auf `seuzach_roads_octilinear.json` umstellen
- CLIP/Origin/FIELD neu kalibrieren statt aus aktueller Welt übernehmen

## Art

- nein — Generator + Vektor-SVG + Docs, keine Comic-Rettung-Sprites

## Testplan

- Script läuft ohne Fehler; Output-JSON-Schema kompatibel zu `seuzach_roads.json`; Segmente nur Achsen/45°
- SVG öffnet mit viewBox=CLIP; Stichprobe Named Roads sichtbar; README erwähnt Trace, Script, Outputs und „Sandbox noch nicht umgestellt“
