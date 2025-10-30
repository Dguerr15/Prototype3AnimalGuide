extends Control

# This function runs when the scene is loaded
func _ready():
	get_tree().paused = false
	
	$Button.pressed.connect(_on_restart_button_pressed)
	
# Function to restart the game
func _on_restart_button_pressed():
	if GlobalTimer:
		GlobalTimer.restart_timer()
		
	var main_scene = load("res://main.tscn")
	
	
	# Reload the main game scene
	get_tree().change_scene_to_packed(main_scene)
