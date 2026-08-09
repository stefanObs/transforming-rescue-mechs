extends SceneTree
## M2: Style C art assets present and player can load them.

var _failed: int = 0

const REQUIRED := [
	"res://assets/art/bolt_robot.png",
	"res://assets/art/bolt_vehicle.png",
	"res://assets/art/marina_robot.png",
	"res://assets/art/marina_vehicle.png",
	"res://assets/art/rush_robot.png",
	"res://assets/art/rush_vehicle.png",
	"res://assets/art/rush_transform_01.png",
	"res://assets/art/rush_transform_06.png",
	"res://assets/art/bolt_transform_01.png",
	"res://assets/art/bolt_transform_06.png",
	"res://assets/art/marina_transform_01.png",
	"res://assets/art/marina_transform_06.png",
	"res://assets/art/tile_grass.png",
	"res://assets/art/tile_road.png",
	"res://assets/art/tile_house.png",
	"res://assets/art/tile_church.png",
	"res://assets/art/hub_station.png",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_test start ===")
	for path in REQUIRED:
		_assert(ResourceLoader.exists(path), "exists %s" % path)
		if ResourceLoader.exists(path):
			var tex: Variant = load(path)
			_assert(tex is Texture2D, "loads Texture2D %s" % path)

	var packed: Variant = load("res://scenes/player.tscn")
	_assert(packed is PackedScene, "player.tscn loads")
	if packed is PackedScene:
		var player: Node = (packed as PackedScene).instantiate()
		root.add_child(player)
		player.call("set_character", "bolt")
		_assert(player.get_node("RobotSprite").texture != null, "bolt robot texture")
		_assert(player.get_node("VehicleSprite").texture != null, "bolt vehicle texture")
		var frames: SpriteFrames = player.get_node("TransformSprite").sprite_frames
		_assert(frames != null and frames.has_animation("to_vehicle"), "transform frames")
		_assert(frames.get_frame_count("to_vehicle") >= 4, "transform has >=4 frames")
		player.call("set_character", "marina")
		_assert(player.get_node("RobotSprite").texture != null, "marina robot texture")
		player.call("set_character", "rush")
		_assert(player.get_node("RobotSprite").texture != null, "rush robot texture")
		_assert(player.get_node("VehicleSprite").texture != null, "rush vehicle texture")
		_assert(is_equal_approx(float(player.call("_vehicle_speed")), 360.0), "rush vehicle speed bonus")
		var rush_frames: SpriteFrames = player.get_node("TransformSprite").sprite_frames
		_assert(rush_frames != null and rush_frames.has_animation("to_vehicle"), "rush transform frames")
		player.queue_free()

	_assert_transparent_corners()
	if _failed == 0:
		print("=== m2_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_test FAIL (%d) ===" % _failed)
		quit(1)


func _assert_transparent_corners() -> void:
	for path in [
		"res://assets/art/bolt_robot.png",
		"res://assets/art/rush_vehicle.png",
		"res://assets/art/marina_robot.png",
	]:
		var img := Image.new()
		var err := img.load(path)
		_assert(err == OK, "load image %s" % path)
		if err != OK:
			continue
		_assert(img.get_format() == Image.FORMAT_RGBA8 or img.detect_alpha(), "has alpha %s" % path)
		var c := img.get_pixel(0, 0)
		_assert(c.a < 0.05, "top-left transparent %s (a=%s)" % [path, c.a])


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
