extends CanvasLayer

@onready var score_label = $Label

func _ready():
	
	GameManager.score_changed.connect(update_score_text)
	update_score_text(GameManager.score)

func update_score_text(value):
	score_label.text = "Moedas: " + str(value)
