extends SceneTree
## M3 hub ↔ world transition, spawn handoff, building collision.
## Note: Autoload globals are not injected into -s scripts; use /root nodes.

const WORLD_SCENE := "res://scenes/world_sandbox.tscn"
const HUB_SCENE := "res://scenes/hub_station.tscn"
const SPAWN_TOL := 2.0
## Default world spawn is Winterthurerstrasse (WINT-KERN), not HubEnter at Forrenberg.
var DEFAULT_WORLD_SPAWN: Vector2 = SeuzachGeo.default_world_spawn()
var HUB_ENTER_POS: Vector2 = SeuzachGeo.hub_enter_pos()
## player.tscn CapsuleShape2D: radius 14, height 40, offset (0, -12)
## Godot capsule half-height along Y is height/2 (=20) + ends; use half extents matching shape.
const PLAYER_CAPSULE_OFFSET := Vector2(0, -12)
const PLAYER_CAPSULE_HALF := Vector2(14, 20)

var _failed: int = 0
var _gs: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m3_hub_transition_test start ===")
	_gs = root.get_node_or_null("GameState")
	_assert(_gs != null, "GameState autoload exists")
	if _gs == null:
		_finish()
		return
	await _run_async()


func _run_async() -> void:
	_test_game_state_spawn_api()
	await _test_world_hub_enter_and_collision()
	await _test_hub_scene_and_exit_api()
	await _test_spawn_restore_on_world_ready()
	await _test_scene_transition_roundtrip()
	_finish()


func _test_game_state_spawn_api() -> void:
	_gs.call("reset_for_new_game")
	_assert(not bool(_gs.get("has_world_spawn")), "reset clears has_world_spawn")
	_assert(
		_gs.get("world_spawn_position") == DEFAULT_WORLD_SPAWN,
		"reset restores default world_spawn_position"
	)

	var marker := Vector2(510, 770)
	_gs.call("set_world_spawn", marker)
	_assert(bool(_gs.get("has_world_spawn")), "set_world_spawn sets flag")
	_assert(_gs.get("world_spawn_position") == marker, "set_world_spawn stores position")

	var consumed: Vector2 = _gs.call("consume_world_spawn")
	_assert(consumed == marker, "consume_world_spawn returns stored position")
	_assert(not bool(_gs.get("has_world_spawn")), "consume_world_spawn clears flag")
	_assert(
		_gs.get("world_spawn_position") == marker,
		"consume keeps last position for reference"
	)


func _test_world_hub_enter_and_collision() -> void:
	_gs.call("reset_for_new_game")
	var packed: Variant = load(WORLD_SCENE)
	_assert(packed is PackedScene, "world_sandbox.tscn loads")
	if not (packed is PackedScene):
		return

	var world: Node = (packed as PackedScene).instantiate()
	root.add_child(world)
	await process_frame

	_assert(world.has_method("enter_hub_for_test"), "world has enter_hub_for_test")
	_assert(world.has_method("get_hub_enter_for_test"), "world has get_hub_enter_for_test")

	var hub_enter: Area2D = null
	if world.has_method("get_hub_enter_for_test"):
		hub_enter = world.call("get_hub_enter_for_test") as Area2D
	if hub_enter == null:
		hub_enter = world.find_child("HubEnter", true, false) as Area2D
	_assert(hub_enter != null, "HubEnter area exists")
	if hub_enter:
		_assert(hub_enter.monitoring, "HubEnter monitoring enabled")
		_assert(
			hub_enter.has_meta("hub_enter") and bool(hub_enter.get_meta("hub_enter")),
			"HubEnter meta hub_enter=true"
		)
		_assert(
			hub_enter.global_position.distance_to(HUB_ENTER_POS) <= SPAWN_TOL,
			"HubEnter centered at HUB_ENTER_POS"
		)
		_assert(
			HUB_ENTER_POS.distance_to(SeuzachGeo.hub_enter_pos()) <= SPAWN_TOL,
			"HubEnter stays at SeuzachGeo.hub_enter_pos()"
		)
		_assert(
			DEFAULT_WORLD_SPAWN.distance_to(HUB_ENTER_POS) > 40.0,
			"default world spawn is not HubEnter (Forrenberg)"
		)

	var props: Node = world.get_node_or_null("%Props")
	_assert(props != null, "Props node exists")
	var collision_count := _count_building_collisions(props)
	_assert(
		collision_count >= 1,
		"school props have building collision (got %d)" % collision_count
	)

	var player: CharacterBody2D = world.get_node_or_null("%Player") as CharacterBody2D
	_assert(player != null, "world Player exists")
	if player:
		_assert(player.collision_layer == 1, "player collision_layer=1")
		_assert(player.collision_mask == 1, "player collision_mask=1")

	var sample_body := _find_building_static_body(props)
	if sample_body:
		_assert(sample_body.collision_layer == 1, "building StaticBody collision_layer=1")
		_assert(sample_body.collision_mask == 1, "building StaticBody collision_mask=1")

	_assert_hub_enter_clear_of_collision(world, hub_enter)

	world.queue_free()
	await process_frame


func _assert_hub_enter_clear_of_collision(world: Node, hub_enter: Area2D) -> void:
	var hub_spr: Sprite2D = world.find_child("hub_station", true, false) as Sprite2D
	_assert(hub_spr == null, "street map has no hub_station sprite")

	var spawn_cap := _player_capsule_aabb(DEFAULT_WORLD_SPAWN)
	var enter_cap := _player_capsule_aabb(HUB_ENTER_POS)
	var props: Node = world.get_node_or_null("%Props")
	for body in _forrenberg_building_bodies(props):
		var aabb := _static_body_aabb(body)
		if not aabb.has_area():
			continue
		_assert(
			not spawn_cap.intersects(aabb),
			"default spawn clear of %s BuildingCollision" % body.get_parent().name
		)
		_assert(
			not enter_cap.intersects(aabb),
			"HubEnter clear of %s BuildingCollision" % body.get_parent().name
		)

	if hub_enter == null:
		return
	var enter_aabb := _area_aabb(hub_enter)
	_assert(enter_aabb.has_area(), "HubEnter AABB has area")
	_assert(
		enter_cap.intersects(enter_aabb),
		"player capsule at HubEnter center overlaps HubEnter area"
	)


func _forrenberg_building_bodies(props: Node) -> Array[StaticBody2D]:
	var out: Array[StaticBody2D] = []
	if props == null:
		return out
	for node in _collect_nodes(props):
		if not (node is Sprite2D):
			continue
		var spr := node as Sprite2D
		if not spr.has_meta("district") or str(spr.get_meta("district")) != "forrenberg":
			continue
		var body := spr.get_node_or_null("BuildingCollision") as StaticBody2D
		if body:
			out.append(body)
	return out


func _usable_enter_strip_ok(enter_aabb: Rect2, hub_aabb: Rect2) -> bool:
	## Require ≥40px of enter height south of hub collision (capsule diameter).
	var clear_top := maxf(enter_aabb.position.y, hub_aabb.end.y)
	var clear_h := enter_aabb.end.y - clear_top
	return clear_h >= 40.0


func _player_capsule_aabb(at: Vector2) -> Rect2:
	var center := at + PLAYER_CAPSULE_OFFSET
	return Rect2(center - PLAYER_CAPSULE_HALF, PLAYER_CAPSULE_HALF * 2.0)


func _static_body_aabb(body: StaticBody2D) -> Rect2:
	for child in body.get_children():
		if child is CollisionShape2D:
			var col := child as CollisionShape2D
			if col.shape is RectangleShape2D:
				var rect := col.shape as RectangleShape2D
				var half := rect.size * 0.5
				var center: Vector2 = body.global_position + col.position
				return Rect2(center - half, rect.size)
	return Rect2()


func _area_aabb(area: Area2D) -> Rect2:
	for child in area.get_children():
		if child is CollisionShape2D:
			var col := child as CollisionShape2D
			if col.shape is RectangleShape2D:
				var rect := col.shape as RectangleShape2D
				var half := rect.size * 0.5
				var center: Vector2 = area.global_position + col.position
				return Rect2(center - half, rect.size)
	return Rect2()


func _test_hub_scene_and_exit_api() -> void:
	_gs.call("reset_for_new_game")
	var packed: Variant = load(HUB_SCENE)
	_assert(packed is PackedScene, "hub_station.tscn loads")
	if not (packed is PackedScene):
		return

	var hub: Node = (packed as PackedScene).instantiate()
	root.add_child(hub)
	await process_frame

	var player: Node = hub.get_node_or_null("%Player")
	_assert(player != null and player is CharacterBody2D, "hub instantiates with Player")
	_assert(hub.has_method("exit_to_world_for_test"), "hub has exit_to_world_for_test")

	var exit_area: Area2D = hub.get_node_or_null("%HubExit") as Area2D
	if exit_area == null:
		exit_area = hub.find_child("HubExit", true, false) as Area2D
	_assert(exit_area != null, "HubExit area exists")
	if exit_area:
		_assert(
			exit_area.has_meta("hub_exit") and bool(exit_area.get_meta("hub_exit")),
			"HubExit meta hub_exit=true"
		)

	hub.queue_free()
	await process_frame


func _test_spawn_restore_on_world_ready() -> void:
	_gs.call("reset_for_new_game")
	var marker := Vector2(500, 765)
	_gs.call("set_world_spawn", marker)

	var packed: Variant = load(WORLD_SCENE)
	_assert(packed is PackedScene, "world loads for spawn restore")
	if not (packed is PackedScene):
		return

	var world: Node = (packed as PackedScene).instantiate()
	root.add_child(world)
	await process_frame

	var player: CharacterBody2D = world.get_node_or_null("%Player") as CharacterBody2D
	_assert(player != null, "player present for spawn restore")
	if player:
		var delta: float = player.global_position.distance_to(marker)
		_assert(delta <= SPAWN_TOL, "player spawned at stored position (delta=%.2f)" % delta)
	_assert(not bool(_gs.get("has_world_spawn")), "world _ready consumed spawn flag")

	world.queue_free()
	await process_frame


func _test_scene_transition_roundtrip() -> void:
	_gs.call("reset_for_new_game")
	change_scene_to_file(WORLD_SCENE)
	await process_frame
	await process_frame

	var world: Node = current_scene
	_assert(world != null, "current_scene is world after change_scene")
	if world == null or not world.has_method("enter_hub_for_test"):
		return

	var player: CharacterBody2D = world.get_node_or_null("%Player") as CharacterBody2D
	var expected := HUB_ENTER_POS
	if player:
		player.global_position = expected
		expected = player.global_position

	world.call("enter_hub_for_test")
	await process_frame
	await process_frame

	# enter_hub sets spawn; flag remains until world consumes it
	_assert(bool(_gs.get("has_world_spawn")), "has_world_spawn after enter_hub")
	_assert(
		(_gs.get("world_spawn_position") as Vector2).distance_to(expected) <= SPAWN_TOL,
		"spawn near player position after enter_hub"
	)

	var hub: Node = current_scene
	_assert(hub != null, "current_scene is hub after enter")
	_assert(
		hub != null and hub.has_method("exit_to_world_for_test"),
		"hub scene active with exit API"
	)
	if hub == null or not hub.has_method("exit_to_world_for_test"):
		return

	hub.call("exit_to_world_for_test")
	await process_frame
	await process_frame

	var world_back: Node = current_scene
	_assert(world_back != null, "returned to a scene after exit")
	_assert(
		world_back != null and world_back.has_method("enter_hub_for_test"),
		"returned to world_sandbox"
	)
	if world_back == null:
		return

	var player_back: CharacterBody2D = world_back.get_node_or_null("%Player") as CharacterBody2D
	_assert(player_back != null, "player present after return")
	if player_back:
		var delta: float = player_back.global_position.distance_to(expected)
		_assert(
			delta <= SPAWN_TOL,
			"player near saved spawn after hub exit (delta=%.2f)" % delta
		)
	_assert(not bool(_gs.get("has_world_spawn")), "spawn consumed after return to world")


func _count_building_collisions(root_node: Node) -> int:
	if root_node == null:
		return 0
	var n := 0
	for node in _collect_nodes(root_node):
		if node is Sprite2D and node.has_meta("has_building_collision"):
			n += 1
			continue
		if node is StaticBody2D and (
			node.has_meta("has_building_collision") or node.name == "BuildingCollision"
		):
			n += 1
	return n


func _find_building_static_body(root_node: Node) -> StaticBody2D:
	if root_node == null:
		return null
	for node in _collect_nodes(root_node):
		if node is StaticBody2D and (
			node.has_meta("has_building_collision") or node.name == "BuildingCollision"
		):
			return node as StaticBody2D
	return null


func _collect_nodes(root_node: Node) -> Array[Node]:
	var out: Array[Node] = []
	_collect_nodes_recursive(root_node, out)
	return out


func _collect_nodes_recursive(node: Node, out: Array[Node]) -> void:
	out.append(node)
	for child in node.get_children():
		_collect_nodes_recursive(child, out)


func _finish() -> void:
	if _failed == 0:
		print("=== m3_hub_transition_test PASS ===")
		quit(0)
	else:
		printerr("=== m3_hub_transition_test FAIL (%d) ===" % _failed)
		quit(1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
