#!/usr/bin/env python3
"""Docs regression: ~2× packing, skip planner, no duplicate playtest suite."""
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

ABLAUF = ROOT / "docs" / "ENTWICKLUNGSABLAUF.md"
SLICER = ROOT / ".cursor" / "agents" / "task-slicer.md"
RULE = ROOT / ".cursor" / "rules" / "entwicklungsablauf.mdc"
PLANNER = ROOT / ".cursor" / "agents" / "feature-planner.md"
PLAY = ROOT / ".cursor" / "agents" / "godot-playtester.md"

PACKING = re.compile(
    r"zwei verwandte|zwei zusammengehörige|~2|ca\.\s*2|2×|2x",
    re.IGNORECASE,
)
SKIP_PLANNER = re.compile(
    r"überspringen|Skip \(keine Doppelarbeit\)|Phase 1 skipped|skip-reason",
    re.IGNORECASE,
)
NO_DUP_SUITE = re.compile(
    r"keine doppelte Suite|Do \*\*not\*\* re-run `?\.?/scripts/run_tests\.sh",
    re.IGNORECASE,
)
DOCS_ONLY_NO_GODOT = re.compile(
    r"Docs-only.*kein Godot|kein Godot, kein Art-Alpha|\*\*kein Godot\*\*",
    re.IGNORECASE | re.DOTALL,
)
FORBID_WORKFLOW_SLICES = re.compile(
    r"Keine\*\* Slices für Review|Never slice review|\*\*Keine\*\* Slices für Review",
    re.IGNORECASE,
)
KEEP_REVIEW = re.compile(
    r"Code Review|code-reviewer",
    re.IGNORECASE,
)
KEEP_PLAYTEST = re.compile(
    r"Playtest|godot-playtester",
    re.IGNORECASE,
)
SPIELSICHTBAR_REQUIRED = re.compile(
    r"spielsichtbar",
    re.IGNORECASE,
)

# Old default packing without the 2× rule.
OLD_DEFAULTS = [
    "Houses = one house; maps = raster cells",
    "only this slice (one house, one raster cell, one behavior)",
    "**Häuser:** ein Haus / eine Variante / ein Landmark",
    "**Karte:** ein Quartier / eine Rasterzelle.",
    "Häuser einzeln, Karte in Quartiere",
]


def fail(msg: str) -> None:
    print(f"FAIL {msg}", file=sys.stderr)
    raise SystemExit(1)


def ok(msg: str) -> None:
    print(f"OK  {msg}")


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"missing {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def main() -> None:
    print("=== entwicklungsablauf_docs_test start ===")
    ablauf = read(ABLAUF)
    slicer = read(SLICER)
    rule = read(RULE)
    planner = read(PLANNER)
    play = read(PLAY)
    ok("living process files exist")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (SLICER, slicer, "task-slicer"),
        (RULE, rule, "entwicklungsablauf.mdc"),
    ):
        if not PACKING.search(text):
            fail(f"{label} must state ~2 / zwei verwandte / zwei zusammengehörige packing")
        ok(f"packing language in {label}")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (PLANNER, planner, "feature-planner"),
    ):
        if not SKIP_PLANNER.search(text):
            fail(f"{label} must document skip-planner / überspringen")
        ok(f"skip-planner in {label}")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (PLAY, play, "godot-playtester"),
    ):
        if not NO_DUP_SUITE.search(text):
            fail(f"{label} must forbid re-running a green full suite (keine doppelte Suite)")
        if not DOCS_ONLY_NO_GODOT.search(text):
            fail(f"{label} must say docs-only: kein Godot")
        ok(f"playtest dedup + docs-only no Godot in {label}")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (SLICER, slicer, "task-slicer"),
        (RULE, rule, "entwicklungsablauf.mdc"),
    ):
        if not FORBID_WORKFLOW_SLICES.search(text):
            fail(f"{label} must still forbid Review/Test/Git as slices")
        ok(f"forbid workflow slices in {label}")

    if not KEEP_REVIEW.search(ablauf) or not KEEP_PLAYTEST.search(ablauf):
        fail("ENTWICKLUNGSABLAUF must still name code-review and playtest")
    if not SPIELSICHTBAR_REQUIRED.search(ablauf):
        fail("ENTWICKLUNGSABLAUF must still require gates for spielsichtbare Arbeit")
    if re.search(
        r"Code-Review oder Playtest für spielsichtbare Slices abschaffen",
        ablauf,
        re.IGNORECASE,
    ):
        fail("ENTWICKLUNGSABLAUF must not drop review/playtest for game-visible slices")
    # Positive keep: review and playtest are Pflicht, not skipped for spielsichtbar.
    if not re.search(
        r"nicht mit Playtest zusammenlegen, nicht überspringen",
        ablauf,
    ):
        fail("ENTWICKLUNGSABLAUF must keep code-review as a separate required gate")
    if not re.search(r"Phase 3\+4 bleiben Pflicht für spielsichtbare Arbeit", ablauf):
        fail("Hotfix path must still require phase 3+4 for game-visible work")
    ok("code-review + playtest still required for spielsichtbar")

    for phrase in OLD_DEFAULTS:
        for label, text in (
            ("ENTWICKLUNGSABLAUF", ablauf),
            ("task-slicer", slicer),
            ("entwicklungsablauf.mdc", rule),
            ("feature-planner", planner),
        ):
            if phrase in text:
                fail(f"{label} still has old single-item default {phrase!r}")
    ok("no old single-house / single-cell default without 2× rule")

    iso = ROOT / "docs" / "ENTWICKLUNGSABLAUF.md"
    iso_text = ablauf
    if "Haus–Strasse" not in iso_text and "Haus–Strasse-Interaktion" not in iso_text:
        fail("ENTWICKLUNGSABLAUF must keep iso-map Haus–Strasse interaction wording")
    if "Masse/Kamera/Größe" not in iso_text:
        fail("ENTWICKLUNGSABLAUF must keep iso-map not Masse/Kamera/Größe")
    if "c-umgebung" not in iso_text or "c-basis" not in iso_text:
        fail("ENTWICKLUNGSABLAUF must keep c-umgebung / c-basis proportions")
    ok("iso-map sentences kept in ENTWICKLUNGSABLAUF")

    print("=== entwicklungsablauf_docs_test passed ===")


if __name__ == "__main__":
    main()
