# Author: Lastek
# FP controller
# MIT License
# Based off of Colormatic Studio's FPC v2
# Thanks to StayAtHomeDev for his YouTube tutorials

class_name Character extends CharacterBody3D
var myq := InputQueue

var PL_HEAD: Node3D
var PL_CAMERA: Camera3D
var PL_MESH: MeshInstance3D
var PL_COLLISION_MESH: CollisionShape3D
var PL_CROUCH_CEILING_DETECTION: Node3D
var AN_HEADBOB_EFFECT: AnimationPlayer
var AN_JUMP_EFFECT: AnimationPlayer
var AN_CROUCH_EFFECT: AnimationPlayer
var AN_CROUCH_EFFECT_SPEED: float = 3.0
var AN_JUMP_EFFECT_AMOUNT: float = 1.0
var AN_HEADBOB_EFFECT_AMOUNT: float = 1.0
var AN_ENABLED: bool = true # This wont apply to crouching the way it's done rn.


const SPEED_BASE = 6.0
const SPRINT_SPEED_MUL = 1.75

const ACCELERATION = 40
const ACCELERATION_AIR = .055555
const DECELERATION = 30.0

const CROUCH_SPEED = 1.0

const JUMP_VELOCITY = 3.5
const JUMP_MUL = 1.8
var FRICTION = .8

const MOUSE_SENSITIVITY = 0.1

var speed = SPEED_BASE

var input_dir: Vector2
var input_dir_prev: Vector2
var direction: Vector3
var crouched: bool = false
var crouch_mode: bool = false

var low_ceiling: bool = false
var was_on_floor: bool = false
var dir_lerp: Vector2 = Vector2(0.0, 0.0)
var f_transform: Vector3 = Vector3(0.0, 0.0, 0.0)
# Get the gravity from the project settings to be synced with RigidBody nodes.
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

# Stores mouse input for rotating the camera in the physics process
var mouseInput: Vector2 = Vector2(0, 0)

# this is problematic because this is not restricted to ACTIONS
enum {
	JUMP = 0,
	LEFT,
	RIGHT,
	FORWARD,
	BACKWARD,
	CROUCH,
	SPRINT,
	PAUSE
}

var ACTIONS: Dictionary = {
JUMP: "vk_jump",
LEFT: "vk_left",
RIGHT: "vk_right",
FORWARD: "vk_forward",
BACKWARD: "vk_backward",
PAUSE: "vk_pause",
CROUCH: "vk_crouch",
SPRINT: "vk_sprint"
}

var PlayerStateIdle: State
var PlayerStateWalk: State
var PlayerStateSprint: State
var FSM: StateMachine
var frames = 0
var dt_ac = 0.0
@onready var dt = Engine.physics_ticks_per_second / 1000
var physics_time = 0.0
#==============================================================================
#==============================================================================

enum PHYS_STATE {
	POSITION,
	VELOCITY,
	ROTATION,
	INPUT_DIR,  # Add input state
	DIRECTION,  # Add processed direction
	TIME,
	SIZE
}

# Fixed-size arrays for physics states
var physics_state: Array = []
var previous_physics_state: Array = []
var tracker = 0
func _ready():
	# Initialize arrays with correct size
	physics_state.resize(PHYS_STATE.SIZE)
	previous_physics_state.resize(PHYS_STATE.SIZE)

	# Initialize default values
	physics_time = Time.get_ticks_usec() / 1000000.0
	physics_state[PHYS_STATE.POSITION] = position
	physics_state[PHYS_STATE.VELOCITY] = velocity
	physics_state[PHYS_STATE.ROTATION] = PL_HEAD.rotation
	physics_state[PHYS_STATE.INPUT_DIR] = Vector2.ZERO
	physics_state[PHYS_STATE.DIRECTION] = Vector3.ZERO
	physics_state[PHYS_STATE.TIME] = physics_time
	previous_physics_state = physics_state.duplicate()

	# ... rest of your _ready() code ...
	ready_cont()


func ready_cont():
	print("Player _ready():")
	Global.player = self # provides reference to player
	print("Init FSM")
	print("Get Player Node references")
	PL_HEAD = get_node("Head")
	PL_CAMERA = get_node("Head/Camera")
	PL_MESH = get_node("Mesh")
	PL_COLLISION_MESH = get_node("Collision")
	PL_CROUCH_CEILING_DETECTION = get_node("CrouchCeilingDetection")
	AN_HEADBOB_EFFECT = get_node("Head/HeadbobAnimation")
	AN_JUMP_EFFECT = get_node("Head/JumpAnimation")
	AN_CROUCH_EFFECT = get_node("CrouchAnimation")
	PL_CROUCH_CEILING_DETECTION.add_exception($".")
	print("set up inputs")
	controls_mapping_check()
	initStates()
	initAnim()
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # This has been relocated to the main scene script
	print("End Player _ready()")


func initStates():
	PlayerStateIdle = StateIdle.new()
	PlayerStateWalk = StateWalk.new()
	PlayerStateSprint = StateSprint.new()
	## Prepare animations:
	PlayerStateWalk.ANIMATION = AN_HEADBOB_EFFECT
	PlayerStateSprint.ANIMATION = AN_HEADBOB_EFFECT
	FSM = StateMachine.new()

	FSM.add_child(PlayerStateIdle)
	FSM.add_child(PlayerStateWalk)
	# add_child(FSM) # Add FSM as child after assigning states to kick off _ready()

## Some housekeeping to make sure anims start correctly
func initAnim():
	AN_HEADBOB_EFFECT.play("RESET")


# Current input state that will be used in next physics step
var current_input: Dictionary = {
	"input_dir": Vector2.ZERO,
	"direction": Vector3.ZERO
}

func _physics_process(delta: float) -> void:
	previous_physics_state = physics_state.duplicate()
	
	# Handle input before physics integration
	handle_input(delta)
	integrate_physics(delta)
	
	physics_time += delta
	physics_state[PHYS_STATE.POSITION] = position
	physics_state[PHYS_STATE.VELOCITY] = velocity
	physics_state[PHYS_STATE.ROTATION] = PL_HEAD.rotation
	physics_state[PHYS_STATE.TIME] = physics_time

func _process(_delta: float) -> void:
	var render_time = Time.get_ticks_usec() / 1000000.0
	var alpha = (render_time - previous_physics_state[PHYS_STATE.TIME]) / PHYSICS_DT
	alpha = clampf(alpha, 0.0, 1.0)
	
	var snapshot_position = previous_physics_state[PHYS_STATE.POSITION] + (
		physics_state[PHYS_STATE.POSITION] - 
		previous_physics_state[PHYS_STATE.POSITION]
	) * alpha
	
	position = snapshot_position
	update_debug_info()

# New function for handling visual effects based on interpolated state
func handle_visual_effects(interpolated_direction: Vector3) -> void:
	# Handle any visual effects that depend on movement direction
	# For example: head bobbing, particle effects, etc.
	if AN_ENABLED and interpolated_direction.length() > 0.1:
		if !AN_HEADBOB_EFFECT.is_playing():
			AN_HEADBOB_EFFECT.play("headbob")
	else:
		if AN_HEADBOB_EFFECT.is_playing():
			AN_HEADBOB_EFFECT.stop()

func update_debug_info() -> void:
	if frames >= 20:
		Global.debug.add_property("FPS", frames/dt_ac, 0)
		dt_ac = 0
		frames = 0

	# Show both current input and physics state input
	Global.debug.add_property("current input", current_input["input_dir"], -1)
	Global.debug.add_property("physics input", physics_state[PHYS_STATE.INPUT_DIR], -1)
	Global.debug.add_property("physics direction", physics_state[PHYS_STATE.DIRECTION], -1)
	Global.debug.add_property("PL_HEAD", PL_HEAD.rotation, -1)
	Global.debug.add_property("Velocity", velocity, -1)
# func _physics_process(delta: float) -> void:
# 	f_tracker("physics")
# 	# Store previous state
# 	previous_physics_state = physics_state.duplicate()

# 	# Run physics simulation
# 	r_physics_process(delta)

# 	# Update physics state
# 	physics_time += delta	
# 	physics_state[PHYS_STATE.POSITION] = position
# 	physics_state[PHYS_STATE.VELOCITY] = velocity
# 	physics_state[PHYS_STATE.ROTATION] = PL_HEAD.rotation
# 	physics_state[PHYS_STATE.TIME] = physics_time

# 	### DEBUG ###
# 	if velocity.length() > 40:
# 		Global.debug.add_property("Broken :((( -> ", "", -1)
# 	### ### ### #

# func _process(delta: float) -> void:
# 	frames += 1
# 	dt_ac += delta
# 	f_tracker("process-")
# 	# Get current render time
# 	var render_time = Time.get_ticks_usec() / 1000000.0

# 	# Calculate alpha between physics frames
# 	var alpha = (render_time - previous_physics_state[PHYS_STATE.TIME]) / dt
# 	alpha = clampf(alpha, 0.0, 1.0)

# 	# Update input
# 	# handle_mouse_input()
# 	handle_input(delta)
# 	# Interpolate between physics states
# 	var snapshot_position = previous_physics_state[PHYS_STATE.POSITION] + (
# 		physics_state[PHYS_STATE.POSITION] - 
# 		previous_physics_state[PHYS_STATE.POSITION]
# 	) * alpha
# 	# Apply snapshot values
# 	position = snapshot_position
# 	# Handle other non-physics updates
# 	update_debug_info()

func integrate_physics(delta):
	var accel = ACCELERATION
	# var dt = delta
	if !is_on_floor():
		velocity.y -= GRAVITY * delta * JUMP_MUL
		accel = ACCELERATION_AIR

 	# give speed in facing direction with acceleration (faking friction)
 	# how to do rampup for input vector to allow small taps. Taps vs Holding
	if direction:
		#velocity.x = lerp(velocity.x, direction.x * speed, delta*accel)
		#velocity.z = lerp(velocity.z, direction.z * speed, delta*accel)
		velocity.z = velocity.z+(direction.z*speed - velocity.z)*delta*accel
		velocity.x = velocity.x+(direction.x*speed - velocity.x)*delta*accel
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta*DECELERATION)
		velocity.z = move_toward(velocity.z, 0.0, delta*DECELERATION)

	var frict = FRICTION * delta
	var spd = velocity.length()
	var dv = 0
	if (frict < spd):
		dv = frict * -1 * (velocity / spd)
	else:
		dv = -velocity
	velocity += dv

 	# This is a curious method for movement. Might be cool mechanic
 	# velocity = stop_motion_movement(velocity, direction, speed, accel, delta)
	move_and_slide()
	Global.debug.add_property("speed", speed, -1)


# Move debug info to separate function:
func update_debug_info() -> void:
	if frames >= 40:
		Global.debug.add_property("FPS", frames/dt_ac, 0)
		dt_ac = 0
		frames = 0

	Global.debug.add_property("input vector", input_dir, -1)
	Global.debug.add_property("direction vec", direction, -1)
	Global.debug.add_property("PL_HEAD", PL_HEAD.rotation, -1)
	Global.debug.add_property("Velocity", velocity, -1)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x += event.relative.x * MOUSE_SENSITIVITY
		mouseInput.y += event.relative.y * MOUSE_SENSITIVITY
	if event and event != InputEventMouseMotion:
		pass


func handle_input(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	input_dir = Input.get_vector(ACTIONS[LEFT], ACTIONS[RIGHT], ACTIONS[FORWARD], ACTIONS[BACKWARD])
	Global.debug.add_property("input vector", input_dir, -1)
	
	# doing a basis transform and creating a normalized 3-vec
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	Global.debug.add_property("direction vec", direction, -1)
	
	# Get the direction vector from mouse look
	handle_mouse_input()
	var vec2: Vector2 = input_dir.rotated(-PL_HEAD.rotation.y)
	direction = Vector3(vec2.x, 0, vec2.y)

	Global.debug.add_property("input rotated vec", direction, -1)
	Global.debug.add_property("rotated vec3", direction, -1)
	Global.debug.add_property("Velocity", velocity, -1)


# Move mouse handling to separate function:
func handle_mouse_input() -> void:
	PL_HEAD.rotation_degrees.x -= mouseInput.y
	PL_HEAD.rotation_degrees.y -= mouseInput.x
	PL_HEAD.rotation.x = clamp(PL_HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	mouseInput = Vector2.ZERO


## Just to see what starts first and when things execute
func f_tracker(str:String)-> void:
	if tracker > 10 and tracker < 100:
		tracker += 1
		print("Tracker in %s: " %  str,tracker)
	else: tracker +=1


func calculate_alpha(current_time: float) -> float: 
	var physics_delta = physics_state[PHYS_STATE.TIME] - previous_physics_state[PHYS_STATE.TIME]
	if physics_delta <= 0:
		return 1.0
	var time_since_physics = current_time - previous_physics_state[PHYS_STATE.TIME]
	return clampf(time_since_physics / physics_delta, 0.0, 1.0)


func _unhandled_input(event):
	pass

# Checks that actions are mapped events and that events are mapped to keys
func controls_mapping_check():
	for i in ACTIONS:
		var k = ACTIONS.get(i)
		if !InputMap.has_action(k):
			push_error("No action mapped to ", k)
			print("No action mapped to ", k)
		else:
			var v = InputMap.action_get_events(k)
			if v.is_empty():
				push_error("No key mapped to the following action: ", k)
				print("No key mapped to the following action: ", k)

