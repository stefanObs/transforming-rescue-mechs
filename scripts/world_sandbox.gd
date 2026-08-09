extends Node2D
## Sandbox world: flat Style-C ground (no tiled 3D tile sprites) + landmark props.

const ART := "res://assets/art/"
const PROP_SCALE := Vector2(0.26, 0.26)
const HUB_SCALE := Vector2(0.34, 0.34)

const COLOR_SKY := Color("4DA3FF")
const COLOR_GRASS := Color("3DCC5A")
const COLOR_GRASS_ALT := Color("36C053")
const COLOR_ROAD := Color("6E6E6E")
const COLOR_ROAD_EDGE := Color("1A1A1A")

## Iso diamond half-size (flat top, NOT a 3D block sprite).
const TILE_HW := 56.0
const TILE_HH := 28.0

@onready var _player: CharacterBody2D = %Player
@onready var _hint: Label = %HintLabel
@onready var _status: Label = %StatusLabel
@onready var _props: Node2D = %Props
@onready var _ground: Node2D = %Ground
@onready var _sky: Polygon2D = %Sky

var _paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sky.color = COLOR_SKY
	_build_flat_ground()
	_place_landmarks()
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
		if _player:
			_player.z_index = 10 + int(_player.global_position.y)


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


func _build_flat_ground() -> void:
	for child in _ground.get_children():
		child.queue_free()

	# One continuous grass fill — Style-C cel ground (no tiled 3D block sprites).
	var base := Polygon2D.new()
	base.color = COLOR_GRASS
	base.z_index = -50
	base.polygon = PackedVector2Array([
		Vector2(-900, -500), Vector2(900, -500), Vector2(900, 700), Vector2(-900, 700),
	])
	_ground.add_child(base)

	# Soft checker accents with correct iso packing (edge-sharing diamonds).
	for y in range(-3, 5):
		for x in range(-5, 6):
			if (x + y) % 2 != 0:
				continue
			if _is_road_cell(x, y):
				continue
			var cx := (x - y) * TILE_HW
			var cy := (x + y) * TILE_HH
			_add_flat_iso_diamond(cx, cy, COLOR_GRASS_ALT, -45)

	_add_road_cells()
	_add_road_outline()


func _is_road_cell(x: int, y: int) -> bool:
	return abs(x) <= 1 or y == 2


func _iso_center(x: int, y: int) -> Vector2:
	return Vector2((x - y) * TILE_HW, (x + y) * TILE_HH)


func _add_flat_iso_diamond(cx: float, cy: float, color: Color, z: int) -> void:
	var poly := Polygon2D.new()
	poly.color = color
	poly.z_index = z
	poly.polygon = PackedVector2Array([
		Vector2(cx, cy - TILE_HH),
		Vector2(cx + TILE_HW, cy),
		Vector2(cx, cy + TILE_HH),
		Vector2(cx - TILE_HW, cy),
	])
	_ground.add_child(poly)


func _add_road_cells() -> void:
	for y in range(-3, 5):
		for x in range(-5, 6):
			if not _is_road_cell(x, y):
				continue
			var c := _iso_center(x, y)
			_add_flat_iso_diamond(c.x, c.y, COLOR_ROAD, -40)


func _add_road_outline() -> void:
	for y in range(-3, 5):
		for x in range(-5, 6):
			if not _is_road_cell(x, y):
				continue
			var c := _iso_center(x, y)
			var edge := Line2D.new()
			edge.width = 3.0
			edge.default_color = COLOR_ROAD_EDGE
			edge.z_index = -34
			edge.closed = true
			edge.points = PackedVector2Array([
				Vector2(c.x, c.y - TILE_HH),
				Vector2(c.x + TILE_HW, c.y),
				Vector2(c.x, c.y + TILE_HH),
				Vector2(c.x - TILE_HW, c.y),
			])
			_ground.add_child(edge)


func _place_landmarks() -> void:
	for child in _props.get_children():
		child.queue_free()
	# Spaced landmark sprites only — never used as repeating ground tiles.
	_add_prop("tile_house.png", Vector2(-280, 20), PROP_SCALE)
	_add_prop("tile_church.png", Vector2(300, -20), PROP_SCALE)
	_add_prop("hub_station.png", Vector2(40, 220), HUB_SCALE)


func _add_prop(file_name: String, pos: Vector2, scale: Vector2) -> void:
	var path := ART + file_name
	if not ResourceLoader.exists(path):
		return
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.scale = scale
	spr.position = pos
	spr.centered = true
	spr.offset = Vector2(0, -80)
	spr.z_index = 5 + int(pos.y)
	_props.add_child(spr)
