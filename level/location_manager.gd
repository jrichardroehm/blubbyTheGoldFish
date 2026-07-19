extends Node
## Autoload. Remembers where Blubby should spawn after a scene transition
## triggered by swimming into a location (cave, ship, etc).

var pending_spawn_position: Vector2 = Vector2.ZERO
var has_pending_spawn: bool = false


func travel_to(scene_path: String, spawn_position: Vector2) -> void:
	pending_spawn_position = spawn_position
	has_pending_spawn = true
	get_tree().change_scene_to_file(scene_path)


func consume_pending_spawn() -> Vector2:
	has_pending_spawn = false
	return pending_spawn_position
