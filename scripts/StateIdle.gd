class_name StateIdle

extends State

# func enter(previous_state_path: String, data := {}) -> void:
func update(delta):
	# player.animation_player.play("idle")
	# print("Lazy")
	if Global.player.velocity.length() > 0.0:
		transition.emit("PlayerStateWalk")
