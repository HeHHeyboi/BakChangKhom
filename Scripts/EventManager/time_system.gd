class_name TimeSystem extends CanvasLayer
## เวลาในเกม — ลูปตาม Docs/GAME_LOOP.md
## 1 วัน = 3 ช่วง (เช้า · เที่ยง · เย็น) · 1 รอบ = 7 วัน = 1 Chapter · ทั้งเกม = 12 รอบ
## [Claude 5 ต.ค. 2569] เปลี่ยนจาก 30 วัน/เดือน เป็น 7 วัน/รอบ · 12 รอบ + สัญญาณ week_ended

const DAYS_PER_WEEK := 7
const TOTAL_WEEKS := 12

## ช่วงเวลาเปลี่ยน (รวมตอนขึ้นวันใหม่ที่กลับเป็นเช้า)
signal period_changed(period: TIME)
## เริ่มวันใหม่ (หลังนอน) — week 1–12 · day 1–7
signal day_started(week: int, day: int)
## ครบ 7 วันของรอบ week · ยิงก่อน day_started ของรอบถัดไป
signal week_ended(week: int)
## ครบ 12 รอบ → ฉากจบ
signal all_weeks_ended

@onready var timeText = $PanelContainer/HBoxContainer/Time as RichTextLabel
@onready var dateText = $PanelContainer/HBoxContainer/Date as RichTextLabel
@export var cur_period = TIME.MORNING

var current_day := 1
var current_week := 1
var finished := false
var _money_label: Label

enum TIME {
	MORNING,
	NOON,
	EVENING,
}


func _enter_tree() -> void:
	EventManager.next_period.connect(change_period)
	EventManager.next_day.connect(change_day)


func _exit_tree() -> void:
	EventManager.next_period.disconnect(change_period)
	EventManager.next_day.disconnect(change_day)


func _ready() -> void:
	updateTime()
	_build_money_label()
	_connect_money.call_deferred()


## เงินของร้านแสดงต่อท้ายวันที่ (GameState เป็น autoload ที่โหลดหลัง EventManager จึงผูกแบบ deferred)
func _build_money_label() -> void:
	var box := $PanelContainer/HBoxContainer as HBoxContainer
	_money_label = Label.new()
	_money_label.name = "Money"
	_money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money_label.size_flags_stretch_ratio = 1.6
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_money_label.add_theme_font_size_override("font_size", 28)
	_money_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	box.add_child(_money_label)
	($PanelContainer as Control).offset_right = 640


func _connect_money() -> void:
	if not has_node("/root/GameState"):
		return
	var gs := get_node("/root/GameState")
	gs.money_changed.connect(_on_money_changed)
	_on_money_changed(gs.money, 0)


func _on_money_changed(money: int, _delta: int) -> void:
	_money_label.text = "฿ %d" % money


## เช้า → เที่ยง → เย็น · เย็นแล้วกดอีกที = จบวัน (นอน)
func change_period() -> void:
	if finished:
		return
	match cur_period:
		TIME.MORNING:
			cur_period = TIME.NOON
		TIME.NOON:
			cur_period = TIME.EVENING
		TIME.EVENING:
			change_day()
			return
	updateTime()
	period_changed.emit(cur_period)


## จบวัน → วันถัดไปช่วงเช้า · ครบ 7 วันยิง week_ended · ครบ 12 รอบยิง all_weeks_ended
func change_day() -> void:
	if finished:
		return
	cur_period = TIME.MORNING
	if current_day >= DAYS_PER_WEEK:
		var ended := current_week
		if current_week >= TOTAL_WEEKS:
			finished = true
			updateTime()
			week_ended.emit(ended)
			all_weeks_ended.emit()
			return
		current_day = 1
		current_week += 1
		updateTime()
		week_ended.emit(ended)
	else:
		current_day += 1
		updateTime()
	period_changed.emit(cur_period)
	day_started.emit(current_week, current_day)


func set_period(time: TIME) -> void:
	cur_period = time
	updateTime()
	period_changed.emit(cur_period)


## ใช้ตอนโหลดเซฟ / debug
func set_date(week: int, day: int, period: TIME = TIME.MORNING) -> void:
	current_week = clampi(week, 1, TOTAL_WEEKS)
	current_day = clampi(day, 1, DAYS_PER_WEEK)
	cur_period = period
	finished = false
	updateTime()
	period_changed.emit(cur_period)


func is_last_day_of_week() -> bool:
	return current_day == DAYS_PER_WEEK


func updateTime() -> void:
	if timeText == null:
		return
	timeText.clear()
	match cur_period:
		TIME.MORNING:
			timeText.push_color(Color.LIGHT_YELLOW)
			timeText.append_text("เช้า")
		TIME.NOON:
			timeText.push_color(Color.YELLOW)
			timeText.append_text("เที่ยง")
		TIME.EVENING:
			timeText.push_color(Color.NAVY_BLUE)
			timeText.append_text("เย็น")
	timeText.pop()
	dateText.clear()
	dateText.add_text("รอบ %d/%d · วันที่ %d/%d" % [current_week, TOTAL_WEEKS, current_day, DAYS_PER_WEEK])
