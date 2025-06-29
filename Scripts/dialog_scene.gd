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

var dialog_stack: Array[String] = []
var index_stack: Array[int] = []
var current_dialog: Array
var DialogDict := {DIALOG: []}
var choiceButton = preload("res://Scene/DialogChoice.tscn")
var curPlayer: Player = null

# NOTE: มีไว้ test
# func _ready():
# 	read_file(TXT_PATH + test_file)
# 	current_dialog = DialogDict[dialog_stack[-1]]
# 	show_text(current_dialog[index_stack[-1]])
# 	print("MainDialog Size: ", len(MainDialog))


# NOTE: อันนี้เอาไว้ใช้จริง จะเรียกผ่าน Object อื่น
func show_dialog(file_path: StringName, player: Player):
	curPlayer = player
	curPlayer.isDialogShow = true

	dialog_stack.append(DIALOG)
	index_stack.append(0)
	self.visible = true
	read_file(file_path)
	current_dialog = DialogDict[dialog_stack[-1]]
	show_text(current_dialog[index_stack[-1]])
	pass


# HACK: อาจจะเปลี่ยนที่หลัง
func _ready() -> void:
	self.visible = false
	self.call_deferred("move_to_front")


func read_file(file_path: StringName):
	var file = FileAccess.open(file_path, FileAccess.READ)
	var type = "dialog"

	while !file.eof_reached():
		var line = file.get_line()
		line = line.rstrip(" ").lstrip(" ")
		if line.findn("#") == 0:
			continue
		# print(line)

		var split = line.split(":")
		var header = split.get(0).to_lower()
		match header:
			DIALOG, CHOICE:
				DialogDict[type].append(line)
			_:
				if header == "":
					type = "dialog"
					continue
				if !DialogDict.has(header):
					DialogDict[header] = []
					type = header
					continue
	# print(MainDialog)
	# print(DialogDict)
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
	index_stack[-1] += 1
	while index_stack.size() > 0 and index_stack[-1] >= current_dialog.size():
		index_stack.pop_back()
		dialog_stack.pop_back()
		if dialog_stack.size() == 0:
			dialog_end()
			return

		current_dialog = DialogDict[dialog_stack[-1]]

	show_text(current_dialog[index_stack[-1]])


# NOTE: maybe this is a signal
func dialog_end() -> void:
	self.visible = false
	curPlayer.isDialogShow = false
	DialogDict.clear()
	DialogDict[DIALOG] = []
	index_stack.clear()


func click_choice(button: Button) -> void:
	var select_Choice = button.text

	index_stack[-1] += 1
	index_stack.append(0)
	dialog_stack.append(select_Choice)
	current_dialog = DialogDict[dialog_stack[-1]]

	show_text(current_dialog[index_stack[-1]])
	ChoiceContainer.visible = false
	for i in ChoiceContainer.get_children():
		i.queue_free()
