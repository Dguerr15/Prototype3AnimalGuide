extends Node2D
const CarrotScene = preload("res://carrot.tscn")
@onready var camera := $Camera2D

func _ready() -> void:
	if camera:
		camera.make_current()

func place_carrot(world_pos: Vector2) -> void:
	var c := CarrotScene.instantiate()
	add_child(c)
	c.global_position = world_pos
	print("Carrot placed at: ", world_pos)

func _input(event):
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos := get_global_mouse_position()
		place_carrot(world_pos)
