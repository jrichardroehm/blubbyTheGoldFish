class_name Enemy
extends CharacterBody2D

enum State {
	SWIMMING,
	DEAD,
}

const SWIM_SPEED: float = 40.0
const DIRECTION_CHANGE_INTERVAL_MIN: float = 2.0
const DIRECTION_CHANGE_INTERVAL_MAX: float = 5.0

var _state := State.SWIMMING
var _direction := Vector2.RIGHT
var _direction_change_timer: float = 0.0

@onready var sprite := $Sprite2D as AnimatedSprite2D


func _ready() -> void:
	_pick_new_direction()


func _physics_process(delta: float) -> void:
	if _state != State.SWIMMING:
		return

	_direction_change_timer -= delta
	if _direction_change_timer <= 0.0:
		_pick_new_direction()

	velocity = _direction * SWIM_SPEED
	move_and_slide()

	if is_on_wall():
		_pick_new_direction()

	sprite.flip_h = velocity.x < 0.0


func destroy() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO


func _pick_new_direction() -> void:
	_direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	_direction_change_timer = randf_range(DIRECTION_CHANGE_INTERVAL_MIN, DIRECTION_CHANGE_INTERVAL_MAX)
