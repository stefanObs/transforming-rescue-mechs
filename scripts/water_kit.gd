class_name WaterKit
extends RefCounted
## Procedural Style-C brook ribbons: mitered bank + water fill. No Line2D, no collision.

const COLOR_WATER := Color("2E8FD4")
const COLOR_BANK := Color("1F6FB0")

const DEFAULT_HALF_W := 16.0
const DEFAULT_BANK_EXTRA := 4.0
const Z_BANK := -46
const Z_WATER := -45


## opts: half_w (float), bank (bool), bank_extra (float)
static func add_polyline(parent: Node2D, points: Array, opts: Dictionary = {}) -> void:
	if parent == null:
		return
	var pts := _clean_poly_points(points)
	if pts.size() < 2:
		return
	var half_w: float = float(opts.get("half_w", DEFAULT_HALF_W))
	var want_bank: bool = bool(opts.get("bank", true))
	var bank_extra: float = float(opts.get("bank_extra", DEFAULT_BANK_EXTRA))
	if want_bank and bank_extra > 0.0:
		_add_poly_strip(
			parent,
			pts,
			-(half_w + bank_extra),
			half_w + bank_extra,
			COLOR_BANK,
			Z_BANK,
			"bank"
		)
	_add_poly_strip(parent, pts, -half_w, half_w, COLOR_WATER, Z_WATER, "water")


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
	poly.set_meta("water_kit", meta)
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
