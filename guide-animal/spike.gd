extends Area2D


func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Animal"):
		call_deferred("_reload_scene")

func _reload_scene() -> void:
	if is_instance_valid(GlobalTimer):
		GlobalTimer.restart_timer()
	get_tree().reload_current_scene() 
