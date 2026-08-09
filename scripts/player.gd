extends CharacterBody2D
## Player with Style C sprites, robot/vehicle forms, transform anim, 4-dir facing.

enum Form { ROBOT, VEHICLE }
enum Facing { N, E, S, W }

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
## Angle that maps to full ±1 turn blend.
const TURN_FULL_ANGLE := deg_to_rad(45.0)
const TURN_POSE_THRESHOLD := 0.28
const LEAN_ROBOT_RAD := deg_to_rad(8.0)
const LEAN_VEHICLE_RAD := deg_to_rad(18.0)
## Milder lean when dedicated N/E/S/W textures are present.
const LEAN_ROBOT_DIR_RAD := deg_to_rad(4.0)
const LEAN_VEHICLE_DIR_RAD := deg_to_rad(10.0)
## How fast blend follows target while moving / decays when stopped.
const TURN_BLEND_RESPOND := 14.0
const TURN_BLEND_DECAY := 10.0
## Smear last move dir so sharp turns keep blend elevated for a few frames.
const MOVE_DIR_SMEAR := 8.0
const DIR_SUFFIX := ["n", "e", "s", "w"]

var form: Form = Form.ROBOT
var character_id: String = "bolt"
var _transform_lock := 0.0
var _transforming := false
var _facing: Facing = Facing.S
var _facing_left := false
var _move_dir: Vector2 = Vector2.ZERO
var _turn_blend: float = 0.0
var _robot_idle_tex: Texture2D
var _vehicle_idle_tex: Texture2D
var _robot_turn_tex: Texture2D
var _vehicle_turn_tex: Texture2D
## Indexed by Facing: N=0 E=1 S=2 W=3
var _robot_dir: Array = [null, null, null, null]
var _vehicle_dir: Array = [null, null, null, null]
var _robot_has_dir: Array = [false, false, false, false]
var _vehicle_has_dir: Array = [false, false, false, false]
## Flip W when no dedicated W art (mirror E or idle).
var _robot_flip_w := false
var _vehicle_flip_w := false

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
		_turn_blend = 0.0
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
	_update_turn_blend(delta)
	# Facing from pre-iso input so keyboard up → N (heck), not post-iso E.
	if input_vec.length() > MOVE_EPS:
		update_facing_from_velocity(input_vec)
	else:
		_apply_turn_visuals()


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
	_reset_turn_state()
	if _transform_sprite.sprite_frames and has_transform_animation():
		_play_transform(to_vehicle)
	else:
		_apply_visuals()
		_apply_facing_visuals()
		form_changed.emit(form)


func set_form(new_form: Form) -> void:
	form = new_form
	_transforming = false
	_reset_turn_state()
	_apply_visuals()
	_apply_facing_visuals()
	form_changed.emit(form)


func set_character(id: String) -> void:
	character_id = id
	GameState.current_character_id = id
	_load_character_art()
	_reset_turn_state()
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


func get_facing() -> int:
	return int(_facing)


## Dominant-axis facing from screen velocity: −y=N, +y=S, +x=E, −x=W.
static func facing_from_velocity(vel: Vector2) -> Facing:
	if absf(vel.x) < MOVE_EPS and absf(vel.y) < MOVE_EPS:
		return Facing.S
	if absf(vel.x) >= absf(vel.y):
		return Facing.E if vel.x > 0.0 else Facing.W
	return Facing.N if vel.y < 0.0 else Facing.S


func get_turn_blend() -> float:
	return _turn_blend


func uses_dir_textures() -> bool:
	return _form_has_dir_art(form)


func _form_has_dir_art(which: Form) -> bool:
	var has: Array = _vehicle_has_dir if which == Form.VEHICLE else _robot_has_dir
	return (
		bool(has[Facing.N])
		or bool(has[Facing.E])
		or bool(has[Facing.S])
		or bool(has[Facing.W])
	)


func is_using_turn_pose() -> bool:
	if uses_dir_textures():
		return false
	if absf(_turn_blend) <= TURN_POSE_THRESHOLD:
		return false
	if form == Form.VEHICLE:
		return _vehicle_turn_tex != null
	return _robot_turn_tex != null


## Apply an instantaneous turn from `from` → `to` for unit tests (no physics).
func apply_turn_from_dirs(from: Vector2, to: Vector2) -> void:
	if from.length() <= MOVE_EPS or to.length() <= MOVE_EPS:
		return
	_move_dir = from.normalized()
	var vel_dir := to.normalized()
	var ang := _move_dir.angle_to(vel_dir)
	_turn_blend = clampf(ang / TURN_FULL_ANGLE, -1.0, 1.0)
	# Partial smear so consecutive calls can stack / reverse.
	_move_dir = _move_dir.lerp(vel_dir, 0.35).normalized()
	_facing = facing_from_velocity(vel_dir)
	_facing_left = _facing == Facing.W
	_apply_facing_visuals()


func _reset_turn_state() -> void:
	_turn_blend = 0.0
	_move_dir = Vector2.ZERO


func _update_turn_blend(delta: float) -> void:
	if velocity.length() > MOVE_EPS:
		var vel_dir := velocity.normalized()
		if _move_dir.length() <= MOVE_EPS:
			_move_dir = vel_dir
			_turn_blend = move_toward(_turn_blend, 0.0, TURN_BLEND_DECAY * delta)
		else:
			var ang := _move_dir.angle_to(vel_dir)
			var target := clampf(ang / TURN_FULL_ANGLE, -1.0, 1.0)
			_turn_blend = lerpf(_turn_blend, target, 1.0 - exp(-TURN_BLEND_RESPOND * delta))
			_move_dir = _move_dir.lerp(vel_dir, 1.0 - exp(-MOVE_DIR_SMEAR * delta)).normalized()
	else:
		_turn_blend = move_toward(_turn_blend, 0.0, TURN_BLEND_DECAY * delta)
		if absf(_turn_blend) < 0.01:
			_turn_blend = 0.0
			_move_dir = Vector2.ZERO


## Face move/drive direction via Facing enum + dir textures (flip_h only as W fallback).
func update_facing_from_velocity(vel: Vector2) -> void:
	if vel.length() <= MOVE_EPS:
		return
	_facing = facing_from_velocity(vel)
	_facing_left = _facing == Facing.W
	_apply_facing_visuals()


func _apply_facing_visuals() -> void:
	var flip_robot := _facing == Facing.W and _robot_flip_w
	var flip_vehicle := _facing == Facing.W and _vehicle_flip_w
	_facing_left = flip_robot if form == Form.ROBOT else flip_vehicle
	# Keep transform sprite mirroring consistent with active form fallback.
	var flip_xform := flip_vehicle if form == Form.VEHICLE else flip_robot
	if _robot_sprite:
		_robot_sprite.flip_h = flip_robot
	if _vehicle_sprite:
		_vehicle_sprite.flip_h = flip_vehicle
	if _transform_sprite:
		_transform_sprite.flip_h = flip_xform
		_transform_sprite.rotation = 0.0
	if _transforming:
		if _robot_sprite:
			_robot_sprite.rotation = 0.0
		if _vehicle_sprite:
			_vehicle_sprite.rotation = 0.0
		return
	_apply_turn_visuals()


func _apply_turn_visuals() -> void:
	if _transforming:
		return
	var lean_scale: float
	if uses_dir_textures():
		lean_scale = LEAN_VEHICLE_DIR_RAD if form == Form.VEHICLE else LEAN_ROBOT_DIR_RAD
	else:
		lean_scale = LEAN_VEHICLE_RAD if form == Form.VEHICLE else LEAN_ROBOT_RAD
	var lean := _turn_blend * lean_scale
	if _robot_sprite:
		_robot_sprite.rotation = lean if form == Form.ROBOT else 0.0
		_robot_sprite.texture = _texture_for(Form.ROBOT)
	if _vehicle_sprite:
		_vehicle_sprite.rotation = lean if form == Form.VEHICLE else 0.0
		_vehicle_sprite.texture = _texture_for(Form.VEHICLE)


func _texture_for(which: Form) -> Texture2D:
	var dirs: Array = _vehicle_dir if which == Form.VEHICLE else _robot_dir
	var facing_tex: Texture2D = dirs[_facing] as Texture2D
	if _form_has_dir_art(which) and facing_tex != null:
		return facing_tex
	# Legacy turn-pose swap when no dedicated dir art.
	var use_turn := absf(_turn_blend) > TURN_POSE_THRESHOLD
	if which == Form.VEHICLE:
		if use_turn and _vehicle_turn_tex != null:
			return _vehicle_turn_tex
		if facing_tex != null:
			return facing_tex
		return _vehicle_idle_tex
	if use_turn and _robot_turn_tex != null:
		return _robot_turn_tex
	if facing_tex != null:
		return facing_tex
	return _robot_idle_tex


func _cartesian_to_iso(input: Vector2) -> Vector2:
	return Vector2(input.x - input.y, (input.x + input.y) * 0.5)


func _load_character_art() -> void:
	var robot_path := ART + "%s_robot.png" % character_id
	var vehicle_path := ART + "%s_vehicle.png" % character_id
	var robot_turn_path := ART + "%s_robot_turn.png" % character_id
	var vehicle_turn_path := ART + "%s_vehicle_turn.png" % character_id
	_robot_idle_tex = null
	_vehicle_idle_tex = null
	_robot_turn_tex = null
	_vehicle_turn_tex = null
	_robot_dir = [null, null, null, null]
	_vehicle_dir = [null, null, null, null]
	_robot_has_dir = [false, false, false, false]
	_vehicle_has_dir = [false, false, false, false]
	_robot_flip_w = false
	_vehicle_flip_w = false
	if ResourceLoader.exists(robot_path):
		_robot_idle_tex = load(robot_path)
		_robot_sprite.texture = _robot_idle_tex
	if ResourceLoader.exists(vehicle_path):
		_vehicle_idle_tex = load(vehicle_path)
		_vehicle_sprite.texture = _vehicle_idle_tex
	if ResourceLoader.exists(robot_turn_path):
		_robot_turn_tex = load(robot_turn_path)
	if ResourceLoader.exists(vehicle_turn_path):
		_vehicle_turn_tex = load(vehicle_turn_path)
	_load_dir_textures("robot", _robot_idle_tex, _robot_dir, _robot_has_dir)
	_load_dir_textures("vehicle", _vehicle_idle_tex, _vehicle_dir, _vehicle_has_dir)
	# W fallback: mirror E if present, else mirror idle.
	_robot_flip_w = not bool(_robot_has_dir[Facing.W])
	if _robot_flip_w:
		if bool(_robot_has_dir[Facing.E]) and _robot_dir[Facing.E] != null:
			_robot_dir[Facing.W] = _robot_dir[Facing.E]
		else:
			_robot_dir[Facing.W] = _robot_idle_tex
	_vehicle_flip_w = not bool(_vehicle_has_dir[Facing.W])
	if _vehicle_flip_w:
		if bool(_vehicle_has_dir[Facing.E]) and _vehicle_dir[Facing.E] != null:
			_vehicle_dir[Facing.W] = _vehicle_dir[Facing.E]
		else:
			_vehicle_dir[Facing.W] = _vehicle_idle_tex
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


func _load_dir_textures(
	form_name: String,
	idle: Texture2D,
	out_dirs: Array,
	out_has: Array
) -> void:
	for i in range(4):
		var path := ART + "%s_%s_%s.png" % [character_id, form_name, DIR_SUFFIX[i]]
		if ResourceLoader.exists(path):
			out_dirs[i] = load(path)
			out_has[i] = true
		else:
			# Fallbacks: s/e/n ← idle; w handled by caller (flip).
			out_dirs[i] = idle
			out_has[i] = false


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
	_reset_turn_state()
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
