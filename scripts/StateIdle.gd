class_name StateIdle
extends VirtualPlayerState 

func _ready():
	super._ready()
	self.name = "PlayerStateIdle"

# func enter(previous_state_path: String, data := {}) -> void:
func physics_update(_delta):
	# player.animation_player.play("idle")
	# print("Lazy")
	if Global.player.velocity.length() > 0.0 and Global.player.is_on_floor():
		transition.emit("PlayerStateWalk")
	
func update_input(event):
	if event.is_action_pressed("vk_jump"):
		transition.emit("PlayerStateJump")
	if event.is_action_pressed("vk_sprint"):
		transition.emit("PlayerStateSprint")
