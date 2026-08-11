#!/usr/bin/env python3
"""Regression: Windows launchers must start project mode so figures are visible."""
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PLAY = ROOT / "play-windows.bat"
RUN = ROOT / "Run_windows.bat"


def fail(msg: str) -> None:
    print(f"FAIL {msg}", file=sys.stderr)
    raise SystemExit(1)


def ok(msg: str) -> None:
    print(f"OK  {msg}")


def main() -> None:
    print("=== play_windows_launcher_test start ===")
    if not PLAY.is_file():
        fail("play-windows.bat exists")
    ok("play-windows.bat exists")
    if not RUN.is_file():
        fail("Run_windows.bat exists")
    ok("Run_windows.bat exists")

    play = PLAY.read_text(encoding="utf-8", errors="replace")
    run = RUN.read_text(encoding="utf-8", errors="replace")

    if not re.search(r'call\s+"%~dp0play-windows\.bat"', run):
        fail('Run_windows.bat must call "%~dp0play-windows.bat"')
    ok("Run_windows.bat calls %~dp0play-windows.bat")

    if "--path" not in play:
        fail("play-windows.bat launches Godot --path (project mode)")
    ok("play-windows.bat launches Godot --path (project mode)")

    if "--import" not in play:
        fail("play-windows.bat imports resources before run (figures need textures)")
    ok("play-windows.bat imports resources before run")
    if ".godot\\imported" not in play and ".godot/imported" not in play:
        fail("import is gated on .godot\\imported")
    ok("import is gated on .godot\\imported")

    if 'if /I "%PLAY_USE_EXPORT%"=="1"' not in play:
        fail('export must be wrapped in if /I "%PLAY_USE_EXPORT%"=="1"')
    ok("export is wrapped in PLAY_USE_EXPORT==1")

    unguarded = re.search(
        r'^if exist "%EXPORT_EXE%"',
        play,
        re.MULTILINE,
    )
    if unguarded:
        fail("must not launch export on mere if exist EXPORT_EXE")
    ok("no unguarded if exist EXPORT_EXE launch")
    if 'set "USE_EXPORT=1"' in play:
        fail("legacy USE_EXPORT=1 path must not return")
    ok("legacy USE_EXPORT=1 path removed")

    stale = play.lower()
    for needle in ("project.godot", "assets", "scripts", "scenes"):
        if needle not in stale:
            fail(f"export stale-check watches {needle}")
        ok(f"export stale-check watches {needle}")

    if "Starte Projektmodus mit aktuellen Figuren" not in play:
        fail("play-windows.bat announces project mode / current figures")
    ok("play-windows.bat announces project mode / current figures")

    print("=== play_windows_launcher_test PASS ===")


if __name__ == "__main__":
    main()
