extends Node
## Stub: maps logical actions to keyboard / Xbox glyph labels for UI prompts (M1).

enum DeviceKind { KEYBOARD, XBOX }


func glyph_for(action: String, device: DeviceKind = DeviceKind.KEYBOARD) -> String:
	match device:
		DeviceKind.XBOX:
			return _xbox_glyph(action)
		_:
			return _keyboard_glyph(action)


func _keyboard_glyph(action: String) -> String:
	match action:
		"move_left", "move_right", "move_up", "move_down":
			return "WASD"
		"interact":
			return "E"
		"transform":
			return "Space"
		"gadget":
			return "F"
		"scan":
			return "R"
		"pause_menu":
			return "Esc"
		_:
			return action


func _xbox_glyph(action: String) -> String:
	match action:
		"move_left", "move_right", "move_up", "move_down":
			return "L-Stick"
		"interact":
			return "A"
		"transform":
			return "B"
		"gadget":
			return "X"
		"scan":
			return "Y"
		"pause_menu":
			return "Start"
		_:
			return action
