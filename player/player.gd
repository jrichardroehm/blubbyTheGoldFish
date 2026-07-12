extends CharacterBody2D

signal coin_collected

const WALK_SPEED: float = 150.0
const ACCELERATION_SPEED: float = WALK_SPEED * 6.0
const JUMP_VELOCITY: float = -4.0
const TERMINAL_VELOCITY: float = 700.0
const DRIFT_SPEED: float = 0.0
const DRIFT_DIRECTION: float = 0.0
# Typical volume of a fantail goldfish is 15in^3, .15kg, .02L (air sack), .25L (body)
const AIR_VOLUME_FULL: float = 0.02 # listed in Liters
const AIR_VOLUME_EMPTY: float = 0.0 # no air in air sack
const BODY_VOLUME_FULL: float = 0.27 # includes air sack
const BODY_VOLUME_EMPTY: float = 0.25 # empty air sack

@export var action_suffix: String = ""

var gravity: int = 0
#(int)ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var platform_detector: RayCast2D = $PlatformDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shoot_timer: Timer = $ShootAnimation
@onready var sprite: Sprite2D = $Sprite2D
@onready var jump_sound: AudioStreamPlayer2D = $Jump
@onready var gun: Gun = $Sprite2D/Gun
@onready var camera: Camera2D = $Camera

var _double_jump_charged: bool = false

func _ready() -> void:
	print("Player script is running")

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_double_jump_charged = true

	if Input.is_action_pressed("jump" + action_suffix):
		_try_inflate()
	elif Input.is_action_pressed("jump" + action_suffix) and velocity.y < 0.0:
		# Reduce vertical momentum if the jump button is released early
		#velocity.y *= 0.6
		pass

	if Input.is_action_pressed("deflate" + action_suffix):
		velocity.y = -JUMP_VELOCITY + velocity.y

	# Apply gravity and terminal velocity
	velocity.y = minf(TERMINAL_VELOCITY, velocity.y + gravity * delta)

	# Handle horizontal movement
	var direction := Input.get_axis("move_left" + action_suffix, "move_right" + action_suffix) * WALK_SPEED
	velocity.x = move_toward(velocity.x, direction, ACCELERATION_SPEED * delta)

	# Flip sprite based on movement direction
	if not is_zero_approx(velocity.x):
		sprite.scale.x = 1.0 if velocity.x > 0.0 else -1.0

	floor_stop_on_slope = not platform_detector.is_colliding()
	move_and_slide()

	# Shooting logic
	var is_shooting := false
	if Input.is_action_just_pressed("shoot" + action_suffix):
		is_shooting = gun.shoot(sprite.scale.x)

	# Animation handling
	var animation := _get_new_animation(is_shooting)
	if animation != animation_player.current_animation and shoot_timer.is_stopped():
		if is_shooting:
			shoot_timer.start()
		animation_player.play(animation)

func _get_new_animation(is_shooting: bool = false) -> String:
	var animation_new: String
	if is_on_floor():
		animation_new = "run" if absf(velocity.x) > 0.1 else "idle"
	else:
		animation_new = "falling" if velocity.y > 0.0 else "jumping"

	if is_shooting:
		animation_new += "_weapon"

	return animation_new

func _try_inflate() -> void:
	# if is_on_floor():
	# 	jump_sound.pitch_scale = 1.0
	# elif _double_jump_charged:
	# 	_double_jump_charged = false
	# 	velocity.x *= 2.5
	# 	jump_sound.pitch_scale = 1.5
	# else:
	# 	return

	velocity.y = JUMP_VELOCITY + velocity.y
	#jump_sound.play()
