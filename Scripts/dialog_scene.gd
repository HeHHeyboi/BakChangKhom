extends Control

@export var DialogList: Array[String]
var dialog_index: int = 0
@export var TextBox: RichTextLabel
@export var NameBox: Label

enum DialogType { Dialog, Choice }


func _ready():
	show_text(DialogList[dialog_index])


# เอาไว้เรียกจาก Scene อื่นๆ
func show_dialog(list: Array[String]):
	pass


func show_text(text: String):
	var parse_text = parse_text(text)
	NameBox.text = parse_text[0]
	TextBox.text = parse_text[1]


func parse_text(text: String):
	var p = text.split(":")
	var header = p[0]
	var body = p[1]
	body.trim_prefix(" ")
	return [header, body]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("next_text"):
		dialog_index += 1
		if dialog_index >= len(DialogList):
			self.visible = false
		else:
			show_text(DialogList[dialog_index])
