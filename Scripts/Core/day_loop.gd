extends CanvasLayer
## DayLoop (autoload: Scene/Core/day_loop.tscn) — ลูปวันของร้านซ่อม ตาม Docs/GAME_LOOP.md §3–4
## ลูกค้า 1 คน/วัน มาจาก WeekPlan (Resources/Week/weekN.tres) → CustomerCase (Resources/Customers/*.tres)
## แก้ลูกค้า/ลำดับวันใน Inspector ได้ทั้งหมด — วิธีแก้: Docs/WEEK1_CUSTOMERS.md
##
## ลูกค้าปกติ: การ์ดลูกค้า (เหตุผล · เครื่อง · อาการ) → รับงาน → บทลูกค้า → มินิเกม → การ์ดผลงาน
## ลูกค้า forced (event บังคับ): บทลูกค้าเล่นเองเมื่อเข้าร้าน → การ์ด "เริ่มซ่อม" ปุ่มเดียว → มินิเกม → การ์ดผลงาน
## → ปิดร้าน (เย็น · ไปหมู่บ้านทางแผนที่ได้) → เข้านอน → วันใหม่ · ครบ 7 วัน = การ์ดสรุปรอบ → บท Chapter รอบถัดไป
## เริ่มทำงานหลังเควสต์หลัก (main.tres · Tutorial + ซ่อมแรมคอมตัวเอง) จบ — งานในเควสต์ไม่นับเป็นงานลูกค้า
## UI เป็น placeholder สร้างจากโค้ด · [Claude 5 ต.ค. 2569]

## แผนลูกค้าแต่ละรอบ (ช่อง 0 = รอบ 1) · รอบที่ไม่มีแผน หรือวันที่เว้นว่าง = สุ่มจาก random_pool
@export var week_plans: Array[WeekPlan] = []
## ลูกค้าที่ใช้สุ่มเมื่อไม่มีแผน (ห้ามใส่ลูกค้า forced)
@export var random_pool: Array[CustomerCase] = []
## ซีนที่ถือว่าเป็น "ร้าน" (การ์ดขึ้นเฉพาะที่นี่)
@export var shop_scenes: PackedStringArray = ["res://Scene/Location/Home.tscn", "res://Scene/Location/Room.tscn"]
## รอให้อยู่ในร้านกี่วินาทีก่อนลูกค้า forced เดินเข้ามา
@export var forced_delay := 0.8
## ข้ามเควสต์หลัก (Debug F1)
@export var force_active := false

@export_group("พักหลัง Tutorial")
## บทพักหลังจบ Tutorial ก่อนลูกค้าคนแรก (เล่นครั้งเดียวต่อเกม) · ว่าง = ไม่มีพัก
@export_file("*.txt") var break_dialog := "res://Assets/Dialog/Break/after_tutorial.txt"
@export_file("*.png", "*.jpg") var break_bg := "res://Assets/Background/HomeBG.jpg"
## หลังบทพัก เวลาในเกมเดินไปกี่นาที
@export var break_minutes := 30
## แอนิเมชันเวลาหมุนยาวกี่วินาที (เวลาจริง)
@export var time_skip_seconds := 1.0

const ENDING_TEXT := {
	&"stay": "ฉากจบ: อยู่หมู่บ้าน ขยายร้าน\nร้านบักช่างขมกลายเป็นที่พึ่งของทั้งหมู่บ้าน",
	&"city": "ฉากจบ: กลับเมือง\nมิ้นดูแลร้านแทน ส่วนขมกลับไปทำงานบริษัท",
	&"coworking": "ฉากจบ: ปรับร้านเป็น Coworking\nร้านกลายเป็นที่เรียนรู้ของเด็ก ๆ ในหมู่บ้าน",
	&"failure": "ฉากจบ: ร้านปิด\nลูกค้าไม่พอใจจนร้านไปต่อไม่ไหว…",
}
const GRADE_TEXT := ["ซ่อมถูกทุกอย่าง", "ผ่าน แต่มีจุดพลาด", "ซ่อมไม่ผ่าน"]

enum Card { NONE, JOB, JOB_FORCED, RESULT, EVENING, WEEK_SUMMARY, ENDING }

var today_case: CustomerCase
var job_done_today := false
var arrived_today := false     # บทลูกค้าเข้าร้านเล่นไปแล้ว
var last_result: Dictionary = {}
var week_results: Array[Dictionary] = []
var week_start_money := 0
var _pending_summary_week := 0
var _game_over := false
var _working := false          # กำลังคุยกับลูกค้า / อยู่ในมินิเกม
var _shop_time := 0.0
var _break_done := false
var _skip_overlay: ColorRect
var _skip_clock: Label
var _skip_caption: Label
var _rng := RandomNumberGenerator.new()

var _panel: PanelContainer
var _title: Label
var _body: Label
var _primary: Button
var _secondary: Button
var _card := Card.NONE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build_ui()
	_validate()
	_connect.call_deferred()


func _connect() -> void:
	var ts: TimeSystem = EventManager.time_system
	ts.day_started.connect(_on_day_started)
	ts.week_ended.connect(_on_week_ended)
	ts.all_weeks_ended.connect(_on_all_weeks_ended)
	GameState.repair_recorded.connect(_on_repair_recorded)
	week_start_money = GameState.money
	today_case = case_for(ts.current_week, ts.current_day)


## เตือนใน Output ถ้าลูกค้าคนไหนกรอกไม่ครบ (เช่น ไม่มีเหตุผลที่มาร้าน)
func _validate() -> void:
	var all: Array[CustomerCase] = random_pool.duplicate()
	for plan in week_plans:
		if plan:
			for c in plan.days:
				if c:
					all.append(c)
	for c in all:
		for p in c.problems():
			push_warning("CustomerCase %s: %s" % [c.resource_path, p])
	for c in random_pool:
		if c and c.forced:
			push_warning("random_pool ไม่ควรมีลูกค้า forced: %s" % c.resource_path)


# ---------------------------------------------------------------- ลูป

func plan_for(week: int) -> WeekPlan:
	for p in week_plans:
		if p and p.week == week:
			return p
	return null


## ลูกค้าของวัน (week 1–12 · day 1–7)
func case_for(week: int, day: int) -> CustomerCase:
	var plan := plan_for(week)
	if plan:
		var c := plan.case_for_day(day)
		if c:
			return c
	var pool := random_pool.filter(func(c): return c != null)
	if pool.is_empty():
		return null
	return pool[_rng.randi_range(0, pool.size() - 1)]


func _on_day_started(week: int, day: int) -> void:
	job_done_today = false
	arrived_today = false
	last_result = {}
	_shop_time = 0.0
	today_case = case_for(week, day)


func _on_repair_recorded(result: Dictionary) -> void:
	job_done_today = true
	last_result = result
	week_results.append(result)
	_working = false


func _on_week_ended(week: int) -> void:
	_pending_summary_week = week


func _on_all_weeks_ended() -> void:
	_game_over = true


## ลูกค้าเดินเข้าร้าน → บทพูด · then_repair = จบบทแล้วเปิดมินิเกมต่อเลย
func play_arrival(then_repair: bool) -> void:
	if today_case == null:
		return
	_working = true
	_hide()
	arrived_today = true
	var path := today_case.arrive_dialog
	if path == "" or not FileAccess.file_exists(path):
		_working = false
		if then_repair:
			start_repair()
		return
	var done := func():
		_working = false
		if then_repair:
			start_repair()
	DialogScene.on_dialog_finish.connect(done, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	var bg := today_case.bg if today_case.bg != "" and ResourceLoader.exists(today_case.bg) else ""
	EventManager.play_story_dialog("ลูกค้า: " + today_case.customer, path, bg, GameState.speakers_in(path))


## เปิดมินิเกมของงานวันนี้ · meta "work_order" = งานลูกค้า (PartMinigame ส่งคะแนนเข้า GameState เฉพาะงานที่มี meta นี้)
func start_repair() -> void:
	var cs := get_tree().current_scene
	if today_case == null or cs == null or not ResourceLoader.exists(today_case.scene_path()):
		push_warning("DayLoop: เปิดมินิเกมไม่ได้ %s" % (today_case.scene_path() if today_case else "<ไม่มีลูกค้า>"))
		return
	_working = true
	_hide()
	var m := (load(today_case.scene_path()) as PackedScene).instantiate()
	m.set_meta("work_order", today_case)
	m.tree_exited.connect(func(): _working = false)
	cs.add_child(m)
	Global.in_minigame = true


## บทพักหลัง Tutorial → เวลาหมุน → แล้วลูกค้า forced ค่อยเข้ามา
func _play_break() -> void:
	_break_done = true
	_working = true
	_hide()
	if not FileAccess.file_exists(break_dialog):
		_after_break()
		return
	DialogScene.on_dialog_finish.connect(_after_break, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	var bg := break_bg if break_bg != "" and ResourceLoader.exists(break_bg) else ""
	EventManager.play_story_dialog("พักก่อน", break_dialog, bg, GameState.speakers_in(break_dialog))


func _after_break() -> void:
	await time_skip(break_minutes, time_skip_seconds)
	_shop_time = 0.0
	_working = false


## จอมืดลงครึ่งหนึ่ง + นาฬิกาหมุนจากตอนนี้ไปอีก minutes นาที ใน seconds วินาที (HUD หมุนตาม) แล้วสว่างกลับ
## ใช้ซ้ำได้ทุกที่: await DayLoop.time_skip(30)
func time_skip(minutes: int, seconds := 1.0) -> void:
	var ts: TimeSystem = EventManager.time_system
	var from := ts.current_minute
	var to := from + minutes
	_skip_caption.text = ("%d นาทีต่อมา…" % minutes) if minutes < 60 else ("%d ชั่วโมงต่อมา…" % (minutes / 60))
	_skip_clock.text = TimeSystem.clock_text(from)
	_skip_overlay.modulate.a = 0.0
	_skip_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(_skip_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_method(_skip_step, float(from), float(to), maxf(seconds, 0.05))
	tw.tween_interval(0.15)
	tw.tween_property(_skip_overlay, "modulate:a", 0.0, 0.2)
	await tw.finished
	ts.set_clock(to)
	_skip_overlay.visible = false


func _skip_step(v: float) -> void:
	EventManager.time_system.set_clock(int(v))
	_skip_clock.text = TimeSystem.clock_text(int(v))


func close_shop() -> void:
	EventManager.time_system.set_period(TimeSystem.TIME.EVENING)


func sleep() -> void:
	EventManager.end_day()


func _continue_after_summary() -> void:
	var week := _pending_summary_week
	_pending_summary_week = 0
	week_results.clear()
	week_start_money = GameState.money
	if _game_over:
		GameState.finish_game()
	else:
		GameState.play_week_chapter(week)


## เริ่มเกมใหม่หลังฉากจบ: เงิน/คะแนน/เวลา กลับค่าเริ่มต้น
func _reset_run() -> void:
	_game_over = false
	_pending_summary_week = 0
	week_results.clear()
	job_done_today = false
	arrived_today = false
	last_result = {}
	force_active = false
	_break_done = false
	GameState.reset()
	week_start_money = GameState.money
	EventManager.time_system.set_date(1, 1)
	today_case = case_for(1, 1)


# ---------------------------------------------------------------- UI

func _process(delta: float) -> void:
	var want := _decide_card()
	# ก่อนลูกค้าคนแรก: บทพัก → เวลาหมุน break_minutes นาที (ครั้งเดียวต่อเกม)
	if want == Card.JOB_FORCED and not arrived_today and not _break_done and break_dialog != "":
		_play_break()
		return
	# ลูกค้า forced เดินเข้ามาเองเมื่ออยู่ในร้านครบ forced_delay วินาที
	if want == Card.JOB_FORCED and not arrived_today:
		_hide()
		_shop_time += delta
		if _shop_time >= forced_delay:
			play_arrival(false)
		return
	if want == Card.NONE:
		_shop_time = 0.0
		_hide()
		return
	if want != _card or not _panel.visible:
		_show_card(want)


func _decide_card() -> Card:
	if _working or Global.in_minigame or DialogScene.visible:
		return Card.NONE
	if _pending_summary_week > 0:
		return Card.WEEK_SUMMARY
	if _game_over:
		return Card.ENDING if GameState.ending != &"" else Card.NONE
	if not _loop_active() or not _in_shop():
		return Card.NONE
	var ts: TimeSystem = EventManager.time_system
	if job_done_today:
		return Card.EVENING if ts.cur_period == TimeSystem.TIME.EVENING else Card.RESULT
	if today_case and today_case.forced:
		return Card.JOB_FORCED          # ปิดร้านหนีไม่ได้ ต้องซ่อมก่อน
	if ts.cur_period == TimeSystem.TIME.EVENING or today_case == null:
		return Card.EVENING
	return Card.JOB


func _loop_active() -> bool:
	if force_active:
		return true
	var ev = EventManager.eventMap.get(EventManager.EventID.MAIN)
	return ev != null and ev.isDone


func _in_shop() -> bool:
	var cs := get_tree().current_scene
	return cs != null and cs.scene_file_path in shop_scenes


func _fee(c: CustomerCase) -> int:
	if c.fee >= 0:
		return c.fee
	return GameState.economy.repair_fee.get(c.part(), GameState.economy.default_fee)


func _show_card(card: Card) -> void:
	_card = card
	_panel.visible = true
	_secondary.visible = false
	var ts: TimeSystem = EventManager.time_system
	var c := today_case
	match card:
		Card.JOB:
			_title.text = "ลูกค้ามาที่ร้าน · วันที่ %d" % ts.current_day
			_body.text = "%s\nมาเพราะ: %s\nเครื่อง: %s\nอาการ: %s\nงาน: %s · ค่าซ่อม ฿%d" % [
				c.customer, c.reason, c.device, c.symptom, c.job_title, _fee(c)]
			_primary.text = "รับงาน"
			_secondary.text = "ปิดร้านวันนี้"
			_secondary.visible = true
		Card.JOB_FORCED:
			_title.text = "งานด่วน! · วันที่ %d" % ts.current_day
			_body.text = "%s รอเครื่องอยู่\nเครื่อง: %s\nอาการ: %s\nงาน: %s · ค่าซ่อม ฿%d" % [
				c.customer, c.device, c.symptom, c.job_title, _fee(c)]
			_primary.text = "เริ่มซ่อม"
		Card.RESULT:
			_title.text = "ส่งเครื่องคืนลูกค้า"
			if last_result.is_empty():
				_body.text = "ซ่อมเสร็จแล้ว"
			else:
				var r := last_result
				var money_txt := ("+฿%d" % r["money"]) if r["money"] >= 0 else ("−฿%d" % -r["money"])
				var quote := ""
				if c:
					quote = "\n\n%s: \"%s\"" % [c.customer, c.complain_text if r["grade"] == GameState.Grade.FAIL else c.thanks_text]
				_body.text = "%s\nคะแนน %d/100%s\nเงิน %s · ความพอใจ %d · XP +%d%s" % [
					GRADE_TEXT[r["grade"]], r["score"], "  (ทำของเสีย!)" if r["damaged"] else "",
					money_txt, r["satisfaction"], r["xp"], quote]
			_primary.text = "ปิดร้าน → ช่วงเย็น"
		Card.EVENING:
			_title.text = "ช่วงเย็น · วันที่ %d/%d" % [ts.current_day, TimeSystem.DAYS_PER_WEEK]
			_body.text = "ออกไปหมู่บ้านได้ทางแผนที่\nเงินในร้าน ฿%d" % GameState.money
			_primary.text = "เข้านอน (จบรอบ)" if ts.is_last_day_of_week() else "เข้านอน → วันถัดไป"
		Card.WEEK_SUMMARY:
			var earned := GameState.money - week_start_money
			var sat := 0.0
			for r in week_results:
				sat += r["satisfaction"]
			sat = sat / week_results.size() if not week_results.is_empty() else 0.0
			_title.text = "สรุปรอบ %d" % _pending_summary_week
			_body.text = "งานที่ซ่อม %d งาน\nรายได้รอบนี้ %s฿%d\nความพอใจเฉลี่ย %d · ทั้งเกม %d\nXP รวม %d" % [
				week_results.size(), "+" if earned >= 0 else "−", absi(earned), roundi(sat),
				roundi(GameState.average_satisfaction()), GameState.xp]
			_primary.text = "ดูฉากจบ" if _game_over else "ไปต่อ (บทของรอบ %d)" % (_pending_summary_week + 1)
		Card.ENDING:
			_title.text = "จบเกม"
			_body.text = "%s\n\nเงิน ฿%d · ความพอใจเฉลี่ย %d" % [
				ENDING_TEXT.get(GameState.ending, ""), GameState.money, roundi(GameState.average_satisfaction())]
			_primary.text = "กลับหน้าแรก"


func _on_primary() -> void:
	match _card:
		Card.JOB:
			play_arrival(true)
		Card.JOB_FORCED:
			start_repair()
		Card.RESULT:
			close_shop()
		Card.EVENING:
			sleep()
		Card.WEEK_SUMMARY:
			_continue_after_summary()
		Card.ENDING:
			_reset_run()
			get_tree().change_scene_to_file("res://Scene/Start_Scene.tscn")
	_card = Card.NONE


func _on_secondary() -> void:
	if _card == Card.JOB:
		close_shop()
	_card = Card.NONE


func _hide() -> void:
	_panel.visible = false
	_card = Card.NONE


func _build_time_skip() -> void:
	_skip_overlay = ColorRect.new()
	_skip_overlay.name = "TimeSkip"
	_skip_overlay.color = Color(0.05, 0.04, 0.08, 0.6)
	_skip_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_skip_overlay.size = Vector2(1152, 648)
	_skip_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip_overlay.visible = false
	add_child(_skip_overlay)
	_skip_clock = Label.new()
	_skip_clock.add_theme_font_size_override("font_size", 96)
	_skip_clock.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_skip_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_clock.position = Vector2(0, 220)
	_skip_clock.size = Vector2(1152, 120)
	_skip_overlay.add_child(_skip_clock)
	_skip_caption = Label.new()
	_skip_caption.add_theme_font_size_override("font_size", 28)
	_skip_caption.add_theme_color_override("font_color", Color.WHITE)
	_skip_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_caption.position = Vector2(0, 340)
	_skip_caption.size = Vector2(1152, 48)
	_skip_overlay.add_child(_skip_caption)
	_card = Card.NONE


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DayCard"
	_panel.position = Vector2(772, 120)
	_panel.custom_minimum_size = Vector2(364, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.94, 0.87, 0.97)
	sb.border_color = Color(0.45, 0.3, 0.15)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color(0.35, 0.2, 0.08))
	box.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(332, 0)
	_body.add_theme_font_size_override("font_size", 17)
	_body.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
	box.add_child(_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	_primary = Button.new()
	_primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_primary.focus_mode = Control.FOCUS_NONE
	_primary.pressed.connect(_on_primary)
	row.add_child(_primary)
	_secondary = Button.new()
	_secondary.focus_mode = Control.FOCUS_NONE
	_secondary.pressed.connect(_on_secondary)
	row.add_child(_secondary)
	_panel.visible = false
	_build_time_skip()
