
class_name StateWalk 

extends State

# func enter(previous_state_path: String, data := {}) -> void:
func update(_delta):
    # player.animation_player.play("idle")
    # print("Walking")
    if Global.player.velocity.length() == 0.0:
        transition.emit("PlayerStateIdle")