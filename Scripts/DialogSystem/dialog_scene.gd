extends CanvasLayer

@export var TextBox: RichTextLabel
@export var NameBox: Label
@export var ChoiceContainer: VBoxContainer
@export var DialogButton: Button
@export var test_file: String
@export var skip_btn: Button
# @export var BG_img: Texture2D
@export var Test: bool
# @export var ShowSprites: Node2D

@onready var bg_node = $"BG" as Sprite2D
@onready var ShowSprites = $"CharacterPos" as CharacterPos
@onready var Title = $"Title" as RichTextLabel

const DIALOG = "dialog"
const CHOICE = "choice"

const AssetDir = "res://Assets/"
const BackgroundDir = "res://Assets/Background/"
const DialogChoiceScene = "res://Scene/DialogChoice.tscn"

const MaxBGSize = Vector2(1152.0, 648.0)
var dialog_stack: Array[String] = []
var index_stack: Array[int] = []
var current_dialog: Array
var DialogDict := { DIALOG: [] }
var choiceButton = preload(DialogChoiceScene)
var curSprite: CharacterSprite = null
var charSprite: Array[CharacterSprite]

signal on_dialog_finish


func set_title(title: String):
	Title.clear()
	Title.add_text(title)


func _enter_tree() -> void:
	EventManager.showDialogEvent.connect(show_dialog)


func _exit_tree() -> void:
	EventManager.showDialogEvent.disconnect(show_dialog)


# NOTE: มีไว้ test
func _ready():
	if Test:
		get_tree().root.remove_child(self)
		read_file(AssetDir + test_file + ".txt")
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


func show_dialog(file_path: StringName, bg_name: String, chars: Array = []):
	Global.showDialog()
	bg_node.scale = Vector2(1, 1)
	if !chars.is_empty():
		for entry in chars:
			for char_name in String(entry).split(",", false):
				char_name = char_name.strip_edges()
				if Global.hasCharacter(char_name) and not ShowSprites.has_node(NodePath(char_name.validate_node_name())):
					ShowSprites.addCharacterSprite(Global.getCharacterSprite(char_name))

	if bg_name.is_empty():
		var transparent_img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		transparent_img.fill(Color(0, 0, 0, 0))
		bg_node.texture = ImageTexture.create_from_image(transparent_img)
	else:
		# var loadImg = Image.load_from_file(bg)
		bg_node.texture = load(bg_name) as Texture2D
		var bgSize = bg_node.texture.get_size()
		if bgSize > MaxBGSize:
			bg_node.scale = MaxBGSize / bgSize

	dialog_stack.append(DIALOG)
	index_stack.append(0)
	self.visible = true
	read_file(file_path)
	current_dialog = DialogDict[dialog_stack[-1]]
	show_text(current_dialog[index_stack[-1]])


func read_file(file_path: StringName):
	var file = FileAccess.open(file_path, FileAccess.READ)
	var type = DIALOG

	var line_num = 0

	while !file.eof_reached():
		var line = file.get_line()
		line = line.rstrip(" ").lstrip(" ")
		line_num += 1

		if line == "":
			type = DIALOG
			continue
		if line.findn("#") == 0:
			continue
		# print(line)

		# var header = ""
		if line.find(":") > -1:
			var split = line.split(":", true, 1)
			if split.get(0) == "":
				printerr("%s missing header on line: %d" % [file_path, line_num])
				continue
			var header = split.get(0).to_lower()
			if header != CHOICE:
				type = header
		match type:
			CHOICE, DIALOG:
				DialogDict[type].append(parse_text(line))
			_:
				if !DialogDict.has(type):
					DialogDict[type] = []
					continue
				DialogDict[type].append(parse_text(line))
	file.close()


## คำในวงเล็บหลังชื่อผู้พูด → อารมณ์ เช่น "ขม (ยิ้ม)" → name "ขม" · mood "happy"
## อารมณ์ที่ตรงก่อน (ตามลำดับ key) ชนะ · ไม่ตรงเลย = ""
const MOOD_WORDS := {
	"happy": ["ยิ้ม", "ดีใจ", "หัวเราะ", "ภูมิใจ", "ตื่นเต้น"],
	"worry": ["กังวล", "เครียด", "ถอนหายใจ", "ตกใจ", "เศร้า", "เหนื่อย", "สั่น"],
}


## แยก "ชื่อ (คำกำกับ)" ออกเป็นชื่อ + อารมณ์ + คำกำกับ แล้วสร้าง token
func from_raw(raw_name: String, p_dialog: String) -> DialogToken:
	var base := raw_name.strip_edges()
	var extra := ""
	var i := base.find("(")
	if i > 0:
		extra = base.substr(i)
		base = base.substr(0, i).strip_edges()
	var mood := ""
	for m in MOOD_WORDS:
		for w in MOOD_WORDS[m]:
			if extra.contains(w):
				mood = m
				break
		if !mood.is_empty():
			break
	return DialogToken.new(base, p_dialog, mood, extra)


func parse_text(text: String):
	var header: String = ""
	var body
	if text.find(":") > -1:
		var p = text.split(":")
		header = p.get(0)
		body = p.get(1)

	if header != null:
		header = header.to_lower()

	match header:
		CHOICE:
			var choices = body.split(",")
			for i in range(len(choices)):
				choices[i] = choices.get(i).lstrip(" ")
			return ChoiceToken.new(choices)
		_:
			body = text.split(",")
			if body.size() < 2:
				push_error("บรรทัดบทผิดรูปแบบ: %s" % text)
				return null
			for i in range(len(body)):
				body[i] = body.get(i).lstrip(" ")
			return from_raw(body[0], body[1])


func show_text(token) -> void:
	curSprite = null
	DialogButton.disabled = false

	match token:
		var dialog when token is DialogToken:
			NameBox.text = dialog.name + " " + dialog.note
			TextBox.clear()
			TextBox.add_text(dialog.dialog)
			_show_speaker(dialog)
		var choice when token is ChoiceToken:
			create_choice_buttons(choice.choices)
			skip_btn.disabled = true
			ChoiceContainer.visible = true
			DialogButton.disabled = true


## [Claude 1 ต.ค.] รูปคนพูดขึ้นเองตามชื่อในสคริปต์ — "ยาย (น้ำเสียงอ่อนโยน)" → ยาย · อารมณ์ในวงเล็บเปลี่ยนรูป เช่น "ขม (ยิ้ม)" → ขม:happy
## ชื่อที่ไม่มีรูป (คำบรรยาย · โทรศัพท์) = ไม่ขึ้นรูป · เพิ่มตัวละครได้ที่ _CharacterMap ใน Scene/Global.tscn
## (แยกชื่อ/อารมณ์ทำตอนอ่านไฟล์ใน DialogToken.from_raw — ดู MOOD_WORDS ที่นั่น)
const PORTRAIT_SCALE := 0.85
var _recent: Array[CharacterSprite] = [] # คนพูดล่าสุดอยู่ท้าย


## โชว์ได้ทีละ 2 คน (ซ้าย/ขวา) ไม่ซ้อนกัน · คนที่ 3 มาแทนคนที่ไม่ได้พูดนานสุด
func _show_speaker(token: DialogToken) -> void:
	var base := token.name
	if not Global.hasCharacter(base):
		return
	var mood_key := base + ":" + token.mood
	var tex = Global.getCharacterTexture(mood_key if token.mood != "" and Global.hasCharacter(mood_key) else base)
	_recent = _recent.filter(
		func(c):
			return is_instance_valid(c) and not c.is_queued_for_deletion(),
	)
	for n in ShowSprites.get_children():
		if n is CharacterSprite and n.name == base.validate_node_name() and not n.is_queued_for_deletion():
			curSprite = n
	if curSprite == null:
		var slot := 0
		if _recent.size() >= 2:
			var old: CharacterSprite = _recent.pop_front()
			slot = old.get_meta("slot", 0)
			ShowSprites.remove_child(old)
			old.queue_free()
		elif _recent.size() == 1:
			slot = 1 - int(_recent[0].get_meta("slot", 0))
		curSprite = Global.getCharacterSprite(base)
		curSprite.set_meta("slot", slot)
		curSprite.scale = Vector2.ONE * PORTRAIT_SCALE
		ShowSprites.addCharacterSprite(curSprite, slot)
	_recent.erase(curSprite)
	_recent.append(curSprite)
	curSprite.texture = tex
	curSprite.highlight()


func create_choice_buttons(choices: Array) -> void:
	for choice in choices:
		var button = choiceButton.instantiate()
		button.get_choice.connect(click_choice)
		button.text = choice
		ChoiceContainer.add_child(button)


# Advances the cursor one line, popping any finished branches off the stack
# so we return to the parent dialog. Returns false when the whole dialog ends.
func advance_index() -> bool:
	index_stack[-1] += 1
	while index_stack.size() > 0 and index_stack[-1] >= current_dialog.size():
		index_stack.pop_back()
		dialog_stack.pop_back()
		if dialog_stack.size() == 0:
			return false
		current_dialog = DialogDict[dialog_stack[-1]]
	return true


func next_text() -> void:
	if curSprite != null:
		curSprite.fade()

	if not advance_index():
		dialog_end()
		return

	# prints(index_stack)
	show_text(current_dialog[index_stack[-1]])


# NOTE: maybe this is a signal
func dialog_end() -> void:
	on_dialog_finish.emit()
	Global.hideDialog()
	self.visible = false
	DialogDict.clear()
	index_stack.clear()
	dialog_stack.clear()
	DialogDict[DIALOG] = []
	ShowSprites.reset()
	_recent.clear()


func click_choice(button: Button) -> void:
	var select_Choice = button.text
	skip_btn.disabled = false

	index_stack[-1] += 1
	index_stack.append(0)
	dialog_stack.append(select_Choice)
	current_dialog = DialogDict[dialog_stack[-1]]

	show_text(current_dialog[index_stack[-1]])
	ChoiceContainer.visible = false
	for i in ChoiceContainer.get_children():
		i.queue_free()


func _on_skip_pressed() -> void:
	# Fast-forward through dialog lines (across branches) until we reach a
	# choice or the dialog ends. Each line is rendered through show_text, so
	# the line right before a choice stays visible as its prompt.
	while true:
		if curSprite != null:
			curSprite.fade()

		if not advance_index():
			dialog_end()
			break

		var token = current_dialog[index_stack[-1]]
		show_text(token)
		if token is ChoiceToken:
			break
