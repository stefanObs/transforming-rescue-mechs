#!/usr/bin/env python3
"""Docs regression: Fast-Path, ~2× packing, skip planner, verifier dedup."""
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

ABLAUF = ROOT / "docs" / "ENTWICKLUNGSABLAUF.md"
SLICER = ROOT / ".cursor" / "agents" / "task-slicer.md"
RULE = ROOT / ".cursor" / "rules" / "entwicklungsablauf.mdc"
PLANNER = ROOT / ".cursor" / "agents" / "feature-planner.md"
VERIFY = ROOT / ".cursor" / "agents" / "automated-verifier.md"
IMPLEMENTER = ROOT / ".cursor" / "agents" / "feature-implementer.md"

PACKING = re.compile(
    r"zwei verwandte|zwei zusammengehörige|~2|ca\.\s*2|2×|2x",
    re.IGNORECASE,
)
FAST_PATH = re.compile(r"Fast-Path|FastPath|Parent-Fast-Path", re.IGNORECASE)
SKIP_PLANNER = re.compile(
    r"überspringen|Skip immediately|Phase 1 skipped|skip-reason",
    re.IGNORECASE,
)
NO_DUP_SUITE = re.compile(
    r"Keine doppelte Suite|do not re-run the suite|suite green: yes",
    re.IGNORECASE,
)
DOCS_ONLY_NO_GODOT = re.compile(
    r"Docs-only.*kein Game-Launch|docs-only = read-through|kein Game-Launch|no Godot launch",
    re.IGNORECASE | re.DOTALL,
)
FORBID_WORKFLOW_SLICES = re.compile(
    r"Keine\*\* Slices für Review|Never slice|Keine.*Slices für Review",
    re.IGNORECASE,
)
KEEP_REVIEW = re.compile(r"Code Review|code-reviewer", re.IGNORECASE)
KEEP_VERIFY = re.compile(r"automated-verifier|Verifier", re.IGNORECASE)
PLAN_MODE_FIRST = re.compile(r"SwitchMode|Plan-Modus zuerst", re.IGNORECASE)
PHYSICAL_ON_REQUEST = re.compile(
    r"nur auf \*\*explizite User-Anforderung\*\*|only if the user (explicitly )?asked|nur auf User-Anforderung",
    re.IGNORECASE,
)

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
    verify = read(VERIFY)
    implementer = read(IMPLEMENTER)
    ok("living process files exist")

    if (ROOT / ".cursor" / "agents" / "godot-playtester.md").exists():
        fail("godot-playtester.md must be removed; use automated-verifier")
    ok("godot-playtester replaced by automated-verifier")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (SLICER, slicer, "task-slicer"),
        (RULE, rule, "entwicklungsablauf.mdc"),
    ):
        if not PACKING.search(text):
            fail(f"{label} must state ~2 / zwei verwandte packing")
        ok(f"packing language in {label}")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (RULE, rule, "entwicklungsablauf.mdc"),
        (SLICER, slicer, "task-slicer"),
    ):
        if not FAST_PATH.search(text):
            fail(f"{label} must document Parent Fast-Path")
        ok(f"Fast-Path in {label}")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (PLANNER, planner, "feature-planner"),
    ):
        if not SKIP_PLANNER.search(text):
            fail(f"{label} must document skip-planner")
        if not PLAN_MODE_FIRST.search(text):
            fail(f"{label} must require SwitchMode / Plan-Modus zuerst")
        ok(f"skip-planner + plan-mode-first in {label}")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (VERIFY, verify, "automated-verifier"),
    ):
        if not NO_DUP_SUITE.search(text):
            fail(f"{label} must forbid re-running a green full suite")
        if not DOCS_ONLY_NO_GODOT.search(text):
            fail(f"{label} must say docs-only: no Godot launch")
        ok(f"verifier dedup + docs-only in {label}")

    if not PHYSICAL_ON_REQUEST.search(ablauf):
        fail("ENTWICKLUNGSABLAUF must gate physical play on user request")
    ok("physical play only on request")

    for path, text, label in (
        (ABLAUF, ablauf, "ENTWICKLUNGSABLAUF"),
        (SLICER, slicer, "task-slicer"),
        (RULE, rule, "entwicklungsablauf.mdc"),
    ):
        if not FORBID_WORKFLOW_SLICES.search(text):
            fail(f"{label} must forbid Review/Test/Git as slices")
        ok(f"forbid workflow slices in {label}")

    if not KEEP_REVIEW.search(ablauf) or not KEEP_VERIFY.search(ablauf):
        fail("ENTWICKLUNGSABLAUF must name code-reviewer and automated-verifier")
    if re.search(r"immer zuerst.*task-slicer", ablauf, re.IGNORECASE | re.DOTALL):
        # Old wording required slicer always; Fast-Path must win.
        if "nur ab Größe" not in ablauf and "nur wenn" not in ablauf.lower():
            fail("ENTWICKLUNGSABLAUF must not always require task-slicer first")
    ok("review + verifier named; slicer not always-first")

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

    if "Haus–Strasse" not in ablauf and "Haus–Strasse-Interaktion" not in ablauf:
        fail("ENTWICKLUNGSABLAUF must keep iso-map Haus–Strasse interaction wording")
    if "Masse/Kamera/Größe" not in ablauf:
        fail("ENTWICKLUNGSABLAUF must keep iso-map not Masse/Kamera/Größe")
    if "c-umgebung" not in ablauf or "c-basis" not in ablauf:
        fail("ENTWICKLUNGSABLAUF must keep c-umgebung / c-basis proportions")
    ok("iso-map sentences kept in ENTWICKLUNGSABLAUF")

    art = read(ROOT / ".cursor" / "agents" / "comic-rettung-art.md")
    art_rule = read(ROOT / ".cursor" / "rules" / "comic-rettung-art.mdc")
    asphalt = re.compile(r"asphalt|Asphalt|RoadKit", re.IGNORECASE)
    bearing = re.compile(
        r"bearing|street-aligned|parallel.*street|E–W|E-W|N–S|N-S|nie Asphalt|_ew|_ns",
        re.IGNORECASE,
    )
    for label, text in (
        ("comic-rettung-art.md", art),
        ("feature-implementer.md", implementer),
        ("feature-planner.md", planner),
        ("comic-rettung-art.mdc", art_rule),
        ("automated-verifier.md", verify),
    ):
        if not asphalt.search(text):
            fail(f"{label} must mention asphalt / RoadKit clearance")
        if not bearing.search(text) and label != "automated-verifier.md":
            fail(f"{label} must mention street-aligned / bearing")
        ok(f"asphalt clearance language in {label}")

    if "Art: ja" not in implementer and "Art: ja" not in art:
        fail("implementer or art agent must gate on Art: ja + filenames")
    ok("Art: ja gate present")

    print("=== entwicklungsablauf_docs_test passed ===")


if __name__ == "__main__":
    main()
