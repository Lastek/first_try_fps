class_name StateMachine extends Node

@export var CURRENT_STATE: State # Reference to state in action.
var available_states: Dictionary = {} # Holds all child states to state machine

## States must be created before they are able to be read in
## Make sure states are instanced before the state machine.
func _ready() -> void:
	# Every state gets a reference to the state machine
	print("AWAITING PLAYER.....")
	await Global.player
	print("Await done........")
	var init_state = get_children()[0].name
	for child in get_children():
		if child is State:
			available_states[child.name] = child
			child.transition.connect(on_transition)
		else:
			push_warning("Wrong node type in state machine {{available_states}}")
			
	CURRENT_STATE = available_states[init_state]
	CURRENT_STATE.enter()

func _process(delta: float):
	CURRENT_STATE.update(delta)
	Global.debug.add_property("FSM State", CURRENT_STATE.name, -1)

func _physics_process(delta: float):
	CURRENT_STATE.physics_update(delta)

func on_transition(new_state_name: String, _data := {}) -> void:
	var new_state = available_states.get(new_state_name)

	if new_state != null:
		if new_state != CURRENT_STATE:
			CURRENT_STATE.exit()
			new_state.enter()
			CURRENT_STATE = new_state
	else:
		push_warning("Attempting transition to non-existent state!")

#func _unhandled_input(event: InputEvent) -> void:
	#CURRENT_STATE.handle_input(event)
