extends SceneTree
## S01 world-perf: spatial road index clearance ≡ full-road scan (algorithmic, no wall-clock).

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m3_road_spatial_index_test start ===")
	var world_script: GDScript = load("res://scripts/world_sandbox.gd")
	_assert(world_script != null, "world_sandbox.gd loads")
	if world_script == null:
		_finish()
		return

	var world: Node2D = world_script.new() as Node2D
	_assert(world != null, "world_sandbox instance")
	if world == null:
		_finish()
		return

	var roads := _fixture_roads()
	_assert(roads.size() > 8, "fixture has >8 roads so index path is used (got %d)" % roads.size())
	world.call("_build_road_spatial_index", roads)

	var tex: Texture2D = load("res://assets/art/house_street_a_ew.png")
	_assert(tex != null, "house texture for clearance fixture")
	if tex == null:
		world.free()
		_finish()
		return

	var scale := Vector2(0.38, 0.38) ## matches HOUSE_SCALE
	var samples: Array[Vector2] = [
		Vector2(0.0, -200.0), ## clear of center road
		Vector2(0.0, 0.0), ## on asphalt
		Vector2(0.0, 90.0), ## near curb
		Vector2(0.0, 140.0), ## should clear after typical setback
		Vector2(2500.0, 0.0), ## near a distant parallel road
		Vector2(2500.0, 200.0),
		Vector2(-4000.0, 50.0),
		Vector2(8000.0, -100.0),
		Vector2(100.0, 5000.0), ## far from all
	]

	for pos in samples:
		var margin: float = world.call(
			"_clearance_query_margin", tex, scale, true, "ew", 0.0
		)
		var local: Array = world.call("_query_road_index", pos, margin)
		_assert(local is Array, "query returns Array at %s" % str(pos))
		var clear_all: bool = world.call(
			"_sprite_clears_roads_list", pos, tex, scale, roads, true, "ew"
		)
		var clear_local: bool = world.call(
			"_sprite_clears_roads_list", pos, tex, scale, local, true, "ew"
		)
		_assert(
			clear_all == clear_local,
			"clearance local≡all at %s (all=%s local=%s local_n=%d)"
			% [str(pos), clear_all, clear_local, local.size()]
		)
		## Indexed query must be a strict subset (or equal) — never invent roads.
		_assert(
			local.size() <= roads.size(),
			"local road count ≤ all at %s (%d ≤ %d)" % [str(pos), local.size(), roads.size()]
		)

	## Near the main EW road, local query must include that road (not empty miss).
	var near := Vector2(0.0, 100.0)
	var near_margin: float = world.call(
		"_clearance_query_margin", tex, scale, true, "ew", 700.0
	)
	var near_local: Array = world.call("_query_road_index", near, near_margin)
	var found_main := false
	for road in near_local:
		if str(road.get("name", "")) == "Main":
			found_main = true
			break
	_assert(found_main, "index finds Main road near origin curb")

	## Texture cache: second load is same instance.
	var t1: Texture2D = world.call("_load_art_texture", "house_street_a_ew.png")
	var t2: Texture2D = world.call("_load_art_texture", "house_street_a_ew.png")
	_assert(t1 != null and t2 != null, "texture cache loads house art")
	_assert(t1 == t2, "texture cache returns same Texture2D instance")

	world.free()
	_finish()


func _fixture_roads() -> Array[Dictionary]:
	## One central EW road + many distant parallels so full scans would be expensive.
	var out: Array[Dictionary] = []
	out.append({
		"name": "Main",
		"half_w": 72.0,
		"points": PackedVector2Array([Vector2(-2000.0, 0.0), Vector2(2000.0, 0.0)]),
	})
	for i in range(12):
		var y := 3000.0 + float(i) * 800.0
		var x := float(i) * 900.0
		out.append({
			"name": "Far_%d" % i,
			"half_w": 36.0,
			"points": PackedVector2Array([
				Vector2(x - 500.0, y),
				Vector2(x + 500.0, y),
			]),
		})
	## Extra NS corridor far east.
	out.append({
		"name": "EastNS",
		"half_w": 52.0,
		"points": PackedVector2Array([Vector2(2500.0, -800.0), Vector2(2500.0, 800.0)]),
	})
	return out


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		_failed += 1
		printerr("FAIL: %s" % msg)
	else:
		print("ok: %s" % msg)


func _finish() -> void:
	if _failed == 0:
		print("=== m3_road_spatial_index_test PASS ===")
		quit(0)
	else:
		printerr("=== m3_road_spatial_index_test FAIL (%d) ===" % _failed)
		quit(1)
