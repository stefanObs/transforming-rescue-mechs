#!/usr/bin/env bash
# Start Transformierende Rettungsmechs on macOS.
# Stale exports are skipped so current sprites are visible.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/godot_runtime.sh
source "$ROOT/scripts/lib/godot_runtime.sh"

EXPORT_APP="$ROOT/build/macos/TransformierendeRettungsmechs.app"
EXPORT_BIN="$EXPORT_APP/Contents/MacOS/TransformierendeRettungsmechs"

export_is_stale() {
  local path="$1"
  [[ -e "$path" ]] || return 0
  local bin_t project_t art_t
  bin_t="$(stat -f '%m' "$path" 2>/dev/null || stat -c '%Y' "$path")"
  project_t="$(stat -f '%m' "$ROOT/project.godot" 2>/dev/null || stat -c '%Y' "$ROOT/project.godot")"
  art_t="$(find "$ROOT/assets/art" -type f -print0 2>/dev/null | xargs -0 stat -f '%m' 2>/dev/null | sort -n | tail -1)"
  art_t="${art_t:-0}"
  if (( project_t > bin_t )) || (( art_t > bin_t )); then
    return 0
  fi
  return 1
}

if [[ -x "$EXPORT_BIN" ]] && ! export_is_stale "$EXPORT_BIN"; then
  echo "Starte exportiertes Spiel…"
  exec "$EXPORT_BIN" "$@"
fi
if [[ -d "$EXPORT_APP" ]] && ! export_is_stale "$EXPORT_APP"; then
  echo "Starte exportiertes .app…"
  exec open "$EXPORT_APP" --args "$@"
fi

if [[ -x "$EXPORT_BIN" || -d "$EXPORT_APP" ]]; then
  echo "Hinweis: macOS-Export ist veraltet — starte Projektmodus (aktuelle Sprites)."
fi

GODOT_BIN=""
if GODOT_BIN="$(find_system_godot)"; then
  echo "Starte mit System-Godot: $GODOT_BIN"
else
  GODOT_BIN="$(ensure_macos_godot "$ROOT")"
  echo "Starte mit portablem Godot: $GODOT_BIN"
fi

exec "$GODOT_BIN" --path "$ROOT" "$@"
