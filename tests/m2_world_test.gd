extends SceneTree
## World ground must not tile 3D grass/road sprites.

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_world_test start ===")
	var packed: Variant = load("res://scenes/world_sandbox.tscn")
	_assert(packed is PackedScene, "world_sandbox.tscn loads")
	if packed is PackedScene:
		var world: Node = (packed as PackedScene).instantiate()
		root.add_child(world)
		# _ready builds ground/props synchronously on add_child.
		var ground: Node2D = world.get_node_or_null("%Ground")
		_assert(ground != null, "Ground node exists")
		var props: Node2D = world.get_node_or_null("%Props")
		_assert(props != null, "Props node exists")
		var ground_sprites := 0
		var ground_polys := 0
		var ground_lines := 0
		if ground:
			for child in ground.get_children():
				if child is Sprite2D:
					ground_sprites += 1
				elif child is Polygon2D:
					ground_polys += 1
			ground_lines = _count_line2d_nested(ground)
		_assert(ground_sprites == 0, "ground has no Sprite2D tiles (got %d)" % ground_sprites)
		_assert(ground_polys >= 1, "ground has flat polygons")
		_assert(ground_lines == 0, "ground has no Line2D (got %d)" % ground_lines)
		# Organic ground + RoadKit dashes/ring — not a diamond flood.
		# RailwayKit / WaterKit / forest floors live under Rails / Streams / Forests holders.
		_assert(ground_polys <= 4000, "ground poly count organic (got %d, want <=4000)" % ground_polys)
		var kit_roads := 0
		var kit_stripes := 0
		if ground:
			for child in ground.get_children():
				if child.has_meta("road_kit"):
					var meta := str(child.get_meta("road_kit"))
					if meta == "road":
						kit_roads += 1
					elif meta == "stripe":
						kit_stripes += 1
		_assert(kit_roads >= 2, "RoadKit road pieces present (got %d)" % kit_roads)
		_assert(kit_stripes >= 2, "RoadKit stripe dashes present (got %d)" % kit_stripes)
		var kit_junctions := 0
		if ground:
			for child in ground.get_children():
				if child.has_meta("road_kit") and str(child.get_meta("road_kit")) == "junction":
					kit_junctions += 1
		_assert(kit_junctions >= 4, "junction pads cover crossings (got %d)" % kit_junctions)
		var road_polys := 0
		if ground:
			for child in ground.get_children():
				if child is Polygon2D:
					var c: Color = (child as Polygon2D).color
					# Road gray band (lighter than grass greens).
					if c.r > 0.45 and c.g > 0.45 and c.b > 0.45 and absf(c.r - c.g) < 0.08:
						road_polys += 1
		_assert(road_polys >= 2, "continuous road ribbons present (got %d)" % road_polys)
		var prop_sprites := 0
		if props:
			for child in props.get_children():
				if child is Sprite2D:
					prop_sprites += 1
					var tex: Texture2D = (child as Sprite2D).texture
					if tex:
						var path := str(tex.resource_path)
						_assert(not path.ends_with("tile_grass.png"), "props must not use tile_grass")
						_assert(not path.ends_with("tile_road.png"), "props must not use tile_road")
		_assert(prop_sprites >= 1, "school orientation props present (got %d)" % prop_sprites)
		var player: Node = world.get_node_or_null("%Player")
		_assert(player != null, "Player exists")
		if player:
			var robot: Sprite2D = player.get_node_or_null("RobotSprite") as Sprite2D
			_assert(robot != null, "RobotSprite exists")
			if robot:
				_assert(robot.visible, "RobotSprite visible at spawn")
				_assert(robot.texture != null, "RobotSprite has texture at spawn")
				_assert(robot.modulate.a > 0.99, "RobotSprite opaque modulate")
			var world_script: GDScript = load("res://scripts/world_sandbox.gd")
			var expected_z: int = int(world_script.compute_actor_z(player.global_position.y))
			_assert(
				player.z_index == expected_z,
				"Player z_index set in _ready (got %d want %d)" % [player.z_index, expected_z]
			)
			_assert(not player.z_as_relative, "Player z_as_relative=false so the figure is not buried")
		world.queue_free()

	if _failed == 0:
		print("=== m2_world_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_world_test FAIL (%d) ===" % _failed)
		quit(1)


func _count_line2d_nested(node: Node) -> int:
	var n := 0
	if node is Line2D:
		n += 1
	for child in node.get_children():
		n += _count_line2d_nested(child)
	return n


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
