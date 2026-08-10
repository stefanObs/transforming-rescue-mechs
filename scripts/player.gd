extends CharacterBody2D
## Player with Style C sprites, robot/vehicle forms, transform anim, 8-dir facing.
## Locomotion is screen-aligned (arrow down = +y on screen); no iso skew.

enum Form { ROBOT, VEHICLE }
enum Facing { N, NE, E, SE, S, SW, W, NW }

signal form_changed(new_form: Form)

const SPEED_ROBOT := 140.0
const SPEED_VEHICLE := 260.0
const SPEED_VEHICLE_RUSH := 360.0
## Lockout covers full 6-frame anim at TRANSFORM_FPS plus a small buffer.
const TRANSFORM_FPS := 8.0
const TRANSFORM_LOCKOUT := 0.9
const WALK_FPS := 9.0
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
## How fast blend follows target while moving / decays when stopped.
const TURN_BLEND_RESPOND := 14.0
const TURN_BLEND_DECAY := 10.0
## Smear last move dir so sharp turns keep blend elevated for a few frames.
const MOVE_DIR_SMEAR := 8.0
const DIR_SUFFIX := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const WALK_DIRS := ["n", "e", "s"]
const DIR_COUNT := 8
const VEHICLE_BOB_AMP := 1.5
const VEHICLE_BOB_HZ := 8.0
const SHADOW_SCALE_ROBOT := Vector2(1.0, 1.0)
const SHADOW_SCALE_VEHICLE := Vector2(1.45, 1.1)
const FORM_LABEL_PAD := 8.0

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
## Indexed by Facing: N NE E SE S SW W NW
var _robot_dir: Array = [null, null, null, null, null, null, null, null]
var _vehicle_dir: Array = [null, null, null, null, null, null, null, null]
var _robot_has_dir: Array = [false, false, false, false, false, false, false, false]
var _vehicle_has_dir: Array = [false, false, false, false, false, false, false, false]
## Flip W when no dedicated W art (mirror E or idle).
var _robot_flip_w := false
var _vehicle_flip_w := false
var _robot_ground_oy := 0.0
var _vehicle_ground_oy := 0.0
var _transform_ground_oy := 0.0
var _walk_ground_oy := 0.0
var _has_walk := false
var _moving_for_test := false
var _walk_playing := false

@onready var _shadow: Polygon2D = %Shadow
@onready var _robot_sprite: Sprite2D = %RobotSprite
@onready var _walk_sprite: AnimatedSprite2D = %WalkSprite
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
	if _walk_sprite and not _walk_sprite.frame_changed.is_connected(_on_walk_frame_changed):
		_walk_sprite.frame_changed.connect(_on_walk_frame_changed)


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
	var speed := _vehicle_speed() if form == Form.VEHICLE else SPEED_ROBOT
	# Screen-space locomotion: arrow down = +y (south), no iso skew.
	if input_vec.length() > MOVE_EPS:
		velocity = input_vec.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_update_turn_blend(delta)
	if input_vec.length() > MOVE_EPS:
		update_facing_from_velocity(input_vec)
	else:
		_apply_turn_visuals()
	_update_locomotion_visuals()


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
	_stop_walk()
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
	_stop_walk()
	_apply_visuals()
	_apply_facing_visuals()
	form_changed.emit(form)


func set_character(id: String) -> void:
	character_id = id
	GameState.current_character_id = id
	_load_character_art()
	_reset_turn_state()
	_stop_walk()
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


func has_walk_animation() -> bool:
	return _has_walk


func is_walk_playing() -> bool:
	return _walk_playing


func get_ground_contact_offset_y() -> float:
	if form == Form.VEHICLE:
		return _vehicle_ground_oy
	return _robot_ground_oy


## Unit-test helper: force locomotion as if moving / stopped.
func set_moving_for_test(moving: bool) -> void:
	_moving_for_test = moving
	if moving and velocity.length() <= MOVE_EPS:
		velocity = Vector2(SPEED_ROBOT, 0.0)
	elif not moving:
		velocity = Vector2.ZERO
	_update_locomotion_visuals()


func is_facing_left() -> bool:
	return _facing_left


func get_facing() -> int:
	return int(_facing)


## 8-dir facing from screen velocity via atan2: +x=E, +y=S, −y=N.
## Sectors are 45° each, centered on the cardinals/diagonals.
static func facing_from_velocity(vel: Vector2) -> Facing:
	if absf(vel.x) < MOVE_EPS and absf(vel.y) < MOVE_EPS:
		return Facing.S
	var angle := atan2(vel.y, vel.x)
	# Sector 0 = E at angle 0; then SE, S, SW, W, NW, N, NE.
	var sector := int(floor((angle + PI / 8.0) / (PI / 4.0)))
	sector = ((sector % 8) + 8) % 8
	const SECTOR_TO_FACING: Array[Facing] = [
		Facing.E,
		Facing.SE,
		Facing.S,
		Facing.SW,
		Facing.W,
		Facing.NW,
		Facing.N,
		Facing.NE,
	]
	return SECTOR_TO_FACING[sector]


func get_turn_blend() -> float:
	return _turn_blend


func uses_dir_textures() -> bool:
	return _form_has_dir_art(form)


func _form_has_dir_art(which: Form) -> bool:
	var has: Array = _vehicle_has_dir if which == Form.VEHICLE else _robot_has_dir
	for i in range(DIR_COUNT):
		if bool(has[i]):
			return true
	return false


func _facing_has_dir_art(which: Form) -> bool:
	var has: Array = _vehicle_has_dir if which == Form.VEHICLE else _robot_has_dir
	return bool(has[_facing])


## True for N/E/S/W; false for NE/SE/SW/NW.
func _facing_is_cardinal(facing: Facing = _facing) -> bool:
	return facing == Facing.N or facing == Facing.E or facing == Facing.S or facing == Facing.W


## resource_path of the texture `_texture_for` would show for `which` at current facing.
func get_facing_texture_path(which: Form) -> String:
	var tex := _texture_for(which)
	if tex == null:
		return ""
	return tex.resource_path


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
	_update_locomotion_visuals()


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
	if _walk_sprite:
		# W walk uses east frames + flip.
		_walk_sprite.flip_h = _facing == Facing.W
	if _transform_sprite:
		_transform_sprite.flip_h = flip_xform
		_transform_sprite.rotation = 0.0
	if _transforming:
		if _robot_sprite:
			_robot_sprite.rotation = 0.0
		if _vehicle_sprite:
			_vehicle_sprite.rotation = 0.0
		if _walk_sprite:
			_walk_sprite.rotation = 0.0
		return
	_apply_turn_visuals()


func _apply_turn_visuals() -> void:
	if _transforming:
		return
	# Dedicated dir art: no lean — show the static facing sprite as authored.
	var lean := 0.0
	if not uses_dir_textures():
		var lean_scale := LEAN_VEHICLE_RAD if form == Form.VEHICLE else LEAN_ROBOT_RAD
		lean = _turn_blend * lean_scale
	if _robot_sprite:
		_robot_sprite.rotation = lean if form == Form.ROBOT else 0.0
		_robot_sprite.texture = _texture_for(Form.ROBOT)
		if _robot_sprite.texture:
			_ground_align(_robot_sprite, _robot_sprite.texture)
			_robot_ground_oy = _robot_sprite.offset.y
	if _walk_sprite:
		_walk_sprite.rotation = lean if form == Form.ROBOT else 0.0
	if _vehicle_sprite:
		_vehicle_sprite.rotation = lean if form == Form.VEHICLE else 0.0
		_vehicle_sprite.texture = _texture_for(Form.VEHICLE)
		if _vehicle_sprite.texture:
			_ground_align(_vehicle_sprite, _vehicle_sprite.texture)
			_vehicle_ground_oy = _vehicle_sprite.offset.y
	_place_form_label()


func _texture_for(which: Form) -> Texture2D:
	var dirs: Array = _vehicle_dir if which == Form.VEHICLE else _robot_dir
	var facing_tex: Texture2D = dirs[_facing] as Texture2D
	# Prefer facing slot texture whenever set (dedicated or cardinal fallback).
	if facing_tex != null and (_facing_has_dir_art(which) or _form_has_dir_art(which)):
		return facing_tex
	# Legacy turn-pose swap only when this form has no dir art at all.
	var use_turn := (not _form_has_dir_art(which)) and absf(_turn_blend) > TURN_POSE_THRESHOLD
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


## Deprecated identity: locomotion is screen-aligned; kept for older tests.
func _cartesian_to_iso(input: Vector2) -> Vector2:
	return input


func _is_moving() -> bool:
	if _moving_for_test:
		return true
	return velocity.length() > MOVE_EPS


func _update_locomotion_visuals() -> void:
	if _transforming:
		return
	_update_shadow()
	if form == Form.VEHICLE:
		_stop_walk()
		if _vehicle_sprite and _vehicle_sprite.visible:
			var bob := 0.0
			if _is_moving():
				bob = sin(Time.get_ticks_msec() / 1000.0 * TAU * VEHICLE_BOB_HZ) * VEHICLE_BOB_AMP
			_vehicle_sprite.offset.y = _vehicle_ground_oy + bob
		return
	# Robot form: walk cycles only for cardinals; diagonals stay on static dir art.
	if _has_walk and _is_moving() and _facing_is_cardinal():
		_start_walk()
	else:
		_stop_walk()
		if _robot_sprite and _robot_sprite.texture:
			_ground_align(_robot_sprite, _robot_sprite.texture)
			_robot_ground_oy = _robot_sprite.offset.y


func _start_walk() -> void:
	if not _has_walk or _walk_sprite == null:
		return
	if not _facing_is_cardinal():
		_stop_walk()
		return
	var anim := _walk_anim_name(_facing)
	if not _walk_sprite.sprite_frames.has_animation(anim):
		return
	_walk_playing = true
	if _robot_sprite:
		_robot_sprite.visible = false
	_walk_sprite.visible = true
	if _walk_sprite.animation != anim or not _walk_sprite.is_playing():
		_walk_sprite.play(anim)
	_walk_sprite.flip_h = _facing == Facing.W
	_align_walk_frame()


func _on_walk_frame_changed() -> void:
	if _walk_playing:
		_align_walk_frame()


func _align_walk_frame() -> void:
	if _walk_sprite == null or _walk_sprite.sprite_frames == null:
		return
	var anim := _walk_sprite.animation
	if not _walk_sprite.sprite_frames.has_animation(anim):
		return
	var tex := _walk_sprite.sprite_frames.get_frame_texture(anim, _walk_sprite.frame)
	if tex:
		_ground_align(_walk_sprite, tex)
		_walk_ground_oy = _walk_sprite.offset.y


func _stop_walk() -> void:
	_walk_playing = false
	if _walk_sprite:
		_walk_sprite.stop()
		_walk_sprite.visible = false
	if form == Form.ROBOT and not _transforming and _robot_sprite:
		_robot_sprite.visible = true


func _walk_anim_name(facing: Facing) -> String:
	# Only called for cardinals; diagonals use static RobotSprite dir art.
	match facing:
		Facing.N:
			return "walk_n"
		Facing.S:
			return "walk_s"
		_:
			# E and W share east frames; W flips via flip_h.
			return "walk_e"


func _update_shadow() -> void:
	if _shadow == null:
		return
	_shadow.visible = true
	_shadow.scale = SHADOW_SCALE_VEHICLE if form == Form.VEHICLE else SHADOW_SCALE_ROBOT


func _ground_align(sprite: Node2D, tex: Texture2D) -> void:
	if sprite == null or tex == null:
		return
	var half_h := float(tex.get_height()) * 0.5
	if sprite is Sprite2D:
		var s := sprite as Sprite2D
		s.centered = true
		s.offset = Vector2(0.0, -half_h)
	elif sprite is AnimatedSprite2D:
		var a := sprite as AnimatedSprite2D
		a.centered = true
		a.offset = Vector2(0.0, -half_h)


func _place_form_label() -> void:
	if _form_label == null:
		return
	var tex: Texture2D = null
	if form == Form.VEHICLE:
		tex = _vehicle_sprite.texture if _vehicle_sprite else null
	elif _walk_playing and _walk_sprite and _walk_sprite.sprite_frames:
		var anim := _walk_anim_name(_facing)
		if _walk_sprite.sprite_frames.has_animation(anim):
			tex = _walk_sprite.sprite_frames.get_frame_texture(anim, 0)
	if tex == null and _robot_sprite:
		tex = _robot_sprite.texture
	var top_y := -72.0
	if tex != null:
		top_y = -float(tex.get_height()) * SPRITE_SCALE.y - FORM_LABEL_PAD
	_form_label.offset_top = top_y - 20.0
	_form_label.offset_bottom = top_y


func _load_character_art() -> void:
	var robot_path := ART + "%s_robot.png" % character_id
	var vehicle_path := ART + "%s_vehicle.png" % character_id
	var robot_turn_path := ART + "%s_robot_turn.png" % character_id
	var vehicle_turn_path := ART + "%s_vehicle_turn.png" % character_id
	_robot_idle_tex = null
	_vehicle_idle_tex = null
	_robot_turn_tex = null
	_vehicle_turn_tex = null
	_robot_dir = [null, null, null, null, null, null, null, null]
	_vehicle_dir = [null, null, null, null, null, null, null, null]
	_robot_has_dir = [false, false, false, false, false, false, false, false]
	_vehicle_has_dir = [false, false, false, false, false, false, false, false]
	_robot_flip_w = false
	_vehicle_flip_w = false
	_has_walk = false
	if ResourceLoader.exists(robot_path):
		_robot_idle_tex = load(robot_path)
		_robot_sprite.texture = _robot_idle_tex
	else:
		push_error("Missing robot art: %s" % robot_path)
	if ResourceLoader.exists(vehicle_path):
		_vehicle_idle_tex = load(vehicle_path)
		_vehicle_sprite.texture = _vehicle_idle_tex
	else:
		push_error("Missing vehicle art: %s" % vehicle_path)
	if ResourceLoader.exists(robot_turn_path):
		_robot_turn_tex = load(robot_turn_path)
	if ResourceLoader.exists(vehicle_turn_path):
		_vehicle_turn_tex = load(vehicle_turn_path)
	_load_dir_textures("robot", _robot_idle_tex, _robot_dir, _robot_has_dir)
	_load_dir_textures("vehicle", _vehicle_idle_tex, _vehicle_dir, _vehicle_has_dir)
	_apply_cardinal_flip_fallbacks()
	_apply_diagonal_fallbacks(_robot_dir, _robot_has_dir, true)
	_apply_diagonal_fallbacks(_vehicle_dir, _vehicle_has_dir, false)
	_robot_sprite.scale = SPRITE_SCALE
	_vehicle_sprite.scale = SPRITE_SCALE
	_robot_sprite.centered = true
	_vehicle_sprite.centered = true
	if _robot_sprite.texture:
		_ground_align(_robot_sprite, _robot_sprite.texture)
		_robot_ground_oy = _robot_sprite.offset.y
	if _vehicle_sprite.texture:
		_ground_align(_vehicle_sprite, _vehicle_sprite.texture)
		_vehicle_ground_oy = _vehicle_sprite.offset.y

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
		_transform_ground_oy = _ground_offset_y(forward[0])
	_transform_sprite.sprite_frames = frames
	_transform_sprite.scale = SPRITE_SCALE
	_transform_sprite.centered = true
	_transform_sprite.offset = Vector2(0.0, _transform_ground_oy)

	_load_walk_frames()
	_place_form_label()
	_update_shadow()


func _ground_offset_y(tex: Texture2D) -> float:
	if tex == null:
		return 0.0
	return -float(tex.get_height()) * 0.5


func _load_walk_frames() -> void:
	_has_walk = false
	if _walk_sprite == null:
		return
	var walk_frames := SpriteFrames.new()
	var loaded_any := false
	for d in WALK_DIRS:
		var anim := "walk_%s" % d
		var frame_texs: Array[Texture2D] = []
		for i in range(1, 5):
			var path := ART + "%s_robot_walk_%s_%02d.png" % [character_id, d, i]
			if ResourceLoader.exists(path):
				frame_texs.append(load(path))
		if frame_texs.size() == 4:
			walk_frames.add_animation(anim)
			walk_frames.set_animation_speed(anim, WALK_FPS)
			walk_frames.set_animation_loop(anim, true)
			for tex in frame_texs:
				walk_frames.add_frame(anim, tex)
			loaded_any = true
			if _walk_ground_oy == 0.0:
				_walk_ground_oy = _ground_offset_y(frame_texs[0])
	_walk_sprite.sprite_frames = walk_frames
	_walk_sprite.scale = SPRITE_SCALE
	_walk_sprite.centered = true
	_walk_sprite.offset = Vector2(0.0, _walk_ground_oy)
	_walk_sprite.visible = false
	_has_walk = loaded_any and walk_frames.has_animation("walk_s")


func _load_dir_textures(
	form_name: String,
	idle: Texture2D,
	out_dirs: Array,
	out_has: Array
) -> void:
	for i in range(DIR_COUNT):
		var path := ART + "%s_%s_%s.png" % [character_id, form_name, DIR_SUFFIX[i]]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				out_dirs[i] = tex
				out_has[i] = true
				continue
		out_dirs[i] = idle
		out_has[i] = false


func _apply_cardinal_flip_fallbacks() -> void:
	# W fallback: mirror E if present, else mirror idle (flip_h).
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


## Missing diagonals fall back to cardinals (prefer S for SE/SW front).
func _apply_diagonal_fallbacks(dirs: Array, has: Array, _prefer_s_for_front: bool) -> void:
	_fill_diag_slot(dirs, has, Facing.SE, [Facing.S, Facing.E])
	_fill_diag_slot(dirs, has, Facing.SW, [Facing.S, Facing.W])
	_fill_diag_slot(dirs, has, Facing.NE, [Facing.N, Facing.E])
	_fill_diag_slot(dirs, has, Facing.NW, [Facing.N, Facing.W])


func _fill_diag_slot(dirs: Array, has: Array, slot: Facing, prefs: Array) -> void:
	if bool(has[slot]) and dirs[slot] != null:
		return
	for pref in prefs:
		var p: int = int(pref)
		if dirs[p] != null:
			dirs[slot] = dirs[p]
			has[slot] = false
			return
	# Last resort: leave whatever idle was assigned at load.
	has[slot] = false


func _play_transform(to_vehicle: bool) -> void:
	_transforming = true
	_stop_walk()
	_robot_sprite.visible = false
	_vehicle_sprite.visible = false
	if _walk_sprite:
		_walk_sprite.visible = false
	_transform_sprite.visible = true
	_transform_sprite.scale = TRANSFORM_SPRITE_SCALE
	if _transform_sprite.sprite_frames and _transform_sprite.sprite_frames.has_animation("to_vehicle"):
		var tex := _transform_sprite.sprite_frames.get_frame_texture("to_vehicle", 0)
		if tex:
			_ground_align(_transform_sprite, tex)
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
	if _walk_sprite:
		_walk_sprite.visible = false
	_walk_playing = false
	if _robot_sprite:
		_robot_sprite.visible = form == Form.ROBOT
	if _vehicle_sprite:
		_vehicle_sprite.visible = form == Form.VEHICLE
	if _form_label:
		_form_label.text = "Robot" if form == Form.ROBOT else "Fahrzeug"
	_update_shadow()
	_place_form_label()
