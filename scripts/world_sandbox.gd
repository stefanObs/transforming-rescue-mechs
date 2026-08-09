extends Node2D
## Sandbox world for M1: player + HUD hints.

@onready var _player: CharacterBody2D = %Player
@onready var _hint: Label = %HintLabel
@onready var _status: Label = %StatusLabel

var _paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hint.text = (
		"Bewegen: %s | Transform: %s / Q | Pause: %s"
		% [
			InputGlyphs.glyph_for("move_left"),
			InputGlyphs.glyph_for("transform"),
			InputGlyphs.glyph_for("pause_menu"),
		]
	)
	if _player and _player.has_signal("form_changed"):
		_player.form_changed.connect(_on_form_changed)
	_refresh_status()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause_menu"):
		_paused = not _paused
		get_tree().paused = _paused
		if _paused:
			_status.text = "Pause / Speichern (Stub) — Esc zum Weiterspielen"
		else:
			_refresh_status()
		return
	if not _paused:
		_refresh_status()


func _on_form_changed(_new_form: Variant) -> void:
	if not _paused:
		_refresh_status()


func _refresh_status() -> void:
	if _player == null:
		return
	var form_name := "Fahrzeug" if int(_player.get("form")) == 1 else "Robot"
	_status.text = "M1 Sandbox | Form: %s | Münzen: %d" % [form_name, GameState.coins]
