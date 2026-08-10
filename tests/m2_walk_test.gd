extends SceneTree
## Walk assets, ground contact, shadow, and robot walk playback.

var _failed: int = 0

const CHAR_IDS := ["bolt", "marina", "rush"]
const WALK_DIRS := ["n", "e", "s", "ne", "se"]
const ART := "res://assets/art/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_walk_test start ===")
	_test_walk_assets_exist()
	_test_player_walk_and_shadow()
	if _failed == 0:
		print("=== m2_walk_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_walk_test FAIL (%d) ===" % _failed)
		quit(1)


func _test_walk_assets_exist() -> void:
	for id in CHAR_IDS:
		for d in WALK_DIRS:
			var sizes: Array[Vector2i] = []
			for i in range(1, 5):
				var path := ART + "%s_robot_walk_%s_%02d.png" % [id, d, i]
				_assert(ResourceLoader.exists(path), "exists %s" % path)
				var img := Image.new()
				if img.load(path) == OK:
					sizes.append(img.get_size())
				# Sample transparency on first and last frames only (enough coverage).
				if i == 1 or i == 4:
					_assert_corners_transparent(path)
			if sizes.size() == 4:
				for s in sizes:
					_assert(
						s == sizes[0],
						"%s walk_%s shared canvas %s (got %s)" % [id, d, str(sizes[0]), str(s)]
					)


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


func _test_player_walk_and_shadow() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	_assert(packed is PackedScene, "player.tscn loads")
	if packed is not PackedScene:
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)

	var shadow: Node = player.get_node_or_null("%Shadow")
	if shadow == null:
		shadow = player.get_node_or_null("Shadow")
	_assert(shadow != null, "Shadow node exists")
	if shadow is CanvasItem:
		_assert((shadow as CanvasItem).visible, "Shadow visible")

	for id in CHAR_IDS:
		player.call("set_character", id)
		player.call("set_form", 0) # ROBOT
		_assert(bool(player.call("has_walk_animation")), "%s has_walk_animation" % id)

		var ground_oy: float = float(player.call("get_ground_contact_offset_y"))
		_assert(ground_oy < -1.0, "%s ground contact offset_y < -1 (got %.2f)" % [id, ground_oy])

		player.call("update_facing_from_velocity", Vector2(1, 0))
		player.call("set_moving_for_test", true)
		_assert(bool(player.call("is_walk_playing")), "%s moving robot → is_walk_playing" % id)
		var walk: AnimatedSprite2D = player.get_node("WalkSprite")
		var robot: Sprite2D = player.get_node("RobotSprite")
		_assert(walk.visible, "%s WalkSprite visible while walking" % id)
		_assert(not robot.visible, "%s RobotSprite hidden while walking" % id)
		_assert(walk.animation == "walk_e", "%s walk anim walk_e for E" % id)

		player.call("update_facing_from_velocity", Vector2(-1, 0))
		player.call("set_moving_for_test", true)
		_assert(walk.animation == "walk_e", "%s W uses walk_e" % id)
		_assert(walk.flip_h == true, "%s W flip_h" % id)

		player.call("update_facing_from_velocity", Vector2(1, 1))
		player.call("set_moving_for_test", true)
		_assert(bool(player.call("is_walk_playing")), "%s SE moving → is_walk_playing" % id)
		_assert(walk.animation == "walk_se", "%s SE walk anim walk_se" % id)
		_assert(walk.flip_h == false, "%s SE flip_h false" % id)

		player.call("update_facing_from_velocity", Vector2(-1, 1))
		player.call("set_moving_for_test", true)
		_assert(bool(player.call("is_walk_playing")), "%s SW moving → is_walk_playing" % id)
		_assert(walk.animation == "walk_se", "%s SW uses walk_se" % id)
		_assert(walk.flip_h == true, "%s SW flip_h" % id)

		player.call("update_facing_from_velocity", Vector2(1, -1))
		player.call("set_moving_for_test", true)
		_assert(bool(player.call("is_walk_playing")), "%s NE moving → is_walk_playing" % id)
		_assert(walk.animation == "walk_ne", "%s NE walk anim walk_ne" % id)
		_assert(walk.flip_h == false, "%s NE flip_h false" % id)

		player.call("update_facing_from_velocity", Vector2(-1, -1))
		player.call("set_moving_for_test", true)
		_assert(bool(player.call("is_walk_playing")), "%s NW moving → is_walk_playing" % id)
		_assert(walk.animation == "walk_ne", "%s NW uses walk_ne" % id)
		_assert(walk.flip_h == true, "%s NW flip_h" % id)

		player.call("set_moving_for_test", false)
		_assert(not bool(player.call("is_walk_playing")), "%s stop → not is_walk_playing" % id)
		_assert(robot.visible, "%s stop → RobotSprite visible" % id)
		_assert(not walk.visible, "%s stop → WalkSprite hidden" % id)

		player.call("set_form", 1) # VEHICLE
		player.call("set_moving_for_test", true)
		_assert(not bool(player.call("is_walk_playing")), "%s vehicle moving → no walk" % id)

	player.queue_free()


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
