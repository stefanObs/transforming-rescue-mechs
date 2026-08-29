extends SceneTree
## M3 Seuzach street map: art on disk, world is roads-only (no landmarks/houses).

const ART := "res://assets/art/"
const HousingQuarters := preload("res://scripts/housing_quarters.gd")
const REQUIRED_ART := [
	"landmark_bahnhof_seuzach.png",
	"landmark_feuerwehr_seuzach.png",
	"landmark_badi_weiher.png",
	"landmark_schulhaus_birch_a.png",
	"landmark_schulhaus_birch_b.png",
	"landmark_schulhaus_birch_a_ew.png",
	"landmark_schulhaus_birch_a_ns.png",
	"landmark_schulhaus_birch_b_ew.png",
	"landmark_schulhaus_birch_b_ns.png",
	"landmark_turnhalle_birch_ew.png",
	"landmark_turnhalle_birch_ns.png",
	"landmark_schulhaus_rietacker_a.png",
	"landmark_schulhaus_rietacker_b.png",
	"landmark_schulhaus_rietacker_a_ew.png",
	"landmark_schulhaus_rietacker_a_ns.png",
	"landmark_schulhaus_rietacker_b_ew.png",
	"landmark_schulhaus_rietacker_b_ns.png",
	"landmark_turnhalle_rietacker_ew.png",
	"landmark_turnhalle_rietacker_ns.png",
	"landmark_schulhaus_ohringen_a.png",
	"landmark_schulhaus_ohringen_b.png",
	"landmark_turnhalle_ohringen.png",
	"landmark_schulhaus_ohringen_a_ew.png",
	"landmark_schulhaus_ohringen_a_ns.png",
	"landmark_schulhaus_ohringen_b_ew.png",
	"landmark_schulhaus_ohringen_b_ns.png",
	"landmark_turnhalle_ohringen_ew.png",
	"landmark_turnhalle_ohringen_ns.png",
	"landmark_kiga_ohringen_ew.png",
	"landmark_kiga_ohringen_ns.png",
	"house_a.png",
	"house_b.png",
	"house_c.png",
	"house_d.png",
	"house_farm.png",
	"landmark_kiga_bachtobel.png",
	"landmark_kiga_bachtobel_ew.png",
	"landmark_kiga_bachtobel_ns.png",
	"landmark_kiga_weid.png",
	"landmark_kiga_weid_ew.png",
	"landmark_kiga_weid_ns.png",
	"landmark_kiga_schneckenwiese.png",
	"landmark_kiga_schneckenwiese_ew.png",
	"landmark_kiga_schneckenwiese_ns.png",
	"landmark_kiga_ohringen.png",
	"landmark_gemeindehaus_seuzach.png",
	"landmark_kirche_seuzach.png",
	"landmark_tankstelle_seuzach.png",
	"landmark_restaurant_a.png",
	"landmark_restaurant_b.png",
	"landmark_laden_a.png",
	"landmark_laden_b.png",
	"landmark_laden_c.png",
	"hub_station.png",
	"house_mfh.png",
	"house_flachdach.png",
	"house_reihen.png",
	"house_street_a.png",
	"house_street_b.png",
	"house_street_flachdach.png",
	"house_street_reihen.png",
	"house_street_a_ew.png",
	"house_street_a_ns.png",
	"house_street_b_ew.png",
	"house_street_b_ns.png",
	"house_street_flachdach_ew.png",
	"house_street_flachdach_ns.png",
	"house_street_reihen_ew.png",
	"house_street_reihen_ns.png",
]

## Preferred new geo-slice art (required once delivered).
const GEO_ART := [
	"landmark_kirche_st_martin.png",
	"landmark_sportplatz.png",
	"landmark_spielplatz.png",
	"landmark_turnhalle_birch.png",
	"landmark_turnhalle_rietacker.png",
	"landmark_wald_a.png",
	"landmark_wald_b.png",
]

const KIGA_IDS := [
	"kiga_bachtobel",
	"kiga_weid",
	"kiga_schneckenwiese",
	"kiga_ohringen",
]

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m3_world_landmarks_test start ===")

	for file_name in REQUIRED_ART:
		var path: String = ART + str(file_name)
		_assert(ResourceLoader.exists(path), "art exists %s" % file_name)

	for file_name in GEO_ART:
		var path: String = ART + str(file_name)
		_assert(ResourceLoader.exists(path), "geo art exists %s" % file_name)

	_assert_ns_house_art_not_rotate_of_ew()

	var packed: Variant = load("res://scenes/world_sandbox.tscn")
	_assert(packed is PackedScene, "world_sandbox.tscn loads")
	if not (packed is PackedScene):
		_finish()
		return

	var world: Node = (packed as PackedScene).instantiate()
	root.add_child(world)

	var props: Node2D = world.get_node_or_null("%Props")
	_assert(props != null, "Props node exists")
	if props == null:
		world.queue_free()
		_finish()
		return

	var all_sprites := _collect_sprites(props)
	var house_n := 0
	var forest_n := 0
	for spr in all_sprites:
		if spr.has_meta("house_variant"):
			house_n += 1
		if spr.has_meta("terrain") and str(spr.get_meta("terrain")) == "forest":
			forest_n += 1
	_assert(house_n >= 12, "spawn+corridor housing props present (got %d)" % house_n)
	_assert(forest_n >= 1, "forest silhouette props present (got %d)" % forest_n)

	_assert_landmark_scales(world, all_sprites)
	_assert_spawn_housing(world, all_sprites)
	_assert_corridor_housing(world, all_sprites)
	_assert_quartier_housing(world, all_sprites)
	_assert_street_facing_housing(world, all_sprites)
	_assert_bearing_aligned_housing(world, all_sprites)

	for cluster in ["rietacker", "ohringen"]:
		var n := _count_school_cluster(all_sprites, cluster)
		_assert(n >= 2, "school_cluster %s has >=2 props (got %d)" % [cluster, n])
	_assert_birch_campus(world, all_sprites)
	_assert_rietacker_campus(world, all_sprites)
	_assert_ohringen_campus(world, all_sprites)
	_assert_kiga_bachtobel(world, all_sprites)
	_assert_kiga_weid(world, all_sprites)
	_assert_kiga_schneckenwiese(world, all_sprites)
	_assert_kiga_ohringen(world, all_sprites)
	_assert_bahnhof(world, all_sprites)
	_assert_railway(world, all_sprites)
	_assert_badi(world, all_sprites)
	_assert_streams(world, all_sprites)
	_assert_forests(world, all_sprites)
	_assert_forest_silhouettes_off_roads(world, all_sprites)
	_assert_geo_quadrants(all_sprites)
	_assert_schools_off_roads(world, all_sprites)

	_assert_named_roads(world)
	_assert_field_scale()

	var ohringen: Node = props.get_node_or_null("DistrictOhringen")
	_assert(ohringen != null, "DistrictOhringen node exists")

	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground node exists")
	if ground:
		var hills := 0
		for node in _collect_nodes(ground):
			if node.has_meta("terrain") and str(node.get_meta("terrain")) == "hill":
				hills += 1
		_assert(hills == 0, "street map has no hill markers (got %d)" % hills)

	world.queue_free()
	_finish()


func _assert_named_roads(world: Node) -> void:
	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground for road markers")
	if ground == null:
		return
	var names: Dictionary = {}
	var classes: Dictionary = {}
	var widths: Dictionary = {}
	var winter_min_x := 1.0e9
	var stations_min_x := 1.0e9
	for node in _collect_nodes(ground):
		if not node.has_meta("road_name"):
			continue
		var n := str(node.get_meta("road_name"))
		names[n] = true
		if node.has_meta("road_class"):
			classes[str(node.get_meta("road_class"))] = true
		if node.has_meta("half_w"):
			widths[str(int(round(float(node.get_meta("half_w")))))] = true
		if n == "Winterthurerstrasse" or n == "Stationsstrasse":
			if node.has_meta("road_points"):
				var pts: PackedVector2Array = node.get_meta("road_points")
				for pt in pts:
					if n == "Winterthurerstrasse":
						winter_min_x = minf(winter_min_x, pt.x)
					else:
						stations_min_x = minf(stations_min_x, pt.x)
	for required in [
		"Winterthurerstrasse",
		"Landstrasse",
		"Ohringerstrasse",
		"Stationsstrasse",
		"Reutlingerstrasse",
		"Forrenbergstrasse",
		"Welsikonerstrasse",
		"Schaffhauserstrasse",
		"Rietstrasse",
		"Birchstrasse",
		"Kirchhügelstrasse",
		"A1",
	]:
		_assert(names.has(required), "road marker %s present" % required)
	_assert(classes.has("motorway"), "road_class motorway (A1)")
	_assert(classes.has("main"), "road_class main")
	_assert(classes.has("collector"), "road_class collector")
	_assert(classes.has("local"), "road_class local")
	_assert(widths.size() >= 3, "≥3 distinct road half_w (got %s)" % str(widths.keys()))
	if winter_min_x < 1.0e8 and stations_min_x < 1.0e8:
		_assert(
			winter_min_x < stations_min_x,
			"Winterthurerstrasse west of Stationsstrasse (wx=%.0f sx=%.0f)"
			% [winter_min_x, stations_min_x]
		)
	_assert(
		SeuzachGeo.bahnhof_world().x > 10000.0,
		"Bahnhof east of Kirche at field scale (x>10000, got %.0f)" % SeuzachGeo.bahnhof_world().x
	)
	_assert_road_reaches(ground, "Schaffhauserstrasse", -15000.0, 8000.0)
	_assert_road_reaches(ground, "A1", -800.0, 700.0)
	_assert_road_near(ground, "A1", SeuzachGeo.forrenberg_world(), 800.0)
	_assert_road_near(ground, "Stationsstrasse", SeuzachGeo.bahnhof_world(), 900.0)
	_assert_road_near(ground, "Winterthurerstrasse", SeuzachGeo.default_world_spawn(), 40.0)


func _assert_landmark_scales(world: Node, sprites: Array[Sprite2D]) -> void:
	## S01 globals + S02 Birch/Rietacker + S03 Ohringen + S04 Seuzach kiga + S05 Bahnhof/Badi mults.
	var world_script: Script = world.get_script()
	_assert(world_script != null, "world_sandbox script attached")
	if world_script == null:
		return
	var consts: Dictionary = world_script.get_script_constant_map()
	_assert(
		consts.get("SCHOOL_SCALE") == Vector2(0.50, 0.50),
		"SCHOOL_SCALE == (0.50, 0.50) (got %s)" % str(consts.get("SCHOOL_SCALE"))
	)
	_assert(
		consts.get("LANDMARK_SCALE") == Vector2(0.55, 0.55),
		"LANDMARK_SCALE == (0.55, 0.55) (got %s)" % str(consts.get("LANDMARK_SCALE"))
	)
	_assert(
		consts.get("HOUSE_SCALE") == Vector2(0.38, 0.38),
		"HOUSE_SCALE == (0.38, 0.38) (got %s)" % str(consts.get("HOUSE_SCALE"))
	)
	_assert(
		consts.get("FOREST_SCALE") == Vector2(0.24, 0.24),
		"FOREST_SCALE == (0.24, 0.24) (got %s)" % str(consts.get("FOREST_SCALE"))
	)
	_assert(
		is_equal_approx(float(consts.get("BUILDING_CLEAR_W_FRAC", 0.0)), 0.95),
		"BUILDING_CLEAR_W_FRAC == 0.95 (got %s)" % str(consts.get("BUILDING_CLEAR_W_FRAC"))
	)
	_assert(
		is_equal_approx(float(consts.get("BUILDING_CLEAR_H_FRAC", 0.0)), 0.88),
		"BUILDING_CLEAR_H_FRAC == 0.88 (got %s)" % str(consts.get("BUILDING_CLEAR_H_FRAC"))
	)
	_assert(
		is_equal_approx(float(consts.get("BUILDING_CLEAR_EDGE_MARGIN", 0.0)), 40.0),
		"BUILDING_CLEAR_EDGE_MARGIN == 40 (got %s)" % str(consts.get("BUILDING_CLEAR_EDGE_MARGIN"))
	)
	_assert(
		is_equal_approx(float(consts.get("HOUSE_CLEAR_W_FRAC", 0.0)), 0.70),
		"HOUSE_CLEAR_W_FRAC == 0.70 (got %s)" % str(consts.get("HOUSE_CLEAR_W_FRAC"))
	)
	_assert(
		is_equal_approx(float(consts.get("HOUSE_CLEAR_H_FRAC", 0.0)), 0.55),
		"HOUSE_CLEAR_H_FRAC == 0.55 (got %s)" % str(consts.get("HOUSE_CLEAR_H_FRAC"))
	)
	_assert(
		is_equal_approx(float(consts.get("HOUSE_CLEAR_EDGE_MARGIN", 0.0)), 12.0),
		"HOUSE_CLEAR_EDGE_MARGIN == 12 (got %s)" % str(consts.get("HOUSE_CLEAR_EDGE_MARGIN"))
	)
	_assert(
		is_equal_approx(float(consts.get("HOUSE_CURB_SLACK", 0.0)), 6.0),
		"HOUSE_CURB_SLACK == 6 (got %s)" % str(consts.get("HOUSE_CURB_SLACK"))
	)
	var school_scale: Vector2 = consts.get("SCHOOL_SCALE")
	var landmark_scale: Vector2 = consts.get("LANDMARK_SCALE")
	var forest_scale: Vector2 = consts.get("FOREST_SCALE")
	var birch_a_mult: float = float(consts.get("BIRCH_A_SCALE_MULT", 1.68))
	var birch_b_mult: float = float(consts.get("BIRCH_B_SCALE_MULT", 1.34))
	var birch_gym_mult: float = float(consts.get("BIRCH_TURNHALLE_SCALE_MULT", 2.22))
	var riet_a_mult: float = float(consts.get("RIETACKER_A_SCALE_MULT", 1.04))
	var riet_b_mult: float = float(consts.get("RIETACKER_B_SCALE_MULT", 1.21))
	var riet_gym_mult: float = float(consts.get("RIETACKER_TURNHALLE_SCALE_MULT", 2.62))
	var ohr_a_mult: float = float(consts.get("OHRINGEN_A_SCALE_MULT", 1.42))
	var ohr_b_mult: float = float(consts.get("OHRINGEN_B_SCALE_MULT", 1.28))
	var ohr_gym_mult: float = float(consts.get("OHRINGEN_TURNHALLE_SCALE_MULT", 1.21))
	var kiga_ohr_mult: float = float(consts.get("KIGA_OHRINGEN_SCALE_MULT", 0.78))
	var kiga_bt_mult: float = float(consts.get("KIGA_BACHTOBEL_SCALE_MULT", 1.00))
	var kiga_weid_mult: float = float(consts.get("KIGA_WEID_SCALE_MULT", 0.43))
	var kiga_sw_mult: float = float(consts.get("KIGA_SCHNECKENWIESE_SCALE_MULT", 1.12))
	var bahnhof_mult: float = float(consts.get("BAHNHOF_SCALE_MULT", 0.79))
	var badi_mult: float = float(consts.get("BADI_SCALE_MULT", 1.01))
	_assert(absf(birch_a_mult - 1.68) < 0.02, "BIRCH_A_SCALE_MULT ≈ 1.68 (got %.3f)" % birch_a_mult)
	_assert(absf(birch_b_mult - 1.34) < 0.02, "BIRCH_B_SCALE_MULT ≈ 1.34 (got %.3f)" % birch_b_mult)
	_assert(absf(birch_gym_mult - 2.22) < 0.02, "BIRCH_TURNHALLE_SCALE_MULT ≈ 2.22 (got %.3f)" % birch_gym_mult)
	_assert(absf(riet_a_mult - 1.04) < 0.02, "RIETACKER_A_SCALE_MULT ≈ 1.04 (got %.3f)" % riet_a_mult)
	_assert(absf(riet_b_mult - 1.21) < 0.02, "RIETACKER_B_SCALE_MULT ≈ 1.21 (got %.3f)" % riet_b_mult)
	_assert(absf(riet_gym_mult - 2.62) < 0.02, "RIETACKER_TURNHALLE_SCALE_MULT ≈ 2.62 (got %.3f)" % riet_gym_mult)
	_assert(absf(ohr_a_mult - 1.42) < 0.02, "OHRINGEN_A_SCALE_MULT ≈ 1.42 (got %.3f)" % ohr_a_mult)
	_assert(absf(ohr_b_mult - 1.28) < 0.02, "OHRINGEN_B_SCALE_MULT ≈ 1.28 (got %.3f)" % ohr_b_mult)
	_assert(absf(ohr_gym_mult - 1.21) < 0.02, "OHRINGEN_TURNHALLE_SCALE_MULT ≈ 1.21 (got %.3f)" % ohr_gym_mult)
	_assert(absf(kiga_ohr_mult - 0.78) < 0.02, "KIGA_OHRINGEN_SCALE_MULT ≈ 0.78 (got %.3f)" % kiga_ohr_mult)
	_assert(absf(kiga_bt_mult - 1.00) < 0.02, "KIGA_BACHTOBEL_SCALE_MULT ≈ 1.00 (got %.3f)" % kiga_bt_mult)
	_assert(absf(kiga_weid_mult - 0.43) < 0.02, "KIGA_WEID_SCALE_MULT ≈ 0.43 (got %.3f)" % kiga_weid_mult)
	_assert(absf(kiga_sw_mult - 1.12) < 0.02, "KIGA_SCHNECKENWIESE_SCALE_MULT ≈ 1.12 (got %.3f)" % kiga_sw_mult)
	_assert(absf(bahnhof_mult - 0.79) < 0.02, "BAHNHOF_SCALE_MULT ≈ 0.79 (got %.3f)" % bahnhof_mult)
	_assert(absf(badi_mult - 1.01) < 0.02, "BADI_SCALE_MULT ≈ 1.01 (got %.3f)" % badi_mult)

	var per_building_expected := {
		"schulhaus_birch_a": school_scale * birch_a_mult,
		"schulhaus_birch_b": school_scale * birch_b_mult,
		"turnhalle_birch": school_scale * birch_gym_mult,
		"schulhaus_rietacker_a": school_scale * riet_a_mult,
		"schulhaus_rietacker_b": school_scale * riet_b_mult,
		"turnhalle_rietacker": school_scale * riet_gym_mult,
		"schulhaus_ohringen_a": school_scale * ohr_a_mult,
		"schulhaus_ohringen_b": school_scale * ohr_b_mult,
		"turnhalle_ohringen": school_scale * ohr_gym_mult,
		"kiga_ohringen": school_scale * kiga_ohr_mult,
		"kiga_bachtobel": school_scale * kiga_bt_mult,
		"kiga_weid": school_scale * kiga_weid_mult,
		"kiga_schneckenwiese": school_scale * kiga_sw_mult,
	}
	var civic_expected := {
		"bahnhof": landmark_scale * bahnhof_mult,
		"badi_weiher": landmark_scale * badi_mult,
	}
	var school_building_n := 0
	var birch_rietacker_n := 0
	var ohringen_n := 0
	var seuzach_kiga_n := 0
	var civic_n := 0
	for spr in sprites:
		if not spr.has_meta("landmark_id"):
			continue
		var lid := str(spr.get_meta("landmark_id"))
		if spr.name in per_building_expected:
			var expected: Vector2 = per_building_expected[spr.name]
			_assert(
				spr.scale.is_equal_approx(expected),
				"%s scale == SCHOOL_SCALE * mult (got %s expect %s)"
				% [spr.name, str(spr.scale), str(expected)]
			)
			if spr.name in [
				"schulhaus_birch_a",
				"schulhaus_birch_b",
				"turnhalle_birch",
				"schulhaus_rietacker_a",
				"schulhaus_rietacker_b",
				"turnhalle_rietacker",
			]:
				birch_rietacker_n += 1
			elif spr.name in ["kiga_bachtobel", "kiga_weid", "kiga_schneckenwiese"]:
				seuzach_kiga_n += 1
			else:
				ohringen_n += 1
			school_building_n += 1
		elif spr.name in civic_expected:
			var civic_scale: Vector2 = civic_expected[spr.name]
			_assert(
				spr.scale.is_equal_approx(civic_scale),
				"%s scale == LANDMARK_SCALE * mult (got %s expect %s)"
				% [spr.name, str(spr.scale), str(civic_scale)]
			)
			civic_n += 1
		elif lid == "bahnhof" or lid == "badi_weiher":
			_assert(false, "civic landmark %s missing expected name for scale mult" % spr.name)
	_assert(birch_rietacker_n == 6, "6 Birch/Rietacker per-building scales (got %d)" % birch_rietacker_n)
	_assert(ohringen_n == 4, "4 Ohringen campus+kiga per-building scales (got %d)" % ohringen_n)
	_assert(seuzach_kiga_n == 3, "3 Seuzach kiga per-building scales (got %d)" % seuzach_kiga_n)
	_assert(school_building_n == 13, "9 campus + 4 kiga school buildings (got %d)" % school_building_n)
	_assert(civic_n == 2, "2 civic Bahnhof/Badi per-building scales (got %d)" % civic_n)
	_assert(_count_landmark(sprites, "bahnhof") == 1, "bahnhof present for scale check")
	_assert(_count_landmark(sprites, "badi_weiher") == 1, "badi present for scale check")
	## 9 school/gym + 4 kiga + bahnhof + badi = 15 building landmarks
	var building_n := school_building_n + _count_landmark(sprites, "bahnhof") + _count_landmark(
		sprites, "badi_weiher"
	)
	_assert(building_n == 15, "15 building landmarks present (got %d)" % building_n)

	var birch_a := _find_named_sprite(sprites, "schulhaus_birch_a")
	if birch_a == null:
		## Fallback: first birch schulhaus with ~1000px texture.
		for spr in sprites:
			if (
				spr.has_meta("landmark_id")
				and str(spr.get_meta("landmark_id")) == "schulhaus_birch"
				and spr.texture != null
				and spr.texture.get_height() >= 800
			):
				birch_a = spr
				break
	_assert(birch_a != null and birch_a.texture != null, "birch sample for visual height")
	if birch_a != null and birch_a.texture != null:
		_assert(
			birch_a.scale.is_equal_approx(school_scale * birch_a_mult),
			"birch sample scale == SCHOOL_SCALE * BIRCH_A_SCALE_MULT"
		)
		var tex_h := float(birch_a.texture.get_height())
		var visual_h := tex_h * absf(birch_a.scale.y)
		var expected_h := tex_h * absf((school_scale * birch_a_mult).y)
		_assert(
			visual_h >= expected_h * 0.85 and visual_h <= expected_h * 1.15,
			"birch visual height ≈ tex_h * SCHOOL_SCALE * BIRCH_A_SCALE_MULT ±15%% (got %.1f expect %.1f)"
			% [visual_h, expected_h]
		)

	var forest_checked := 0
	for spr in sprites:
		if spr.has_meta("terrain") and str(spr.get_meta("terrain")) == "forest":
			_assert(
				spr.scale.is_equal_approx(forest_scale),
				"forest %s scale == FOREST_SCALE (got %s)" % [spr.name, str(spr.scale)]
			)
			forest_checked += 1
	_assert(forest_checked >= 1, "at least one forest at FOREST_SCALE")


func _assert_spawn_housing(world: Node, sprites: Array[Sprite2D]) -> void:
	## S01: Winterthurer spawn-corridor houses visible at zoom 0.9; off asphalt; mixed variants.
	var world_script: Script = world.get_script()
	_assert(world_script != null, "world_sandbox script for HOUSE_SCALE")
	if world_script != null:
		var consts: Dictionary = world_script.get_script_constant_map()
		_assert(
			consts.get("HOUSE_SCALE") == Vector2(0.38, 0.38),
			"HOUSE_SCALE constant == (0.38, 0.38)"
		)
		_assert(
			consts.get("SCHOOL_SCALE") == Vector2(0.50, 0.50),
			"SCHOOL_SCALE unchanged with housing"
		)
		_assert(
			consts.get("LANDMARK_SCALE") == Vector2(0.55, 0.55),
			"LANDMARK_SCALE unchanged with housing"
		)
	var spawn := SeuzachGeo.default_world_spawn()
	_assert(
		spawn.is_equal_approx(Vector2(3861.9, -101.0)),
		"default spawn stays Winterthurer (3861.9, -101.0)"
	)
	_assert(
		SeuzachGeo.winterthurer_spawn().is_equal_approx(spawn),
		"winterthurer_spawn matches default_world_spawn"
	)
	var houses: Array[Sprite2D] = []
	var variants: Dictionary = {}
	for spr in sprites:
		if not spr.has_meta("house_variant"):
			continue
		houses.append(spr)
		variants[str(spr.get_meta("house_variant"))] = true
		_assert(
			spr.scale.is_equal_approx(Vector2(0.38, 0.38)),
			"%s scale == HOUSE_SCALE (got %s)" % [spr.name, str(spr.scale)]
		)
		_assert(is_zero_approx(spr.rotation), "%s rotation is 0" % spr.name)
		_assert(
			spr.has_meta("has_building_collision") and bool(spr.get_meta("has_building_collision")),
			"%s has BuildingCollision" % spr.name
		)
		_assert_sprite_off_named_roads(world, spr)
	_assert(houses.size() >= 6, "≥6 housing props near spawn corridor (got %d)" % houses.size())
	_assert(variants.size() >= 2, "≥2 distinct house_variant values (got %d)" % variants.size())
	var view := _spawn_viewport_rect(spawn, Vector2(0.9, 0.9))
	var in_view := 0
	for spr in houses:
		if _sprite_hits_rect(spr, view):
			in_view += 1
	_assert(
		in_view >= 3,
		"≥3 houses intersect spawn viewport @ zoom 0.9 (got %d)" % in_view
	)


func _assert_corridor_housing(world: Node, sprites: Array[Sprite2D]) -> void:
	## Kirche + Reutlinger + spawn: bearing-suffixed house_street_* only.
	## Corridor tags remain for facing suite; quarters also set housing_quartier.
	var kirche_n := 0
	var reut_mitte_n := 0
	var reut_se_n := 0
	var spawn_n := 0
	var street_variants: Dictionary = {}
	var bases := {
		"house_street_a": true,
		"house_street_b": true,
		"house_street_flachdach": true,
		"house_street_reihen": true,
	}
	for spr in sprites:
		if not spr.has_meta("house_variant"):
			continue
		if not spr.has_meta("housing_corridor"):
			continue
		var variant := str(spr.get_meta("house_variant"))
		_assert(
			variant.ends_with("_ew") or variant.ends_with("_ns"),
			"%s house_variant has bearing suffix (got %s)" % [spr.name, variant]
		)
		var base := variant.trim_suffix("_ew").trim_suffix("_ns")
		_assert(
			bases.has(base),
			"%s house_variant base is street-ribbon (got %s)" % [spr.name, variant]
		)
		_assert(
			variant != base,
			"%s must not use unprefixed house_street_* (got %s)" % [spr.name, variant]
		)
		street_variants[variant] = true
		var corridor := str(spr.get_meta("housing_corridor"))
		match corridor:
			"kirche":
				kirche_n += 1
				_assert(
					spr.has_meta("housing_quartier")
					and str(spr.get_meta("housing_quartier")) == "KIRCHE-KERN",
					"%s kirche corridor maps to KIRCHE-KERN quartier" % spr.name
				)
			"reut-mitte":
				reut_mitte_n += 1
				_assert(
					spr.has_meta("housing_quartier")
					and str(spr.get_meta("housing_quartier")) == "REUT-MITTE",
					"%s reut-mitte corridor maps to REUT-MITTE quartier" % spr.name
				)
			"reut-se":
				reut_se_n += 1
				_assert(
					spr.has_meta("housing_quartier")
					and str(spr.get_meta("housing_quartier")) == "REUT-SE",
					"%s reut-se corridor maps to REUT-SE quartier" % spr.name
				)
			"spawn":
				spawn_n += 1
				_assert(
					spr.has_meta("housing_quartier")
					and str(spr.get_meta("housing_quartier")) == "WINT-WEST",
					"%s spawn corridor maps to WINT-WEST quartier" % spr.name
				)
			"wint-nord":
				_assert(
					spr.has_meta("housing_quartier")
					and str(spr.get_meta("housing_quartier")) == "WINT-NORD",
					"%s wint-nord corridor maps to WINT-NORD quartier" % spr.name
				)
			"land-mitte":
				_assert(
					spr.has_meta("housing_quartier")
					and str(spr.get_meta("housing_quartier")) == "LAND-MITTE",
					"%s land-mitte corridor maps to LAND-MITTE quartier" % spr.name
				)
			"stat-west":
				_assert(
					spr.has_meta("housing_quartier")
					and str(spr.get_meta("housing_quartier")) == "STAT-WEST",
					"%s stat-west corridor maps to STAT-WEST quartier" % spr.name
				)
			"stat-bhf":
				_assert(
					spr.has_meta("housing_quartier")
					and str(spr.get_meta("housing_quartier")) == "STAT-BHF",
					"%s stat-bhf corridor maps to STAT-BHF quartier" % spr.name
				)
			_:
				_assert(false, "unexpected housing_corridor meta '%s'" % corridor)
		_assert(
			spr.scale.is_equal_approx(Vector2(0.38, 0.38)),
			"%s corridor house scale == HOUSE_SCALE" % spr.name
		)
		_assert(is_zero_approx(spr.rotation), "%s building rotation stays 0" % spr.name)
		_assert_sprite_off_named_roads(world, spr)
	_assert(spawn_n >= 3, "≥3 S01 spawn-corridor houses (got %d)" % spawn_n)
	_assert(kirche_n >= 4, "≥4 Kirche-corridor houses (got %d)" % kirche_n)
	_assert(reut_mitte_n >= 4, "≥4 reut-mitte-corridor houses (got %d)" % reut_mitte_n)
	_assert(reut_se_n >= 4, "≥4 reut-se-corridor houses (got %d)" % reut_se_n)
	_assert(
		kirche_n + reut_mitte_n + reut_se_n + spawn_n >= 15,
		"≥15 total tagged housing props (got %d)"
		% (kirche_n + reut_mitte_n + reut_se_n + spawn_n)
	)
	_assert(
		street_variants.size() >= 2,
		"≥2 distinct house_street_* variants (got %d)" % street_variants.size()
	)


func _assert_quartier_housing(_world: Node, sprites: Array[Sprite2D]) -> void:
	## S01–S04 F1 quarter cells: registry, counts in bounds, no double-stack.
	var reg: Dictionary = HousingQuarters.REGISTRY
	_assert(reg.size() == 8, "S01–S04 registry has exactly 8 quarters (got %d)" % reg.size())
	_assert(reg.has("KIRCHE-KERN"), "registry has KIRCHE-KERN")
	_assert(reg.has("WINT-WEST"), "registry has WINT-WEST")
	_assert(reg.has("WINT-NORD"), "registry has WINT-NORD")
	_assert(reg.has("LAND-MITTE"), "registry has LAND-MITTE")
	_assert(reg.has("STAT-WEST"), "registry has STAT-WEST")
	_assert(reg.has("STAT-BHF"), "registry has STAT-BHF")
	_assert(reg.has("REUT-MITTE"), "registry has REUT-MITTE")
	_assert(reg.has("REUT-SE"), "registry has REUT-SE")
	var s01: Array[String] = HousingQuarters.s01_ids()
	_assert(s01.size() == 2, "s01_ids size == 2")
	var s02: Array[String] = HousingQuarters.s02_ids()
	_assert(s02.size() == 2, "s02_ids size == 2")
	var s03: Array[String] = HousingQuarters.s03_ids()
	_assert(s03.size() == 2, "s03_ids size == 2")
	var s04: Array[String] = HousingQuarters.s04_ids()
	_assert(s04.size() == 2, "s04_ids size == 2")
	_assert(
		HousingQuarters.active_ids().size() == 8,
		"active_ids includes S01–S04 (got %d)" % HousingQuarters.active_ids().size()
	)
	_assert(
		HousingQuarters.quarter_contains_world("WINT-WEST", SeuzachGeo.winterthurer_spawn()),
		"Winterthurer spawn cell is inside WINT-WEST"
	)
	_assert(
		HousingQuarters.quarter_contains_world("STAT-BHF", SeuzachGeo.bahnhof_world()),
		"Bahnhof cell is inside STAT-BHF"
	)
	_assert(
		HousingQuarters.quarter_contains_world(
			"REUT-MITTE", SeuzachGeo.kiga_schneckenwiese_world()
		),
		"Kiga Schneckenwiese cell is inside REUT-MITTE"
	)
	_assert(
		str(reg["WINT-NORD"].get("roads", [])).contains("Winterthurerstrasse"),
		"WINT-NORD roads include Winterthurerstrasse"
	)
	_assert(
		str(reg["LAND-MITTE"].get("roads", [])).contains("Landstrasse"),
		"LAND-MITTE roads include Landstrasse"
	)
	_assert(
		str(reg["STAT-WEST"].get("roads", [])).contains("Stationsstrasse"),
		"STAT-WEST roads include Stationsstrasse"
	)
	_assert(
		str(reg["STAT-BHF"].get("roads", [])).contains("Stationsstrasse"),
		"STAT-BHF roads include Stationsstrasse"
	)
	_assert(
		str(reg["REUT-MITTE"].get("roads", [])).contains("Reutlingerstrasse"),
		"REUT-MITTE roads include Reutlingerstrasse"
	)
	_assert(
		str(reg["REUT-MITTE"].get("roads", [])).contains("Schneckenwiesenstrasse"),
		"REUT-MITTE roads include Schneckenwiesenstrasse"
	)
	_assert(
		str(reg["REUT-SE"].get("roads", [])).contains("Reutlingerstrasse"),
		"REUT-SE roads include Reutlingerstrasse"
	)

	var allowed_q := {
		"KIRCHE-KERN": true,
		"WINT-WEST": true,
		"WINT-NORD": true,
		"LAND-MITTE": true,
		"STAT-WEST": true,
		"STAT-BHF": true,
		"REUT-MITTE": true,
		"REUT-SE": true,
	}
	var counts := {
		"KIRCHE-KERN": 0,
		"WINT-WEST": 0,
		"WINT-NORD": 0,
		"LAND-MITTE": 0,
		"STAT-WEST": 0,
		"STAT-BHF": 0,
		"REUT-MITTE": 0,
		"REUT-SE": 0,
	}
	var houses: Array[Sprite2D] = []
	var bahnhof := _find_landmark(sprites, "bahnhof")
	_assert(bahnhof != null, "bahnhof landmark present for STAT clearance")
	var kiga_sw := _find_named(sprites, "kiga_schneckenwiese")
	_assert(kiga_sw != null, "kiga_schneckenwiese present for REUT clearance")
	var min_landmark_sep := 320.0
	for spr in sprites:
		if not spr.has_meta("house_variant"):
			continue
		houses.append(spr)
		if not spr.has_meta("housing_quartier"):
			continue
		var qid := str(spr.get_meta("housing_quartier"))
		_assert(allowed_q.has(qid), "%s unexpected housing_quartier '%s'" % [spr.name, qid])
		## Final curb offset may land ±1 field outside the sample rect.
		var cell: Vector2i = HousingQuarters.world_to_cell(spr.position)
		var bounds: Dictionary = HousingQuarters.field_bounds(qid)
		var loose := {
			"ix_min": int(bounds["ix_min"]) - 1,
			"ix_max": int(bounds["ix_max"]) + 1,
			"iy_min": int(bounds["iy_min"]) - 1,
			"iy_max": int(bounds["iy_max"]) + 1,
		}
		_assert(
			HousingQuarters.cell_in_bounds(cell, loose),
			"%s cell %s outside %s (±1)" % [spr.name, str(cell), qid]
		)
		counts[qid] = int(counts[qid]) + 1
		if bahnhof != null and (qid == "STAT-WEST" or qid == "STAT-BHF"):
			_assert(
				spr.position.distance_to(bahnhof.position) >= min_landmark_sep - 1.0,
				"%s too close to bahnhof (d=%.1f, need ≥%.0f)"
				% [spr.name, spr.position.distance_to(bahnhof.position), min_landmark_sep]
			)
		if kiga_sw != null and (qid == "REUT-MITTE" or qid == "REUT-SE"):
			_assert(
				spr.position.distance_to(kiga_sw.position) >= min_landmark_sep - 1.0,
				"%s too close to kiga_schneckenwiese (d=%.1f, need ≥%.0f)"
				% [spr.name, spr.position.distance_to(kiga_sw.position), min_landmark_sep]
			)
	_assert(int(counts["KIRCHE-KERN"]) >= 4, "≥4 KIRCHE-KERN housing props (got %d)" % counts["KIRCHE-KERN"])
	_assert(int(counts["WINT-WEST"]) >= 4, "≥4 WINT-WEST housing props (got %d)" % counts["WINT-WEST"])
	_assert(int(counts["WINT-NORD"]) >= 4, "≥4 WINT-NORD housing props (got %d)" % counts["WINT-NORD"])
	_assert(int(counts["LAND-MITTE"]) >= 4, "≥4 LAND-MITTE housing props (got %d)" % counts["LAND-MITTE"])
	_assert(int(counts["STAT-WEST"]) >= 4, "≥4 STAT-WEST housing props (got %d)" % counts["STAT-WEST"])
	_assert(int(counts["STAT-BHF"]) >= 4, "≥4 STAT-BHF housing props (got %d)" % counts["STAT-BHF"])
	_assert(int(counts["REUT-MITTE"]) >= 4, "≥4 REUT-MITTE housing props (got %d)" % counts["REUT-MITTE"])
	_assert(int(counts["REUT-SE"]) >= 4, "≥4 REUT-SE housing props (got %d)" % counts["REUT-SE"])
	_assert(_count_landmark(sprites, "bahnhof") == 1, "bahnhof landmark count stays 1")
	_assert(
		_count_landmark(sprites, "kiga_schneckenwiese") == 1,
		"kiga_schneckenwiese landmark count stays 1"
	)

	## Shared placed[]: no pairwise stack closer than placement min_house_sep.
	var min_sep := 200.0
	var closest := 1.0e9
	for i in range(houses.size()):
		for j in range(i + 1, houses.size()):
			var d: float = houses[i].position.distance_to(houses[j].position)
			if d < closest:
				closest = d
	_assert(
		houses.size() < 2 or closest >= min_sep - 1.0,
		"no double-stack housing (min pairwise sep=%.1f, need ≥%.0f)" % [closest, min_sep]
	)


func _assert_street_facing_housing(world: Node, sprites: Array[Sprite2D]) -> void:
	## Side-aware flip_h on NS (Winterthurer _ns) and EW (Kirchgasse/Reutlinger _ew) samples.
	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground for street-facing housing")
	if ground == null:
		return
	var roads_by_name: Dictionary = {} ## name -> Array[Dictionary]
	for node in _collect_nodes(ground):
		if not node.has_meta("road_name") or not node.has_meta("road_points"):
			continue
		var rname := str(node.get_meta("road_name"))
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		if pts.size() < 2:
			continue
		if not roads_by_name.has(rname):
			roads_by_name[rname] = []
		roads_by_name[rname].append({"name": rname, "points": pts})
	_assert(roads_by_name.has("Winterthurerstrasse"), "Winterthurerstrasse for NS facing")
	_assert(
		roads_by_name.has("Kirchgasse") or roads_by_name.has("Reutlingerstrasse"),
		"Kirchgasse or Reutlingerstrasse for EW facing"
	)

	## Spawn corridor: both sides + majority flip consistency (often _ns on Winterthurer).
	var winter_roads: Array[Dictionary] = _road_list_named(roads_by_name, ["Winterthurerstrasse"])
	var side_pos_n := 0
	var side_neg_n := 0
	var flip_true_on_pos := 0
	var flip_false_on_pos := 0
	var flip_true_on_neg := 0
	var flip_false_on_neg := 0
	var tagged := 0
	var ns_flip_checked := 0
	for spr in sprites:
		if not spr.has_meta("house_variant"):
			continue
		if not spr.has_meta("housing_corridor"):
			continue
		if str(spr.get_meta("housing_corridor")) != "spawn":
			continue
		_assert(spr.has_meta("street_side"), "%s has street_side meta" % spr.name)
		_assert(spr.has_meta("faces_street"), "%s has faces_street meta" % spr.name)
		_assert(bool(spr.get_meta("faces_street")), "%s faces_street == true" % spr.name)
		_assert(is_zero_approx(spr.rotation), "%s rotation stays 0 (no iso break)" % spr.name)
		var side := int(spr.get_meta("street_side"))
		_assert(side == 1 or side == -1, "%s street_side is ±1 (got %d)" % [spr.name, side])
		tagged += 1
		if side == 1:
			side_pos_n += 1
			if spr.flip_h:
				flip_true_on_pos += 1
			else:
				flip_false_on_pos += 1
		else:
			side_neg_n += 1
			if spr.flip_h:
				flip_true_on_neg += 1
			else:
				flip_false_on_neg += 1
		var variant := str(spr.get_meta("house_variant"))
		var roads_for_spr := _roads_for_housing_sprite(spr, roads_by_name, winter_roads)
		var nearest := _nearest_road_sample(spr.position, roads_for_spr)
		_assert(nearest.has("tangent"), "%s finds nearest corridor sample" % spr.name)
		if not nearest.has("tangent"):
			continue
		_assert_flip_matches_bearing(spr, variant, side, nearest)
		if variant.ends_with("_ns"):
			ns_flip_checked += 1
	_assert(tagged >= 3, "≥3 spawn-corridor houses with street_side (got %d)" % tagged)
	_assert(side_pos_n >= 1, "spawn corridor has street_side +1 (got %d)" % side_pos_n)
	_assert(side_neg_n >= 1, "spawn corridor has street_side -1 (got %d)" % side_neg_n)
	_assert(ns_flip_checked >= 1, "≥1 spawn _ns house with W/E flip assert (got %d)" % ns_flip_checked)
	if side_pos_n > 2:
		_assert(
			maxi(flip_true_on_pos, flip_false_on_pos) * 2 > side_pos_n,
			"spawn +1 side: clear majority flip_h (true=%d false=%d)"
			% [flip_true_on_pos, flip_false_on_pos]
		)
	if side_neg_n > 2:
		_assert(
			maxi(flip_true_on_neg, flip_false_on_neg) * 2 > side_neg_n,
			"spawn -1 side: clear majority flip_h (true=%d false=%d)"
			% [flip_true_on_neg, flip_false_on_neg]
		)

	## E–W corridor sample: Kirchgasse / Reutlinger _ew houses use SW/SE door dirs.
	var ew_roads: Array[Dictionary] = _road_list_named(
		roads_by_name, ["Kirchgasse", "Kirchhügelstrasse", "Reutlingerstrasse"]
	)
	var ew_flip_checked := 0
	for spr in sprites:
		if not spr.has_meta("house_variant") or not spr.has_meta("housing_corridor"):
			continue
		var variant := str(spr.get_meta("house_variant"))
		if not variant.ends_with("_ew"):
			continue
		var corridor := str(spr.get_meta("housing_corridor"))
		if corridor != "kirche" and corridor != "reut-mitte" and corridor != "reut-se":
			continue
		_assert(spr.has_meta("street_side"), "%s has street_side" % spr.name)
		_assert(is_zero_approx(spr.rotation), "%s rotation == 0" % spr.name)
		var side_ew := int(spr.get_meta("street_side"))
		var roads_for_ew := _roads_for_housing_sprite(spr, roads_by_name, ew_roads)
		var nearest_ew := _nearest_road_sample(spr.position, roads_for_ew)
		if not nearest_ew.has("tangent"):
			continue
		var t_ew: Vector2 = nearest_ew["tangent"]
		## Only assert SW/SE when the sampled segment is actually E–W-ish.
		if absf(t_ew.x) < absf(t_ew.y):
			continue
		_assert_flip_matches_bearing(spr, variant, side_ew, nearest_ew)
		ew_flip_checked += 1
	_assert(ew_flip_checked >= 2, "≥2 E–W corridor _ew flip asserts (got %d)" % ew_flip_checked)

	for spr in sprites:
		if not spr.has_meta("street_side"):
			continue
		if not spr.has_meta("house_variant"):
			continue
		_assert(
			spr.has_meta("faces_street") and bool(spr.get_meta("faces_street")),
			"%s faces_street true" % spr.name
		)
		_assert(spr.has_meta("housing_corridor"), "%s keeps housing_corridor" % spr.name)
		_assert(spr.has_meta("house_variant"), "%s keeps house_variant" % spr.name)


func _road_list_named(roads_by_name: Dictionary, names: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n in names:
		var key := str(n)
		if not roads_by_name.has(key):
			continue
		for road in roads_by_name[key]:
			out.append(road)
	return out


func _roads_for_housing_sprite(
	spr: Sprite2D, roads_by_name: Dictionary, fallback: Array[Dictionary]
) -> Array[Dictionary]:
	## Prefer the placement street_name (all polylines with that name); else corridor set.
	if spr.has_meta("street_name"):
		var sname := str(spr.get_meta("street_name"))
		var named := _road_list_named(roads_by_name, [sname])
		if not named.is_empty():
			return named
	var corridor := str(spr.get_meta("housing_corridor")) if spr.has_meta("housing_corridor") else ""
	var names: Array = []
	match corridor:
		"spawn":
			names = ["Winterthurerstrasse"]
		"kirche":
			names = ["Kirchgasse", "Kirchhügelstrasse", "Winterthurerstrasse"]
		"reut-mitte":
			names = [
				"Reutlingerstrasse",
				"Schneckenwiesenstrasse",
				"Eibenstrasse",
				"Gartenstrasse",
				"Oberwiesenstrasse",
				"Schwalbenweg",
				"Seestrasse",
			]
		"reut-se":
			names = [
				"Reutlingerstrasse",
				"Birchweg",
				"Buchenstrasse",
				"Gartenstrasse",
				"Handschüsselweg",
				"Oberwiesenstrasse",
				"Schwalbenweg",
				"Seestrasse",
			]
		"wint-nord":
			names = ["Winterthurerstrasse"]
		"land-mitte":
			names = ["Landstrasse"]
		"stat-west":
			names = ["Stationsstrasse", "Strehlgasse", "Stadlerstrasse"]
		"stat-bhf":
			names = ["Stationsstrasse", "Stadlerstrasse"]
		_:
			return fallback
	var out := _road_list_named(roads_by_name, names)
	return out if not out.is_empty() else fallback


func _assert_flip_matches_bearing(
	spr: Sprite2D, variant: String, side: int, nearest: Dictionary
) -> void:
	## Match placement: toward asphalt via side × segment perp (same as world_sandbox).
	if not nearest.has("tangent"):
		return
	var tangent: Vector2 = nearest["tangent"]
	var perp := Vector2(-tangent.y, tangent.x)
	if perp.length_squared() < 0.0001:
		return
	perp = perp.normalized()
	var toward_road := (-perp * float(side)).normalized()
	var door_no_flip: Vector2
	var door_flip: Vector2
	if variant.ends_with("_ns"):
		door_no_flip = Vector2(-1.0, 0.0)
		door_flip = Vector2(1.0, 0.0)
	else:
		door_no_flip = Vector2(-1.0, 1.0).normalized()
		door_flip = Vector2(1.0, 1.0).normalized()
	var expect_flip := door_flip.dot(toward_road) > door_no_flip.dot(toward_road)
	_assert(
		spr.flip_h == expect_flip,
		"%s flip_h matches side-aware rule (got %s expect %s side=%d variant=%s)"
		% [spr.name, str(spr.flip_h), str(expect_flip), side, variant]
	)


func _assert_bearing_aligned_housing(world: Node, sprites: Array[Sprite2D]) -> void:
	## ≥80% of corridor houses use _ew/_ns matching their placement corridor road tangent.
	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground for bearing-aligned housing")
	if ground == null:
		return
	var roads_by_name: Dictionary = {}
	for node in _collect_nodes(ground):
		if not node.has_meta("road_name") or not node.has_meta("road_points"):
			continue
		var rname := str(node.get_meta("road_name"))
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		if pts.size() < 2:
			continue
		if not roads_by_name.has(rname):
			roads_by_name[rname] = []
		roads_by_name[rname].append({"name": rname, "points": pts})
	_assert(roads_by_name.size() >= 1, "corridor polylines for bearing match")

	var all_corridor: Array[Dictionary] = _road_list_named(
		roads_by_name,
		[
			"Winterthurerstrasse",
			"Kirchgasse",
			"Kirchhügelstrasse",
			"Reutlingerstrasse",
			"Schneckenwiesenstrasse",
		]
	)

	var total := 0
	var matched := 0
	for spr in sprites:
		if not spr.has_meta("house_variant"):
			continue
		if not spr.has_meta("housing_corridor"):
			continue
		var variant := str(spr.get_meta("house_variant"))
		_assert(
			variant.ends_with("_ew") or variant.ends_with("_ns"),
			"%s bearing suffix on house_variant" % spr.name
		)
		_assert(is_zero_approx(spr.rotation), "%s rotation == 0" % spr.name)
		total += 1
		var roads_for_spr := _roads_for_housing_sprite(spr, roads_by_name, all_corridor)
		var nearest := _nearest_road_sample(spr.position, roads_for_spr)
		if not nearest.has("tangent"):
			continue
		var t: Vector2 = nearest["tangent"]
		var expect := "ew" if absf(t.x) >= absf(t.y) else "ns"
		if variant.ends_with("_" + expect):
			matched += 1
		if spr.has_meta("street_bearing"):
			_assert(
				variant.ends_with("_" + str(spr.get_meta("street_bearing"))),
				"%s street_bearing matches house_variant suffix" % spr.name
			)
	_assert(total >= 15, "≥15 corridor houses for bearing match (got %d)" % total)
	_assert(
		float(matched) / float(maxi(total, 1)) >= 0.80,
		"≥80%% corridor houses match road-tangent bearing (matched %d / %d)"
		% [matched, total]
	)


func _nearest_road_sample(p: Vector2, roads: Array[Dictionary]) -> Dictionary:
	var best_d := 1.0e9
	var best := {}
	for road in roads:
		var pts: PackedVector2Array = road["points"]
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var seg := b - a
			var seg_len_sq := seg.length_squared()
			if seg_len_sq < 0.0001:
				continue
			var t := clampf((p - a).dot(seg) / seg_len_sq, 0.0, 1.0)
			var closest := a + seg * t
			var d := p.distance_to(closest)
			if d < best_d:
				best_d = d
				best = {"point": closest, "tangent": seg.normalized(), "dist": d}
	return best


func _spawn_viewport_rect(center: Vector2, zoom: Vector2) -> Rect2:
	var screen := Vector2(1280.0, 720.0)
	var world_size := Vector2(screen.x / maxf(zoom.x, 0.01), screen.y / maxf(zoom.y, 0.01))
	return Rect2(center - world_size * 0.5, world_size)


func _sprite_hits_rect(spr: Sprite2D, rect: Rect2) -> bool:
	if rect.has_point(spr.position):
		return true
	if spr.texture == null:
		return false
	var tex_w := float(spr.texture.get_width()) * absf(spr.scale.x)
	var tex_h := float(spr.texture.get_height()) * absf(spr.scale.y)
	## Feet pivot at position; sprite extends upward (negative local Y via offset).
	var top_left := spr.position + Vector2(-tex_w * 0.5, -tex_h)
	var spr_rect := Rect2(top_left, Vector2(tex_w, tex_h))
	return spr_rect.intersects(rect)


func _find_named_sprite(sprites: Array[Sprite2D], node_name: String) -> Sprite2D:
	for spr in sprites:
		if spr.name == node_name:
			return spr
	return null


func _assert_field_scale() -> void:
	var ns := SeuzachGeo.village_ns_fields()
	var ew := SeuzachGeo.village_ew_fields()
	_assert(ns >= 307.0 and ns <= 327.0, "Seuzach N–S ≈ 317 Felder (got %.1f)" % ns)
	_assert(ew >= 281.0 and ew <= 301.0, "Seuzach E–W ≈ 291 Felder (got %.1f)" % ew)
	_assert(is_equal_approx(SeuzachGeo.FIELD_METERS, 5.3), "1 Feld = 5,3 m")
	_assert(is_equal_approx(SeuzachGeo.FIELD_WU, 100.0), "1 Feld = 100 wu")
	var church := SeuzachGeo.gps_to_world(SeuzachGeo.CHURCH_LAT, SeuzachGeo.CHURCH_LON)
	_assert(church.length() < 0.5, "Kirche is world origin (got %s)" % str(church))
	var spawn := SeuzachGeo.default_world_spawn()
	var ix := int(floor(spawn.x / SeuzachGeo.FIELD_WU))
	var iy := int(floor(spawn.y / SeuzachGeo.FIELD_WU))
	_assert(
		spawn.is_equal_approx(Vector2(3861.9, -101.0)),
		"default_world_spawn is Winterthurer vertex (got %s)" % str(spawn)
	)
	_assert(ix >= 30 and ix <= 45 and iy >= -15 and iy <= 10, "spawn Feld (%d,%d) in WINT-KERN" % [ix, iy])
	_assert(SeuzachGeo.WORLD_BOUNDS.has_point(spawn), "default spawn inside WORLD_BOUNDS")
	_assert(
		spawn.distance_to(SeuzachGeo.forrenberg_world() + Vector2(0.0, 200.0)) > 40.0,
		"default spawn is not Forrenberg + (0, 200)"
	)


func _assert_road_reaches(ground: Node, road_name: String, x_lt: float, y_gt: float) -> void:
	var hit := false
	var saw := false
	for node in _collect_nodes(ground):
		if not node.has_meta("road_name") or str(node.get_meta("road_name")) != road_name:
			continue
		if not node.has_meta("road_points"):
			_assert(false, "%s has road_points meta" % road_name)
			return
		saw = true
		var pts: PackedVector2Array = node.get_meta("road_points")
		for pt in pts:
			if pt.x < x_lt and pt.y > y_gt:
				hit = true
				break
		if hit:
			break
	_assert(saw, "%s marker for reach check" % road_name)
	_assert(
		hit,
		"%s reaches Maps west/south (x<%.0f y>%.0f)" % [road_name, x_lt, y_gt]
	)


func _assert_road_near(ground: Node, road_name: String, target: Vector2, max_dist: float) -> void:
	var best := 1.0e9
	var saw := false
	for node in _collect_nodes(ground):
		if not node.has_meta("road_name") or str(node.get_meta("road_name")) != road_name:
			continue
		if not node.has_meta("road_points"):
			_assert(false, "%s has road_points meta" % road_name)
			return
		saw = true
		var pts: PackedVector2Array = node.get_meta("road_points")
		best = minf(best, _dist_to_polyline(target, pts))
	_assert(saw, "%s marker for near check" % road_name)
	_assert(
		best <= max_dist,
		"%s passes near %s (got %.0f, want ≤%.0f)" % [road_name, str(target), best, max_dist]
	)


func _assert_birch_campus(world: Node, sprites: Array[Sprite2D]) -> void:
	var a := _find_named(sprites, "schulhaus_birch_a")
	var b := _find_named(sprites, "schulhaus_birch_b")
	var gym := _find_named(sprites, "turnhalle_birch")
	_assert(a != null, "node schulhaus_birch_a exists")
	_assert(b != null, "node schulhaus_birch_b exists")
	_assert(gym != null, "node turnhalle_birch exists")
	_assert(
		is_equal_approx(SeuzachGeo.BIRCH_LAT, 47.5353419)
		and is_equal_approx(SeuzachGeo.BIRCH_LON, 8.7362524),
		"birch_world() GPS constants unchanged"
	)
	_assert(
		SeuzachGeo.birch_world().is_equal_approx(
			SeuzachGeo.gps_to_world(SeuzachGeo.BIRCH_LAT, SeuzachGeo.BIRCH_LON)
		),
		"birch_world() still maps BIRCH_LAT/LON"
	)
	_assert(
		is_equal_approx(SeuzachGeo.BIRCH_SCHULHAUS_A_LAT, 47.5352696)
		and is_equal_approx(SeuzachGeo.BIRCH_SCHULHAUS_A_LON, 8.7368319)
		and is_equal_approx(SeuzachGeo.BIRCH_SCHULHAUS_B_LAT, 47.5351495)
		and is_equal_approx(SeuzachGeo.BIRCH_SCHULHAUS_B_LON, 8.7362716)
		and is_equal_approx(SeuzachGeo.BIRCH_TURNHALLE_LAT, 47.5354751)
		and is_equal_approx(SeuzachGeo.BIRCH_TURNHALLE_LON, 8.7362554),
		"Birch building GPS constants match S01 OSM table"
	)
	_assert(
		SeuzachGeo.birch_schulhaus_a_world().distance_to(
			SeuzachGeo.birch_world() + Vector2(821.8, 151.9)
		) < 1.0,
		"birch_a offset vs yard ≈ (821.8, 151.9)"
	)
	_assert(
		SeuzachGeo.birch_schulhaus_b_world().distance_to(
			SeuzachGeo.birch_world() + Vector2(27.2, 404.1)
		) < 1.0,
		"birch_b offset vs yard ≈ (27.2, 404.1)"
	)
	_assert(
		SeuzachGeo.birch_turnhalle_world().distance_to(
			SeuzachGeo.birch_world() + Vector2(4.3, -279.8)
		) < 1.0,
		"birch turnhalle offset vs yard ≈ (4.3, -279.8)"
	)
	var birch_n := _count_school_cluster(sprites, "birch")
	_assert(birch_n == 3, "school_cluster birch has exactly 3 props (got %d)" % birch_n)
	if a == null or b == null or gym == null:
		return
	_assert(
		str(a.get_meta("landmark_id")) == "schulhaus_birch"
		and str(a.get_meta("school_cluster")) == "birch"
		and str(a.get_meta("district")) == "birch",
		"schulhaus_birch_a metas"
	)
	_assert(
		str(b.get_meta("landmark_id")) == "schulhaus_birch"
		and str(b.get_meta("school_cluster")) == "birch"
		and str(b.get_meta("district")) == "birch",
		"schulhaus_birch_b metas"
	)
	_assert(
		str(gym.get_meta("landmark_id")) == "turnhalle_birch"
		and str(gym.get_meta("school_cluster")) == "birch"
		and str(gym.get_meta("district")) == "birch"
		and str(gym.get_meta("poi_type")) == "gym",
		"turnhalle_birch metas"
	)
	_assert(
		a.position.distance_to(SeuzachGeo.birch_schulhaus_a_world()) <= 720.0,
		"schulhaus_birch_a within 720 wu of OSM getter (d=%.1f)"
		% a.position.distance_to(SeuzachGeo.birch_schulhaus_a_world())
	)
	_assert(
		b.position.distance_to(SeuzachGeo.birch_schulhaus_b_world()) <= 720.0,
		"schulhaus_birch_b within 720 wu of OSM getter (d=%.1f)"
		% b.position.distance_to(SeuzachGeo.birch_schulhaus_b_world())
	)
	_assert(
		gym.position.distance_to(SeuzachGeo.birch_turnhalle_world()) <= 720.0,
		"turnhalle_birch within 720 wu of OSM getter (d=%.1f)"
		% gym.position.distance_to(SeuzachGeo.birch_turnhalle_world())
	)
	_assert(
		a.scale.is_equal_approx(Vector2(0.84, 0.84)),
		"schulhaus_birch_a scale ≈ 0.84 (got %s)" % str(a.scale)
	)
	_assert(
		b.scale.is_equal_approx(Vector2(0.67, 0.67)),
		"schulhaus_birch_b scale ≈ 0.67 (got %s)" % str(b.scale)
	)
	_assert(
		gym.scale.is_equal_approx(Vector2(1.11, 1.11)),
		"turnhalle_birch scale ≈ 1.11 (got %s)" % str(gym.scale)
	)
	_assert(
		a.position.x > b.position.x + 400.0,
		"birch_a east of birch_b by >400 wu (a.x=%.0f b.x=%.0f)"
		% [a.position.x, b.position.x]
	)
	_assert(
		gym.position.y < minf(a.position.y, b.position.y) - 200.0,
		"turnhalle north of birch a/b (gym.y=%.0f a.y=%.0f b.y=%.0f)"
		% [gym.position.y, a.position.y, b.position.y]
	)
	var yard := SeuzachGeo.birch_world()
	for spr in [a, b, gym]:
		_assert(
			spr.position.distance_to(yard) < 1400.0,
			"%s within 1400 wu of birch_world (d=%.1f)"
			% [spr.name, spr.position.distance_to(yard)]
		)
		_assert(
			spr.has_meta("has_building_collision") and bool(spr.get_meta("has_building_collision")),
			"%s has BuildingCollision" % spr.name
		)
		_assert(is_zero_approx(spr.rotation), "%s rotation is 0" % spr.name)
	_assert_school_street_prop(world, a, "Bachwiesenstrasse", true)
	_assert_school_street_prop(world, b, "Birchstrasse", false)
	_assert_school_street_prop(world, gym, "Birchstrasse", false)


func _assert_rietacker_campus(world: Node, sprites: Array[Sprite2D]) -> void:
	var a := _find_named(sprites, "schulhaus_rietacker_a")
	var b := _find_named(sprites, "schulhaus_rietacker_b")
	var gym := _find_named(sprites, "turnhalle_rietacker")
	_assert(a != null, "node schulhaus_rietacker_a exists")
	_assert(b != null, "node schulhaus_rietacker_b exists")
	_assert(gym != null, "node turnhalle_rietacker exists")
	_assert(
		is_equal_approx(SeuzachGeo.RIETACKER_LAT, 47.5362833)
		and is_equal_approx(SeuzachGeo.RIETACKER_LON, 8.7271400),
		"rietacker_world() GPS constants unchanged"
	)
	_assert(
		SeuzachGeo.rietacker_world().is_equal_approx(
			SeuzachGeo.gps_to_world(SeuzachGeo.RIETACKER_LAT, SeuzachGeo.RIETACKER_LON)
		),
		"rietacker_world() still maps RIETACKER_LAT/LON"
	)
	_assert(
		is_equal_approx(SeuzachGeo.RIETACKER_SCHULHAUS_A_LAT, 47.5360788)
		and is_equal_approx(SeuzachGeo.RIETACKER_SCHULHAUS_A_LON, 8.7273791)
		and is_equal_approx(SeuzachGeo.RIETACKER_SCHULHAUS_B_LAT, 47.5365102)
		and is_equal_approx(SeuzachGeo.RIETACKER_SCHULHAUS_B_LON, 8.7275595)
		and is_equal_approx(SeuzachGeo.RIETACKER_TURNHALLE_LAT, 47.5361323)
		and is_equal_approx(SeuzachGeo.RIETACKER_TURNHALLE_LON, 8.7262616),
		"Rietacker building GPS constants match S02 OSM table"
	)
	_assert(
		SeuzachGeo.rietacker_schulhaus_a_world().distance_to(
			SeuzachGeo.rietacker_world() + Vector2(339.1, 429.5)
		) < 1.0,
		"rietacker_a offset vs yard ≈ (339.1, 429.5)"
	)
	_assert(
		SeuzachGeo.rietacker_schulhaus_b_world().distance_to(
			SeuzachGeo.rietacker_world() + Vector2(594.9, -476.6)
		) < 1.0,
		"rietacker_b offset vs yard ≈ (594.9, -476.6)"
	)
	_assert(
		SeuzachGeo.rietacker_turnhalle_world().distance_to(
			SeuzachGeo.rietacker_world() + Vector2(-1245.6, 317.2)
		) < 1.0,
		"rietacker turnhalle offset vs yard ≈ (-1245.6, 317.2)"
	)
	var rietacker_n := _count_school_cluster(sprites, "rietacker")
	_assert(rietacker_n == 3, "school_cluster rietacker has exactly 3 props (got %d)" % rietacker_n)
	if a == null or b == null or gym == null:
		return
	_assert(
		str(a.get_meta("landmark_id")) == "schulhaus_rietacker"
		and str(a.get_meta("school_cluster")) == "rietacker"
		and str(a.get_meta("district")) == "rietacker",
		"schulhaus_rietacker_a metas"
	)
	_assert(
		str(b.get_meta("landmark_id")) == "schulhaus_rietacker"
		and str(b.get_meta("school_cluster")) == "rietacker"
		and str(b.get_meta("district")) == "rietacker",
		"schulhaus_rietacker_b metas"
	)
	_assert(
		str(gym.get_meta("landmark_id")) == "turnhalle_rietacker"
		and str(gym.get_meta("school_cluster")) == "rietacker"
		and str(gym.get_meta("district")) == "rietacker"
		and str(gym.get_meta("poi_type")) == "gym",
		"turnhalle_rietacker metas"
	)
	_assert(
		a.position.distance_to(SeuzachGeo.rietacker_schulhaus_a_world()) <= 720.0,
		"schulhaus_rietacker_a within 720 wu of OSM getter (d=%.1f)"
		% a.position.distance_to(SeuzachGeo.rietacker_schulhaus_a_world())
	)
	_assert(
		b.position.distance_to(SeuzachGeo.rietacker_schulhaus_b_world()) <= 720.0,
		"schulhaus_rietacker_b within 720 wu of OSM getter (d=%.1f)"
		% b.position.distance_to(SeuzachGeo.rietacker_schulhaus_b_world())
	)
	_assert(
		gym.position.distance_to(SeuzachGeo.rietacker_turnhalle_world()) <= 720.0,
		"turnhalle_rietacker within 720 wu of OSM getter (d=%.1f)"
		% gym.position.distance_to(SeuzachGeo.rietacker_turnhalle_world())
	)
	_assert(
		a.scale.is_equal_approx(Vector2(0.52, 0.52)),
		"schulhaus_rietacker_a scale ≈ 0.52 (got %s)" % str(a.scale)
	)
	_assert(
		b.scale.is_equal_approx(Vector2(0.605, 0.605)),
		"schulhaus_rietacker_b scale ≈ 0.605 (got %s)" % str(b.scale)
	)
	_assert(
		gym.scale.is_equal_approx(Vector2(1.31, 1.31)),
		"turnhalle_rietacker scale ≈ 1.31 (got %s)" % str(gym.scale)
	)
	_assert(
		gym.position.x < minf(a.position.x, b.position.x) - 800.0,
		"turnhalle west of rietacker a/b (gym.x=%.0f a.x=%.0f b.x=%.0f)"
		% [gym.position.x, a.position.x, b.position.x]
	)
	_assert(
		b.position.y < a.position.y - 400.0,
		"rietacker_b north of rietacker_a (b.y=%.0f a.y=%.0f)"
		% [b.position.y, a.position.y]
	)
	_assert(
		a.position.x > gym.position.x and b.position.x > gym.position.x,
		"both rietacker schulhäuser east of turnhalle (a.x=%.0f b.x=%.0f gym.x=%.0f)"
		% [a.position.x, b.position.x, gym.position.x]
	)
	var yard := SeuzachGeo.rietacker_world()
	for spr in [a, b, gym]:
		_assert(
			spr.position.distance_to(yard) < 1600.0,
			"%s within 1600 wu of rietacker_world (d=%.1f)"
			% [spr.name, spr.position.distance_to(yard)]
		)
		_assert(
			spr.has_meta("has_building_collision") and bool(spr.get_meta("has_building_collision")),
			"%s has BuildingCollision" % spr.name
		)
		_assert(is_zero_approx(spr.rotation), "%s rotation is 0" % spr.name)
	_assert_school_street_prop(world, a, "Ohringerstrasse", true, "north")
	var b_road := str(b.get_meta("street_name")) if b.has_meta("street_name") else "Ohringerstrasse"
	if b_road == "Püntenstrasse":
		## NE tract: GPS sits ~1291 wu north of Ohringer; Pünten setback, south of the stub.
		_assert_school_street_prop(world, b, "Püntenstrasse", false, "south")
	else:
		_assert_school_street_prop(world, b, "Ohringerstrasse", true, "north")
	_assert_school_street_prop(world, gym, "Turnerstrasse", false, "east")


func _assert_ohringen_campus(world: Node, sprites: Array[Sprite2D]) -> void:
	var a := _find_named(sprites, "schulhaus_ohringen_a")
	var b := _find_named(sprites, "schulhaus_ohringen_b")
	var gym := _find_named(sprites, "turnhalle_ohringen")
	_assert(a != null, "node schulhaus_ohringen_a exists")
	_assert(b != null, "node schulhaus_ohringen_b exists")
	_assert(gym != null, "node turnhalle_ohringen exists")
	_assert(
		is_equal_approx(SeuzachGeo.OHRINGEN_LAT, 47.5280584)
		and is_equal_approx(SeuzachGeo.OHRINGEN_LON, 8.7121325),
		"ohringen_world() GPS constants unchanged"
	)
	_assert(
		SeuzachGeo.ohringen_world().is_equal_approx(
			SeuzachGeo.gps_to_world(SeuzachGeo.OHRINGEN_LAT, SeuzachGeo.OHRINGEN_LON)
		),
		"ohringen_world() still maps OHRINGEN_LAT/LON"
	)
	_assert(
		is_equal_approx(SeuzachGeo.OHRINGEN_SCHULHAUS_A_LAT, 47.5283478)
		and is_equal_approx(SeuzachGeo.OHRINGEN_SCHULHAUS_A_LON, 8.7123497)
		and is_equal_approx(SeuzachGeo.OHRINGEN_SCHULHAUS_B_LAT, 47.5281003)
		and is_equal_approx(SeuzachGeo.OHRINGEN_SCHULHAUS_B_LON, 8.7125046)
		and is_equal_approx(SeuzachGeo.OHRINGEN_TURNHALLE_LAT, 47.5279647)
		and is_equal_approx(SeuzachGeo.OHRINGEN_TURNHALLE_LON, 8.7122618),
		"Ohringen building GPS constants match S03 OSM table"
	)
	_assert(
		SeuzachGeo.ohringen_schulhaus_a_world().distance_to(
			SeuzachGeo.ohringen_world() + Vector2(308.0, -607.8)
		) < 1.0,
		"ohringen_a offset vs yard ≈ (308.0, -607.8)"
	)
	_assert(
		SeuzachGeo.ohringen_schulhaus_b_world().distance_to(
			SeuzachGeo.ohringen_world() + Vector2(527.7, -88.0)
		) < 1.0,
		"ohringen_b offset vs yard ≈ (527.7, -88.0)"
	)
	_assert(
		SeuzachGeo.ohringen_turnhalle_world().distance_to(
			SeuzachGeo.ohringen_world() + Vector2(183.4, 196.8)
		) < 1.0,
		"ohringen turnhalle offset vs yard ≈ (183.4, 196.8)"
	)
	var ohringen_n := _count_school_cluster(sprites, "ohringen")
	_assert(ohringen_n == 3, "school_cluster ohringen has exactly 3 props (got %d)" % ohringen_n)
	if a == null or b == null or gym == null:
		return
	_assert(
		_has_named_ancestor(a, "DistrictOhringen")
		and _has_named_ancestor(b, "DistrictOhringen")
		and _has_named_ancestor(gym, "DistrictOhringen"),
		"Ohringen campus parent chain includes DistrictOhringen"
	)
	_assert(
		str(a.get_meta("landmark_id")) == "schulhaus_ohringen"
		and str(a.get_meta("school_cluster")) == "ohringen"
		and str(a.get_meta("district")) == "ohringen",
		"schulhaus_ohringen_a metas"
	)
	_assert(
		str(b.get_meta("landmark_id")) == "schulhaus_ohringen"
		and str(b.get_meta("school_cluster")) == "ohringen"
		and str(b.get_meta("district")) == "ohringen",
		"schulhaus_ohringen_b metas"
	)
	_assert(
		str(gym.get_meta("landmark_id")) == "turnhalle_ohringen"
		and str(gym.get_meta("school_cluster")) == "ohringen"
		and str(gym.get_meta("district")) == "ohringen"
		and str(gym.get_meta("poi_type")) == "gym",
		"turnhalle_ohringen metas"
	)
	_assert(
		a.position.distance_to(SeuzachGeo.ohringen_schulhaus_a_world()) <= 720.0,
		"schulhaus_ohringen_a within 720 wu of OSM getter (d=%.1f)"
		% a.position.distance_to(SeuzachGeo.ohringen_schulhaus_a_world())
	)
	_assert(
		b.position.distance_to(SeuzachGeo.ohringen_schulhaus_b_world()) <= 720.0,
		"schulhaus_ohringen_b within 720 wu of OSM getter (d=%.1f)"
		% b.position.distance_to(SeuzachGeo.ohringen_schulhaus_b_world())
	)
	_assert(
		gym.position.distance_to(SeuzachGeo.ohringen_turnhalle_world()) <= 720.0,
		"turnhalle_ohringen within 720 wu of OSM getter (d=%.1f)"
		% gym.position.distance_to(SeuzachGeo.ohringen_turnhalle_world())
	)
	_assert(
		a.scale.is_equal_approx(Vector2(0.71, 0.71)),
		"schulhaus_ohringen_a scale ≈ 0.71 (got %s)" % str(a.scale)
	)
	_assert(
		b.scale.is_equal_approx(Vector2(0.64, 0.64)),
		"schulhaus_ohringen_b scale ≈ 0.64 (got %s)" % str(b.scale)
	)
	_assert(
		gym.scale.is_equal_approx(Vector2(0.605, 0.605)),
		"turnhalle_ohringen scale ≈ 0.605 (got %s)" % str(gym.scale)
	)
	_assert(
		a.position.y < b.position.y - 150.0,
		"ohringen_a north of ohringen_b (a.y=%.0f b.y=%.0f; ≥150 wu after clearance nudge)"
		% [a.position.y, b.position.y]
	)
	_assert(
		a.position.y < gym.position.y - 400.0,
		"ohringen_a north of turnhalle (a.y=%.0f gym.y=%.0f)"
		% [a.position.y, gym.position.y]
	)
	_assert(
		gym.position.y > maxf(a.position.y, b.position.y),
		"turnhalle south of ohringen a/b (gym.y=%.0f a.y=%.0f b.y=%.0f)"
		% [gym.position.y, a.position.y, b.position.y]
	)
	_assert(
		b.position.x > gym.position.x + 200.0,
		"ohringen_b east of turnhalle by >200 wu (b.x=%.0f gym.x=%.0f)"
		% [b.position.x, gym.position.x]
	)
	_assert(
		a.position.x > gym.position.x,
		"ohringen_a east of turnhalle (a.x=%.0f gym.x=%.0f)"
		% [a.position.x, gym.position.x]
	)
	_assert(
		a.position.x < -15000.0 and a.position.y > 8000.0,
		"ohringen school SW (got %s)" % str(a.position)
	)
	var yard := SeuzachGeo.ohringen_world()
	for spr in [a, b, gym]:
		_assert(
			spr.position.distance_to(yard) < 1400.0,
			"%s within 1400 wu of ohringen_world (d=%.1f; clearance nudge)"
			% [spr.name, spr.position.distance_to(yard)]
		)
		_assert(
			spr.has_meta("has_building_collision") and bool(spr.get_meta("has_building_collision")),
			"%s has BuildingCollision" % spr.name
		)
		_assert(is_zero_approx(spr.rotation), "%s rotation is 0" % spr.name)
	_assert_school_street_prop(world, a, "Schulstrasse", true, "west")
	_assert_school_street_prop(world, b, "Schulstrasse", true, "west")
	_assert_school_street_prop(world, gym, "Schaffhauserstrasse", true, "north")


func _assert_kiga_bachtobel(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(
		is_equal_approx(SeuzachGeo.KIGA_BACHTOBEL_LAT, 47.5376225)
		and is_equal_approx(SeuzachGeo.KIGA_BACHTOBEL_LON, 8.7380927),
		"kiga_bachtobel GPS constants match OSM building centroid"
	)
	_assert(
		SeuzachGeo.kiga_bachtobel_world().is_equal_approx(
			SeuzachGeo.gps_to_world(SeuzachGeo.KIGA_BACHTOBEL_LAT, SeuzachGeo.KIGA_BACHTOBEL_LON)
		),
		"kiga_bachtobel_world() maps KIGA_BACHTOBEL_LAT/LON"
	)
	_assert(
		SeuzachGeo.kiga_bachtobel_world().distance_to(Vector2(16973.4, -8656.3)) < 1.0,
		"kiga_bachtobel_world() ≈ (16973.4, -8656.3)"
	)
	var kiga := _find_named(sprites, "kiga_bachtobel")
	_assert(kiga != null, "node kiga_bachtobel exists")
	_assert(_has_kindergarten(sprites, "kiga_bachtobel"), "kindergarten_id kiga_bachtobel present")
	if kiga == null:
		return
	_assert(
		str(kiga.get_meta("landmark_id")) == "kiga_bachtobel"
		and str(kiga.get_meta("kindergarten_id")) == "kiga_bachtobel"
		and str(kiga.get_meta("district")) == "bachtobel",
		"kiga_bachtobel metas"
	)
	_assert(not kiga.has_meta("school_cluster"), "kiga_bachtobel has no school_cluster")
	_assert(
		not _has_named_ancestor(kiga, "DistrictOhringen"),
		"kiga_bachtobel parent chain excludes DistrictOhringen"
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.kiga_bachtobel_world()) <= 720.0,
		"kiga_bachtobel within 720 wu of OSM getter (d=%.1f)"
		% kiga.position.distance_to(SeuzachGeo.kiga_bachtobel_world())
	)
	_assert(
		kiga.position.x > 15000.0 and kiga.position.y < -8000.0,
		"kiga_bachtobel NE village (got %s)" % str(kiga.position)
	)
	var birch := SeuzachGeo.birch_world()
	_assert(
		kiga.position.y < birch.y - 4000.0,
		"kiga_bachtobel north of Birch (kiga.y=%.0f birch.y=%.0f)"
		% [kiga.position.y, birch.y]
	)
	_assert(
		kiga.position.x > birch.x,
		"kiga_bachtobel east of Birch (kiga.x=%.0f birch.x=%.0f)"
		% [kiga.position.x, birch.x]
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.ohringen_world()) > 8000.0,
		"kiga_bachtobel far from Ohringen (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.ohringen_world())
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.forrenberg_world()) > 8000.0,
		"kiga_bachtobel far from Forrenberg hub (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.forrenberg_world())
	)
	_assert(
		kiga.has_meta("has_building_collision") and bool(kiga.get_meta("has_building_collision")),
		"kiga_bachtobel has BuildingCollision"
	)
	_assert(
		kiga.scale.is_equal_approx(Vector2(0.50, 0.50)),
		"kiga_bachtobel scale ≈ 0.50 (got %s)" % str(kiga.scale)
	)
	_assert(is_zero_approx(kiga.rotation), "kiga_bachtobel rotation is 0")
	_assert_school_street_prop(world, kiga, "Bachtobelstrasse", false, "east")
	var ground: Node = world.get_node_or_null("%Ground")
	if ground:
		_assert_road_near(ground, "Bachtobelstrasse", SeuzachGeo.kiga_bachtobel_world(), 900.0)


func _assert_kiga_weid(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(
		is_equal_approx(SeuzachGeo.KIGA_WEID_LAT, 47.5330589)
		and is_equal_approx(SeuzachGeo.KIGA_WEID_LON, 8.7379167),
		"kiga_weid GPS constants match OSM building centroid"
	)
	_assert(
		SeuzachGeo.kiga_weid_world().is_equal_approx(
			SeuzachGeo.gps_to_world(SeuzachGeo.KIGA_WEID_LAT, SeuzachGeo.KIGA_WEID_LON)
		),
		"kiga_weid_world() maps KIGA_WEID_LAT/LON"
	)
	_assert(
		SeuzachGeo.kiga_weid_world().distance_to(Vector2(16723.8, 929.0)) < 1.0,
		"kiga_weid_world() ≈ (16723.8, 929.0)"
	)
	var kiga := _find_named(sprites, "kiga_weid")
	_assert(kiga != null, "node kiga_weid exists")
	_assert(_has_kindergarten(sprites, "kiga_weid"), "kindergarten_id kiga_weid present")
	if kiga == null:
		return
	_assert(
		str(kiga.get_meta("landmark_id")) == "kiga_weid"
		and str(kiga.get_meta("kindergarten_id")) == "kiga_weid"
		and str(kiga.get_meta("district")) == "weid",
		"kiga_weid metas"
	)
	_assert(not kiga.has_meta("school_cluster"), "kiga_weid has no school_cluster")
	_assert(
		not _has_named_ancestor(kiga, "DistrictOhringen"),
		"kiga_weid parent chain excludes DistrictOhringen"
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.kiga_weid_world()) <= 720.0,
		"kiga_weid within 720 wu of OSM getter (d=%.1f)"
		% kiga.position.distance_to(SeuzachGeo.kiga_weid_world())
	)
	_assert(
		kiga.position.x > 15000.0 and kiga.position.y > -2000.0 and kiga.position.y < 4000.0,
		"kiga_weid east village not Ohringen/hub (got %s)" % str(kiga.position)
	)
	var birch := SeuzachGeo.birch_world()
	_assert(
		kiga.position.y > birch.y + 3000.0,
		"kiga_weid south of Birch (kiga.y=%.0f birch.y=%.0f)"
		% [kiga.position.y, birch.y]
	)
	_assert(
		kiga.position.x > birch.x,
		"kiga_weid east of Birch (kiga.x=%.0f birch.x=%.0f)"
		% [kiga.position.x, birch.x]
	)
	_assert(
		kiga.position.y > SeuzachGeo.kiga_bachtobel_world().y + 4000.0,
		"kiga_weid south of Bachtobel (kiga.y=%.0f bachtobel.y=%.0f)"
		% [kiga.position.y, SeuzachGeo.kiga_bachtobel_world().y]
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.ohringen_world()) > 8000.0,
		"kiga_weid far from Ohringen (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.ohringen_world())
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.forrenberg_world()) > 8000.0,
		"kiga_weid far from Forrenberg hub (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.forrenberg_world())
	)
	_assert(
		kiga.has_meta("has_building_collision") and bool(kiga.get_meta("has_building_collision")),
		"kiga_weid has BuildingCollision"
	)
	_assert(
		kiga.scale.is_equal_approx(Vector2(0.215, 0.215)),
		"kiga_weid scale ≈ 0.215 (got %s)" % str(kiga.scale)
	)
	_assert(is_zero_approx(kiga.rotation), "kiga_weid rotation is 0")
	_assert_school_street_prop(world, kiga, "Weidstrasse", false, "south")
	var ground: Node = world.get_node_or_null("%Ground")
	if ground:
		_assert_road_near(ground, "Weidstrasse", SeuzachGeo.kiga_weid_world(), 900.0)


func _assert_kiga_schneckenwiese(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(
		is_equal_approx(SeuzachGeo.KIGA_SCHNECKENWIESE_LAT, 47.5347527)
		and is_equal_approx(SeuzachGeo.KIGA_SCHNECKENWIESE_LON, 8.7310559),
		"kiga_schneckenwiese GPS constants match OSM building centroid"
	)
	_assert(
		SeuzachGeo.kiga_schneckenwiese_world().is_equal_approx(
			SeuzachGeo.gps_to_world(
				SeuzachGeo.KIGA_SCHNECKENWIESE_LAT, SeuzachGeo.KIGA_SCHNECKENWIESE_LON
			)
		),
		"kiga_schneckenwiese_world() maps KIGA_SCHNECKENWIESE_LAT/LON"
	)
	_assert(
		SeuzachGeo.kiga_schneckenwiese_world().distance_to(Vector2(6994.6, -2628.6)) < 1.0,
		"kiga_schneckenwiese_world() ≈ (6994.6, -2628.6)"
	)
	var kiga := _find_named(sprites, "kiga_schneckenwiese")
	_assert(kiga != null, "node kiga_schneckenwiese exists")
	_assert(
		_has_kindergarten(sprites, "kiga_schneckenwiese"),
		"kindergarten_id kiga_schneckenwiese present"
	)
	if kiga == null:
		return
	_assert(
		str(kiga.get_meta("landmark_id")) == "kiga_schneckenwiese"
		and str(kiga.get_meta("kindergarten_id")) == "kiga_schneckenwiese"
		and str(kiga.get_meta("district")) == "schneckenwiese",
		"kiga_schneckenwiese metas"
	)
	_assert(not kiga.has_meta("school_cluster"), "kiga_schneckenwiese has no school_cluster")
	_assert(
		not _has_named_ancestor(kiga, "DistrictOhringen"),
		"kiga_schneckenwiese parent chain excludes DistrictOhringen"
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.kiga_schneckenwiese_world()) <= 720.0,
		"kiga_schneckenwiese within 720 wu of OSM getter (d=%.1f)"
		% kiga.position.distance_to(SeuzachGeo.kiga_schneckenwiese_world())
	)
	_assert(
		kiga.position.x > 4000.0
		and kiga.position.x < 12000.0
		and kiga.position.y > -5000.0
		and kiga.position.y < 0.0,
		"kiga_schneckenwiese village core not Ohringen/hub (got %s)" % str(kiga.position)
	)
	var birch := SeuzachGeo.birch_world()
	_assert(
		kiga.position.x < birch.x - 4000.0,
		"kiga_schneckenwiese west of Birch (kiga.x=%.0f birch.x=%.0f)"
		% [kiga.position.x, birch.x]
	)
	_assert(
		kiga.position.y > birch.y,
		"kiga_schneckenwiese south of Birch (kiga.y=%.0f birch.y=%.0f)"
		% [kiga.position.y, birch.y]
	)
	_assert(
		kiga.position.y > SeuzachGeo.kiga_bachtobel_world().y + 4000.0,
		"kiga_schneckenwiese south of Bachtobel (kiga.y=%.0f bachtobel.y=%.0f)"
		% [kiga.position.y, SeuzachGeo.kiga_bachtobel_world().y]
	)
	_assert(
		kiga.position.x < SeuzachGeo.kiga_weid_world().x - 4000.0
		and kiga.position.y < SeuzachGeo.kiga_weid_world().y,
		"kiga_schneckenwiese west and north of Weid (kiga=%s weid=%s)"
		% [str(kiga.position), str(SeuzachGeo.kiga_weid_world())]
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.ohringen_world()) > 8000.0,
		"kiga_schneckenwiese far from Ohringen (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.ohringen_world())
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.forrenberg_world()) > 8000.0,
		"kiga_schneckenwiese far from Forrenberg hub (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.forrenberg_world())
	)
	_assert(
		kiga.has_meta("has_building_collision") and bool(kiga.get_meta("has_building_collision")),
		"kiga_schneckenwiese has BuildingCollision"
	)
	_assert(
		kiga.scale.is_equal_approx(Vector2(0.56, 0.56)),
		"kiga_schneckenwiese scale ≈ 0.56 (got %s)" % str(kiga.scale)
	)
	_assert(is_zero_approx(kiga.rotation), "kiga_schneckenwiese rotation is 0")
	var sw_road := str(kiga.get_meta("street_name")) if kiga.has_meta("street_name") else "Schneckenwiesenstrasse"
	if sw_road == "Reutlingerstrasse":
		## Fallback: GPS ~1142 wu from collector; north bank if stub still misses asphalt.
		_assert_school_street_prop(world, kiga, "Reutlingerstrasse", true, "north")
	else:
		## Preferred: west of Schneckenwiesenstrasse (NS ribbon east of the prop).
		_assert_school_street_prop(world, kiga, "Schneckenwiesenstrasse", true, "west")
	var ground: Node = world.get_node_or_null("%Ground")
	if ground:
		_assert_road_near(
			ground, "Schneckenwiesenstrasse", SeuzachGeo.kiga_schneckenwiese_world(), 900.0
		)


func _assert_kiga_ohringen(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(
		is_equal_approx(SeuzachGeo.KIGA_OHRINGEN_LAT, 47.5278851)
		and is_equal_approx(SeuzachGeo.KIGA_OHRINGEN_LON, 8.7126832),
		"kiga_ohringen GPS constants match OSM building centroid"
	)
	_assert(
		SeuzachGeo.kiga_ohringen_world().is_equal_approx(
			SeuzachGeo.gps_to_world(SeuzachGeo.KIGA_OHRINGEN_LAT, SeuzachGeo.KIGA_OHRINGEN_LON)
		),
		"kiga_ohringen_world() maps KIGA_OHRINGEN_LAT/LON"
	)
	_assert(
		SeuzachGeo.kiga_ohringen_world().distance_to(Vector2(-19059.5, 11795.9)) < 1.0,
		"kiga_ohringen_world() ≈ (-19059.5, 11795.9)"
	)
	for kiga_id in KIGA_IDS:
		_assert(_has_kindergarten(sprites, kiga_id), "kindergarten_id %s present" % kiga_id)
		_assert(_find_named(sprites, kiga_id) != null, "node %s exists" % kiga_id)
	var kiga := _find_named(sprites, "kiga_ohringen")
	_assert(kiga != null, "node kiga_ohringen exists")
	_assert(_has_kindergarten(sprites, "kiga_ohringen"), "kindergarten_id kiga_ohringen present")
	if kiga == null:
		return
	_assert(
		str(kiga.get_meta("landmark_id")) == "kiga_ohringen"
		and str(kiga.get_meta("kindergarten_id")) == "kiga_ohringen"
		and str(kiga.get_meta("district")) == "ohringen",
		"kiga_ohringen metas"
	)
	_assert(not kiga.has_meta("school_cluster"), "kiga_ohringen has no school_cluster")
	_assert(
		_has_named_ancestor(kiga, "DistrictOhringen"),
		"kiga_ohringen parent chain includes DistrictOhringen"
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.kiga_ohringen_world()) <= 720.0,
		"kiga_ohringen within 720 wu of OSM getter (d=%.1f)"
		% kiga.position.distance_to(SeuzachGeo.kiga_ohringen_world())
	)
	_assert(
		kiga.scale.is_equal_approx(Vector2(0.39, 0.39)),
		"kiga_ohringen scale ≈ 0.39 (got %s)" % str(kiga.scale)
	)
	_assert(
		kiga.position.x < -15000.0 and kiga.position.y > 8000.0,
		"kiga_ohringen SW Ohringen cells (got %s)" % str(kiga.position)
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.ohringen_world()) < 1200.0,
		"kiga_ohringen near campus anchor (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.ohringen_world())
	)
	_assert(
		kiga.position.x > SeuzachGeo.ohringen_schulhaus_b_world().x,
		"kiga_ohringen east of schulhaus b (kiga.x=%.0f b.x=%.0f)"
		% [kiga.position.x, SeuzachGeo.ohringen_schulhaus_b_world().x]
	)
	_assert(
		kiga.position.x > SeuzachGeo.ohringen_turnhalle_world().x,
		"kiga_ohringen east of turnhalle (kiga.x=%.0f gym.x=%.0f)"
		% [kiga.position.x, SeuzachGeo.ohringen_turnhalle_world().x]
	)
	_assert(
		kiga.position.y > SeuzachGeo.ohringen_schulhaus_a_world().y
		and kiga.position.y > SeuzachGeo.ohringen_schulhaus_b_world().y,
		"kiga_ohringen south of schulhaus a and b (kiga.y=%.0f a.y=%.0f b.y=%.0f)"
		% [
			kiga.position.y,
			SeuzachGeo.ohringen_schulhaus_a_world().y,
			SeuzachGeo.ohringen_schulhaus_b_world().y,
		]
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.birch_world()) > 8000.0,
		"kiga_ohringen far from Birch (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.birch_world())
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.forrenberg_world()) > 8000.0,
		"kiga_ohringen far from Forrenberg hub (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.forrenberg_world())
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.kiga_bachtobel_world()) > 8000.0,
		"kiga_ohringen far from Bachtobel (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.kiga_bachtobel_world())
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.kiga_weid_world()) > 8000.0,
		"kiga_ohringen far from Weid (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.kiga_weid_world())
	)
	_assert(
		kiga.position.distance_to(SeuzachGeo.kiga_schneckenwiese_world()) > 8000.0,
		"kiga_ohringen far from Schneckenwiese (d=%.0f)"
		% kiga.position.distance_to(SeuzachGeo.kiga_schneckenwiese_world())
	)
	_assert(
		kiga.has_meta("has_building_collision") and bool(kiga.get_meta("has_building_collision")),
		"kiga_ohringen has BuildingCollision"
	)
	_assert(is_zero_approx(kiga.rotation), "kiga_ohringen rotation is 0")
	_assert_school_street_prop(world, kiga, "Schulstrasse", true, "west")
	var ground: Node = world.get_node_or_null("%Ground")
	if ground:
		_assert_road_near(ground, "Schulstrasse", SeuzachGeo.kiga_ohringen_world(), 900.0)


func _assert_bahnhof(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(
		is_equal_approx(SeuzachGeo.BAHNHOF_LAT, 47.5357159)
		and is_equal_approx(SeuzachGeo.BAHNHOF_LON, 8.7388969),
		"bahnhof GPS constants match OSM building centroid (not bus platform)"
	)
	_assert(
		SeuzachGeo.bahnhof_world().is_equal_approx(
			SeuzachGeo.gps_to_world(SeuzachGeo.BAHNHOF_LAT, SeuzachGeo.BAHNHOF_LON)
		),
		"bahnhof_world() maps BAHNHOF_LAT/LON"
	)
	_assert(
		SeuzachGeo.bahnhof_world().distance_to(Vector2(18113.8, -4651.7)) < 1.0,
		"bahnhof_world() ≈ (18113.8, -4651.7)"
	)
	_assert(
		_count_landmark(sprites, "bahnhof") == 1,
		"exactly one bahnhof landmark (got %d)" % _count_landmark(sprites, "bahnhof")
	)
	var bahnhof := _find_named(sprites, "bahnhof")
	_assert(bahnhof != null, "node bahnhof exists")
	_assert(_find_landmark(sprites, "bahnhof") != null, "landmark_id bahnhof present")
	_assert(_count_poi(sprites, "railway") == 0, "railway sprite POIs stay 0 (S09 kit is Ground, not Sprite)")
	_assert(_find_landmark(sprites, "gleise") == null, "no gleise landmark sprite (S09 uses RailwayKit)")
	if bahnhof == null:
		return
	_assert(
		str(bahnhof.get_meta("landmark_id")) == "bahnhof"
		and str(bahnhof.get_meta("district")) == "seuzach"
		and str(bahnhof.get_meta("poi_type")) == "station",
		"bahnhof metas"
	)
	_assert(not bahnhof.has_meta("school_cluster"), "bahnhof has no school_cluster")
	_assert(not bahnhof.has_meta("kindergarten_id"), "bahnhof has no kindergarten_id")
	_assert(
		str(bahnhof.get_meta("district")) != "forrenberg",
		"bahnhof district is not forrenberg"
	)
	_assert(
		not _has_named_ancestor(bahnhof, "DistrictOhringen"),
		"bahnhof parent chain excludes DistrictOhringen"
	)
	_assert(
		bahnhof.position.distance_to(SeuzachGeo.bahnhof_world()) <= 720.0,
		"bahnhof within 720 wu of OSM getter (d=%.1f)"
		% bahnhof.position.distance_to(SeuzachGeo.bahnhof_world())
	)
	_assert(
		bahnhof.position.x > 15000.0 and bahnhof.position.y < 0.0,
		"bahnhof east village north of Kirche (got %s)" % str(bahnhof.position)
	)
	_assert(
		bahnhof.position.x > SeuzachGeo.birch_schulhaus_a_world().x,
		"bahnhof east of Birch-a (bahnhof.x=%.0f a.x=%.0f)"
		% [bahnhof.position.x, SeuzachGeo.birch_schulhaus_a_world().x]
	)
	var d_birch := bahnhof.position.distance_to(SeuzachGeo.birch_world())
	_assert(
		d_birch > 3000.0 and d_birch < 5000.0,
		"bahnhof 3000–5000 wu from Birch (d=%.0f)" % d_birch
	)
	_assert(
		bahnhof.position.distance_to(SeuzachGeo.forrenberg_world()) > 8000.0,
		"bahnhof far from Forrenberg hub (d=%.0f)"
		% bahnhof.position.distance_to(SeuzachGeo.forrenberg_world())
	)
	_assert(
		bahnhof.position.distance_to(SeuzachGeo.kiga_ohringen_world()) > 8000.0,
		"bahnhof far from kiga_ohringen (d=%.0f)"
		% bahnhof.position.distance_to(SeuzachGeo.kiga_ohringen_world())
	)
	_assert(
		bahnhof.position.distance_to(SeuzachGeo.ohringen_world()) > 15000.0,
		"bahnhof far from Ohringen campus (d=%.0f)"
		% bahnhof.position.distance_to(SeuzachGeo.ohringen_world())
	)
	## OSM stop ref 1 (node 130250360) — inline GPS, not a SeuzachGeo constant (S09).
	var stop_ref1 := SeuzachGeo.gps_to_world(47.5358162, 8.7389630)
	_assert(
		bahnhof.position.y > stop_ref1.y,
		"bahnhof south of track stop ref 1 (bahnhof.y=%.0f stop.y=%.0f)"
		% [bahnhof.position.y, stop_ref1.y]
	)
	_assert(
		bahnhof.has_meta("has_building_collision") and bool(bahnhof.get_meta("has_building_collision")),
		"bahnhof has BuildingCollision"
	)
	_assert(not bahnhof.flip_h, "bahnhof flip_h false")
	_assert(is_zero_approx(bahnhof.rotation), "bahnhof rotation is 0")
	_assert_sprite_off_named_roads(world, bahnhof)
	var ground: Node = world.get_node_or_null("%Ground")
	if ground:
		_assert_road_near(ground, "Stationsstrasse", SeuzachGeo.bahnhof_world(), 900.0)


func _assert_railway(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(_count_poi(sprites, "railway") == 0, "railway sprite POIs remain 0 (kit ≠ sprite)")
	_assert(_find_landmark(sprites, "gleise") == null, "no gleise landmark sprite")
	var house_n := 0
	var forest_n := 0
	for spr in sprites:
		if spr.has_meta("house_variant"):
			house_n += 1
		if spr.has_meta("terrain") and str(spr.get_meta("terrain")) == "forest":
			forest_n += 1
	_assert(house_n >= 6, "housing props present (got %d)" % house_n)
	_assert(forest_n >= 1, "forest props present (got %d)" % forest_n)
	for cluster in ["birch", "rietacker", "ohringen"]:
		var n := _count_school_cluster(sprites, cluster)
		_assert(n == 3, "school_cluster %s still has 3 props (got %d)" % [cluster, n])
	for kiga_id in KIGA_IDS:
		_assert(_has_kindergarten(sprites, str(kiga_id)), "%s still placed" % kiga_id)
	_assert(_count_landmark(sprites, "bahnhof") == 1, "bahnhof count stays 1")

	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground for railway markers")
	if ground == null:
		return
	var hills := 0
	var rail_markers: Array[Node] = []
	var ballast_n := 0
	var rail_n := 0
	var has_platform_kit := false
	var has_platform_marker := false
	var platform_north := false
	var stop_ref1 := SeuzachGeo.gps_to_world(47.5358162, 8.7389630)
	var stop_ref2 := SeuzachGeo.gps_to_world(47.5358434, 8.7390122)
	for node in _collect_nodes(ground):
		if node.has_meta("terrain") and str(node.get_meta("terrain")) == "hill":
			hills += 1
		if node.has_meta("railway_kit"):
			var kit := str(node.get_meta("railway_kit"))
			if kit == "ballast":
				ballast_n += 1
			elif kit == "rail":
				rail_n += 1
		if node.has_meta("railway_kit") and str(node.get_meta("railway_kit")) == "platform":
			has_platform_kit = true
			if node is Polygon2D:
				for p in (node as Polygon2D).polygon:
					if p.y < stop_ref1.y and p.distance_to(stop_ref1) <= 400.0:
						platform_north = true
						break
		if node.has_meta("platform_ref") and str(node.get_meta("platform_ref")) == "2":
			has_platform_marker = true
			if node.position.y < stop_ref1.y:
				platform_north = true
		if not node.has_meta("poi_type") or str(node.get_meta("poi_type")) != "railway":
			continue
		rail_markers.append(node)
		_assert(not node.has_meta("road_name"), "railway marker has no road_name")
		_assert(
			not _has_named_ancestor(node, "DistrictOhringen"),
			"railway marker parent chain excludes DistrictOhringen"
		)
	_assert(hills == 0, "no hill markers")
	_assert(ballast_n >= 1, "Ground railway_kit=ballast ≥ 1 (got %d)" % ballast_n)
	_assert(rail_n >= 2, "Ground railway_kit=rail ≥ 2 (got %d)" % rail_n)
	_assert(rail_markers.size() >= 1, "Ground railway markers ≥ 1 (got %d)" % rail_markers.size())

	var through: Node = null
	var through_pts := PackedVector2Array()
	var through_len := 0.0
	var min_x := 1.0e9
	var max_x := -1.0e9
	var best_stop1 := 1.0e9
	var loop: Node = null
	var best_stop2 := 1.0e9
	for marker in rail_markers:
		if not marker.has_meta("track_ref") or not marker.has_meta("railway_points"):
			continue
		var tref := str(marker.get_meta("track_ref"))
		var pts: PackedVector2Array = PackedVector2Array(marker.get_meta("railway_points"))
		if pts.size() < 2:
			continue
		if tref == "1":
			for p in pts:
				min_x = minf(min_x, p.x)
				max_x = maxf(max_x, p.x)
			through_len = maxf(through_len, _polyline_len(pts))
			var d1 := _dist_to_polyline(stop_ref1, pts)
			if d1 <= best_stop1:
				best_stop1 = d1
				through_pts = pts
				through = marker
		elif tref == "2":
			loop = marker
			best_stop2 = minf(best_stop2, _dist_to_polyline(stop_ref2, pts))
	_assert(through != null, "track_ref=1 through marker present")
	if through != null:
		var half_w := float(through.get_meta("half_w")) if through.has_meta("half_w") else 38.0
		_assert(
			best_stop1 <= half_w + 40.0,
			"stop ref 1 on/near Gleis 1 (d=%.1f, need ≤%.1f)" % [best_stop1, half_w + 40.0]
		)
		var bahnhof := _find_named(sprites, "bahnhof")
		_assert(bahnhof != null, "bahnhof prop for railway side check")
		if bahnhof:
			_assert(
				bahnhof.position.y > stop_ref1.y,
				"bahnhof south of Gleis 1 / stop ref 1 (bahnhof.y=%.0f stop.y=%.0f)"
				% [bahnhof.position.y, stop_ref1.y]
			)
			var d_bldg := _dist_to_polyline(SeuzachGeo.bahnhof_world(), through_pts)
			_assert(
				d_bldg >= 80.0 and d_bldg <= 400.0,
				"bahnhof centroid 80–400 wu from Gleis 1 (d=%.1f)" % d_bldg
			)
		_assert(
			(min_x < 16000.0 and max_x > 28000.0) or through_len > 20000.0,
			"through spans Ost-Dorf (x %.0f..%.0f len=%.0f)" % [min_x, max_x, through_len]
		)
	_assert(loop != null or rail_markers.size() >= 2, "Gleis 2 marker or second railway polyline")
	if loop != null:
		var loop_hw := float(loop.get_meta("half_w")) if loop.has_meta("half_w") else 38.0
		_assert(
			best_stop2 <= loop_hw + 40.0,
			"stop ref 2 on/near Gleis 2 (d=%.1f)" % best_stop2
		)
	_assert(has_platform_kit or has_platform_marker, "Perron 2 kit polygon or platform_ref=2 marker")
	_assert(platform_north, "Perron 2 north of Gleis 1 (smaller Y than stop ref 1)")


func _assert_badi(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(
		is_equal_approx(SeuzachGeo.BADI_LAT, 47.5393193)
		and is_equal_approx(SeuzachGeo.BADI_LON, 8.7333710),
		"badi GPS constants match OSM facility centroid way 37106305 (not pool ways, not Birch)"
	)
	_assert(
		SeuzachGeo.badi_world().is_equal_approx(
			SeuzachGeo.gps_to_world(SeuzachGeo.BADI_LAT, SeuzachGeo.BADI_LON)
		),
		"badi_world() maps BADI_LAT/LON"
	)
	_assert(
		SeuzachGeo.badi_world().distance_to(Vector2(10277.6, -12220.2)) < 1.0,
		"badi_world() ≈ (10277.6, -12220.2)"
	)
	_assert(
		_count_landmark(sprites, "badi_weiher") == 1,
		"exactly one badi_weiher landmark (got %d)" % _count_landmark(sprites, "badi_weiher")
	)
	var badi := _find_named(sprites, "badi_weiher")
	_assert(badi != null, "node badi_weiher exists")
	_assert(_find_landmark(sprites, "badi_weiher") != null, "landmark_id badi_weiher present")
	_assert(_find_landmark(sprites, "sportplatz") == null, "no sportplatz prop")
	_assert(_count_poi(sprites, "stream") == 0, "no stream/bach sprite POIs")
	var house_n := 0
	var forest_n := 0
	for spr in sprites:
		if spr.has_meta("house_variant"):
			house_n += 1
		if spr.has_meta("terrain") and str(spr.get_meta("terrain")) == "forest":
			forest_n += 1
	_assert(house_n >= 6, "housing props present (got %d)" % house_n)
	_assert(forest_n >= 1, "forest props present (got %d)" % forest_n)
	for cluster in ["birch", "rietacker", "ohringen"]:
		var n := _count_school_cluster(sprites, cluster)
		_assert(n == 3, "school_cluster %s still has 3 props (got %d)" % [cluster, n])
	for kiga_id in KIGA_IDS:
		_assert(_has_kindergarten(sprites, str(kiga_id)), "%s still placed" % kiga_id)
	_assert(_count_landmark(sprites, "bahnhof") == 1, "bahnhof count stays 1")
	if badi == null:
		return
	_assert(
		str(badi.get_meta("landmark_id")) == "badi_weiher"
		and str(badi.get_meta("district")) == "seuzach"
		and str(badi.get_meta("poi_type")) == "swimming",
		"badi metas"
	)
	_assert(not badi.has_meta("school_cluster"), "badi has no school_cluster")
	_assert(not badi.has_meta("kindergarten_id"), "badi has no kindergarten_id")
	_assert(
		str(badi.get_meta("district")) != "forrenberg"
		and str(badi.get_meta("district")) != "ohringen",
		"badi district is not forrenberg or ohringen"
	)
	_assert(
		not _has_named_ancestor(badi, "DistrictOhringen"),
		"badi parent chain excludes DistrictOhringen"
	)
	_assert(
		badi.position.distance_to(SeuzachGeo.badi_world()) <= 720.0,
		"badi within 720 wu of OSM getter (d=%.1f)"
		% badi.position.distance_to(SeuzachGeo.badi_world())
	)
	_assert(
		badi.position.x > 5000.0 and badi.position.y < -8000.0,
		"badi north village north of Kirche (got %s)" % str(badi.position)
	)
	_assert(
		badi.position.y < SeuzachGeo.kiga_bachtobel_world().y,
		"badi north of Bachtobel (badi.y=%.0f bachtobel.y=%.0f)"
		% [badi.position.y, SeuzachGeo.kiga_bachtobel_world().y]
	)
	_assert(
		badi.position.x < SeuzachGeo.bahnhof_world().x,
		"badi west of Bahnhof (badi.x=%.0f bahnhof.x=%.0f)"
		% [badi.position.x, SeuzachGeo.bahnhof_world().x]
	)
	_assert(
		badi.position.x > SeuzachGeo.rietacker_world().x,
		"badi east of Rietacker (badi.x=%.0f rietacker.x=%.0f)"
		% [badi.position.x, SeuzachGeo.rietacker_world().x]
	)
	_assert(
		badi.position.distance_to(SeuzachGeo.forrenberg_world()) > 20000.0,
		"badi far from Forrenberg hub (d=%.0f)"
		% badi.position.distance_to(SeuzachGeo.forrenberg_world())
	)
	_assert(
		badi.position.distance_to(SeuzachGeo.ohringen_world()) > 15000.0,
		"badi far from Ohringen campus (d=%.0f)"
		% badi.position.distance_to(SeuzachGeo.ohringen_world())
	)
	_assert(
		badi.position.distance_to(SeuzachGeo.kiga_ohringen_world()) > 15000.0,
		"badi far from kiga_ohringen (d=%.0f)"
		% badi.position.distance_to(SeuzachGeo.kiga_ohringen_world())
	)
	_assert(
		badi.has_meta("has_building_collision") and bool(badi.get_meta("has_building_collision")),
		"badi has BuildingCollision"
	)
	_assert(not badi.flip_h, "badi flip_h false")
	_assert(is_zero_approx(badi.rotation), "badi rotation is 0")
	_assert_sprite_off_named_roads(world, badi)
	var ground: Node = world.get_node_or_null("%Ground")
	if ground:
		var hills := 0
		for node in _collect_nodes(ground):
			if node.has_meta("terrain") and str(node.get_meta("terrain")) == "hill":
				hills += 1
		_assert(hills == 0, "no hill markers")
		_assert_road_near(ground, "Landstrasse", SeuzachGeo.badi_world(), 2200.0)


func _assert_streams(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(
		FileAccess.file_exists("res://data/seuzach_water.json"),
		"data/seuzach_water.json exists"
	)
	_assert(_count_poi(sprites, "stream") == 0, "stream sprite POIs remain 0 (kit ≠ sprite)")
	_assert(_find_landmark(sprites, "riedbach") == null, "no riedbach landmark sprite")
	_assert(_find_landmark(sprites, "bach") == null, "no bach landmark sprite")
	var house_n := 0
	var forest_n := 0
	for spr in sprites:
		if spr.has_meta("house_variant"):
			house_n += 1
		if spr.has_meta("terrain") and str(spr.get_meta("terrain")) == "forest":
			forest_n += 1
	_assert(house_n >= 6, "housing props present (got %d)" % house_n)
	_assert(forest_n >= 1, "forest props present (got %d)" % forest_n)
	for cluster in ["birch", "rietacker", "ohringen"]:
		var n := _count_school_cluster(sprites, cluster)
		_assert(n == 3, "school_cluster %s still has 3 props (got %d)" % [cluster, n])
	for kiga_id in KIGA_IDS:
		_assert(_has_kindergarten(sprites, str(kiga_id)), "%s still placed" % kiga_id)
	_assert(_count_landmark(sprites, "bahnhof") == 1, "bahnhof count stays 1")
	_assert(_count_landmark(sprites, "badi_weiher") == 1, "badi count stays 1")

	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground for stream markers")
	if ground == null:
		return
	_assert(ground.get_node_or_null("Streams") != null, "Streams holder under Ground")
	var hills := 0
	var stream_markers: Array[Node] = []
	var water_n := 0
	var rail_markers := 0
	for node in _collect_nodes(ground):
		if node.has_meta("terrain") and str(node.get_meta("terrain")) == "hill":
			hills += 1
		if node.has_meta("water_kit") and str(node.get_meta("water_kit")) == "water":
			water_n += 1
		if node.has_meta("poi_type") and str(node.get_meta("poi_type")) == "railway":
			rail_markers += 1
		if not node.has_meta("poi_type") or str(node.get_meta("poi_type")) != "stream":
			continue
		stream_markers.append(node)
		_assert(not node.has_meta("road_name"), "stream marker has no road_name")
		_assert(not node.has_meta("railway_name"), "stream marker has no railway_name")
		_assert(
			not _has_named_ancestor(node, "DistrictOhringen"),
			"stream marker parent chain excludes DistrictOhringen"
		)
	_assert(hills == 0, "no hill markers")
	_assert(water_n >= 1, "Ground water_kit=water ≥ 1 (got %d)" % water_n)
	_assert(stream_markers.size() >= 1, "Ground stream markers ≥ 1 (got %d)" % stream_markers.size())
	_assert(rail_markers >= 1, "railway markers remain (got %d)" % rail_markers)
	var line2d := _count_line2d_nested(ground)
	_assert(line2d == 0, "Ground has no Line2D (got %d)" % line2d)

	var has_chreb := false
	var has_wels := false
	var has_bachtobel := false
	var has_ohringer := false
	var chreb_min_x := 1.0e9
	var chreb_max_x := -1.0e9
	var chreb_len := 0.0
	var chreb_hw := 16.0
	var wels_hw := 16.0
	var best_chreb := 1.0e9
	var best_wels := 1.0e9
	var best_bt := 1.0e9
	var best_ohr := 1.0e9
	## Vertex of OSM way 13872507 (plan GPS 47.5330924/8.7386221 is that way's bbox center).
	var chreb_sample := SeuzachGeo.gps_to_world(47.5341937, 8.7386451)
	var wels_sample := SeuzachGeo.gps_to_world(47.5393883, 8.7320363)
	var kiga_bt := SeuzachGeo.kiga_bachtobel_world()
	var ohr := SeuzachGeo.ohringen_world()
	for marker in stream_markers:
		var sname := str(marker.get_meta("stream_name")) if marker.has_meta("stream_name") else ""
		if sname == "Chrebsbach":
			has_chreb = true
			if marker.has_meta("half_w"):
				chreb_hw = float(marker.get_meta("half_w"))
		elif sname == "Welsikonerbach":
			has_wels = true
			if marker.has_meta("half_w"):
				wels_hw = float(marker.get_meta("half_w"))
		elif sname == "Bachtobelgraben":
			has_bachtobel = true
		elif sname == "Ohringerbach":
			has_ohringer = true
		if not marker.has_meta("stream_points"):
			continue
		var poly: PackedVector2Array = PackedVector2Array(marker.get_meta("stream_points"))
		if poly.size() < 2:
			continue
		best_bt = minf(best_bt, _dist_to_polyline(kiga_bt, poly))
		best_ohr = minf(best_ohr, _dist_to_polyline(ohr, poly))
		if sname == "Chrebsbach":
			chreb_len = maxf(chreb_len, _polyline_len(poly))
			best_chreb = minf(best_chreb, _dist_to_polyline(chreb_sample, poly))
			for p in poly:
				chreb_min_x = minf(chreb_min_x, p.x)
				chreb_max_x = maxf(chreb_max_x, p.x)
		elif sname == "Welsikonerbach":
			best_wels = minf(best_wels, _dist_to_polyline(wels_sample, poly))
	_assert(has_chreb, "stream_name=Chrebsbach marker present")
	_assert(
		best_chreb <= chreb_hw + 80.0,
		"Chrebsbach way 13872507 on/near band (d=%.1f, need ≤%.1f)" % [best_chreb, chreb_hw + 80.0]
	)
	_assert(
		(chreb_min_x < 8000.0 and chreb_max_x > 15000.0) or chreb_len > 12000.0,
		"Chrebsbach spans the village (x %.0f..%.0f len=%.0f)" % [chreb_min_x, chreb_max_x, chreb_len]
	)
	_assert(
		has_wels or best_wels <= wels_hw + 80.0,
		"Welsikonerbach marker or sample on band (marker=%s d=%.1f)" % [str(has_wels), best_wels]
	)
	if has_wels:
		_assert(
			best_wels <= wels_hw + 80.0,
			"Welsikonerbach way 758678996 on/near band (d=%.1f)" % best_wels
		)
	_assert(
		has_bachtobel or best_bt < 4000.0,
		"Bachtobelgraben marker or kiga within 4000 wu (marker=%s d=%.0f)"
		% [str(has_bachtobel), best_bt]
	)
	_assert(
		has_ohringer or best_ohr < 5000.0,
		"Ohringerbach marker or Ohringen within 5000 wu (marker=%s d=%.0f)"
		% [str(has_ohringer), best_ohr]
	)


func _assert_forests(world: Node, sprites: Array[Sprite2D]) -> void:
	_assert(
		FileAccess.file_exists("res://data/seuzach_forests.json"),
		"data/seuzach_forests.json exists"
	)
	var house_n := 0
	var forest_n := 0
	for spr in sprites:
		if spr.has_meta("house_variant"):
			house_n += 1
		if spr.has_meta("terrain") and str(spr.get_meta("terrain")) == "forest":
			forest_n += 1
			_assert(
				spr.has_meta("forest_kit") and str(spr.get_meta("forest_kit")) == "silhouette",
				"forest silhouette has forest_kit=silhouette (%s)" % spr.name
			)
			_assert(
				not spr.has_meta("has_building_collision")
				or not bool(spr.get_meta("has_building_collision")),
				"forest silhouette has no has_building_collision (%s)" % spr.name
			)
			_assert(
				spr.get_node_or_null("BuildingCollision") == null,
				"forest silhouette has no BuildingCollision (%s)" % spr.name
			)
			_assert(
				not _has_named_ancestor(spr, "DistrictOhringen"),
				"forest silhouette parent chain excludes DistrictOhringen (%s)" % spr.name
			)
			## Silhouettes clear asphalt; Ground floors may still sit under roads (maps-true).
	_assert(house_n >= 6, "housing props present (got %d)" % house_n)
	_assert(
		forest_n >= 3 and forest_n <= 10,
		"forest silhouettes 3–10 (got %d)" % forest_n
	)
	for cluster in ["birch", "rietacker", "ohringen"]:
		var n := _count_school_cluster(sprites, cluster)
		_assert(n == 3, "school_cluster %s still has 3 props (got %d)" % [cluster, n])
	for kiga_id in KIGA_IDS:
		_assert(_has_kindergarten(sprites, str(kiga_id)), "%s still placed" % kiga_id)
	_assert(_count_landmark(sprites, "bahnhof") == 1, "bahnhof count stays 1")
	_assert(_count_landmark(sprites, "badi_weiher") == 1, "badi count stays 1")

	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground for forest markers")
	if ground == null:
		return
	_assert(ground.get_node_or_null("Forests") != null, "Forests holder under Ground")
	var hills := 0
	var floor_n := 0
	var forest_markers: Array[Node] = []
	var stream_markers := 0
	var rail_markers := 0
	for node in _collect_nodes(ground):
		if node.has_meta("terrain") and str(node.get_meta("terrain")) == "hill":
			hills += 1
		if node.has_meta("forest_kit") and str(node.get_meta("forest_kit")) == "floor":
			floor_n += 1
		if node.has_meta("poi_type") and str(node.get_meta("poi_type")) == "stream":
			stream_markers += 1
		if node.has_meta("poi_type") and str(node.get_meta("poi_type")) == "railway":
			rail_markers += 1
		if not node.has_meta("poi_type") or str(node.get_meta("poi_type")) != "forest":
			continue
		forest_markers.append(node)
		_assert(not node.has_meta("road_name"), "forest marker has no road_name")
		_assert(not node.has_meta("railway_name"), "forest marker has no railway_name")
		_assert(not node.has_meta("stream_name"), "forest marker has no stream_name")
		_assert(
			not _has_named_ancestor(node, "DistrictOhringen"),
			"forest marker parent chain excludes DistrictOhringen"
		)
	_assert(hills == 0, "no hill markers")
	_assert(floor_n >= 3, "Ground forest_kit=floor ≥ 3 (got %d)" % floor_n)
	_assert(forest_markers.size() >= 3, "Ground forest markers ≥ 3 (got %d)" % forest_markers.size())
	_assert(stream_markers >= 1, "stream markers remain (got %d)" % stream_markers)
	_assert(rail_markers >= 1, "railway markers remain (got %d)" % rail_markers)
	var line2d := _count_line2d_nested(ground)
	_assert(line2d == 0, "Ground has no Line2D (got %d)" % line2d)

	var buech_sample := SeuzachGeo.gps_to_world(47.5306911, 8.7357986)
	var a1_sample := SeuzachGeo.gps_to_world(47.5281998, 8.7332964)
	var ohr_sample := SeuzachGeo.gps_to_world(47.5262718, 8.7123371)
	var nord_sample := SeuzachGeo.gps_to_world(47.5402506, 8.7179862)
	var has_buech_name := false
	var buech_hit := false
	var a1_hit := false
	var nord_hit := false
	var nord_y := false
	var best_a1_centroid := 1.0e9
	var best_ohr_ring := 1.0e9
	for marker in forest_markers:
		var fname := str(marker.get_meta("forest_name")) if marker.has_meta("forest_name") else ""
		if fname == "Buechwäldli":
			has_buech_name = true
		var pts := PackedVector2Array()
		if marker.has_meta("forest_points"):
			pts = PackedVector2Array(marker.get_meta("forest_points"))
		if fname == "Buechwäldli" or _sample_hits_forest(buech_sample, marker.position, pts):
			buech_hit = true
		if _sample_hits_forest(a1_sample, marker.position, pts):
			a1_hit = true
		if _sample_hits_forest(nord_sample, marker.position, pts):
			nord_hit = true
		if marker.position.y < -8000.0:
			nord_y = true
		best_a1_centroid = minf(
			best_a1_centroid, marker.position.distance_to(SeuzachGeo.forrenberg_world())
		)
		if pts.size() >= 3:
			best_ohr_ring = minf(best_ohr_ring, _dist_to_ring(SeuzachGeo.ohringen_world(), pts))
			best_ohr_ring = minf(best_ohr_ring, _dist_to_ring(ohr_sample, pts))
	_assert(
		has_buech_name or buech_hit,
		"Buechwäldli named marker or sample in a forest ring"
	)
	_assert(
		a1_hit or best_a1_centroid < 6000.0,
		"A1/Forrenberg sample in ring or centroid < 6000 wu (hit=%s d=%.0f)"
		% [str(a1_hit), best_a1_centroid]
	)
	_assert(
		best_ohr_ring < 5000.0,
		"Ohringen campus/sample within 5000 wu of a forest ring (d=%.0f)" % best_ohr_ring
	)
	_assert(
		nord_hit or nord_y,
		"Nord sample in ring or forest centroid y < -8000 (hit=%s y=%s)"
		% [str(nord_hit), str(nord_y)]
	)
	var stream_lines: Array[PackedVector2Array] = []
	for node in _collect_nodes(ground):
		if not node.has_meta("stream_points"):
			continue
		var spts: PackedVector2Array = PackedVector2Array(node.get_meta("stream_points"))
		if spts.size() >= 2:
			stream_lines.append(spts)
	for spr in sprites:
		if not spr.has_meta("terrain") or str(spr.get_meta("terrain")) != "forest":
			continue
		var best_stream := 1.0e9
		for spts in stream_lines:
			best_stream = minf(best_stream, _dist_to_polyline(spr.position, spts))
		_assert(
			best_stream >= 400.0,
			"forest silhouette %s off brooks (d=%.0f, need ≥400)"
			% [spr.name, best_stream]
		)


func _assert_forest_silhouettes_off_roads(world: Node, sprites: Array[Sprite2D]) -> void:
	## Prop silhouettes must clear named asphalt; Ground forest floors may underlay roads.
	var checked := 0
	for spr in sprites:
		var is_silhouette := (
			spr.has_meta("forest_kit") and str(spr.get_meta("forest_kit")) == "silhouette"
		) or (
			spr.has_meta("terrain")
			and str(spr.get_meta("terrain")) == "forest"
			and spr is Sprite2D
		)
		if not is_silhouette:
			continue
		checked += 1
		_assert_sprite_off_named_roads(world, spr)
	_assert(checked >= 3, "forest silhouettes off-road checked ≥3 (got %d)" % checked)


func _sample_hits_forest(sample: Vector2, centroid: Vector2, pts: PackedVector2Array) -> bool:
	if centroid.distance_to(sample) <= 80.0:
		return true
	if pts.size() >= 3 and Geometry2D.is_point_in_polygon(sample, pts):
		return true
	return false


func _dist_to_ring(p: Vector2, pts: PackedVector2Array) -> float:
	if pts.size() >= 3 and Geometry2D.is_point_in_polygon(p, pts):
		return 0.0
	if pts.is_empty():
		return 1.0e9
	var closed := PackedVector2Array(pts)
	if closed[0].distance_to(closed[closed.size() - 1]) > 1.0:
		closed.append(closed[0])
	return _dist_to_polyline(p, closed)


func _count_line2d_nested(node: Node) -> int:
	var n := 0
	if node is Line2D:
		n += 1
	for child in node.get_children():
		n += _count_line2d_nested(child)
	return n


func _polyline_len(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total


func _assert_sprite_off_named_roads(world: Node, spr: Sprite2D) -> void:
	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground for %s-vs-road clearance" % spr.name)
	if ground == null:
		return
	var aabb := _school_aabb(spr)
	var edge := _clear_edge_margin_for(spr)
	var street_half := _street_half_for(spr, aabb)
	for node in _collect_nodes(ground):
		if not node.has_meta("road_name") or not node.has_meta("road_points"):
			continue
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		if pts.size() < 2:
			continue
		var half_w := float(node.get_meta("half_w")) if node.has_meta("half_w") else 36.0
		var d_feet := _dist_to_polyline(spr.position, pts)
		var d_aabb := _dist_aabb_to_polyline(aabb, pts)
		## Matches world_sandbox: street-facing half when street_bearing is set.
		var need_feet := half_w + street_half + edge
		var need_aabb := half_w + edge
		var road_name := str(node.get_meta("road_name"))
		_assert(
			d_feet >= need_feet,
			"%s must sit off %s (d=%.0f, need ≥%.0f)"
			% [spr.name, road_name, d_feet, need_feet]
		)
		_assert(
			d_aabb >= need_aabb,
			"%s facade must sit off %s (aabb d=%.0f, need ≥%.0f)"
			% [spr.name, road_name, d_aabb, need_aabb]
		)


func _assert_geo_quadrants(sprites: Array[Sprite2D]) -> void:
	## +X east, +Y south; Kirche ~ (0,0); Forrenberg south; Badi north; Ohringen SW.
	var hub := _find_landmark(sprites, "hub_station")
	var tank := _find_landmark(sprites, "tankstelle")
	var badi := _find_landmark(sprites, "badi_weiher")
	var bahnhof := _find_landmark(sprites, "bahnhof")
	var ohringen_school := _find_landmark(sprites, "schulhaus_ohringen")
	var birch := _find_landmark(sprites, "schulhaus_birch")
	var rietacker := _find_landmark(sprites, "schulhaus_rietacker")

	if hub:
		_assert(hub.position.y > 400.0, "hub south at Forrenberg (y>400, got %.0f)" % hub.position.y)
		_assert(
			hub.has_meta("district") and str(hub.get_meta("district")) == "forrenberg",
			"hub district=forrenberg"
		)
	if tank:
		_assert(
			tank.position.distance_to(SeuzachGeo.forrenberg_world()) < 800.0,
			"tankstelle near Forrenberg hub"
		)
	_assert(badi != null, "badi present in geo quadrants")
	if badi:
		_assert(
			badi.position.y < -8000.0,
			"badi north of Kirche (y<-8000, got %.0f)" % badi.position.y
		)
		_assert(
			badi.position.x > 5000.0,
			"badi east of Kirche at field scale (x>5000, got %.0f)" % badi.position.x
		)
	_assert(bahnhof != null, "bahnhof present in geo quadrants")
	if bahnhof:
		_assert(
			bahnhof.position.x > 10000.0,
			"bahnhof east of Kirche at field scale (x>10000, got %.0f)" % bahnhof.position.x
		)
	if ohringen_school:
		_assert(
			ohringen_school.position.x < -15000.0 and ohringen_school.position.y > 8000.0,
			"ohringen school SW (got %s)" % str(ohringen_school.position)
		)
		_assert(
			ohringen_school.position.distance_to(SeuzachGeo.ohringen_world()) < 1400.0,
			"ohringen school near Nominatim GPS (1400 wu covers OSM a + clearance nudge)"
		)
	if birch and rietacker:
		_assert(
			birch.position.x > rietacker.position.x,
			"birch east of rietacker (birch.x=%.0f rietacker.x=%.0f)"
			% [birch.position.x, rietacker.position.x]
		)
		## First schulhaus_birch is a (~836 wu east of the yard centroid). 800 wu is too tight.
		_assert(
			birch.position.distance_to(SeuzachGeo.birch_world()) < 1400.0,
			"birch school near Nominatim GPS (1400 wu covers OSM building a)"
		)
		_assert(
			rietacker.position.distance_to(SeuzachGeo.rietacker_world()) < 1600.0,
			"rietacker school near Nominatim GPS (1600 wu covers OSM gym)"
		)


func _assert_schools_off_roads(world: Node, sprites: Array[Sprite2D]) -> void:
	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground for school-vs-road clearance")
	if ground == null:
		return
	var roads: Array[Dictionary] = []
	for node in _collect_nodes(ground):
		if not node.has_meta("road_name") or not node.has_meta("road_points"):
			continue
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		if pts.size() < 2:
			continue
		roads.append({
			"name": str(node.get_meta("road_name")),
			"half_w": float(node.get_meta("half_w")) if node.has_meta("half_w") else 36.0,
			"points": pts,
		})
	_assert(not roads.is_empty(), "named road polylines present for school clearance")
	var checked := 0
	for spr in sprites:
		var is_building := (
			spr.has_meta("school_cluster")
			or spr.has_meta("kindergarten_id")
			or spr.has_meta("house_variant")
			or (
				spr.has_meta("landmark_id")
				and str(spr.get_meta("landmark_id")) in ["bahnhof", "badi_weiher", "feuerwehr"]
			)
		)
		if not is_building:
			continue
		checked += 1
		var aabb := _school_aabb(spr)
		var edge := _clear_edge_margin_for(spr)
		var street_half := _street_half_for(spr, aabb)
		for road in roads:
			var half_w := float(road["half_w"])
			var pts: PackedVector2Array = road["points"]
			var d_feet := _dist_to_polyline(spr.position, pts)
			var d_aabb := _dist_aabb_to_polyline(aabb, pts)
			var need_feet := half_w + street_half + edge
			var need_aabb := half_w + edge
			_assert(
				d_feet >= need_feet,
				"%s must sit off %s (d=%.0f, need ≥%.0f)"
				% [spr.name, str(road["name"]), d_feet, need_feet]
			)
			_assert(
				d_aabb >= need_aabb,
				"%s facade must sit off %s (aabb d=%.0f, need ≥%.0f)"
				% [spr.name, str(road["name"]), d_aabb, need_aabb]
			)
	_assert(checked >= 10, "visual clear checked for buildings (got %d)" % checked)


func _clear_edge_margin_for(spr: Sprite2D) -> float:
	## Houses use HOUSE_CLEAR_EDGE_MARGIN (12); landmarks/schools keep BUILDING (40).
	if spr.has_meta("house_variant"):
		return 12.0
	return 40.0


func _street_half_for(spr: Sprite2D, aabb: Rect2) -> float:
	## Houses and street-aligned schools: ns → clear.x/2, ew → clear.y/2.
	## Other landmarks keep isotropic clear.y/2.
	var bearing := ""
	if spr.has_meta("street_bearing"):
		bearing = str(spr.get_meta("street_bearing"))
	elif spr.has_meta("house_variant"):
		if str(spr.get_meta("house_variant")).ends_with("_ns"):
			bearing = "ns"
		else:
			bearing = "ew"
	if bearing != "":
		return (aabb.size.x if bearing == "ns" else aabb.size.y) * 0.5
	return aabb.size.y * 0.5


func _assert_ns_house_art_not_rotate_of_ew() -> void:
	## Guard: NS must be upright-authored, not PIL ROTATE_270 of EW (= Godot rotate_90 CLOCKWISE).
	var bases: Array[String] = [
		"house_street_a",
		"house_street_b",
		"house_street_flachdach",
		"house_street_reihen",
		"landmark_schulhaus_birch_a",
		"landmark_schulhaus_birch_b",
		"landmark_turnhalle_birch",
		"landmark_schulhaus_rietacker_a",
		"landmark_schulhaus_rietacker_b",
		"landmark_turnhalle_rietacker",
		"landmark_schulhaus_ohringen_a",
		"landmark_schulhaus_ohringen_b",
		"landmark_turnhalle_ohringen",
		"landmark_kiga_ohringen",
		"landmark_kiga_bachtobel",
		"landmark_kiga_weid",
		"landmark_kiga_schneckenwiese",
	]
	for base in bases:
		var ew_path := ART + base + "_ew.png"
		var ns_path := ART + base + "_ns.png"
		_assert(ResourceLoader.exists(ew_path), "ew art exists %s" % ew_path)
		_assert(ResourceLoader.exists(ns_path), "ns art exists %s" % ns_path)
		var ew_tex: Texture2D = load(ew_path)
		var ns_tex: Texture2D = load(ns_path)
		_assert(ew_tex != null and ns_tex != null, "ew/ns textures load for %s" % base)
		if ew_tex == null or ns_tex == null:
			continue
		var ew_img: Image = ew_tex.get_image()
		var ns_img: Image = ns_tex.get_image()
		_assert(ew_img != null and ns_img != null, "ew/ns images for %s" % base)
		if ew_img == null or ns_img == null:
			continue
		var rotated := ew_img.duplicate()
		rotated.rotate_90(CLOCKWISE)
		var same_size: bool = (
			rotated.get_width() == ns_img.get_width()
			and rotated.get_height() == ns_img.get_height()
		)
		if not same_size:
			continue
		## Cheap sample grid: identical ROTATE_270 would match every sample.
		var identical: bool = true
		var step_x: int = maxi(1, rotated.get_width() / 8)
		var step_y: int = maxi(1, rotated.get_height() / 8)
		for y in range(0, rotated.get_height(), step_y):
			for x in range(0, rotated.get_width(), step_x):
				if rotated.get_pixel(x, y) != ns_img.get_pixel(x, y):
					identical = false
					break
			if not identical:
				break
		_assert(not identical, "%s_ns must not be ROTATE_270 of _ew" % base)


func _assert_texture_unprefixed(spr: Sprite2D) -> void:
	if spr == null or spr.texture == null:
		return
	var file_name := spr.texture.resource_path.get_file()
	_assert(
		not file_name.ends_with("_ew.png") and not file_name.ends_with("_ns.png"),
		"%s stays on unprefixed art (got %s)" % [spr.name, file_name]
	)


func _named_roads_from_world(world: Node, road_name: String) -> Array[Dictionary]:
	var ground: Node = world.get_node_or_null("%Ground")
	var out: Array[Dictionary] = []
	if ground == null:
		return out
	for node in _collect_nodes(ground):
		if not node.has_meta("road_name") or str(node.get_meta("road_name")) != road_name:
			continue
		if not node.has_meta("road_points"):
			continue
		var pts: PackedVector2Array = PackedVector2Array(node.get_meta("road_points"))
		if pts.size() < 2:
			continue
		out.append({
			"name": road_name,
			"half_w": float(node.get_meta("half_w")) if node.has_meta("half_w") else 36.0,
			"points": pts,
		})
	return out


func _assert_school_street_prop(
	world: Node,
	spr: Sprite2D,
	target_road_name: String,
	west_of_road: bool,
	bank: String = ""
) -> void:
	## Regression vs the 1425-wu / no-facing Birch repro: target polyline, suffix, curb flip.
	## bank: west|east|north|south. Empty keeps Birch west_of_road (x).
	if spr == null:
		return
	_assert(spr.has_meta("street_bearing"), "%s has street_bearing" % spr.name)
	_assert(spr.has_meta("faces_street") and bool(spr.get_meta("faces_street")), "%s faces_street" % spr.name)
	_assert(spr.has_meta("street_side"), "%s has street_side" % spr.name)
	_assert(spr.has_meta("street_name") and str(spr.get_meta("street_name")) == target_road_name, "%s street_name == %s" % [spr.name, target_road_name])
	_assert(is_zero_approx(spr.rotation), "%s rotation is 0" % spr.name)
	var side := int(spr.get_meta("street_side")) if spr.has_meta("street_side") else 0
	_assert(side == 1 or side == -1, "%s street_side is ±1 (got %d)" % [spr.name, side])
	var bearing := str(spr.get_meta("street_bearing")) if spr.has_meta("street_bearing") else ""
	_assert(bearing == "ew" or bearing == "ns", "%s street_bearing ew|ns (got %s)" % [spr.name, bearing])
	var file_name := spr.texture.resource_path.get_file() if spr.texture != null else ""
	_assert(
		file_name.ends_with("_%s.png" % bearing),
		"%s texture suffix matches street_bearing (got %s)" % [spr.name, file_name]
	)
	_assert(
		not file_name.ends_with("landmark_schulhaus_birch_a.png")
		and not file_name.ends_with("landmark_schulhaus_birch_b.png")
		and not file_name.ends_with("landmark_turnhalle_birch.png")
		and not file_name.ends_with("landmark_schulhaus_rietacker_a.png")
		and not file_name.ends_with("landmark_schulhaus_rietacker_b.png")
		and not file_name.ends_with("landmark_turnhalle_rietacker.png")
		and not file_name.ends_with("landmark_schulhaus_ohringen_a.png")
		and not file_name.ends_with("landmark_schulhaus_ohringen_b.png")
		and not file_name.ends_with("landmark_turnhalle_ohringen.png")
		and not file_name.ends_with("landmark_kiga_ohringen.png")
		and not file_name.ends_with("landmark_kiga_bachtobel.png")
		and not file_name.ends_with("landmark_kiga_weid.png")
		and not file_name.ends_with("landmark_kiga_schneckenwiese.png"),
		"%s must not load unprefixed Birch/Rietacker/Ohringen/Seuzach-kiga art (got %s)" % [spr.name, file_name]
	)
	var roads := _named_roads_from_world(world, target_road_name)
	_assert(not roads.is_empty(), "%s target road %s present" % [spr.name, target_road_name])
	if roads.is_empty():
		return
	var nearest := _nearest_road_sample(spr.position, roads)
	_assert(nearest.has("point") and nearest.has("tangent"), "%s nearest %s sample" % [spr.name, target_road_name])
	if not nearest.has("point"):
		return
	var closest: Vector2 = nearest["point"]
	var bank_mode := bank
	if bank_mode == "":
		bank_mode = "west" if west_of_road else "east"
	if bank_mode == "west":
		_assert(
			spr.position.x < closest.x,
			"%s west of %s (x=%.0f closest.x=%.0f)"
			% [spr.name, target_road_name, spr.position.x, closest.x]
		)
	elif bank_mode == "east":
		_assert(
			spr.position.x > closest.x,
			"%s east of %s (x=%.0f closest.x=%.0f)"
			% [spr.name, target_road_name, spr.position.x, closest.x]
		)
	elif bank_mode == "north":
		_assert(
			spr.position.y < closest.y,
			"%s north of %s (y=%.0f closest.y=%.0f)"
			% [spr.name, target_road_name, spr.position.y, closest.y]
		)
	elif bank_mode == "south":
		_assert(
			spr.position.y > closest.y,
			"%s south of %s (y=%.0f closest.y=%.0f)"
			% [spr.name, target_road_name, spr.position.y, closest.y]
		)
	else:
		_assert(false, "%s unknown bank %s" % [spr.name, bank_mode])
	var d: float = float(nearest.get("dist", spr.position.distance_to(closest)))
	var aabb := _school_aabb(spr)
	var street_half := _street_half_for(spr, aabb)
	var half_w := float(roads[0]["half_w"])
	var need := half_w + street_half + 40.0
	_assert(
		d < 800.0,
		"%s %s setback-band not ~1425 wu (d=%.1f)" % [spr.name, target_road_name, d]
	)
	_assert(
		d >= need - 12.0,
		"%s %s distance in setback band (d=%.1f need=%.1f)"
		% [spr.name, target_road_name, d, need]
	)
	var tangent: Vector2 = nearest["tangent"]
	var expect_bearing := "ew" if absf(tangent.x) >= absf(tangent.y) else "ns"
	_assert(
		bearing == expect_bearing,
		"%s street_bearing matches %s tangent (got %s expect %s)"
		% [spr.name, target_road_name, bearing, expect_bearing]
	)
	_assert_flip_matches_bearing(spr, "_" + bearing, side, nearest)


func _school_aabb(spr: Sprite2D) -> Rect2:
	## Visual clear AABB — houses: HOUSE_CLEAR 0.70/0.55; landmarks: BUILDING 0.95/0.88.
	## Centered on visual body (feet at node origin); not BuildingCollision 0.20/0.10.
	if spr.texture == null:
		return Rect2(spr.position, Vector2.ZERO)
	var tex_w := float(spr.texture.get_width()) * absf(spr.scale.x)
	var tex_h := float(spr.texture.get_height()) * absf(spr.scale.y)
	var w_frac := 0.70 if spr.has_meta("house_variant") else 0.95
	var h_frac := 0.55 if spr.has_meta("house_variant") else 0.88
	var footprint_w := maxf(24.0, tex_w * w_frac)
	var footprint_h := maxf(16.0, tex_h * h_frac)
	var visual_center_y := -tex_h * 0.5
	var center := spr.position + Vector2(0.0, visual_center_y)
	return Rect2(center - Vector2(footprint_w, footprint_h) * 0.5, Vector2(footprint_w, footprint_h))


func _dist_to_polyline(p: Vector2, pts: PackedVector2Array) -> float:
	if pts.is_empty():
		return 1.0e9
	var best := p.distance_to(pts[0])
	for i in range(pts.size() - 1):
		best = minf(best, _dist_to_segment(p, pts[i], pts[i + 1]))
	return best


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
	var edges: Array[Vector2] = [c0, c1, c2, c3, c0]
	for i in range(4):
		if Geometry2D.segment_intersects_segment(a, b, edges[i], edges[i + 1]) != null:
			return 0.0
	var best := 1.0e9
	for c in [c0, c1, c2, c3]:
		best = minf(best, _dist_to_segment(c, a, b))
	best = minf(best, _dist_point_to_rect(a, rect))
	best = minf(best, _dist_point_to_rect(b, rect))
	return best


func _dist_point_to_rect(p: Vector2, rect: Rect2) -> float:
	var q := Vector2(
		clampf(p.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(p.y, rect.position.y, rect.position.y + rect.size.y)
	)
	return p.distance_to(q)


func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _find_landmark(sprites: Array[Sprite2D], landmark_id: String) -> Sprite2D:
	for spr in sprites:
		if spr.has_meta("landmark_id") and str(spr.get_meta("landmark_id")) == landmark_id:
			return spr
	return null


func _find_named(sprites: Array[Sprite2D], node_name: String) -> Sprite2D:
	for spr in sprites:
		if str(spr.name) == node_name:
			return spr
	return null


func _has_named_ancestor(node: Node, ancestor_name: String) -> bool:
	var cur: Node = node.get_parent()
	while cur != null:
		if str(cur.name) == ancestor_name:
			return true
		cur = cur.get_parent()
	return false


func _finish() -> void:
	if _failed == 0:
		print("=== m3_world_landmarks_test PASS ===")
		quit(0)
	else:
		printerr("=== m3_world_landmarks_test FAIL (%d) ===" % _failed)
		quit(1)


func _collect_sprites(root_node: Node) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	_collect_sprites_recursive(root_node, out)
	return out


func _collect_sprites_recursive(node: Node, out: Array[Sprite2D]) -> void:
	if node is Sprite2D:
		out.append(node as Sprite2D)
	for child in node.get_children():
		_collect_sprites_recursive(child, out)


func _collect_nodes(root_node: Node) -> Array[Node]:
	var out: Array[Node] = []
	_collect_nodes_recursive(root_node, out)
	return out


func _collect_nodes_recursive(node: Node, out: Array[Node]) -> void:
	out.append(node)
	for child in node.get_children():
		_collect_nodes_recursive(child, out)


func _count_landmark(sprites: Array[Sprite2D], landmark_id: String) -> int:
	var n := 0
	for spr in sprites:
		if spr.has_meta("landmark_id") and str(spr.get_meta("landmark_id")) == landmark_id:
			n += 1
	return n


func _count_school_cluster(sprites: Array[Sprite2D], cluster: String) -> int:
	var n := 0
	for spr in sprites:
		if spr.has_meta("school_cluster") and str(spr.get_meta("school_cluster")) == cluster:
			n += 1
	return n


func _has_kindergarten(sprites: Array[Sprite2D], kiga_id: String) -> bool:
	for spr in sprites:
		if spr.has_meta("landmark_id") and str(spr.get_meta("landmark_id")) == kiga_id:
			return true
		if spr.has_meta("kindergarten_id") and str(spr.get_meta("kindergarten_id")) == kiga_id:
			return true
	return false


func _count_poi(sprites: Array[Sprite2D], poi_type: String) -> int:
	var n := 0
	for spr in sprites:
		if spr.has_meta("poi_type") and str(spr.get_meta("poi_type")) == poi_type:
			n += 1
			continue
		if poi_type == "restaurant" and spr.has_meta("landmark_id"):
			if str(spr.get_meta("landmark_id")).begins_with("restaurant"):
				n += 1
	return n


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
