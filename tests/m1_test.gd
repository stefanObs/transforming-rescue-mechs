extends SceneTree
## M1 tests: input actions + player transform state.
## Run via scripts/run_tests.sh

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m1_test start ===")
	var input_setup: Node = root.get_node_or_null("InputSetup")
	var glyphs: Node = root.get_node_or_null("InputGlyphs")
	_assert(input_setup != null, "InputSetup autoload exists")
	_assert(glyphs != null, "InputGlyphs autoload exists")
	if input_setup:
		input_setup.call("ensure_actions")
		_assert(bool(input_setup.call("has_required_actions")), "required input actions registered")
	if glyphs:
		_assert(str(glyphs.call("glyph_for", "transform")) == "Space", "keyboard glyph transform=Space")
		_assert(str(glyphs.call("glyph_for", "transform", 1)) == "B", "xbox glyph transform=B")
		_assert(str(glyphs.call("glyph_for", "debug_overlay")) == "F1", "keyboard glyph debug_overlay=F1")
	if input_setup:
		_assert(InputMap.has_action("debug_overlay"), "debug_overlay action registered")
		if InputMap.has_action("debug_overlay"):
			var has_f1 := false
			for ev in InputMap.action_get_events("debug_overlay"):
				if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_F1:
					has_f1 = true
			_assert(has_f1, "debug_overlay bound to F1")

	_test_player_transform()
	_test_screen_move_helper()

	if _failed == 0:
		print("=== m1_test PASS ===")
		quit(0)
	else:
		printerr("=== m1_test FAIL (%d) ===" % _failed)
		quit(1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _test_player_transform() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	_assert(packed is PackedScene, "player.tscn loads")
	if not (packed is PackedScene):
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	_assert(int(player.get("form")) == 0, "default form ROBOT")
	_assert(bool(player.call("can_transform")), "can_transform initially")
	player.call("toggle_form")
	_assert(int(player.get("form")) == 1, "after toggle VEHICLE")
	# M2: Bolt plays transform animation; finish it for deterministic unit tests.
	if bool(player.get("_transforming")):
		player.call("_on_transform_finished")
	_assert(not bool(player.call("can_transform")), "lockout active after toggle")
	player.set("_transform_lock", 0.0)
	_assert(bool(player.call("can_transform")), "lockout cleared")
	player.call("toggle_form")
	if bool(player.get("_transforming")):
		player.call("_on_transform_finished")
	_assert(int(player.get("form")) == 0, "toggle back to ROBOT")
	player.queue_free()


func _test_screen_move_helper() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	if not (packed is PackedScene):
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	# Locomotion is screen-aligned; _cartesian_to_iso is a deprecated identity.
	var east: Vector2 = player.call("_cartesian_to_iso", Vector2(1, 0))
	var south: Vector2 = player.call("_cartesian_to_iso", Vector2(0, 1))
	_assert(is_equal_approx(east.x, 1.0) and is_equal_approx(east.y, 0.0), "screen east identity")
	_assert(is_equal_approx(south.x, 0.0) and is_equal_approx(south.y, 1.0), "screen south identity")
	player.queue_free()
