class_name Coin
extends Area2D
## Collectible that disappears when the player touches it.


@onready var animation_player := $AnimationPlayer as AnimationPlayer


func _on_body_entered(body: Node2D) -> void:
    animation_player.play("picked")
    if body.get_class() == "Player":
        body.emit_signal("coin_collected")
