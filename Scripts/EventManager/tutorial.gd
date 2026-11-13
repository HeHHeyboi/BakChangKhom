class_name Tutorial extends CanvasLayer

enum TutorialState {
	BASIC_START,
	BASIC_HOME,
	RAM_CLEANING,
	MOTHERBOARD,
	GPU,
	FRONT_PANEL,
	BIOS,
}

@export var TutorialSlide: Dictionary[TutorialState, TutorialSlides]:
	set(value):
		_slides = value
@export var test = false
@onready var slide_show = $"Control/Slide" as TextureRect
@onready var next_btn = $"Control/Next" as Button
@onready var prev_btn = $"Control/Previous" as Button
@onready var caption = get_node_or_null("Control/Caption") as Label

var tutorial_seen: Dictionary[TutorialState, bool] = { }

var _slides = { }
var cur_slide: TutorialSlides = null
var _finished = false

signal on_tutorial_end


func _ready() -> void:
	_build_skip()
	_layout_buttons()
	self.visible = false
	self.process_mode = Node.PROCESS_MODE_DISABLED
	if test:
		show_tutorial(TutorialState.BASIC_START)


func show_tutorial(tutor_index: TutorialState) -> void:
	# ตอนนี้มีสไลด์จริงแค่บาง state (BASIC_START, RAM_CLEANING)
	# state ที่ยังไม่มีสไลด์ต้องข้ามไปเงียบ ๆ ไม่ใช่ crash
	if not _slides.has(tutor_index) or _slides[tutor_index] == null:
		push_warning("ยังไม่มีสไลด์ของ TutorialState %d — ข้าม tutorial นี้ไปก่อน" % tutor_index)
		self.visible = false
		self.process_mode = Node.PROCESS_MODE_DISABLED
		on_tutorial_end.emit()
		return

	self.visible = true
	self._finished = false
	self.process_mode = Node.PROCESS_MODE_INHERIT
	cur_slide = _slides[tutor_index]
	cur_slide.reset()
	slide_show.texture = cur_slide.get_cur_slide()


func _process(_delta: float) -> void:
	if cur_slide == null:
		return

	if caption:
		caption.text = cur_slide.get_caption()
	if cur_slide.curIndex == 0:
		prev_btn.disabled = true
	else:
		prev_btn.disabled = false

	if cur_slide.is_finish():
		next_btn.text = "เข้าใจแล้ว"
		_finished = true
	else:
		next_btn.text = "ถัดไป"
		_finished = false


func _on_next_btn_pressed():
	if _finished:
		on_tutorial_end.emit()
		self.visible = false
		self.process_mode = Node.PROCESS_MODE_DISABLED
		return
	var slide = cur_slide.get_next_slide()
	if slide == null:
		return

	slide_show.texture = slide
	pass


## [Claude 5 ต.ค. 2569] ปุ่ม "ข้าม" มุมขวาบน — จบสไลด์ชุดนี้ทันที (เหมือนกด "เข้าใจแล้ว")
func _build_skip() -> void:
	var b := Button.new()
	b.name = "Skip"
	b.text = "ข้าม ►"
	b.focus_mode = Control.FOCUS_NONE
	b.text = "ข้าม"
	b.pressed.connect(skip)
	var root := get_node_or_null(^"Control")
	if root == null:
		push_warning("Tutorial: ไม่พบโหนด Control — ไม่มีปุ่มข้าม")
		b.free()
		return
	root.add_child(b)


## [Claude 13 พ.ย. 2569] ปุ่ม ย้อนกลับ · ข้าม · ถัดไป เรียงกลางแถบล่าง ขนาดเท่ากัน (เดิมแยกซ้าย/กลาง/ขวา ปุ่มข้ามเล็กกว่าเพื่อน)
const BUTTON_SIZE := Vector2(230, 58)
const BUTTON_FONT := 26


func _layout_buttons() -> void:
	var root := get_node_or_null(^"Control") as Control
	if root == null:
		return
	var row := HBoxContainer.new()
	row.name = "ButtonRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.anchor_left = 0.0
	row.anchor_right = 1.0
	row.offset_left = 0.0
	row.offset_right = 0.0
	row.offset_top = -BUTTON_SIZE.y - 6.0
	row.offset_bottom = -6.0
	root.add_child(row)
	for n in [&"Previous", &"Skip", &"Next"]:
		var b := root.get_node_or_null(NodePath(n)) as Button
		if b == null:
			continue
		root.remove_child(b)
		b.set_anchors_preset(Control.PRESET_TOP_LEFT)
		b.custom_minimum_size = BUTTON_SIZE
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", BUTTON_FONT)
		row.add_child(b)


func skip() -> void:
	if not visible:
		return
	on_tutorial_end.emit()
	self.visible = false
	self.process_mode = Node.PROCESS_MODE_DISABLED


func _on_prev_btn_pressed():
	var slide = cur_slide.get_prev_slide()
	if slide == null:
		return
	slide_show.texture = slide
