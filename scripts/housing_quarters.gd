extends Object
## Named F1 housing quarter cells. Kirche = Ursprung, 1 Feld = SeuzachGeo.FIELD_WU.
## No class_name: preload from world_sandbox / tests (same pattern as debug_grid).

const DEBUG_GRID_SCRIPT := preload("res://scripts/debug_grid.gd")

## S01–S04 quarters. Later slices append further ids; do not invent a second grid.
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
	"WINT-NORD": {
		## INDEX 25..55, −90..−30; ix_max +10 so east-side curb offsets stay in-cell.
		"ix_min": 25,
		"ix_max": 65,
		"iy_min": -90,
		"iy_max": -30,
		"roads": ["Winterthurerstrasse"],
		"corridor_id": "wint-nord",
	},
	"LAND-MITTE": {
		"ix_min": 40,
		"ix_max": 120,
		"iy_min": -130,
		"iy_max": -50,
		"roads": ["Landstrasse"],
		"corridor_id": "land-mitte",
	},
	"STAT-WEST": {
		## INDEX 80..160, −70..−20; ±10 on axes for Stationsstrasse/Stadler curb samples.
		"ix_min": 70,
		"ix_max": 170,
		"iy_min": -80,
		"iy_max": -10,
		"roads": ["Stationsstrasse", "Strehlgasse", "Stadlerstrasse"],
		"corridor_id": "stat-west",
	},
	"STAT-BHF": {
		## INDEX 155..210, −70..−25; ±10 so Bahnhof-band curb samples stay placeable.
		"ix_min": 145,
		"ix_max": 220,
		"iy_min": -80,
		"iy_max": -15,
		"roads": ["Stationsstrasse", "Stadlerstrasse"],
		"corridor_id": "stat-bhf",
	},
	"REUT-MITTE": {
		## INDEX 45..95, −45..10; ±10 for Reutlinger/Schneckenwiese curb samples.
		## Locals that cut the rect; exclude Winterthurer / Breite / Seebühl (other slices).
		"ix_min": 35,
		"ix_max": 105,
		"iy_min": -55,
		"iy_max": 20,
		"roads": [
			"Reutlingerstrasse",
			"Schneckenwiesenstrasse",
			"Eibenstrasse",
			"Gartenstrasse",
			"Oberwiesenstrasse",
			"Schwalbenweg",
			"Seestrasse",
		],
		"corridor_id": "reut-mitte",
	},
	"REUT-SE": {
		## INDEX 70..120, −20..40; ±10 for SE curb samples / Wohnstiche.
		## Locals that cut the rect; exclude Breite / Seebühl / Birch campus arterial.
		"ix_min": 60,
		"ix_max": 130,
		"iy_min": -30,
		"iy_max": 50,
		"roads": [
			"Reutlingerstrasse",
			"Birchweg",
			"Buchenstrasse",
			"Gartenstrasse",
			"Handschüsselweg",
			"Oberwiesenstrasse",
			"Schwalbenweg",
			"Seestrasse",
		],
		"corridor_id": "reut-se",
	},
}


static func s01_ids() -> Array[String]:
	return ["KIRCHE-KERN", "WINT-WEST"]


static func s02_ids() -> Array[String]:
	return ["WINT-NORD", "LAND-MITTE"]


static func s03_ids() -> Array[String]:
	return ["STAT-WEST", "STAT-BHF"]


static func s04_ids() -> Array[String]:
	return ["REUT-MITTE", "REUT-SE"]


static func active_ids() -> Array[String]:
	## Placement order: S01 → S02 → S03 → S04; shared placed[] across all.
	var out: Array[String] = []
	out.append_array(s01_ids())
	out.append_array(s02_ids())
	out.append_array(s03_ids())
	out.append_array(s04_ids())
	return out


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
