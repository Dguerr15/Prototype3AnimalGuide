extends Node2D
const CarrotScene = preload("res://carrot.tscn")
const AnimalScene = preload("res://animal.gd")



# Called when the node enters the scene tree for the first time.

func place_carrot(position):
	var new_carrot = CarrotScene.instantiate()
	new_carrot.position = position
	add_child(new_carrot)
	print("Carrot placed at: ", position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_carrot(event.position)
			
				
