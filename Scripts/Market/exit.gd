extends Area2D

@onready var text = $"Control"
@export var map: Control


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_E:
				map.visible = !map.visible


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		text.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		text.visible = false
