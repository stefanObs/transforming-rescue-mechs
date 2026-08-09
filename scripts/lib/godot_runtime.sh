#!/usr/bin/env bash
# Shared helpers for play-*.sh launchers. Source after ROOT is set.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.4.1}"
GODOT_TAG="${GODOT_TAG:-4.4.1-stable}"

find_system_godot() {
  if [[ -n "${GODOT:-}" && -x "${GODOT}" ]]; then
    echo "$GODOT"
    return 0
  fi
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi
  if command -v godot4 >/dev/null 2>&1; then
    command -v godot4
    return 0
  fi
  return 1
}

download() {
  local url="$1"
  local out="$2"
  if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$out" "$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar -o "$out" "$url"
  else
    echo "Fehler: weder wget noch curl gefunden — bitte eines davon installieren oder Godot setzen (GODOT=...)." >&2
    return 1
  fi
}

ensure_linux_godot() {
  local root="$1"
  local tools="$root/.tools"
  local bin="$tools/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
  if [[ -x "$bin" ]]; then
    echo "$bin"
    return 0
  fi
  mkdir -p "$tools"
  local zip="$tools/godot-linux.zip"
  local url="https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
  echo "Lade portables Godot ${GODOT_VERSION} (einmalig nach .tools/)…"
  download "$url" "$zip"
  unzip -o -q "$zip" -d "$tools"
  chmod +x "$bin"
  rm -f "$zip"
  echo "$bin"
}

ensure_macos_godot() {
  local root="$1"
  local tools="$root/.tools"
  local bin="$tools/Godot.app/Contents/MacOS/Godot"
  if [[ -x "$bin" ]]; then
    echo "$bin"
    return 0
  fi
  mkdir -p "$tools"
  local zip="$tools/godot-macos.zip"
  local url="https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/Godot_v${GODOT_VERSION}-stable_macos.universal.zip"
  echo "Lade portables Godot ${GODOT_VERSION} für macOS (einmalig nach .tools/)…"
  download "$url" "$zip"
  unzip -o -q "$zip" -d "$tools"
  chmod +x "$bin"
  rm -f "$zip"
  echo "$bin"
}
