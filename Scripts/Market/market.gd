extends Node2D

@onready var player_spawn_point = $PlayerSpawn.position


func _on_hidden() -> void:
	$Player.position = player_spawn_point
