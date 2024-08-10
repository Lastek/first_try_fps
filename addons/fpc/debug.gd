extends PanelContainer

@onready var property_container = $MarginContainer/VBoxContainer

#var property
var frames_per_second: String

func _ready():
	Global.debug = self
	visible = true

func _process(delta):
	pass
	#if visible:
		#pass
		#property.text = property.name+ ": " + frames_per_second

func _input(event):
	if event.is_action_pressed("vk_debug"):
		visible = !visible


func add_property(title :String, value, order):
	# @order 0 - n or -1 for append
	if order < 0: order = 999
	var target
	target = property_container.find_child(title, true, false)
	if !target:
		target = Label.new()
		property_container.add_child(target)
		target.name = title
		target.text = target.name + ": " + str(value)
	elif visible:
		target.text = title + ": " + str(value)
		#property_container.move_child(target, order)
	#property = Label.new()
	#property_container.add_child(property)
	#property.name = title
	#property.text = property.name + value		
