#!/usr/bin/env bash
# Export a standalone Linux build into build/linux/ (requires Godot export templates).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
OUT_DIR="$ROOT/build/linux"
OUT_BIN="$OUT_DIR/TransformierendeRettungsmechs.x86_64"

mkdir -p "$OUT_DIR"
echo "Exportiere Linux-Release nach $OUT_BIN …"
"$GODOT" --headless --path "$ROOT" --export-release "Linux" "$OUT_BIN"
chmod +x "$OUT_BIN" || true
echo "Fertig. Start: ./play-linux.sh  oder  $OUT_BIN"
