extends CharacterBody2D
## Player with Style C sprites, robot/vehicle forms, transform anim.

enum Form { ROBOT, VEHICLE }

signal form_changed(new_form: Form)

const SPEED_ROBOT := 140.0
const SPEED_VEHICLE := 260.0
const SPEED_VEHICLE_RUSH := 360.0
## Lockout covers full 6-frame anim at TRANSFORM_FPS plus a small buffer.
const TRANSFORM_FPS := 8.0
const TRANSFORM_LOCKOUT := 0.9
## ~1000px art → ~85px on screen (readable vs ~210px houses).
const SPRITE_SCALE := Vector2(0.085, 0.085)
## Slightly larger during transform so intermediate frames read clearly.
const TRANSFORM_SPRITE_SCALE := Vector2(0.1, 0.1)
const ART := "res://assets/art/"
const MOVE_EPS := 0.001

var form: Form = Form.ROBOT
var character_id: String = "bolt"
var _transform_lock := 0.0
var _transforming := false
var _facing_left := false

@onready var _robot_sprite: Sprite2D = %RobotSprite
@onready var _vehicle_sprite: Sprite2D = %VehicleSprite
@onready var _transform_sprite: AnimatedSprite2D = %TransformSprite
@onready var _form_label: Label = %FormLabel


func _ready() -> void:
	character_id = GameState.current_character_id
	_load_character_art()
	_apply_visuals()
	_apply_facing_visuals()
	if not _transform_sprite.animation_finished.is_connected(_on_transform_finished):
		_transform_sprite.animation_finished.connect(_on_transform_finished)


func _physics_process(delta: float) -> void:
	if _transform_lock > 0.0:
		_transform_lock = maxf(0.0, _transform_lock - delta)

	if (not _transforming) and Input.is_action_just_pressed("transform") and can_transform():
		toggle_form()

	if _transforming:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var iso := _cartesian_to_iso(input_vec)
	var speed := _vehicle_speed() if form == Form.VEHICLE else SPEED_ROBOT
	if iso.length() > MOVE_EPS:
		velocity = iso.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if velocity.length() > MOVE_EPS:
		update_facing_from_velocity(velocity)


func _vehicle_speed() -> float:
	if character_id == "rush":
		return SPEED_VEHICLE_RUSH
	return SPEED_VEHICLE


func can_transform() -> bool:
	return _transform_lock <= 0.0 and not _transforming


func toggle_form() -> void:
	if not can_transform():
		return
	var to_vehicle := form == Form.ROBOT
	form = Form.VEHICLE if to_vehicle else Form.ROBOT
	_transform_lock = TRANSFORM_LOCKOUT
	if _transform_sprite.sprite_frames and has_transform_animation():
		_play_transform(to_vehicle)
	else:
		_apply_visuals()
		_apply_facing_visuals()
		form_changed.emit(form)


func set_form(new_form: Form) -> void:
	form = new_form
	_transforming = false
	_apply_visuals()
	_apply_facing_visuals()
	form_changed.emit(form)


func set_character(id: String) -> void:
	character_id = id
	GameState.current_character_id = id
	_load_character_art()
	_apply_visuals()
	_apply_facing_visuals()


func get_sprite_scale() -> Vector2:
	return SPRITE_SCALE


func has_transform_animation() -> bool:
	return (
		_transform_sprite != null
		and _transform_sprite.sprite_frames != null
		and _transform_sprite.sprite_frames.has_animation("to_vehicle")
	)


func is_facing_left() -> bool:
	return _facing_left


## Face move/drive direction via flip_h (¾ Style-C art — no full rotation).
func update_facing_from_velocity(vel: Vector2) -> void:
	if vel.length() <= MOVE_EPS:
		return
	# Prefer screen-x; when mostly vertical, keep last facing.
	if absf(vel.x) > MOVE_EPS:
		_facing_left = vel.x < 0.0
	_apply_facing_visuals()


func _apply_facing_visuals() -> void:
	if _robot_sprite:
		_robot_sprite.flip_h = _facing_left
		_robot_sprite.rotation = 0.0
	if _vehicle_sprite:
		_vehicle_sprite.flip_h = _facing_left
		_vehicle_sprite.rotation = 0.0
	if _transform_sprite:
		_transform_sprite.flip_h = _facing_left
		_transform_sprite.rotation = 0.0


func _cartesian_to_iso(input: Vector2) -> Vector2:
	return Vector2(input.x - input.y, (input.x + input.y) * 0.5)


func _load_character_art() -> void:
	var robot_path := ART + "%s_robot.png" % character_id
	var vehicle_path := ART + "%s_vehicle.png" % character_id
	if ResourceLoader.exists(robot_path):
		_robot_sprite.texture = load(robot_path)
	if ResourceLoader.exists(vehicle_path):
		_vehicle_sprite.texture = load(vehicle_path)
	_robot_sprite.scale = SPRITE_SCALE
	_vehicle_sprite.scale = SPRITE_SCALE
	_robot_sprite.centered = true
	_vehicle_sprite.centered = true
	_robot_sprite.offset = Vector2(0, -17)
	_vehicle_sprite.offset = Vector2(0, -9)

	var frames := SpriteFrames.new()
	var forward: Array[Texture2D] = []
	for i in range(1, 7):
		var path := ART + "%s_transform_%02d.png" % [character_id, i]
		if ResourceLoader.exists(path):
			forward.append(load(path))
	if not forward.is_empty():
		frames.add_animation("to_vehicle")
		frames.set_animation_speed("to_vehicle", TRANSFORM_FPS)
		frames.set_animation_loop("to_vehicle", false)
		frames.add_animation("to_robot")
		frames.set_animation_speed("to_robot", TRANSFORM_FPS)
		frames.set_animation_loop("to_robot", false)
		for tex in forward:
			frames.add_frame("to_vehicle", tex)
		for i in range(forward.size() - 1, -1, -1):
			frames.add_frame("to_robot", forward[i])
	_transform_sprite.sprite_frames = frames
	_transform_sprite.scale = SPRITE_SCALE
	_transform_sprite.offset = Vector2(0, -13)


func _play_transform(to_vehicle: bool) -> void:
	_transforming = true
	_robot_sprite.visible = false
	_vehicle_sprite.visible = false
	_transform_sprite.visible = true
	_transform_sprite.scale = TRANSFORM_SPRITE_SCALE
	_apply_facing_visuals()
	var anim := "to_vehicle" if to_vehicle else "to_robot"
	_transform_sprite.animation = anim
	_transform_sprite.set_frame_and_progress(0, 0.0)
	_transform_sprite.play(anim)
	_form_label.text = "Transform…"


func _on_transform_finished() -> void:
	if not _transforming:
		return
	_transforming = false
	_transform_sprite.visible = false
	_transform_sprite.stop()
	_transform_sprite.scale = SPRITE_SCALE
	_apply_visuals()
	_apply_facing_visuals()
	form_changed.emit(form)


func _apply_visuals() -> void:
	if _transform_sprite:
		_transform_sprite.visible = false
	if _robot_sprite:
		_robot_sprite.visible = form == Form.ROBOT
	if _vehicle_sprite:
		_vehicle_sprite.visible = form == Form.VEHICLE
	if _form_label:
		_form_label.text = "Robot" if form == Form.ROBOT else "Fahrzeug"
