extends SceneTree
## RoadKit straight + roundabout produce meta-tagged Polygon2D pieces.

const RoadKitLib := preload("res://scripts/road_kit.gd")

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_road_kit_test start ===")
	_test_straight_and_roundabout()
	if _failed == 0:
		print("=== m2_road_kit_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_road_kit_test FAIL (%d) ===" % _failed)
		quit(1)


func _test_straight_and_roundabout() -> void:
	var parent := Node2D.new()
	root.add_child(parent)

	RoadKitLib.add_straight(parent, Vector2(0, 0), Vector2(200, 0), {
		"sidewalk": true,
		"centerline": true,
		"half_w": 40.0,
		"sidewalk_w": 12.0,
	})
	RoadKitLib.add_roundabout(parent, Vector2(400, 0), 80.0, 24.0, {
		"sidewalk": true,
		"centerline": true,
	})

	var counts := {"road": 0, "sidewalk": 0, "stripe": 0, "island": 0}
	var line2d := 0
	for child in parent.get_children():
		if child is Line2D:
			line2d += 1
		if child.has_meta("road_kit"):
			var key := str(child.get_meta("road_kit"))
			if counts.has(key):
				counts[key] = int(counts[key]) + 1

	_assert(line2d == 0, "RoadKit creates no Line2D (got %d)" % line2d)
	_assert(int(counts["road"]) >= 2, "road metas present (got %d)" % counts["road"])
	_assert(int(counts["sidewalk"]) >= 1, "sidewalk metas present (got %d)" % counts["sidewalk"])
	_assert(int(counts["stripe"]) >= 2, "stripe count >= 2 (got %d)" % counts["stripe"])
	_assert(int(counts["island"]) >= 1, "island meta present (got %d)" % counts["island"])

	parent.queue_free()


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
