extends SceneTree
## Transform anim assets + playback visibility for bolt/marina/rush.

var _failed: int = 0

const CHAR_IDS := ["bolt", "marina", "rush"]

const REQUIRED_TRANSFORM := [
	"res://assets/art/bolt_transform_01.png",
	"res://assets/art/bolt_transform_06.png",
	"res://assets/art/marina_transform_01.png",
	"res://assets/art/marina_transform_06.png",
	"res://assets/art/rush_transform_01.png",
	"res://assets/art/rush_transform_06.png",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== m2_transform_test start ===")
	for path in REQUIRED_TRANSFORM:
		_assert(ResourceLoader.exists(path), "exists %s" % path)

	var packed: Variant = load("res://scenes/player.tscn")
	_assert(packed is PackedScene, "player.tscn loads")
	if packed is PackedScene:
		var player: Node = (packed as PackedScene).instantiate()
		root.add_child(player)
		for id in CHAR_IDS:
			player.call("set_character", id)
			_assert(bool(player.call("has_transform_animation")), "%s has_transform_animation" % id)
			var frames: SpriteFrames = player.get_node("TransformSprite").sprite_frames
			_assert(frames != null and frames.has_animation("to_vehicle"), "%s has to_vehicle" % id)
			if frames != null and frames.has_animation("to_vehicle"):
				_assert(
					frames.get_frame_count("to_vehicle") >= 4,
					"%s to_vehicle frames >= 4 (got %d)" % [id, frames.get_frame_count("to_vehicle")]
				)
			player.set("_transform_lock", 0.0)
			player.set("_transforming", false)
			player.call("set_form", 0) # Form.ROBOT
			player.call("toggle_form")
			_assert(bool(player.get("_transforming")), "%s toggle → _transforming" % id)
			var xform: AnimatedSprite2D = player.get_node("TransformSprite")
			_assert(xform.visible, "%s toggle → TransformSprite.visible" % id)
			# Finish anim so next character starts clean.
			if bool(player.get("_transforming")):
				player.call("_on_transform_finished")
		player.queue_free()

	if _failed == 0:
		print("=== m2_transform_test PASS ===")
		quit(0)
	else:
		printerr("=== m2_transform_test FAIL (%d) ===" % _failed)
		quit(1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)
