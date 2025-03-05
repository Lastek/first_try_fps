## This is a base state which should be extended when implementing a state
## Provides frequently used variables or common state utilities
class_name VirtualPlayerState
extends State

var PLAYER: Player
var ANIMATION: AnimationPlayer

func _ready() -> void:
	#await owner.ready
	PLAYER = owner as Player
	
func _process(_delta: float) -> void:
	pass
