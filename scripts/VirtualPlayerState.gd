## This is a base state which should be extended when implementing a state
## Provides frequently used variables or common state utilities
class_name VirtualPlayerState
extends State

var PLAYER: Player
var ANIMATION: AnimationPlayer

# Override this method to set physics values for the current state

func enter() -> void:
	pass

func process(_delta: float) -> void:
	pass

func update_input(event) -> void:
	pass

func init_player_reference(player_ref: Player):
	self.PLAYER = player_ref

func player_get_vector_length():
	return PLAYER.physics_state[PLAYER.PHYS_STATE.VELOCITY].length()
