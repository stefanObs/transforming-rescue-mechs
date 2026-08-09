extends SceneTree
## Lightweight headless smoke tests for M0 (no external addon required yet).
## Run: godot --headless --path . -s res://tests/smoke_test.gd
## Note: Autoload globals are not injected into -s scripts; use /root nodes.

var _failed: int = 0
var _game_state: Node
var _save_service: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== smoke_test start ===")
	_game_state = root.get_node_or_null("GameState")
	_save_service = root.get_node_or_null("SaveService")
	_test_autoloads_present()
	_test_game_state_coins()
	_test_save_service_roundtrip()
	_test_main_scene_path()
	if _failed == 0:
		print("=== smoke_test PASS ===")
		quit(0)
	else:
		printerr("=== smoke_test FAIL (%d) ===" % _failed)
		quit(1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _test_autoloads_present() -> void:
	_assert(_game_state != null, "GameState autoload exists")
	_assert(_save_service != null, "SaveService autoload exists")


func _test_game_state_coins() -> void:
	if _game_state == null:
		_failed += 1
		return
	_game_state.call("reset_for_new_game")
	_assert(int(_game_state.get("coins")) == 0, "coins reset to 0")
	_game_state.call("add_coins", 5)
	_assert(int(_game_state.get("coins")) == 5, "add_coins(5) => 5")
	_game_state.call("add_coins", -2)
	_assert(int(_game_state.get("coins")) == 3, "add_coins(-2) => 3")
	_game_state.call("reset_for_new_game")


func _test_save_service_roundtrip() -> void:
	if _game_state == null or _save_service == null:
		_failed += 1
		return
	_game_state.call("reset_for_new_game")
	_game_state.call("add_coins", 7)
	_game_state.set("current_character_id", "marina")
	var save_err: int = _save_service.call("save_game")
	_assert(save_err == OK, "save_game OK")
	_game_state.call("reset_for_new_game")
	_assert(int(_game_state.get("coins")) == 0, "reset before load")
	var load_err: int = _save_service.call("load_game")
	_assert(load_err == OK, "load_game OK")
	_assert(int(_game_state.get("coins")) == 7, "loaded coins == 7")
	_assert(str(_game_state.get("current_character_id")) == "marina", "loaded character marina")
	_game_state.call("reset_for_new_game")


func _test_main_scene_path() -> void:
	_assert(ResourceLoader.exists("res://scenes/main.tscn"), "main.tscn exists")
	var packed: Variant = load("res://scenes/main.tscn")
	_assert(packed is PackedScene, "main.tscn loads as PackedScene")
	if packed is PackedScene:
		var instance: Node = (packed as PackedScene).instantiate()
		root.add_child(instance)
		_assert(instance is Control, "main scene instantiates as Control")
		var title: Label = instance.get_node_or_null("%TitleLabel") as Label
		_assert(title != null, "TitleLabel unique name resolves")
		if title != null:
			_assert(title.text.contains("Rettungsmechs"), "title text set after _ready")
		instance.queue_free()
	var save_path := ProjectSettings.globalize_path("user://save_slot_0.json")
	if FileAccess.file_exists("user://save_slot_0.json"):
		DirAccess.remove_absolute(save_path)