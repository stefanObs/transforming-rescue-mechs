extends Node
## Global game state stub (coins, unlocks, flags). Expanded in later MVP epics.

signal coins_changed(new_amount: int)

var coins: int = 0
var current_character_id: String = "bolt"
var world_spawn_position: Vector2 = SeuzachGeo.default_world_spawn() # Winterthurerstrasse / WINT-KERN
var has_world_spawn: bool = false


func add_coins(amount: int) -> void:
	if amount == 0:
		return
	coins = maxi(0, coins + amount)
	coins_changed.emit(coins)


func set_world_spawn(pos: Vector2) -> void:
	world_spawn_position = pos
	has_world_spawn = true


func consume_world_spawn() -> Vector2:
	has_world_spawn = false
	return world_spawn_position


func reset_for_new_game() -> void:
	coins = 0
	current_character_id = "bolt"
	has_world_spawn = false
	world_spawn_position = SeuzachGeo.default_world_spawn()
	coins_changed.emit(coins)
