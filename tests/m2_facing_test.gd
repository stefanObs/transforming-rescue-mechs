extends SceneTree
## 8-dir facing_from_velocity + screen vectors + vehicle se/sw/ne/nw art.

var _failed: int = 0

const CHAR_IDS := ["bolt", "marina", "rush"]
const ART := "res://assets/art/"
## Cardinals required for robot+vehicle; diagonals required for vehicles.
const CARDINAL_SUFFIX := ["n", "e", "s", "w"]
const VEHICLE_DIAG_SUFFIX := ["se", "sw", "ne", "nw"]
const FORMS := ["robot", "vehicle"]

# Facing enum: N=0 NE=1 E=2 SE=3 S=4 SW=5 W=6 NW=7
const FACING_N := 0
const FACING_NE := 1
const FACING_E := 2
const FACING_SE := 3
const FACING_S := 4
const FACING_SW := 5
const FACING_W := 6
const FACING_NW := 7


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_facing_test start ===")
	_test_facing_from_velocity()
	_test_dir_assets_exist()
	_test_facing_applies_texture()
	_test_screen_move_identity()
	if _failed == 0:
		print("=== m2_facing_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_facing_test FAIL (%d) ===" % _failed)
		quit(1)


func _test_facing_from_velocity() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	_assert(packed is PackedScene, "player.tscn loads")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)

	_assert(int(player.call("facing_from_velocity", Vector2(0, -1))) == FACING_N, "up → N")
	_assert(int(player.call("facing_from_velocity", Vector2(1, -1))) == FACING_NE, "up+right → NE")
	_assert(int(player.call("facing_from_velocity", Vector2(1, 0))) == FACING_E, "right → E")
	_assert(int(player.call("facing_from_velocity", Vector2(1, 1))) == FACING_SE, "down+right → SE")
	_assert(int(player.call("facing_from_velocity", Vector2(0, 1))) == FACING_S, "down → S")
	_assert(int(player.call("facing_from_velocity", Vector2(-1, 1))) == FACING_SW, "down+left → SW")
	_assert(int(player.call("facing_from_velocity", Vector2(-1, 0))) == FACING_W, "left → W")
	_assert(int(player.call("facing_from_velocity", Vector2(-1, -1))) == FACING_NW, "up+left → NW")
	_assert(int(player.call("facing_from_velocity", Vector2.ZERO)) == FACING_S, "zero → S default")

	# Near-cardinal / near-diagonal sectors
	_assert(int(player.call("facing_from_velocity", Vector2(2, 0.2))) == FACING_E, "mostly right → E")
	_assert(int(player.call("facing_from_velocity", Vector2(0.2, 2))) == FACING_S, "mostly down → S")
	_assert(int(player.call("facing_from_velocity", Vector2(1, 0.9))) == FACING_SE, "near SE stays SE")

	player.call("update_facing_from_velocity", Vector2(0, 1))
	_assert(int(player.call("get_facing")) == FACING_S, "gameplay down → get_facing S")
	player.call("update_facing_from_velocity", Vector2(1, 1))
	_assert(int(player.call("get_facing")) == FACING_SE, "gameplay down+right → SE")
	player.call("update_facing_from_velocity", Vector2(-1, 1))
	_assert(int(player.call("get_facing")) == FACING_SW, "gameplay down+left → SW")

	player.queue_free()


func _test_dir_assets_exist() -> void:
	for id in CHAR_IDS:
		for form_name in FORMS:
			for d in CARDINAL_SUFFIX:
				var path := ART + "%s_%s_%s.png" % [id, form_name, d]
				_assert(ResourceLoader.exists(path), "exists %s" % path)
				if ResourceLoader.exists(path):
					_assert_corners_transparent(path)
		for d in VEHICLE_DIAG_SUFFIX:
			var vpath := ART + "%s_vehicle_%s.png" % [id, d]
			_assert(ResourceLoader.exists(vpath), "exists %s" % vpath)
			if ResourceLoader.exists(vpath):
				_assert_corners_transparent(vpath)


func _assert_corners_transparent(path: String) -> void:
	var img := Image.new()
	var err := img.load(path)
	_assert(err == OK, "load image %s" % path)
	if err != OK:
		return
	_assert(img.get_format() == Image.FORMAT_RGBA8 or img.detect_alpha(), "has alpha %s" % path)
	for p in [
		Vector2i(0, 0),
		Vector2i(img.get_width() - 1, 0),
		Vector2i(0, img.get_height() - 1),
		Vector2i(img.get_width() - 1, img.get_height() - 1),
	]:
		var c := img.get_pixelv(p)
		_assert(c.a < 0.05, "transparent corner %s @%s a=%.2f" % [path, str(p), c.a])


func _test_facing_applies_texture() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	var robot: Sprite2D = player.get_node("RobotSprite")
	var vehicle: Sprite2D = player.get_node("VehicleSprite")

	for id in CHAR_IDS:
		player.call("set_character", id)
		player.call("set_form", 0) # ROBOT
		var n_path := ART + "%s_robot_n.png" % id
		var e_path := ART + "%s_robot_e.png" % id
		if not ResourceLoader.exists(n_path) or not ResourceLoader.exists(e_path):
			_assert(false, "%s dir art required for texture apply test" % id)
			continue
		var n_tex: Texture2D = load(n_path)
		var e_tex: Texture2D = load(e_path)

		player.call("update_facing_from_velocity", Vector2(0, -1))
		_assert(int(player.call("get_facing")) == FACING_N, "%s facing N" % id)
		_assert(robot.texture == n_tex, "%s robot texture is N art" % id)

		player.call("update_facing_from_velocity", Vector2(1, 0))
		_assert(int(player.call("get_facing")) == FACING_E, "%s facing E" % id)
		_assert(robot.texture == e_tex, "%s robot texture is E art" % id)
		_assert(robot.flip_h == false, "%s E no flip_h" % id)

		player.call("update_facing_from_velocity", Vector2(-1, 0))
		_assert(int(player.call("get_facing")) == FACING_W, "%s facing W" % id)
		var w_path := ART + "%s_robot_w.png" % id
		if ResourceLoader.exists(w_path):
			_assert(robot.flip_h == false, "%s dedicated W → flip_h false" % id)
			_assert(robot.texture == load(w_path), "%s robot texture is W art" % id)
		else:
			_assert(robot.flip_h == true, "%s W fallback flip_h" % id)

		# Vehicle diagonals (SE/SW) when art present.
		player.call("set_form", 1) # VEHICLE
		var se_path := ART + "%s_vehicle_se.png" % id
		var sw_path := ART + "%s_vehicle_sw.png" % id
		if ResourceLoader.exists(se_path):
			player.call("update_facing_from_velocity", Vector2(1, 1))
			_assert(int(player.call("get_facing")) == FACING_SE, "%s vehicle SE facing" % id)
			_assert(vehicle.texture == load(se_path), "%s vehicle texture is SE art" % id)
		if ResourceLoader.exists(sw_path):
			player.call("update_facing_from_velocity", Vector2(-1, 1))
			_assert(int(player.call("get_facing")) == FACING_SW, "%s vehicle SW facing" % id)
			_assert(vehicle.texture == load(sw_path), "%s vehicle texture is SW art" % id)

	player.queue_free()


func _test_screen_move_identity() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	# Movement no longer applies iso skew; helper is identity for legacy callers.
	var down: Vector2 = player.call("_cartesian_to_iso", Vector2(0, 1))
	var up: Vector2 = player.call("_cartesian_to_iso", Vector2(0, -1))
	_assert(is_equal_approx(down.x, 0.0) and is_equal_approx(down.y, 1.0), "screen down identity")
	_assert(is_equal_approx(up.x, 0.0) and is_equal_approx(up.y, -1.0), "screen up identity")
	# Facing uses screen vectors directly (down → S, not iso-skewed E).
	_assert(int(player.call("facing_from_velocity", Vector2(0, 1))) == FACING_S, "screen down → S")
	player.queue_free()


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
