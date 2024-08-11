# Author: Lastek 
# FP controller 
# MIT License
# Based off of Colormatic Studio's FPC v2 
# Thanks to StayAtHomeDev for his YouTube tutorials

extends CharacterBody3D

enum STATE {IDLE = 0, NORMAL = 1, CROUCHED = 2, JUMPING = 4, SPRINTING = 8, CROUCHED_RUN = 16}

const SPEED_BASE = 6.0
const SPRINT_SPEED_MUL = 1.75

const ACCELERATION = 1.25
const ACCELERATION_AIR = .055555
const DECELERATION = 0.4

const CROUCH_SPEED = 1.0

const JUMP_VELOCITY = 3.5
const JUMP_MUL = 1.8
var FRICTION = .8

const MOUSE_SENSITIVITY = 0.1

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

#const BIT_TABLE_BITS = 8
#var BIT_TABLE: Array = range(BIT_TABLE_BITS).map(func(n): return 2**n)
#func compute_bit_table(bits:int):
	#BIT_TABLE = range(bits).map(func(n): return 2**n)
# enum STATE {NORMAL, CROUCHED, SPRINTING, CROUCHED_RUN}

var DEBUG_STATE: Dictionary = {
	STATE.IDLE: "idle",
	STATE.NORMAL: "normal",
	STATE.CROUCHED: "crouched",
	STATE.JUMPING: "jumping",
	STATE.SPRINTING: "sprinting",
	STATE.CROUCHED_RUN: "courched_run"
}
var speed = SPEED_BASE
var state: STATE = STATE.NORMAL
var state_prev: STATE = STATE.NORMAL

var input_dir: Vector2
var input_dir_prev: Vector2
var crouched: bool = false
var crouch_mode: bool = false

var low_ceiling: bool = false
var was_on_floor: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

# Stores mouse input for rotating the camera in the phyhsics process
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

func _ready():
	PL_HEAD = get_node("Head")
	PL_CAMERA = get_node("Head/Camera")
	PL_MESH = get_node("Mesh")
	PL_COLLISION_MESH = get_node("Collision")
	PL_CROUCH_CEILING_DETECTION = get_node("CrouchCeilingDetection")
	AN_HEADBOB_EFFECT = get_node("Head/HeadbobAnimation")
	AN_JUMP_EFFECT = get_node("Head/JumpAnimation")
	AN_CROUCH_EFFECT = get_node("CrouchAnimation")
	controls_mapping_check()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	PL_CROUCH_CEILING_DETECTION.add_exception($".")
	
func _physics_process(delta):
	# Add the gravity.
	Global.debug.add_property("STATE", DEBUG_STATE[state], 1)
	Global.debug.add_property("STATE_PREV", DEBUG_STATE[state_prev], 2)
	var accel = ACCELERATION
	
	if !is_on_floor():
		velocity.y -= GRAVITY * delta * JUMP_MUL
		accel = ACCELERATION_AIR

	# Get the input direction and handle the movement/deceleration.
	input_dir = Input.get_vector(ACTIONS[LEFT], ACTIONS[RIGHT], ACTIONS[FORWARD], ACTIONS[BACKWARD])
	# Smooth out movement changes
	#input_dir = lerp(input_dir_prev, input_dir, FRICTION)
	#input_dir_prev = input_dir
	Global.debug.add_property("input vector", input_dir, -1)
	
	# doing a basis transform and creating a normalized 3-vec	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	Global.debug.add_property("direction vec", direction, -1)
	
	# PL_HEAD.rotate(Vector3(1,1,0), -mouseInput.x/PI*MOUSE_SENSITIVITY)
	# PL_HEAD.rotate(Vector3(0,0,1), -mouseInput.y/PI*MOUSE_SENSITIVITY)

	# Get the direction vector from mouse look
	direction = input_dir.rotated(-PL_HEAD.rotation.y)
	Global.debug.add_property("input rotated vec", direction, -1)

	direction = Vector3(direction.x, 0, direction.y)
	
	# rotate player head based on mouse input
	# NOTE: This does not rotate the body and needs to be handled differently
	# perpendicular to z-axis
	PL_HEAD.rotation_degrees.x -= mouseInput.y
	PL_HEAD.rotation_degrees.y -= mouseInput.x

	Global.debug.add_property("PL_HEAD", PL_HEAD.rotation, -1)
	mouseInput = Vector2(0, 0)
	### DEBUG ###
	if speed > 40:
		Global.debug.add_property("Broken :((( -> ", "", -1)
	### ### ### #
	# clam respective to x-axis ( cant look up and backwards)
	PL_HEAD.rotation.x = clamp(PL_HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	Global.debug.add_property("rotated vec3", direction, -1)
	Global.debug.add_property("Velocity", velocity, -1)
	
	# give speed in facing direction with acceleration (faking friction)
	if direction:
		velocity.x = lerp(velocity.x, direction.x * speed, accel)
		velocity.z = lerp(velocity.z, direction.z * speed, accel)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION)
	# set player states
	_state(input_dir)

	# built-in func
	move_and_slide()
	Global.debug.add_property("speed", speed, -1)
	# tracking when player was on floor.
	# FIXME: This should be done as part of _state() 
	was_on_floor = is_on_floor()
	#input_dir_prev = direction

# TODO: Pump events into a queue and then use that to set states accordingly
# this should eliminate if statements for higher perf... supposedly.
func _state(input_dir):
	var touching_floor: int = is_on_floor()
	
	if touching_floor and Input.is_action_just_pressed(ACTIONS[JUMP]):
		velocity.y += JUMP_VELOCITY  * JUMP_MUL
		state_prev = state
		state = STATE.JUMPING
	# elif touching_floor and state == STATE.JUMPING:
		## Swap the two variables
		#@warning_ignore("int_as_enum_without_cast")
		#state_prev ^= state
		#@warning_ignore("int_as_enum_without_cast")
		#state ^= state_prev
		#state_prev ^=state
	elif touching_floor and state == STATE.SPRINTING:
		state_prev = state
		speed = SPEED_BASE
		state = STATE.NORMAL
	elif Input.is_action_pressed(ACTIONS[CROUCH]):
		handle_crouch(touching_floor,true)
	elif Input.is_action_just_released(ACTIONS[CROUCH]):
		handle_crouch(touching_floor,false)
	# FIXME: Proper state handling
	# FIXME: Proper stae handling
	# this will repeatedly trigger
	elif touching_floor and Input.is_action_pressed(ACTIONS[SPRINT]):
		state_prev = state
		speed = SPEED_BASE * SPRINT_SPEED_MUL
		state = STATE.SPRINTING
	set_speed()

func handle_crouch(touching_floor: int, pressed: bool):
	#player is either falling or jumping. Doesnt matter. Just shrink the player and go into crouch state
	if pressed: #touching_floor:
		if Input.is_action_just_pressed(ACTIONS[SPRINT]):
			state_prev = state
			state = STATE.CROUCHED_RUN
		elif Input.is_action_pressed(ACTIONS[SPRINT]):
			state_prev = state
			state = STATE.CROUCHED_RUN
		else:
			state_prev = state
			state = STATE.CROUCHED
	elif !pressed:
		state_prev = state
		state = STATE.NORMAL
		
# TODO: Replace with velocity boost that decays instead
func set_speed():
	if state == STATE.NORMAL: speed = SPEED_BASE
	elif state == STATE.SPRINTING: speed = SPEED_BASE * SPRINT_SPEED_MUL
	elif state == STATE.CROUCHED: speed = CROUCH_SPEED
	elif state == STATE.CROUCHED_RUN: speed = CROUCH_SPEED * SPRINT_SPEED_MUL

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x += event.relative.x * MOUSE_SENSITIVITY
		mouseInput.y += event.relative.y * MOUSE_SENSITIVITY
	# if event is Input.is_action_just_pressed()

func check_flags(field: int) -> Array:
	return []

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
