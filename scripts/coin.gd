extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var label: Label = $"../../HUD/Label"

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": 
		GameManager.add_point() 
		queue_free()
