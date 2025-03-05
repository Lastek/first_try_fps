class_name StateIdle
extends State

var ANIMATION: AnimationPlayer

func _ready():
	self.name = "PlayerStateIdle"

# func enter(previous_state_path: String, data := {}) -> void:
func update(_delta):
	# player.animation_player.play("idle")
	# print("Lazy")
	if Global.player.velocity.length() > 0.0 and Global.player.is_on_floor():
		transition.emit("PlayerStateWalk")
	
