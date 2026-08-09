#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
cd "$ROOT"

FAILED=0
for test_script in tests/smoke_test.gd tests/m1_test.gd tests/m2_test.gd; do
  echo "---- $test_script ----"
  if ! "$GODOT" --headless --path "$ROOT" -s "res://$test_script"; then
    FAILED=1
  fi
done

if [[ "$FAILED" -ne 0 ]]; then
  echo "TEST SUITE FAILED"
  exit 1
fi
echo "TEST SUITE PASSED"
exit 0
