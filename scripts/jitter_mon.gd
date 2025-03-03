extends Panel

var alpha_history: Array = []
var max_history: int = 100
var fadeout_period: float = 2.0
var time_since_reset: float = 0.0
var reset_interval: float = 5.0
@onready var player = Global.player

func _process(delta: float) -> void:
	time_since_reset += delta
	if time_since_reset >= reset_interval:
		alpha_history.clear()
		time_since_reset = 0.0
	
	var alpha: float = player.global_alpha  # Your alpha calculation here
	alpha_history.append({"alpha": alpha, "age": 0.0})
	if alpha_history.size() > max_history:
		alpha_history.remove_at(0)
	for entry in alpha_history:
		entry.age += delta
	queue_redraw()

func _draw() -> void:
	var width: float = size.x
	var height: float = size.y
	var step_width: float = width / max_history
	
	for i in range(alpha_history.size() - 1):
		var current = alpha_history[i]
		var next = alpha_history[i + 1]
		var x_current: float = i * step_width
		var y_current: float = height - (current.alpha * height)
		var x_next: float = (i + 1) * step_width
		var y_next: float = height - (next.alpha * height)
		var opacity: float = 1.0 - clamp(current.age / fadeout_period, 0.0, 1.0)
		
		draw_line(Vector2(x_current, y_current), Vector2(x_next, y_current),
				  Color(1, 1, 1, opacity), 2.0)
		draw_line(Vector2(x_next, y_current), Vector2(x_next, y_next),
				  Color(1, 1, 1, opacity), 2.0)
	
	if alpha_history.size() > 0:
		var last = alpha_history[-1]
		var x_last: float = (alpha_history.size() - 1) * step_width
		var y_last: float = height - (last.alpha * height)
		var opacity: float = 1.0 - clamp(last.age / fadeout_period, 0.0, 1.0)
		draw_line(Vector2(x_last, y_last), Vector2(width, y_last),
				  Color(1, 1, 1, opacity), 2.0)
		draw_circle(Vector2(x_last, y_last), 3.0, Color.RED)

func calculate_alpha() -> float:
	return randf()  # Replace with your actual alpha source
