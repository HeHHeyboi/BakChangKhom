class_name PowerCheckMinigame extends Control
## มินิเกม "ตรวจเครื่องเบื้องต้น" — คอมเก่าในห้องขมเปิดไม่ติด → ไล่เช็คของง่ายก่อน แล้วฟังเสียงบี๊บ
## ขั้น: เสียบปลั๊ก → เปิดสวิตช์ปลั๊กพ่วง → เปิดสวิตช์ PSU หลังเครื่อง → กดเปิดเครื่อง → ฟังบี๊บ (สั้น 3 = แรม) → ตอบ
## ทำสลับลำดับได้ · กดเปิดเครื่องตอนไฟยังไม่เข้า = เงียบ + ขมบอกว่าขาดอะไร (นับ mistakes ไว้ ไม่ตัดคะแนน)
## แทนมินิเกมหายางลบ (เควสต์หลักขั้น 3 · Resources/main.tres) · ภาพ Assets/MiniGame/PowerCheck/ (src/gen_power.py)
## [Claude 10 ต.ค. 2569]

signal finished(mistakes: int)

## ข้อความตอนเริ่ม
@export_multiline var intro_text := "เครื่องเปิดไม่ติด… ช่างเขาสอนว่าให้เช็คของง่าย ๆ ก่อน เริ่มจากไฟเข้าเครื่องไหม"
## ตำแหน่งปลั๊กตอนเสียบแล้ว (พิกัดจอ)
@export var plug_in_pos := Vector2(765, 520)

const C_DONE := Color(0.25, 0.55, 0.2)
const C_TODO := Color(0.23, 0.16, 0.11)
const C_WARN := Color(0.85, 0.3, 0.1)
const TEX := "res://Assets/MiniGame/PowerCheck/"

var plugged := false
var strip_on := false
var psu_on := false
var powered := false
var answered := false
var mistakes := 0
var _beeping := false

@onready var plug: TextureButton = $Plug
@onready var strip_switch: TextureButton = $Strip/StripSwitch
@onready var psu_switch: TextureButton = $PcBack/PsuSwitch
@onready var power_button: TextureButton = $Front/PcFront/PowerButton
@onready var led: Panel = $Front/PcFront/Led
@onready var fan: TextureRect = $PcBack/Fan
@onready var cable: Line2D = $Cable
@onready var inlet: Control = $PcBack/Inlet
@onready var say_label: Label = $Bubble/Text
@onready var steps: VBoxContainer = $Checklist/Box/Steps
@onready var beep_fx: Label = $Front/BeepFx
@onready var quiz: PanelContainer = $Quiz
@onready var answers: VBoxContainer = $Quiz/Box/Answers
@onready var quiz_text: Label = $Quiz/Box/Question
@onready var done_button: Button = $Quiz/Box/Done
@onready var replay_button: Button = $Quiz/Box/Replay


func _ready() -> void:
	plug.pressed.connect(_on_plug)
	strip_switch.pressed.connect(_on_strip)
	psu_switch.pressed.connect(_on_psu)
	power_button.pressed.connect(_on_power)
	replay_button.pressed.connect(play_beep)
	done_button.pressed.connect(finish)
	for b in answers.get_children():
		if b is Button:
			b.pressed.connect(_on_answer.bind(b))
	quiz.hide()
	done_button.hide()
	beep_fx.hide()
	fan.pivot_offset = fan.size / 2.0
	_refresh()
	say(intro_text)


func _process(delta: float) -> void:
	if powered:
		fan.rotation += delta * 14.0
	cable.points = PackedVector2Array([_inlet_point(), _inlet_point() + Vector2(100, 0), # [10 ต.ค.] PSU อยู่ล่าง → สายออกด้านข้าง ไม่ทับสวิตช์
		 plug.position + Vector2(plug.size.x / 2.0, plug.size.y), plug.position + Vector2(plug.size.x / 2.0, plug.size.y - 8)])


func _inlet_point() -> Vector2:
	return inlet.global_position + inlet.size / 2.0 - global_position


func say(text: String) -> void:
	say_label.text = text


## ทุกอย่างพร้อมให้ไฟเข้าเครื่องไหม
func is_ready() -> bool:
	return plugged and strip_on and psu_on


func _on_plug() -> void:
	if plugged or powered:
		return
	plugged = true
	var tw := create_tween()
	tw.tween_property(plug, "position", plug_in_pos, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	say("เสียบปลั๊กเข้าปลั๊กพ่วงแล้ว — ปลั๊กหลุดอยู่จริง ๆ ด้วย")
	_sfx(&"pop")
	_refresh()


func _on_strip() -> void:
	if powered:
		return
	strip_on = not strip_on
	say("เปิดสวิตช์ปลั๊กพ่วงแล้ว ไฟแดงติด" if strip_on else "ปิดสวิตช์ปลั๊กพ่วง")
	_sfx(&"click")
	_refresh()


func _on_psu() -> void:
	if powered:
		return
	psu_on = not psu_on
	say("สวิตช์หลังพาวเวอร์ซัพพลายอยู่ที่ O (ปิด) — เปลี่ยนเป็น I (เปิด) แล้ว" if psu_on else "ปิดสวิตช์หลังเครื่อง (O)")
	_sfx(&"click")
	_refresh()


func _on_power() -> void:
	if powered:
		return
	if not is_ready():
		mistakes += 1
		var missing := 0 if not plugged else (1 if not strip_on else 2)
		say(["กดแล้วเงียบ… ปลั๊กยังไม่ได้เสียบเลย ดูที่พื้นสิ", "กดแล้วเงียบ… สวิตช์ปลั๊กพ่วงยังปิดอยู่", "กดแล้วเงียบ… สวิตช์หลังเครื่อง (PSU) ยังเป็น O อยู่"][missing])
		_flash_step(missing)
		return
	powered = true
	led.modulate = Color(0.3, 1.0, 0.35)
	say("ไฟเข้าแล้ว! พัดลมหมุน… แต่จอไม่ขึ้น แล้วมีเสียงบี๊บ ฟังดี ๆ")
	_refresh()
	await play_beep()
	_show_quiz()


## เล่นเสียงบี๊บรหัส POST แรมเสีย (สั้น 3 × 3 รอบ) + ป้าย "บี๊บ!" กระพริบตามจังหวะ
func play_beep() -> void:
	if _beeping:
		return
	_beeping = true
	replay_button.disabled = true
	_sfx(&"beep_ram")
	beep_fx.show()
	beep_fx.pivot_offset = beep_fx.size / 2.0
	beep_fx.scale = Vector2.ONE * 0.6
	var tw := create_tween()
	for g in 3:
		for k in 3:
			tw.tween_property(beep_fx, "scale", Vector2.ONE * 1.2, 0.08)
			tw.tween_property(beep_fx, "scale", Vector2.ONE * 0.6, 0.26)
		tw.tween_interval(0.6)
	await tw.finished
	beep_fx.hide()
	replay_button.disabled = false
	_beeping = false


func _show_quiz() -> void:
	quiz.show()
	quiz_text.text = "บี๊บสั้น 3 ครั้ง (ดังซ้ำ 3 รอบ) แปลว่าอะไร?"


func _on_answer(b: Button) -> void:
	if answered:
		return
	match String(b.name):
		"Ram":
			answered = true
			for x in answers.get_children():
				(x as Button).disabled = true
			quiz_text.text = "ถูกต้อง! บี๊บสั้น 3 ครั้ง = หน่วยความจำ (แรม) มีปัญหา\nแรมที่ทิ้งไว้นานมักมีฝุ่น/ขาสนิม ถอดมาทำความสะอาดก่อน"
			say("แรมนี่เอง… ต้องถอดแรมออกมาขัด แต่ก่อนลงมือ ไปทบทวนชิ้นส่วนในคอมกับปิ๊บก่อนดีกว่า")
			replay_button.hide()
			done_button.show()
			_sfx(&"success")
			_refresh()
		"Gpu":
			mistakes += 1
			quiz_text.text = "ยังไม่ใช่ — การ์ดจอเสียมักเป็น ยาว 1 สั้น 2 · ลองฟังอีกครั้ง"
		"Power":
			mistakes += 1
			quiz_text.text = "ยังไม่ใช่ — ถ้าไฟไม่เข้า พัดลมจะไม่หมุนและไม่มีเสียงเลย แต่ตอนนี้ไฟ LED ติดแล้ว"


func finish() -> void:
	finished.emit(mistakes)
	Global.in_minigame = false
	if get_node_or_null(^"/root/EventManager") and get_parent() and get_parent().name == "overlay":
		EventManager.minigame_end()
	else:
		queue_free()


func _refresh() -> void:
	strip_switch.texture_normal = load(TEX + ("strip_sw_on.png" if strip_on else "strip_sw_off.png"))
	psu_switch.texture_normal = load(TEX + ("psu_sw_on.png" if psu_on else "psu_sw_off.png"))
	if not powered:
		led.modulate = Color(0.35, 0.35, 0.35)
	var done := [plugged, strip_on, psu_on, powered, answered]
	for i in steps.get_child_count():
		var l := steps.get_child(i) as Label
		var base := String(l.get_meta(&"text", l.text))
		l.set_meta(&"text", base)
		l.text = "%d. %s%s" % [i + 1, base, "  ✔" if done[i] else ""]
		l.add_theme_color_override("font_color", C_DONE if done[i] else C_TODO)


func _flash_step(i: int) -> void:
	var l := steps.get_child(i) as Label
	l.add_theme_color_override("font_color", C_WARN)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(_refresh)


func _sfx(n: StringName) -> void:
	if has_node(^"/root/Audio"):
		get_node(^"/root/Audio").sfx(n)
