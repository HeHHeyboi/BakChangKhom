extends CanvasLayer

@export var TextBox: RichTextLabel
@export var NameBox: Label
@export var ChoiceContainer: VBoxContainer
@export var DialogButton: Button
@export var test_file: String
# @export var BG_img: Texture2D
@export var Test: bool
# @export var ShowSprites: Node2D

@onready var bg_node = $"BG" as Sprite2D
@onready var ShowSprites = $"CharacterPos" as CharacterPos
@onready var Title = $"Title" as RichTextLabel
enum DialogType { Dialog, Choice, SelectChoice }

const DIALOG = "dialog"
const CHOICE = "choice"
const AssetDir = "res://Assets/"

var dialog_stack: Array[String] = []
var index_stack: Array[int] = []
var current_dialog: Array
var DialogDict := {DIALOG: []}
var choiceButton = preload("res://Scene/DialogChoice.tscn")
var curSprite: CharacterSprite = null
var charSprite: Array[CharacterSprite]


func set_title(title: String):
	Title.clear()
	Title.add_text(title)


# NOTE: มีไว้ test
func _ready():
	if Test:
		read_file(AssetDir + test_file + ".txt")
		# print_rich(DialogDict)
		# bg_node.texture = BG_img
		dialog_stack.append(DIALOG)
		index_stack.append(0)
		current_dialog = DialogDict[dialog_stack[-1]]
		var playerSprite = CharacterSprite.new(Global.getCharacterTexture("ขม"), "ขม")
		var grandma = CharacterSprite.new(Global.getCharacterTexture("ยาย"), "ยาย")
		charSprite.append_array([playerSprite, grandma])
		ShowSprites.addCharacterSprite(playerSprite)
		ShowSprites.addCharacterSprite(grandma)
		show_text(current_dialog[index_stack[-1]])
		return

	self.visible = false
	# self.call_deferred("move_to_front")


func addCharcter(chars: Array):
	for char_name in chars:
		var c = Global.getCharacterSprite(char_name)
		print(c.name)
		ShowSprites.addCharacterSprite(c)


# NOTE: อันนี้เอาไว้ใช้จริง จะเรียกผ่าน Object อื่น
func show_dialog(file_path: StringName, bg_name: String, chars: Array = []):
	Global.showDialog()
	if !chars.is_empty():
		addCharcter(chars)

	if !bg_name.is_empty():
		# var loadImg = Image.load_from_file(bg)
		bg_node.texture = load(bg_name) as Texture2D

	dialog_stack.append(DIALOG)
	index_stack.append(0)
	self.visible = true
	read_file(file_path)
	current_dialog = DialogDict[dialog_stack[-1]]
	show_text(current_dialog[index_stack[-1]])


func read_file(file_path: StringName):
	var file = FileAccess.open(file_path, FileAccess.READ)
	var type = DIALOG

	while !file.eof_reached():
		var line = file.get_line()
		line = line.rstrip(" ").lstrip(" ")

		if line == "":
			type = DIALOG
			continue
		if line.findn("#") == 0:
			continue
		# print(line)

		# var header = ""
		if line.find(":") > -1:
			var split = line.split(":")
			var header = split.get(0).to_lower()
			if header != CHOICE:
				type = header
		match type:
			CHOICE, DIALOG:
				DialogDict[type].append(line)
			_:
				if !DialogDict.has(type):
					DialogDict[type] = []
					continue

				DialogDict[type].append(line)
	# print(MainDialog)
	# print(DialogDict)
	file.close()


# TODO:
# 	1. Parse header "Choice"
# 	2. other thing too
func show_text(text: String):
	curSprite = null
	var parse = parse_text(text)
	DialogButton.disabled = false

	match parse["type"]:
		DialogType.Dialog:
			NameBox.text = parse["name"]
			TextBox.clear()
			TextBox.add_text(parse["dialog"])
			for n in ShowSprites.get_children():
				if n.name == parse["name"]:
					curSprite = n as CharacterSprite
					curSprite.highlight()
					break
		DialogType.Choice:
			ChoiceContainer.visible = true
			DialogButton.disabled = true


func parse_text(text: String):
	var header
	var body
	if text.find(":") > -1:
		var p = text.split(":")
		header = p.get(0)

		body = p.get(1).split(",")
		for i in range(len(body)):
			body[i] = body.get(i).lstrip(" ")
	else:
		body = text.split(",")
		for i in range(len(body)):
			body[i] = body.get(i).lstrip(" ")

	match header:
		"Choice":
			for choice in body:
				var button = choiceButton.instantiate()
				button.connect("get_choice", click_choice)
				button.text = choice
				ChoiceContainer.add_child(button)

			return {"type": DialogType.Choice}
		_:
			return {"type": DialogType.Dialog, "name": body[0], "dialog": body[1]}


func next_text() -> void:
	index_stack[-1] += 1
	if curSprite != null:
		curSprite.fade()
	while index_stack.size() > 0 and index_stack[-1] >= current_dialog.size():
		index_stack.pop_back()
		dialog_stack.pop_back()
		if dialog_stack.size() == 0:
			dialog_end()
			return

		current_dialog = DialogDict[dialog_stack[-1]]

	# prints(index_stack)
	show_text(current_dialog[index_stack[-1]])


# NOTE: maybe this is a signal
func dialog_end() -> void:
	Global.hideDialog()
	self.visible = false
	DialogDict.clear()
	index_stack.clear()
	dialog_stack.clear()
	DialogDict[DIALOG] = []
	ShowSprites.reset()


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


func _on_skip_pressed():
	var choice
	for i in range(index_stack[-1], current_dialog.size()):
		choice = parse_text(current_dialog[i])
		if choice["type"] == DialogType.Choice:
			var dialog = parse_text(current_dialog[i - 1])
			index_stack[-1] = i
			ChoiceContainer.visible = true
			DialogButton.disabled = true
			NameBox.text = dialog["name"]
			TextBox.clear()
			TextBox.add_text(dialog["dialog"])

			for n in ShowSprites.get_children():
				if n.name == dialog["name"]:
					curSprite = n as CharacterSprite
					curSprite.highlight()
					break
			return

	if choice["type"] == DialogType.Dialog:
		dialog_end()
