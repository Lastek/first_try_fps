class_name StateSprint

extends State

var ANIMATION: AnimationPlayer
var TOP_ANIM_SPEED: float = 2.2

func _ready():
    pass

func enter():
    pass

func update(delta):
    pass

func set_animation_speed(speed):
    var alpha = remap(speed, 0.0, Global.player.SPEED_BASE, 0.0, 1.0)
    ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

func exit():
    pass