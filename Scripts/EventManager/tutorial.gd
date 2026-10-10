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
	b.add_theme_font_size_override("font_size", 20)
	b.position = Vector2(496, 594) # [10 ต.ค.] แถบล่างกลาง (สไลด์ย่อลงไม่ให้ปุ่มบังรูป)
	b.custom_minimum_size = Vector2(160, 50)
	b.pressed.connect(skip)
	var root := get_node_or_null(^"Control")
	if root == null:
		push_warning("Tutorial: ไม่พบโหนด Control — ไม่มีปุ่มข้าม")
		b.free()
		return
	root.add_child(b)


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
