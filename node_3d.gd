extends Node3D

func _input(event):
	if event.is_action_pressed("vk_exit"):
		get_tree().quit()

