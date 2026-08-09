extends CharacterBody2D
## Player with robot/vehicle forms, isometric movement, transform lockout (M1).

enum Form { ROBOT, VEHICLE }

signal form_changed(new_form: Form)

const SPEED_ROBOT := 140.0
const SPEED_VEHICLE := 260.0
const TRANSFORM_LOCKOUT := 0.6

var form: Form = Form.ROBOT
var _transform_lock := 0.0

@onready var _robot_visual: Polygon2D = %RobotVisual
@onready var _vehicle_visual: Polygon2D = %VehicleVisual
@onready var _form_label: Label = %FormLabel


func _ready() -> void:
	_apply_visuals()


func _physics_process(delta: float) -> void:
	if _transform_lock > 0.0:
		_transform_lock = maxf(0.0, _transform_lock - delta)

	if Input.is_action_just_pressed("transform") and can_transform():
		toggle_form()

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var iso := _cartesian_to_iso(input_vec)
	var speed := SPEED_VEHICLE if form == Form.VEHICLE else SPEED_ROBOT
	if iso.length() > 0.001:
		velocity = iso.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func can_transform() -> bool:
	return _transform_lock <= 0.0


func toggle_form() -> void:
	if not can_transform():
		return
	form = Form.VEHICLE if form == Form.ROBOT else Form.ROBOT
	_transform_lock = TRANSFORM_LOCKOUT
	_apply_visuals()
	form_changed.emit(form)


func set_form(new_form: Form) -> void:
	form = new_form
	_apply_visuals()
	form_changed.emit(form)


func _cartesian_to_iso(input: Vector2) -> Vector2:
	# Classic 2:1 isometric projection for free movement.
	return Vector2(input.x - input.y, (input.x + input.y) * 0.5)


func _apply_visuals() -> void:
	if _robot_visual:
		_robot_visual.visible = form == Form.ROBOT
	if _vehicle_visual:
		_vehicle_visual.visible = form == Form.VEHICLE
	if _form_label:
		_form_label.text = "Robot" if form == Form.ROBOT else "Fahrzeug"
