extends Control

@export var DialogList: Array[String]
@export var TextBox: Label
@export var NameBox: Label
@export var ChoiceContainer: VBoxContainer

enum DialogType { Dialog, Choice, SelectChoice }

const DIALOG = "dialog"
const CHOICE = "choice"
var dialog_index: int = 0
var select_index = 0
var select_Choice: String
var ChoiceDict := {}
var choiceButton = preload("res://Scene/DialogChoice.tscn")


func _ready():
	show_text(DialogList[dialog_index])


# will change to file name?
func show_dialog(list: Array[String]):
	pass


func read_file(list: Array[String]):
	for i in list:
		var split = i.split(":")
		var header = split.get(0).to_lower()
		var body = split.get(1)
		match header:
			DIALOG, CHOICE:
				DialogList.append(i)
			_:
				if !ChoiceDict.has(header):
					ChoiceDict[header] = [] as Array[String]
				ChoiceDict[header].append(body)


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
	var body = p.get(1).split(",")
	for i in range(len(body)):
		body[i] = body.get(i).trim_prefix(" ")
	match header:
		"Dialog":
			return {"type": DialogType.Dialog, "name": body[0], "dialog": body[1]}
		"Choice":
			for choice in body:
				var button = choiceButton.instantiate()
				button.connect("get_choice", click_choice)
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


func click_choice(button: Button) -> void:
	select_Choice = button.text
	print(select_Choice)
	ChoiceContainer.visible = false
	# dialog_index += 1
	# if dialog_index >= len(DialogList):
	# 	self.visible = false
	# else:
	# 	show_text(DialogList[dialog_index])
