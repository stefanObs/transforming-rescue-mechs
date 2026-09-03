extends Object
## Named F1 housing quarter cells. Kirche = Ursprung, 1 Feld = SeuzachGeo.FIELD_WU.
## Schema-Dorf: Hauptstrasse + Wohnstrasse only.

const DEBUG_GRID_SCRIPT := preload("res://scripts/debug_grid.gd")

const REGISTRY := {
	"KERN": {
		"ix_min": -15,
		"ix_max": 18,
		"iy_min": -8,
		"iy_max": 8,
		"roads": ["Hauptstrasse"],
		"corridor_id": "haupt",
	},
	"WOHN": {
		"ix_min": -8,
		"ix_max": 18,
		"iy_min": -14,
		"iy_max": -5,
		"roads": ["Wohnstrasse"],
		"corridor_id": "wohn",
	},
}


static func s01_ids() -> Array[String]:
	return ["KERN", "WOHN"]


static func s02_ids() -> Array[String]:
	return []


static func s03_ids() -> Array[String]:
	return []


static func s04_ids() -> Array[String]:
	return []


static func s05_ids() -> Array[String]:
	return []


static func s06_ids() -> Array[String]:
	return []


static func active_ids() -> Array[String]:
	return s01_ids()


static func get_quarter(id: String) -> Dictionary:
	if not REGISTRY.has(id):
		return {}
	return REGISTRY[id]


static func field_bounds(id: String) -> Dictionary:
	var q := get_quarter(id)
	if q.is_empty():
		return {}
	return {
		"ix_min": int(q["ix_min"]),
		"ix_max": int(q["ix_max"]),
		"iy_min": int(q["iy_min"]),
		"iy_max": int(q["iy_max"]),
	}


static func cell_in_bounds(cell: Vector2i, bounds: Dictionary) -> bool:
	if bounds.is_empty():
		return false
	return (
		cell.x >= int(bounds["ix_min"])
		and cell.x <= int(bounds["ix_max"])
		and cell.y >= int(bounds["iy_min"])
		and cell.y <= int(bounds["iy_max"])
	)


static func quarter_contains_world(id: String, pos: Vector2) -> bool:
	var bounds := field_bounds(id)
	if bounds.is_empty():
		return false
	var cell: Vector2i = DEBUG_GRID_SCRIPT.world_to_cell(pos, SeuzachGeo.FIELD_WU)
	return cell_in_bounds(cell, bounds)


static func world_to_cell(pos: Vector2) -> Vector2i:
	return DEBUG_GRID_SCRIPT.world_to_cell(pos, SeuzachGeo.FIELD_WU)


static func cell_distance_to_bounds(cell: Vector2i, bounds: Dictionary) -> int:
	if bounds.is_empty():
		return 999999
	var dx := 0
	if cell.x < int(bounds["ix_min"]):
		dx = int(bounds["ix_min"]) - cell.x
	elif cell.x > int(bounds["ix_max"]):
		dx = cell.x - int(bounds["ix_max"])
	var dy := 0
	if cell.y < int(bounds["iy_min"]):
		dy = int(bounds["iy_min"]) - cell.y
	elif cell.y > int(bounds["iy_max"]):
		dy = cell.y - int(bounds["iy_max"])
	return maxi(dx, dy)


static func ids_near_world(pos: Vector2, margin_cells: int = 2) -> Array[String]:
	var cell: Vector2i = world_to_cell(pos)
	var out: Array[String] = []
	for id in s01_ids():
		out.append(id)
	for id in active_ids():
		if out.has(id):
			continue
		var bounds: Dictionary = field_bounds(id)
		if cell_distance_to_bounds(cell, bounds) <= margin_cells:
			out.append(id)
	return out


static func is_near_quarter(pos: Vector2, quarter_id: String, margin_cells: int = 2) -> bool:
	var bounds: Dictionary = field_bounds(quarter_id)
	if bounds.is_empty():
		return false
	return cell_distance_to_bounds(world_to_cell(pos), bounds) <= margin_cells
