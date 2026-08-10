extends Node2D
## Sandbox world: flat Style-C ground (no tiled 3D tile sprites) + landmark props.
## M3: stilisierte Seuzach-Welt inkl. Ohringen-District.

const RoadKitLib := preload("res://scripts/road_kit.gd")
const ART := "res://assets/art/"
const PROP_SCALE := Vector2(0.26, 0.26)
const LANDMARK_SCALE := Vector2(0.30, 0.30)
const HUB_SCALE := Vector2(0.34, 0.34)
const SCHOOL_SCALE := Vector2(0.28, 0.28)
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
var _prop_parent: Node2D = null


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
	_sync_actor_z()
	_refresh_status()


func _sync_actor_z() -> void:
	if _player:
		_player.z_index = compute_actor_z(_player.global_position.y)


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
	_status.text = "M3 Seuzach | %s | Form: %s | Münzen: %d" % [char_id.capitalize(), form_name, GameState.coins]


func _build_flat_ground() -> void:
	for child in _ground.get_children():
		child.queue_free()

	# Continuous grass — Style-C cel ground (no diamond checker / 3D tile sprites).
	# Roughly x∈[-1400,1400], y∈[-900,1100].
	var base := Polygon2D.new()
	base.color = COLOR_GRASS
	base.z_index = -50
	base.polygon = PackedVector2Array([
		Vector2(-1400, -900), Vector2(1400, -900), Vector2(1400, 1100), Vector2(-1400, 1100),
	])
	_ground.add_child(base)

	# Large soft patches for organic feel (not a grid).
	_add_grass_patch(Vector2(-320, -40), 160.0, 110.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(280, 80), 140.0, 100.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(-80, 280), 180.0, 90.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(420, -180), 120.0, 130.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(-480, 200), 100.0, 140.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(-900, -400), 150.0, 120.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(900, 60), 130.0, 100.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(500, 700), 160.0, 110.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(-200, -520), 140.0, 100.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(400, -450), 120.0, 90.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(-700, 220), 110.0, 100.0, COLOR_GRASS_PATCH, -48)

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
	# Connected Seuzach network (screen-axis). Sidewalk+centerline on main straights only.
	var main_opts := {
		"sidewalk": true,
		"centerline": true,
		"half_w": ROAD_HALF_W,
	}
	var branch_opts := {
		"sidewalk": true,
		"centerline": false,
		"half_w": ROAD_HALF_W * 0.85,
	}

	# Main N–S through Dorfkern (Birch north → Badi south).
	RoadKitLib.add_straight(_ground, Vector2(0, -650), Vector2(0, 900), main_opts)

	# Main E–W: Feuerwehr west ↔ Bahnhof east.
	RoadKitLib.add_straight(_ground, Vector2(-900, 120), Vector2(1050, 120), main_opts)

	# Spur south to Feuerwehr landmark.
	RoadKitLib.add_straight(_ground, Vector2(-700, 120), Vector2(-700, 260), branch_opts)

	# Road north-east to Schule Rietacker.
	RoadKitLib.add_straight(_ground, Vector2(0, -450), Vector2(450, -450), branch_opts)

	# Road north-west toward Ohringen.
	RoadKitLib.add_straight(_ground, Vector2(0, -280), Vector2(-900, -350), branch_opts)

	# Road south-east toward Badi Weiher.
	RoadKitLib.add_diagonal(_ground, Vector2(0, 520), Vector2(520, 720), branch_opts)

	# Roundabout SW of kern — clears N–S (x=0) and E–W (y=120); no centerline.
	RoadKitLib.add_roundabout(_ground, Vector2(-520, 380), 160.0, ROAD_HALF_W, {
		"sidewalk": true,
	})
	# Short connector from E–W into roundabout approach.
	RoadKitLib.add_straight(_ground, Vector2(-520, 120), Vector2(-520, 220), branch_opts)


func _place_landmarks() -> void:
	for child in _props.get_children():
		child.queue_free()
	_prop_parent = _props

	# --- Dorfkern ---
	_add_prop(
		"hub_station.png",
		Vector2(40, 300),
		HUB_SCALE,
		{"landmark_id": "hub_station", "district": "dorfkern"},
		"hub_station"
	)
	var church := _add_prop(
		"landmark_kirche_seuzach.png",
		Vector2(220, -40),
		PROP_SCALE,
		{"landmark_id": "kirche_seuzach", "district": "dorfkern"},
		"landmark_kirche_seuzach"
	)
	if church == null:
		_add_prop(
			"tile_church.png",
			Vector2(220, -40),
			PROP_SCALE,
			{"landmark_id": "kirche_seuzach", "district": "dorfkern"},
			"landmark_kirche_seuzach"
		)
	_add_prop(
		"landmark_gemeindehaus_seuzach.png",
		Vector2(-80, 40),
		LANDMARK_SCALE,
		{"landmark_id": "gemeindehaus", "district": "dorfkern"},
		"landmark_gemeindehaus"
	)
	_add_prop(
		"landmark_restaurant_a.png",
		Vector2(120, 200),
		PROP_SCALE,
		{"landmark_id": "restaurant_a", "poi_type": "restaurant", "district": "dorfkern"},
		"landmark_restaurant_a"
	)
	_add_prop(
		"landmark_laden_a.png",
		Vector2(-200, 100),
		PROP_SCALE,
		{"landmark_id": "laden_a", "poi_type": "shop", "district": "dorfkern"},
		"landmark_laden_a"
	)
	_add_prop(
		"landmark_laden_b.png",
		Vector2(60, 60),
		PROP_SCALE,
		{"landmark_id": "laden_b", "poi_type": "shop", "district": "dorfkern"},
		"landmark_laden_b"
	)
	_add_prop(
		"house_a.png",
		Vector2(-140, -60),
		PROP_SCALE,
		{"house_variant": "a", "district": "dorfkern"},
		"house_kern_a"
	)
	_add_prop(
		"house_b.png",
		Vector2(160, 80),
		PROP_SCALE,
		{"house_variant": "b", "district": "dorfkern"},
		"house_kern_b"
	)
	_add_prop(
		"house_c.png",
		Vector2(-100, 160),
		PROP_SCALE,
		{"house_variant": "c", "district": "dorfkern"},
		"house_kern_c"
	)
	_add_prop(
		"house_d.png",
		Vector2(280, 180),
		PROP_SCALE,
		{"house_variant": "d", "district": "dorfkern"},
		"house_kern_d"
	)

	# --- Bahnhof (east) ---
	_add_prop(
		"landmark_bahnhof_seuzach.png",
		Vector2(900, 80),
		LANDMARK_SCALE,
		{"landmark_id": "bahnhof", "district": "bahnhof"},
		"landmark_bahnhof"
	)
	_add_prop(
		"landmark_laden_c.png",
		Vector2(780, 40),
		PROP_SCALE,
		{"landmark_id": "laden_c", "poi_type": "shop", "district": "bahnhof"},
		"landmark_laden_c"
	)
	_add_prop(
		"landmark_tankstelle_seuzach.png",
		Vector2(650, 200),
		LANDMARK_SCALE,
		{"landmark_id": "tankstelle", "district": "bahnhof"},
		"landmark_tankstelle"
	)

	# --- Feuerwehr (west-south) ---
	_add_prop(
		"landmark_feuerwehr_seuzach.png",
		Vector2(-700, 200),
		LANDMARK_SCALE,
		{"landmark_id": "feuerwehr", "district": "feuerwehr"},
		"landmark_feuerwehr"
	)
	_add_prop(
		"landmark_restaurant_b.png",
		Vector2(-600, 80),
		PROP_SCALE,
		{"landmark_id": "restaurant_b", "poi_type": "restaurant", "district": "feuerwehr"},
		"landmark_restaurant_b"
	)

	# --- Badi Weiher (south-east) ---
	_add_prop(
		"landmark_badi_weiher.png",
		Vector2(500, 700),
		LANDMARK_SCALE,
		{"landmark_id": "badi_weiher", "district": "badi"},
		"landmark_badi_weiher"
	)

	# --- Kindergärten ---
	_add_prop(
		"landmark_kiga_bachtobel.png",
		Vector2(-400, -200),
		PROP_SCALE,
		{
			"landmark_id": "kiga_bachtobel",
			"kindergarten_id": "kiga_bachtobel",
			"district": "birch",
		},
		"landmark_kiga_bachtobel"
	)
	_add_prop(
		"landmark_kiga_weid.png",
		Vector2(100, -280),
		PROP_SCALE,
		{
			"landmark_id": "kiga_weid",
			"kindergarten_id": "kiga_weid",
			"district": "dorfkern",
		},
		"landmark_kiga_weid"
	)
	_add_prop(
		"landmark_kiga_schneckenwiese.png",
		Vector2(550, -200),
		PROP_SCALE,
		{
			"landmark_id": "kiga_schneckenwiese",
			"kindergarten_id": "kiga_schneckenwiese",
			"district": "rietacker",
		},
		"landmark_kiga_schneckenwiese"
	)

	# --- Schule Birch (north cluster) ---
	_add_prop(
		"landmark_schulhaus_birch_a.png",
		Vector2(-240, -500),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_birch", "school_cluster": "birch", "district": "birch"},
		"schulhaus_birch_a"
	)
	_add_prop(
		"landmark_schulhaus_birch_b.png",
		Vector2(-140, -520),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_birch", "school_cluster": "birch", "district": "birch"},
		"schulhaus_birch_b"
	)

	# --- Schule Rietacker (north-east cluster) ---
	_add_prop(
		"landmark_schulhaus_rietacker_a.png",
		Vector2(360, -440),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_rietacker", "school_cluster": "rietacker", "district": "rietacker"},
		"schulhaus_rietacker_a"
	)
	_add_prop(
		"landmark_schulhaus_rietacker_b.png",
		Vector2(460, -460),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_rietacker", "school_cluster": "rietacker", "district": "rietacker"},
		"schulhaus_rietacker_b"
	)

	# --- Ohringen district (north-west) ---
	var ohringen := Node2D.new()
	ohringen.name = "DistrictOhringen"
	ohringen.set_meta("district", "ohringen")
	ohringen.position = Vector2.ZERO
	_props.add_child(ohringen)
	_prop_parent = ohringen

	_add_prop(
		"landmark_schulhaus_ohringen_a.png",
		Vector2(-940, -360),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_ohringen", "school_cluster": "ohringen", "district": "ohringen"},
		"schulhaus_ohringen_a"
	)
	_add_prop(
		"landmark_schulhaus_ohringen_b.png",
		Vector2(-840, -340),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_ohringen", "school_cluster": "ohringen", "district": "ohringen"},
		"schulhaus_ohringen_b"
	)
	_add_prop(
		"landmark_kiga_ohringen.png",
		Vector2(-1000, -280),
		PROP_SCALE,
		{
			"landmark_id": "kiga_ohringen",
			"kindergarten_id": "kiga_ohringen",
			"district": "ohringen",
		},
		"landmark_kiga_ohringen"
	)
	_add_prop(
		"landmark_kirche_ohringen.png",
		Vector2(-820, -280),
		PROP_SCALE,
		{"landmark_id": "kirche_ohringen", "district": "ohringen"},
		"landmark_kirche_ohringen"
	)
	_add_prop(
		"house_a.png",
		Vector2(-1100, -220),
		PROP_SCALE,
		{"house_variant": "a", "district": "ohringen"},
		"house_ohringen_a"
	)
	_add_prop(
		"house_b.png",
		Vector2(-720, -320),
		PROP_SCALE,
		{"house_variant": "b", "district": "ohringen"},
		"house_ohringen_b"
	)
	_add_prop(
		"house_c.png",
		Vector2(-880, -220),
		PROP_SCALE,
		{"house_variant": "c", "district": "ohringen"},
		"house_ohringen_c"
	)
	_add_prop(
		"house_farm.png",
		Vector2(-1040, -400),
		PROP_SCALE,
		{"house_variant": "farm", "district": "ohringen"},
		"house_ohringen_farm"
	)

	_prop_parent = _props


func _add_prop(
	file_name: String,
	pos: Vector2,
	scale: Vector2,
	metas: Dictionary = {},
	node_name: String = ""
) -> Sprite2D:
	var path := ART + file_name
	if not ResourceLoader.exists(path):
		return null
	var spr := Sprite2D.new()
	if node_name != "":
		spr.name = node_name
	spr.texture = load(path)
	spr.scale = scale
	spr.position = pos
	spr.centered = true
	spr.offset = Vector2(0, -80)
	spr.z_index = compute_prop_z(pos.y)
	for key in metas.keys():
		spr.set_meta(str(key), metas[key])
	var parent: Node2D = _prop_parent if _prop_parent != null else _props
	parent.add_child(spr)
	return spr
