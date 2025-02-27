## virtual base class for all states.
## extend this class and override its methods to implement a state.
class_name State extends Node

## communication between state machine and states; Callback to StateMachine
signal transition(new_state_name: String)

## entry into state; Called by StateMachine
func enter() -> void:
	pass

## per tick logic updates; Called by StateMachine
func update(_delta: float) -> void:
	pass

## Per tick updates; Called by StateMachine
func physics_update(_delta: float) -> void:
	pass

## perform cleanup; Called by StateMachine
func exit() -> void:
	pass