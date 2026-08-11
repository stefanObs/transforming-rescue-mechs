extends SceneTree
## M3 Seuzach street map: art on disk, world is roads-only (no landmarks/houses).

const ART := "res://assets/art/"
const REQUIRED_ART := [
	"landmark_bahnhof_seuzach.png",
	"landmark_feuerwehr_seuzach.png",
	"landmark_badi_weiher.png",
	"landmark_schulhaus_birch_a.png",
	"landmark_schulhaus_birch_b.png",
	"landmark_schulhaus_rietacker_a.png",
	"landmark_schulhaus_rietacker_b.png",
	"landmark_schulhaus_ohringen_a.png",
	"landmark_schulhaus_ohringen_b.png",
	"landmark_turnhalle_ohringen.png",
	"house_a.png",
	"house_b.png",
	"house_c.png",
	"house_d.png",
	"house_farm.png",
	"landmark_kiga_bachtobel.png",
	"landmark_kiga_weid.png",
	"landmark_kiga_schneckenwiese.png",
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
	_assert(house_n == 0, "no housing props in street-map reset (got %d)" % house_n)
	_assert(forest_n == 0, "street map has no forest props (got %d)" % forest_n)

	for cluster in ["birch", "rietacker", "ohringen"]:
		var n := _count_school_cluster(all_sprites, cluster)
		_assert(n >= 2, "school_cluster %s has >=2 props (got %d)" % [cluster, n])
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
	if badi:
		_assert(badi.position.y < -200.0, "badi north of Kirche (y<-200, got %.0f)" % badi.position.y)
	if bahnhof:
		_assert(bahnhof.position.x > 500.0, "bahnhof east (x>500, got %.0f)" % bahnhof.position.x)
	if ohringen_school:
		_assert(
			ohringen_school.position.x < -15000.0 and ohringen_school.position.y > 8000.0,
			"ohringen school SW (got %s)" % str(ohringen_school.position)
		)
		_assert(
			ohringen_school.position.distance_to(SeuzachGeo.ohringen_world()) < 800.0,
			"ohringen school near Nominatim GPS"
		)
	if birch and rietacker:
		_assert(
			birch.position.x > rietacker.position.x,
			"birch east of rietacker (birch.x=%.0f rietacker.x=%.0f)"
			% [birch.position.x, rietacker.position.x]
		)
		_assert(
			birch.position.distance_to(SeuzachGeo.birch_world()) < 800.0,
			"birch school near Nominatim GPS"
		)
		_assert(
			rietacker.position.distance_to(SeuzachGeo.rietacker_world()) < 800.0,
			"rietacker school near Nominatim GPS"
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
	for spr in sprites:
		if not spr.has_meta("school_cluster"):
			continue
		var aabb := _school_aabb(spr)
		for road in roads:
			var half_w := float(road["half_w"])
			var pts: PackedVector2Array = road["points"]
			var d_feet := _dist_to_polyline(spr.position, pts)
			var d_aabb := _dist_aabb_to_polyline(aabb, pts)
			var need_feet := half_w + 14.0 + 50.0
			var need_aabb := half_w + 14.0
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


func _school_aabb(spr: Sprite2D) -> Rect2:
	## Feet on origin, facade extends up (smaller Y) and sideways.
	if spr.texture == null:
		return Rect2(spr.position, Vector2.ZERO)
	var tw := float(spr.texture.get_width()) * absf(spr.scale.x)
	var th := float(spr.texture.get_height()) * absf(spr.scale.y)
	return Rect2(Vector2(spr.position.x - tw * 0.5, spr.position.y - th), Vector2(tw, th))


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
