extends Area2D

@export_file("*.tscn") var next_scene_path
var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered: 
		return
	if body.is_in_group("Animal"):
		_triggered = true
		await get_tree().process_frame
		get_tree().change_scene_to_file(next_scene_path)
