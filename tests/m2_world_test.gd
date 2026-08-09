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
				elif child is Line2D:
					ground_lines += 1
		_assert(ground_sprites == 0, "ground has no Sprite2D tiles (got %d)" % ground_sprites)
		_assert(ground_polys >= 1, "ground has flat polygons")
		_assert(ground_lines == 0, "ground has no per-tile Line2D outlines (got %d)" % ground_lines)
		# Organic ground: few polys (base + patches + road ribbons), not a diamond flood.
		_assert(ground_polys <= 20, "ground poly count organic (got %d, want <=20)" % ground_polys)
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
		_assert(prop_sprites >= 1, "landmark props present")
		world.queue_free()

	if _failed == 0:
		print("=== m2_world_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_world_test FAIL (%d) ===" % _failed)
		quit(1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
