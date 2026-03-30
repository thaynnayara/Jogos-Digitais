extends Area2D

func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	pass
	
func _on_water_body_entered(body: Node2D) -> void:
	if body.has_method("go_to_dead_state"):
		body.go_to_dead_state()
