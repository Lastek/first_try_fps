extends Node3D

func _input(event):
	if event.is_action_pressed("vk_exit"):
		get_tree().quit()
		
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("MouseMode: ", Input.mouse_mode)
		
	
