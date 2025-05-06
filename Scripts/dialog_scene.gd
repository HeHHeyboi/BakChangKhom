extends Control

@export var DialogList: Array[String]
var dialog_index: int = 0
@export var TextBox: RichTextLabel
@export var NameBox: Label


func _ready():
	show_text(DialogList[dialog_index])


# เอาไว้เรียกจาก Scene อื่นๆ
func show_dialog(list: Array[String]):
	pass


func show_text(text: String):
	TextBox.text = text


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("next_text"):
		dialog_index += 1
		if dialog_index >= len(DialogList):
			self.visible = false
		else:
			show_text(DialogList[dialog_index])
