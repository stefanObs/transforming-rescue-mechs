extends SceneTree
## M3 Seuzach geo-aligned world: landmarks, schools, kigas, forests, hills, Forrenberg hub.

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

	for landmark_id in [
		"bahnhof",
		"feuerwehr",
		"badi_weiher",
		"gemeindehaus",
		"tankstelle",
		"kirche_seuzach",
		"kirche_st_martin",
		"hub_station",
		"sportplatz",
		"turnhalle_ohringen",
	]:
		_assert(
			_count_landmark(all_sprites, landmark_id) >= 1,
			"landmark %s present" % landmark_id
		)

	_assert(_count_landmark(all_sprites, "kirche_ohringen") == 0, "no fake kirche_ohringen")

	for cluster in ["birch", "rietacker", "ohringen"]:
		var n := _count_school_cluster(all_sprites, cluster)
		_assert(n >= 2, "school_cluster %s has >=2 props (got %d)" % [cluster, n])

	for kiga_id in KIGA_IDS:
		_assert(
			_has_kindergarten(all_sprites, kiga_id),
			"kindergarten %s present (landmark_id or kindergarten_id)" % kiga_id
		)

	var restaurant_n := _count_poi(all_sprites, "restaurant")
	_assert(restaurant_n >= 1, "≥1 restaurant (got %d)" % restaurant_n)

	var shop_n := _count_poi(all_sprites, "shop")
	var laden_n := 0
	for spr in all_sprites:
		if spr.has_meta("landmark_id") and str(spr.get_meta("landmark_id")).begins_with("laden"):
			laden_n += 1
	var shop_or_laden := maxi(shop_n, laden_n)
	_assert(shop_or_laden >= 2, "≥2 laden/shop (got shop=%d laden=%d)" % [shop_n, laden_n])

	var playground_n := _count_poi(all_sprites, "playground")
	_assert(playground_n >= 1, "≥1 playground (got %d)" % playground_n)

	var gym_n := _count_poi(all_sprites, "gym")
	_assert(gym_n >= 1, "≥1 turnhalle/gym (got %d)" % gym_n)

	var forest_n := 0
	for spr in all_sprites:
		if spr.has_meta("terrain") and str(spr.get_meta("terrain")) == "forest":
			forest_n += 1
	_assert(forest_n >= 1, "≥1 forest prop (got %d)" % forest_n)

	var variants: Dictionary = {}
	for spr in all_sprites:
		if spr.has_meta("house_variant"):
			variants[str(spr.get_meta("house_variant"))] = true
	_assert(
		variants.size() >= 4,
		"≥4 distinct house_variant values (got %d: %s)" % [variants.size(), str(variants.keys())]
	)

	var ohringen: Node = props.get_node_or_null("DistrictOhringen")
	_assert(ohringen != null, "DistrictOhringen node exists")
	if ohringen:
		_assert(
			ohringen.get_child_count() >= 1,
			"DistrictOhringen has children (got %d)" % ohringen.get_child_count()
		)
		_assert(
			ohringen.has_meta("district") and str(ohringen.get_meta("district")) == "ohringen",
			"DistrictOhringen meta district=ohringen"
		)

	_assert_geo_quadrants(all_sprites)

	var ground: Node = world.get_node_or_null("%Ground")
	_assert(ground != null, "Ground node exists")
	if ground:
		var hills := 0
		for node in _collect_nodes(ground):
			if node.has_meta("terrain") and str(node.get_meta("terrain")) == "hill":
				hills += 1
		_assert(hills >= 2, "≥2 hill markers (got %d)" % hills)

	world.queue_free()
	_finish()


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
			tank.position.distance_to(Vector2(490, 600)) < 350.0,
			"tankstelle near Forrenberg hub"
		)
	if badi:
		_assert(badi.position.y < -200.0, "badi north of Kirche (y<-200, got %.0f)" % badi.position.y)
	if bahnhof:
		_assert(bahnhof.position.x > 500.0, "bahnhof east (x>500, got %.0f)" % bahnhof.position.x)
	if ohringen_school:
		_assert(
			ohringen_school.position.x < -500.0 and ohringen_school.position.y > 200.0,
			"ohringen school SW (got %s)" % str(ohringen_school.position)
		)
	if birch and rietacker:
		_assert(
			birch.position.x > rietacker.position.x,
			"birch east of rietacker (birch.x=%.0f rietacker.x=%.0f)"
			% [birch.position.x, rietacker.position.x]
		)


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
