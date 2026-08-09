#!/usr/bin/env bash
# Start Transformierende Rettungsmechs on Linux without a preinstalled Godot editor.
# Preference: exported build → GODOT/PATH → portable download into .tools/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/godot_runtime.sh
source "$ROOT/scripts/lib/godot_runtime.sh"

EXPORT_BIN="$ROOT/build/linux/TransformierendeRettungsmechs.x86_64"

if [[ -x "$EXPORT_BIN" ]]; then
  echo "Starte exportiertes Spiel…"
  exec "$EXPORT_BIN" "$@"
fi

GODOT_BIN=""
if GODOT_BIN="$(find_system_godot)"; then
  echo "Starte mit System-Godot: $GODOT_BIN"
else
  GODOT_BIN="$(ensure_linux_godot "$ROOT")"
  echo "Starte mit portablem Godot: $GODOT_BIN"
fi

exec "$GODOT_BIN" --path "$ROOT" "$@"
