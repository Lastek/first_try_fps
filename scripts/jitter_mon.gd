extends Panel

var value_history: Array = []
var max_history: int = 250
@onready var player = Global.player
var color_main: Color = Color.WHITE  # Default, though we'll override with conditional colors
var color_point: Color = Color.RED
var color_axis: Color = Color.GRAY  # For axis lines and labels
var default_font: Font
var thresh_invert: bool = false
# New configurable variables
var y_min: float = 0.0              # Minimum value for y-axis
var y_max: float = 100.0            # Maximum value for y-axis (default set for frame rate)
var threshold_low: float = 30.0     # Low threshold for color coding
var threshold_high: float = 60.0    # High threshold for color coding
var value_provider: Callable = func(delta): return 1.0 / delta  # Default to frame rate

func _ready():
	default_font = SystemFont.new()

func _process(delta: float) -> void:
	# Get the value from the provided callable
	var value: float = value_provider.call(delta)
	value_history.append({"value": value, "age": 0.0})
	if value_history.size() > max_history:
		value_history.remove_at(0)
	for entry in value_history:
		entry.age += delta
	queue_redraw()
	
func line_color(value) -> Color:
	if value < threshold_low:
		return Color.GREEN
	elif value >= threshold_low and value <= threshold_high:
		return Color.YELLOW
	else:  # current.value > threshold_high
		return Color.RED


func line_color_inv(value) -> Color:
	if value < threshold_low:
		return Color.RED
	elif value >= threshold_low and value <= threshold_high:
		return Color.YELLOW
	else:  # current.value > threshold_high
		return Color.GREEN

func _draw() -> void:
	var width: float = size.x
	var height: float = size.y
	var step_width: float = width / max_history

	# Draw the graph with conditional colors
	for i in range(value_history.size() - 1):
		var current = value_history[i]
		var next = value_history[i + 1]
		var x_current: float = i * step_width
		# Scale the value to the panel height based on y_min and y_max
		var scaled_current = (current.value - y_min) / (y_max - y_min)
		var y_current: float = height - (scaled_current * height)
		var x_next: float = (i + 1) * step_width
		var scaled_next = (next.value - y_min) / (y_max - y_min)
		var y_next: float = height - (scaled_next * height)

		# Determine color based on the actual value
		var line_color: Color
		# braindead way
		if(!thresh_invert):
			line_color = line_color(current.value)
		else:
			line_color = line_color_inv(current.value)
		# Draw stepped lines with the chosen color
		draw_line(Vector2(x_current, height), Vector2(x_current, y_current),
				  line_color, 2.0)
		draw_line(Vector2(x_next, y_current), Vector2(x_next, y_next),
				  line_color, 2.0)

	# Draw the last segment
	if value_history.size() > 0:
		var last = value_history[-1]
		var x_last: float = (value_history.size() - 1) * step_width
		var scaled_last = (last.value - y_min) / (y_max - y_min)
		var y_last: float = height - (scaled_last * height)

		# Determine color for the last segment
		var last_color: Color
		if last.value < threshold_low:
			last_color = Color.GREEN
		elif last.value >= threshold_low and last.value <= threshold_high:
			last_color = Color.YELLOW
		else:  # last.value > threshold_high
			last_color = Color.RED

		# Uncomment if you want the line to extend to the right edge
		# draw_line(Vector2(x_last, y_last), Vector2(width, y_last), last_color, 2.0)
		draw_circle(Vector2(x_last, y_last), 8.0, color_point)

	# Draw Y-axis markers based on y_min and y_max
	var y_levels = [y_min, (y_min + y_max) / 2.0, y_max]
	var y_axis_off = -20
	var x_axis_off = 40
	for level in y_levels:
		var scaled_level = (level - y_min) / (y_max - y_min)
		var y_pos = height - (scaled_level * height) + 10
		# Draw a faint horizontal line across the panel
		draw_line(Vector2(0, y_pos), Vector2(width, y_pos), color_axis, 1.0, true)
		# Draw label (formatted to 1 decimal place)
		var label = str(round(level * 10) / 10.0)
		draw_string(default_font, Vector2(5 - x_axis_off, y_pos - 5), label,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GREEN)

	# Draw X-axis markers (time based on physics tick rate)
	var physics_tick_rate = Engine.physics_ticks_per_second  # Default 60 Hz
	var tick_duration = 1.0 / physics_tick_rate  # ~0.01667 seconds
	var total_time = max_history * tick_duration  # ~4.17 seconds

	# Markers at 0 (right), half, and max (left)
	var x_times = [0.0, total_time / 2.0, total_time]
	for time in x_times:
		var x_pos = width - (time / total_time * width)  # Right-to-left mapping
		# Draw a faint vertical line
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, height), color_axis, 1.0, true)
		# Draw label (time in seconds, rounded to 1 decimal)
		var label = str(round(time * 10) / 10.0) + "s"
		draw_string(default_font, Vector2(x_pos + 5, height - 5), label,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLUE)
