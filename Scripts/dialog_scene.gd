extends Control

@export var DialogList: Array[String]
var dialog_index: int = 0
@export var TextBox: RichTextLabel
@export var NameBox: Label
@export var ChoiceContainer: VBoxContainer
var select_Choice: String
enum DialogType { Dialog, Choice, SelectChoice }


func _ready():
	show_text(DialogList[dialog_index])


# เอาไว้เรียกจาก Scene อื่นๆ
func show_dialog(list: Array[String]):
	pass


# TODO:
# 	1. Parse header "Choice"
# 	2. other thing too


func show_text(text: String):
	var parse = parse_text(text)
	match parse["type"]:
		DialogType.Dialog:
			NameBox.text = parse["name"]
			TextBox.text = parse["dialog"]


func parse_text(text: String):
	var p = text.split(":")
	var header = p[0]
	var body: String = p[1]
	body.trim_prefix(" ")
	match header:
		"Dialog":
			var split_body = body.split(",")
			return {"type": DialogType.Dialog, "name": split_body[0], "dialog": split_body[1]}
		"Choice":
			pass
		select_Choice:
			pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("next_text"):
		dialog_index += 1
		if dialog_index >= len(DialogList):
			self.visible = false
		else:
			show_text(DialogList[dialog_index])
