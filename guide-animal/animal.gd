extends CharacterBody2D

const SPEED = 250.0  # Reduced for better control
const RADIUS = 25000.0

@onready var navigation_agent = $NavigationAgent2D

var target_position = Vector2.ZERO
var nearest_carrot = null

func _ready():
	# Wait for the navigation to be ready
	await get_tree().physics_frame
	
	target_position = global_position
	navigation_agent.target_position = target_position
	
	# Configure navigation agent
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 10.0
	navigation_agent.debug_enabled = true  # Visualize path in editor

func _physics_process(delta):
	nearest_carrot = find_nearest_carrot()
	
	if nearest_carrot != null:
		target_position = nearest_carrot.global_position
		navigation_agent.target_position = target_position
		
		# Check if close enough to eat carrot
		if global_position.distance_to(target_position) < 10:
			nearest_carrot.queue_free() 
			target_position = global_position
			navigation_agent.target_position = target_position
			velocity = Vector2.ZERO
			move_and_slide()
			return
	else:
		target_position = global_position
		navigation_agent.target_position = target_position
	
	# Follow the navigation path
	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_path_position = navigation_agent.get_next_path_position()
		var direction = (next_path_position - global_position).normalized()
		velocity = direction * SPEED
	
	move_and_slide()

func find_nearest_carrot():
	var parent = get_parent()
	var carrots = []
	
	for child in parent.get_children():
		if child.get_scene_file_path() == "res://carrot.tscn":
			var carrot_distance = global_position.distance_to(child.global_position)
			if carrot_distance <= RADIUS:
				carrots.append(child)
			
	if carrots.is_empty():
		return null

	var closest_carrot = null
	var min_distance = INF
	
	for carrot in carrots:
		var distance = global_position.distance_to(carrot.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_carrot = carrot
			
	return closest_carrot

# Debug function to see what's happening
func _process(delta):
	if nearest_carrot != null and navigation_agent != null:
		if navigation_agent.is_target_reachable():
			print("Path to carrot is clear!")
		else:
			print("No path to carrot - it's blocked!")
