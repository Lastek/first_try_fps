extends Node

## Global reference to debug script `debug.gd`
var debug # reference to debug script
## Global reference to the player for FSM player states
var player

# hacky but need to grab input focus on start
func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#print("window_is_focused: ", DisplayServer.window_is_focused())
	# get_tree().get_root().get_window().set_visible(true)
	# var window_id = get_tree().get_root().get_window_id()
	# print("window_id: ", window_id)
	# DisplayServer.window_move_to_foreground(window_id)
	pass
	
