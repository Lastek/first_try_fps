# COPYRIGHT Colormatic Studios
# MIT licence
# Quality Godot First Person Controller v2

# Modified by Lastek
extends CharacterBody3D
# TODO: Add descriptions for each value
@export_category("Character")
@export var base_speed : float = 6.0
@export var sprint_speed_multiplier : float = 1.75
@export var crouch_speed : float = 4.0

@export var jump_mul : float = 1.8
@export var acceleration : float = 10.0
@export var jump_velocity : float = (3.5)

@export var mouse_sensitivity : float = 0.1
@export var immobile : bool = false
@export_file var default_reticle

@export_group("Nodes")
@export var HEAD : Node3D 
@export var CAMERA : Camera3D
@export var HEADBOB_ANIMATION : AnimationPlayer
@export var JUMP_ANIMATION : AnimationPlayer
@export var CROUCH_ANIMATION : AnimationPlayer
@export var COLLISION_MESH : CollisionShape3D
@export var CROUCH_CEILING_DETECTION : Node3D

#TODO: Remove this export group and replace it with an enum and array that is generated from the ACTIONS dict.
#	This should simplify alot of the code that needs to access the information 
#	and then make loadin/saving much easier too.
@export_group("Controls")
@export var JUMP : String = "vk_jump"
@export var LEFT : String = "vk_left"
@export var RIGHT : String = "vk_right"
@export var FORWARD : String = "vk_forward"
@export var BACKWARD : String = "vk_backward"
@export var PAUSE : String = "vk_pause"
@export var CROUCH : String = "vk_crouch"
@export var SPRINT : String = "vk_sprint"


var ACTIONS: Dictionary = {
JUMP : "vk_jump",
LEFT : "vk_left",
RIGHT : "vk_right",
FORWARD : "vk_forward",
BACKWARD : "vk_backward",
PAUSE : "vk_pause",
CROUCH : "vk_crouch",
SPRINT : "vk_sprint"
}
#var ACTIONS = [JUMP, LEFT, RIGHT, FORWARD, BACKWARD, PAUSE, CROUCH, SPRINT]
# Uncomment if you want full controller support
#@export var LOOK_LEFT : String = "look_left"
#@export var LOOK_RIGHT : String = "look_right"
#@export var LOOK_UP : String = "look_up"
#@export var LOOK_DOWN : String = "look_down"

@export_group("Feature Settings")
@export var jumping_enabled : bool = true
@export var in_air_momentum : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = true
@export var crouch_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode: int = 0
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = true
@export var view_bobbing : bool = true
@export var jump_animation : bool = true
@export var pausing_enabled : bool = true
@export var gravity_enabled : bool = true

# Member variables
var speed : float = base_speed
var current_speed : float = 0.0
# States: normal, crouched, sprinting, crouch sprinting
enum STATE {NORMAL, CROUCH, SPRINT, CH_SPRINT}
var state : int = STATE.NORMAL
var low_ceiling : bool = false # This is for when the cieling is too low and the player needs to crouch.
var was_on_floor : bool = true # Was the player on the floor last frame (for landing animation)
var is_crouched : bool = false
var ANIM_CROUCH_SPEED :float = 3.0
# The reticle should always have a Control node as the root
var RETICLE : Control

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process

# Stores mouse input for rotating the camera in the phyhsics process
var mouseInput : Vector2 = Vector2(0,0)

func _ready():
	print("_ready called")
	#It is safe to comment this line if your game doesn't start with the mouse captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#JUMP = Input.new()
	#JUMP.action = "space"
	#JUMP.pressed = true
	CROUCH_CEILING_DETECTION.add_exception($".")
	
	var ck = InputMap.has_action(FORWARD)
	print(ck)
	
	print(InputMap.get_signal_list())
	# If the controller is rotated in a certain direction for game design purposes, redirect this rotation into the head.
	HEAD.rotation.y = rotation.y
	rotation.y = 0
	
	if default_reticle:
		change_reticle(default_reticle)
	
	# Reset the camera position
	# If you want to change the default head height, change these animations.
	HEADBOB_ANIMATION.play("RESET")
	JUMP_ANIMATION.play("RESET")
	CROUCH_ANIMATION.play("RESET")
	
	check_controls()
	
#func bind_keys():
	##for i in 
	#InputMap.add_action(JUMP)
	#var e = InputEventKey.new()
	#e.keycode = 66
	#InputMap.action_add_event(JUMP, e)
	#print("Physical label")
	#print(e.get_physical_keycode_with_modifiers())
	
func change_reticle(reticle): # Yup, this function is kinda strange
	if RETICLE:
		RETICLE.queue_free()
	
	RETICLE = load(reticle).instantiate()
	RETICLE.character = self
	$UserInterface.add_child(RETICLE)

func _physics_process(delta):
	# Big thanks to github.com/LorenzoAncora for the concept of the improved debug values
	current_speed = Vector3.ZERO.distance_to(get_real_velocity())
	$UserInterface/DebugPanel.add_property("Speed", snappedf(current_speed, 0.001), 1)
	$UserInterface/DebugPanel.add_property("Target speed", speed, 2)
	var cv : Vector3 = get_real_velocity()
	var vd : Array[float] = [
		snappedf(cv.x, 0.001),
		snappedf(cv.y, 0.001),
		snappedf(cv.z, 0.001)
	]
	#TODO: Move these out of the physics processing and into the idle func
	var readable_velocity : String = "X: " + str(vd[0]) + " Y: " + str(vd[1]) + " Z: " + str(vd[2])
	$UserInterface/DebugPanel.add_property("Velocity", readable_velocity, 3)
	
	# Gravity
	if not is_on_floor() and gravity and gravity_enabled:
		velocity.y -= gravity * jump_mul * delta
	
	handle_jumping()
	
	var input_dir = Vector2.ZERO
	input_dir = Input.get_vector(LEFT, RIGHT, FORWARD, BACKWARD)
	var vectoring : String = "X: " + str(vd[0]) + " Y: " + str(vd[1]) + " Z: " + str(vd[2])
	$UserInterface/DebugPanel.add_property("Vector", vectoring, 3)
	
	handle_movement(delta, input_dir)
	handle_head_rotation()
	
	 #The player is not able to stand up if the ceiling is too low
	#low_ceiling = $CrouchCeilingDetection.is_colliding()
	
	handle_state(input_dir)
	if dynamic_fov: # This may be changed to an AnimationPlayer
		update_camera_fov()
	
	if view_bobbing:
		headbob_animation(input_dir)
	
	if jump_animation:
		if !was_on_floor and is_on_floor(): # The player just landed
			match randi() % 2: #TODO: Change this to detecting velocity direction
				0:
					JUMP_ANIMATION.play("land_left", 1.5)
				1:
					JUMP_ANIMATION.play("land_right", 1.5)
	
	was_on_floor = is_on_floor() # This must always be at the end of physics_process
	

		
func handle_jumping():
	if continuous_jumping: # Hold down the jump button
		if Input.is_action_pressed(JUMP) and is_on_floor() and !low_ceiling:
			if jump_animation:
				JUMP_ANIMATION.play("jump", 1.5)
			velocity.y += jump_velocity # Adding instead of setting so jumping on slopes works properly
	else:
		if Input.is_action_just_pressed(JUMP) and is_on_floor() and !low_ceiling:
			if jump_animation:
				JUMP_ANIMATION.play("jump", 0.25)
			velocity.y += jump_velocity

func handle_movement(delta, input_dir):
	var direction = input_dir.rotated(-HEAD.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	move_and_slide()
	
	if in_air_momentum:
		if is_on_floor():
			if motion_smoothing:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
			else:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
	else:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

func handle_head_rotation():
	HEAD.rotation_degrees.y -= mouseInput.x * mouse_sensitivity
	HEAD.rotation_degrees.x -= mouseInput.y * mouse_sensitivity
	
	# Uncomment for controller support
	#var controller_view_rotation = Input.get_vector(LOOK_DOWN, LOOK_UP, LOOK_RIGHT, LOOK_LEFT) * 0.035 # These are inverted because of the nature of 3D rotation.
	#HEAD.rotation.x += controller_view_rotation.x
	#HEAD.rotation.y += controller_view_rotation.y
	mouseInput = Vector2(0,0)
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _handle_state(moving):
	pass

func handle_state(moving):
	if sprint_enabled:
		if sprint_mode == 0:
			if Input.is_action_pressed(SPRINT) and state != STATE.CROUCH :
				if moving:
					if state != STATE.SPRINT:
						enter_sprint_state()
				else:
					if state == STATE.SPRINT:
						enter_normal_state()
			elif state == STATE.SPRINT:
				enter_normal_state()
		elif sprint_mode == 1:
			if moving:
				# If the player is holding sprint before moving, handle that cenerio
				if Input.is_action_pressed(SPRINT) and state == STATE.NORMAL: 
					enter_sprint_state()
				#if Input.is_action_pressed(SPRINT) and state == STATE.CROUCH:
					#
				if Input.is_action_just_pressed(SPRINT):
					match state:
						STATE.NORMAL:
							enter_sprint_state()
						STATE.SPRINT:
							enter_normal_state()
			elif state == STATE.SPRINT :
				enter_normal_state()
	
	#if crouch_enabled:
		#if crouch_mode == 0:
			#if Input.is_action_pressed(CROUCH) and state != "sprinting":
				#if state != "crouching":
					#enter_crouch_state()
			#elif state == "crouching" and !$CrouchCeilingDetection.is_colliding():
				#enter_normal_state()
		#elif crouch_mode == 1:
			#if Input.is_action_just_pressed(CROUCH):
				#match state:
					#"normal":
						#enter_crouch_state()
					#"crouching":
						#if !$CrouchCeilingDetection.is_colliding():
							#enter_normal_state()
						
# Any enter state function should only be called once when you want to enter that state, not every frame.
func enter_normal_state():
	#print("entering normal state")
	var prev_state = state
	#if prev_state == STATE.CROUCH:
		#CROUCH_ANIMATION.play_backwards("crouch")
	state = STATE.NORMAL
	speed = base_speed

	state = STATE.CROUCH
	speed = crouch_speed
	CROUCH_ANIMATION.play("crouch")

func enter_sprint_state():
	#print("entering sprint state")
	var prev_state = state
	if prev_state == STATE.CROUCH:
		speed *= sprint_speed_multiplier
		#CROUCH_ANIMATION.play_backwards("crouch")
	else:	
		state = STATE.SPRINT
		speed *= sprint_speed_multiplier

func update_camera_fov():
	if state == STATE.SPRINT:
		CAMERA.fov = lerp(CAMERA.fov, 85.0, 0.3)
	else:
		CAMERA.fov = lerp(CAMERA.fov, 75.0, 0.3)

func headbob_animation(moving):
	if moving and is_on_floor():
		var use_headbob_animation : String

		match state:
			STATE.NORMAL, STATE.CROUCH:
				use_headbob_animation = "walk"
			STATE.SPRINT:
				use_headbob_animation = "sprint"
		
		var was_playing : bool = false
		if HEADBOB_ANIMATION.current_animation == use_headbob_animation:
			was_playing = true
		
		HEADBOB_ANIMATION.play(use_headbob_animation, 0.25)
		HEADBOB_ANIMATION.speed_scale = (current_speed / base_speed) * 1.75
		if !was_playing:
			HEADBOB_ANIMATION.seek(float(randi() % 2)) # Randomize the initial headbob direction
			# Let me explain that piece of code because it looks like it does the opposite of what it actually does.
			# The headbob animation has two starting positions. One is at 0 and the other is at 1.
			# randi() % 2 returns either 0 or 1, and so the animation randomly starts at one of the starting positions.
			# This code is extremely performant but it makes no sense.
		
	else:
		if HEADBOB_ANIMATION.current_animation == "sprint" or HEADBOB_ANIMATION.current_animation == "walk":
			HEADBOB_ANIMATION.speed_scale = 1
			HEADBOB_ANIMATION.play("RESET", 1)

func _process(delta):
	$UserInterface/DebugPanel.add_property("FPS", Performance.get_monitor(Performance.TIME_FPS), 0)
	var status : String = STATE.find_key(state)
	# if !is_on_floor():
	# 	status += " in the air"
	# 	print("in air")
	$UserInterface/DebugPanel.add_property("State", status, 4)
	
	if pausing_enabled:
		if Input.is_action_just_pressed(PAUSE):
			match Input.mouse_mode:
				Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event.is_action_pressed(CROUCH) and crouch_mode == 1 and is_on_floor() :
		toggle_crouch()
	elif event.is_action_pressed(CROUCH) and is_crouched== false and is_on_floor() and crouch_mode == 0:
		crouch(true)
	if event.is_action_released(CROUCH) and crouch_mode == 0:
		crouch(false)

func _unhandled_input(event):
	#pass
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouseInput.x += event.relative.x
		mouseInput.y += event.relative.y

func toggle_crouch():
	if !is_crouched: # are we crouched already?
		crouch(true)
	elif is_crouched and !CROUCH_CEILING_DETECTION.is_colliding(): # are we trying to uncrouch and there is nothing blocking above? 
		crouch(false)

func crouch(crouching:bool):
	CROUCH_ANIMATION.stop()
	match crouching:
		true:
			speed = crouch_speed
			CROUCH_ANIMATION.play("crouch", -1, ANIM_CROUCH_SPEED)
		false:
			if(CROUCH_CEILING_DETECTION.is_colliding() == true):
				await get_tree().create_timer(0.1).timeout
				crouch(false)
			else: 
				speed = base_speed
				CROUCH_ANIMATION.play("crouch", -1, -ANIM_CROUCH_SPEED, true)

func _on_crouch_animation_animation_started(anim_name):
	print("playing crouch anim")
	if anim_name == "crouch":
		is_crouched = !is_crouched
		

func check_controls(): 
	for i in ACTIONS:
		var k = ACTIONS.find_key(i)
		if !InputMap.has_action(i):
			push_error("No action mapped to ", k)
			print("No action mapped to ", k)
		else:			
			var v = InputMap.action_get_events(i)
			if v.is_empty():
				push_error("No key mapped to the following action: ", k)
				print("No key mapped to the following action: ", k)
