extends Node2D
## Sandbox world: street map (grass + RoadKit) + school clusters for orientation.
## M3: Seuzach+Ohringen OSM-Netz auf 5,3 m/Feld; HubEnter unsichtbar am Forrenberg.

const RoadKitLib := preload("res://scripts/road_kit.gd")
const RailwayKitLib := preload("res://scripts/railway_kit.gd")
const WaterKitLib := preload("res://scripts/water_kit.gd")
const ART := "res://assets/art/"
const HUB_SCENE := "res://scenes/hub_station.tscn"
## Unused; buildings use SCHOOL_SCALE / LANDMARK_SCALE (not PROP_SCALE).
const PROP_SCALE := Vector2(0.22, 0.22)
const LANDMARK_SCALE := Vector2(0.55, 0.55)
const FOREST_SCALE := Vector2(0.24, 0.24)
const HUB_SCALE := Vector2(0.28, 0.28)
const SCHOOL_SCALE := Vector2(0.50, 0.50)
## Residential props along Winterthurer spawn corridor (not SCHOOL/LANDMARK scale).
const HOUSE_SCALE := Vector2(0.38, 0.38)
## Visual off-road clearance (sprite paint vs RoadKit asphalt). Separate from BuildingCollision 0.20/0.10.
## Near-full sprite AABB so landmark/school façades cannot paint onto asphalt.
const BUILDING_CLEAR_W_FRAC := 0.95
const BUILDING_CLEAR_H_FRAC := 0.88
const BUILDING_CLEAR_EDGE_MARGIN := 40.0
## Housing: tighter curb setback (street-facing paint only; landmarks keep BUILDING_CLEAR_*).
const HOUSE_CLEAR_W_FRAC := 0.70
const HOUSE_CLEAR_H_FRAC := 0.55
const HOUSE_CLEAR_EDGE_MARGIN := 12.0
const HOUSE_CURB_SLACK := 6.0
## S02: Birch/Rietacker per-building multipliers on SCHOOL_SCALE (OSM footprint ratios).
const BIRCH_A_SCALE_MULT := 1.20
const BIRCH_B_SCALE_MULT := 1.20
const BIRCH_TURNHALLE_SCALE_MULT := 1.00
const RIETACKER_A_SCALE_MULT := 1.30
const RIETACKER_B_SCALE_MULT := 1.25
const RIETACKER_TURNHALLE_SCALE_MULT := 1.30
## S03: Ohringen campus + kiga per-building multipliers on SCHOOL_SCALE (OSM footprint ratios).
const OHRINGEN_A_SCALE_MULT := 1.35
const OHRINGEN_B_SCALE_MULT := 0.83
const OHRINGEN_TURNHALLE_SCALE_MULT := 0.75
const KIGA_OHRINGEN_SCALE_MULT := 0.55
## S04: Seuzach kigas Bachtobel/Weid/Schneckenwiese multipliers on SCHOOL_SCALE (OSM footprint ratios).
const KIGA_BACHTOBEL_SCALE_MULT := 0.57
const KIGA_WEID_SCALE_MULT := 0.55
const KIGA_SCHNECKENWIESE_SCALE_MULT := 1.03
## S05: Bahnhof + Badi multipliers on LANDMARK_SCALE (OSM footprint ratios).
const BAHNHOF_SCALE_MULT := 0.79
const BADI_SCALE_MULT := 1.01
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
const RAILS_JSON := "res://data/seuzach_rails.json"
const WATER_JSON := "res://data/seuzach_water.json"
const FORESTS_JSON := "res://data/seuzach_forests.json"
const FOREST_FLOOR_Z := -48
const RAIL_HW := 38.0
const STREAM_HW := 16.0
const RIVER_HW := 24.0

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

	# Flat grass canvas + OSM forest floors under water/roads. No hills.
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

	_add_forest_floors()
	_add_continuous_streams()
	_add_continuous_roads()
	_add_continuous_rails()


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


func _load_rail_data() -> Dictionary:
	if not FileAccess.file_exists(RAILS_JSON):
		push_warning("Missing %s" % RAILS_JSON)
		return {}
	var file := FileAccess.open(RAILS_JSON, FileAccess.READ)
	if file == null:
		push_warning("Cannot read %s" % RAILS_JSON)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _load_water_data() -> Dictionary:
	if not FileAccess.file_exists(WATER_JSON):
		push_warning("Missing %s" % WATER_JSON)
		return {}
	var file := FileAccess.open(WATER_JSON, FileAccess.READ)
	if file == null:
		push_warning("Cannot read %s" % WATER_JSON)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _add_continuous_streams() -> void:
	## OSM named brooks under Ground, below RoadKit asphalt. No collision, no road_name.
	var data := _load_water_data()
	var streams_root := Node2D.new()
	streams_root.name = "Streams"
	_ground.add_child(streams_root)
	var streams: Array = data.get("streams", [])
	for item in streams:
		if not (item is Dictionary):
			continue
		var rec: Dictionary = item
		var pts := _points_from_json(rec.get("points", []))
		if pts.size() < 2:
			continue
		var waterway := str(rec.get("waterway", "stream"))
		var half_w := RIVER_HW if waterway == "river" else STREAM_HW
		WaterKitLib.add_polyline(streams_root, pts, {"half_w": half_w})
		var mid: Vector2 = pts[int(pts.size() / 2)] as Vector2
		_add_stream_marker(str(rec.get("name", "")), waterway, mid, half_w, pts)


func _load_forest_data() -> Dictionary:
	if not FileAccess.file_exists(FORESTS_JSON):
		push_warning("Missing %s" % FORESTS_JSON)
		return {}
	var file := FileAccess.open(FORESTS_JSON, FileAccess.READ)
	if file == null:
		push_warning("Cannot read %s" % FORESTS_JSON)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


func _add_forest_floors() -> void:
	## OSM forest/wood fills under Ground, below WaterKit. No collision, no Line2D.
	var data := _load_forest_data()
	var forests_root := Node2D.new()
	forests_root.name = "Forests"
	_ground.add_child(forests_root)
	var forests: Array = data.get("forests", [])
	for item in forests:
		if not (item is Dictionary):
			continue
		var rec: Dictionary = item
		var pts := _points_from_json(rec.get("points", []))
		if pts.size() < 3:
			continue
		var poly := Polygon2D.new()
		poly.color = COLOR_FOREST_FLOOR
		poly.z_index = FOREST_FLOOR_Z
		var packed := PackedVector2Array()
		for pt in pts:
			packed.append(pt as Vector2)
		poly.polygon = packed
		poly.set_meta("forest_kit", "floor")
		poly.set_meta("terrain", "forest")
		forests_root.add_child(poly)
		var centroid := _json_vec2(rec.get("centroid", []), packed)
		_add_forest_marker(str(rec.get("name", "")), str(rec.get("osm", "forest")), centroid, packed)


func _json_vec2(raw: Variant, fallback_pts: PackedVector2Array) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	if fallback_pts.size() == 0:
		return Vector2.ZERO
	var acc := Vector2.ZERO
	for p in fallback_pts:
		acc += p
	return acc / float(fallback_pts.size())


func _add_forest_marker(
	forest_name: String,
	osm: String,
	pos: Vector2,
	points: PackedVector2Array
) -> void:
	var marker := Node2D.new()
	var label := forest_name if forest_name != "" else "unnamed"
	marker.name = "Forest_%s_%d_%d" % [label.replace(" ", "_"), int(pos.x), int(pos.y)]
	marker.position = pos
	marker.set_meta("forest_name", forest_name)
	marker.set_meta("osm", osm)
	marker.set_meta("poi_type", "forest")
	if points.size() >= 3:
		marker.set_meta("forest_points", points)
	_ground.add_child(marker)


func _add_stream_marker(
	stream_name: String,
	waterway: String,
	pos: Vector2,
	half_w: float,
	points: Array
) -> void:
	var marker := Node2D.new()
	marker.name = "Stream_%s_%d_%d" % [stream_name.replace(" ", "_"), int(pos.x), int(pos.y)]
	marker.position = pos
	marker.set_meta("stream_name", stream_name)
	marker.set_meta("waterway", waterway)
	marker.set_meta("half_w", half_w)
	marker.set_meta("poi_type", "stream")
	if not points.is_empty():
		var packed := PackedVector2Array()
		for pt in points:
			packed.append(pt as Vector2)
		marker.set_meta("stream_points", packed)
	_ground.add_child(marker)


func _add_continuous_rails() -> void:
	## OSM SBB 821 ballast+rails under Ground. No collision, no road_name.
	var data := _load_rail_data()
	var rails_root := Node2D.new()
	rails_root.name = "Rails"
	_ground.add_child(rails_root)
	var tracks: Array = data.get("tracks", [])
	for item in tracks:
		if not (item is Dictionary):
			continue
		var rec: Dictionary = item
		var pts := _points_from_json(rec.get("points", []))
		if pts.size() < 2:
			continue
		RailwayKitLib.add_polyline(rails_root, pts, {"half_w": RAIL_HW})
		var mid: Vector2 = pts[int(pts.size() / 2)] as Vector2
		_add_railway_marker(
			str(rec.get("name", "")),
			str(rec.get("track_ref", "")),
			mid,
			RAIL_HW,
			pts
		)
	var platforms: Array = data.get("platforms", [])
	for item in platforms:
		if not (item is Dictionary):
			continue
		var rec: Dictionary = item
		var pts := _points_from_json(rec.get("points", []))
		if pts.size() < 3:
			continue
		RailwayKitLib.add_platform(rails_root, pts)
		_add_platform_marker(str(rec.get("ref", "")), pts)


func _points_from_json(raw_pts: Variant) -> Array:
	var pts: Array = []
	if not (raw_pts is Array):
		return pts
	for p in raw_pts:
		if p is Array and (p as Array).size() >= 2:
			pts.append(Vector2(float(p[0]), float(p[1])))
	return pts


func _add_railway_marker(
	railway_name: String,
	track_ref: String,
	pos: Vector2,
	half_w: float,
	points: Array
) -> void:
	var marker := Node2D.new()
	marker.name = "Railway_%s_%s" % [railway_name.replace(" ", "_"), track_ref]
	marker.position = pos
	marker.set_meta("railway_name", railway_name)
	marker.set_meta("track_ref", track_ref)
	marker.set_meta("half_w", half_w)
	marker.set_meta("poi_type", "railway")
	if not points.is_empty():
		var packed := PackedVector2Array()
		for pt in points:
			packed.append(pt as Vector2)
		marker.set_meta("railway_points", packed)
	_ground.add_child(marker)


func _add_platform_marker(platform_ref: String, points: Array) -> void:
	if points.is_empty():
		return
	## Station-area vertex (closest to OSM stop ref 1), not the long SE tail centroid.
	var stop_ref1 := SeuzachGeo.gps_to_world(47.5358162, 8.7389630)
	var pos: Vector2 = points[0] as Vector2
	var best := pos.distance_to(stop_ref1)
	for pt in points:
		var p: Vector2 = pt as Vector2
		var d := p.distance_to(stop_ref1)
		if d < best:
			best = d
			pos = p
	var marker := Node2D.new()
	marker.name = "Railway_platform_%s" % platform_ref
	marker.position = pos
	marker.set_meta("platform_ref", platform_ref)
	marker.set_meta("poi_type", "railway")
	_ground.add_child(marker)


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
	## Street map + school clusters + kindergartens + Bahnhof + Badi + corridor housing + forest silhouettes.
	## No hub facade.
	for child in _props.get_children():
		child.free()
	_prop_parent = _props
	_add_hub_enter_zone()
	_place_school_clusters()
	_place_kindergartens()
	_place_bahnhof()
	_place_badi()
	_place_spawn_housing()
	_place_forest_silhouettes()


func _place_spawn_housing() -> void:
	## Spawn + Kirche / Schneckenwiese — street-ribbon bases; bearing suffix picked per tangent.
	_prop_parent = _props
	var spawn := SeuzachGeo.winterthurer_spawn()
	var variants: Array[String] = [
		"house_street_a",
		"house_street_b",
		"house_street_flachdach",
		"house_street_reihen",
	]
	var roads := _named_road_polylines()
	if roads.is_empty():
		return
	var landmark_positions: Array[Vector2] = []
	for child in _collect_prop_sprites(_props):
		if child.has_meta("landmark_id"):
			landmark_positions.append(child.position)
	var placed: Array[Vector2] = []
	var counters := Vector2i(0, 0) ## x=variant_i, y=house_i
	## S01: both sides of Winterthurerstrasse in the spawn viewport.
	counters = _place_housing_along_roads(
		["Winterthurerstrasse"],
		spawn,
		900.0,
		"spawn",
		roads,
		variants,
		landmark_positions,
		placed,
		counters
	)
	## S02 Kirche corridor: Kirchgasse + Winterthurer linking west/south from spawn (~first 2 km).
	var kirche_center := Vector2(2500.0, -1000.0)
	counters = _place_housing_along_roads(
		["Kirchgasse", "Winterthurerstrasse"],
		kirche_center,
		2000.0,
		"kirche",
		roads,
		variants,
		landmark_positions,
		placed,
		counters
	)
	## S02 Schneckenwiese corridor: first stretch of the drive toward kiga (~Reutlinger / Winterthurer N).
	var kiga := SeuzachGeo.kiga_schneckenwiese_world()
	var schn_center := spawn.lerp(kiga, 0.30)
	counters = _place_housing_along_roads(
		["Winterthurerstrasse", "Reutlingerstrasse", "Schneckenwiesenstrasse"],
		schn_center,
		2000.0,
		"schneckenwiese",
		roads,
		variants,
		landmark_positions,
		placed,
		counters
	)


func _place_housing_along_roads(
	road_names: Array,
	center: Vector2,
	radius: float,
	corridor_id: String,
	roads: Array[Dictionary],
	variants: Array[String],
	landmark_positions: Array[Vector2],
	placed: Array[Vector2],
	counters: Vector2i
) -> Vector2i:
	## Both sides, off-road, spaced houses along named RoadKit polylines inside radius.
	var spacing := 250.0
	var min_house_sep := 200.0
	var min_spawn_sep := 160.0
	var min_landmark_sep := 320.0
	var spawn := SeuzachGeo.winterthurer_spawn()
	var name_set: Dictionary = {}
	for n in road_names:
		name_set[str(n)] = true
	var variant_i := counters.x
	var house_i := counters.y
	for road in roads:
		if not name_set.has(str(road.get("name", ""))):
			continue
		var pts: PackedVector2Array = road["points"]
		var half_w: float = float(road["half_w"])
		if pts.size() < 2:
			continue
		var samples := _sample_polyline(pts, spacing)
		for sample in samples:
			var point: Vector2 = sample["point"]
			var tangent: Vector2 = sample["tangent"]
			if point.distance_to(center) > radius:
				continue
			var perp := Vector2(-tangent.y, tangent.x)
			if perp.length_squared() < 0.0001:
				continue
			perp = perp.normalized()
			for side_i in range(2):
				var side := 1.0 if side_i == 0 else -1.0
				var base: String = variants[variant_i % variants.size()]
				## Sample tangent bearing; recomputed after nudge from closest segment.
				var bearing := _street_bearing_from_tangent(tangent)
				var variant := "%s_%s" % [base, bearing]
				var file_name := "%s.png" % variant
				var path := ART + file_name
				if not ResourceLoader.exists(path):
					variant_i += 1
					continue
				var tex: Texture2D = load(path)
				var clear_sz := _house_clear_size(tex, HOUSE_SCALE)
				## Street-facing half-extent: NS → clear.x (left façade); EW → clear.y (bottom).
				var street_half := (clear_sz.x if bearing == "ns" else clear_sz.y) * 0.5
				var need := half_w + street_half + HOUSE_CLEAR_EDGE_MARGIN + HOUSE_CURB_SLACK
				var pos := point + perp * side * need
				if pos.distance_to(spawn) < min_spawn_sep:
					variant_i += 1
					continue
				var too_close := false
				for other in placed:
					if pos.distance_to(other) < min_house_sep:
						too_close = true
						break
				if too_close:
					variant_i += 1
					continue
				for lp in landmark_positions:
					if pos.distance_to(lp) < min_landmark_sep:
						too_close = true
						break
				if too_close:
					variant_i += 1
					continue
				if not _sprite_clears_named_roads(pos, tex, HOUSE_SCALE, roads, true, bearing):
					pos = _nudge_off_named_roads(pos, tex, HOUSE_SCALE, roads, 700.0, true, bearing)
					if not _sprite_clears_named_roads(pos, tex, HOUSE_SCALE, roads, true, bearing):
						variant_i += 1
						continue
				## After nudge: sep/landmark/spawn must still hold at the final position.
				if pos.distance_to(spawn) < min_spawn_sep:
					variant_i += 1
					continue
				too_close = false
				for other in placed:
					if pos.distance_to(other) < min_house_sep:
						too_close = true
						break
				if too_close:
					variant_i += 1
					continue
				for lp in landmark_positions:
					if pos.distance_to(lp) < min_landmark_sep:
						too_close = true
						break
				if too_close:
					variant_i += 1
					continue
				## Street-facing + bearing from nudged pos vs this corridor road.
				var corridor_road := {
					"name": str(road.get("name", "")),
					"half_w": half_w,
					"points": pts,
				}
				var facing := _housing_facing_on_corridor(pos, corridor_road, perp, tangent)
				if facing.is_empty():
					variant_i += 1
					continue
				side = float(facing["side"])
				var local_perp: Vector2 = facing["perp"]
				bearing = str(facing["bearing"])
				variant = "%s_%s" % [base, bearing]
				file_name = "%s.png" % variant
				path = ART + file_name
				if not ResourceLoader.exists(path):
					variant_i += 1
					continue
				## Final texture may differ after EW↔NS; recompute clear and re-nudge if needed.
				tex = load(path)
				if not _sprite_clears_named_roads(pos, tex, HOUSE_SCALE, roads, true, bearing):
					pos = _nudge_off_named_roads(pos, tex, HOUSE_SCALE, roads, 700.0, true, bearing)
					if not _sprite_clears_named_roads(pos, tex, HOUSE_SCALE, roads, true, bearing):
						variant_i += 1
						continue
					if pos.distance_to(spawn) < min_spawn_sep:
						variant_i += 1
						continue
					too_close = false
					for other in placed:
						if pos.distance_to(other) < min_house_sep:
							too_close = true
							break
					if too_close:
						variant_i += 1
						continue
					for lp in landmark_positions:
						if pos.distance_to(lp) < min_landmark_sep:
							too_close = true
							break
					if too_close:
						variant_i += 1
						continue
					facing = _housing_facing_on_corridor(pos, corridor_road, perp, tangent)
					if facing.is_empty():
						variant_i += 1
						continue
					side = float(facing["side"])
					local_perp = facing["perp"]
					var bearing_after := str(facing["bearing"])
					if bearing_after != bearing:
						bearing = bearing_after
						variant = "%s_%s" % [base, bearing]
						file_name = "%s.png" % variant
						path = ART + file_name
						if not ResourceLoader.exists(path):
							variant_i += 1
							continue
						tex = load(path)
						if not _sprite_clears_named_roads(pos, tex, HOUSE_SCALE, roads, true, bearing):
							variant_i += 1
							continue
				variant_i += 1
				## EW: door bottom-left (SW); NS: door on left edge (W). Flip so door faces asphalt.
				var toward_road := (-local_perp * side).normalized()
				var flip := _street_door_flip_h(bearing, toward_road)
				var node_name := "house_%s_%s_%d" % [
					corridor_id, variant.trim_prefix("house_"), house_i
				]
				var meta := {
					"house_variant": variant,
					"district": "seuzach",
					"housing_corridor": corridor_id,
					"street_name": str(road.get("name", "")),
					"street_side": int(side),
					"street_bearing": bearing,
					"faces_street": true,
				}
				var spr := _add_prop(
					file_name,
					pos,
					HOUSE_SCALE,
					meta,
					node_name,
					flip
				)
				if spr == null:
					continue
				placed.append(pos)
				house_i += 1
	return Vector2i(variant_i, house_i)


func _housing_facing_on_corridor(
	pos: Vector2,
	corridor_road: Dictionary,
	fallback_perp: Vector2,
	fallback_tangent: Vector2
) -> Dictionary:
	## Side / perp / bearing from house pos vs the placement corridor polyline.
	var pts: PackedVector2Array = corridor_road["points"]
	var closest := _closest_point_on_polyline(pos, pts)
	var away := pos - closest
	if away.length_squared() < 0.0001:
		return {}
	var local_perp := _nearest_road_segment_perp(pos, [corridor_road])
	if local_perp.length_squared() < 0.0001:
		local_perp = fallback_perp
	else:
		local_perp = local_perp.normalized()
	var side := 1.0 if away.dot(local_perp) >= 0.0 else -1.0
	var local_tangent := _nearest_road_segment_tangent(pos, [corridor_road])
	if local_tangent.length_squared() < 0.0001:
		local_tangent = fallback_tangent
	else:
		local_tangent = local_tangent.normalized()
	return {
		"side": side,
		"perp": local_perp,
		"bearing": _street_bearing_from_tangent(local_tangent),
	}


func _street_bearing_from_tangent(tangent: Vector2) -> String:
	## Binary bearing from road tangent (+X east, +Y south).
	var t := tangent
	if t.length_squared() < 0.0001:
		return "ew"
	t = t.normalized()
	return "ew" if absf(t.x) >= absf(t.y) else "ns"


func _street_door_flip_h(bearing: String, toward_road: Vector2) -> bool:
	## NS door W/E; EW door SW/SE. Flip when the flipped door aims more at the curb.
	var door_no_flip: Vector2
	var door_flip: Vector2
	if bearing == "ns":
		door_no_flip = Vector2(-1.0, 0.0)
		door_flip = Vector2(1.0, 0.0)
	else:
		door_no_flip = Vector2(-1.0, 1.0).normalized()
		door_flip = Vector2(1.0, 1.0).normalized()
	return door_flip.dot(toward_road) > door_no_flip.dot(toward_road)


func _nearest_road_segment_tangent(pos: Vector2, roads: Array[Dictionary]) -> Vector2:
	## Unit tangent of the nearest named-road segment (or RIGHT if none).
	var best_d := 1.0e9
	var best_tangent := Vector2.RIGHT
	for road in roads:
		var pts: PackedVector2Array = road["points"]
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var ab := b - a
			var len_sq := ab.length_squared()
			if len_sq < 0.0001:
				continue
			var t := clampf((pos - a).dot(ab) / len_sq, 0.0, 1.0)
			var closest := a + ab * t
			var d := pos.distance_to(closest)
			if d < best_d:
				best_d = d
				best_tangent = ab / sqrt(len_sq)
	return best_tangent


func _named_road_polylines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _ground == null:
		return out
	for node in _ground.get_children():
		_collect_named_road_markers(node, out)
	return out


func _collect_named_road_markers(node: Node, out: Array[Dictionary]) -> void:
	if node.has_meta("road_name") and node.has_meta("road_points"):
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		if pts.size() >= 2:
			out.append({
				"name": str(node.get_meta("road_name")),
				"half_w": float(node.get_meta("half_w")) if node.has_meta("half_w") else ROAD_HW_LOCAL,
				"points": pts,
			})
	for child in node.get_children():
		_collect_named_road_markers(child, out)


func _sample_polyline(pts: PackedVector2Array, spacing: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if pts.size() < 2 or spacing <= 0.0:
		return out
	var remain := 0.0
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var seg := a.distance_to(b)
		if seg < 1.0:
			continue
		var tangent := (b - a) / seg
		var t := remain
		while t <= seg:
			out.append({"point": a + tangent * t, "tangent": tangent})
			t += spacing
		remain = t - seg
	return out


func _building_clear_size(tex: Texture2D, spr_scale: Vector2) -> Vector2:
	## Visual clear pad — wider/taller than BuildingCollision so sprite paint clears asphalt.
	var footprint_w := 40.0
	var footprint_h := 20.0
	if tex != null:
		var tex_w := float(tex.get_width()) * absf(spr_scale.x)
		var tex_h := float(tex.get_height()) * absf(spr_scale.y)
		footprint_w = maxf(24.0, tex_w * BUILDING_CLEAR_W_FRAC)
		footprint_h = maxf(16.0, tex_h * BUILDING_CLEAR_H_FRAC)
	return Vector2(footprint_w, footprint_h)


func _house_clear_size(tex: Texture2D, spr_scale: Vector2) -> Vector2:
	## Housing clear pad — tighter than landmark BUILDING_CLEAR (street-facing paint).
	var footprint_w := 40.0
	var footprint_h := 20.0
	if tex != null:
		var tex_w := float(tex.get_width()) * absf(spr_scale.x)
		var tex_h := float(tex.get_height()) * absf(spr_scale.y)
		footprint_w = maxf(24.0, tex_w * HOUSE_CLEAR_W_FRAC)
		footprint_h = maxf(16.0, tex_h * HOUSE_CLEAR_H_FRAC)
	return Vector2(footprint_w, footprint_h)


func _building_clear_aabb(pos: Vector2, tex: Texture2D, spr_scale: Vector2) -> Rect2:
	## Near-full clear box centered on the visual sprite body (feet at node origin).
	var clear := _building_clear_size(tex, spr_scale)
	var tex_h := 0.0
	if tex != null:
		tex_h = float(tex.get_height()) * absf(spr_scale.y)
	var visual_center_y := -tex_h * 0.5
	return Rect2(pos + Vector2(0.0, visual_center_y) - clear * 0.5, clear)


func _house_clear_aabb(pos: Vector2, tex: Texture2D, spr_scale: Vector2) -> Rect2:
	## House clear box centered on the visual sprite body (feet at node origin).
	var clear := _house_clear_size(tex, spr_scale)
	var tex_h := 0.0
	if tex != null:
		tex_h = float(tex.get_height()) * absf(spr_scale.y)
	var visual_center_y := -tex_h * 0.5
	return Rect2(pos + Vector2(0.0, visual_center_y) - clear * 0.5, clear)


func _house_street_half(clear: Vector2, street_bearing: String) -> float:
	## NS left façade → clear.x; EW bottom façade → clear.y.
	return (clear.x if street_bearing == "ns" else clear.y) * 0.5


func _clear_street_half(clear: Vector2, house_mode: bool, street_bearing: String) -> float:
	## Houses always use the street-facing axis; landmarks only when street_bearing is set.
	if house_mode or not street_bearing.is_empty():
		return _house_street_half(clear, street_bearing)
	return clear.y * 0.5


func _sprite_clears_named_roads(
	pos: Vector2,
	tex: Texture2D,
	spr_scale: Vector2,
	roads: Array[Dictionary],
	house_mode: bool = false,
	street_bearing: String = ""
) -> bool:
	var clear := (
		_house_clear_size(tex, spr_scale) if house_mode else _building_clear_size(tex, spr_scale)
	)
	var aabb := (
		_house_clear_aabb(pos, tex, spr_scale) if house_mode else _building_clear_aabb(pos, tex, spr_scale)
	)
	var edge := HOUSE_CLEAR_EDGE_MARGIN if house_mode else BUILDING_CLEAR_EDGE_MARGIN
	for road in roads:
		var pts: PackedVector2Array = road["points"]
		var half_w: float = float(road["half_w"])
		var d_feet := _dist_point_to_polyline(pos, pts)
		var d_aabb := _dist_aabb_to_polyline(aabb, pts)
		var street_half := _clear_street_half(clear, house_mode, street_bearing)
		var need_feet := half_w + street_half + edge
		var need_aabb := half_w + edge
		if d_feet < need_feet:
			return false
		if d_aabb < need_aabb:
			return false
	return true


func _nearest_road_segment_perp(pos: Vector2, roads: Array[Dictionary]) -> Vector2:
	## Unit perpendicular of the nearest named-road segment (or RIGHT if none).
	var best_d := 1.0e9
	var best_perp := Vector2.RIGHT
	for road in roads:
		var pts: PackedVector2Array = road["points"]
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var ab := b - a
			var len_sq := ab.length_squared()
			if len_sq < 0.0001:
				continue
			var t := clampf((pos - a).dot(ab) / len_sq, 0.0, 1.0)
			var closest := a + ab * t
			var d := pos.distance_to(closest)
			if d < best_d:
				best_d = d
				var tangent := ab / sqrt(len_sq)
				best_perp = Vector2(-tangent.y, tangent.x)
	return best_perp


func _nudge_off_named_roads(
	pos: Vector2,
	tex: Texture2D,
	spr_scale: Vector2,
	roads: Array[Dictionary],
	max_nudge: float = 700.0,
	house_mode: bool = false,
	street_bearing: String = "",
	prefer_away: Vector2 = Vector2.ZERO
) -> Vector2:
	## Push perpendicular (and along axes) until visual AABB clears asphalt.
	## Optional prefer_away is tried first (GPS curb side); housing omits it so +perp stays first.
	if roads.is_empty() or _sprite_clears_named_roads(
		pos, tex, spr_scale, roads, house_mode, street_bearing
	):
		return pos
	var perp := _nearest_road_segment_perp(pos, roads)
	if perp.length_squared() < 0.0001:
		perp = Vector2.RIGHT
	else:
		perp = perp.normalized()
	var dirs: Array[Vector2] = []
	if prefer_away.length_squared() > 0.0001:
		var away_dir := prefer_away.normalized()
		dirs.append(away_dir)
		dirs.append(-away_dir)
	dirs.append_array([
		perp,
		-perp,
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
		Vector2.DOWN,
		Vector2(1, 1).normalized(),
		Vector2(1, -1).normalized(),
		Vector2(-1, 1).normalized(),
		Vector2(-1, -1).normalized(),
	])
	var step := 8.0
	for dir in dirs:
		var candidate := pos
		var traveled := 0.0
		while traveled < max_nudge:
			candidate += dir * step
			traveled += step
			if _sprite_clears_named_roads(
				candidate, tex, spr_scale, roads, house_mode, street_bearing
			):
				return candidate
	## Iterative push away from the most-violating road (tight street grids).
	var candidate := pos
	var traveled := 0.0
	while traveled < max_nudge:
		if _sprite_clears_named_roads(
			candidate, tex, spr_scale, roads, house_mode, street_bearing
		):
			return candidate
		var push := _clearance_push_away(
			candidate, tex, spr_scale, roads, house_mode, street_bearing
		)
		if push.length_squared() < 0.0001:
			break
		candidate += push.normalized() * step
		traveled += step
	if _sprite_clears_named_roads(candidate, tex, spr_scale, roads, house_mode, street_bearing):
		return candidate
	return pos


func _clearance_push_away(
	pos: Vector2,
	tex: Texture2D,
	spr_scale: Vector2,
	roads: Array[Dictionary],
	house_mode: bool = false,
	street_bearing: String = ""
) -> Vector2:
	## Unit vector away from the worst-violating named road (feet or AABB).
	var clear := (
		_house_clear_size(tex, spr_scale) if house_mode else _building_clear_size(tex, spr_scale)
	)
	var aabb := (
		_house_clear_aabb(pos, tex, spr_scale) if house_mode else _building_clear_aabb(pos, tex, spr_scale)
	)
	var edge := HOUSE_CLEAR_EDGE_MARGIN if house_mode else BUILDING_CLEAR_EDGE_MARGIN
	var worst_deficit := 0.0
	var push := Vector2.ZERO
	for road in roads:
		var pts: PackedVector2Array = road["points"]
		var half_w: float = float(road["half_w"])
		var d_feet := _dist_point_to_polyline(pos, pts)
		var d_aabb := _dist_aabb_to_polyline(aabb, pts)
		var street_half := _clear_street_half(clear, house_mode, street_bearing)
		var need_feet := half_w + street_half + edge
		var need_aabb := half_w + edge
		var deficit := maxf(need_feet - d_feet, need_aabb - d_aabb)
		if deficit <= 0.0:
			continue
		var closest := _closest_point_on_polyline(pos, pts)
		var away := pos - closest
		if away.length_squared() < 0.0001:
			away = _nearest_road_segment_perp(pos, [road])
		if away.length_squared() < 0.0001:
			continue
		if deficit > worst_deficit:
			worst_deficit = deficit
			push = away.normalized()
	return push


func _closest_point_on_polyline(p: Vector2, pts: PackedVector2Array) -> Vector2:
	if pts.is_empty():
		return p
	var best_pt := pts[0]
	var best_d := p.distance_to(pts[0])
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var len_sq := ab.length_squared()
		var closest: Vector2 = a
		if len_sq >= 0.0001:
			var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
			closest = a + ab * t
		var d := p.distance_to(closest)
		if d < best_d:
			best_d = d
			best_pt = closest
	return best_pt


func _dist_point_to_polyline(p: Vector2, pts: PackedVector2Array) -> float:
	if pts.is_empty():
		return 1.0e9
	var best := p.distance_to(pts[0])
	for i in range(pts.size() - 1):
		best = minf(best, _dist_point_to_segment(p, pts[i], pts[i + 1]))
	return best


func _dist_point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _dist_aabb_to_polyline(rect: Rect2, pts: PackedVector2Array) -> float:
	if pts.size() < 2:
		return 1.0e9
	var best := 1.0e9
	for i in range(pts.size() - 1):
		best = minf(best, _dist_aabb_to_segment(rect, pts[i], pts[i + 1]))
		if best <= 0.0:
			return 0.0
	return best


func _dist_aabb_to_segment(rect: Rect2, a: Vector2, b: Vector2) -> float:
	var c0 := rect.position
	var c1 := rect.position + Vector2(rect.size.x, 0.0)
	var c2 := rect.position + rect.size
	var c3 := rect.position + Vector2(0.0, rect.size.y)
	var corners: Array[Vector2] = [c0, c1, c2, c3]
	var edges: Array[Vector2] = [c0, c1, c2, c3, c0]
	for i in range(4):
		if Geometry2D.segment_intersects_segment(a, b, edges[i], edges[i + 1]) != null:
			return 0.0
	var best := 1.0e9
	for c in corners:
		best = minf(best, _dist_point_to_segment(c, a, b))
	best = minf(best, _dist_point_to_segment(a, c0, c1))
	best = minf(best, _dist_point_to_segment(a, c1, c2))
	best = minf(best, _dist_point_to_segment(a, c2, c3))
	best = minf(best, _dist_point_to_segment(a, c3, c0))
	best = minf(best, _dist_point_to_segment(b, c0, c1))
	best = minf(best, _dist_point_to_segment(b, c1, c2))
	best = minf(best, _dist_point_to_segment(b, c2, c3))
	best = minf(best, _dist_point_to_segment(b, c3, c0))
	## Point-in-rect: segment endpoint inside footprint counts as overlap.
	if rect.has_point(a) or rect.has_point(b):
		return 0.0
	return best


func _collect_prop_sprites(node: Node) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	if node is Sprite2D:
		out.append(node as Sprite2D)
	for child in node.get_children():
		out.append_array(_collect_prop_sprites(child))
	return out


func _add_building_prop(
	file_name: String,
	pos: Vector2,
	scale: Vector2,
	metas: Dictionary = {},
	node_name: String = "",
	flip_h: bool = false
) -> Sprite2D:
	## Place a building sprite, nudging perpendicular off RoadKit asphalt when visual clear fails.
	var path := ART + file_name
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var roads := _named_road_polylines()
	var cleared := _nudge_off_named_roads(pos, tex, scale, roads, 700.0)
	if not _sprite_clears_named_roads(cleared, tex, scale, roads):
		## Never place a building that still paints on RoadKit asphalt.
		return null
	return _add_prop(file_name, cleared, scale, metas, node_name, flip_h)


func _named_road_by_name(road_name: String, roads: Array[Dictionary]) -> Dictionary:
	for road in roads:
		if str(road.get("name", "")) == road_name:
			return road
	return {}


func _add_school_street_prop(
	base_without_suffix: String,
	pos: Vector2,
	scale: Vector2,
	metas: Dictionary,
	node_name: String,
	target_road_name: String
) -> Sprite2D:
	## Street-aligned school: bearing from the target polyline, GPS bank, door toward curb.
	var roads := _named_road_polylines()
	var target := _named_road_by_name(target_road_name, roads)
	if target.is_empty():
		return null
	var pts: PackedVector2Array = target["points"]
	var closest := _closest_point_on_polyline(pos, pts)
	var away := pos - closest
	if away.length_squared() < 0.0001:
		return null
	var fallback_tangent := _nearest_road_segment_tangent(pos, [target])
	var fallback_perp := _nearest_road_segment_perp(pos, [target])
	var bearing := _street_bearing_from_tangent(fallback_tangent)
	var file_name := "%s_%s.png" % [base_without_suffix, bearing]
	var path := ART + file_name
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var clear := _building_clear_size(tex, scale)
	var street_half := _house_street_half(clear, bearing)
	var half_w := float(target["half_w"])
	var need := half_w + street_half + BUILDING_CLEAR_EDGE_MARGIN + HOUSE_CURB_SLACK
	var d_feet := pos.distance_to(closest)
	if d_feet < need:
		pos = closest + away.normalized() * need
		closest = _closest_point_on_polyline(pos, pts)
		away = pos - closest
		if away.length_squared() < 0.0001:
			return null
	var facing := _housing_facing_on_corridor(pos, target, fallback_perp, fallback_tangent)
	if facing.is_empty():
		return null
	bearing = str(facing["bearing"])
	file_name = "%s_%s.png" % [base_without_suffix, bearing]
	path = ART + file_name
	if not ResourceLoader.exists(path):
		return null
	tex = load(path)
	pos = _nudge_off_named_roads(pos, tex, scale, roads, 700.0, false, bearing, away)
	if not _sprite_clears_named_roads(pos, tex, scale, roads, false, bearing):
		return null
	facing = _housing_facing_on_corridor(pos, target, facing["perp"], fallback_tangent)
	if facing.is_empty():
		return null
	var side := float(facing["side"])
	var local_perp: Vector2 = facing["perp"]
	bearing = str(facing["bearing"])
	file_name = "%s_%s.png" % [base_without_suffix, bearing]
	path = ART + file_name
	if not ResourceLoader.exists(path):
		return null
	tex = load(path)
	if not _sprite_clears_named_roads(pos, tex, scale, roads, false, bearing):
		return null
	var toward_road := (-local_perp * side).normalized()
	var flip := _street_door_flip_h(bearing, toward_road)
	var placed_metas := metas.duplicate()
	placed_metas["street_side"] = int(side)
	placed_metas["street_bearing"] = bearing
	placed_metas["faces_street"] = true
	placed_metas["street_name"] = target_road_name
	return _add_prop(file_name, pos, scale, placed_metas, node_name, flip)


func _place_school_clusters() -> void:
	## Birch + Rietacker + Ohringen: OSM building centroids.
	## Birch uses street-aligned _ew/_ns; Rietacker/Ohringen stay unprefixed (S02/S03).
	_add_school_street_prop(
		"landmark_schulhaus_birch_a",
		SeuzachGeo.birch_schulhaus_a_world(),
		SCHOOL_SCALE * BIRCH_A_SCALE_MULT,
		{"landmark_id": "schulhaus_birch", "school_cluster": "birch", "district": "birch"},
		"schulhaus_birch_a",
		"Bachwiesenstrasse"
	)
	_add_school_street_prop(
		"landmark_schulhaus_birch_b",
		SeuzachGeo.birch_schulhaus_b_world(),
		SCHOOL_SCALE * BIRCH_B_SCALE_MULT,
		{"landmark_id": "schulhaus_birch", "school_cluster": "birch", "district": "birch"},
		"schulhaus_birch_b",
		"Birchstrasse"
	)
	_add_school_street_prop(
		"landmark_turnhalle_birch",
		SeuzachGeo.birch_turnhalle_world(),
		SCHOOL_SCALE * BIRCH_TURNHALLE_SCALE_MULT,
		{"landmark_id": "turnhalle_birch", "school_cluster": "birch", "district": "birch", "poi_type": "gym"},
		"turnhalle_birch",
		"Birchstrasse"
	)
	_add_building_prop(
		"landmark_schulhaus_rietacker_a.png",
		SeuzachGeo.rietacker_schulhaus_a_world(),
		SCHOOL_SCALE * RIETACKER_A_SCALE_MULT,
		{"landmark_id": "schulhaus_rietacker", "school_cluster": "rietacker", "district": "rietacker"},
		"schulhaus_rietacker_a"
	)
	_add_building_prop(
		"landmark_schulhaus_rietacker_b.png",
		SeuzachGeo.rietacker_schulhaus_b_world(),
		SCHOOL_SCALE * RIETACKER_B_SCALE_MULT,
		{"landmark_id": "schulhaus_rietacker", "school_cluster": "rietacker", "district": "rietacker"},
		"schulhaus_rietacker_b"
	)
	_add_building_prop(
		"landmark_turnhalle_rietacker.png",
		SeuzachGeo.rietacker_turnhalle_world(),
		SCHOOL_SCALE * RIETACKER_TURNHALLE_SCALE_MULT,
		{"landmark_id": "turnhalle_rietacker", "school_cluster": "rietacker", "district": "rietacker", "poi_type": "gym"},
		"turnhalle_rietacker"
	)
	var ohringen := Node2D.new()
	ohringen.name = "DistrictOhringen"
	ohringen.set_meta("district", "ohringen")
	ohringen.position = Vector2.ZERO
	_props.add_child(ohringen)
	_prop_parent = ohringen
	## S03: Ohringen per-building scales; flip_h false, rotation 0 (authored facing OK).
	_add_building_prop(
		"landmark_schulhaus_ohringen_a.png",
		SeuzachGeo.ohringen_schulhaus_a_world(),
		SCHOOL_SCALE * OHRINGEN_A_SCALE_MULT,
		{"landmark_id": "schulhaus_ohringen", "school_cluster": "ohringen", "district": "ohringen"},
		"schulhaus_ohringen_a"
	)
	_add_building_prop(
		"landmark_schulhaus_ohringen_b.png",
		SeuzachGeo.ohringen_schulhaus_b_world(),
		SCHOOL_SCALE * OHRINGEN_B_SCALE_MULT,
		{"landmark_id": "schulhaus_ohringen", "school_cluster": "ohringen", "district": "ohringen"},
		"schulhaus_ohringen_b"
	)
	_add_building_prop(
		"landmark_turnhalle_ohringen.png",
		SeuzachGeo.ohringen_turnhalle_world(),
		SCHOOL_SCALE * OHRINGEN_TURNHALLE_SCALE_MULT,
		{"landmark_id": "turnhalle_ohringen", "school_cluster": "ohringen", "district": "ohringen", "poi_type": "gym"},
		"turnhalle_ohringen"
	)
	_prop_parent = _props


func _place_kindergartens() -> void:
	## Bachtobel + Weid + Schneckenwiese under %Props; Ohringen-Kiga under DistrictOhringen.
	_add_building_prop(
		"landmark_kiga_bachtobel.png",
		SeuzachGeo.kiga_bachtobel_world(),
		SCHOOL_SCALE * KIGA_BACHTOBEL_SCALE_MULT,
		{"landmark_id": "kiga_bachtobel", "kindergarten_id": "kiga_bachtobel", "district": "bachtobel"},
		"kiga_bachtobel"
	)
	_add_building_prop(
		"landmark_kiga_weid.png",
		SeuzachGeo.kiga_weid_world(),
		SCHOOL_SCALE * KIGA_WEID_SCALE_MULT,
		{"landmark_id": "kiga_weid", "kindergarten_id": "kiga_weid", "district": "weid"},
		"kiga_weid"
	)
	_add_building_prop(
		"landmark_kiga_schneckenwiese.png",
		SeuzachGeo.kiga_schneckenwiese_world(),
		SCHOOL_SCALE * KIGA_SCHNECKENWIESE_SCALE_MULT,
		{
			"landmark_id": "kiga_schneckenwiese",
			"kindergarten_id": "kiga_schneckenwiese",
			"district": "schneckenwiese",
		},
		"kiga_schneckenwiese"
	)
	var district := _props.get_node_or_null("DistrictOhringen")
	_prop_parent = district if district else _props
	_add_building_prop(
		"landmark_kiga_ohringen.png",
		SeuzachGeo.kiga_ohringen_world(),
		SCHOOL_SCALE * KIGA_OHRINGEN_SCALE_MULT,
		{
			"landmark_id": "kiga_ohringen",
			"kindergarten_id": "kiga_ohringen",
			"district": "ohringen",
		},
		"kiga_ohringen"
	)
	_prop_parent = _props


func _place_bahnhof() -> void:
	## S08: station building + canopy at Stationsstrasse 53. No tracks (S09).
	## S05: LANDMARK_SCALE * BAHNHOF_SCALE_MULT; flip_h false; rotation 0 (canopy faces N).
	_prop_parent = _props
	_add_building_prop(
		"landmark_bahnhof_seuzach.png",
		SeuzachGeo.bahnhof_world(),
		LANDMARK_SCALE * BAHNHOF_SCALE_MULT,
		{"landmark_id": "bahnhof", "district": "seuzach", "poi_type": "station"},
		"bahnhof"
	)


func _place_badi() -> void:
	## S10: outdoor pool at Landstrasse 26. Not Ohringen, not Birch indoor pool.
	## S05: LANDMARK_SCALE * BADI_SCALE_MULT; flip_h false; rotation 0 (north of Landstrasse).
	_prop_parent = _props
	_add_building_prop(
		"landmark_badi_weiher.png",
		SeuzachGeo.badi_world(),
		LANDMARK_SCALE * BADI_SCALE_MULT,
		{"landmark_id": "badi_weiher", "district": "seuzach", "poi_type": "swimming"},
		"badi_weiher"
	)


func _place_forest_silhouettes() -> void:
	## Few cluster sprites on patch centroids. Not _add_prop (no BuildingCollision).
	_prop_parent = _props
	var data := _load_forest_data()
	var silhouettes: Array = data.get("silhouettes", [])
	var idx := 0
	for item in silhouettes:
		if not (item is Dictionary):
			continue
		var rec: Dictionary = item
		var art := str(rec.get("art", "a"))
		if art != "b":
			art = "a"
		var file_name := "landmark_wald_b.png" if art == "b" else "landmark_wald_a.png"
		var pos := _json_vec2(rec.get("pos", []), PackedVector2Array())
		var forest_name := str(rec.get("name", ""))
		var node_name := "wald_%s_%d" % [art, idx]
		idx += 1
		_add_forest_silhouette(
			file_name,
			pos,
			{
				"terrain": "forest",
				"landmark_id": "wald",
				"forest_name": forest_name,
				"art": art,
			},
			node_name
		)


func _add_forest_silhouette(
	file_name: String,
	pos: Vector2,
	metas: Dictionary = {},
	node_name: String = ""
) -> Sprite2D:
	## Cluster sprite only — no BuildingCollision. Nudge off RoadKit asphalt; floors stay put.
	var path := ART + file_name
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var roads := _named_road_polylines()
	var cleared := _nudge_off_named_roads(pos, tex, FOREST_SCALE, roads)
	var spr := Sprite2D.new()
	if node_name != "":
		spr.name = node_name
	spr.texture = tex
	spr.scale = FOREST_SCALE
	spr.position = cleared
	spr.centered = true
	spr.offset = Vector2(0.0, feet_offset_y(spr.texture))
	spr.z_as_relative = false
	spr.z_index = compute_prop_z(cleared.y)
	var all_metas := metas.duplicate()
	if not all_metas.has("forest_kit"):
		all_metas["forest_kit"] = "silhouette"
	for key in all_metas.keys():
		spr.set_meta(str(key), all_metas[key])
	var parent: Node2D = _prop_parent if _prop_parent != null else _props
	parent.add_child(spr)
	return spr


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
	# Non-hub: shallow ground footprint — display scale grew in S01; keep collision near pre-scale size.
	var footprint_w := tex_w * (0.28 if is_hub else 0.20)
	var footprint_h := tex_h * (0.12 if is_hub else 0.10)
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
	node_name: String = "",
	flip_h: bool = false
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
	spr.flip_h = flip_h
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
