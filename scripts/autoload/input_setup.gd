extends Node
## Registers keyboard + Xbox-style gamepad actions if missing (M1).

const DEADZONE := 0.25


func _ready() -> void:
	_ensure_actions()


func ensure_actions() -> void:
	_ensure_actions()


func has_required_actions() -> bool:
	var required := [
		"move_left", "move_right", "move_up", "move_down",
		"interact", "transform", "gadget", "scan", "pause_menu", "debug_overlay",
	]
	for action in required:
		if not InputMap.has_action(action):
			return false
		if InputMap.action_get_events(action).is_empty():
			return false
	return true


func _ensure_actions() -> void:
	_ensure_move_action("move_left", KEY_A, KEY_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_ensure_move_action("move_right", KEY_D, KEY_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_ensure_move_action("move_up", KEY_W, KEY_UP, JOY_AXIS_LEFT_Y, -1.0)
	_ensure_move_action("move_down", KEY_S, KEY_DOWN, JOY_AXIS_LEFT_Y, 1.0)

	_ensure_button_action("interact", KEY_E, JOY_BUTTON_A)
	_ensure_button_action("transform", KEY_SPACE, JOY_BUTTON_B)
	_add_key_if_missing("transform", KEY_Q)
	_ensure_button_action("gadget", KEY_F, JOY_BUTTON_X)
	_ensure_button_action("scan", KEY_R, JOY_BUTTON_Y)
	_ensure_button_action("pause_menu", KEY_ESCAPE, JOY_BUTTON_START)
	if not InputMap.has_action("debug_overlay"):
		InputMap.add_action("debug_overlay", DEADZONE)
	if InputMap.action_get_events("debug_overlay").is_empty():
		_add_key("debug_overlay", KEY_F1)


func _ensure_move_action(
	action: String,
	key_primary: Key,
	key_secondary: Key,
	axis: JoyAxis,
	axis_value: float
) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
	if InputMap.action_get_events(action).is_empty():
		_add_key(action, key_primary)
		_add_key(action, key_secondary)
		_add_axis(action, axis, axis_value)


func _ensure_button_action(action: String, key: Key, joy_button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
	if InputMap.action_get_events(action).is_empty():
		_add_key(action, key)
		_add_joy_button(action, joy_button)


func _add_key(action: String, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


func _add_key_if_missing(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		return
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and (existing as InputEventKey).physical_keycode == keycode:
			return
	_add_key(action, keycode)


func _add_joy_button(action: String, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _add_axis(action: String, axis: JoyAxis, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)
