#!/usr/bin/env python3
"""Docs regression: c-iso-city-map.png is house–street interaction, not scale."""
from __future__ import annotations

from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

LIVING = [
    ROOT / ".cursor" / "agents" / "comic-rettung-art.md",
    ROOT / ".cursor" / "rules" / "comic-rettung-art.mdc",
    ROOT / "docs" / "STYLE-BIBLE-C.md",
    ROOT / "docs" / "ENTWICKLUNGSABLAUF.md",
    ROOT / "docs" / "design-refs" / "c-iso-city-map.source.md",
]

# GenerateImage wiring lives in agent + rule (+ bible mentions the tool arg).
REF_PATH_FILES = LIVING[:3]

OLD_COPY_PHRASES = [
    "Blockmasse",
    "chunky blocks",
    "orients layout and block mass",
    "Iso-Stadt-Orientierung: Blockmasse",
    "Übernehmen: Blockmasse",
]


def fail(msg: str) -> None:
    print(f"FAIL {msg}", file=sys.stderr)
    raise SystemExit(1)


def ok(msg: str) -> None:
    print(f"OK  {msg}")


def main() -> None:
    print("=== iso_map_interaction_docs_test start ===")
    texts: dict[Path, str] = {}
    for path in LIVING:
        if not path.is_file():
            fail(f"missing living file {path.relative_to(ROOT)}")
        texts[path] = path.read_text(encoding="utf-8")
        ok(f"exists {path.relative_to(ROOT)}")

    for path, text in texts.items():
        rel = path.relative_to(ROOT)
        if "c-iso-city-map" not in text:
            fail(f"{rel} must still name c-iso-city-map")
        ok(f"c-iso-city-map in {rel}")
        for phrase in OLD_COPY_PHRASES:
            if phrase in text:
                fail(f"{rel} must not treat iso map as dimensions ({phrase!r})")
        ok(f"no dimension copy-target in {rel}")

    interaction = re.compile(
        r"Interaktion|street–house|street-house|Haus–Strasse|along|"
        r"entlang|Korridor|corridor|Straßenbänder|street ribbons",
        re.IGNORECASE,
    )
    for path, text in texts.items():
        rel = path.relative_to(ROOT)
        if not interaction.search(text):
            fail(f"{rel} must describe house–street interaction / along-ribbon layout")
        ok(f"interaction language in {rel}")

    proportions = re.compile(r"c-umgebung", re.IGNORECASE)
    basis = re.compile(r"c-basis", re.IGNORECASE)
    for path, text in texts.items():
        rel = path.relative_to(ROOT)
        if not (proportions.search(text) and basis.search(text)):
            fail(f"{rel} must point size/proportions at c-umgebung and c-basis")
        ok(f"umgebung+basis in {rel}")

    for path in REF_PATH_FILES:
        text = texts[path]
        rel = path.relative_to(ROOT)
        if "reference_image_paths" not in text:
            fail(f"{rel} must keep reference_image_paths for the iso map")
        if "c-umgebung" not in text or "c-basis" not in text:
            fail(f"{rel} must pass iso map together with c-umgebung / c-basis")
        together = (
            "zusammen mit" in text
            or "together with" in text
            or "together with `c-umgebung" in text
        )
        if not together:
            fail(f"{rel} must say iso map is used together with umgebung/basis")
        ok(f"reference_image_paths + umgebung/basis in {rel}")

    implementer = ROOT / ".cursor" / "agents" / "feature-implementer.md"
    if implementer.is_file():
        impl = implementer.read_text(encoding="utf-8")
        if re.search(r"iso-city-map|Blockmasse", impl):
            fail("feature-implementer.md must not treat iso map as block mass/scale")
        ok("feature-implementer.md has no iso-map scale language")

    art_diff = subprocess.run(
        ["git", "diff", "--", "assets/art/"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if art_diff.returncode != 0:
        fail("git diff -- assets/art/ failed")
    if art_diff.stdout.strip() or art_diff.stderr.strip():
        fail("assets/art/ must be unchanged (S01 is docs-only)")
    ok("assets/art/ diff empty")

    png = ROOT / "docs" / "design-refs" / "c-iso-city-map.png"
    if not png.is_file():
        fail("c-iso-city-map.png must still exist")
    png_diff = subprocess.run(
        ["git", "diff", "--", "docs/design-refs/c-iso-city-map.png"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if png_diff.returncode != 0:
        fail("git diff of c-iso-city-map.png failed")
    if png_diff.stdout.strip():
        fail("c-iso-city-map.png binary must be unchanged")
    ok("c-iso-city-map.png unchanged")

    print("=== iso_map_interaction_docs_test passed ===")


if __name__ == "__main__":
    main()
