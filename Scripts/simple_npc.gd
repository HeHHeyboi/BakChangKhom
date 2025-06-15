extends Node2D

var playerEnter = false
@onready var TextAppear = $TextHelp
@onready var player = self.get_node("../Player")


func _ready() -> void:
	prints(player)
	TextAppear.hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		event = event as InputEventKey
		if event.is_pressed() && playerEnter:
			if event.keycode == KEY_E:
				DialogScene.visible = !DialogScene.visible
				DialogScene.show_dialog("res://Assets/Chapter1ReturnHome.txt")


func _on_dialog_area_body_entered(body: Node2D) -> void:
	if body == player:
		prints("Player Enter")
		playerEnter = true
		TextAppear.show()


func _on_dialog_area_body_exited(body: Node2D) -> void:
	if body == player:
		prints("Player Exit")
		playerEnter = false
		TextAppear.hide()
