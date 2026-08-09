#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
cd "$ROOT"
exec "$GODOT" --headless --path "$ROOT" -s res://tests/smoke_test.gd
