class_name StateWalk extends VirtualPlayerState 

var TOP_ANIM_SPEED: float = 2.2
const SPEED = 6.0
const ACCELLERATION = 50
const DECELERATION = 20.0

func _ready():
	super._ready()
	self.name = "PlayerStateWalk"

func enter():
	super.enter() # Call parent enter to ensure physics_values is initialized
	#ANIMATION.play("walk", -1.0, 1.0)
	# Set walk-specific physics values
	PLAYER.movement_values[PLAYER.MovementValues.SPEED] = SPEED
	PLAYER.movement_values[PLAYER.MovementValues.ACCELERATION] = ACCELLERATION
	PLAYER.movement_values[PLAYER.MovementValues.DECELERATION] = DECELERATION 
	pass
	
# func enter(previous_state_path: String, data := {}) -> void:
func update(_delta):
	# set_animation_speed(player_get_vector_length())
	# player.animation_player.play("idle")
	# print("Walking")
	if player_get_vector_length() == 0.0:
		transition.emit("PlayerStateIdle")

func set_animation_speed(speed):
	var alpha = remap(speed, 0.0, PLAYER.movement_values[PLAYER.MovementValues.SPEED], 0.0, 1.0)
	ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

func update_input(event):
	if event.is_action_pressed("vk_sprint"):
		transition.emit("PlayerStateSprint")
	if event.is_action_pressed("vk_jump"):
		transition.emit("PlayerStateJump")

func exit():
	print("anim_pause")
	# ANIMATION.pause()
