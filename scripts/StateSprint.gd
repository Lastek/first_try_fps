class_name StateSprint extends VirtualPlayerState 

var TOP_ANIM_SPEED: float = 2.2
var SPEED = PLAYER.SPRINT
var SPRINT_SPEED_MUL = PLAYER.SPRINT_SPEED_MUL
func _ready():
	super._ready()
	self.name = "PlayerStateSprint"

func enter():
	PLAYER.mv[PLAYER.MV.SPEED] = SPEED * SPRINT_SPEED_MUL 

func update(_delta):
	pass

func set_animation_speed(speed):
	var alpha = remap(speed, 0.0, PLAYER.mv[PLAYER.MV.SPEED], 0.0, 1.0)
	#ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

func update_input(event) -> void:
	if event.is_action_released("vk_sprint"):
		transition.emit("PlayerStateWalk")
	if event.is_action_pressed("vk_jump"):
		transition.emit("PlayerStateJump")

func exit():
	pass
