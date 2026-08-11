extends Node2D
## F1 debug cell grid. Origin (0,0) = Kirche. +X east, +Y south.
## Cell (ix, iy) covers [ix*cell, (ix+1)*cell) × [iy*cell, (iy+1)*cell).
## No class_name: preload + class_name deadlocks Godot on this script.

const DEFAULT_CELL := 100.0
const COLOR_MINOR := Color(1.0, 1.0, 1.0, 0.28)
const COLOR_MAJOR := Color(1.0, 1.0, 1.0, 0.52)
const COLOR_AXIS := Color(1.0, 0.86, 0.18, 0.82)
const COLOR_LABEL := Color(1.0, 1.0, 1.0, 0.95)
const COLOR_LABEL_OUTLINE := Color(0.12, 0.12, 0.12, 0.92)

var cell_size: float = DEFAULT_CELL
var bounds: Rect2 = Rect2(Vector2(-1500, -1000), Vector2(3000, 2200))
var major_every: int = 5


func _ready() -> void:
	z_as_relative = false
	queue_redraw()


static func world_to_cell(pos: Vector2, size: float = DEFAULT_CELL) -> Vector2i:
	var step := size if size > 0.001 else DEFAULT_CELL
	return Vector2i(floori(pos.x / step), floori(pos.y / step))


static func cell_center(index: Vector2i, size: float = DEFAULT_CELL) -> Vector2:
	var step := size if size > 0.001 else DEFAULT_CELL
	return Vector2(float(index.x) + 0.5, float(index.y) + 0.5) * step


func _draw() -> void:
	var size := cell_size if cell_size > 0.001 else DEFAULT_CELL
	if size < 1.0:
		return
	var x0 := floorf(bounds.position.x / size) * size
	var y0 := floorf(bounds.position.y / size) * size
	var x1 := bounds.end.x
	var y1 := bounds.end.y
	var x := x0
	while x <= x1 + 0.001:
		var ix := int(round(x / size))
		var col := COLOR_MINOR
		var width := 1.0
		if is_equal_approx(x, 0.0):
			col = COLOR_AXIS
			width = 3.0
		elif ix % major_every == 0:
			col = COLOR_MAJOR
			width = 2.0
		draw_line(Vector2(x, y0), Vector2(x, y1), col, width, true)
		x += size
	var y := y0
	while y <= y1 + 0.001:
		var iy := int(round(y / size))
		var col := COLOR_MINOR
		var width := 1.0
		if is_equal_approx(y, 0.0):
			col = COLOR_AXIS
			width = 3.0
		elif iy % major_every == 0:
			col = COLOR_MAJOR
			width = 2.0
		draw_line(Vector2(x0, y), Vector2(x1, y), col, width, true)
		y += size
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var font_size := 16
	var ix0 := floori(x0 / size)
	var iy0 := floori(y0 / size)
	var ix1 := floori((x1 - 0.001) / size)
	var iy1 := floori((y1 - 0.001) / size)
	for ix in range(ix0, ix1 + 1):
		for iy in range(iy0, iy1 + 1):
			var text := "%d,%d" % [ix, iy]
			var center := cell_center(Vector2i(ix, iy), size)
			var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var pos := center - text_size * 0.5 + Vector2(0.0, text_size.y * 0.35)
			draw_string_outline(
				font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, COLOR_LABEL_OUTLINE
			)
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_LABEL)
