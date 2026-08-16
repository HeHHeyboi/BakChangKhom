class_name Tutorial extends CanvasLayer

enum TutorialState { BASIC_START, BASIC_HOME, RAM_CLEANING, MOTHERBOARD, GPU, FRONT_PANEL, BIOS }

@export var TutorialSlide: Dictionary[TutorialState,TutorialSlides]:
	set(value):
		_slides = value
@export var test = false
@onready var slide_show = $"Control/Slide" as TextureRect
@onready var next_btn = $"Control/Next" as Button
@onready var prev_btn = $"Control/Previous" as Button

var _slides = {}
var cur_slide: TutorialSlides = null
var _finished = false


func _ready() -> void:
	self.visible = false
	self.process_mode = Node.PROCESS_MODE_DISABLED
	if test:
		show_tutorial()


func show_tutorial() -> void:
	self.visible = true
	self.process_mode = Node.PROCESS_MODE_INHERIT
	cur_slide = _slides[TutorialState.BASIC_START]
	slide_show.texture = cur_slide.get_cur_slide()


func _process(delta: float) -> void:
	if cur_slide == null:
		return

	if cur_slide.curIndex == 0:
		prev_btn.disabled = true
	else:
		prev_btn.disabled = false

	if cur_slide.is_finish():
		next_btn.text = "Close"
		_finished = true
	else:
		next_btn.text = "Next"
		_finished = false


func _on_next_btn_pressed():
	if _finished:
		self.visible = false
		self.process_mode = Node.PROCESS_MODE_DISABLED
		return
	var slide = cur_slide.get_next_slide()
	if slide == null:
		return

	slide_show.texture = slide
	pass


func _on_prev_btn_pressed():
	var slide = cur_slide.get_prev_slide()
	if slide == null:
		return
	slide_show.texture = slide
