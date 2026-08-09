extends Control
## Boot / main placeholder UI for MVP epic M0.

@onready var _title: Label = %TitleLabel
@onready var _status: Label = %StatusLabel


func _ready() -> void:
	_title.text = "Transformierende Rettungsmechs"
	_status.text = "MVP M0 — Godot-Grundgerüst bereit\nMünzen: %d" % GameState.coins
