extends Node2D

@onready var player_spawn_point = $PlayerSpawn.position


func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_DISABLED
	self.hide()


func _on_hidden() -> void:
	$Player.position = player_spawn_point
