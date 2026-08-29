extends Object
## Named F1 housing quarter cells. Kirche = Ursprung, 1 Feld = SeuzachGeo.FIELD_WU.
## No class_name: preload from world_sandbox / tests (same pattern as debug_grid).

const DEBUG_GRID_SCRIPT := preload("res://scripts/debug_grid.gd")

## S01 only. S02+ append further ids; do not invent a second grid.
const REGISTRY := {
	"KIRCHE-KERN": {
		"ix_min": -15,
		"ix_max": 25,
		"iy_min": -30,
		"iy_max": 25,
		"roads": ["Kirchgasse", "Kirchhügelstrasse", "Winterthurerstrasse"],
		## Legacy corridor tag for facing/bearing suite compatibility.
		"corridor_id": "kirche",
	},
	"WINT-WEST": {
		"ix_min": 20,
		"ix_max": 50,
		"iy_min": -35,
		"iy_max": 40,
		"roads": ["Winterthurerstrasse"],
		"corridor_id": "spawn",
	},
}


static func s01_ids() -> Array[String]:
	return ["KIRCHE-KERN", "WINT-WEST"]


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
