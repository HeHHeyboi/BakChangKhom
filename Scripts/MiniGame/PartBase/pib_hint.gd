# Scripts/MiniGame/PartBase/pib_hint.gd
## ปิ๊บผู้ช่วย แนวนกใน Volcano Princess — ลอยขึ้นมาจากมุมซ้ายล่างพร้อมกล่องคำพูดทุกครั้งที่ให้ข้อมูล
## หน้าตาเปลี่ยนตามอารมณ์ (Mood) · ตัวหนังสือขึ้นทีละตัว · ลอยขึ้นลงเบา ๆ ตลอดเวลาที่อยู่บนจอ
## [Claude 1 ต.ค. 2569] เดิมเป็นแถบข้อความเฉย ๆ ไม่มีตัวปิ๊บ
class_name PibHint extends CanvasLayer
@onready var dialog_panel = $DialogPanel as Button
@onready var pib_sprite = $DialogPanel/Pib as TextureRect
@onready var bubble = $DialogPanel/Bubble as Control
@onready var name_label = $DialogPanel/Bubble/Name as Label
@onready var dialog_label = $DialogPanel/Bubble/Dialog as Label # [Claude 2 ต.ค.] เดิม RichTextLabel — ดูหมายเหตุใน dialog_scene.gd
@onready var next_mark = $DialogPanel/Bubble/Next as Label
@onready var toast_box = $Toast as Control
@onready var toast_pib = $Toast/Pib as TextureRect
@onready var toast_text = $Toast/Bubble/Text as Label
@onready var timer = $Timer as Timer
enum Mood {
	NORMAL,
	HAPPY,
	WORRY,
	POINT,
}

## รูปปิ๊บของแต่ละอารมณ์ — เปลี่ยนรูปได้ใน Inspector ของ pib_hint.tscn
@export var mood_textures: Dictionary[Mood, Texture2D] = { }
## ตัวอักษรต่อวินาที (0 = ขึ้นทั้งบรรทัดทันที)
@export var chars_per_sec := 45.0

## connect from Godot's Editor
signal line_finished
## connect from Godot's Editor
signal all_lines_finished

const DEFAULT_SPEAKER := "ปิ๊บ"
const BOB_HEIGHT := 6.0 # ลอยขึ้นลงกี่พิกเซล
const BOB_SPEED := 2.4
var cur_dialog: Array[DialogToken] = []
var _pib_home_y := 0.0
var _toast_home_y := 0.0
var _t := 0.0
var _type_tw: Tween
var _pop_tw: Tween
var _closing := false # กำลังลอยลง (ยังเห็นอยู่แต่กำลังจะซ่อน)


func _ready() -> void:
	_pib_home_y = pib_sprite.position.y
	_toast_home_y = toast_pib.position.y
	pib_sprite.pivot_offset = Vector2(pib_sprite.size.x / 2.0, pib_sprite.size.y)
	toast_box.hide()
	# เริ่มต้นซ่อนเสมอ ไม่ขึ้นกับค่า visible ที่เซฟใน .tscn
	dialog_panel.hide()
	hide()


func _process(delta: float) -> void:
	_t += delta
	var bob := sin(_t * BOB_SPEED) * BOB_HEIGHT
	if dialog_panel.visible and (_pop_tw == null or not _pop_tw.is_running()):
		pib_sprite.position.y = _pib_home_y + bob
	if toast_box.visible:
		toast_pib.position.y = _toast_home_y + bob * 0.6


func _create_dialog(lines: Array):
	for line in lines:
		var token: DialogToken
		if line is DialogToken:
			token = line
		elif line is String:
			token = DialogToken.new(DEFAULT_SPEAKER, line)
		else:
			push_error("PibHint.say: element of type %s cannot convert to DialogToken" % type_string(typeof(line)))
			return
		cur_dialog.append(token)


func _typing() -> bool:
	return _type_tw != null and _type_tw.is_running()


func _on_dialog_panel_pressed() -> void:
	# กำลังพิมพ์อยู่ → คลิกครั้งแรกให้ขึ้นครบทั้งบรรทัดก่อน
	if _typing():
		_type_tw.kill()
		dialog_label.visible_ratio = 1.0
		next_mark.show()
		return
	if cur_dialog.is_empty():
		_pop_out()
		all_lines_finished.emit()
		return
	_show_line(cur_dialog.pop_front())
	line_finished.emit()


## พูดต่อเนื่องหลายบรรทัด — ผู้เล่นคลิกเพื่อไปบรรทัดถัดไป
## รับ Array ของ String หรือ DialogToken ปนกันได้
func say(lines: Array, mood: Mood = Mood.NORMAL) -> void:
	_create_dialog(lines)
	if cur_dialog.is_empty():
		return
	_set_mood(pib_sprite, mood)
	# [Claude 1 ต.ค.] บทใหม่มาระหว่างกำลังลอยลง (phase ถัดไปพูดต่อทันที) → ยกเลิกการซ่อน แล้วลอยขึ้นใหม่
	#   เดิมตัวซ่อนทำงานทีหลังแล้วซ่อนบทใหม่ไปด้วย ผู้เล่นเลยไม่เห็นกล่องให้กด
	var was_open: bool = visible and dialog_panel.visible and not _closing
	if _closing and _pop_tw:
		_pop_tw.kill()
	_closing = false
	self.show()
	dialog_panel.show()
	if not was_open:
		_pop_in()
	_show_line(cur_dialog.pop_front())


func _show_line(t: DialogToken) -> void:
	name_label.text = t.name
	dialog_label.text = t.dialog
	next_mark.hide()
	# ปิ๊บเด้งนิดหนึ่งทุกครั้งที่เริ่มพูดบรรทัดใหม่
	var sq := create_tween()
	sq.tween_property(pib_sprite, "scale", Vector2(1.06, 0.94), 0.07)
	sq.tween_property(pib_sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _type_tw:
		_type_tw.kill()
	var n := dialog_label.get_total_character_count()
	if chars_per_sec <= 0.0 or n == 0:
		dialog_label.visible_ratio = 1.0
		next_mark.show()
		return
	dialog_label.visible_ratio = 0.0
	_type_tw = create_tween()
	_type_tw.tween_property(dialog_label, "visible_ratio", 1.0, n / chars_per_sec)
	_type_tw.tween_callback(next_mark.show)


## ลอยขึ้นจากขอบล่าง + กล่องคำพูดขยายออก
func _pop_in() -> void:
	if _pop_tw:
		_pop_tw.kill()
	pib_sprite.position.y = _pib_home_y + 220.0
	bubble.pivot_offset = Vector2(0, bubble.size.y)
	bubble.scale = Vector2(0.6, 0.6)
	bubble.modulate.a = 0.0
	_pop_tw = create_tween().set_parallel()
	_pop_tw.tween_property(pib_sprite, "position:y", _pib_home_y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	_pop_tw.tween_property(bubble, "scale", Vector2.ONE, 0.25).set_delay(0.12).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	_pop_tw.tween_property(bubble, "modulate:a", 1.0, 0.15).set_delay(0.12)


## ลอยลงหายไป (ไม่ต้องรอ — เกมเดินต่อได้ทันที)
func _pop_out() -> void:
	if _pop_tw:
		_pop_tw.kill()
	_closing = true
	_pop_tw = create_tween().set_parallel()
	_pop_tw.tween_property(bubble, "modulate:a", 0.0, 0.12)
	_pop_tw.tween_property(pib_sprite, "position:y", _pib_home_y + 220.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_IN
	)
	_pop_tw.chain().tween_callback(_after_pop_out)


func _after_pop_out() -> void:
	_closing = false
	dialog_panel.hide()
	if not toast_box.visible:
		hide()


func _set_mood(rect: TextureRect, mood: Mood) -> void:
	var tex: Texture2D = mood_textures.get(mood, mood_textures.get(Mood.NORMAL))
	if tex:
		rect.texture = tex


## พูดบรรทัดเดียวแล้วหายไปเองใน N วินาที (ใช้ตอนเตือนระหว่างเล่น) — ปิ๊บตัวเล็กโผล่ข้างจอ ไม่บังการคลิก
func toast(line: DialogToken, seconds: float = 3.0, mood: Mood = Mood.WORRY) -> void:
	self.show()
	_set_mood(toast_pib, mood)
	toast_text.text = line.dialog
	var fresh: bool = not toast_box.visible
	toast_box.show()
	if fresh:
		toast_box.position.x = -toast_box.size.x
		create_tween().tween_property(toast_box, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(
			Tween.EASE_OUT
		)
	timer.wait_time = seconds
	timer.one_shot = true
	timer.start()


## ชี้ไปที่ node เป้าหมาย (วาดลูกศรจากปิ๊บไปยัง target)
func point_at(target: Node2D, line: String) -> void:
	pass


func _on_timer_timeout() -> void:
	# ซ่อนทั้ง layer เฉพาะตอนกล่องคำพูดปิดอยู่ — ไม่งั้นบทที่กำลังพูดจะหายไปด้วย
	var tw := create_tween()
	tw.tween_property(toast_box, "position:x", -toast_box.size.x, 0.2).set_ease(Tween.EASE_IN)
	tw.tween_callback(_after_toast)


func _after_toast() -> void:
	toast_box.hide()
	if not dialog_panel.visible:
		hide()


class Data extends RefCounted:
	enum Act {
		SAY,
		TOAST,
		POINT_AT,
	}

	var type: Act
	var header: String
	var mood: PibHint.Mood
	var seconds: float
	var target: Node2D


	static func say(p_header: String, p_mood: Mood = Mood.NORMAL) -> Data:
		var p = Data.new()
		p.type = Act.SAY
		p.header = p_header
		p.mood = p_mood
		return p


	static func toast(p_header: String, p_seconds: float = 3.0, p_mood: Mood = Mood.WORRY) -> Data:
		var p = Data.new()
		p.type = Act.TOAST
		p.header = p_header
		p.mood = p_mood
		p.seconds = p_seconds
		return p
