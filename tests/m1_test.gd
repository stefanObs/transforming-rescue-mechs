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

	_test_player_transform()
	_test_iso_helper()

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
	_assert(not bool(player.call("can_transform")), "lockout active after toggle")
	player.set("_transform_lock", 0.0)
	_assert(bool(player.call("can_transform")), "lockout cleared")
	player.call("toggle_form")
	_assert(int(player.get("form")) == 0, "toggle back to ROBOT")
	player.queue_free()


func _test_iso_helper() -> void:
	var packed: Variant = load("res://scenes/player.tscn")
	if not (packed is PackedScene):
		return
	var player: Node = (packed as PackedScene).instantiate()
	root.add_child(player)
	var east: Vector2 = player.call("_cartesian_to_iso", Vector2(1, 0))
	var south: Vector2 = player.call("_cartesian_to_iso", Vector2(0, 1))
	_assert(is_equal_approx(east.x, 1.0) and is_equal_approx(east.y, 0.5), "iso east vector")
	_assert(is_equal_approx(south.x, -1.0) and is_equal_approx(south.y, 0.5), "iso south vector")
	player.queue_free()
