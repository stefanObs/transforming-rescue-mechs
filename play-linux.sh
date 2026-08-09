#!/usr/bin/env bash
# Start Transformierende Rettungsmechs on Linux.
# Preference: fresh exported build → GODOT/PATH → portable download into .tools/
# Stale exports (older than project/art) are skipped so you see current sprites.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/godot_runtime.sh
source "$ROOT/scripts/lib/godot_runtime.sh"

EXPORT_BIN="$ROOT/build/linux/TransformierendeRettungsmechs.x86_64"

export_is_stale() {
  local bin="$1"
  [[ -x "$bin" ]] || return 0
  local bin_t project_t art_t
  bin_t="$(stat -c '%Y' "$bin")"
  project_t="$(stat -c '%Y' "$ROOT/project.godot")"
  art_t="$(find "$ROOT/assets/art" -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1)"
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

if [[ -x "$EXPORT_BIN" ]]; then
  echo "Hinweis: Export unter build/linux/ ist älter als Projekt/Art — starte Projektmodus (aktuelle Sprites)."
  echo "         Neu bauen: ./scripts/export_linux.sh"
fi

GODOT_BIN=""
if GODOT_BIN="$(find_system_godot)"; then
  echo "Starte mit System-Godot: $GODOT_BIN"
else
  GODOT_BIN="$(ensure_linux_godot "$ROOT")"
  echo "Starte mit portablem Godot: $GODOT_BIN"
fi

exec "$GODOT_BIN" --path "$ROOT" "$@"
