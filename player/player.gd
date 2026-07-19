extends CharacterBody2D

signal coin_collected

const WALK_SPEED: float = 120.0
const ACCELERATION_SPEED: float = WALK_SPEED * 6.0
# Scale: 64px grid tile = 6in, so 1ft = 128px. TERMINAL_VELOCITY scaled to match
# 2d/default_gravity=4118 (real-world 1g at this scale, see project.godot).
const TERMINAL_VELOCITY: float = 1372.0

# --- Buoyancy (underwater physics) ---
# Waterline: everything above this y is open air (normal gravity), everything
# below follows buoyancy. Y grows downward, so "deeper" means larger y.
const WATERLINE_Y: float = 400.0
# Open-air gravity (4118 px/s^2) is far stronger than underwater buoyant
# acceleration (tens to low hundreds of px/s^2), so switching between them
# instantly at the waterline causes a hard velocity discontinuity: Blubby
# rockets up, pops into "air" gravity, gets yanked back down, re-enters water
# fast, and bounces forever. Blending the two over this band around the
# waterline removes that discontinuity.
const WATERLINE_BLEND: float = 64.0 # px, one grid tile

# Typical volume of a fantail goldfish is 15in^3 (~0.246L total).
# Tissue (non-air-sack) density is slightly above water so a fully deflated
# fish sinks; the air sack's displaced volume is what makes it float.
const RHO_WATER: float = 1.0 # kg/L (fresh water, approx)
const RHO_TISSUE: float = 1.05 # kg/L, real fish flesh/bone is denser than water
const AIR_VOLUME_FULL: float = 0.02 # L, fully inflated air sack
const BODY_VOLUME_EMPTY: float = 0.2258 # L, displaced volume with air sack empty
const BODY_VOLUME_FULL: float = BODY_VOLUME_EMPTY + AIR_VOLUME_FULL # L, fully inflated
const MASS_KG: float = BODY_VOLUME_EMPTY * RHO_TISSUE # fish mass is constant; air is ~massless by comparison

# How fast the air sack fills/empties per second of held input.
const INFLATE_RATE: float = 1.0
const DEFLATE_RATE: float = 1.0

# Depth (in px below the waterline) over which water pressure ramps from
# "surface" to "fully compressed". Stylized, not literal Boyle's law/33ft-per-atm,
# so pressure effects are felt across this map's playable depth rather than
# needing real ocean depths to matter. Tune alongside level/content work.
# Set past the map's current max depth (~5000px) so full inflation can still
# out-swim pressure anywhere reachable today, while a genuine "point of no
# return" still exists further down — same as real free-diving, where past a
# certain depth no amount of air in your lungs/BCD can out-buoy the pressure.
const PRESSURE_FALLOFF_DEPTH: float = 15000.0

const UNDERWATER_TERMINAL_VELOCITY: float = 400.0

# Fish tissue isn't perfectly incompressible either; approximate a mild extra
# compression under pressure so sinking (not just floating) is depth-dependent
# too — without this, a deflated Blubby sinks at the exact same rate at any
# depth, which doesn't read as "descending."
const TISSUE_COMPRESSIBILITY: float = 0.1

# Water drag (1/s): without it, buoyancy has nothing to dissipate energy, so
# Blubby overshoots his neutral depth, gets pushed back, overshoots again, and
# oscillates between the seafloor and the surface forever like a frictionless
# spring. This damps vertical velocity underwater so he actually settles.
const WATER_DRAG: float = 2.0

# Idle bob: a purely cosmetic sprite-only sine wave (never touches velocity/
# collision) so Blubby doesn't look frozen-stiff when nearly stopped, like a
# fish hanging in the water.
const IDLE_BOB_SPEED_THRESHOLD: float = 15.0 # px/s, below this counts as "stopped"
const IDLE_BOB_AMPLITUDE: float = 3.0 # px
const IDLE_BOB_FREQUENCY: float = 1.5 # cycles/sec

# Swim animation speed tiers, as a fraction of WALK_SPEED.
const INTENSE_SWIM_SPEED_FRACTION: float = 0.6
const FRANTIC_SWIM_SPEED_FRACTION: float = 0.9

@onready var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var _air_fill: float = 0.5 # 0 = air sack empty, 1 = fully inflated; start half-full so Blubby doesn't instantly sink on spawn

@onready var platform_detector: RayCast2D = $PlatformDetector
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var jump_sound: AudioStreamPlayer2D = $Jump
@onready var camera: Camera2D = $Camera
@onready var bubbles: CPUParticles2D = $Sprite2D/Bubbles

var _double_jump_charged: bool = false
var _idle_bob_time: float = 0.0
@onready var _sprite_base_position: Vector2 = sprite.position
var _facing: float = 1.0 # +1 = facing right, -1 = facing left

func _ready() -> void:
	add_to_group(&"player")
	print("Player script is running")

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_double_jump_charged = true

	if Input.is_action_pressed("jump"):
		_air_fill = minf(1.0, _air_fill + INFLATE_RATE * delta)
	var is_deflating := Input.is_action_pressed("deflate")
	if is_deflating:
		_air_fill = maxf(0.0, _air_fill - DEFLATE_RATE * delta)
	bubbles.emitting = is_deflating and _air_fill > 0.0

	var is_underwater := global_position.y >= WATERLINE_Y
	# Underwater there's no "floor to stand on" — the seafloor is just an
	# obstacle Blubby swims along, not a resting surface. Grounded mode's floor
	# snapping otherwise cancels small upward buoyant velocity every frame,
	# making it impossible to swim up off the bottom.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING if is_underwater else CharacterBody2D.MOTION_MODE_GROUNDED

	# Blend gravity and buoyancy across a band around the waterline so
	# crossing it doesn't cause a hard velocity discontinuity (see
	# WATERLINE_BLEND). 0 = fully in air, 1 = fully underwater.
	var water_t := clampf((global_position.y - (WATERLINE_Y - WATERLINE_BLEND)) / (2.0 * WATERLINE_BLEND), 0.0, 1.0)
	var depth := maxf(0.0, global_position.y - WATERLINE_Y)
	var accel := lerpf(gravity, _buoyant_acceleration(depth), water_t)
	var drag_accel := -velocity.y * WATER_DRAG * water_t
	var terminal := lerpf(TERMINAL_VELOCITY, UNDERWATER_TERMINAL_VELOCITY, water_t)
	velocity.y = clampf(velocity.y + (accel + drag_accel) * delta, -terminal, terminal)

	# Handle horizontal movement
	var direction := Input.get_axis("move_left", "move_right") * WALK_SPEED
	velocity.x = move_toward(velocity.x, direction, ACCELERATION_SPEED * delta)

	# Flip sprite based on movement direction, playing the turnaround animation
	# on an actual reversal rather than instantly mirroring.
	var new_facing := _facing
	if not is_zero_approx(velocity.x):
		new_facing = 1.0 if velocity.x > 0.0 else -1.0
	if new_facing != _facing and sprite.animation != &"turnaround-180":
		sprite.play(&"turnaround-180")
	_facing = new_facing
	sprite.flip_h = _facing < 0.0

	floor_stop_on_slope = not is_underwater and not platform_detector.is_colliding()
	move_and_slide()

	# Idle bob: nudge the sprite (not the body) up and down when nearly
	# stopped, so Blubby reads as floating in place rather than frozen.
	if velocity.length() < IDLE_BOB_SPEED_THRESHOLD:
		_idle_bob_time += delta
		var bob_offset := sin(_idle_bob_time * TAU * IDLE_BOB_FREQUENCY) * IDLE_BOB_AMPLITUDE
		sprite.position = _sprite_base_position + Vector2(0.0, bob_offset)
	else:
		_idle_bob_time = 0.0
		sprite.position = _sprite_base_position

	# Animation handling. Turnaround is a one-shot triggered above; don't
	# stomp it with a swim-speed animation until it finishes.
	if sprite.animation != &"turnaround-180" or not sprite.is_playing():
		var animation := _get_new_animation()
		if animation != sprite.animation:
			sprite.play(animation)

func _get_new_animation() -> StringName:
	var speed_fraction := absf(velocity.x) / WALK_SPEED
	if speed_fraction >= FRANTIC_SWIM_SPEED_FRACTION:
		return &"frantic-boost-swim"
	elif speed_fraction >= INTENSE_SWIM_SPEED_FRACTION:
		return &"intense-swim"
	return &"swim"

## Net vertical acceleration (px/s^2) from buoyancy at the given depth (px below
## the waterline). Positive = downward (sinking), negative = upward (floating).
func _buoyant_acceleration(depth: float) -> float:
	var pressure_factor := clampf(1.0 - depth / PRESSURE_FALLOFF_DEPTH, 0.0, 1.0)
	var tissue_volume := BODY_VOLUME_EMPTY * (1.0 - TISSUE_COMPRESSIBILITY * (1.0 - pressure_factor))
	var displaced_volume := tissue_volume + (BODY_VOLUME_FULL - BODY_VOLUME_EMPTY) * _air_fill * pressure_factor
	var displaced_mass := displaced_volume * RHO_WATER

	# Weight - buoyant force, per unit mass, scaled to this project's gravity constant.
	return (MASS_KG - displaced_mass) / MASS_KG * gravity
