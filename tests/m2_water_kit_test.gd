extends SceneTree
## WaterKit bank + water: meta-tagged Polygon2D, no Line2D, mitered bends.

const WaterKitLib := preload("res://scripts/water_kit.gd")

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_water_kit_test start ===")
	_test_polyline_water_and_bank()
	_test_polyline_covers_bend_corner()
	_test_empty_polyline_is_noop()
	if _failed == 0:
		print("=== m2_water_kit_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_water_kit_test FAIL (%d) ===" % _failed)
		quit(1)


func _test_polyline_water_and_bank() -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	WaterKitLib.add_polyline(
		parent,
		[Vector2(0, 0), Vector2(200, 0)],
		{"half_w": 16.0}
	)
	var counts := _count_water_kit(parent)
	var line2d := _count_line2d(parent)
	_assert(line2d == 0, "WaterKit creates no Line2D (got %d)" % line2d)
	_assert(int(counts["water"]) == 1, "one water meta (got %d)" % counts["water"])
	_assert(int(counts["bank"]) == 1, "one bank meta (got %d)" % counts["bank"])
	_assert(_count_road_kit(parent) == 0, "WaterKit does not set road_kit")
	_assert(_count_railway_kit(parent) == 0, "WaterKit does not set railway_kit")
	var water: Polygon2D = null
	for child in parent.get_children():
		if child is Polygon2D and str(child.get_meta("water_kit", "")) == "water":
			water = child as Polygon2D
			break
	_assert(water != null, "water polygon present")
	if water:
		_assert(water.z_index == -45, "water z_index is -45 (got %d)" % water.z_index)
		_assert(
			water.color.is_equal_approx(Color("2E8FD4")),
			"water color is #2E8FD4 (got %s)" % str(water.color)
		)
	parent.queue_free()


func _test_polyline_covers_bend_corner() -> void:
	## L-bend must fill the outer elbow (miter), not leave a grass wedge.
	var parent := Node2D.new()
	root.add_child(parent)
	WaterKitLib.add_polyline(
		parent,
		[Vector2(0, 0), Vector2(200, 0), Vector2(200, 200)],
		{"half_w": 16.0}
	)
	var water: Polygon2D = null
	for child in parent.get_children():
		if child is Polygon2D and str(child.get_meta("water_kit", "")) == "water":
			water = child as Polygon2D
			break
	_assert(water != null, "polyline creates one water polygon")
	if water:
		_assert(
			water.polygon.size() >= 6,
			"mitered strip has both sides (got %d verts)" % water.polygon.size()
		)
		var outer := Vector2(211, -11)
		_assert(
			Geometry2D.is_point_in_polygon(outer, water.polygon),
			"outer bend corner is water (sample %s)" % str(outer)
		)
		var inner := Vector2(189, 11)
		_assert(
			Geometry2D.is_point_in_polygon(inner, water.polygon),
			"inner bend corner is water (sample %s)" % str(inner)
		)
	var line2d := _count_line2d(parent)
	_assert(line2d == 0, "mitered water polyline has no Line2D")
	parent.queue_free()


func _test_empty_polyline_is_noop() -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	WaterKitLib.add_polyline(parent, [], {})
	WaterKitLib.add_polyline(parent, [Vector2(1, 1)], {})
	_assert(parent.get_child_count() == 0, "short/empty geometry adds no nodes (got %d)" % parent.get_child_count())
	parent.queue_free()


func _count_water_kit(parent: Node) -> Dictionary:
	var counts := {"water": 0, "bank": 0}
	for child in parent.get_children():
		if child.has_meta("water_kit"):
			var key := str(child.get_meta("water_kit"))
			if counts.has(key):
				counts[key] = int(counts[key]) + 1
	return counts


func _count_road_kit(parent: Node) -> int:
	var n := 0
	for child in parent.get_children():
		if child.has_meta("road_kit"):
			n += 1
	return n


func _count_railway_kit(parent: Node) -> int:
	var n := 0
	for child in parent.get_children():
		if child.has_meta("railway_kit"):
			n += 1
	return n


func _count_line2d(parent: Node) -> int:
	var n := 0
	if parent is Line2D:
		n += 1
	for child in parent.get_children():
		n += _count_line2d(child)
	return n


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
