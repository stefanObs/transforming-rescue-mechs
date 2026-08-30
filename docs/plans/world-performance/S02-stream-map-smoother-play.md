# Slice: S02 — Stream map + smoother play

**Parent:** `docs/plans/world-performance/INDEX.md`  
**Hängt ab von:** S01

Nur der **Feature-Schritt** (typisch **zwei verwandte** / **zwei zusammengehörige** spieler-sichtbare Inkremente). Plan nur wenn nötig; Tests, Review, Playtest und Git sind der normale Ablauf für *dieses* Stück — nicht extra Slices.

INDEX-Status: `offen` → `in Arbeit` → `erledigt`. Dieses File nicht durch Phasen jagen.

## Feature

Schnelleres First Paint (Housing erst near-spawn), bessere FPS während des Spiels; Straßen bleiben vollständig befahrbar. Spieler merkt: Start zeigt nahe Umgebung sofort, weniger Ruckeln, HUD/Sprites/Polygone belasten weniger.

## In diesem Schritt

- Quarter lazy-load Housing über `housing_quarters`-IDs (nur near-spawn beim Start, Rest nachladen)
- Dash-Merge in `road_kit` (weniger Polygon2Ds statt ~1 Node pro Dash)
- HUD `_refresh_status` nur bei Änderung (kein Per-Frame-Refresh)
- Texture import `size_limit` ~512–768 für Houses/Landmarks

## Nicht (andere Feature-Schritte)

- Spatial road index / Texture cache / cheaper nudge / `_ready`-Timing (S01)
- Kartenlayout oder Straßennetz ändern; Roads müssen voll traversierbar bleiben
- Art neu zeichnen (nur Import-Limits / Runtime)

## Art

- nein — Import-Settings und Runtime; keine neuen PNGs

## Testplan

- First paint: nur near-spawn Housing sichtbar/geladen; entfernte Quartiere laden nach ohne starke Hitches; Straßen durchgängig befahrbar
- Weniger Polygon2D-/Sprite-Last bzw. spürbar glattere FPS; HUD aktualisiert nur bei Statuswechsel
- Unit: lazy near-spawn + `ensure_all_housing_loaded`; dash batch node count < legacy; status stable across `_process`

## Akzeptanz

- [ ] Start: WINT-WEST + KIRCHE-KERN (und near margin) geladen; Ohringen-Housing deferred
- [ ] `ensure_all_housing_loaded()` / `force_load_all_housing_quarters()` idempotent; Full-Map-Tests grün
- [ ] RoadKit-Dashes: 1 Stripe-Node pro Segment, weißes Dash-Look unverändert
- [ ] `_refresh_status` nicht mehr jedes Frame; Refresh bei Form/Char/Debug/Hub/Pause
- [ ] house_street_*/landmark_*.import: `process/size_limit=768`; Reimport gelaufen
- [ ] `./scripts/run_tests.sh` grün
