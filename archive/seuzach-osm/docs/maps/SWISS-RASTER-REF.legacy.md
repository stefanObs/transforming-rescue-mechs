# Official Swiss map raster references

Large GeoTIFFs stay under `docs/maps/` locally — **do not commit** (hundreds of MB). Listed in `.gitignore`.

## Coverage vs Seuzach

Kirche Seuzach ≈ **E 2696945 / N 1265541** (CH1903+ / LV95).

| File | Sheet extent (LV95) | Covers |
|------|---------------------|--------|
| `swiss-map-raster10_2024_1072-1_krel_0.5_2056.tif` | E 2690000–2698750, N 1260000–1266000 | **Kirche, Bahnhof, Ohringen, Forrenberg** |
| `swiss-map-raster10_2024_1052-3_krel_0.5_2056.tif` | E 2690000–2698750, N 1266000–1272000 | **Badi** (north edge; village core is south on 1072-1) |
| `swiss-map-raster10_2024_1052-4_krel_0.5_2056.tif` | E 2698750–2707500, N 1266000–1272000 | East of Seuzach (not needed for core) |
| `swiss-map-raster10_2026_1071-2_krel_0.5_2056.tif` | E 2681250–2690000, N 1260000–1266000 | West — no Seuzach |
| `swiss-map-raster10_2026_1051-4_krel_0.5_2056.tif` | E 2681250–2690000, N 1266000–1272000 | West/north — no Seuzach |
| `swiss-map-raster10_2026_1051-4_kgrel_0.5_2056.tif` | same as 1051-4 colour | Greyscale duplicate |

**Primary Seuzach+Ohringen reference:** `1072-1` (+ `1052-3` for Badi / north fringe).

## Georef

- Product: Swiss Map Raster 10, 0.5 m/px, EPSG:2056

## Next use

Octilinear network (S04–S07): Swiss sheets **1072-1 + 1052-3** as map reference
(`scripts/build_seuzach_swiss_raster_ref.py`, `scripts/gen_seuzach_swiss_road_trace.py`,
`scripts/gen_seuzach_octilinear_roads.py`). Centerlines are named highways in sheet coverage,
checked against `seuzach_swiss_raster_ref.jpg` and `seuzach_zoom_verify_*.jpg`.

**Agent rule:** `.cursor/rules/swiss-raster-maps.mdc` (applies to map/octilinear paths).
