class_name RailwayKit
extends RefCounted
## Procedural Style-C railway ribbons: mitered ballast + two rails. No Line2D, no sleepers.

const COLOR_BALLAST := Color("8A7A68")
const COLOR_RAIL := Color("C5C5C5")
const COLOR_PLATFORM := Color("D4D0C8")

const DEFAULT_HALF_W := 38.0
const DEFAULT_RAIL_OFFSET := 13.5
const DEFAULT_RAIL_HALF_W := 3.0
const Z_BALLAST := -37
const Z_RAIL := -36
const Z_PLATFORM := -38


## opts: half_w (float), rail_offset (float), rail_half_w (float)
static func add_polyline(parent: Node2D, points: Array, opts: Dictionary = {}) -> void:
	if parent == null:
		return
	var pts := _clean_poly_points(points)
	if pts.size() < 2:
		return
	var half_w: float = float(opts.get("half_w", DEFAULT_HALF_W))
	var rail_offset: float = float(opts.get("rail_offset", DEFAULT_RAIL_OFFSET))
	var rail_half_w: float = float(opts.get("rail_half_w", DEFAULT_RAIL_HALF_W))
	_add_poly_strip(parent, pts, -half_w, half_w, COLOR_BALLAST, Z_BALLAST, "ballast")
	_add_poly_strip(
		parent,
		pts,
		rail_offset - rail_half_w,
		rail_offset + rail_half_w,
		COLOR_RAIL,
		Z_RAIL,
		"rail"
	)
	_add_poly_strip(
		parent,
		pts,
		-(rail_offset + rail_half_w),
		-(rail_offset - rail_half_w),
		COLOR_RAIL,
		Z_RAIL,
		"rail"
	)


static func add_platform(parent: Node2D, points: Array) -> void:
	if parent == null:
		return
	var pts := _clean_poly_points(points)
	if pts.size() >= 2 and pts[0].distance_to(pts[pts.size() - 1]) <= 0.5:
		pts.remove_at(pts.size() - 1)
	if pts.size() < 3:
		return
	var poly := Polygon2D.new()
	poly.color = COLOR_PLATFORM
	poly.z_index = Z_PLATFORM
	poly.polygon = pts
	poly.set_meta("railway_kit", "platform")
	parent.add_child(poly)


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
	poly.set_meta("railway_kit", meta)
	parent.add_child(poly)


static func _miter_offset(pts: PackedVector2Array, i: int, offset: float) -> Vector2:
	if i == 0:
		var t := (pts[1] - pts[0]).normalized()
		return pts[0] + Vector2(-t.y, t.x) * offset
	if i == pts.size() - 1:
		var t := (pts[i] - pts[i - 1]).normalized()
		return pts[i] + Vector2(-t.y, t.x) * offset
	var t0 := (pts[i] - pts[i - 1]).normalized()
	var t1 := (pts[i + 1] - pts[i]).normalized()
	var n0 := Vector2(-t0.y, t0.x)
	var n1 := Vector2(-t1.y, t1.x)
	var m := n0 + n1
	if m.length() < 0.001:
		return pts[i] + n0 * offset
	m = m.normalized()
	var den := m.dot(n0)
	if absf(den) < 0.18:
		den = 0.18 * signf(den)
	var miter := clampf(offset / den, -absf(offset) * 3.5, absf(offset) * 3.5)
	return pts[i] + m * miter
