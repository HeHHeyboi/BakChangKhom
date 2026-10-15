class_name MonthGoalBar extends PanelContainer
## [0.2.0-D · 15 ต.ค. 2569] แถบเป้ากำไรเดือนนี้ ใต้แถบยศช่าง — Docs/ROADMAP_1_0_0.md ข้อ 8.1 D
## ฉาก Scene/UI/month_goal_bar.tscn (วางใน day_loop.tscn → GoalLayer ชั้น 100 เท่า HUD)
## ย้ายไปไว้ใน HUD ของ EventManager ได้ทีหลังโดยลากโหนดนี้ไปวาง (สคริปต์ไม่ผูกกับที่อยู่)
## ตัวเลข: กำไรเดือนนี้ = GameState.month_profit(เดือน) (ไม่นับลงทุน) · เป้า = EconomyConfig.month_target
## "เป้า ม.ค. ━━━━━── ฿1,240/฿2,000 · เหลือ 12 วัน" (นับวันทำการ จ.–ศ. ที่เหลือในเดือน)

## สีแถบเมื่อยังไม่ถึงเป้า / ถึงแล้ว
@export var fill_color := Color(0.95, 0.62, 0.2)
@export var reached_color := Color(0.45, 0.82, 0.45)
## ซ่อนตอนยังไม่เริ่มลูปร้าน (ระหว่างเควสต์หลัก/บทฝึก)
@export var only_when_shop_open := true

@onready var _title: Label = %GoalTitle
@onready var _bar: ProgressBar = %GoalBar
@onready var _value: Label = %GoalValue

var _fill: StyleBoxFlat
var _bound := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := _bar.get_theme_stylebox(&"fill")
	_fill = (sb.duplicate() if sb is StyleBoxFlat else StyleBoxFlat.new()) as StyleBoxFlat
	_bar.add_theme_stylebox_override(&"fill", _fill)
	_bind.call_deferred()


func _bind() -> void:
	var ts := _ts()
	if ts == null or not has_node(^"/root/GameState"):
		await get_tree().process_frame
		_bind()
		return
	if _bound:
		return
	_bound = true
	GameState.money_changed.connect(func(_m: int, _d: int) -> void: refresh())
	ts.shift_started.connect(func(_m: int, _w: int, _s: int) -> void: refresh())
	refresh()


func _process(_delta: float) -> void:
	var want := _should_show()
	if visible != want:
		visible = want
		if want:
			refresh()


func _should_show() -> bool:
	var ts := _ts()
	if ts == null or not ts.visible or Global.in_minigame:
		return false
	if only_when_shop_open and has_node(^"/root/DayLoop"):
		var dl = get_node(^"/root/DayLoop")
		if dl.has_method("_loop_active") and not dl._loop_active():
			return false
	return true


func refresh() -> void:
	var ts := _ts()
	if ts == null or not is_node_ready():
		return
	var m := ts.month()
	var target := maxi(GameState.target_of(m), 1) # โหมดช่วยลดเป้า
	var profit := GameState.month_profit(m)
	var reached := profit >= target
	_title.text = "เป้า %s" % TimeSystem.MONTH_NAME[clampi(m, 1, 12) - 1]
	_bar.value = clampf(float(profit) / target, 0.0, 1.0)
	_fill.bg_color = reached_color if reached else fill_color
	var left := ts.days_left_in_month()
	var tail := "ถึงเป้าแล้ว!" if reached else (("เหลือ %d วัน" % left) if left > 0 else "วันสุดท้าย")
	_value.text = "%s/%s · %s" % [_baht(profit), _baht(target), tail]
	tooltip_text = "กำไรเดือนนี้ = รายรับ − รายจ่าย (ไม่นับเงินลงทุน เช่น ชั้นวางของ)\nต้องได้อย่างน้อย %s ภายในสิ้นเดือน (บิลค่าเช่า/ไฟ/น้ำ/เน็ตตัดตอนสิ้นเดือน)" % _baht(target)


## "฿1,240" · "−฿270"
static func _baht(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("−฿" if n < 0 else "฿") + s + out


func _ts() -> TimeSystem:
	var em := get_node_or_null(^"/root/EventManager")
	if em == null:
		return null
	var ts = em.get("time_system")
	return ts as TimeSystem if is_instance_valid(ts) else null
