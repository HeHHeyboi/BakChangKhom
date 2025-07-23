extends Button

@onready var marketScene = load("res://Scene/Market.tscn").instantiate() as Node2D


func _on_market_pressed() -> void:
	get_tree().root.add_child(marketScene)
