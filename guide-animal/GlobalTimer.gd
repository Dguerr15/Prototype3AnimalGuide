extends Node

# Reference the Timer node as a variable
@onready var timer = $Timer
var timer_label: Label = null
var carrots_placed: int = 0

# The function that runs when the Timer hits 0
func _on_timer_timeout():
	# Stop all game activity
	get_tree().paused = true
	
	# Load and switch to the Game Over scene (you will create this next)
	var game_over_scene = load("res://GameOver.tscn")
	get_tree().change_scene_to_packed(game_over_scene)

# Connect the signal in the _ready function
func _ready():
	# Connect the Timer's 'timeout' signal to the '_on_timer_timeout' function
	timer.timeout.connect(_on_timer_timeout)

func _process(delta):
	# Check if a label reference has been set (from the main scene)
	if timer_label:
		# Calculate the time remaining and format it to show only whole seconds
		var time_left_sec = int(timer.time_left)
		
		# Display the time
		timer_label.text = "Time: " + str(time_left_sec)

# New function to be called from the main scene to link the Label
func set_timer_label(label_node: Label):
	timer_label = label_node
	# Call _process immediately to show the starting time
	_process(0)

func restart_timer():
	# Set the timer's wait_time back to its starting value (e.g., 60.0)
	# You might need to change this if your start time is different
	timer.wait_time = 60.0 
	timer.start()

func Timercarrot():
	carrots_placed += 1
	var new_time_remaining = timer.time_left - 1.0 # Deduct 1 second
	# Check if we have time to deduct before deducting
	if new_time_remaining <= 0.0:
		timer.stop() # Stop the timer
		_on_timer_timeout() # Trigger Game Over immediately
		return
	timer.stop()
	timer.wait_time = new_time_remaining
	timer.start()
	_process(0)
	
	# Debug message to confirm
	print("Carrots Placed: ", carrots_placed, " | New Time Left: ", timer.time_left)
