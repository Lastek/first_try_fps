# Author: Lastek
# FP controller
# MIT License
# Thanks to StayAtHomeDev for his YouTube tutorials
class_name Player extends CharacterBody3D 

## Player Node References
var PL_HEAD: Node3D
var PL_CAMERA: Camera3D
var PL_MESH: MeshInstance3D
var PL_COLLISION_MESH: CollisionShape3D
var PL_CROUCH_CEILING_DETECTION: Node3D
var PL_VISUAL: Node3D
var AN_HEADBOB_EFFECT: AnimationPlayer
var AN_JUMP_EFFECT: AnimationPlayer
#var AN_CROUCH_EFFECT: AnimationPlayer
#var AN_CROUCH_EFFECT_SPEED: float = 3.0
var AN_JUMP_EFFECT_AMOUNT: float = 1.0
var AN_HEADBOB_EFFECT_AMOUNT: float = 1.0
var AN_ENABLED: bool = true

## Player Movement Constants
const MOUSE_SENSITIVITY = 0.1

const WALK_SPEED = 6.0
const SPRINT_SPEED_MUL = 1.75
const ACCELERATION = 40
const AIR_ACCELERATION = 1.4
const DECELERATION = 30.0
const AIR_DECELERATION= 0.2
const CROUCH_SPEED = 1.0
const JUMP_VELOCITY = 3.5
const JUMP_MUL = 1.8
const GROUND_FRICTION = 0.8

## Player Movement Indexing enum
enum MV {
	SPEED,
	ACCELERATION,
	DECELERATION,
	GROUND_FRICTION,
	AIR_ACCELERATION,
	AIR_DECELERATION,
	JUMP_VELOCITY,
	JUMP_MUL,
	CROUCH_SPEED,
	SIZE
}

## Player Movement Array
var mv:Array

## Player Input Vectors 

# Stores mouse input for rotating the camera in the physics process
var mouseInput: Vector2 = Vector2(0, 0)
var input_dir: Vector2
var input_dir_prev: Vector2
var direction: Vector3
var rotVel: Vector2

## Misc
# var low_ceiling: bool = false
# var was_on_floor: bool = false
var dir_lerp: Vector2 = Vector2(0.0, 0.0)
var f_transform: Vector3 = Vector3(0.0, 0.0, 0.0)
var head_rot:Vector2 = Vector2()
# Get the gravity from the project settings to be synced with RigidBody nodes.
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

## Player Input Actions Indexing Enum
# this is problematic because this is not restricted to ACTIONS
enum {
	JUMP = 0,
	LEFT,
	RIGHT,
	FORWARD,
	BACKWARD,
	CROUCH,
	SPRINT,
	PAUSE,
	RENDER_FPS_DECREMENT,
	RENDER_FPS_INCREMENT,
}

## Player Input Actions
var ACTIONS: Dictionary = {
	JUMP: "vk_jump",
	LEFT: "vk_left",
	RIGHT: "vk_right",
	FORWARD: "vk_forward",
	BACKWARD: "vk_backward",
	PAUSE: "vk_pause",
	CROUCH: "vk_crouch",
	SPRINT: "vk_sprint",
	RENDER_FPS_DECREMENT: "vk_bracket_right",
	RENDER_FPS_INCREMENT: "vk_bracket_left"
}

## FSM
var FSM: StateMachine
var PlayerStateIdle: State
var PlayerStateWalk: State
var PlayerStateSprint: State
var PlayerStateJump: State

## Utility stuff
var frames = 0
var frames_dt_accumulator = 0.0
var dt = 1.0/Engine.physics_ticks_per_second
var physics_time = 0.0
var current_time = 0.0


enum PS {
	POSITION,
	VELOCITY,
	ROTATION,
	TIME,
	SIZE
}

# Fixed-size arrays for physics states
var ps: Array = []
var prev_ps: Array = []

## Monitoring and Graphing related variables
@onready var jittermon
var tracker = 0
var spin: int = 0
var global_alpha: float
var max_alpha: float = 0
var accumulator = 0.0

func init_jittermon():
	jittermon = get_tree().get_root().get_node("MainTestScene/CanvasLayer/JitterMon")
	if jittermon == null: return
	jittermon.y_min = 0.0
	jittermon.y_max = 400
	jittermon.threshold_low = 100 # Below 30 FPS is GREEN (indicating a warning if low is bad)
	jittermon.threshold_high = 240  # Above 60 FPS is RED (or adjust logic if desired)
	jittermon.value_provider = func(delta): return 1.0 / delta
	jittermon.thresh_invert = true	


func _ready():
	call_deferred("init_jittermon")

	ready_node_references()
	ready_state_machine()
	ready_physics_state()
	ready_animation()
	ready_player_movement()

	controls_mapping_check()


func ready_node_references():
	print("Player _ready():")
	Global.player = self # provides reference to player
	print("Init FSM")
	print("Get Player Node references")
	PL_HEAD = get_node("VisualPlayer/Head")
	PL_CAMERA = get_node("VisualPlayer/Head/Camera")
	PL_MESH = get_node("VisualPlayer/Mesh")
	PL_COLLISION_MESH = get_node("Collision")
	PL_CROUCH_CEILING_DETECTION = get_node("CrouchCeilingDetection")
	PL_VISUAL = get_node("VisualPlayer")
	AN_HEADBOB_EFFECT = get_node("VisualPlayer/Head/HeadbobAnimation")
	AN_JUMP_EFFECT = get_node("VisualPlayer/Head/JumpAnimation")
	#AN_CROUCH_EFFECT = get_node("VisualPlayer/Head/CrouchAnimation")
	PL_CROUCH_CEILING_DETECTION.add_exception($".")
	print("PL_VISUAL: ", PL_VISUAL)
	print("set up inputs")
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # This has been relocated to the main scene script
	print("End Player _ready()")

func ready_physics_state():
	# Initialize arrays with correct size
	ps.resize(PS.SIZE)
	prev_ps.resize(PS.SIZE)

	# Initialize default values
	current_time = Time.get_ticks_usec() / 1000000.0
	physics_time = Time.get_ticks_usec() / 1000000.0 +0.01
	ps[PS.POSITION] = position
	ps[PS.VELOCITY] = velocity
	ps[PS.ROTATION] = PL_HEAD.rotation
	ps[PS.TIME] = physics_time
	prev_ps = ps.duplicate()

func ready_state_machine():
	print("Instantiating FSM")
	FSM = StateMachine.new(self)

	PlayerStateIdle = StateIdle.new()
	PlayerStateWalk = StateWalk.new()
	PlayerStateSprint = StateSprint.new()
	PlayerStateJump = StateJump.new()

	## Prepare animations:
	PlayerStateWalk.ANIMATION = AN_HEADBOB_EFFECT
	PlayerStateSprint.ANIMATION = AN_HEADBOB_EFFECT
	PlayerStateJump.ANIMATION = AN_JUMP_EFFECT 

	FSM.add_child(PlayerStateIdle)
	FSM.add_child(PlayerStateWalk)
	FSM.add_child(PlayerStateSprint)
	FSM.add_child(PlayerStateJump)

	print("Adding FSM as child to Player")
	add_child(FSM) # Add FSM as child after assigning states to kick off _ready()
	print("FSM Child Added")


## Some housekeeping to make sure anims start correctly
func ready_animation():
	AN_HEADBOB_EFFECT.play("RESET")

func ready_player_movement():
	mv.resize(MV.SIZE)
	mv[MV.SPEED] = WALK_SPEED
	mv[MV.ACCELERATION] = ACCELERATION
	mv[MV.DECELERATION] = DECELERATION
	mv[MV.GROUND_FRICTION] = GROUND_FRICTION
	mv[MV.AIR_ACCELERATION] = AIR_ACCELERATION 
	mv[MV.AIR_DECELERATION] = AIR_DECELERATION 
	mv[MV.JUMP_VELOCITY] = JUMP_VELOCITY
	mv[MV.JUMP_MUL] = JUMP_MUL
	mv[MV.CROUCH_SPEED] = CROUCH_SPEED

func _physics_process(delta: float) -> void:
	prev_ps = ps.duplicate()
	# Handle input and physics
	input_to_vec(delta)
	integrate_physics(delta)
	physics_save_state(delta)
	var y_off = 1.32
	var place = (Vector3(0,y_off,0) )
	var vel = velocity.normalized()
	vel = Vector3(vel.x, 0, vel.z)
	DebugDraw3D.draw_arrow(ps[PS.POSITION].origin+(place),
					(place+(vel))+ps[PS.POSITION].origin,
					Color.GREEN, .06, true)
	Global.debug.add_property("Phys", dt, 0)
	Global.debug.add_property("Physics Position", global_position, 1)
	Global.debug.add_property("Physics Velocity", velocity, 2)
	
## Call after integrate_physics
func physics_save_state(_delta:float) -> void:
	physics_time = Time.get_ticks_usec() / 1_000_000.0
	ps[PS.POSITION] = global_transform  # Use global_position for consistency
	ps[PS.VELOCITY] = velocity			# Player velocity after applying changes
	ps[PS.ROTATION] = head_rot  # Head rotation from mouse input
	ps[PS.TIME] = physics_time
	

func integrate_physics(delta:float) -> void:
	# Get physics values from current state
	var speed = mv[MV.SPEED]
	var accel = mv[MV.ACCELERATION]
	var decel = mv[MV.DECELERATION]
	var frict = mv[MV.GROUND_FRICTION]
	var air_accel = mv[MV.AIR_ACCELERATION]
	var air_decel = mv[MV.AIR_DECELERATION]
	
	if !is_on_floor():
		velocity.y -= GRAVITY * delta * JUMP_MUL
		accel = air_accel
		decel = air_decel
 	# give speed in facing direction with acceleration (faking friction)
 	# how to do rampup for input vector to allow small taps. Taps vs Holding
	if direction:
		# velocity.z = velocity.z+(direction.z*speed - velocity.z)*delta*accel
		# velocity.x = velocity.x+(direction.x*speed - velocity.x)*delta*accel
		velocity.x = move_toward(velocity.x, direction.x*speed, delta*accel)
		velocity.z = move_toward(velocity.z, direction.z*speed, delta*accel)
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta*decel)
		velocity.z = move_toward(velocity.z, 0.0, delta*decel)

	if is_on_floor():
		var spd = velocity.length()
		if spd > 0:
			velocity -= velocity.normalized() * min(frict * delta, spd)

	move_and_slide()
	Global.debug.add_property("speed", speed, -1)
	
func jump_impulse():
	velocity.y += mv[MV.JUMP_VELOCITY] \
					* mv[MV.JUMP_MUL]

func _process(delta: float) -> void:
	frames += 1
	frames_dt_accumulator += delta
	
	# Calculate interpolation factor (alpha)
	var alpha = Engine.get_physics_interpolation_fraction()
	alpha = clampf(alpha, 0.0, 1.0)
	global_alpha = alpha
	#var prev_ps = prev_ps[PS.POSITION]
	var cur_ps = ps[PS.POSITION]
	# Interpolate position
	#var interpolated_pos:Transform3D = prev_ps[PS.POSITION] * alpha \
							#+ ps[PS.POSITION] \
							#*(1.0 - alpha)	
	var lerp_pos:Transform3D = prev_ps[PS.POSITION].interpolate_with(cur_ps, alpha)
		#var interpolated_pos:Vector3 = lerp(prev_ps[PS.POSITION], ps[PS.POSITION], alpha)
	# Interpolate head rotation
	var prev_rot = prev_ps[PS.ROTATION]
	var curr_rot = ps[PS.ROTATION]
	#PL_VISUAL.prev_rot.slerp(curr_rot, alpha)
	head_rotation()
	rotVel = head_rot
	var off = 1.5
	
	DebugDraw3D.draw_arrow(lerp_pos.origin+(Vector3(0,off,0)), Vector3(0,off,0)+(lerp_pos*Vector3(0,0,-1)), Color.PURPLE, .1, true)
	
	## Interpolate player camera position
	PL_VISUAL.global_transform.origin  = lerp_pos.origin
	
	#DebugDraw3D.draw_arrow(global_position+(Vector3(0,off,0)), Vector3(0,off,0)+(global_position*Vector3(0,0,-1)), Color.PURPLE, .1, true)
	#DebugDraw3D.draw_arrow(interpolated_pos+(Vector3(0,off,0)), Vector3(0,off,0)+(interpolated_pos*Vector3(-1,0,1)), Color.PURPLE, .1, true)
	# Apply to VisualPlayer
	 #PL_VISUAL.position = interpolated_pos
	# PL_MESH.rotation = interpolated_rot
	
	update_debug_info()
	#PL_CAMERA.global_position = interpolated_pos
	Global.debug.add_property("Render Position", PL_VISUAL.global_position, 3)
	
func update_mesh_rotation(angle, delta:float)->void:
	PL_MESH.rotate(Vector3(0,1,0), angle)

# Move debug info to separate function:
func update_debug_info() -> void:
	if frames >= 250:
		Global.debug.add_property("FPS", frames/frames_dt_accumulator, 0)
		frames_dt_accumulator = 0
		frames = 0
	if global_alpha>max_alpha:
		max_alpha = global_alpha
		
	Global.debug.add_property("input vector", input_dir, -1)
	Global.debug.add_property("direction vec", direction, -1)
	Global.debug.add_property("PL_HEAD", PL_HEAD.rotation, -1)
	Global.debug.add_property("Velocity", velocity, -1)
	Global.debug.add_property("Alpha", global_alpha, -1)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x -= event.relative.y * MOUSE_SENSITIVITY
		mouseInput.y -= event.relative.x * MOUSE_SENSITIVITY
		head_rot += mouseInput
		mouseInput = Vector2.ZERO
	if event and event != InputEventMouseMotion:
		pass
	if event.is_action_pressed(ACTIONS[RENDER_FPS_INCREMENT]):
		spin+=1
	if event.is_action_pressed(ACTIONS[RENDER_FPS_DECREMENT]):
		if spin > 0:
			spin -= 1

	Global.debug.add_property("spin", spin, -1)

## Will handle mouse input and generate a Vector3 `direction` based on movement actions
func input_to_vec(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	input_dir = Input.get_vector(ACTIONS[LEFT], ACTIONS[RIGHT], ACTIONS[FORWARD], ACTIONS[BACKWARD])
	Global.debug.add_property("input vector", input_dir, -1)
	
	head_rotation()
	rotVel = head_rot

	Global.debug.add_property("Rotation Degrees", rotVel,-1)
	Global.debug.add_property("Rot Q", PL_HEAD.quaternion ,-1)
	var vec2: Vector2 = input_dir.rotated(deg_to_rad(-PL_HEAD.rotation_degrees.y))
	direction = Vector3(vec2.x, 0, vec2.y)
	#Global.debug.add_property("PL_HEAD_ROTD",0, -1)
	Global.debug.add_property("input rotated vec", direction, -1)

## Rotate head in degrees. Clamp pitch [-90, 90]
func head_rotation():
	head_rot.x = clamp(head_rot.x, -90, 90)
	PL_HEAD.rotation_degrees.x = head_rot.x
	PL_HEAD.rotation_degrees.y = head_rot.y 


## Just to see what starts first and when things execute
func f_tracker(s:String)-> void:
	if tracker > 10 and tracker < 100:
		tracker += 1
		print("Tracker in %s: " %  s,tracker)
	else: tracker +=1


func _unhandled_input(_event):
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
