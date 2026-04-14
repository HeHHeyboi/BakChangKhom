extends Control

var minigame = Global.ReturnMiniGame("MiniGame1") as Node2D


func _ready() -> void:
	pass  # Replace with function body.


func _on_event_pressed() -> void:
	get_tree().root.add_child(minigame)
	Global.in_minigame = true
