extends SceneTree
## Building occlusion: feet pivot + Y-sort so the player stays visible in front of props.

const WORLD_SCENE := "res://scenes/world_sandbox.tscn"
const FEET_TOL := 2.0
const VISUAL_BOTTOM_TOL := 8.0
## Cluster members should not sit almost on top of each other (screen-space).
## School sprites ~200px tall at current scale — require clear gaps.
const MIN_CLUSTER_SEP := 160.0
const MIN_FORRENBERG_SEP := 220.0

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m3_building_occlusion_test start ===")
	var world_script: GDScript = load("res://scripts/world_sandbox.gd")
	_assert(world_script != null, "world_sandbox.gd loads")
	if world_script == null:
		_finish()
		return

	_assert(
		world_script.compute_actor_z(100.0) > world_script.compute_prop_z(100.0),
		"same-Y actor draws above prop"
	)

	var packed: Variant = load(WORLD_SCENE)
	_assert(packed is PackedScene, "world loads")
	if not (packed is PackedScene):
		_finish()
		return

	var world: Node = (packed as PackedScene).instantiate()
	root.add_child(world)
	await process_frame

	var props: Node = world.get_node_or_null("%Props")
	_assert(props != null, "Props exists")
	var player: CharacterBody2D = world.get_node_or_null("%Player") as CharacterBody2D
	_assert(player != null, "Player exists")

	var landmark_count := 0
	for spr in _collect_sprites(props):
		if spr.texture == null:
			continue
		if not spr.has_meta("landmark_id") and not spr.has_meta("house_variant"):
			continue
		landmark_count += 1
		var expected_oy: float = float(world_script.feet_offset_y(spr.texture))
		_assert(
			absf(spr.offset.y - expected_oy) <= FEET_TOL,
			"%s feet offset ≈ -tex_h/2 (got %.1f want %.1f)" % [spr.name, spr.offset.y, expected_oy]
		)
		var visual_bottom := _sprite_visual_bottom_y(spr)
		_assert(
			absf(visual_bottom - spr.global_position.y) <= VISUAL_BOTTOM_TOL,
			"%s visual bottom near feet Y (bottom=%.1f feet=%.1f)"
			% [spr.name, visual_bottom, spr.global_position.y]
		)
		_assert(not spr.z_as_relative, "%s z_as_relative=false" % spr.name)

	_assert(landmark_count >= 8, "checked ≥8 school sprites (got %d)" % landmark_count)

	if player:
		var sample := _find_landmark(props, "schulhaus_birch")
		if sample:
			var south := sample.global_position + Vector2(0, 40)
			player.global_position = south
			if world.has_method("_sync_actor_z"):
				world.call("_sync_actor_z")
			else:
				player.z_index = int(world_script.compute_actor_z(south.y))
			_assert(
				player.z_index > sample.z_index,
				"player south of school draws in front (player z=%d prop z=%d)"
				% [player.z_index, sample.z_index]
			)

	_assert_cluster_spacing(props, "birch")
	_assert_cluster_spacing(props, "rietacker")
	_assert_cluster_spacing(props, "ohringen")

	world.queue_free()
	_finish()


func _assert_forrenberg_hub_tank_spacing(props: Node) -> void:
	var hub := _find_landmark(props, "hub_station")
	var tank := _find_landmark(props, "tankstelle")
	_assert(hub != null and tank != null, "hub and tankstelle present for spacing")
	if hub == null or tank == null:
		return
	var d := hub.global_position.distance_to(tank.global_position)
	_assert(
		d >= MIN_FORRENBERG_SEP,
		"hub↔tankstelle separation ≥%.0f (got %.1f)" % [MIN_FORRENBERG_SEP, d]
	)
	# Prefer different sort rows so facades do not fully stack.
	_assert(
		absf(hub.global_position.y - tank.global_position.y) >= 40.0
		or absf(hub.global_position.x - tank.global_position.x) >= MIN_FORRENBERG_SEP,
		"hub/tank staggered in X or Y"
	)


func _sprite_visual_bottom_y(spr: Sprite2D) -> float:
	## Centered sprite: bottom = position.y + (offset.y + tex_h/2) * scale.y
	var h := float(spr.texture.get_height())
	return spr.global_position.y + (spr.offset.y + h * 0.5) * absf(spr.scale.y)


func _assert_cluster_spacing(props: Node, cluster: String) -> void:
	var pts: Array[Vector2] = []
	for spr in _collect_sprites(props):
		if spr.has_meta("school_cluster") and str(spr.get_meta("school_cluster")) == cluster:
			pts.append(spr.global_position)
	_assert(pts.size() >= 2, "cluster %s has ≥2 props" % cluster)
	var min_d := 1.0e9
	for i in range(pts.size()):
		for j in range(i + 1, pts.size()):
			min_d = minf(min_d, pts[i].distance_to(pts[j]))
	_assert(
		min_d >= MIN_CLUSTER_SEP,
		"cluster %s min separation ≥%.0f (got %.1f)" % [cluster, MIN_CLUSTER_SEP, min_d]
	)


func _find_landmark(props: Node, landmark_id: String) -> Sprite2D:
	for spr in _collect_sprites(props):
		if spr.has_meta("landmark_id") and str(spr.get_meta("landmark_id")) == landmark_id:
			return spr
	return null


func _collect_sprites(root_node: Node) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	_collect_sprites_recursive(root_node, out)
	return out


func _collect_sprites_recursive(node: Node, out: Array[Sprite2D]) -> void:
	if node is Sprite2D:
		out.append(node as Sprite2D)
	for child in node.get_children():
		_collect_sprites_recursive(child, out)


func _finish() -> void:
	if _failed == 0:
		print("=== m3_building_occlusion_test PASS ===")
		quit(0)
	else:
		printerr("=== m3_building_occlusion_test FAIL (%d) ===" % _failed)
		quit(1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
