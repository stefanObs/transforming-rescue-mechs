#!/usr/bin/env bash
# Start Transformierende Rettungsmechs on macOS without a preinstalled Godot editor.
# Preference: exported .app → GODOT/PATH → portable Godot.app in .tools/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/godot_runtime.sh
source "$ROOT/scripts/lib/godot_runtime.sh"

EXPORT_APP="$ROOT/build/macos/TransformierendeRettungsmechs.app"
EXPORT_BIN="$EXPORT_APP/Contents/MacOS/TransformierendeRettungsmechs"

if [[ -x "$EXPORT_BIN" ]]; then
  echo "Starte exportiertes Spiel…"
  exec "$EXPORT_BIN" "$@"
fi
if [[ -d "$EXPORT_APP" ]]; then
  echo "Starte exportiertes .app…"
  exec open "$EXPORT_APP" --args "$@"
fi

GODOT_BIN=""
if GODOT_BIN="$(find_system_godot)"; then
  echo "Starte mit System-Godot: $GODOT_BIN"
else
  GODOT_BIN="$(ensure_macos_godot "$ROOT")"
  echo "Starte mit portablem Godot: $GODOT_BIN"
fi

exec "$GODOT_BIN" --path "$ROOT" "$@"
