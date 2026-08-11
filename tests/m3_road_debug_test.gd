extends SceneTree
## F1 road-debug overlay: street names on ribbons, aligned to road tangent.

const WORLD_SCENE := "res://scenes/world_sandbox.tscn"
const RoadKitLib := preload("res://scripts/road_kit.gd")

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

	world.call("set_road_debug", false)
	_assert(not bool(world.call("is_road_debug_enabled")), "debug overlay toggles off")
	_assert(_count_debug_labels(world) == 0, "turning debug off removes labels")

	_send_f1(world)
	_assert(bool(world.call("is_road_debug_enabled")), "F1 enables road debug")
	_assert(_count_debug_labels(world) >= 10, "F1 spawn street-name labels")
	_send_f1(world)
	_assert(not bool(world.call("is_road_debug_enabled")), "F1 toggles road debug off")
	_assert(_count_debug_labels(world) == 0, "second F1 clears labels")

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
	for node in ground.get_children():
		if not node.has_meta("road_name") or str(node.get_meta("road_name")) != road_name:
			continue
		if not node.has_meta("road_points"):
			continue
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		return _nearest_segment_tangent(pts, pos)
	return Vector2.RIGHT


func _nearest_segment_tangent(pts: PackedVector2Array, pos: Vector2) -> Vector2:
	if pts.size() < 2:
		return Vector2.RIGHT
	var best_d := 1.0e9
	var best_t := Vector2.RIGHT
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
	return best_t


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
