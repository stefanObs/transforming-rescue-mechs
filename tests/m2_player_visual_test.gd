extends SceneTree
## Player scale, actor z above ground, and facing from velocity.

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_player_visual_test start ===")
	_test_sprite_scale()
	_test_actor_z_above_ground()
	_test_facing()
	if _failed == 0:
		print("=== m2_player_visual_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_player_visual_test FAIL (%d) ===" % _failed)
		quit(1)


func _test_sprite_scale() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	_assert(packed is PackedScene, "player.tscn loads")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	var scale: Vector2 = player.call("get_sprite_scale")
	_assert(scale.x <= 0.1 and scale.y <= 0.1, "sprite scale <= 0.1 (got %s)" % scale)
	_assert(is_equal_approx(scale.x, 0.085), "sprite scale.x == 0.085")
	var robot: Sprite2D = player.get_node("RobotSprite")
	_assert(is_equal_approx(robot.scale.x, scale.x), "RobotSprite uses SPRITE_SCALE")
	player.queue_free()


func _test_actor_z_above_ground() -> void:
	var world_script: GDScript = load("res://scripts/world_sandbox.gd")
	_assert(world_script != null, "world_sandbox.gd loads")
	var base: int = int(world_script.ACTOR_Z_BASE)
	_assert(base >= 100, "ACTOR_Z_BASE high enough above ground")
	for y in [-500, -40, -1, 0, 100, 700]:
		var z: int = world_script.compute_actor_z(float(y))
		_assert(z == base + y, "actor_z(%d) == %d+%d (got %d)" % [y, base, y, z])
		_assert(z > -30, "actor_z(%d)=%d always above ground max (-30)" % [y, z])
		_assert(z <= 4096, "actor_z(%d)=%d within Godot canvas z max" % [y, z])
	var prop_base: int = int(world_script.PROP_Z_BASE)
	_assert(prop_base == base, "props and actors share z BASE for Y-sort")
	_assert(
		world_script.compute_actor_z(10.0) > world_script.compute_prop_z(0.0),
		"actor south of prop draws in front"
	)
	_assert(
		world_script.compute_actor_z(-10.0) < world_script.compute_prop_z(0.0),
		"actor north of prop draws behind"
	)


func _test_facing() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	var robot: Sprite2D = player.get_node("RobotSprite")
	var vehicle: Sprite2D = player.get_node("VehicleSprite")

	# Facing: N=0 NE=1 E=2 SE=3 S=4 SW=5 W=6 NW=7
	player.call("update_facing_from_velocity", Vector2(-1, 0))
	_assert(int(player.call("get_facing")) == 6, "left move → facing W")
	_assert(is_equal_approx(robot.rotation, 0.0), "no turn → robot lean 0")

	player.call("update_facing_from_velocity", Vector2(1, 0))
	_assert(int(player.call("get_facing")) == 2, "right move → facing E")
	_assert(robot.flip_h == false, "right move → robot flip_h false")
	_assert(vehicle.flip_h == false, "right move → vehicle flip_h false")

	player.call("set_form", 1) # Form.VEHICLE
	player.call("update_facing_from_velocity", Vector2(-0.5, 0.5))
	# 8-dir: down+left → SW
	_assert(int(player.call("get_facing")) == 5, "vehicle leftish → facing SW")
	_assert(is_equal_approx(vehicle.rotation, 0.0), "no turn → vehicle lean 0")

	var facing_before := int(player.call("get_facing"))
	player.call("update_facing_from_velocity", Vector2.ZERO)
	_assert(int(player.call("get_facing")) == facing_before, "facing kept when stopped")

	player.call("set_form", 0) # Form.ROBOT
	player.call("update_facing_from_velocity", Vector2(0, -1))
	_assert(int(player.call("get_facing")) == 0, "pure up → facing N")
	_assert(is_equal_approx(robot.rotation, 0.0), "no turn → robot lean still 0")

	player.queue_free()


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
