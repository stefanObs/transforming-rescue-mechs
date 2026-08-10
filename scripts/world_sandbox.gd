extends Node2D
## Sandbox world: flat Style-C ground (no tiled 3D tile sprites) + landmark props.
## M3: stilisierte Seuzach-Welt inkl. Ohringen-District.

const RoadKitLib := preload("res://scripts/road_kit.gd")
const ART := "res://assets/art/"
const HUB_SCENE := "res://scenes/hub_station.tscn"
const PROP_SCALE := Vector2(0.22, 0.22)
const LANDMARK_SCALE := Vector2(0.24, 0.24)
const HUB_SCALE := Vector2(0.28, 0.28)
const SCHOOL_SCALE := Vector2(0.22, 0.22)
## Ground polygons sit at z ≈ −50…−34. Actors/props share one BASE so Y-sort works
## while staying above ground. Godot canvas z_index max is 4096.
const ACTOR_Z_BASE := 2000
const PROP_Z_BASE := 2000
## Geo: +X east, +Y south; origin ≈ Reformierte Kirche. Hub at Tankstelle Forrenberg (A1).
## Enter/spawn south of hub + tankstelle BuildingCollision (capsule clear).
const HUB_ENTER_POS := Vector2(490, 760)
const DEFAULT_WORLD_SPAWN := Vector2(490, 750)
const COLOR_HILL := Color("4BB85A")
const COLOR_HILL_2 := Color("3FA050")
const COLOR_FOREST_FLOOR := Color("2F9A45")



static func compute_actor_z(y: float) -> int:
	## +1 so the player wins same-row draw ties against props (tree order alone is fragile).
	return ACTOR_Z_BASE + int(y) + 1


static func compute_prop_z(y: float) -> int:
	return PROP_Z_BASE + int(y)


## Texture-pixel Y offset so a centered sprite's bottom (feet) sits on the node origin.
static func feet_offset_y(texture: Texture2D) -> float:
	if texture == null:
		return -80.0
	return -float(texture.get_height()) * 0.5


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
var _hub_enter: Area2D = null
var _player_in_hub_enter: bool = false


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
	if GameState.has_world_spawn and _player:
		_player.global_position = GameState.consume_world_spawn()
	_sync_actor_z()
	_refresh_status()


func _sync_actor_z() -> void:
	if _player:
		_player.z_as_relative = false
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
	if _paused:
		return
	if _player_in_hub_enter and Input.is_action_just_pressed("interact"):
		enter_hub_for_test()
		return
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
	var hub_hint := ""
	if _player_in_hub_enter:
		hub_hint = " | %s — Erdstation betreten" % InputGlyphs.glyph_for("interact")
	_status.text = "M3 Seuzach+Ohringen | Hub Forrenberg | %s | Form: %s | Münzen: %d%s" % [
		char_id.capitalize(), form_name, GameState.coins, hub_hint
	]


func _build_flat_ground() -> void:
	for child in _ground.get_children():
		child.queue_free()

	# Continuous grass — Style-C cel ground (no diamond checker / 3D tile sprites).
	# Geo slice: Ohringen SW → Bahnhof E → Badi N → Forrenberg S.
	var base := Polygon2D.new()
	base.color = COLOR_GRASS
	base.z_index = -50
	base.polygon = PackedVector2Array([
		Vector2(-1500, -1000), Vector2(1500, -1000), Vector2(1500, 1200), Vector2(-1500, 1200),
	])
	_ground.add_child(base)

	# Soft patches for organic feel (not a grid).
	_add_grass_patch(Vector2(-320, -40), 160.0, 110.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(280, 80), 140.0, 100.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(80, 280), 180.0, 90.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(420, -180), 120.0, 130.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(-480, 200), 100.0, 140.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(-900, 400), 150.0, 120.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(900, -60), 130.0, 100.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(460, -520), 160.0, 110.0, COLOR_GRASS_PATCH_2, -48)
	_add_grass_patch(Vector2(490, 580), 140.0, 100.0, COLOR_GRASS_PATCH, -48)
	_add_grass_patch(Vector2(-700, -80), 120.0, 90.0, COLOR_GRASS_PATCH_2, -48)

	# Recognizable hills (Kirchhügel, Forrenberg, Erdbühl near Badi).
	_add_hill_mound(Vector2(0, -20), 210.0, 140.0, COLOR_HILL, -46)
	_add_hill_mound(Vector2(20, 10), 140.0, 90.0, COLOR_HILL_2, -45)
	_add_hill_mound(Vector2(490, 560), 260.0, 150.0, COLOR_HILL, -46)
	_add_hill_mound(Vector2(430, -580), 180.0, 110.0, COLOR_HILL_2, -46)

	# Forest floors (Buechewäldli SE, Ohringen belt, north fringe, Weiherholz S of A1).
	_add_grass_patch(Vector2(520, 380), 220.0, 160.0, COLOR_FOREST_FLOOR, -47)
	_add_grass_patch(Vector2(-500, 280), 200.0, 140.0, COLOR_FOREST_FLOOR, -47)
	_add_grass_patch(Vector2(200, -720), 180.0, 120.0, COLOR_FOREST_FLOOR, -47)
	_add_grass_patch(Vector2(400, 920), 320.0, 180.0, COLOR_FOREST_FLOOR, -47)
	_add_grass_patch(Vector2(800, 900), 260.0, 160.0, COLOR_FOREST_FLOOR, -47)
	_add_grass_patch(Vector2(100, 950), 240.0, 140.0, COLOR_FOREST_FLOOR, -47)

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


func _add_hill_mound(center: Vector2, rx: float, ry: float, color: Color, z: int) -> void:
	_add_grass_patch(center, rx, ry, color, z)
	var marker := Node2D.new()
	marker.name = "Hill_%d_%d" % [int(center.x), int(center.y)]
	marker.position = center
	marker.set_meta("terrain", "hill")
	_ground.add_child(marker)


func _add_continuous_roads() -> void:
	# Maps/OSM-aligned Seuzach network (stilisiert). Named markers for tests.
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
	var lane_opts := {
		"sidewalk": true,
		"centerline": false,
		"half_w": ROAD_HALF_W * 0.72,
	}
	var a1_opts := {
		"sidewalk": false,
		"centerline": true,
		"half_w": ROAD_HALF_W * 1.25,
	}

	# Winterthurerstrasse — primary N–S on the west side (Maps).
	_add_named_road(
		"Winterthurerstrasse",
		Vector2(-140, -720),
		Vector2(-80, 720),
		main_opts
	)

	# Landstrasse — central N–S through Dorfkern toward Badi/Halden (Maps).
	_add_named_road(
		"Landstrasse",
		Vector2(160, -720),
		Vector2(200, 620),
		main_opts
	)

	# Ohringerstrasse — E–W toward Ohringen (west) and kern (Maps secondary).
	_add_named_road(
		"Ohringerstrasse",
		Vector2(-1050, 40),
		Vector2(420, -60),
		main_opts
	)

	# Stationsstrasse — toward Bahnhof (east).
	_add_named_road(
		"Stationsstrasse",
		Vector2(220, -80),
		Vector2(980, -120),
		branch_opts
	)

	# Kirchgasse — stub to Kirchhügel.
	_add_named_road(
		"Kirchgasse",
		Vector2(160, -20),
		Vector2(-40, 20),
		lane_opts
	)

	# Strehlgasse — toward Feuerwehr / Gemeindehaus (N).
	_add_named_road(
		"Strehlgasse",
		Vector2(180, -180),
		Vector2(280, -380),
		lane_opts
	)

	# Bachwiesenstrasse — Birch school area (E).
	_add_named_road(
		"Bachwiesenstrasse",
		Vector2(220, -100),
		Vector2(760, -200),
		lane_opts
	)

	# Weiherstrasse / Landstrasse spur — Badi Weiher (N).
	_add_named_road(
		"Weiherstrasse",
		Vector2(200, -240),
		Vector2(460, -560),
		branch_opts
	)

	# Welsikonerstrasse — NE residential connector.
	_add_named_road(
		"Welsikonerstrasse",
		Vector2(200, -300),
		Vector2(520, -420),
		lane_opts
	)

	# Breitestrasse — short E–W residential in kern.
	_add_named_road(
		"Breitestrasse",
		Vector2(-40, 120),
		Vector2(360, 100),
		lane_opts
	)

	# Reutlingerstrasse / Forrenbergstrasse — SE toward St. Martin + Forrenberg/A1.
	_add_named_road(
		"Reutlingerstrasse",
		Vector2(200, 80),
		Vector2(520, 380),
		branch_opts
	)
	_add_named_road(
		"Forrenbergstrasse",
		Vector2(420, 380),
		Vector2(490, 600),
		branch_opts
	)

	# Schulstrasse — Ohringen school access.
	_add_named_road(
		"Schulstrasse",
		Vector2(-980, 380),
		Vector2(-820, 700),
		lane_opts
	)

	# A1 motorway strip south of Forrenberg.
	_add_named_road(
		"A1",
		Vector2(-200, 800),
		Vector2(1100, 800),
		a1_opts
	)

	# Roundabout near Landstrasse / Badi approach (stilisiert).
	RoadKitLib.add_roundabout(_ground, Vector2(280, -280), 130.0, ROAD_HALF_W, {
		"sidewalk": true,
	})
	_add_road_marker("Kreisel_Landstrasse", Vector2(280, -280))


func _add_named_road(road_name: String, a: Vector2, b: Vector2, opts: Dictionary) -> void:
	RoadKitLib.add_straight(_ground, a, b, opts)
	_add_road_marker(road_name, (a + b) * 0.5)


func _add_road_marker(road_name: String, pos: Vector2) -> void:
	var marker := Node2D.new()
	marker.name = "Road_%s" % road_name.replace(" ", "_")
	marker.position = pos
	marker.set_meta("road_name", road_name)
	_ground.add_child(marker)


func _place_landmarks() -> void:
	for child in _props.get_children():
		child.queue_free()
	_prop_parent = _props

	# --- Forrenberg: Hub + Tankstelle (Basisstation) ---
	_add_prop(
		"hub_station.png",
		Vector2(490, 600),
		HUB_SCALE,
		{"landmark_id": "hub_station", "district": "forrenberg"},
		"hub_station"
	)
	_add_hub_enter_zone()
	_add_prop(
		"landmark_tankstelle_seuzach.png",
		Vector2(780, 680),
		LANDMARK_SCALE,
		{"landmark_id": "tankstelle", "district": "forrenberg", "poi_type": "fuel"},
		"landmark_tankstelle"
	)
	# Sportanlage Rolli — north of A1 / near Forrenberg (Maps); kept clear of hub footprint.
	_add_prop(
		"landmark_sportplatz.png",
		Vector2(300, 420),
		LANDMARK_SCALE,
		{"landmark_id": "sportplatz_rolli", "district": "forrenberg", "poi_type": "sport"},
		"landmark_sportplatz_rolli"
	)

	# --- Dorfkern / Kirchhügel ---
	var church := _add_prop(
		"landmark_kirche_seuzach.png",
		Vector2(0, 0),
		PROP_SCALE,
		{"landmark_id": "kirche_seuzach", "district": "dorfkern", "on_hill": true},
		"landmark_kirche_seuzach"
	)
	if church == null:
		_add_prop(
			"tile_church.png",
			Vector2(0, 0),
			PROP_SCALE,
			{"landmark_id": "kirche_seuzach", "district": "dorfkern", "on_hill": true},
			"landmark_kirche_seuzach"
		)
	_add_prop(
		"landmark_gemeindehaus_seuzach.png",
		Vector2(230, -320),
		LANDMARK_SCALE,
		{"landmark_id": "gemeindehaus", "district": "dorfkern"},
		"landmark_gemeindehaus"
	)
	_add_prop(
		"landmark_feuerwehr_seuzach.png",
		Vector2(260, -360),
		LANDMARK_SCALE,
		{"landmark_id": "feuerwehr", "district": "feuerwehr"},
		"landmark_feuerwehr"
	)
	_add_prop(
		"landmark_restaurant_a.png",
		Vector2(120, 80),
		PROP_SCALE,
		{"landmark_id": "restaurant_a", "poi_type": "restaurant", "district": "dorfkern"},
		"landmark_restaurant_a"
	)
	_add_prop(
		"landmark_laden_a.png",
		Vector2(-120, 60),
		PROP_SCALE,
		{"landmark_id": "laden_a", "poi_type": "shop", "district": "dorfkern"},
		"landmark_laden_a"
	)
	_add_prop(
		"landmark_laden_b.png",
		Vector2(100, -60),
		PROP_SCALE,
		{"landmark_id": "laden_b", "poi_type": "shop", "district": "dorfkern"},
		"landmark_laden_b"
	)

	# St. Martin (modern) SE of Kirchhügel near Buechewäldli — not a fake Ohringen church.
	var st_martin := _add_prop(
		"landmark_kirche_st_martin.png",
		Vector2(420, 320),
		PROP_SCALE,
		{"landmark_id": "kirche_st_martin", "district": "dorfkern"},
		"landmark_kirche_st_martin"
	)
	if st_martin == null:
		_add_prop(
			"landmark_kirche_ohringen.png",
			Vector2(420, 320),
			PROP_SCALE,
			{"landmark_id": "kirche_st_martin", "district": "dorfkern"},
			"landmark_kirche_st_martin"
		)

	# --- Bahnhof (east) ---
	_add_prop(
		"landmark_bahnhof_seuzach.png",
		Vector2(890, -130),
		LANDMARK_SCALE,
		{"landmark_id": "bahnhof", "district": "bahnhof"},
		"landmark_bahnhof"
	)
	_add_prop(
		"landmark_laden_c.png",
		Vector2(780, -40),
		PROP_SCALE,
		{"landmark_id": "laden_c", "poi_type": "shop", "district": "bahnhof"},
		"landmark_laden_c"
	)
	_add_prop(
		"landmark_restaurant_b.png",
		Vector2(820, 40),
		PROP_SCALE,
		{"landmark_id": "restaurant_b", "poi_type": "restaurant", "district": "bahnhof"},
		"landmark_restaurant_b"
	)

	# --- Badi Weiher (north) + Sport ---
	_add_prop(
		"landmark_badi_weiher.png",
		Vector2(460, -550),
		LANDMARK_SCALE,
		{"landmark_id": "badi_weiher", "district": "badi"},
		"landmark_badi_weiher"
	)
	_add_prop(
		"landmark_sportplatz.png",
		Vector2(560, -640),
		LANDMARK_SCALE,
		{"landmark_id": "sportplatz", "district": "badi", "poi_type": "sport"},
		"landmark_sportplatz"
	)
	_add_prop(
		"landmark_spielplatz.png",
		Vector2(400, -480),
		PROP_SCALE,
		{"landmark_id": "spielplatz_badi", "district": "badi", "poi_type": "playground"},
		"landmark_spielplatz_badi"
	)

	# --- Kindergärten (OSM-nahe) ---
	_add_prop(
		"landmark_kiga_bachtobel.png",
		Vector2(760, -380),
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
		Vector2(750, 40),
		PROP_SCALE,
		{
			"landmark_id": "kiga_weid",
			"kindergarten_id": "kiga_weid",
			"district": "bahnhof",
		},
		"landmark_kiga_weid"
	)
	_add_prop(
		"landmark_kiga_schneckenwiese.png",
		Vector2(310, -100),
		PROP_SCALE,
		{
			"landmark_id": "kiga_schneckenwiese",
			"kindergarten_id": "kiga_schneckenwiese",
			"district": "rietacker",
		},
		"landmark_kiga_schneckenwiese"
	)
	_add_prop(
		"landmark_spielplatz.png",
		Vector2(280, -40),
		PROP_SCALE,
		{"landmark_id": "spielplatz_schneckenwiese", "district": "rietacker", "poi_type": "playground"},
		"landmark_spielplatz_schneckenwiese"
	)

	# --- Schule Birch (east, near Bahnhof) — spaced so facades do not stack ---
	_add_prop(
		"landmark_schulhaus_birch_a.png",
		Vector2(520, -240),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_birch", "school_cluster": "birch", "district": "birch"},
		"schulhaus_birch_a"
	)
	_add_prop(
		"landmark_schulhaus_birch_b.png",
		Vector2(780, -120),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_birch", "school_cluster": "birch", "district": "birch"},
		"schulhaus_birch_b"
	)
	_add_prop(
		"landmark_turnhalle_birch.png",
		Vector2(650, 40),
		SCHOOL_SCALE,
		{"landmark_id": "turnhalle_birch", "school_cluster": "birch", "district": "birch", "poi_type": "gym"},
		"turnhalle_birch"
	)

	# --- Schule Rietacker + Sporthalle (north of Kirchhügel) ---
	_add_prop(
		"landmark_schulhaus_rietacker_a.png",
		Vector2(-100, -320),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_rietacker", "school_cluster": "rietacker", "district": "rietacker"},
		"schulhaus_rietacker_a"
	)
	_add_prop(
		"landmark_schulhaus_rietacker_b.png",
		Vector2(200, -200),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_rietacker", "school_cluster": "rietacker", "district": "rietacker"},
		"schulhaus_rietacker_b"
	)
	_add_prop(
		"landmark_turnhalle_rietacker.png",
		Vector2(40, -80),
		SCHOOL_SCALE,
		{
			"landmark_id": "turnhalle_rietacker",
			"school_cluster": "rietacker",
			"district": "rietacker",
			"poi_type": "gym",
		},
		"turnhalle_rietacker"
	)

	# --- Forests ---
	_add_prop(
		"landmark_wald_a.png",
		Vector2(520, 380),
		LANDMARK_SCALE,
		{"landmark_id": "wald_buechewaeldli", "district": "dorfkern", "terrain": "forest"},
		"wald_buechewaeldli"
	)
	_add_prop(
		"landmark_wald_b.png",
		Vector2(-480, 260),
		LANDMARK_SCALE,
		{"landmark_id": "wald_ohringen_belt", "district": "ohringen", "terrain": "forest"},
		"wald_ohringen_belt"
	)
	_add_prop(
		"landmark_wald_a.png",
		Vector2(180, -720),
		LANDMARK_SCALE,
		{"landmark_id": "wald_nord", "district": "badi", "terrain": "forest"},
		"wald_nord"
	)
	_add_prop(
		"landmark_wald_b.png",
		Vector2(450, 920),
		LANDMARK_SCALE,
		{"landmark_id": "wald_weiherholz", "district": "forrenberg", "terrain": "forest"},
		"wald_weiherholz"
	)
	_add_prop(
		"landmark_wald_a.png",
		Vector2(780, 900),
		LANDMARK_SCALE,
		{"landmark_id": "wald_eggenzahn", "district": "forrenberg", "terrain": "forest"},
		"wald_eggenzahn"
	)

	# --- Ohringen district (south-west) ---
	var ohringen := Node2D.new()
	ohringen.name = "DistrictOhringen"
	ohringen.set_meta("district", "ohringen")
	ohringen.position = Vector2.ZERO
	_props.add_child(ohringen)
	_prop_parent = ohringen

	_add_prop(
		"landmark_schulhaus_ohringen_a.png",
		Vector2(-1040, 400),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_ohringen", "school_cluster": "ohringen", "district": "ohringen"},
		"schulhaus_ohringen_a"
	)
	_add_prop(
		"landmark_schulhaus_ohringen_b.png",
		Vector2(-740, 580),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_ohringen", "school_cluster": "ohringen", "district": "ohringen"},
		"schulhaus_ohringen_b"
	)
	_add_prop(
		"landmark_turnhalle_ohringen.png",
		Vector2(-900, 720),
		SCHOOL_SCALE,
		{
			"landmark_id": "turnhalle_ohringen",
			"school_cluster": "ohringen",
			"district": "ohringen",
			"poi_type": "gym",
		},
		"turnhalle_ohringen"
	)
	_add_prop(
		"landmark_kiga_ohringen.png",
		Vector2(-920, 360),
		PROP_SCALE,
		{
			"landmark_id": "kiga_ohringen",
			"kindergarten_id": "kiga_ohringen",
			"district": "ohringen",
		},
		"landmark_kiga_ohringen"
	)
	_add_prop(
		"landmark_spielplatz.png",
		Vector2(-740, 500),
		PROP_SCALE,
		{"landmark_id": "spielplatz_ohringen", "district": "ohringen", "poi_type": "playground"},
		"landmark_spielplatz_ohringen"
	)

	_prop_parent = _props
	_place_housing_blocks()


func _place_housing_blocks() -> void:
	## Realistic mix: EFH (a–d), farm, MFH, Flachdach, Reihen — denser along Maps streets.
	## Keep spacing ≥~120 so Y-sort / occlusion stay readable.
	var kern := [
		["house_a.png", Vector2(-220, -120), "a", "gabled"],
		["house_b.png", Vector2(-40, 160), "b", "gabled"],
		["house_c.png", Vector2(320, 180), "c", "gabled"],
		["house_d.png", Vector2(40, 240), "d", "gabled"],
		["house_reihen.png", Vector2(-280, 200), "reihen", "gabled"],
		["house_reihen.png", Vector2(380, 80), "reihen", "gabled"],
		["house_flachdach.png", Vector2(280, -140), "flachdach", "flat"],
		["house_mfh.png", Vector2(-100, 280), "mfh", "gabled"],
		["house_a.png", Vector2(420, 200), "a", "gabled"],
		["house_flachdach.png", Vector2(-320, 40), "flachdach", "flat"],
	]
	for item in kern:
		_add_house(str(item[0]), item[1] as Vector2, str(item[2]), str(item[3]), "dorfkern")

	# Bahnhof / Stationsstrasse — more MFH + Flachdach (Maps denser east).
	var bahnhof := [
		["house_mfh.png", Vector2(720, -200), "mfh", "gabled"],
		["house_mfh.png", Vector2(980, -40), "mfh", "gabled"],
		["house_flachdach.png", Vector2(840, 80), "flachdach", "flat"],
		["house_reihen.png", Vector2(640, 40), "reihen", "gabled"],
		["house_b.png", Vector2(1080, -160), "b", "gabled"],
		["house_flachdach.png", Vector2(920, -220), "flachdach", "flat"],
	]
	for item in bahnhof:
		_add_house(str(item[0]), item[1] as Vector2, str(item[2]), str(item[3]), "bahnhof")

	# Birch / Bachwiesen — EFH + Reihen.
	var birch := [
		["house_reihen.png", Vector2(480, -80), "reihen", "gabled"],
		["house_a.png", Vector2(880, -280), "a", "gabled"],
		["house_c.png", Vector2(400, -200), "c", "gabled"],
		["house_flachdach.png", Vector2(900, -80), "flachdach", "flat"],
	]
	for item in birch:
		_add_house(str(item[0]), item[1] as Vector2, str(item[2]), str(item[3]), "birch")

	# Süd / Reutlinger–Forrenberg — Flachdach + EFH toward A1.
	var sued := [
		["house_flachdach.png", Vector2(300, 280), "flachdach", "flat"],
		["house_flachdach.png", Vector2(600, 500), "flachdach", "flat"],
		["house_d.png", Vector2(140, 360), "d", "gabled"],
		["house_reihen.png", Vector2(360, 440), "reihen", "gabled"],
		["house_mfh.png", Vector2(680, 360), "mfh", "gabled"],
	]
	for item in sued:
		_add_house(str(item[0]), item[1] as Vector2, str(item[2]), str(item[3]), "forrenberg")

	# Ohringen / Unterohringen — farm + EFH + some Reihen/MFH.
	var ohringen: Node2D = _props.get_node_or_null("DistrictOhringen") as Node2D
	var prev: Node2D = _prop_parent
	if ohringen:
		_prop_parent = ohringen
	var ohr := [
		["house_farm.png", Vector2(-1100, 300), "farm", "gabled"],
		["house_a.png", Vector2(-760, -40), "a", "gabled"],
		["house_b.png", Vector2(-640, 360), "b", "gabled"],
		["house_c.png", Vector2(-1120, 520), "c", "gabled"],
		["house_reihen.png", Vector2(-680, 640), "reihen", "gabled"],
		["house_flachdach.png", Vector2(-960, 240), "flachdach", "flat"],
		["house_mfh.png", Vector2(-560, 500), "mfh", "gabled"],
		["house_d.png", Vector2(-820, 280), "d", "gabled"],
	]
	for item in ohr:
		_add_house(str(item[0]), item[1] as Vector2, str(item[2]), str(item[3]), "ohringen")
	_prop_parent = prev if prev != null else _props


func _add_house(
	file_name: String,
	pos: Vector2,
	variant: String,
	roof_type: String,
	district: String
) -> void:
	var metas := {
		"house_variant": variant,
		"roof_type": roof_type,
		"district": district,
	}
	var node_name := "house_%s_%d_%d" % [variant, int(pos.x), int(pos.y)]
	_add_prop(file_name, pos, PROP_SCALE, metas, node_name)


func _add_hub_enter_zone() -> void:
	var area := Area2D.new()
	area.name = "HubEnter"
	area.position = HUB_ENTER_POS
	area.collision_layer = 1
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = true
	area.set_meta("hub_enter", true)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(120, 70)
	var col := CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_hub_enter_body_entered)
	area.body_exited.connect(_on_hub_enter_body_exited)
	var parent: Node2D = _prop_parent if _prop_parent != null else _props
	parent.add_child(area)
	_hub_enter = area


func _on_hub_enter_body_entered(body: Node) -> void:
	if body == _player:
		_player_in_hub_enter = true
		_refresh_status()


func _on_hub_enter_body_exited(body: Node) -> void:
	if body == _player:
		_player_in_hub_enter = false
		_refresh_status()


## Headless-friendly: save spawn and switch to hub scene.
func enter_hub_for_test() -> void:
	var spawn := DEFAULT_WORLD_SPAWN
	if _player:
		spawn = _player.global_position
	GameState.set_world_spawn(spawn)
	get_tree().change_scene_to_file(HUB_SCENE)


func is_player_in_hub_enter_for_test() -> bool:
	return _player_in_hub_enter


func get_hub_enter_for_test() -> Area2D:
	return _hub_enter


func _attach_building_collision(spr: Sprite2D, is_hub: bool = false) -> void:
	if spr.texture == null:
		return
	var tex_w := float(spr.texture.get_width()) * absf(spr.scale.x)
	var tex_h := float(spr.texture.get_height()) * absf(spr.scale.y)
	# Hub footprint kept tighter so enter zone south of the building stays walkable.
	var footprint_w := tex_w * (0.28 if is_hub else 0.45)
	var footprint_h := tex_h * (0.12 if is_hub else 0.22)
	var body := StaticBody2D.new()
	body.name = "BuildingCollision"
	body.collision_layer = 1
	body.collision_mask = 1
	body.set_meta("has_building_collision", true)
	# Feet pivot is at sprite origin; keep a shallow footprint just above the ground line.
	var feet_y := -footprint_h * (0.35 if is_hub else 0.25)
	body.position = Vector2(0, feet_y)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(maxf(24.0, footprint_w), maxf(16.0, footprint_h))
	var col := CollisionShape2D.new()
	col.shape = rect
	body.add_child(col)
	spr.add_child(body)
	spr.set_meta("has_building_collision", true)


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
	# Feet on origin so Y-sort matches visual front/back (no south-hanging facade).
	spr.offset = Vector2(0.0, feet_offset_y(spr.texture))
	spr.z_as_relative = false
	spr.z_index = compute_prop_z(pos.y)
	for key in metas.keys():
		spr.set_meta(str(key), metas[key])
	var parent: Node2D = _prop_parent if _prop_parent != null else _props
	parent.add_child(spr)
	var is_hub := node_name == "hub_station" or str(metas.get("landmark_id", "")) == "hub_station"
	_attach_building_collision(spr, is_hub)
	return spr
