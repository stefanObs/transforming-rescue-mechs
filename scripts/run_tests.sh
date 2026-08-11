#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
cd "$ROOT"

echo "---- scripts/verify_art_alpha.py ----"
python3 scripts/verify_art_alpha.py

echo "---- tests/play_windows_launcher_test.py ----"
python3 tests/play_windows_launcher_test.py

FAILED=0
for test_script in tests/smoke_test.gd tests/m1_test.gd tests/m2_test.gd tests/m2_world_test.gd tests/m2_player_visual_test.gd tests/m2_transform_test.gd tests/m2_turn_test.gd tests/m2_facing_test.gd tests/m2_road_kit_test.gd tests/m2_walk_test.gd tests/m3_world_landmarks_test.gd tests/m3_hub_transition_test.gd tests/m3_building_occlusion_test.gd tests/m3_road_debug_test.gd; do
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
