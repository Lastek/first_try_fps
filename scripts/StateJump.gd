class_name StateJump extends VirtualPlayerState 

var TOP_ANIM_SPEED: float = 2.2
const JUMP_VELOCITY = 3.5
const JUMP_MUL = 1.8
const ACCEL_AIR = 3 
const DECEL_AIR = 8 

func _ready():
	super._ready()
	self.name = "PlayerStateJump"

func enter():
	ANIMATION.play("jump", -1.0, 1.0)
	# Apply upward impulse
	PLAYER.jump_impulse(JUMP_VELOCITY, JUMP_MUL)

func physics_update(delta):
	if Global.player.velocity.length() == 0.0:
		transition.emit("PlayerStateIdle")
	elif Global.player.is_on_floor():
		transition.emit("PlayerStateWalk")

func set_animation_speed(speed):
	var alpha = remap(speed, 0.0, Global.player.SPEED_BASE, 0.0, 1.0)
	ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

func exit():
	print("anim_pause")
	ANIMATION.reset_section()
