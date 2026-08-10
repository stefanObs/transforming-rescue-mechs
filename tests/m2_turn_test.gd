extends SceneTree
## Turn-pose assets + lean/blend helpers for bolt/marina/rush.

var _failed: int = 0

const CHAR_IDS := ["bolt", "marina", "rush"]
const ART := "res://assets/art/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_turn_test start ===")
	_test_turn_assets_exist()
	_test_turn_blend_and_lean()
	if _failed == 0:
		print("=== m2_turn_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_turn_test FAIL (%d) ===" % _failed)
		quit(1)


func _test_turn_assets_exist() -> void:
	for id in CHAR_IDS:
		var robot_turn := ART + "%s_robot_turn.png" % id
		var vehicle_turn := ART + "%s_vehicle_turn.png" % id
		_assert(ResourceLoader.exists(robot_turn), "exists %s" % robot_turn)
		_assert(ResourceLoader.exists(vehicle_turn), "exists %s" % vehicle_turn)
		_assert_corners_transparent(robot_turn)
		_assert_corners_transparent(vehicle_turn)


func _assert_corners_transparent(path: String) -> void:
	var img := Image.new()
	var err := img.load(path)
	_assert(err == OK, "load image %s" % path)
	if err != OK:
		return
	_assert(img.get_format() == Image.FORMAT_RGBA8 or img.detect_alpha(), "has alpha %s" % path)
	for p in [Vector2i(0, 0), Vector2i(img.get_width() - 1, 0), Vector2i(0, img.get_height() - 1), Vector2i(img.get_width() - 1, img.get_height() - 1)]:
		var c := img.get_pixelv(p)
		_assert(c.a < 0.05, "transparent corner %s @%s a=%.2f" % [path, str(p), c.a])


func _test_turn_blend_and_lean() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	_assert(packed is PackedScene, "player.tscn loads")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)

	for id in CHAR_IDS:
		player.call("set_character", id)
		_assert(
			is_equal_approx(float(player.call("get_turn_blend")), 0.0),
			"%s turn_blend reset after set_character" % id
		)

		# Sharp left turn (east → north-ish left).
		player.call("apply_turn_from_dirs", Vector2(1, 0), Vector2(0, -1))
		var blend_left: float = float(player.call("get_turn_blend"))
		_assert(absf(blend_left) > 0.2, "%s left turn |blend|=%.3f > 0.2" % [id, absf(blend_left)])

		player.call("set_form", 0) # ROBOT
		player.call("apply_turn_from_dirs", Vector2(1, 0), Vector2(0, -1))
		var robot: Sprite2D = player.get_node("RobotSprite")
		var robot_rot: float = robot.rotation
		var has_dir_art := bool(player.call("uses_dir_textures"))
		if has_dir_art:
			_assert(is_equal_approx(robot_rot, 0.0), "%s dir art → robot lean 0 (got %.4f)" % [id, robot_rot])
		else:
			_assert(absf(robot_rot) > 0.0, "%s robot lean nonzero (%.4f)" % [id, robot_rot])
			var lean_cap := deg_to_rad(8.0) + 0.001
			_assert(absf(robot_rot) <= lean_cap, "%s robot lean <= 8° (got %.4f)" % [id, robot_rot])
		if absf(float(player.call("get_turn_blend"))) > 0.28:
			if has_dir_art:
				_assert(
					not bool(player.call("is_using_turn_pose")),
					"%s dir art → no turn pose" % id
				)
			else:
				var turn_tex: Variant = player.get("_robot_turn_tex")
				if turn_tex != null:
					_assert(bool(player.call("is_using_turn_pose")), "%s robot uses turn pose" % id)
					_assert(
						robot.texture == turn_tex,
						"%s robot sprite shows turn texture" % id
					)
				else:
					_assert(
						not bool(player.call("is_using_turn_pose")),
						"%s no turn tex → is_using_turn_pose false" % id
					)

		# Sharp right turn from previous smear.
		player.call("apply_turn_from_dirs", Vector2(0, -1), Vector2(1, 0))
		var blend_right: float = float(player.call("get_turn_blend"))
		_assert(absf(blend_right) > 0.2, "%s right turn |blend|=%.3f > 0.2" % [id, absf(blend_right)])
		# Opposite turn should flip lean sign vs previous left turn.
		_assert(
			signf(blend_right) != signf(blend_left) or absf(blend_right - blend_left) > 0.3,
			"%s left/right blends differ (L=%.3f R=%.3f)" % [id, blend_left, blend_right]
		)

		# Same dirs → same |blend|; with dir art both forms stay rotation 0.
		player.call("set_form", 0) # ROBOT
		player.call("apply_turn_from_dirs", Vector2(1, 0), Vector2(0, 1))
		var robot_blend: float = float(player.call("get_turn_blend"))
		var robot_abs: float = absf(robot.rotation)
		player.call("set_form", 1) # VEHICLE (resets turn)
		player.call("apply_turn_from_dirs", Vector2(1, 0), Vector2(0, 1))
		var vehicle: Sprite2D = player.get_node("VehicleSprite")
		var vehicle_blend: float = float(player.call("get_turn_blend"))
		var vehicle_abs: float = absf(vehicle.rotation)
		_assert(
			is_equal_approx(robot_blend, vehicle_blend),
			"%s same dirs → equal blend (R=%.3f V=%.3f)" % [id, robot_blend, vehicle_blend]
		)
		if has_dir_art:
			_assert(is_equal_approx(robot_abs, 0.0), "%s dir art → robot rot 0" % id)
			_assert(is_equal_approx(vehicle_abs, 0.0), "%s dir art → vehicle rot 0" % id)
		else:
			_assert(
				vehicle_abs > robot_abs,
				"%s vehicle |rot|=%.4f > robot |rot|=%.4f" % [id, vehicle_abs, robot_abs]
			)
			_assert(
				absf(vehicle.rotation) <= deg_to_rad(18.0) + 0.001,
				"%s vehicle lean <= 18° (got %.4f)" % [id, vehicle.rotation]
			)
			_assert(
				signf(vehicle.rotation) == signf(vehicle_blend) or is_zero_approx(vehicle.rotation),
				"%s vehicle lean sign matches blend" % id
			)

	player.queue_free()


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
