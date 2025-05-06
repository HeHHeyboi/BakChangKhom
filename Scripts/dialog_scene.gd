extends Control

@export var DialogList: Array[String]
var dialog_index: int = 0
@export var TextBox: Label
@export var NameBox: Label
@export var ChoiceContainer: VBoxContainer
var select_Choice: String
enum DialogType { Dialog, Choice, SelectChoice }


func _ready():
	show_text(DialogList[dialog_index])


# เอาไว้เรียกจาก Scene อื่นๆ
# อันนี้น่าจะแก้เป็นชื่อไฟล์ text
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
		DialogType.Choice:
			ChoiceContainer.visible = true


func parse_text(text: String):
	var p = text.split(":")
	var header = p.get(0)
	var body := p.get(1).split(",")
	match header:
		"Dialog":
			return {"type": DialogType.Dialog, "name": body[0], "dialog": body[1]}
		"Choice":
			for choice in body:
				var button = Button.new()
				button.connect("pressed", click_choice)
				button.text = choice
				ChoiceContainer.add_child(button)
			return {"type": DialogType.Choice}
		select_Choice:
			pass


# func _input(event: InputEvent) -> void:


func next_text() -> void:
	dialog_index += 1
	if dialog_index >= len(DialogList):
		self.visible = false
	else:
		show_text(DialogList[dialog_index])


func click_choice() -> void:
	ChoiceContainer.visible = false
	dialog_index += 1
	if dialog_index >= len(DialogList):
		self.visible = false
	else:
		show_text(DialogList[dialog_index])
