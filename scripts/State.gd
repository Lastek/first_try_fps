## interface class for all states.
## Extend this to a virtual base class which should serve as your base for all other states.
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
