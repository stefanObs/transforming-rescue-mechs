extends SceneTree
## 4-dir facing_from_velocity + per-char N/E/S/W art + texture apply.

var _failed: int = 0

const CHAR_IDS := ["bolt", "marina", "rush"]
const ART := "res://assets/art/"
const DIR_SUFFIX := ["n", "e", "s", "w"]
const FORMS := ["robot", "vehicle"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_facing_test start ===")
	_test_facing_from_velocity()
	_test_dir_assets_exist()
	_test_facing_applies_texture()
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

	# Facing: N=0 E=1 S=2 W=3
	_assert(int(player.call("facing_from_velocity", Vector2(0, -1))) == 0, "up → N")
	_assert(int(player.call("facing_from_velocity", Vector2(1, 0))) == 1, "right → E")
	_assert(int(player.call("facing_from_velocity", Vector2(0, 1))) == 2, "down → S")
	_assert(int(player.call("facing_from_velocity", Vector2(-1, 0))) == 3, "left → W")
	# Dominant axis
	_assert(int(player.call("facing_from_velocity", Vector2(2, 1))) == 1, "mostly right → E")
	_assert(int(player.call("facing_from_velocity", Vector2(1, -2))) == 0, "mostly up → N")
	_assert(int(player.call("facing_from_velocity", Vector2(-2, 0.5))) == 3, "mostly left → W")
	_assert(int(player.call("facing_from_velocity", Vector2(0.5, 2))) == 2, "mostly down → S")
	_assert(int(player.call("facing_from_velocity", Vector2.ZERO)) == 2, "zero → S default")

	# Regression: post-iso "up" looks like E; facing must use pre-iso input (up → N).
	var iso_up: Vector2 = player.call("_cartesian_to_iso", Vector2(0, -1))
	_assert(int(player.call("facing_from_velocity", iso_up)) == 1, "iso(up) alone would be E")
	_assert(int(player.call("facing_from_velocity", Vector2(0, -1))) == 0, "pre-iso up stays N")
	player.call("update_facing_from_velocity", Vector2(0, -1))
	_assert(int(player.call("get_facing")) == 0, "gameplay path up → get_facing N")

	player.queue_free()


func _test_dir_assets_exist() -> void:
	for id in CHAR_IDS:
		for form_name in FORMS:
			for d in DIR_SUFFIX:
				var path := ART + "%s_%s_%s.png" % [id, form_name, d]
				_assert(ResourceLoader.exists(path), "exists %s" % path)
				if ResourceLoader.exists(path):
					_assert_corners_transparent(path)


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
		_assert(int(player.call("get_facing")) == 0, "%s facing N" % id)
		_assert(robot.texture == n_tex, "%s robot texture is N art" % id)

		player.call("update_facing_from_velocity", Vector2(1, 0))
		_assert(int(player.call("get_facing")) == 1, "%s facing E" % id)
		_assert(robot.texture == e_tex, "%s robot texture is E art" % id)
		_assert(robot.flip_h == false, "%s E no flip_h" % id)

		player.call("update_facing_from_velocity", Vector2(-1, 0))
		_assert(int(player.call("get_facing")) == 3, "%s facing W" % id)
		# Dedicated W → no flip; else flip_h fallback.
		var w_path := ART + "%s_robot_w.png" % id
		if ResourceLoader.exists(w_path):
			_assert(robot.flip_h == false, "%s dedicated W → flip_h false" % id)
			_assert(robot.texture == load(w_path), "%s robot texture is W art" % id)
		else:
			_assert(robot.flip_h == true, "%s W fallback flip_h" % id)

	player.queue_free()


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
