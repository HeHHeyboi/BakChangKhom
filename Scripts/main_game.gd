extends Node2D

# @onready var player = $"Player"


func _enter_tree() -> void:
	DialogScene.call_deferred("move_to_front")
