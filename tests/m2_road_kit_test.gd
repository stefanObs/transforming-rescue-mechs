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
	_test_dashed_line_batches_stripes()
	_test_polyline_covers_bend_corner()
	_test_readable_label_rotation()
	_test_label_samples_follow_tangent()
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


func _test_dashed_line_batches_stripes() -> void:
	## S02: one stripe node per dashed segment; dash_count still covers full length.
	var parent := Node2D.new()
	root.add_child(parent)

	var length := 320.0
	var dash_len := 18.0
	var gap_len := 14.0
	RoadKitLib.add_straight(parent, Vector2(0, 0), Vector2(length, 0), {
		"centerline": true,
		"half_w": 40.0,
		"dash_len": dash_len,
		"gap_len": gap_len,
	})

	var stripe_nodes := 0
	var dash_total := 0
	for child in parent.get_children():
		if child.has_meta("road_kit") and str(child.get_meta("road_kit")) == "stripe":
			stripe_nodes += 1
			if child.has_meta("dash_count"):
				dash_total += int(child.get_meta("dash_count"))
	## Pre-merge baseline for this length: ~ceil(length / (dash+gap)) Polygon2Ds (~10).
	var period := dash_len + gap_len
	var legacy_min := int(floor((length - 0.5) / period)) + 1
	_assert(stripe_nodes == 1, "dashed segment uses 1 stripe node (got %d)" % stripe_nodes)
	_assert(dash_total >= 2, "batch still draws multiple dashes (got %d)" % dash_total)
	_assert(
		stripe_nodes < legacy_min,
		"stripe nodes (%d) < legacy per-dash count (%d)" % [stripe_nodes, legacy_min]
	)

	## Roundabout centerline opt-in also batches into one stripe node.
	var parent2 := Node2D.new()
	root.add_child(parent2)
	RoadKitLib.add_roundabout(parent2, Vector2(0, 0), 80.0, 24.0, {"centerline": true})
	var rb_stripes := 0
	var rb_dashes := 0
	for child in parent2.get_children():
		if child.has_meta("road_kit") and str(child.get_meta("road_kit")) == "stripe":
			rb_stripes += 1
			if child.has_meta("dash_count"):
				rb_dashes += int(child.get_meta("dash_count"))
	_assert(rb_stripes == 1, "roundabout centerline uses 1 stripe node (got %d)" % rb_stripes)
	_assert(rb_dashes >= 2, "roundabout batch has multiple dashes (got %d)" % rb_dashes)

	parent.queue_free()
	parent2.queue_free()


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


func _test_readable_label_rotation() -> void:
	var east: float = RoadKitLib.readable_label_rotation(Vector2(1, 0))
	var west: float = RoadKitLib.readable_label_rotation(Vector2(-1, 0))
	var south: float = RoadKitLib.readable_label_rotation(Vector2(0, 1))
	var nw: float = RoadKitLib.readable_label_rotation(Vector2(-1, -1))
	_assert(_angle_near(east, 0.0, 0.05), "east road label rotation ≈ 0 (got %.3f)" % east)
	_assert(_angle_near(west, 0.0, 0.05), "west road label stays upright ≈ 0 (got %.3f)" % west)
	_assert(_angle_near(south, PI * 0.5, 0.05), "south road label ≈ +π/2 (got %.3f)" % south)
	_assert(absf(nw) <= PI * 0.5 + 0.05, "folded label |rotation| ≤ 90° (got %.3f)" % nw)
	_assert(_angle_near(nw, PI * 0.25, 0.08), "NW tangent folds to +π/4 (got %.3f)" % nw)


func _test_label_samples_follow_tangent() -> void:
	var horiz: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(400, 0)])
	var hs: Array = RoadKitLib.label_samples(horiz, 360.0)
	_assert(hs.size() == 1, "short east-west road gets one label (got %d)" % hs.size())
	if hs.size() >= 1:
		var t: Vector2 = hs[0]["tangent"]
		_assert(t.x > 0.9 and absf(t.y) < 0.1, "horizontal sample tangent points east (got %s)" % str(t))
		_assert(
			_angle_near(RoadKitLib.readable_label_rotation(t), 0.0, 0.05),
			"horizontal label rotation ≈ 0"
		)
		_assert(
			(hs[0]["pos"] as Vector2).distance_to(Vector2(200, 0)) < 8.0,
			"horizontal label sits on the ribbon midpoint"
		)
	var vert: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0, 400)])
	var vs: Array = RoadKitLib.label_samples(vert, 360.0)
	_assert(vs.size() == 1, "short north-south road gets one label (got %d)" % vs.size())
	if vs.size() >= 1:
		var t2: Vector2 = vs[0]["tangent"]
		_assert(t2.y > 0.9 and absf(t2.x) < 0.1, "vertical sample tangent points south (got %s)" % str(t2))
		_assert(
			_angle_near(RoadKitLib.readable_label_rotation(t2), PI * 0.5, 0.05),
			"vertical label rotation ≈ +π/2"
		)


func _angle_near(a: float, b: float, tol: float) -> bool:
	return absf(wrapf(a - b, -PI, PI)) <= tol


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
