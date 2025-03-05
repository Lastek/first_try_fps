extends Panel

# Configuration for the Lissajous curve
var A: float = 50.0  # Amplitude for x
var B: float = 50.0  # Amplitude for y
var a: float = 3.0   # Base frequency for x (modified by input)
var b: float = 4.0   # Frequency for y
var dt: float = PI / 2  # Phase shift
var speed: float = 1.0  # Speed of the parameter t

# Tail effect
var tail_length: int = 200  # Number of points in the tail
var fadeout_period: float = 3.0  # Seconds for points to fade out

# Internal variables
var t: float = 0.0
var points: Array = []  # Stores {position: Vector2, age: float}

# Example input value (replace this with your actual input source)
@onready var input_value: float = Global.player.global_alpha  # This could come from elsewhere in your game

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	t += delta * speed
	
	# Use the input value to modify the frequency 'a'
	var modified_a = a + input_value  # Adjust this based on your input's range
	var x = A * sin(modified_a * t + dt)
	var y = B * sin(b * t)
	
	# Center the curve in the panel
	var center = size / 2
	var position = center + Vector2(x, y)
	
	# Add new point with age 0
	points.append({"position": position, "age": 0.0})
	
	# Remove oldest point if exceeding tail length
	if points.size() > tail_length:
		points.remove_at(0)
	
	# Age all points
	for point in points:
		point.age += delta
	
	queue_redraw()

func _draw() -> void:
	# Draw points with fading opacity
	for i in range(points.size()):
		var point = points[i]
		var opacity = 1.0 - clamp(point.age / fadeout_period, 0.0, 1.0)
		var color = Color(1, 1, 1, opacity)
		draw_circle(point.position, 2.0, color)
	
	# Optionally, connect points with lines
	for i in range(1, points.size()):
		var prev = points[i - 1]
		var current = points[i]
		var opacity = 1.0 - clamp(current.age / fadeout_period, 0.0, 1.0)
		draw_line(prev.position, current.position, Color(1, 1, 1, opacity), 1.0)

# Example function to set the input value (call this from elsewhere)
func set_input_value(value: float) -> void:
	input_value = value
