extends Node
## Global game state stub (coins, unlocks, flags). Expanded in later MVP epics.

signal coins_changed(new_amount: int)

var coins: int = 0
var current_character_id: String = "bolt"


func add_coins(amount: int) -> void:
	if amount == 0:
		return
	coins = maxi(0, coins + amount)
	coins_changed.emit(coins)


func reset_for_new_game() -> void:
	coins = 0
	current_character_id = "bolt"
	coins_changed.emit(coins)
