extends Node2D


func _enter_tree() -> void:
	DialogScene.call_deferred("move_to_front")
