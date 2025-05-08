extends Control

@export var TextBox: Label
@export var NameBox: Label
@export var ChoiceContainer: VBoxContainer
@export var DialogButton: Button
@export var test_file: String

enum DialogType { Dialog, Choice, SelectChoice }

const DIALOG = "dialog"
const CHOICE = "choice"
const TXT_PATH = "res://Assets/"
var dialog_stack: Array[int] = [0]
var select_Choice: String
var ChoiceDict := {}
var choiceButton = preload("res://Scene/DialogChoice.tscn")
var MainDialog: Array[String]


# NOTE: มีไว้ test
func _ready():
	read_file(TXT_PATH + test_file)
	show_text(MainDialog[dialog_stack[-1]])
	# print("MainDialog Size: ", len(MainDialog))


# NOTE: อันนี้เอาไว้ใช้จริง จะเรียกผ่าน Object อื่น
func show_dialog(file_name: StringName):
	pass


func read_file(file_name: StringName):
	var file = FileAccess.open(file_name, FileAccess.READ)
	var type = "dialog"

	while !file.eof_reached():
		var line = file.get_line()
		line = line.rstrip(" ").lstrip(" ")
		if line.findn("#") == 0:
			continue
		print(line)

		var split = line.split(":")
		var header = split.get(0).to_lower()
		match header:
			DIALOG, CHOICE:
				if type == "dialog":
					MainDialog.append(line)
				else:
					ChoiceDict[type].append(line)
			_:
				if header == "":
					type = "dialog"
					continue
				if !ChoiceDict.has(header):
					ChoiceDict[header] = []
					type = header
					continue
	# print(MainDialog)
	# print(ChoiceDict)
	file.close()


# TODO:
# 	1. Parse header "Choice"
# 	2. other thing too


func show_text(text: String):
	var parse = parse_text(text)
	DialogButton.disabled = false

	match parse["type"]:
		DialogType.Dialog:
			NameBox.text = parse["name"]
			TextBox.text = parse["dialog"]
		DialogType.Choice:
			ChoiceContainer.visible = true
			DialogButton.disabled = true


func parse_text(text: String):
	var p = text.split(":")
	var header = p.get(0)

	var body = p.get(1).split(",")
	for i in range(len(body)):
		body[i] = body.get(i).lstrip(" ")

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


func next_text() -> void:
	dialog_stack[-1] += 1
	var current_dialog = MainDialog
	# print("Start", current_dialog)
	var has_selectChoice = ChoiceDict.has(select_Choice)
	print(dialog_stack)

	if has_selectChoice:
		current_dialog = ChoiceDict[select_Choice]

		# for i in range(len(dialog_stack) - 1, -1, -1):
		# print(i)
	for i in range(len(dialog_stack) - 1, -1, -1):
		if dialog_stack[-1] >= len(current_dialog):
			dialog_stack.pop_back()
			select_Choice = ""
			current_dialog = MainDialog

	if len(dialog_stack) == 0:
		self.visible = false
		return
	show_text(current_dialog[dialog_stack[-1]])


func click_choice(button: Button) -> void:
	select_Choice = button.text
	# print(select_Choice)

	dialog_stack[-1] += 1
	dialog_stack.append(0)

	show_text(ChoiceDict[select_Choice][dialog_stack[-1]])
	ChoiceContainer.visible = false
	for i in ChoiceContainer.get_children():
		ChoiceContainer.remove_child(i)
	# dialog_index += 1
	# if dialog_index >= len(MainDialog):
	# 	self.visible = false
	# else:
	# 	show_text(MainDialog[dialog_index])
