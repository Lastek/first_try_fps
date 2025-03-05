class_name StateMachine extends Node

@export var CURRENT_STATE: State # Reference to state in action.
var available_states: Dictionary = {} # Holds all child states to state machine
var PLAYER: Player

## States must be created before they are able to be read in
## Make sure states are instanced before the state machine.

func _init(ref_player: Player):
	if ref_player != null:
		PLAYER = ref_player
	else:
		push_error("Must pass valid Player class reference to StateMachine when initializing with new()")
		

func _ready() -> void:
	# Every state gets a reference to the state machine
	var init_state = get_children()[0].name
	for child in get_children():
		if child is State:
			available_states[child.name] = child
			child.transition.connect(on_transition)
			child.init_player_reference(PLAYER)
		else:
			push_warning("Wrong node type in state machine {%s}" % available_states)
			
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
			print("DEBUG State Transition: {%s}" % new_state)
			CURRENT_STATE.exit()
			new_state.enter()
			CURRENT_STATE = new_state
	else:
		push_warning("Attempting transition to non-existent state!")

func _input(event):
	CURRENT_STATE.update_input(event)

#func _unhandled_input(event: InputEvent) -> void:
	#CURRENT_STATE.handle_input(event)
