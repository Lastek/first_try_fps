class_name StateWalk
extends State

var ANIMATION: AnimationPlayer
var TOP_ANIM_SPEED: float = 2.2

func _ready():
	self.name = "PlayerStateWalk"

func enter():
	# ANIMATION.play("walk", -1.0, 1.0)
	pass
	
# func enter(previous_state_path: String, data := {}) -> void:
func update(_delta):
	# set_animation_speed(Global.player.velocity.length())
	# player.animation_player.play("idle")
	# print("Walking")
	if Global.player.velocity.length() == 0.0:
		transition.emit("PlayerStateIdle")

func set_animation_speed(speed):
	var alpha = remap(speed, 0.0, Global.player.SPEED_BASE, 0.0, 1.0)
	ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

func exit():
	print("anim_pause")
	# ANIMATION.pause()
