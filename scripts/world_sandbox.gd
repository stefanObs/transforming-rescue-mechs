extends Node2D
## Sandbox world: street map (grass + RoadKit) + school clusters for orientation.
## M3: Seuzach+Ohringen OSM-Netz auf 5,3 m/Feld; HubEnter unsichtbar am Forrenberg.

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
## Geo: +X east, +Y south; origin ≈ Reformierte Kirche. 1 Feld = 5,3 m = 100 wu.
## HubEnter: SOCAR Forrenberg (A1), etwas südlich der Tankstelle.
## Default-Spawn: Winterthurerstrasse in WINT-KERN (Dorfkern, Kirche-Ost).
var HUB_ENTER_POS: Vector2 = SeuzachGeo.hub_enter_pos()
var DEFAULT_WORLD_SPAWN: Vector2 = SeuzachGeo.default_world_spawn()
const COLOR_HILL := Color("4BB85A")
const COLOR_HILL_2 := Color("3FA050")
const COLOR_FOREST_FLOOR := Color("2F9A45")



static func compute_actor_z(y: float) -> int:
	## +1 so the player wins same-row draw ties against props (tree order alone is fragile).
	return SeuzachGeo.actor_z(y, ACTOR_Z_BASE)


static func compute_prop_z(y: float) -> int:
	return SeuzachGeo.prop_z(y, PROP_Z_BASE)


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
## Road half-widths (Maps hierarchy). No footways.
const ROAD_HW_MOTORWAY := 110.0
const ROAD_HW_MAIN := 72.0
const ROAD_HW_COLLECTOR := 52.0
const ROAD_HW_LOCAL := 36.0
const ROAD_HALF_W := ROAD_HW_MAIN
const ROAD_DEBUG_Z := 3900
const ROAD_DEBUG_SPACING := 900.0
const DEBUG_GRID_SCRIPT := preload("res://scripts/debug_grid.gd")
const DEBUG_GRID_CELL := 100.0
const ROADS_JSON := "res://data/seuzach_roads.json"

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
var _road_debug_enabled: bool = false
var _road_debug_root: Node2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sky.color = COLOR_SKY
	_build_flat_ground()
	_place_landmarks()
	_hint.text = (
		"Bewegen: %s | Transform: %s/Q | Char: 1=Bolt 2=Marina 3=Rush | Pause: %s | Debug: %s"
		% [
			InputGlyphs.glyph_for("move_left"),
			InputGlyphs.glyph_for("transform"),
			InputGlyphs.glyph_for("pause_menu"),
			InputGlyphs.glyph_for("debug_overlay"),
		]
	)
	if _player and _player.has_signal("form_changed"):
		_player.form_changed.connect(_on_form_changed)
	if _player:
		if GameState.has_world_spawn:
			_player.global_position = GameState.consume_world_spawn()
		else:
			_player.global_position = DEFAULT_WORLD_SPAWN
	_sync_actor_z()
	_refresh_status()


func _sync_actor_z() -> void:
	if _player:
		_player.z_as_relative = false
		_player.z_index = compute_actor_z(_player.global_position.y)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay") and not event.is_echo():
		toggle_road_debug()
		get_viewport().set_input_as_handled()
		return
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



func is_road_debug_enabled() -> bool:
	return _road_debug_enabled


func toggle_road_debug() -> void:
	set_road_debug(not _road_debug_enabled)


func set_road_debug(enabled: bool) -> void:
	_road_debug_enabled = enabled
	if enabled:
		_rebuild_road_debug_labels()
	else:
		_clear_road_debug_labels()
	if not _paused:
		_refresh_status()


func _ensure_road_debug_root() -> Node2D:
	if _road_debug_root == null or not is_instance_valid(_road_debug_root):
		_road_debug_root = Node2D.new()
		_road_debug_root.name = "RoadDebugOverlay"
		_road_debug_root.z_as_relative = false
		_road_debug_root.z_index = ROAD_DEBUG_Z
		add_child(_road_debug_root)
	return _road_debug_root


func _clear_road_debug_labels() -> void:
	if _road_debug_root == null or not is_instance_valid(_road_debug_root):
		return
	for child in _road_debug_root.get_children():
		_road_debug_root.remove_child(child)
		child.free()


func _rebuild_road_debug_labels() -> void:
	_clear_road_debug_labels()
	var overlay := _ensure_road_debug_root()
	_add_debug_grid(overlay)
	if _ground == null:
		return
	for node in _ground.get_children():
		if not node.has_meta("road_name") or not node.has_meta("road_points"):
			continue
		var road_name := str(node.get_meta("road_name"))
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		var samples: Array = RoadKitLib.label_samples(pts, ROAD_DEBUG_SPACING)
		for i in range(samples.size()):
			var sample: Dictionary = samples[i]
			var holder := Node2D.new()
			holder.name = "DebugLabel_%s_%d" % [road_name.replace(" ", "_"), i]
			holder.position = sample["pos"]
			holder.rotation = RoadKitLib.readable_label_rotation(sample["tangent"])
			holder.z_as_relative = false
			holder.z_index = ROAD_DEBUG_Z
			holder.set_meta("road_debug_label", true)
			holder.set_meta("road_name", road_name)
			var label := Label.new()
			label.text = road_name
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			label.add_theme_color_override("font_outline_color", Color(0.12, 0.12, 0.12, 0.92))
			label.add_theme_constant_override("outline_size", 5)
			holder.add_child(label)
			overlay.add_child(holder)
			var sz := label.get_minimum_size()
			label.size = sz
			label.position = -sz * 0.5


func _add_debug_grid(overlay: Node2D) -> void:
	var grid = DEBUG_GRID_SCRIPT.new()
	grid.name = "DebugGrid"
	grid.z_as_relative = false
	grid.z_index = ROAD_DEBUG_Z - 10
	grid.set_meta("road_debug_grid", true)
	grid.set_meta("cell_size", DEBUG_GRID_CELL)
	grid.cell_size = DEBUG_GRID_CELL
	grid.bounds = SeuzachGeo.WORLD_BOUNDS
	grid.major_every = 10
	grid.label_major_only = true
	overlay.add_child(grid)


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
	var debug_hint := ""
	if _road_debug_enabled:
		var feld: Vector2i = DEBUG_GRID_SCRIPT.world_to_cell(_player.global_position, DEBUG_GRID_CELL)
		debug_hint = " | Debug: Strassen | Raster %d | Feld %d,%d" % [
			int(DEBUG_GRID_CELL), feld.x, feld.y
		]
	_status.text = "M3 Strassenkarte | %s | Form: %s | Münzen: %d%s%s" % [
		char_id.capitalize(), form_name, GameState.coins, hub_hint, debug_hint
	]


func _build_flat_ground() -> void:
	for child in _ground.get_children():
		child.queue_free()

	# Flat grass canvas — street map only (no hills, forest floors, or landmark props).
	var b := SeuzachGeo.WORLD_BOUNDS
	var p0 := b.position
	var p1 := Vector2(b.end.x, b.position.y)
	var p2 := b.end
	var p3 := Vector2(b.position.x, b.end.y)
	var base := Polygon2D.new()
	base.color = COLOR_GRASS
	base.z_index = -50
	base.polygon = PackedVector2Array([p0, p1, p2, p3])
	_ground.add_child(base)
	if _sky:
		_sky.polygon = PackedVector2Array([p0, p1, p2, p3])

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


func _load_road_data() -> Dictionary:
	if not FileAccess.file_exists(ROADS_JSON):
		push_warning("Missing %s" % ROADS_JSON)
		return {}
	var file := FileAccess.open(ROADS_JSON, FileAccess.READ)
	if file == null:
		push_warning("Cannot read %s" % ROADS_JSON)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _add_continuous_roads() -> void:
	## OSM/Maps polylines at 5,3 m/Feld. No footways. +X east, +Y south; Kirche = (0,0).
	var data := _load_road_data()
	var roads: Array = data.get("roads", [])
	for item in roads:
		if not (item is Dictionary):
			continue
		var rec: Dictionary = item
		var raw_pts: Array = rec.get("points", [])
		var pts: Array = []
		for p in raw_pts:
			if p is Array and (p as Array).size() >= 2:
				pts.append(Vector2(float(p[0]), float(p[1])))
		_add_named_road(str(rec.get("name", "")), str(rec.get("class", "local")), pts)
	var junctions: Array = data.get("junctions", [])
	for j in junctions:
		if j is Array and (j as Array).size() >= 3:
			RoadKitLib.add_junction(
				_ground, Vector2(float(j[0]), float(j[1])), float(j[2])
			)


func _road_opts(road_class: String) -> Dictionary:
	match road_class:
		"motorway":
			return {
				"sidewalk": false,
				"centerline": true,
				"half_w": ROAD_HW_MOTORWAY,
				"dash_len": 90.0,
				"gap_len": 70.0,
			}
		"main":
			return {
				"sidewalk": true,
				"centerline": true,
				"half_w": ROAD_HW_MAIN,
				"dash_len": 90.0,
				"gap_len": 70.0,
			}
		"collector":
			return {"sidewalk": true, "centerline": false, "half_w": ROAD_HW_COLLECTOR}
		_:
			return {"sidewalk": true, "centerline": false, "half_w": ROAD_HW_LOCAL}


func _add_named_road(road_name: String, road_class: String, points: Array) -> void:
	if points.size() < 2:
		return
	var opts := _road_opts(road_class)
	RoadKitLib.add_polyline(_ground, points, opts)
	var mid: Vector2 = points[int(points.size() / 2)] as Vector2
	_add_road_marker(road_name, mid, road_class, float(opts["half_w"]), points)


func _add_road_marker(
	road_name: String,
	pos: Vector2,
	road_class: String,
	half_w: float,
	points: Array = []
) -> void:
	var marker := Node2D.new()
	marker.name = "Road_%s" % road_name.replace(" ", "_")
	marker.position = pos
	marker.set_meta("road_name", road_name)
	marker.set_meta("road_class", road_class)
	marker.set_meta("half_w", half_w)
	if not points.is_empty():
		var packed := PackedVector2Array()
		for pt in points:
			packed.append(pt as Vector2)
		marker.set_meta("road_points", packed)
	_ground.add_child(marker)


func _place_landmarks() -> void:
	## Street map + school clusters + placed kindergartens (Maps). No houses/hub facade.
	for child in _props.get_children():
		child.free()
	_prop_parent = _props
	_add_hub_enter_zone()
	_place_school_clusters()
	_place_kindergartens()


func _place_school_clusters() -> void:
	## Birch + Rietacker + Ohringen: OSM building centroids.
	_add_prop(
		"landmark_schulhaus_birch_a.png",
		SeuzachGeo.birch_schulhaus_a_world(),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_birch", "school_cluster": "birch", "district": "birch"},
		"schulhaus_birch_a"
	)
	_add_prop(
		"landmark_schulhaus_birch_b.png",
		SeuzachGeo.birch_schulhaus_b_world(),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_birch", "school_cluster": "birch", "district": "birch"},
		"schulhaus_birch_b"
	)
	_add_prop(
		"landmark_turnhalle_birch.png",
		SeuzachGeo.birch_turnhalle_world(),
		SCHOOL_SCALE,
		{"landmark_id": "turnhalle_birch", "school_cluster": "birch", "district": "birch", "poi_type": "gym"},
		"turnhalle_birch"
	)
	_add_prop(
		"landmark_schulhaus_rietacker_a.png",
		SeuzachGeo.rietacker_schulhaus_a_world(),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_rietacker", "school_cluster": "rietacker", "district": "rietacker"},
		"schulhaus_rietacker_a"
	)
	_add_prop(
		"landmark_schulhaus_rietacker_b.png",
		SeuzachGeo.rietacker_schulhaus_b_world(),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_rietacker", "school_cluster": "rietacker", "district": "rietacker"},
		"schulhaus_rietacker_b"
	)
	_add_prop(
		"landmark_turnhalle_rietacker.png",
		SeuzachGeo.rietacker_turnhalle_world(),
		SCHOOL_SCALE,
		{"landmark_id": "turnhalle_rietacker", "school_cluster": "rietacker", "district": "rietacker", "poi_type": "gym"},
		"turnhalle_rietacker"
	)
	var ohringen := Node2D.new()
	ohringen.name = "DistrictOhringen"
	ohringen.set_meta("district", "ohringen")
	ohringen.position = Vector2.ZERO
	_props.add_child(ohringen)
	_prop_parent = ohringen
	_add_prop(
		"landmark_schulhaus_ohringen_a.png",
		SeuzachGeo.ohringen_schulhaus_a_world(),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_ohringen", "school_cluster": "ohringen", "district": "ohringen"},
		"schulhaus_ohringen_a"
	)
	_add_prop(
		"landmark_schulhaus_ohringen_b.png",
		SeuzachGeo.ohringen_schulhaus_b_world(),
		SCHOOL_SCALE,
		{"landmark_id": "schulhaus_ohringen", "school_cluster": "ohringen", "district": "ohringen"},
		"schulhaus_ohringen_b"
	)
	_add_prop(
		"landmark_turnhalle_ohringen.png",
		SeuzachGeo.ohringen_turnhalle_world(),
		SCHOOL_SCALE,
		{"landmark_id": "turnhalle_ohringen", "school_cluster": "ohringen", "district": "ohringen", "poi_type": "gym"},
		"turnhalle_ohringen"
	)
	_prop_parent = _props


func _place_kindergartens() -> void:
	## S04 Bachtobel + S05 Weid + S06 Schneckenwiese under %Props; S07 Ohringen-Kiga under DistrictOhringen.
	_add_prop(
		"landmark_kiga_bachtobel.png",
		SeuzachGeo.kiga_bachtobel_world(),
		SCHOOL_SCALE,
		{"landmark_id": "kiga_bachtobel", "kindergarten_id": "kiga_bachtobel", "district": "bachtobel"},
		"kiga_bachtobel"
	)
	_add_prop(
		"landmark_kiga_weid.png",
		SeuzachGeo.kiga_weid_world(),
		SCHOOL_SCALE,
		{"landmark_id": "kiga_weid", "kindergarten_id": "kiga_weid", "district": "weid"},
		"kiga_weid"
	)
	_add_prop(
		"landmark_kiga_schneckenwiese.png",
		SeuzachGeo.kiga_schneckenwiese_world(),
		SCHOOL_SCALE,
		{
			"landmark_id": "kiga_schneckenwiese",
			"kindergarten_id": "kiga_schneckenwiese",
			"district": "schneckenwiese",
		},
		"kiga_schneckenwiese"
	)
	var district := _props.get_node_or_null("DistrictOhringen")
	_prop_parent = district if district else _props
	_add_prop(
		"landmark_kiga_ohringen.png",
		SeuzachGeo.kiga_ohringen_world(),
		SCHOOL_SCALE,
		{
			"landmark_id": "kiga_ohringen",
			"kindergarten_id": "kiga_ohringen",
			"district": "ohringen",
		},
		"kiga_ohringen"
	)
	_prop_parent = _props


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
