class_name InputQueue
extends Object

'''
Must track Elements in queue.
It's a ring queue
Element must be nulled out
Tracking:
	i % 32 = idx

'''
const BUFFER_SIZE = 32 # Currently its set to 32 and might need to be adjusted
# Buffer States
const STATE_READY = 0
const STATE_FULL = 1
const STATE_EMPTY = 2

var buffer: Array[InputEvent] = []
var slot: int = 0;

var state: int = 0
var _in: int = 0
var _out: int = 0

func _ready():
	buffer.resize(BUFFER_SIZE) # Set the queue size, new elems are null

	
func enq(event: InputEvent) -> bool:
	if STATE_FULL == state:
		return false
	# TODO: Issue #6 : Beware that event could be lost if this is a reference
	# check if copy or reference _in implementation
	buffer[_in] =event  
	_in += 1
	# _in = (_in) % BUFFER_SIZE
	_in %= BUFFER_SIZE
	
	if _out == _in:
		set_state(STATE_FULL)
	else:
		set_state(STATE_READY)
	return true

func deq() -> InputEvent:
	var event: InputEvent = buffer[_out]
	_out += 1
	_out %= BUFFER_SIZE
	if _in == _out:
		set_state(STATE_EMPTY)
	else:
		set_state(STATE_READY)
	return event


func deq_next() -> int:
	if STATE_EMPTY == state:
		return -1
	return _out

func set_state(STATE: int):
	state = STATE

func clear() -> void:
	pass
