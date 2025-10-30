extends CharacterBody2D

# Movement properties
const SPEED = 2500.0 
const SMELL_RANGE = 25000.0 # Max distance the animal can "smell" a carrot
const REACH_TOLERANCE = 5.0 # How close the animal needs to be to a path point/carrot

# --- Node References & AI Systems ---
# 1. Get the wrapper node first (which is correct)
@onready var sprout_lands_wrapper: Node2D = $"../SproutLandsTileMap" 

# FIX: Now explicitly using the known type: TileMapLayer
var fence_layer_node: TileMapLayer = null    
var astar_grid: AStarGrid2D = AStarGrid2D.new() 

# NEW: Stores the top-left coordinate of the used tile area, used to translate 
# world cell coords into AStarGrid's local coords (which start at 0,0).
var grid_cell_offset: Vector2i = Vector2i(0, 0) 

# State variables
var target_carrot: Node2D = null # The current carrot being pursued
var target_position: Vector2 = Vector2.ZERO # The current world target position
var path: Array[Vector2] = []    # The list of world coordinates to follow


func _ready():
	# 1. Check for the wrapper node
	if not is_instance_valid(sprout_lands_wrapper):
		printerr("!!! ERROR: SproutLandsTileMap wrapper not found at path: ../SproutLandsTileMap")
		return 

	# 2. ATTEMPT FENCE ASSIGNMENT
	if sprout_lands_wrapper.has_node("Fence"):
		# ASSIGNMENT: Get the 'Fence' node and cast it to the correct, non-strict type.
		fence_layer_node = sprout_lands_wrapper.get_node("Fence") as TileMapLayer
	
	# 3. Final Validation and Setup
	if is_instance_valid(fence_layer_node):
		setup_astar_grid()
		print("A* Grid successfully initialized using the 'Fence' layer node.")
	else:
		printerr("!!! PATHFINDING ERROR: 'Fence' layer node not found. Check the exact node name. !!!")

	# 4. Start by setting the target to the animal's current position
	target_position = global_position


func _physics_process(_delta): # Renamed 'delta' to '_delta' to fix the unused parameter warning
	# 1. CHECK FOR NEW TARGET & EATING
	var new_nearest_carrot = find_nearest_carrot()
	
	# Check if the animal is already close enough to the target carrot (eating condition)
	if new_nearest_carrot != null and global_position.distance_to(new_nearest_carrot.global_position) < 10:
		eat_carrot(new_nearest_carrot)
		new_nearest_carrot = null
	
	# If the nearest carrot has changed, or we lost the path, recalculate.
	if new_nearest_carrot != target_carrot:
		target_carrot = new_nearest_carrot
		path = [] # Clear the old path
		
	# 2. CALCULATE PATH IF NEEDED (Only if the fence node was successfully found)
	if is_instance_valid(fence_layer_node) and target_carrot != null and path.is_empty():
		target_position = target_carrot.global_position
		if calculate_path(target_position) == false:
			# Pathfinding failed (e.g., unreachable), so stop the animal
			target_position = global_position
			path = []
			
	# 3. MOVE ALONG THE PATH
	if not path.is_empty():
		var next_path_point = path[0]
		
		# Check if the animal has reached the current path point
		if global_position.distance_to(next_path_point) < REACH_TOLERANCE:
			path.pop_front() # Move to the next point in the path
			
		# Set velocity towards the next path point
		var direction = (next_path_point - global_position).normalized()
		velocity = direction * SPEED
		
	else:
		# Stop moving if no path or target is available
		velocity = Vector2.ZERO

	# Apply movement and physics (essential for CharacterBody2D)
	move_and_slide()

# --- Core Pathfinding Functions ---

func setup_astar_grid():
	# Configure the A* Grid based on the FENCE LAYER NODE
	var used_rect = fence_layer_node.get_used_rect()
	
	# FIX: Use 'region' instead of 'size' and 'offset' (Godot 4 compatible)
	astar_grid.region = used_rect
	
	# NEW: Store the top-left cell coordinate to use as the offset baseline
	grid_cell_offset = used_rect.position # Stores e.g., (-18, -23)
	
	if fence_layer_node.tile_set:
		astar_grid.cell_size = fence_layer_node.tile_set.tile_size
	else:
		printerr("Fence layer node has no TileSet! Cannot set up A* grid size.")
		return
		
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER 

	# FIX: Call update *before* the loop. This prepares the A* structure.
	astar_grid.update()

	# Identify and mark solid cells (walls)
	for x in range(used_rect.size.x):
		for y in range(used_rect.size.y):
			var map_coords = used_rect.position + Vector2i(x, y)
			
			# The coordinates passed to set_point_solid must be LOCAL (0,0 based)
			var local_coords = Vector2i(x, y)
			if fence_layer_node.get_cell_source_id(map_coords) != -1: 
				# Mark this cell as solid (unwalkable)
				astar_grid.set_point_solid(local_coords, true)

	# Call update *again* after all points are set to finalize the paths/weights
	astar_grid.update()


func calculate_path(target_world_position: Vector2) -> bool: # Renamed parameter to fix shadowed variable warning
	if not is_instance_valid(fence_layer_node):
		return false
		
	var cell_size = astar_grid.cell_size

	# 1. Get positions relative to the TileMapLayer's local space
	var animal_pos_local = fence_layer_node.to_local(global_position)
	var carrot_pos_local = fence_layer_node.to_local(target_world_position)
	
	# 2. Convert local position to absolute cell coordinates (TileMap indices)
	var global_start_cell = Vector2i((animal_pos_local / cell_size).floor())
	var global_end_cell = Vector2i((carrot_pos_local / cell_size).floor())
	
	# FIX: Use the RELATIVE (0,0 based) A* coordinates! 
	# This is required because AStarGrid2D often ignores the region origin 
	# and expects coordinates from 0 to Size.
	# --- THIS WAS THE COMMENTED-OUT SECTION CAUSING THE WRONG DIRECTION ---
	var start_cell = global_start_cell #- grid_cell_offset
	var end_cell = global_end_cell #- grid_cell_offset
	# ---------------------------------------------------------------------

	# NEW FIX: CLAMP the coordinates to the grid bounds to prevent "out of bounds" crashes
	var max_x = astar_grid.region.size.x - 1
	var max_y = astar_grid.region.size.y - 1
	
	start_cell.x = clamp(start_cell.x, 0, max_x)
	start_cell.y = clamp(start_cell.y, 0, max_y)
	end_cell.x = clamp(end_cell.x, 0, max_x)
	end_cell.y = clamp(end_cell.y, 0, max_y)
	
	# --- DEBUGGING START/END POINTS ---
	var start_solid = astar_grid.is_point_solid(start_cell)
	var end_solid = astar_grid.is_point_solid(end_cell)

	if start_solid or end_solid:
		printerr("!!! DEBUG A* FAIL !!!")
		printerr("  Reason: SOLID BLOCK. Start Cell (Relative A*): ", start_cell, " (Solid: ", start_solid, ")")
		printerr("  End Cell (Relative A*): ", end_cell, " (Solid: ", end_solid, ")")
		print("Pathfinding blocked: Target or Animal position is inside a wall.")
		return false
	# -----------------------------------

	# Get the path as a list of cell coordinates
	var path_cells = astar_grid.get_id_path(start_cell, end_cell)
	
	if path_cells.size() <= 1:
		print("Pathfinding failed or target is unreachable.")
		return false 
		
	# Convert cell coordinates back to world coordinates
	for cell in path_cells:
		# Convert the A* local cell (cell + offset) back to the world center of that tile
		var world_cell = cell + grid_cell_offset # Re-apply the offset to get the global cell index
		var world_pos = fence_layer_node.map_to_world(world_cell) # Use map_to_world for stable conversion
		world_pos += astar_grid.cell_size * fence_layer_node.global_scale / 2 # Center the point
		path.append(world_pos)
	
	# Remove the first point if it's the animal's current location to prevent immediate pop
	if path.size() > 0:
		path.pop_front() 

	return true 

# --- Carrot Management Functions ---

func find_nearest_carrot():
	var parent = get_parent()
	var carrots = []
	
	for child in parent.get_children():
		# Using the assumed carrot scene path
		if child.get_scene_file_path() == "res://carrot.tscn":
			var carrot_distance = global_position.distance_to(child.global_position)
			if carrot_distance <= SMELL_RANGE:
				carrots.append(child)
			
	if carrots.is_empty():
		return null

	# Find the nearest carrot among those within range
	var closest_carrot = null
	var min_distance = INF
	
	for carrot in carrots:
		var distance = global_position.distance_to(carrot.global_position)
		
		if distance < min_distance:
			min_distance = distance
			closest_carrot = carrot
			
	return closest_carrot

func eat_carrot(carrot_node: Node2D):
	if is_instance_valid(carrot_node):
		carrot_node.queue_free()
		print("Carrot eaten!")
		# Force a path recalculation next frame to find the next target
		target_carrot = null
