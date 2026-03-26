extends Node2D

var playerEnter = false
@onready var TextAppear = $TextHelp
# @onready var player = self.pare.get_node("../Player") as Player
@onready var player = self.get_parent().get_node("Player") as Player


func _ready() -> void:
	prints(player)
	TextAppear.hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		event = event as InputEventKey
		if event.is_pressed() && playerEnter:
			if event.keycode == KEY_E:
				# Antigravity: Fixed bug where 'player' object was passed as bg_name string
				# and changed character list to separate elements ["ขม", "ยาย"]
				DialogScene.show_dialog("res://Assets/Chapter1ReturnHome.txt", "", ["ขม", "ยาย"])
				DialogScene.visible = true


func _on_dialog_area_body_entered(body: Node2D) -> void:
	if body is Player:
		prints("Player Enter")
		playerEnter = true
		TextAppear.show()


func _on_dialog_area_body_exited(body: Node2D) -> void:
	if body is Player:
		prints("Player Exit")
		playerEnter = false
		TextAppear.hide()
