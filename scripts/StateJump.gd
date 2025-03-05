class_name StateJump extends VirtualPlayerState 

var TOP_ANIM_SPEED: float = 2.2
const JUMP_VELOCITY = PLAYER.JUMP_VELOCITY
const JUMP_MUL = PLAYER.JUMP_MUL
const ACCEL_AIR = PLAYER.AIR_ACCELERATION
const DECEL_AIR = PLAYER.AIR_DECELERATION

func _ready():
	super._ready()
	self.name = "PlayerStateJump"


func enter():
	super.enter() # Call parent enter to ensure physics_values is initialized
	ANIMATION.play("jump", -1.0, 1.0)
	# Apply upward impulse
	PLAYER.movement_values[PLAYER.MovementValues.JUMP_VELOCITY] = JUMP_VELOCITY
	PLAYER.movement_values[PLAYER.MovementValues.JUMP_MUL] = JUMP_MUL
	PLAYER.jump_impulse()


func physics_update(delta):
	if player_get_vector_length() == 0.0:
		transition.emit("PlayerStateIdle")
	elif PLAYER.is_on_floor():
		if Input.is_action_pressed("vk_sprint"):
			transition.emit("PlayerStateSprint")
		else:
			transition.emit("PlayerStateWalk")

func update_input(event):
	if event.is_action_pressed("vk_sprint"):
		transition.emit("PlayerStateSprint")

func set_animation_speed(speed):
	var alpha = remap(speed, 0.0, 1.0, 0.0, 1.0)
	ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

func exit():
	print("anim_pause")
	ANIMATION.reset_section()
