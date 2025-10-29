extends CharacterBody2D

const SPEED = 100.0 
var target_position = Vector2.ZERO 
func _ready():
	target_position = global_position 

func _physics_process(delta):
	var nearest_carrot = find_nearest_carrot()
	
	if nearest_carrot != null:
		target_position = nearest_carrot.global_position
		
		#if global_position.distance_to(target_position) < 10: # Distance check (10 pixels tolerance)
			## Remove the carrot from the game world
			#nearest_carrot.queue_free() 
			## Reset target to prevent jittering or immediately picking a new one too fast
			#target_position = global_position
			## Stop the movement in this frame
			#velocity = Vector2.ZERO 
			#move_and_slide()
			#return # Exit early after eating

	
	var direction = (target_position - global_position).normalized()
	
	# Calculate the velocity
	velocity = direction * SPEED
	
	move_and_slide()

func find_nearest_carrot():
	var parent = get_parent()
	var carrots = []
	
	for child in parent.get_children():
		if child.get_scene_file_path() == "res://carrot.tscn":
			carrots.append(child)
			
	# If no carrots are found, return null
	if carrots.is_empty():
		return null

	# Find the nearest carrot
	var closest_carrot = null
	var min_distance = INF # Use Godot's infinite value to start
	
	for carrot in carrots:
		var distance = global_position.distance_to(carrot.global_position)
		
		if distance < min_distance:
			min_distance = distance
			closest_carrot = carrot
			
	return closest_carrot
