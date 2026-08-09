extends CharacterBody2D
## Player with Style C sprites, robot/vehicle forms, transform anim (M2).

enum Form { ROBOT, VEHICLE }

signal form_changed(new_form: Form)

const SPEED_ROBOT := 140.0
const SPEED_VEHICLE := 260.0
const TRANSFORM_LOCKOUT := 0.55
const SPRITE_SCALE := Vector2(0.12, 0.12)
const ART := "res://assets/art/"

var form: Form = Form.ROBOT
var character_id: String = "bolt"
var _transform_lock := 0.0
var _transforming := false

@onready var _robot_sprite: Sprite2D = %RobotSprite
@onready var _vehicle_sprite: Sprite2D = %VehicleSprite
@onready var _transform_sprite: AnimatedSprite2D = %TransformSprite
@onready var _form_label: Label = %FormLabel


func _ready() -> void:
	character_id = GameState.current_character_id
	_load_character_art()
	_apply_visuals()
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
	var speed := SPEED_VEHICLE if form == Form.VEHICLE else SPEED_ROBOT
	if iso.length() > 0.001:
		velocity = iso.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func can_transform() -> bool:
	return _transform_lock <= 0.0 and not _transforming


func toggle_form() -> void:
	if not can_transform():
		return
	var to_vehicle := form == Form.ROBOT
	form = Form.VEHICLE if to_vehicle else Form.ROBOT
	_transform_lock = TRANSFORM_LOCKOUT
	if character_id == "bolt" and _transform_sprite.sprite_frames and _transform_sprite.sprite_frames.has_animation("to_vehicle"):
		_play_transform(to_vehicle)
	else:
		_apply_visuals()
		form_changed.emit(form)


func set_form(new_form: Form) -> void:
	form = new_form
	_transforming = false
	_apply_visuals()
	form_changed.emit(form)


func set_character(id: String) -> void:
	character_id = id
	GameState.current_character_id = id
	_load_character_art()
	_apply_visuals()


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
	_robot_sprite.offset = Vector2(0, -40)
	_vehicle_sprite.offset = Vector2(0, -20)

	var frames := SpriteFrames.new()
	if character_id == "bolt":
		frames.add_animation("to_vehicle")
		frames.set_animation_speed("to_vehicle", 12.0)
		frames.set_animation_loop("to_vehicle", false)
		frames.add_animation("to_robot")
		frames.set_animation_speed("to_robot", 12.0)
		frames.set_animation_loop("to_robot", false)
		var forward: Array[Texture2D] = []
		for i in range(1, 7):
			var path := ART + "bolt_transform_%02d.png" % i
			if ResourceLoader.exists(path):
				forward.append(load(path))
		for tex in forward:
			frames.add_frame("to_vehicle", tex)
		for i in range(forward.size() - 1, -1, -1):
			frames.add_frame("to_robot", forward[i])
	_transform_sprite.sprite_frames = frames
	_transform_sprite.scale = SPRITE_SCALE
	_transform_sprite.offset = Vector2(0, -30)


func _play_transform(to_vehicle: bool) -> void:
	_transforming = true
	_robot_sprite.visible = false
	_vehicle_sprite.visible = false
	_transform_sprite.visible = true
	var anim := "to_vehicle" if to_vehicle else "to_robot"
	_transform_sprite.play(anim)
	_form_label.text = "Transform…"


func _on_transform_finished() -> void:
	_transforming = false
	_transform_sprite.visible = false
	_transform_sprite.stop()
	_apply_visuals()
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
