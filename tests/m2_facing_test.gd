extends SceneTree
## 8-dir facing_from_velocity + screen vectors + robot/vehicle dir art match.

var _failed: int = 0

const CHAR_IDS := ["bolt", "marina", "rush"]
const ART := "res://assets/art/"
const DIR_SUFFIX := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const DIAG_SUFFIX := ["ne", "se", "sw", "nw"]
const FORMS := ["robot", "vehicle"]
## Facing enum: N=0 NE=1 E=2 SE=3 S=4 SW=5 W=6 NW=7
const FACING_N := 0
const FACING_NE := 1
const FACING_E := 2
const FACING_SE := 3
const FACING_S := 4
const FACING_SW := 5
const FACING_W := 6
const FACING_NW := 7
## Form enum
const FORM_ROBOT := 0
const FORM_VEHICLE := 1
## Input vector per facing suffix order.
const FACING_INPUTS := [
	Vector2(0, -1), # N
	Vector2(1, -1), # NE
	Vector2(1, 0), # E
	Vector2(1, 1), # SE
	Vector2(0, 1), # S
	Vector2(-1, 1), # SW
	Vector2(-1, 0), # W
	Vector2(-1, -1), # NW
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_facing_test start ===")
	_test_facing_from_velocity()
	_test_dir_assets_exist()
	_test_facing_applies_texture()
	_test_dir_art_no_lean()
	_test_diagonal_walk()
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
			for d in DIR_SUFFIX:
				var path := ART + "%s_%s_%s.png" % [id, form_name, d]
				_assert(ResourceLoader.exists(path), "exists %s" % path)
				if ResourceLoader.exists(path):
					_assert_corners_transparent(path)
		for d in DIAG_SUFFIX:
			var rpath := ART + "%s_robot_%s.png" % [id, d]
			_assert(ResourceLoader.exists(rpath), "robot diagonal required %s" % rpath)


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

	for id in CHAR_IDS:
		player.call("set_character", id)
		for form_enum in [FORM_ROBOT, FORM_VEHICLE]:
			var form_name: String = FORMS[form_enum]
			player.call("set_form", form_enum)
			for i in range(DIR_SUFFIX.size()):
				var suffix: String = DIR_SUFFIX[i]
				var expected_end := "_%s.png" % suffix
				player.call("update_facing_from_velocity", FACING_INPUTS[i])
				_assert(
					int(player.call("get_facing")) == i,
					"%s %s facing %s" % [id, form_name, suffix]
				)
				var tex_path: String = str(player.call("get_facing_texture_path", form_enum))
				_assert(
					tex_path.ends_with(expected_end),
					"%s %s texture path ends with %s (got %s)" % [id, form_name, expected_end, tex_path]
				)
				var expected_path := ART + "%s_%s_%s.png" % [id, form_name, suffix]
				_assert(
					tex_path == expected_path or tex_path.ends_with("%s_%s_%s.png" % [id, form_name, suffix]),
					"%s %s facing %s → %s" % [id, form_name, suffix, expected_path]
				)

	player.queue_free()


func _test_dir_art_no_lean() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	var robot: Sprite2D = player.get_node("RobotSprite")
	var vehicle: Sprite2D = player.get_node("VehicleSprite")

	for id in CHAR_IDS:
		player.call("set_character", id)
		_assert(bool(player.call("uses_dir_textures")), "%s uses_dir_textures" % id)

		player.call("set_form", FORM_ROBOT)
		player.call("apply_turn_from_dirs", Vector2(1, 0), Vector2(0, -1))
		_assert(absf(float(player.call("get_turn_blend"))) > 0.2, "%s robot turn blend nonzero" % id)
		_assert(is_equal_approx(robot.rotation, 0.0), "%s robot dir art → rotation 0 while turning" % id)

		player.call("set_form", FORM_VEHICLE)
		player.call("apply_turn_from_dirs", Vector2(1, 0), Vector2(0, -1))
		_assert(absf(float(player.call("get_turn_blend"))) > 0.2, "%s vehicle turn blend nonzero" % id)
		_assert(is_equal_approx(vehicle.rotation, 0.0), "%s vehicle dir art → rotation 0 while turning" % id)

	player.queue_free()


func _test_diagonal_walk() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	var robot: Sprite2D = player.get_node("RobotSprite")
	var walk: AnimatedSprite2D = player.get_node("WalkSprite")

	for id in CHAR_IDS:
		player.call("set_character", id)
		player.call("set_form", FORM_ROBOT)
		player.call("update_facing_from_velocity", Vector2(1, 1)) # SE
		_assert(int(player.call("get_facing")) == FACING_SE, "%s facing SE" % id)
		player.call("set_moving_for_test", true)
		_assert(bool(player.call("is_walk_playing")), "%s SE moving → is_walk_playing" % id)
		_assert(walk.visible, "%s SE moving → WalkSprite visible" % id)
		_assert(not robot.visible, "%s SE moving → RobotSprite hidden" % id)
		_assert(walk.animation == "walk_se", "%s SE walk anim walk_se (got %s)" % [id, walk.animation])
		player.call("set_moving_for_test", false)
		_assert(robot.visible, "%s SE stop → RobotSprite visible" % id)
		var se_path: String = str(player.call("get_facing_texture_path", FORM_ROBOT))
		_assert(se_path.ends_with("_se.png"), "%s SE idle robot texture (got %s)" % [id, se_path])

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
