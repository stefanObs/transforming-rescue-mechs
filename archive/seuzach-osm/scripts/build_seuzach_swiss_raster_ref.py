#!/usr/bin/env python3
"""Build a Seuzach+Ohringen reference mosaic from Swiss Map Raster 10 sheets.

Sheets (docs/maps/, local only — gitignored):
  - swiss-map-raster10_2024_1072-1_krel_0.5_2056.tif  (Kirche, Bahnhof, Ohringen, Forrenberg)
  - swiss-map-raster10_2024_1052-3_krel_0.5_2056.tif  (Badi / north)

Output:
  docs/maps/seuzach_swiss_raster_ref.jpg
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image

Image.MAX_IMAGE_PIXELS = None

ROOT = Path(__file__).resolve().parents[1]
MAPS = ROOT / "docs" / "maps"
SHEET_S = MAPS / "swiss-map-raster10_2024_1072-1_krel_0.5_2056.tif"
SHEET_N = MAPS / "swiss-map-raster10_2024_1052-3_krel_0.5_2056.tif"
OUT = MAPS / "seuzach_swiss_raster_ref.jpg"

CHURCH_LAT = 47.5335012
CHURCH_LON = 8.7261235


def wgs84_to_lv95(lat: float, lon: float) -> tuple[float, float]:
    lat_s = lat * 3600.0
    lon_s = lon * 3600.0
    lat_aux = (lat_s - 169028.66) / 10000.0
    lon_aux = (lon_s - 26782.5) / 10000.0
    e = (
        2600072.37
        + 211455.93 * lon_aux
        - 10938.46 * lon_aux * lat_aux
        - 0.36 * lon_aux * lat_aux**2
        - 44.54 * lon_aux**3
    )
    n = (
        1200141.43
        + 308807.42 * lat_aux
        + 3745.25 * lon_aux**2
        + 76.63 * lat_aux**2
        - 194.56 * lon_aux**2 * lat_aux
        + 119.79 * lat_aux**3
    )
    return e, n


def sheet_meta(path: Path) -> tuple[Image.Image, float, float, float, float]:
    im = Image.open(path)
    tie = im.tag_v2[33922]
    sc = im.tag_v2[33550]
    e0, n0 = float(tie[3]), float(tie[4])
    sx, sy = float(sc[0]), float(sc[1])
    return im, e0, n0, sx, sy


def lv95_to_px(e: float, n: float, e0: float, n0: float, sx: float, sy: float) -> tuple[float, float]:
    return (e - e0) / sx, (n0 - n) / sy


def main() -> None:
    # Crop window around Seuzach in LV95 (covers Ohringen W → Bahnhof E, A1 S → Badi N)
    e_kirche, n_kirche = wgs84_to_lv95(CHURCH_LAT, CHURCH_LON)
    # ~±3.5 km E/W, ~2.5 km S, ~2.0 km N from Kirche
    e_min, e_max = e_kirche - 3500.0, e_kirche + 4000.0
    n_min, n_max = n_kirche - 3500.0, n_kirche + 2500.0

    south, e0s, n0s, sxs, sys = sheet_meta(SHEET_S)
    north, e0n, n0n, sxn, syn = sheet_meta(SHEET_N)

    # Mosaic in LV95: south sheet below N=1266000, north sheet above
    seam_n = 1266000.0
    # Output resolution: 2 m/px for a manageable preview (~ few thousand px)
    out_res = 2.0
    ow = int(math.ceil((e_max - e_min) / out_res))
    oh = int(math.ceil((n_max - n_min) / out_res))
    canvas = Image.new("RGB", (ow, oh), (230, 230, 220))

    def blit_from(sheet: Image.Image, e0: float, n0: float, sx: float, sy: float) -> None:
        # Sample region in sheet pixels
        c0, r0 = lv95_to_px(e_min, n_max, e0, n0, sx, sy)
        c1, r1 = lv95_to_px(e_max, n_min, e0, n0, sx, sy)
        left = int(max(0, math.floor(min(c0, c1))))
        right = int(min(sheet.size[0], math.ceil(max(c0, c1))))
        top = int(max(0, math.floor(min(r0, r1))))
        bottom = int(min(sheet.size[1], math.ceil(max(r0, r1))))
        if right - left < 2 or bottom - top < 2:
            return
        crop = sheet.crop((left, top, right, bottom))
        # Map crop corners back to LV95
        e_left = e0 + left * sx
        n_top = n0 - top * sy
        e_right = e0 + right * sx
        n_bot = n0 - bottom * sy
        # Paste into canvas
        dx = int(round((e_left - e_min) / out_res))
        dy = int(round((n_max - n_top) / out_res))
        tw = int(round((e_right - e_left) / out_res))
        th = int(round((n_top - n_bot) / out_res))
        if tw < 2 or th < 2:
            return
        resized = crop.resize((tw, th), Image.Resampling.BILINEAR)
        canvas.paste(resized, (dx, dy))

    blit_from(south, e0s, n0s, sxs, sys)
    blit_from(north, e0n, n0n, sxn, syn)

    # Mark Kirche
    kx = int(round((e_kirche - e_min) / out_res))
    ky = int(round((n_max - n_kirche) / out_res))
    from PIL import ImageDraw

    draw = ImageDraw.Draw(canvas)
    draw.ellipse((kx - 6, ky - 6, kx + 6, ky + 6), outline=(200, 30, 30), width=3)
    draw.text((kx + 10, ky - 10), "Kirche", fill=(180, 20, 20))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT, quality=90)
    print(f"wrote {OUT} ({ow}x{oh} @ {out_res} m/px)")
    print(f"LV95 window E {e_min:.0f}..{e_max:.0f}  N {n_min:.0f}..{n_max:.0f}")


if __name__ == "__main__":
    main()
