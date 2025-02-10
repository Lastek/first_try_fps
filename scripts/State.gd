## Virtual base class for all states.
## Extend this class and override its methods to implement a state.
class_name State extends Node

## Communication between state machine and states
signal transition(new_state_name: String)

## Entry into state
func enter() -> void:
	pass

## Per tick logic updates
func update(_delta: float) -> void:
	pass

## Per tick updates
func physics_update(_delta: float) -> void:
	pass

## perform cleanup
func exit() -> void:
	pass