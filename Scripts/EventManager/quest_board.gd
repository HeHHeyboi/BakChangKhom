class_name QuestBoard extends CanvasLayer
## การ์ด "เป้าหมาย" มุมขวาบน (ชั้น 100 เท่า HUD) · [Claude 13 พ.ย. 2569] ออกแบบใหม่ให้เข้ากับ HUD ซ้ายบน
##   เดือนนี้ — เป้ากำไรของเดือน (✔ เมื่อถึง) + เทศกาลของเดือน · โชว์เฉพาะตอนเปิดร้านแล้ว (ลูปร้าน)
##   เควสต์ — งานเนื้อเรื่องจาก EventManager (update_task) · "☐ คุยกับยาย"
## ย่อ = เหลือหัวการ์ด "เป้าหมาย (n)" · กด "ซ่อน" หรือปุ่ม Q

@export var QuestList: Node
## ปุ่มย่อ/ขยาย (กด Q ก็ได้)
@export var ToggleButton: Button
## ความถี่อัปเดตเป้าเดือน (วินาที) — อ่านจาก GameState/TimeSystem ตรง ๆ ไม่ต้องต่อสัญญาณ
@export var refresh_interval := 0.5

const COL_TODO := Color(0.96, 0.96, 0.96)
const COL_DONE := Color(0.55, 0.85, 0.55)

## true = ย่ออยู่ (เห็นแค่หัว)
var collapsed := false

var _event_map: Dictionary[Event, Label] = { }
var _t := 0.0

@onready var _panel: PanelContainer = $PanelContainer
@onready var _title: Label = %Title
@onready var _body: Control = %Body
@onready var _month_box: Control = %MonthBox
@onready var _month_head: Label = %MonthHead
@onready var _month_goal: Label = %MonthGoal
@onready var _month_sub: Label = %MonthSub
@onready var _month_event: Label = %MonthEvent
@onready var _sep: Control = %Sep
@onready var _quest_head: Control = %QuestHead


func update_task(text: String, event: Event) -> void:
	if _event_map.has(event):
		var label = _event_map.get(event)
		if text == "":
			_event_map.erase(event)
			label.queue_free()
		else:
			label.text = "☐ " + text
	elif text != "":
		var label = Label.new()
		label.text = "☐ " + text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", COL_TODO)
		QuestList.add_child(label)
		_event_map.set(event, label)
	_relayout.call_deferred()


func _ready() -> void:
	var icon := %Icon as TextureRect
	if icon:
		icon.texture = Icons.tex(&"clipboard")
	if ToggleButton:
		ToggleButton.pressed.connect(toggle)
	set_collapsed(collapsed)
	refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _t >= refresh_interval:
		_t = 0.0
		refresh()


func toggle() -> void:
	set_collapsed(not collapsed)


func set_collapsed(on: bool) -> void:
	collapsed = on
	if ToggleButton:
		ToggleButton.text = "แสดง" if on else "ซ่อน"
	_relayout()


## จำนวนเควสต์ที่ยังค้าง
func quest_count() -> int:
	var n := 0
	for e in _event_map:
		if is_instance_valid(_event_map[e]):
			n += 1
	return n


## ขอบล่างของการ์ด (พิกัดจอ) — DayLoop ใช้วางปุ่ม "ดูการ์ดงาน" ต่อใต้การ์ด
func bottom_y() -> float:
	if not visible or _panel == null:
		return 0.0
	return _panel.position.y + _panel.size.y


func refresh() -> void:
	if not is_node_ready():
		return
	var show_month := _shop_open()
	_month_box.visible = show_month
	if show_month:
		_fill_month()
	_relayout()


func _fill_month() -> void:
	var ts = _ts()
	if ts == null or not has_node(^"/root/GameState"):
		return
	var m: int = ts.month()
	var target := maxi(GameState.target_of(m), 1)
	var profit := GameState.month_profit(m)
	var reached := profit >= target
	_month_head.text = "เดือน %s" % TimeSystem.MONTH_FULL[clampi(m, 1, 12) - 1]
	if reached:
		_month_goal.text = "✔  กำไรถึงเป้า %s แล้ว" % MonthGoalBar._baht(target)
		_month_goal.add_theme_color_override("font_color", COL_DONE)
	else:
		_month_goal.text = "☐  ทำกำไรให้ถึง %s" % MonthGoalBar._baht(target)
		_month_goal.add_theme_color_override("font_color", COL_TODO)
	var left: int = ts.days_left_in_month()
	var tail := ("เหลือ %d วันเปิดร้าน" % left) if left > 0 else "วันสุดท้ายของเดือน"
	_month_sub.text = "ตอนนี้ %s · %s" % [MonthGoalBar._baht(profit), tail]
	var ev: Dictionary = GameState.economy.month_event(m) if GameState.economy else { }
	var name: String = ev.get("name", "")
	_month_event.visible = name != ""
	if name != "":
		_month_event.text = "เทศกาล: " + name
		_month_event.tooltip_text = ev.get("note", "")


func _relayout() -> void:
	if not is_node_ready():
		return
	var quests := quest_count() > 0
	var month := _month_box.visible
	_body.visible = not collapsed and (quests or month)
	_quest_head.visible = quests
	QuestList.visible = not collapsed
	_sep.visible = quests and month
	var n := quest_count() + (1 if month else 0)
	_title.text = "เป้าหมาย (%d)" % n if collapsed and n > 0 else "เป้าหมาย"
	# ไม่มีอะไรเลย (เช่นหน้าเมนู/ช่วงไม่มีเควสต์ก่อนเปิดร้าน) → ซ่อนทั้งการ์ด
	_panel.visible = quests or month
	_shrink.call_deferred()


## การ์ดสูงพอดีเนื้อหา (Label ตัดบรรทัดคิดความสูงจริงได้หลังรู้ความกว้าง → ย่อซ้ำเฟรมถัดไป)
func _shrink() -> void:
	if _panel == null:
		return
	_panel.size = Vector2(_panel.size.x, 0)
	_panel.offset_bottom = _panel.offset_top + _panel.get_combined_minimum_size().y


func _shop_open() -> bool:
	if not has_node(^"/root/DayLoop"):
		return false
	var dl = get_node(^"/root/DayLoop")
	return dl.has_method("_loop_active") and dl._loop_active()


func _ts():
	var em = get_parent()
	return em.time_system if em and "time_system" in em else null


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q and not Global.in_minigame:
		toggle()
		get_viewport().set_input_as_handled()
