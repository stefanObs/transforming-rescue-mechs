extends Node2D
## Sandbox world: flat Style-C ground (no tiled 3D tile sprites) + landmark props.

const RoadKitLib := preload("res://scripts/road_kit.gd")
const ART := "res://assets/art/"
const PROP_SCALE := Vector2(0.26, 0.26)
const HUB_SCALE := Vector2(0.34, 0.34)
## Ground polygons sit at z ≈ −50…−34. Actors/props share one BASE so Y-sort works
## while staying above ground. Godot canvas z_index max is 4096.
const ACTOR_Z_BASE := 2000
const PROP_Z_BASE := 2000



static func compute_actor_z(y: float) -> int:
	return ACTOR_Z_BASE + int(y)


static func compute_prop_z(y: float) -> int:
	return PROP_Z_BASE + int(y)


const COLOR_SKY := Color("4DA3FF")
const COLOR_GRASS := Color("3DCC5A")
## Soft organic patches (not a checker tile pattern).
const COLOR_GRASS_PATCH := Color("36C053")
const COLOR_GRASS_PATCH_2 := Color("45D468")
const ROAD_HALF_W := 78.0

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
			_player.z_index = compute_actor_z(_player.global_position.y)



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

	# Continuous grass — Style-C cel ground (no diamond checker / 3D tile sprites).
	var base := Polygon2D.new()
	base.color = COLOR_GRASS
	base.z_index = -50
	base.polygon = PackedVector2Array([
		Vector2(-900, -500), Vector2(900, -500), Vector2(900, 700), Vector2(-900, 700),
	])
	_ground.add_child(base)

	# Large soft patches for organic feel (not a grid).
	_add_grass_patch(Vector2(-320, -40), 160.0, 110.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(280, 80), 140.0, 100.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(-80, 280), 180.0, 90.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(420, -180), 120.0, 130.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(-480, 200), 100.0, 140.0, COLOR_GRASS_PATCH, -48)

	_add_continuous_roads()


func _add_grass_patch(center: Vector2, rx: float, ry: float, color: Color, z: int) -> void:
	## Irregular ellipse-like blob (organic, not iso diamonds).
	var pts := PackedVector2Array()
	var n := 10
	for i in range(n):
		var t := TAU * float(i) / float(n)
		var jitter := 0.82 + 0.18 * sin(t * 3.0 + center.x * 0.01)
		pts.append(center + Vector2(cos(t) * rx * jitter, sin(t) * ry * jitter))
	var poly := Polygon2D.new()
	poly.color = color
	poly.z_index = z
	poly.polygon = pts
	_ground.add_child(poly)


func _add_continuous_roads() -> void:
	# Screen-axis RoadKit: vertical main, horizontal cross, one diagonal, roundabout.
	RoadKitLib.add_straight(_ground, Vector2(0, -350), Vector2(0, 400), {
		"sidewalk": true,
		"centerline": true,
		"half_w": ROAD_HALF_W,
	})

	RoadKitLib.add_straight(_ground, Vector2(-450, 80), Vector2(450, 80), {
		"sidewalk": true,
		"centerline": true,
		"half_w": ROAD_HALF_W * 0.85,
	})

	RoadKitLib.add_diagonal(_ground, Vector2(120, 120), Vector2(380, 320), {
		"centerline": true,
		"half_w": ROAD_HALF_W * 0.7,
	})

	# SW of spawn (0, 40) — clears the crossroads.
	RoadKitLib.add_roundabout(_ground, Vector2(-280, 280), 95.0, 30.0, {
		"sidewalk": true,
		"centerline": true,
	})


func _place_landmarks() -> void:
	for child in _props.get_children():
		child.queue_free()
	# Spaced landmark sprites on/near screen-axis roads.
	_add_prop("tile_house.png", Vector2(-140, -60), PROP_SCALE)
	_add_prop("tile_church.png", Vector2(260, 40), PROP_SCALE)
	_add_prop("hub_station.png", Vector2(40, 300), HUB_SCALE)


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
	spr.z_index = compute_prop_z(pos.y)
	_props.add_child(spr)
