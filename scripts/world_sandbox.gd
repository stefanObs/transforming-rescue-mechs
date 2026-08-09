extends Node2D
## Sandbox world with Style C tile/landmark probe (M2).

const ART := "res://assets/art/"
const TILE_SCALE := Vector2(0.18, 0.18)
const PROP_SCALE := Vector2(0.22, 0.22)
const HUB_SCALE := Vector2(0.35, 0.35)

@onready var _player: CharacterBody2D = %Player
@onready var _hint: Label = %HintLabel
@onready var _status: Label = %StatusLabel
@onready var _props: Node2D = %Props

var _paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_art_probe()
	_hint.text = (
		"Bewegen: %s | Transform: %s/Q | Char: 1=Bolt 2=Marina 3=Rush | Pause: %s"
		% [
			InputGlyphs.glyph_for("move_left"),
			InputGlyphs.glyph_for("transform"),
			InputGlyphs.glyph_for("pause_menu"),
		]
	)
	if _player and _player.has_signal("form_changed"):
		_player.form_changed.connect(_on_form_changed)
	_refresh_status()


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
	if not _paused:
		_refresh_status()


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
	_status.text = "M2 Art-Spike | %s | Form: %s | Münzen: %d" % [char_id.capitalize(), form_name, GameState.coins]


func _build_art_probe() -> void:
	for child in _props.get_children():
		child.queue_free()

	# Iso-ish grass / road scatter
	var grass: Texture2D = load(ART + "tile_grass.png")
	var road: Texture2D = load(ART + "tile_road.png")
	for y in range(-2, 3):
		for x in range(-3, 4):
			var spr := Sprite2D.new()
			spr.texture = road if (x + y) % 2 == 0 and abs(x) < 2 else grass
			spr.scale = TILE_SCALE
			spr.position = Vector2((x - y) * 70.0, (x + y) * 35.0)
			spr.z_index = int(spr.position.y)
			_props.add_child(spr)

	_add_prop("tile_house.png", Vector2(-220, -40), PROP_SCALE)
	_add_prop("tile_church.png", Vector2(240, -80), PROP_SCALE)
	_add_prop("hub_station.png", Vector2(0, 160), HUB_SCALE)


func _add_prop(file_name: String, pos: Vector2, scale: Vector2) -> void:
	var path := ART + file_name
	if not ResourceLoader.exists(path):
		return
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.scale = scale
	spr.position = pos
	spr.z_index = int(pos.y)
	_props.add_child(spr)
