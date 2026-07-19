class_name LocationTrigger
extends Area2D
## Swimming into this area transitions to another scene, spawning the player
## at the given position there. Used for points of interest (cave, ship, etc).

@export_file("*.tscn") var destination_scene_path: String
@export var destination_spawn_position: Vector2 = Vector2.ZERO


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		LocationManager.travel_to(destination_scene_path, destination_spawn_position)
