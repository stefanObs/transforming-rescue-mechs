class_name RoadKit
extends RefCounted
## Procedural Style-C road pieces: straight/diagonal ribbons, sidewalks, CH dashed
## centerline, roundabout ring + grass island. Prefers Polygon2D (no Line2D grids).

const COLOR_ROAD := Color("8E8E8E")
const COLOR_SIDEWALK := Color("C8C8C8")
const COLOR_STRIPE := Color("F5F5F5")
const COLOR_ISLAND := Color("3DCC5A")

const DEFAULT_HALF_W := 40.0
const DEFAULT_SIDEWALK_W := 14.0
const DEFAULT_DASH_LEN := 18.0
const DEFAULT_GAP_LEN := 14.0
const DEFAULT_STRIPE_HALF_W := 3.0
const Z_SIDEWALK := -41
const Z_ROAD := -40
const Z_STRIPE := -39
const Z_ISLAND := -38
const ROUNDABOUT_SEGS := 48


## opts: sidewalk (bool), centerline (bool), half_w (float), sidewalk_w (float),
## dash_len, gap_len, stripe_half_w
static func add_straight(parent: Node2D, a: Vector2, b: Vector2, opts: Dictionary = {}) -> void:
	if parent == null:
		return
	var delta := b - a
	var length := delta.length()
	if length < 0.001:
		return
	var half_w: float = float(opts.get("half_w", DEFAULT_HALF_W))
	var sidewalk_w: float = float(opts.get("sidewalk_w", DEFAULT_SIDEWALK_W))
	var want_sidewalk: bool = bool(opts.get("sidewalk", false))
	var want_centerline: bool = bool(opts.get("centerline", false))
	var tangent := delta / length
	var normal := Vector2(-tangent.y, tangent.x)

	if want_sidewalk and sidewalk_w > 0.0:
		_add_ribbon(
			parent,
			a,
			b,
			normal,
			half_w,
			half_w + sidewalk_w,
			COLOR_SIDEWALK,
			Z_SIDEWALK,
			"sidewalk"
		)
		_add_ribbon(
			parent,
			a,
			b,
			normal,
			-(half_w + sidewalk_w),
			-half_w,
			COLOR_SIDEWALK,
			Z_SIDEWALK,
			"sidewalk"
		)

	_add_ribbon(parent, a, b, normal, -half_w, half_w, COLOR_ROAD, Z_ROAD, "road")

	if want_centerline:
		_add_dashed_line(parent, a, b, tangent, normal, opts)


## Alias of add_straight for iso/diagonal segments (same geometry API).
static func add_diagonal(parent: Node2D, a: Vector2, b: Vector2, opts: Dictionary = {}) -> void:
	add_straight(parent, a, b, opts)


## Ring road around center; radius is ring midline. opts: sidewalk, centerline (default off —
## no mittellinie on rings; opt-in for debug only), sidewalk_w, …
static func add_roundabout(
	parent: Node2D,
	center: Vector2,
	radius: float,
	ring_half_w: float,
	opts: Dictionary = {}
) -> void:
	if parent == null or radius <= 0.0 or ring_half_w <= 0.0:
		return
	var sidewalk_w: float = float(opts.get("sidewalk_w", DEFAULT_SIDEWALK_W))
	var want_sidewalk: bool = bool(opts.get("sidewalk", false))
	var want_centerline: bool = bool(opts.get("centerline", false))
	var r_inner := maxf(radius - ring_half_w, 1.0)
	var r_outer := radius + ring_half_w

	if want_sidewalk and sidewalk_w > 0.0:
		_add_annulus(
			parent,
			center,
			r_outer,
			r_outer + sidewalk_w,
			COLOR_SIDEWALK,
			Z_SIDEWALK,
			"sidewalk"
		)

	_add_annulus(parent, center, r_inner, r_outer, COLOR_ROAD, Z_ROAD, "road")

	var island := Polygon2D.new()
	island.color = COLOR_ISLAND
	island.z_index = Z_ISLAND
	island.polygon = _circle_points(center, r_inner * 0.92, ROUNDABOUT_SEGS)
	island.set_meta("road_kit", "island")
	parent.add_child(island)

	if want_centerline:
		_add_dashed_circle(parent, center, radius, opts)


static func _add_ribbon(
	parent: Node2D,
	a: Vector2,
	b: Vector2,
	normal: Vector2,
	offset_a: float,
	offset_b: float,
	color: Color,
	z: int,
	meta: String
) -> void:
	var n := normal.normalized()
	var poly := Polygon2D.new()
	poly.color = color
	poly.z_index = z
	poly.polygon = PackedVector2Array([
		a + n * offset_a,
		b + n * offset_a,
		b + n * offset_b,
		a + n * offset_b,
	])
	poly.set_meta("road_kit", meta)
	parent.add_child(poly)


static func _add_dashed_line(
	parent: Node2D,
	a: Vector2,
	b: Vector2,
	tangent: Vector2,
	normal: Vector2,
	opts: Dictionary
) -> void:
	var length := (b - a).length()
	var dash_len: float = float(opts.get("dash_len", DEFAULT_DASH_LEN))
	var gap_len: float = float(opts.get("gap_len", DEFAULT_GAP_LEN))
	var half_sw: float = float(opts.get("stripe_half_w", DEFAULT_STRIPE_HALF_W))
	var n := normal.normalized()
	var t := 0.0
	while t < length - 0.5:
		var t1 := minf(t + dash_len, length)
		var p0 := a + tangent * t
		var p1 := a + tangent * t1
		var poly := Polygon2D.new()
		poly.color = COLOR_STRIPE
		poly.z_index = Z_STRIPE
		poly.polygon = PackedVector2Array([
			p0 + n * half_sw,
			p1 + n * half_sw,
			p1 - n * half_sw,
			p0 - n * half_sw,
		])
		poly.set_meta("road_kit", "stripe")
		parent.add_child(poly)
		t = t1 + gap_len


static func _add_dashed_circle(parent: Node2D, center: Vector2, radius: float, opts: Dictionary) -> void:
	var dash_len: float = float(opts.get("dash_len", DEFAULT_DASH_LEN))
	var gap_len: float = float(opts.get("gap_len", DEFAULT_GAP_LEN))
	var half_sw: float = float(opts.get("stripe_half_w", DEFAULT_STRIPE_HALF_W))
	var circ := TAU * radius
	if circ < 1.0:
		return
	var t := 0.0
	while t < circ - 0.5:
		var t1 := minf(t + dash_len, circ)
		var ang0 := t / radius
		var ang1 := t1 / radius
		var mid := (ang0 + ang1) * 0.5
		var radial := Vector2(cos(mid), sin(mid))
		var p0 := center + Vector2(cos(ang0), sin(ang0)) * radius
		var p1 := center + Vector2(cos(ang1), sin(ang1)) * radius
		# Slight radial thickness so dashes read on the ring.
		var poly := Polygon2D.new()
		poly.color = COLOR_STRIPE
		poly.z_index = Z_STRIPE
		poly.polygon = PackedVector2Array([
			p0 + radial * half_sw,
			p1 + radial * half_sw,
			p1 - radial * half_sw,
			p0 - radial * half_sw,
		])
		poly.set_meta("road_kit", "stripe")
		parent.add_child(poly)
		t = t1 + gap_len


static func _add_annulus(
	parent: Node2D,
	center: Vector2,
	r_inner: float,
	r_outer: float,
	color: Color,
	z: int,
	meta: String
) -> void:
	var segs := ROUNDABOUT_SEGS
	var pts := PackedVector2Array()
	for i in range(segs):
		var ang := TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(ang), sin(ang)) * r_outer)
	for i in range(segs):
		var ang := TAU * float(segs - 1 - i) / float(segs)
		pts.append(center + Vector2(cos(ang), sin(ang)) * r_inner)
	var poly := Polygon2D.new()
	poly.color = color
	poly.z_index = z
	poly.polygon = pts
	poly.set_meta("road_kit", meta)
	parent.add_child(poly)


static func _circle_points(center: Vector2, radius: float, segs: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segs):
		var ang := TAU * float(i) / float(segs)
		pts.append(center + Vector2(cos(ang), sin(ang)) * radius)
	return pts
