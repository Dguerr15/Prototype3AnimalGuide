extends Camera2D

@onready var camera = $Camera2D 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if camera:
		print("found camera")
		camera.make_current()
	else:
		print("no camera found")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Replace with the correct path to your camera

	
