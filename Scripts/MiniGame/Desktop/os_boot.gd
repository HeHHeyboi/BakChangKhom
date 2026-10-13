class_name OsBoot extends Control
## จอเปิดเครื่องของขมOS แบบคอมจริง: 1) จอ POST ของ BIOS → 2) โลโก้ขมOS + จุดหมุน "กำลังเริ่มต้น" → 3) หน้าลงชื่อเข้าใช้ → เดสก์ท็อป
## หน้าตาเลียนลำดับการเปิดเครื่องของ Windows แต่ใช้โลโก้/ชื่อของเกมเอง (โลโก้ Windows เป็นเครื่องหมายการค้า ใช้ไม่ได้)
## โหนดทั้งหมดอยู่ใน Scene/MiniGame/Desktop/os_boot.tscn — แก้ข้อความ/สี/ตำแหน่งใน Inspector · คลิกที่ไหนก็ได้ = ข้ามขั้นนั้น
## DesktopMinigame._build_boot() สร้างให้ · จบแล้วยิง finished · [Claude 13 ต.ค. 2569]

signal finished

## เริ่มเล่นเองตอนเข้าซีน (ในซีนนี้ปิดไว้ — DesktopMinigame เรียก play() เอง เพราะวางเป็นโหนด Boot ใน desktop_window.tscn)
@export var autoplay := false

## ข้อความจอ POST ทีละบรรทัด
@export var post_lines: PackedStringArray = [
	"ตรวจซีพียู ............ ผ่าน",
	"ตรวจแรม 8192 MB ....... ผ่าน",
	"ตรวจ SSD 256 GB ....... ผ่าน",
	"ตรวจคีย์บอร์ด/เมาส์ ..... ผ่าน",
	"",
	"บี๊บ! (สั้น 1 ครั้ง = ปกติ)",
]
@export var post_line_delay := 0.2
## โชว์โลโก้ + จุดหมุนกี่วินาที
@export var logo_seconds := 1.8
## หน้าลงชื่อเข้าใช้ (ปิด = โลโก้จบแล้วเข้าเดสก์ท็อปเลย)
@export var show_login := true
## หน้าลงชื่อเข้าใช้เข้าเองหลังกี่วินาที (0 = ต้องกดปุ่ม)
@export var login_auto_seconds := 2.5

@onready var post: Control = %Post
@onready var post_text: Label = %PostText
@onready var logo: Control = %Logo
@onready var login: Control = %Login
@onready var clock: Label = %Clock
@onready var date_label: Label = %Date
@onready var sign_in: Button = %SignIn
@onready var welcome: Label = %Welcome

var _stage := 0
var _tw: Tween
var _done := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	sign_in.pressed.connect(_sign_in)
	if autoplay:
		play()


## เริ่มลำดับเปิดเครื่องใหม่ตั้งแต่จอ POST
func play() -> void:
	_done = false
	_stage = 0
	modulate.a = 1.0
	show()
	sign_in.show()
	post.show()
	logo.hide()
	login.hide()
	welcome.hide()
	post_text.text = ""
	_fill_clock()
	_run_post()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_next_stage()


## ข้ามไปขั้นถัดไป (คลิก) · ขั้นสุดท้าย = จบ
func _next_stage() -> void:
	match _stage:
		0:
			_run_logo()
		1:
			_run_login() if show_login else _finish()
		_:
			_sign_in()


## ข้ามทั้งหมด (DesktopMinigame.skip_boot)
func skip_all() -> void:
	_finish()


func _kill() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()


func _run_post() -> void:
	_stage = 0
	_kill()
	_tw = create_tween()
	_tw.tween_interval(0.3)
	for line in post_lines:
		_tw.tween_callback(func(): post_text.text += line + "\n")
		_tw.tween_interval(post_line_delay)
	_tw.tween_interval(0.35)
	_tw.tween_callback(_run_logo)


func _run_logo() -> void:
	_stage = 1
	_kill()
	post.hide()
	logo.show()
	logo.modulate.a = 0.0
	_tw = create_tween()
	_tw.tween_property(logo, "modulate:a", 1.0, 0.35)
	_tw.tween_interval(logo_seconds)
	_tw.tween_callback(func(): _run_login() if show_login else _finish())


func _run_login() -> void:
	_stage = 2
	_kill()
	logo.hide()
	login.show()
	login.modulate.a = 0.0
	_fill_clock()
	_tw = create_tween()
	_tw.tween_property(login, "modulate:a", 1.0, 0.3)
	if login_auto_seconds > 0.0:
		_tw.tween_interval(login_auto_seconds)
		_tw.tween_callback(_sign_in)


func _sign_in() -> void:
	if _stage >= 3:
		return
	_stage = 3
	_kill()
	sign_in.hide()
	welcome.show()
	_tw = create_tween()
	_tw.tween_interval(0.6)
	_tw.tween_property(self, "modulate:a", 0.0, 0.3)
	_tw.tween_callback(_finish)


func _finish() -> void:
	if _done:
		return
	_done = true
	_kill()
	finished.emit()


## นาฬิกาบนหน้าลงชื่อเข้าใช้ = เวลาในเกม (ไม่มี = เวลาเครื่อง)
func _fill_clock() -> void:
	var ts = EventManager.time_system if has_node(^"/root/EventManager") else null
	if ts:
		clock.text = TimeSystem.clock_text(ts.current_minute)
		date_label.text = "สัปดาห์ที่ %d · วันที่ %d" % [ts.week(), ts.shift_in_week()]
	else:
		var t := Time.get_time_dict_from_system()
		clock.text = "%02d:%02d" % [t.hour, t.minute]
		date_label.text = ""
