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
const Z_JUNCTION := -38
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


## Continuous ribbon along `points` with mitered corners (no grass wedges at bends).
static func add_polyline(parent: Node2D, points: Array, opts: Dictionary = {}) -> void:
	if parent == null:
		return
	var pts := _clean_poly_points(points)
	if pts.size() < 2:
		return
	var half_w: float = float(opts.get("half_w", DEFAULT_HALF_W))
	var sidewalk_w: float = float(opts.get("sidewalk_w", DEFAULT_SIDEWALK_W))
	var want_sidewalk: bool = bool(opts.get("sidewalk", false))
	var want_centerline: bool = bool(opts.get("centerline", false))

	if want_sidewalk and sidewalk_w > 0.0:
		_add_poly_strip(
			parent, pts, half_w, half_w + sidewalk_w, COLOR_SIDEWALK, Z_SIDEWALK, "sidewalk"
		)
		_add_poly_strip(
			parent, pts, -(half_w + sidewalk_w), -half_w, COLOR_SIDEWALK, Z_SIDEWALK, "sidewalk"
		)
	_add_poly_strip(parent, pts, -half_w, half_w, COLOR_ROAD, Z_ROAD, "road")
	if want_centerline:
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var delta := b - a
			var length := delta.length()
			if length < 0.001:
				continue
			var tangent := delta / length
			var normal := Vector2(-tangent.y, tangent.x)
			_add_dashed_line(parent, a, b, tangent, normal, opts)


## Asphalt disc covering a T/cross so sidewalks do not stripe through the junction.
static func add_junction(parent: Node2D, center: Vector2, radius: float) -> void:
	if parent == null or radius <= 1.0:
		return
	var poly := Polygon2D.new()
	poly.color = COLOR_ROAD
	poly.z_index = Z_JUNCTION
	poly.polygon = _circle_points(center, radius, 28)
	poly.set_meta("road_kit", "junction")
	parent.add_child(poly)


## Keep debug street names upright: fold tangent into ±90° so text is not upside-down.
static func readable_label_rotation(tangent: Vector2) -> float:
	if tangent.length_squared() < 0.0001:
		return 0.0
	var angle := tangent.angle()
	if absf(angle) > PI * 0.5 + 0.0001:
		angle = wrapf(angle + PI, -PI, PI)
	return angle


## Sample points along a polyline for debug name labels (at least one if long enough).
static func label_samples(points: PackedVector2Array, spacing: float = 360.0) -> Array:
	var pts := PackedVector2Array()
	for p in points:
		if pts.is_empty() or pts[pts.size() - 1].distance_to(p) > 0.5:
			pts.append(p)
	if pts.size() < 2:
		return []
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	if total < 0.5:
		return []
	var gap := maxf(spacing, 80.0)
	var targets: Array[float] = []
	if total < gap * 1.25:
		targets.append(total * 0.5)
	else:
		var d := gap * 0.5
		while d < total - 8.0:
			targets.append(d)
			d += gap
		if targets.is_empty():
			targets.append(total * 0.5)
	var out: Array = []
	for dist in targets:
		out.append(_point_tangent_at_length(pts, float(dist)))
	return out


static func _point_tangent_at_length(pts: PackedVector2Array, dist: float) -> Dictionary:
	var remain := dist
	var last_i := pts.size() - 2
	for i in range(last_i + 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.001:
			continue
		if remain <= seg or i == last_i:
			var t := clampf(remain / maxf(seg, 0.001), 0.0, 1.0)
			return {"pos": a.lerp(b, t), "tangent": (b - a) / seg}
		remain -= seg
	var delta := pts[pts.size() - 1] - pts[pts.size() - 2]
	var ln := delta.length()
	return {
		"pos": pts[pts.size() - 1],
		"tangent": delta / ln if ln > 0.001 else Vector2.RIGHT,
	}


static func _clean_poly_points(points: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for raw in points:
		var p: Vector2 = raw as Vector2
		if pts.is_empty() or pts[pts.size() - 1].distance_to(p) > 0.5:
			pts.append(p)
	return pts


static func _add_poly_strip(
	parent: Node2D,
	pts: PackedVector2Array,
	offset_a: float,
	offset_b: float,
	color: Color,
	z: int,
	meta: String
) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in range(pts.size()):
		left.append(_miter_offset(pts, i, offset_a))
		right.append(_miter_offset(pts, i, offset_b))
	var poly_pts := PackedVector2Array()
	for p in left:
		poly_pts.append(p)
	for i in range(right.size() - 1, -1, -1):
		poly_pts.append(right[i])
	var poly := Polygon2D.new()
	poly.color = color
	poly.z_index = z
	poly.polygon = poly_pts
	poly.set_meta("road_kit", meta)
	parent.add_child(poly)


static func _miter_offset(pts: PackedVector2Array, i: int, offset: float) -> Vector2:
	var n0 := Vector2.ZERO
	var n1 := Vector2.ZERO
	if i == 0:
		var t := (pts[1] - pts[0]).normalized()
		return pts[0] + Vector2(-t.y, t.x) * offset
	if i == pts.size() - 1:
		var t := (pts[i] - pts[i - 1]).normalized()
		return pts[i] + Vector2(-t.y, t.x) * offset
	var t0 := (pts[i] - pts[i - 1]).normalized()
	var t1 := (pts[i + 1] - pts[i]).normalized()
	n0 = Vector2(-t0.y, t0.x)
	n1 = Vector2(-t1.y, t1.x)
	var m := n0 + n1
	if m.length() < 0.001:
		return pts[i] + n0 * offset
	m = m.normalized()
	var den := m.dot(n0)
	if absf(den) < 0.18:
		den = 0.18 * signf(den)
	var miter := clampf(offset / den, -absf(offset) * 3.5, absf(offset) * 3.5)
	return pts[i] + m * miter


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


## One Node2D draws all dash quads for a segment (S02: fewer nodes than 1 Polygon2D/dash).
class DashBatch2D extends Node2D:
	var stripe_color: Color = Color("F5F5F5")
	var dash_polys: Array[PackedVector2Array] = []

	func _draw() -> void:
		for poly in dash_polys:
			if poly.size() >= 3:
				draw_colored_polygon(poly, stripe_color)


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
	var batch := DashBatch2D.new()
	batch.stripe_color = COLOR_STRIPE
	batch.z_index = Z_STRIPE
	var t := 0.0
	while t < length - 0.5:
		var t1 := minf(t + dash_len, length)
		var p0 := a + tangent * t
		var p1 := a + tangent * t1
		batch.dash_polys.append(
			PackedVector2Array([
				p0 + n * half_sw,
				p1 + n * half_sw,
				p1 - n * half_sw,
				p0 - n * half_sw,
			])
		)
		t = t1 + gap_len
	if batch.dash_polys.is_empty():
		return
	batch.set_meta("road_kit", "stripe")
	batch.set_meta("dash_count", batch.dash_polys.size())
	parent.add_child(batch)


static func _add_dashed_circle(parent: Node2D, center: Vector2, radius: float, opts: Dictionary) -> void:
	var dash_len: float = float(opts.get("dash_len", DEFAULT_DASH_LEN))
	var gap_len: float = float(opts.get("gap_len", DEFAULT_GAP_LEN))
	var half_sw: float = float(opts.get("stripe_half_w", DEFAULT_STRIPE_HALF_W))
	var circ := TAU * radius
	if circ < 1.0:
		return
	var batch := DashBatch2D.new()
	batch.stripe_color = COLOR_STRIPE
	batch.z_index = Z_STRIPE
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
		batch.dash_polys.append(
			PackedVector2Array([
				p0 + radial * half_sw,
				p1 + radial * half_sw,
				p1 - radial * half_sw,
				p0 - radial * half_sw,
			])
		)
		t = t1 + gap_len
	if batch.dash_polys.is_empty():
		return
	batch.set_meta("road_kit", "stripe")
	batch.set_meta("dash_count", batch.dash_polys.size())
	parent.add_child(batch)


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
