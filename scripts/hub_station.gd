extends Node2D
## Erdstation hub yard: Style-C backdrop + hub sprite + exit back to world.

const WORLD_SCENE := "res://scenes/world_sandbox.tscn"
var DEFAULT_WORLD_SPAWN: Vector2 = SeuzachGeo.default_world_spawn() # Winterthurerstrasse / WINT-KERN
const ACTOR_Z_BASE := 2000

@onready var _player: CharacterBody2D = %Player
@onready var _hint: Label = %HintLabel
@onready var _status: Label = %StatusLabel
@onready var _hub_exit: Area2D = %HubExit

var _paused: bool = false
var _player_in_exit: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_exit_area()
	_hint.text = (
		"Bewegen: %s | Transform: %s/Q | Exit: %s — Zurück zur Welt"
		% [
			InputGlyphs.glyph_for("move_left"),
			InputGlyphs.glyph_for("transform"),
			InputGlyphs.glyph_for("interact"),
		]
	)
	if _player and _player.has_signal("form_changed"):
		_player.form_changed.connect(_on_form_changed)
	_sync_actor_z()
	_refresh_status()


func _setup_exit_area() -> void:
	if _hub_exit == null:
		return
	_hub_exit.set_meta("hub_exit", true)
	_hub_exit.monitoring = true
	_hub_exit.monitorable = true
	if not _hub_exit.body_entered.is_connected(_on_exit_body_entered):
		_hub_exit.body_entered.connect(_on_exit_body_entered)
	if not _hub_exit.body_exited.is_connected(_on_exit_body_exited):
		_hub_exit.body_exited.connect(_on_exit_body_exited)


func _sync_actor_z() -> void:
	if _player:
		_player.z_as_relative = false
		_player.z_index = ACTOR_Z_BASE + int(_player.global_position.y) + 1


func _unhandled_input(event: InputEvent) -> void:
	if _paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_switch_character("bolt")
			KEY_2:
				_switch_character("marina")
			KEY_3:
				_switch_character("rush")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause_menu"):
		_paused = not _paused
		get_tree().paused = _paused
		if _paused:
			_status.text = "Pause / Speichern (Stub) — Esc zum Weiterspielen"
		else:
			_refresh_status()
		return
	if _paused:
		return
	if _player_in_exit and Input.is_action_just_pressed("interact"):
		exit_to_world_for_test()
	_refresh_status()
	_sync_actor_z()


func _switch_character(id: String) -> void:
	if _player and _player.has_method("set_character"):
		if str(_player.get("character_id")) != id:
			_player.call("set_character", id)


func _on_form_changed(_new_form: Variant) -> void:
	if not _paused:
		_refresh_status()


func _refresh_status() -> void:
	if _player == null:
		return
	var form_name := "Fahrzeug" if int(_player.get("form")) == 1 else "Robot"
	var char_id := str(_player.get("character_id"))
	var exit_hint := ""
	if _player_in_exit:
		exit_hint = " | %s — Zurück zur Welt" % InputGlyphs.glyph_for("interact")
	_status.text = "M3 Hub | %s | Form: %s | Münzen: %d%s" % [
		char_id.capitalize(), form_name, GameState.coins, exit_hint
	]


func _on_exit_body_entered(body: Node) -> void:
	if body == _player:
		_player_in_exit = true
		_refresh_status()


func _on_exit_body_exited(body: Node) -> void:
	if body == _player:
		_player_in_exit = false
		_refresh_status()


## Headless-friendly exit: ensure world spawn, then load world_sandbox.
func exit_to_world_for_test() -> void:
	if not GameState.has_world_spawn:
		GameState.set_world_spawn(DEFAULT_WORLD_SPAWN)
	get_tree().change_scene_to_file(WORLD_SCENE)


func is_player_in_exit_for_test() -> bool:
	return _player_in_exit
