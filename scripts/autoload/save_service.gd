extends Node
## Persist GameState to user:// — stub for M0; full slots in M6.

const SAVE_PATH := "user://save_slot_0.json"


func save_game() -> Error:
	var data := {
		"version": 1,
		"coins": GameState.coins,
		"current_character_id": GameState.current_character_id,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.close()
	return OK


func load_game() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return ERR_INVALID_DATA
	var data: Dictionary = parsed
	GameState.coins = int(data.get("coins", 0))
	GameState.current_character_id = str(data.get("current_character_id", "bolt"))
	GameState.coins_changed.emit(GameState.coins)
	return OK


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
