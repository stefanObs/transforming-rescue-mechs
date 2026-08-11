extends SceneTree
## F1 road-debug overlay: street names on ribbons, aligned to road tangent.

const WORLD_SCENE := "res://scenes/world_sandbox.tscn"
const RoadKitLib := preload("res://scripts/road_kit.gd")
const DebugGridLib := preload("res://scripts/debug_grid.gd")

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m3_road_debug_test start ===")
	var packed: Variant = load(WORLD_SCENE)
	_assert(packed is PackedScene, "world_sandbox.tscn loads")
	if not (packed is PackedScene):
		_finish()
		return

	var world: Node = (packed as PackedScene).instantiate()
	root.add_child(world)
	await process_frame

	_assert(not bool(world.call("is_road_debug_enabled")), "debug overlay off by default")
	_assert(_count_debug_labels(world) == 0, "no street-name labels before F1")
	_assert(_find_debug_grid(world) == null, "no debug grid before F1")
	_assert_cell_mapping()

	world.call("set_road_debug", true)
	_assert(bool(world.call("is_road_debug_enabled")), "set_road_debug(true) enables overlay")
	var labels := _collect_debug_labels(world)
	_assert(labels.size() >= 10, "debug shows names on named roads (got %d)" % labels.size())

	var named_roads := _named_road_set(world)
	_assert(named_roads.has("A1"), "A1 is a named road")
	_assert(named_roads.has("Winterthurerstrasse"), "Winterthurerstrasse is a named road")
	var labeled := {}
	for holder in labels:
		var n := str(holder.get_meta("road_name"))
		labeled[n] = true
		var text := _label_text(holder)
		_assert(text == n, "label text matches road_name (%s)" % n)
		var tangent := _tangent_at(world, n, holder.position)
		var want: float = RoadKitLib.readable_label_rotation(tangent)
		_assert(
			_angle_near(holder.rotation, want, 0.12),
			"%s label follows road direction (rot=%.3f want=%.3f)"
			% [n, holder.rotation, want]
		)
	for road_name in named_roads.keys():
		_assert(bool(labeled.get(road_name, false)), "debug labels include %s" % str(road_name))

	var a1 := _first_label(labels, "A1")
	if a1:
		_assert(
			absf(a1.rotation) < 0.45,
			"A1 (east-west) label stays nearly horizontal (got %.3f)" % a1.rotation
		)
	var winter := _first_label(labels, "Winterthurerstrasse")
	if winter:
		_assert(
			absf(absf(winter.rotation) - PI * 0.5) < 0.45,
			"Winterthurerstrasse (north-south) label is nearly vertical (got %.3f)" % winter.rotation
		)

	var grid := _find_debug_grid(world)
	_assert(grid != null, "F1 shows coordinate grid")
	if grid:
		_assert(
			is_equal_approx(float(grid.get_meta("cell_size")), 100.0),
			"grid cell size is 100 (got %s)" % str(grid.get_meta("cell_size"))
		)
		_assert(grid.get_script() == DebugGridLib, "grid node uses DebugGrid")
		if grid.get_script() == DebugGridLib:
			var grid_bounds: Rect2 = grid.get("bounds")
			_assert(grid_bounds.has_point(Vector2.ZERO), "grid covers Kirche origin (0,0)")
			_assert(is_equal_approx(float(grid.get("cell_size")), 100.0), "DebugGrid.cell_size is 100")
	var player: Node2D = world.get_node_or_null("%Player") as Node2D
	var spawn := SeuzachGeo.default_world_spawn()
	var spawn_feld: Vector2i = DebugGridLib.world_to_cell(spawn, 100.0)
	if player:
		var feld: Vector2i = DebugGridLib.world_to_cell(player.global_position, 100.0)
		_assert(
			feld == spawn_feld,
			"spawn %s is Feld %s (got %s)" % [str(spawn), str(spawn_feld), str(feld)]
		)
	var status: Label = world.get_node_or_null("%StatusLabel") as Label
	if status:
		var feld_txt := "Feld %d,%d" % [spawn_feld.x, spawn_feld.y]
		_assert(
			status.text.contains(feld_txt) and status.text.contains("Raster 100"),
			"status shows %s and Raster 100 (got %s)" % [feld_txt, status.text]
		)
	var ground: Node = world.get_node_or_null("%Ground")
	if ground:
		var ground_lines := 0
		for child in ground.get_children():
			if child is Line2D:
				ground_lines += 1
		_assert(ground_lines == 0, "debug grid does not put Line2D on Ground")
	if grid:
		var grid_lines := 0
		for child in grid.get_children():
			if child is Line2D:
				grid_lines += 1
		_assert(grid_lines == 0, "grid uses _draw, not Line2D children")

	world.call("set_road_debug", false)
	_assert(not bool(world.call("is_road_debug_enabled")), "debug overlay toggles off")
	_assert(_count_debug_labels(world) == 0, "turning debug off removes labels")
	_assert(_find_debug_grid(world) == null, "turning debug off removes grid")

	_send_f1(world)
	_assert(bool(world.call("is_road_debug_enabled")), "F1 enables road debug")
	_assert(_count_debug_labels(world) >= 10, "F1 spawn street-name labels")
	_assert(_find_debug_grid(world) != null, "F1 spawn coordinate grid")
	_send_f1(world)
	_assert(not bool(world.call("is_road_debug_enabled")), "F1 toggles road debug off")
	_assert(_count_debug_labels(world) == 0, "second F1 clears labels")
	_assert(_find_debug_grid(world) == null, "second F1 clears grid")

	world.get_tree().paused = true
	_send_f1(world)
	_assert(bool(world.call("is_road_debug_enabled")), "F1 enables road debug while paused")
	_send_f1(world)
	_assert(not bool(world.call("is_road_debug_enabled")), "F1 toggles off while paused")
	world.get_tree().paused = false

	var hint: Label = world.get_node_or_null("%HintLabel") as Label
	if hint:
		_assert(
			hint.text.contains("F1") or hint.text.contains("Debug"),
			"hint mentions F1 debug"
		)

	world.queue_free()
	_finish()


func _assert_cell_mapping() -> void:
	_assert(
		DebugGridLib.world_to_cell(Vector2(50, 50), 100.0) == Vector2i(0, 0),
		"(50,50) is Feld 0,0 (Kirche south-east cell)"
	)
	_assert(
		DebugGridLib.world_to_cell(Vector2(-1, -1), 100.0) == Vector2i(-1, -1),
		"(-1,-1) is Feld -1,-1"
	)
	_assert(
		DebugGridLib.world_to_cell(Vector2(100, 0), 100.0) == Vector2i(1, 0),
		"(100,0) is Feld 1,0"
	)
	_assert(
		DebugGridLib.world_to_cell(Vector2(0, 0), 100.0) == Vector2i(0, 0),
		"Kirche (0,0) sits on Feld 0,0 corner"
	)
	var center: Vector2 = DebugGridLib.cell_center(Vector2i(2, -3), 100.0)
	_assert(
		center.distance_to(Vector2(250, -250)) < 0.1,
		"Feld 2,-3 center is (250,-250)"
	)


func _find_debug_grid(world: Node) -> Node:
	return _find_grid_recursive(world)


func _find_grid_recursive(node: Node) -> Node:
	if node.has_meta("road_debug_grid"):
		return node
	for child in node.get_children():
		var found := _find_grid_recursive(child)
		if found:
			return found
	return null


func _send_f1(world: Node) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.echo = false
	ev.keycode = KEY_F1
	ev.physical_keycode = KEY_F1
	world._unhandled_input(ev)


func _named_road_set(world: Node) -> Dictionary:
	var out := {}
	var ground: Node = world.get_node_or_null("%Ground")
	if ground == null:
		return out
	for node in ground.get_children():
		if node.has_meta("road_name"):
			out[str(node.get_meta("road_name"))] = true
	return out


func _tangent_at(world: Node, road_name: String, pos: Vector2) -> Vector2:
	var ground: Node = world.get_node_or_null("%Ground")
	if ground == null:
		return Vector2.RIGHT
	var best_d := 1.0e9
	var best_t := Vector2.RIGHT
	for node in ground.get_children():
		if not node.has_meta("road_name") or str(node.get_meta("road_name")) != road_name:
			continue
		if not node.has_meta("road_points"):
			continue
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		var pair: Dictionary = _nearest_segment_tangent_dist(pts, pos)
		if float(pair["d"]) < best_d:
			best_d = float(pair["d"])
			best_t = pair["t"]
	return best_t


func _nearest_segment_tangent_dist(pts: PackedVector2Array, pos: Vector2) -> Dictionary:
	var best_d := 1.0e9
	var best_t := Vector2.RIGHT
	if pts.size() < 2:
		return {"d": best_d, "t": best_t}
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var len2 := ab.length_squared()
		if len2 < 0.001:
			continue
		var t := clampf((pos - a).dot(ab) / len2, 0.0, 1.0)
		var d := pos.distance_to(a + ab * t)
		if d < best_d:
			best_d = d
			best_t = ab / sqrt(len2)
	return {"d": best_d, "t": best_t}


func _collect_debug_labels(world: Node) -> Array[Node2D]:
	var out: Array[Node2D] = []
	_collect_debug_recursive(world, out)
	return out


func _collect_debug_recursive(node: Node, out: Array[Node2D]) -> void:
	if node is Node2D and node.has_meta("road_debug_label"):
		out.append(node as Node2D)
	for child in node.get_children():
		_collect_debug_recursive(child, out)


func _count_debug_labels(world: Node) -> int:
	return _collect_debug_labels(world).size()


func _first_label(labels: Array[Node2D], road_name: String) -> Node2D:
	for holder in labels:
		if str(holder.get_meta("road_name")) == road_name:
			return holder
	return null


func _label_text(holder: Node) -> String:
	for child in holder.get_children():
		if child is Label:
			return (child as Label).text
	return ""


func _angle_near(a: float, b: float, tol: float) -> bool:
	return absf(wrapf(a - b, -PI, PI)) <= tol


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _finish() -> void:
	if _failed == 0:
		print("=== m3_road_debug_test PASS ===")
		quit(0)
	else:
		printerr("=== m3_road_debug_test FAIL (%d) ===" % _failed)
		quit(1)
