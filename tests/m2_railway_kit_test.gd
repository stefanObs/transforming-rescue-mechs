extends SceneTree
## RailwayKit ballast + rails: meta-tagged Polygon2D, no Line2D, mitered bends.

const RailwayKitLib := preload("res://scripts/railway_kit.gd")

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_railway_kit_test start ===")
	_test_polyline_ballast_and_rails()
	_test_polyline_covers_bend_corner()
	_test_platform()
	_test_empty_polyline_is_noop()
	if _failed == 0:
		print("=== m2_railway_kit_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_railway_kit_test FAIL (%d) ===" % _failed)
		quit(1)


func _test_polyline_ballast_and_rails() -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	RailwayKitLib.add_polyline(
		parent,
		[Vector2(0, 0), Vector2(200, 0)],
		{"half_w": 38.0}
	)
	var counts := _count_railway_kit(parent)
	var line2d := _count_line2d(parent)
	_assert(line2d == 0, "RailwayKit creates no Line2D (got %d)" % line2d)
	_assert(int(counts["ballast"]) == 1, "one ballast meta (got %d)" % counts["ballast"])
	_assert(int(counts["rail"]) == 2, "two rail metas (got %d)" % counts["rail"])
	_assert(int(counts["platform"]) == 0, "polyline is not a platform")
	_assert(_count_road_kit(parent) == 0, "RailwayKit does not set road_kit")
	parent.queue_free()


func _test_polyline_covers_bend_corner() -> void:
	## L-bend must fill the outer elbow (miter), not leave a grass wedge.
	var parent := Node2D.new()
	root.add_child(parent)
	RailwayKitLib.add_polyline(
		parent,
		[Vector2(0, 0), Vector2(200, 0), Vector2(200, 200)],
		{"half_w": 38.0}
	)
	var ballast: Polygon2D = null
	for child in parent.get_children():
		if child is Polygon2D and str(child.get_meta("railway_kit", "")) == "ballast":
			ballast = child as Polygon2D
			break
	_assert(ballast != null, "polyline creates one ballast polygon")
	if ballast:
		_assert(
			ballast.polygon.size() >= 6,
			"mitered strip has both sides (got %d verts)" % ballast.polygon.size()
		)
		var outer := Vector2(226, -26)
		_assert(
			Geometry2D.is_point_in_polygon(outer, ballast.polygon),
			"outer bend corner is ballast (sample %s)" % str(outer)
		)
		var inner := Vector2(174, 26)
		_assert(
			Geometry2D.is_point_in_polygon(inner, ballast.polygon),
			"inner bend corner is ballast (sample %s)" % str(inner)
		)
	var line2d := _count_line2d(parent)
	_assert(line2d == 0, "mitered railway polyline has no Line2D")
	parent.queue_free()


func _test_platform() -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	RailwayKitLib.add_platform(
		parent,
		[Vector2(0, 0), Vector2(80, 0), Vector2(80, 20), Vector2(0, 20)]
	)
	var counts := _count_railway_kit(parent)
	_assert(int(counts["platform"]) == 1, "platform meta present (got %d)" % counts["platform"])
	_assert(_count_line2d(parent) == 0, "platform is Polygon2D, not Line2D")
	parent.queue_free()


func _test_empty_polyline_is_noop() -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	RailwayKitLib.add_polyline(parent, [], {})
	RailwayKitLib.add_polyline(parent, [Vector2(1, 1)], {})
	RailwayKitLib.add_platform(parent, [Vector2(0, 0), Vector2(10, 0)])
	_assert(parent.get_child_count() == 0, "short/empty geometry adds no nodes (got %d)" % parent.get_child_count())
	parent.queue_free()


func _count_railway_kit(parent: Node) -> Dictionary:
	var counts := {"ballast": 0, "rail": 0, "platform": 0}
	for child in parent.get_children():
		if child.has_meta("railway_kit"):
			var key := str(child.get_meta("railway_kit"))
			if counts.has(key):
				counts[key] = int(counts[key]) + 1
	return counts


func _count_road_kit(parent: Node) -> int:
	var n := 0
	for child in parent.get_children():
		if child.has_meta("road_kit"):
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
