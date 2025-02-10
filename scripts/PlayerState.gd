class_name PlayerState extends State

enum {
	JUMP = 0,
	LEFT,
	RIGHT,
	FORWARD,
	BACKWARD,
	CROUCH,
	SPRINT,
	PAUSE
}

var player: Character

func _ready() -> void:
    await owner.ready
    player = owner as Character
    assert(player != null, "PlayerState state type must only be used in the character scene. Owner must be a Character node.")

