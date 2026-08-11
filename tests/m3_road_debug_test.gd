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
	_assert_winterthurer_world_spawn(spawn, spawn_feld, world)
	if player:
		var feld: Vector2i = DebugGridLib.world_to_cell(player.global_position, 100.0)
		_assert(
			player.global_position.distance_to(spawn) <= 2.0,
			"Player at world start is at default_world_spawn (got %s want %s)"
			% [str(player.global_position), str(spawn)]
		)
		_assert(
			feld == spawn_feld,
			"spawn %s is Feld %s (got %s)" % [str(spawn), str(spawn_feld), str(feld)]
		)
		_assert_spawn_viewport_shows_streets(player, world)
	var status: Label = world.get_node_or_null("%StatusLabel") as Label
	if status:
		var feld_txt := "Feld %d,%d" % [spawn_feld.x, spawn_feld.y]
		_assert(
			status.text.contains(feld_txt) and status.text.contains("Raster 100"),
			"status shows %s and Raster 100 (got %s)" % [feld_txt, status.text]
		)
		_assert(
			status.text.contains("Feld 38,-2"),
			"status shows Feld 38,-2 for WINT-KERN spawn (got %s)" % status.text
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


func _assert_winterthurer_world_spawn(spawn: Vector2, spawn_feld: Vector2i, world: Node) -> void:
	var winter_vertex := Vector2(3861.9, -101.0)
	var old_forrenberg := SeuzachGeo.forrenberg_world() + Vector2(0.0, 200.0)
	_assert(
		spawn.distance_to(winter_vertex) < 0.05,
		"default_world_spawn is Winterthurer vertex (got %s)" % str(spawn)
	)
	_assert(
		spawn.is_equal_approx(SeuzachGeo.winterthurer_spawn()),
		"default_world_spawn matches winterthurer_spawn()"
	)
	_assert(
		spawn_feld == Vector2i(38, -2),
		"default spawn is Feld 38,-2 (got %s)" % str(spawn_feld)
	)
	_assert(
		spawn_feld.x >= 30 and spawn_feld.x <= 45 and spawn_feld.y >= -15 and spawn_feld.y <= 10,
		"default spawn Feld %s is in WINT-KERN 30..45, −15..10" % str(spawn_feld)
	)
	_assert(
		SeuzachGeo.WORLD_BOUNDS.has_point(spawn),
		"default spawn is inside WORLD_BOUNDS"
	)
	_assert(
		spawn.distance_to(old_forrenberg) > 40.0,
		"default spawn is not forrenberg_world()+(0,200) (got %s old %s)"
		% [str(spawn), str(old_forrenberg)]
	)
	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground exists for Winterthurerstrasse distance")
	if ground == null:
		return
	var best_d := 1.0e9
	var saw_winter := false
	for node in ground.get_children():
		if not node.has_meta("road_name") or str(node.get_meta("road_name")) != "Winterthurerstrasse":
			continue
		if not node.has_meta("road_points"):
			continue
		saw_winter = true
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		var pair: Dictionary = _nearest_segment_tangent_dist(pts, spawn)
		best_d = minf(best_d, float(pair["d"]))
	_assert(saw_winter, "Winterthurerstrasse road_points exist on Ground")
	_assert(
		best_d <= 40.0,
		"spawn distance to Winterthurerstrasse polyline ≤ 40 wu (got %.1f)" % best_d
	)


func _assert_spawn_viewport_shows_streets(player: Node2D, world: Node) -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	_assert(cam != null, "Player Camera2D exists")
	if cam == null:
		return
	_assert(is_equal_approx(cam.zoom.x, 0.9) and is_equal_approx(cam.zoom.y, 0.9), "spawn camera zoom == (0.9, 0.9)")
	_assert(not cam.position_smoothing_enabled, "spawn camera does not lag behind the player")
	var view := _spawn_viewport_rect(player.global_position, cam.zoom)
	var names: Dictionary = {}
	var ground: Node = world.get_node_or_null("%Ground")
	if ground:
		for node in ground.get_children():
			if not node.has_meta("road_name") or not node.has_meta("road_points"):
				continue
			var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
			if _polyline_hits_rect(pts, view):
				names[str(node.get_meta("road_name"))] = true
	_assert(names.has("Winterthurerstrasse"), "start viewport includes Winterthurerstrasse")


func _spawn_viewport_rect(center: Vector2, zoom: Vector2) -> Rect2:
	var screen := Vector2(1280.0, 720.0)
	var world_size := Vector2(screen.x / maxf(zoom.x, 0.01), screen.y / maxf(zoom.y, 0.01))
	return Rect2(center - world_size * 0.5, world_size)


func _polyline_hits_rect(pts: PackedVector2Array, rect: Rect2) -> bool:
	for p in pts:
		if rect.has_point(p):
			return true
	for i in range(pts.size() - 1):
		if Geometry2D.segment_intersects_segment(pts[i], pts[i + 1], rect.position, rect.position + Vector2(rect.size.x, 0.0)) != null:
			return true
		if Geometry2D.segment_intersects_segment(pts[i], pts[i + 1], rect.position, rect.position + Vector2(0.0, rect.size.y)) != null:
			return true
		if Geometry2D.segment_intersects_segment(pts[i], pts[i + 1], rect.end, rect.end - Vector2(rect.size.x, 0.0)) != null:
			return true
		if Geometry2D.segment_intersects_segment(pts[i], pts[i + 1], rect.end, rect.end - Vector2(0.0, rect.size.y)) != null:
			return true
	return false


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
