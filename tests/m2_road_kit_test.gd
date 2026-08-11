extends SceneTree
## RoadKit straight + roundabout produce meta-tagged Polygon2D pieces.

const RoadKitLib := preload("res://scripts/road_kit.gd")

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_road_kit_test start ===")
	_test_straight_and_roundabout()
	_test_roundabout_default_no_centerline()
	_test_roundabout_centerline_opt_in()
	_test_polyline_covers_bend_corner()
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
	# Roundabout without centerline (default false) — stripes come from straight only.
	RoadKitLib.add_roundabout(parent, Vector2(400, 0), 80.0, 24.0, {
		"sidewalk": true,
	})

	var counts := _count_road_kit(parent)
	var line2d := _count_line2d(parent)

	_assert(line2d == 0, "RoadKit creates no Line2D (got %d)" % line2d)
	_assert(int(counts["road"]) >= 2, "road metas present (got %d)" % counts["road"])
	_assert(int(counts["sidewalk"]) >= 1, "sidewalk metas present (got %d)" % counts["sidewalk"])
	_assert(int(counts["stripe"]) >= 1, "straight centerline stripes >= 1 (got %d)" % counts["stripe"])
	_assert(int(counts["island"]) >= 1, "island meta present (got %d)" % counts["island"])

	parent.queue_free()


func _test_roundabout_default_no_centerline() -> void:
	var parent := Node2D.new()
	root.add_child(parent)

	RoadKitLib.add_roundabout(parent, Vector2(0, 0), 80.0, 24.0, {
		"sidewalk": true,
	})

	var counts := _count_road_kit(parent)
	_assert(int(counts["stripe"]) == 0, "roundabout default has no stripe (got %d)" % counts["stripe"])
	_assert(int(counts["island"]) >= 1, "roundabout island present (got %d)" % counts["island"])
	_assert(int(counts["road"]) >= 1, "roundabout road present (got %d)" % counts["road"])

	parent.queue_free()


func _test_roundabout_centerline_opt_in() -> void:
	var parent := Node2D.new()
	root.add_child(parent)

	RoadKitLib.add_roundabout(parent, Vector2(0, 0), 80.0, 24.0, {
		"centerline": true,
	})

	var counts := _count_road_kit(parent)
	_assert(int(counts["stripe"]) >= 1, "roundabout centerline opt-in stripes >= 1 (got %d)" % counts["stripe"])

	parent.queue_free()


func _test_polyline_covers_bend_corner() -> void:
	## L-bend used to leave a grass wedge at the outer elbow (two rectangles).
	var parent := Node2D.new()
	root.add_child(parent)
	RoadKitLib.add_polyline(
		parent,
		[Vector2(0, 0), Vector2(200, 0), Vector2(200, 200)],
		{"sidewalk": false, "centerline": false, "half_w": 40.0}
	)
	var road: Polygon2D = null
	for child in parent.get_children():
		if child is Polygon2D and str(child.get_meta("road_kit", "")) == "road":
			road = child as Polygon2D
			break
	_assert(road != null, "polyline creates one road polygon")
	if road:
		_assert(road.polygon.size() >= 6, "mitered strip has both sides (got %d verts)" % road.polygon.size())
		## Outer elbow of a right turn (+Y south): east of the bend, north of the first segment.
		var outer := Vector2(228, -28)
		_assert(
			Geometry2D.is_point_in_polygon(outer, road.polygon),
			"outer bend corner is asphalt, not grass (sample %s)" % str(outer)
		)
		var inner := Vector2(172, 28)
		_assert(
			Geometry2D.is_point_in_polygon(inner, road.polygon),
			"inner bend corner is asphalt (sample %s)" % str(inner)
		)
	var counts := _count_road_kit(parent)
	_assert(int(counts["road"]) == 1, "polyline is a single road poly (got %d)" % counts["road"])
	parent.queue_free()


func _count_road_kit(parent: Node) -> Dictionary:
	var counts := {"road": 0, "sidewalk": 0, "stripe": 0, "island": 0, "junction": 0}
	for child in parent.get_children():
		if child.has_meta("road_kit"):
			var key := str(child.get_meta("road_kit"))
			if counts.has(key):
				counts[key] = int(counts[key]) + 1
	return counts


func _count_line2d(parent: Node) -> int:
	var line2d := 0
	for child in parent.get_children():
		if child is Line2D:
			line2d += 1
	return line2d


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
