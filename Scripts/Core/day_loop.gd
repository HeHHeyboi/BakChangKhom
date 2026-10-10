extends CanvasLayer
## DayLoop (autoload: Scene/Core/day_loop.tscn) — ลูปกะของร้านซ่อม ตาม Docs/LEVEL_DESIGN.md ข้อ 4–6 · 7.4
## [Claude 9 ต.ค. 2569] เขียนใหม่จาก "ลูกค้าวันละ 1 คน" เป็น "กระดานงานหลายใบ + เวลาเป็นช่อง 30 นาที"
##
## 1 กะ (08:30–18:30): เปิดร้าน → กระดานงาน (งานใหม่ตามสัดส่วน Lv1–Lv5 ของสัปดาห์ + งานค้าง)
##   เลือกรับ/ปฏิเสธ · การ์ดบอกแค่อาการ ไม่บอก Part · รับงาน → บทลูกค้า → มินิเกม → นาฬิกาเดินตามช่องของงาน → การ์ดผลงาน
##   พักบ่าย 15:30 มีงานโทรเข้า · 18:30 ปิดร้าน (ล่วงเวลาได้ ≤ 2 ช่อง · ≤ 2 กะ/สัปดาห์) → กะถัดไป
## งานหมดเขต (due_shifts) = ลูกค้าเดินออก ชื่อเสียงลด · งาน Lv n+1 ขึ้นกระดานเมื่อได้ ⭐⭐ ใน Lv n ครบ 2 งาน
## ครบ 5 กะ = สรุปสัปดาห์ (+ บิลรายเดือนทุก 4 สัปดาห์) → บท Chapter ถัดไป · ครบ 60 กะ = Epilogue + ฉากจบ
## งานบังคับรายกะ (WeekPlan.shifts) ที่เป็น forced: ลูกค้าเดินเข้ามาเอง ปฏิเสธไม่ได้ (กะแรก = ลุงอำนวย หลังบทพัก Tutorial)
## เริ่มทำงานหลังเควสต์หลัก (main.tres) จบ — งานในเควสต์ไม่นับเป็นงานลูกค้า · UI เป็น placeholder สร้างจากโค้ด

## แผนรายสัปดาห์ (WeekPlan.week = 1–12) · สัปดาห์ที่ไม่มีแผน = สัดส่วนจาก DEFAULT_WEIGHTS
@export var week_plans: Array[WeekPlan] = []
## ลูกค้าที่สุ่มขึ้นกระดาน (ห้ามใส่ลูกค้า forced) · ใช้ระดับ (level) ของแต่ละคนเลือกตามสัดส่วน
@export var random_pool: Array[CustomerCase] = []
## สถานที่ที่ถือว่าเป็น "ร้าน" (การ์ดขึ้นเฉพาะที่นี่)
@export var shop_locations: Array[SceneRouter.LocationID] = [SceneRouter.HOME, SceneRouter.ROOM, SceneRouter.VILLAGE]
## รอให้อยู่ในร้านกี่วินาทีก่อนลูกค้า forced เดินเข้ามา
@export var forced_delay := 0.8
## ข้ามเควสต์หลัก (Debug F1)
@export var force_active := false

@export_group("พักหลัง Tutorial")
## บทพักหลังจบ Tutorial ก่อนลูกค้าคนแรก (เล่นครั้งเดียวต่อเกม) · ว่าง = ไม่มีพัก
@export_file("*.txt") var break_dialog := "res://Assets/Dialog/Break/after_tutorial.txt"
@export_file("*.png", "*.jpg") var break_bg := "res://Assets/Background/HomeBG.jpg"
## หลังบทพัก เวลาในเกมเดินไปกี่นาที (08:30 → 09:00 เริ่มงาน)
@export var break_minutes := 30
## แอนิเมชันเวลาหมุนยาวกี่วินาที (เวลาจริง)
@export var time_skip_seconds := 1.0

@export_group("เดโม")
## [Claude 10 ต.ค. 2569] เดโม: ครบกี่กะแล้วจบการเล่น (0 = เล่นเต็ม 60 กะ) → การ์ดสรุป → กลับบ้าน + ป้าย "กำลังพัฒนาให้ครบลูป"
@export var demo_shifts := 7
@export var demo_banner_title := "สิ้นสุดการเล่นเดโม"
@export_multiline var demo_banner_text := "ขอบคุณที่ทดลองเล่นนะ!\nตอนนี้เกมกำลังพัฒนาให้ครบลูป\nแล้วพบกับร้านบักช่างขมฉบับเต็มเร็ว ๆ นี้"

## สัดส่วนงาน Lv1/2/3/4/5 (%) ต่อสัปดาห์ 1–12 (LEVEL_DESIGN ข้อ 6) · WeekPlan.level_weights ทับได้
const DEFAULT_WEIGHTS := [
	[70, 30, 0, 0, 0],
	[50, 40, 10, 0, 0],
	[30, 45, 25, 0, 0],
	[20, 40, 30, 10, 0],
	[20, 30, 35, 15, 0],
	[20, 30, 35, 15, 0],
	[10, 25, 30, 25, 10],
	[10, 25, 30, 25, 10],
	[10, 20, 25, 25, 20],
	[10, 20, 25, 25, 20],
	[5, 15, 20, 30, 30],
	[5, 15, 20, 30, 30],
]
const ENDING_TEXT := {
	&"stay": "ฉากจบ: อยู่หมู่บ้าน ขยายร้าน\nร้านบักช่างขมกลายเป็นที่พึ่งของทั้งหมู่บ้าน",
	&"city": "ฉากจบ: กลับเมือง\nมิ้นดูแลร้านแทน ส่วนขมกลับไปทำงานบริษัท",
	&"coworking": "ฉากจบ: ปรับร้านเป็น Coworking\nร้านกลายเป็นที่เรียนรู้ของเด็ก ๆ ในหมู่บ้าน",
	&"failure": "ฉากจบ: ร้านปิด\nลูกค้าไม่พอใจจนร้านไปต่อไม่ไหว…",
}
const GRADE_TEXT := ["ซ่อมถูกทุกอย่าง", "ผ่าน แต่มีจุดพลาด", "ซ่อมไม่ผ่าน"]

enum Card {
	NONE,
	BOARD,
	JOB_FORCED,
	RESULT,
	SHIFT_END,
	WEEK_SUMMARY,
	ENDING,
	DEMO_END,
}

## งานบนกระดาน: { "case": CustomerCase, "due_shift": int (กะสุดท้ายที่ยังรับได้), "phone": bool }
var board: Array[Dictionary] = []
## งานที่กำลังทำ (ลูกค้าคนนี้)
var today_case: CustomerCase
var current_job: Dictionary = { }
## งานบังคับของกะนี้ (null = ไม่มี / ทำแล้ว)
var forced_case: CustomerCase
var arrived_today := false # บทลูกค้า forced เล่นไปแล้ว
var last_result: Dictionary = { }
var shift_results: Array[Dictionary] = []
var shift_start_money := 0
var week_results: Array[Dictionary] = []
var week_start_money := 0
## ล่วงเวลาไปแล้วกี่กะในสัปดาห์นี้
var ot_this_week := 0
var walkouts: PackedStringArray = []
var _ot_this_shift := false
var _result_pending := false
var _close_requested := false
var _parts_seen: Dictionary = { } # part_id → true (ครั้งแรกใช้เวลา +1 ช่อง)
var _last_bill: Dictionary = { }
var _pending_summary_week := 0
var _game_over := false
## จบเดโมแล้ว (ครบ demo_shifts กะ) · _demo_ack = กดกลับบ้านแล้ว (โชว์ป้ายแทนการ์ด)
var demo_over := false
var _demo_ack := false
var _demo_banner: Control
var _demo_layer: CanvasLayer
var _demo_card: PanelContainer
var _demo_badge: Button
var _working := false # กำลังคุยกับลูกค้า / อยู่ในมินิเกม
var _shop_time := 0.0
var _break_done := false
var _skipping := false # กำลังเล่นแอนิเมชันเวลาหมุน
var _pending_cb := Callable() # callback ที่รอ DialogScene.on_dialog_finish อยู่ (ถอดได้ถ้าบทไม่ขึ้น)
var _minigame: Node # มินิเกมงานลูกค้าที่เปิดอยู่
var _stuck_time := 0.0 # watchdog: _working ค้างโดยไม่มีบท/มินิเกม
var _connect_tries := 0
const STUCK_LIMIT := 3.0
var _board_dirty := true
var _skip_overlay: ColorRect
var _skip_clock: Label
var _skip_caption: Label
var _rng := RandomNumberGenerator.new()

var _panel: PanelContainer
var _title: Label
var _body: Label
var _primary: Button
var _secondary: Button
var _board_panel: PanelContainer
var _board_title: Label
var _board_note: Label
var _board_list: VBoxContainer
var _board_close: Button
var _board_wait: Button
var _card := Card.NONE
## [10 ต.ค.] ย่อกระดาษงาน (กระดานงาน · การ์ดงานด่วน/ผลงาน/ปิดร้าน) → เหลือแถบ "กระดานงาน" ให้กดเปิดคืน
var cards_hidden := false
var _cards_tab: Button
const HIDEABLE := [Card.BOARD, Card.JOB_FORCED, Card.RESULT, Card.SHIFT_END]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build_ui()
	_validate()
	_connect.call_deferred()


func _connect() -> void:
	var ts := _ts()
	if ts == null or not has_node(^"/root/GameState"):
		_connect_tries += 1
		if _connect_tries > 30:
			push_error("DayLoop: ไม่พบ EventManager.time_system / GameState — ลูปร้านไม่ทำงาน")
			return
		await get_tree().process_frame
		_connect()
		return
	var links := [
		[ts.shift_started, _on_shift_started],
		[ts.week_ended, _on_week_ended],
		[ts.month_ended, _on_month_ended],
		[ts.game_ended, _on_game_ended],
		[ts.break_started, _on_break_started],
		[ts.clock_changed, _on_clock_changed],
		[GameState.repair_recorded, _on_repair_recorded],
		[SceneRouter.location_changed, func(_id): autosave()],
	]
	for l in links:
		if not (l[0] as Signal).is_connected(l[1]):
			(l[0] as Signal).connect(l[1])
	week_start_money = GameState.money
	_on_shift_started(ts.month(), ts.week(), ts.shift_in_week())


## เตือนใน Output ถ้าลูกค้าคนไหนกรอกไม่ครบ (เช่น ไม่มีเหตุผลที่มาร้าน)
func _validate() -> void:
	var all: Array[CustomerCase] = []
	for c in random_pool:
		if c:
			all.append(c)
	var weeks_seen := { }
	for plan in week_plans:
		if plan == null:
			push_warning("DayLoop.week_plans มีช่องว่าง")
			continue
		if weeks_seen.has(plan.week):
			push_warning("DayLoop.week_plans มีสัปดาห์ %d ซ้ำ — ใช้อันแรก (%s)" % [plan.week, plan.resource_path])
		weeks_seen[plan.week] = true
		if plan.shifts.size() > TimeSystem.SHIFTS_PER_WEEK:
			push_warning("WeekPlan %s มีงานบังคับ %d กะ (เกิน %d)" % [plan.resource_path, plan.shifts.size(), TimeSystem.SHIFTS_PER_WEEK])
		if not plan.level_weights.is_empty() and plan.level_weights.size() != 5:
			push_warning("WeekPlan %s: level_weights ต้องมี 5 ช่อง (Lv1–Lv5)" % plan.resource_path)
		for c in plan.shifts + plan.days:
			if c:
				all.append(c)
	var ids := { }
	for c in all:
		if c.id != &"" and ids.has(c.id) and ids[c.id] != c:
			push_warning("CustomerCase id ซ้ำ: %s" % c.id)
		ids[c.id] = c
		for p in c.problems():
			push_warning("CustomerCase %s: %s" % [c.resource_path, p])
	for c in random_pool:
		if c and c.forced:
			push_warning("random_pool ไม่ควรมีลูกค้า forced: %s" % c.resource_path)

# ---------------------------------------------------------------- แผน / สุ่มงาน


func plan_for(week: int) -> WeekPlan:
	for p in week_plans:
		if p and p.week == week:
			return p
	return null


## งานบังคับของกะ (week 1–12 · shift_in_week 1–5)
func case_for(week: int, shift_in_week: int) -> CustomerCase:
	var plan := plan_for(week)
	return plan.case_for_shift(shift_in_week) if plan else null


## สัดส่วน Lv1–Lv5 ของสัปดาห์ (ยังไม่ปรับตามที่ปลดล็อก)
func weights_for(week: int) -> PackedFloat32Array:
	var plan := plan_for(week)
	if plan and plan.level_weights.size() == 5:
		return plan.level_weights
	return PackedFloat32Array(DEFAULT_WEIGHTS[clampi(week, 1, DEFAULT_WEIGHTS.size()) - 1])


## สัดส่วนหลังย้ายน้ำหนักของระดับที่ยังล็อก/ไม่มีเคส ไปยังระดับใกล้สุดที่ใช้ได้ (ต่ำกว่าก่อน)
func effective_weights(week: int) -> PackedFloat32Array:
	var w := weights_for(week).duplicate()
	var ok: Array[bool] = []
	for lv in range(1, 6):
		ok.append(GameState.level_unlocked(lv) and not _cases_of_level(lv, false).is_empty())
	var out := PackedFloat32Array([0, 0, 0, 0, 0])
	for i in 5:
		if w[i] <= 0.0:
			continue
		var target := -1
		for j in range(i, -1, -1):
			if ok[j]:
				target = j
				break
		if target < 0:
			for j in range(i + 1, 5):
				if ok[j]:
					target = j
					break
		if target >= 0:
			out[target] += w[i]
	return out


func _cases_of_level(lv: int, exclude_board := true) -> Array[CustomerCase]:
	var out: Array[CustomerCase] = []
	for c in random_pool:
		if c == null or c.forced or c.level != lv:
			continue
		if exclude_board and (_on_board(c) or c == today_case):
			continue
		out.append(c)
	return out


func _on_board(c: CustomerCase) -> bool:
	for j in board:
		if j["case"] == c:
			return true
	return false


## สุ่มงานใหม่ n ใบขึ้นกระดาน (ไม่ซ้ำกับที่อยู่บนกระดาน) · คืนจำนวนที่เพิ่มได้จริง
func add_jobs(n: int, phone := false) -> int:
	var ts := _ts()
	if ts == null:
		return 0
	var e := _econ()
	var added := 0
	for k in n:
		if board.size() >= e.board_max:
			break
		var w := effective_weights(ts.week())
		# ระดับที่เคสถูกใช้หมดแล้ว (อยู่บนกระดานครบ) ตัดออก
		for i in 5:
			if _cases_of_level(i + 1).is_empty():
				w[i] = 0.0
		var total := 0.0
		for x in w:
			total += x
		if total <= 0.0:
			break
		var r := _rng.randf() * total
		var lv := 1
		for i in 5:
			r -= w[i]
			if r <= 0.0:
				lv = i + 1
				break
		var pool := _cases_of_level(lv)
		if pool.is_empty():
			continue
		var c: CustomerCase = pool[_rng.randi_range(0, pool.size() - 1)]
		var due := ts.shift if phone else ts.shift + c.due_shifts
		board.append({ "case": c, "due_shift": due, "phone": phone })
		added += 1
	_board_dirty = true
	return added

# ---------------------------------------------------------------- สัญญาณเวลา


func _on_shift_started(_month: int, week: int, shift_in_week: int) -> void:
	var ts := _ts()
	_result_pending = false
	_close_requested = false
	_ot_this_shift = false
	arrived_today = false
	_shop_time = 0.0
	shift_results.clear()
	shift_start_money = GameState.money
	# งานหมดเขต = ลูกค้าเดินออก
	walkouts.clear()
	for j in board.duplicate():
		if int(j["due_shift"]) < ts.shift:
			board.erase(j)
			walkouts.append((j["case"] as CustomerCase).customer)
			GameState.add_reputation(_econ().rep_walkout)
	var fc := case_for(week, shift_in_week)
	forced_case = fc if fc and fc.forced else null
	if fc and not fc.forced and not _on_board(fc):
		board.append({ "case": fc, "due_shift": ts.shift + fc.due_shifts, "phone": false })
	add_jobs(_econ().month_value(_econ().board_new_per_shift, ts.month()))
	_board_dirty = true
	autosave.call_deferred()


## [10 ต.ค.] บันทึกอัตโนมัติ (SaveGame) — ไม่บันทึกตอนยังอยู่เมนูหลัก/บทนำ หรือระหว่างมินิเกม
func autosave() -> bool:
	if Global.on_start or Global.in_minigame or _working:
		return false
	var cur := get_tree().current_scene
	if cur and cur.is_in_group("main_menu") and cur.visible:
		return false
	return SaveGame.save()


func _on_break_started(kind: StringName) -> void:
	if kind == &"afternoon":
		add_jobs(_econ().board_phone_jobs, true)


func _on_clock_changed(_minute: int) -> void:
	_board_dirty = true


func _on_week_ended(week: int) -> void:
	_pending_summary_week = week
	ot_this_week = 0


func _on_month_ended(month: int) -> void:
	_last_bill = GameState.pay_month_bill(month)


func _on_game_ended() -> void:
	_game_over = true


func _on_repair_recorded(result: Dictionary) -> void:
	var c := today_case
	if c:
		var ts := _ts()
		if ts:
			ts.advance_minutes(job_slots(c) * TimeSystem.SLOT_MIN)
			ts.snap_to_slot()
		_parts_seen[c.part_id] = true
		if c == forced_case:
			forced_case = null
	current_job = { }
	last_result = result
	_result_pending = true
	shift_results.append(result)
	week_results.append(result)
	_working = false

# ---------------------------------------------------------------- งาน


## เวลาของงาน (ช่อง) · ครั้งแรกที่เจอมินิเกมนั้น +1 ช่อง (ปิ๊บสอนเต็ม)
func job_slots(c: CustomerCase) -> int:
	if c == null:
		return 0
	var e := _econ()
	return c.slots(e) + (e.first_time_extra_slots if not _parts_seen.has(c.part_id) else 0)


## สถานะเวลาของงาน: &"ok" · &"ot" (ต้องล่วงเวลา) · &"no" (ไม่ทันกะนี้)
func job_fit(c: CustomerCase) -> StringName:
	var ts := _ts()
	if ts == null:
		return &"no"
	var need := job_slots(c) * TimeSystem.SLOT_MIN
	if need <= ts.remaining_work_minutes(false):
		return &"ok"
	var ot_ok := _ot_this_shift or ot_this_week < _econ().ot_max_per_week
	if ot_ok and need <= ts.remaining_work_minutes(true):
		return &"ot"
	return &"no"


func accept_job(i: int) -> void:
	if i < 0 or i >= board.size() or _working:
		return
	var job: Dictionary = board[i]
	var c: CustomerCase = job["case"]
	var fit := job_fit(c)
	if fit == &"no":
		return
	if fit == &"ot":
		var ts := _ts()
		ts.overtime = true
		if not _ot_this_shift:
			_ot_this_shift = true
			ot_this_week += 1
	board.remove_at(i)
	current_job = job
	today_case = c
	_board_dirty = true
	play_arrival(true)


func reject_job(i: int) -> void:
	if i < 0 or i >= board.size():
		return
	board.remove_at(i)
	GameState.add_reputation(_econ().rep_reject)
	_board_dirty = true


## ไม่มีงานที่อยากรับ — รอลูกค้า 30 นาที
func wait_slot() -> void:
	var ts := _ts()
	if ts:
		ts.advance_minutes(TimeSystem.SLOT_MIN)


## ลูกค้าเดินเข้าร้าน → บทพูด · then_repair = จบบทแล้วเปิดมินิเกมต่อเลย
func play_arrival(then_repair: bool) -> void:
	if today_case == null:
		return
	_working = true
	_hide()
	arrived_today = true
	var path := today_case.arrive_dialog
	var done := func() -> void:
		_pending_cb = Callable()
		_working = false
		if then_repair:
			start_repair()
	var bg := today_case.bg
	if (
		path != ""
		and EventManager.play_story_dialog("ลูกค้า: " + today_case.customer, path, bg, DialogUtil.speakers_in(path))
	):
		_wait_dialog(done)
	else:
		done.call() # ไม่มีบท/เปิดบทไม่ได้ → ข้ามไปขั้นต่อไปเลย ไม่ให้ค้าง


## เปิดมินิเกมของงานนี้ · meta "work_order" = งานลูกค้า (PartMinigame ส่งคะแนนเข้า GameState เฉพาะงานที่มี meta นี้)
func start_repair() -> void:
	if today_case == null:
		push_warning("DayLoop: เปิดมินิเกมไม่ได้ (ไม่มีลูกค้า)")
		return
	if is_instance_valid(_minigame) and _minigame.is_inside_tree():
		push_warning("DayLoop: มีมินิเกมเปิดอยู่แล้ว")
		return
	var path := today_case.scene_path()
	var ps := load(path) as PackedScene if path != "" and ResourceLoader.exists(path) else null
	if ps == null:
		push_error("DayLoop: โหลดมินิเกมไม่ได้ %s (%s)" % [path, today_case.resource_path])
		return
	var m := ps.instantiate()
	if not m is PartMinigame:
		push_warning("DayLoop: %s ไม่ใช่ PartMinigame — จะไม่ได้คะแนน/เงิน" % path)
	_working = true
	_hide()
	m.set_meta("work_order", today_case)
	m.tree_exited.connect(_on_minigame_closed)
	_minigame = m
	SceneRouter.push_node(m)
	Global.in_minigame = true


func _on_minigame_closed() -> void:
	_minigame = null
	_working = false
	Global.in_minigame = false # กันมินิเกมปิดแบบผิดปกติแล้วค่านี้ค้าง true (การ์ดจะไม่ขึ้นอีกเลย)


## รอบทจบแล้วค่อยเรียก cb · จำไว้ใน _pending_cb เพื่อถอดได้ถ้าบทไม่ขึ้นจริง (watchdog)
func _wait_dialog(cb: Callable) -> void:
	if _pending_cb.is_valid() and DialogScene.on_dialog_finish.is_connected(_pending_cb):
		DialogScene.on_dialog_finish.disconnect(_pending_cb)
	_pending_cb = cb
	DialogScene.on_dialog_finish.connect(cb, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


## บทพักหลัง Tutorial → เวลาหมุน → แล้วลูกค้า forced ค่อยเข้ามา
func _play_break() -> void:
	_break_done = true
	_working = true
	_hide()
	if EventManager.play_story_dialog("พักก่อน", break_dialog, break_bg, DialogUtil.speakers_in(break_dialog)):
		_wait_dialog(_after_break)
	else:
		_after_break()


func _after_break() -> void:
	_pending_cb = Callable()
	await time_skip(break_minutes, time_skip_seconds)
	_shop_time = 0.0
	_working = false


## จอมืดลงครึ่งหนึ่ง + นาฬิกาหมุนจากตอนนี้ไปอีก minutes นาที ใน seconds วินาที (HUD หมุนตาม) แล้วสว่างกลับ
## ไม่นับเป็นเวลางาน · ใช้ซ้ำได้: await DayLoop.time_skip(30)
func time_skip(minutes: int, seconds := 1.0) -> void:
	var ts := _ts()
	if ts == null or minutes <= 0 or _skipping:
		return
	_skipping = true
	var from := ts.current_minute
	var to := mini(from + minutes, 24 * 60 - 1)
	_skip_caption.text = ("%d นาทีต่อมา…" % minutes) if minutes < 60 else ("%d ชั่วโมงต่อมา…" % floori(minutes / 60.0))
	_skip_clock.text = TimeSystem.clock_text(from)
	_skip_overlay.modulate.a = 0.0
	_skip_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(_skip_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_method(_skip_step, float(from), float(to), maxf(seconds, 0.05))
	tw.tween_interval(0.15)
	tw.tween_property(_skip_overlay, "modulate:a", 0.0, 0.2)
	await tw.finished
	if is_instance_valid(ts):
		ts.set_clock(to)
	_skip_overlay.visible = false
	_skipping = false


func _skip_step(v: float) -> void:
	var ts := _ts()
	if ts:
		ts.set_clock(int(v))
	_skip_clock.text = TimeSystem.clock_text(int(v))


func _ts() -> TimeSystem:
	var em := get_node_or_null(^"/root/EventManager")
	if em == null:
		return null
	var ts = em.get("time_system")
	return ts as TimeSystem if is_instance_valid(ts) else null


func _econ() -> EconomyConfig:
	var gs := get_node_or_null(^"/root/GameState")
	var e = gs.get("economy") if gs else null
	return e if e is EconomyConfig else EconomyConfig.new()


## ปิดร้านก่อน 18:30 (ไปการ์ดสรุปกะ)
func close_shop() -> void:
	_close_requested = true


## จ่ายค่าไฟล่วงเวลา → กะถัดไป
func end_shift() -> void:
	var ts := _ts()
	if ts == null:
		return
	var ot := ot_slots_now()
	if ot > 0:
		GameState.add_money(-ot * _econ().ot_cost_per_slot)
	if is_demo_last_shift():
		demo_over = true
		_close_requested = false
		_board_dirty = true
		return
	ts.end_shift()


## กะนี้เป็นกะสุดท้ายของเดโมไหม
func is_demo_last_shift() -> bool:
	var ts := _ts()
	return demo_shifts > 0 and ts != null and ts.shift >= demo_shifts


## การ์ดจบเดโม → กลับบ้าน → ป้าย "กำลังพัฒนาให้ครบลูป"
func finish_demo() -> void:
	_demo_ack = true
	_hide()
	SceneRouter.go(SceneRouter.HOME) # เปลี่ยนฉาก → autosave
	_show_demo_banner(true)


## [10 ต.ค.] หน้าจบเดโม: พื้นมืด + การ์ดกลางจอ ตัวใหญ่ (ชั้น 115 เหนือ HUD) · "อยู่ในบ้านต่อ" = ย่อเป็นป้ายเล็กด้านล่าง
func _show_demo_banner(on: bool) -> void:
	if not is_instance_valid(_demo_banner):
		_build_demo_banner()
	(_demo_card.find_child("Text", true, false) as Label).text = demo_banner_text
	(_demo_card.find_child("Title", true, false) as Label).text = demo_banner_title
	(_demo_card.find_child("Stats", true, false) as Label).text = "เปิดร้านครบ %d วัน · ซ่อม %d งาน · เงิน ฿%d · ชื่อเสียง %d · ยศ %s" % [
		demo_shifts, GameState.satisfaction_history.size(), GameState.money, GameState.reputation, GameState.rank_name()]
	_demo_banner.visible = on
	_demo_layer.visible = on
	if on:
		_demo_minimize(false)


func _build_demo_banner() -> void:
	_demo_layer = CanvasLayer.new()
	_demo_layer.name = "DemoEnd"
	_demo_layer.layer = 115
	add_child(_demo_layer)
	_demo_banner = Control.new()
	_demo_banner.name = "DemoBanner"
	_demo_banner.size = Vector2(1152, 648)
	_demo_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_demo_layer.add_child(_demo_banner)
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.06, 0.03, 0.02, 0.6)
	dim.size = Vector2(1152, 648)
	_demo_banner.add_child(dim)
	_demo_card = PanelContainer.new()
	_demo_card.name = "Card"
	var sb := _card_style()
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(32)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	_demo_card.add_theme_stylebox_override("panel", sb)
	_demo_card.custom_minimum_size = Vector2(700, 0)
	_demo_card.position = Vector2(226, 120)
	_demo_banner.add_child(_demo_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	_demo_card.add_child(box)
	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.55, 0.25, 0.06))
	box.add_child(title)
	var t := Label.new()
	t.name = "Text"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", Color(0.22, 0.13, 0.06))
	box.add_child(t)
	var st := Label.new()
	st.name = "Stats"
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.add_theme_font_size_override("font_size", 18)
	st.add_theme_color_override("font_color", Color(0.45, 0.3, 0.15))
	box.add_child(st)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	for it in [["กลับเมนูหลัก", func(): PauseMenu.go_to_main_menu()], ["อยู่ในบ้านต่อ", func(): _demo_minimize(true)]]:
		var b := Button.new()
		b.name = "Btn_" + String(it[0]).validate_node_name()
		b.text = it[0]
		b.theme = load("res://Assets/UI/menu_theme.tres")
		b.custom_minimum_size = Vector2(250, 70)
		b.add_theme_font_size_override("font_size", 24)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(it[1])
		row.add_child(b)
	_demo_badge = Button.new()
	_demo_badge.name = "Badge"
	_demo_badge.text = "★ จบเดโมแล้ว · กดเพื่อดูอีกครั้ง"
	_demo_badge.focus_mode = Control.FOCUS_NONE
	_demo_badge.add_theme_font_size_override("font_size", 20)
	for st2 in ["normal", "hover", "pressed"]:
		_demo_badge.add_theme_stylebox_override(st2, _card_style())
	_demo_badge.add_theme_color_override("font_color", Color(0.55, 0.25, 0.06))
	_demo_badge.add_theme_color_override("font_hover_color", Color(0.75, 0.35, 0.05))
	_demo_badge.position = Vector2(400, 586)
	_demo_badge.custom_minimum_size = Vector2(352, 48)
	_demo_badge.pressed.connect(_demo_minimize.bind(false))
	_demo_banner.add_child(_demo_badge)


## ย่อ (เดินดูบ้านต่อได้ · เหลือป้ายเล็ก) / ขยายคืน
func _demo_minimize(on: bool) -> void:
	if not is_instance_valid(_demo_banner):
		return
	_demo_banner.get_node("Dim").visible = not on
	_demo_card.visible = not on
	_demo_badge.visible = on


func ot_slots_now() -> int:
	var ts := _ts()
	if ts == null or ts.current_minute <= TimeSystem.CLOSE:
		return 0
	return ceili((ts.current_minute - TimeSystem.CLOSE) / float(TimeSystem.SLOT_MIN))


## (เดิม "เข้านอน") = ปิดร้าน → กะถัดไป
func sleep() -> void:
	end_shift()


func _continue_after_summary() -> void:
	var week := _pending_summary_week
	_pending_summary_week = 0
	week_results.clear()
	_last_bill = { }
	week_start_money = GameState.money
	if _game_over:
		GameState.finish_game()
	else:
		GameState.play_week_chapter(week)


## เริ่มเกมใหม่หลังฉากจบ: เงิน/คะแนน/เวลา กลับค่าเริ่มต้น
func _reset_run() -> void:
	_game_over = false
	_working = false
	_result_pending = false
	cards_hidden = false
	demo_over = false
	_demo_ack = false
	_show_demo_banner(false)
	_pending_summary_week = 0
	week_results.clear()
	board.clear()
	walkouts.clear()
	_parts_seen.clear()
	_last_bill = { }
	ot_this_week = 0
	last_result = { }
	current_job = { }
	today_case = null
	force_active = false
	_break_done = false
	GameState.reset()
	week_start_money = GameState.money
	var ts := _ts()
	if ts:
		ts.set_shift(1)
		_on_shift_started(ts.month(), ts.week(), ts.shift_in_week())

# ---------------------------------------------------------------- UI


func _process(delta: float) -> void:
	if _ts() == null:
		return
	if _demo_ack and is_instance_valid(_demo_layer):
		_demo_layer.visible = not (DialogScene.visible or Global.in_minigame or PauseMenu.visible)
	_watchdog(delta)
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
			today_case = forced_case
			play_arrival(false)
		return
	if want == Card.NONE:
		_shop_time = 0.0
		_hide()
		_cards_tab.visible = false
		return
	if cards_hidden and want in HIDEABLE:
		_panel.visible = false
		_board_panel.visible = false
		_cards_tab.visible = true
		_cards_tab.text = "📋 กระดานงาน (%d)" % board.size() if want == Card.BOARD else "📋 ดูการ์ดงาน"
		return
	_cards_tab.visible = false
	if want != _card or (want == Card.BOARD and _board_dirty) or not (_board_panel.visible or _panel.visible):
		_show_card(want)


## _working ค้างนานโดยไม่มีบท/มินิเกม/เวลาหมุน (เช่นบทเปิดไม่ขึ้น) → ปลดล็อกให้การ์ดกลับมา
func _watchdog(delta: float) -> void:
	var busy: bool = (
		DialogScene.visible
		or _skipping
		or (is_instance_valid(_minigame))
		or (Fade.anim as AnimationPlayer).is_playing()
	)
	if not _working or busy:
		_stuck_time = 0.0
		return
	_stuck_time += delta
	if _stuck_time < STUCK_LIMIT:
		return
	push_warning("DayLoop: ค้างรอบท/มินิเกมเกิน %.0f วิ — ปลดล็อก" % STUCK_LIMIT)
	if _pending_cb.is_valid() and DialogScene.on_dialog_finish.is_connected(_pending_cb):
		DialogScene.on_dialog_finish.disconnect(_pending_cb)
	_pending_cb = Callable()
	_working = false
	_stuck_time = 0.0


func _decide_card() -> Card:
	if _working or Global.in_minigame or DialogScene.visible or _skipping:
		return Card.NONE
	if demo_over:
		return Card.NONE if _demo_ack else Card.DEMO_END
	if _pending_summary_week > 0:
		return Card.WEEK_SUMMARY
	if _game_over:
		return Card.ENDING if GameState.ending != &"" else Card.NONE
	if not _loop_active() or not _in_shop():
		return Card.NONE
	if _result_pending:
		return Card.RESULT
	if forced_case:
		return Card.JOB_FORCED # ปิดร้านหนีไม่ได้ ต้องซ่อมก่อน
	var ts := _ts()
	if _close_requested or ts.current_minute >= TimeSystem.CLOSE:
		return Card.SHIFT_END
	return Card.BOARD


func _loop_active() -> bool:
	if force_active:
		return true
	var ev = EventManager.eventMap.get(EventManager.EventID.MAIN)
	return ev != null and ev.isDone


func _in_shop() -> bool:
	return SceneRouter.current_id in shop_locations


func _fee(c: CustomerCase) -> int:
	if c == null:
		return 0
	if c.fee >= 0:
		return c.fee
	return _econ().fee_for_level(c.level)


func _stars(level: int) -> String:
	return "★".repeat(clampi(level, 1, 5)) + "☆".repeat(5 - clampi(level, 1, 5))


func _show_card(card: Card) -> void:
	_card = card
	_board_dirty = false
	if card == Card.BOARD:
		_panel.visible = false
		_board_panel.visible = true
		_fill_board()
		return
	_board_panel.visible = false
	_panel.visible = true
	_secondary.visible = false
	var ts := _ts()
	var c := today_case
	match card:
		Card.JOB_FORCED:
			c = forced_case
			_title.text = "งานด่วน! · %s" % c.level_name()
			_body.text = "%s รอเครื่องอยู่\nเครื่อง: %s\nอาการ: %s\n⏱ ~%d ช่อง · ค่าแรง ฿%d" % [
				c.customer,
				c.device,
				c.symptom,
				job_slots(c),
				_fee(c),
			]
			_primary.text = "เริ่มซ่อม"
		Card.RESULT:
			_title.text = "ส่งเครื่องคืนลูกค้า · 🕘 %s" % TimeSystem.clock_text(ts.current_minute)
			var r := last_result
			var money: int = r.get("money", 0)
			var grade: int = clampi(int(r.get("grade", GameState.Grade.PASS)), 0, GRADE_TEXT.size() - 1)
			var money_txt := ("+฿%d" % money) if money >= 0 else ("−฿%d" % -money)
			var quote := ""
			if c:
				var line := c.complain_text if grade == GameState.Grade.FAIL else c.thanks_text
				if line.strip_edges() != "":
					quote = "\n\n%s: \"%s\"" % [c.customer, line]
			var rep: int = r.get("reputation", 0)
			_body.text = "%s%s\nคะแนน %d/100%s\nเงิน %s · ชื่อเสียง %s%d · XP +%d%s" % [
				(c.job_title + " — ") if c and c.job_title != "" else "",
				GRADE_TEXT[grade],
				int(r.get("score", 0)),
				"  (ทำของเสีย!)" if r.get("damaged", false) else "",
				money_txt,
				"+" if rep >= 0 else "",
				rep,
				int(r.get("xp", 0)),
				quote,
			]
			_primary.text = "กลับกระดานงาน"
		Card.SHIFT_END:
			var earned := GameState.money - shift_start_money
			var ot := ot_slots_now()
			_title.text = "ปิดร้าน · กะ %d/%d · 🕘 %s" % [ts.shift_in_week(), TimeSystem.SHIFTS_PER_WEEK, TimeSystem.clock_text(ts.current_minute)]
			_body.text = "งานเสร็จกะนี้ %d งาน · รายได้ %s฿%d\nงานค้างบนกระดาน %d ใบ (ต่อกะหน้า)%s\nชื่อเสียง %d · %s" % [
				shift_results.size(),
				"+" if earned >= 0 else "−",
				absi(earned),
				board.size(),
				("\nล่วงเวลา %d ช่อง · ค่าไฟ ฿%d" % [ot, ot * _econ().ot_cost_per_slot]) if ot > 0 else "",
				GameState.reputation,
				GameState.rank_name(),
			]
			_primary.text = "ปิดร้าน → สรุปสัปดาห์" if ts.is_last_shift_of_week() else "ปิดร้าน → กะถัดไป"
			if is_demo_last_shift():
				_primary.text = "ปิดร้าน → จบการเล่นเดโม"
			if _close_requested and ts.current_minute < TimeSystem.CLOSE:
				_secondary.text = "กลับไปทำงานต่อ"
				_secondary.visible = true
		Card.WEEK_SUMMARY:
			var earned := GameState.money - week_start_money
			var sat := 0.0
			for r in week_results:
				sat += float(r.get("satisfaction", 0))
			sat = sat / week_results.size() if not week_results.is_empty() else 0.0
			sat = sat if is_finite(sat) else 0.0
			var bill := ""
			if not _last_bill.is_empty():
				bill = "\n\nบิลเดือนนี้: ไฟ ฿%d · ช่วยบ้านยาย ฿%d · เน็ต ฿%d\nจ่ายแล้ว ฿%d%s" % [
					int(_last_bill.get("power", 0)),
					int(_last_bill.get("grandma", 0)),
					int(_last_bill.get("internet", 0)),
					int(_last_bill.get("paid", 0)),
					(" · ค้าง ฿%d" % int(_last_bill.get("debt", 0))) if int(_last_bill.get("debt", 0)) > 0 else "",
				]
			_title.text = "สรุปสัปดาห์ %d" % _pending_summary_week
			_body.text = "งานที่ซ่อม %d งาน\nรายได้สัปดาห์นี้ %s฿%d\nความพอใจเฉลี่ย %d · ชื่อเสียง %d\nยศ %s · XP %d%s" % [
				week_results.size(),
				"+" if earned >= 0 else "−",
				absi(earned),
				roundi(sat),
				GameState.reputation,
				GameState.rank_name(),
				GameState.xp,
				bill,
			]
			_primary.text = "ดูฉากจบ" if _game_over else "ไปต่อ (บท Chapter %d)" % (_pending_summary_week + 1)
		Card.ENDING:
			_title.text = "จบเกม"
			_body.text = "%s\n\nเงิน ฿%d · ความพอใจเฉลี่ย %d · ชื่อเสียง %d" % [
				ENDING_TEXT.get(GameState.ending, ""),
				GameState.money,
				roundi(GameState.average_satisfaction()),
				GameState.reputation,
			]
			_primary.text = "กลับหน้าแรก"
		Card.DEMO_END:
			_title.text = "สิ้นสุดการเล่นเดโม · ครบ %d วัน" % demo_shifts
			_body.text = "ขมเปิดร้านมาครบ %d วันแล้ว!\n\nซ่อมไปทั้งหมด %d งาน · เงิน ฿%d\nชื่อเสียง %d · ยศ %s · XP %d\nความพอใจเฉลี่ย %d\n\nกลับบ้านไปพักกับยายกันเถอะ" % [
				demo_shifts,
				GameState.satisfaction_history.size(),
				GameState.money,
				GameState.reputation,
				GameState.rank_name(),
				GameState.xp,
				roundi(GameState.average_satisfaction()),
			]
			_primary.text = "กลับบ้าน"


## กระดานงาน — แถวละ 1 งาน: ลูกค้า · ระดับ · อาการ (ไม่บอก Part) · เวลา · ค่าแรง · กำหนดรับ · [รับงาน] [ปฏิเสธ]
func _fill_board() -> void:
	var ts := _ts()
	for n in _board_list.get_children():
		_board_list.remove_child(n)
		n.queue_free()
	_board_title.text = "กระดานงาน · กะ %d/%d · 🕘 %s · เหลือ %s" % [
		ts.shift_in_week(),
		TimeSystem.SHIFTS_PER_WEEK,
		TimeSystem.clock_text(ts.current_minute),
		TimeSystem.slots_text(floori(ts.remaining_work_minutes() / float(TimeSystem.SLOT_MIN))),
	]
	var note := ""
	if not walkouts.is_empty():
		note = "ลูกค้าเดินออกเพราะรอนานเกิน: %s" % ", ".join(walkouts)
	if board.is_empty():
		note += ("\n" if note != "" else "") + "ยังไม่มีงานรอ — รอลูกค้า หรือปิดร้าน (ช่วงพักบ่ายมักมีโทรเข้า)"
	_board_note.text = note
	_board_note.visible = note != ""
	for i in board.size():
		var job: Dictionary = board[i]
		var c: CustomerCase = job["case"]
		var row := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.55)
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(8)
		row.add_theme_stylebox_override("panel", sb)
		_board_list.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		row.add_child(h)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(text)
		var head := Label.new()
		head.text = "%s%s · %s %s" % ["📞 " if job["phone"] else "", c.customer, c.level_name(), _stars(c.level)]
		head.add_theme_font_size_override("font_size", 17)
		head.add_theme_color_override("font_color", Color(0.35, 0.2, 0.08))
		text.add_child(head)
		var due: int = int(job["due_shift"]) - ts.shift
		var body := Label.new()
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 14)
		body.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1))
		body.text = "อาการ: %s\nมาเพราะ: %s\n⏱ ~%d ช่อง (%s) · ฿%d · %s" % [
			c.symptom,
			c.reason,
			job_slots(c),
			TimeSystem.slots_text(job_slots(c)),
			_fee(c),
			"ต้องเสร็จกะนี้" if due <= 0 else "รับภายใน %d กะ" % due,
		]
		text.add_child(body)
		var btns := VBoxContainer.new()
		h.add_child(btns)
		var take := Button.new()
		take.focus_mode = Control.FOCUS_NONE
		match job_fit(c):
			&"ok":
				take.text = "รับงาน"
			&"ot":
				take.text = "รับงาน\n(ล่วงเวลา)"
			_:
				take.text = "ไม่ทันกะนี้"
				take.disabled = true
		take.pressed.connect(accept_job.bind(i))
		btns.add_child(take)
		var no := Button.new()
		no.focus_mode = Control.FOCUS_NONE
		no.text = "ปฏิเสธ"
		no.pressed.connect(reject_job.bind(i))
		btns.add_child(no)
	_board_wait.disabled = ts.remaining_work_minutes() <= 0


func _on_primary() -> void:
	match _card:
		Card.JOB_FORCED:
			today_case = forced_case
			start_repair()
		Card.RESULT:
			_result_pending = false
			autosave.call_deferred()
		Card.SHIFT_END:
			end_shift()
		Card.WEEK_SUMMARY:
			_continue_after_summary()
		Card.DEMO_END:
			finish_demo()
		Card.ENDING:
			SaveGame.clear()
			Global.on_start = true
			_reset_run()
			SceneRouter.clear()
			var err := get_tree().change_scene_to_file("res://Scene/Start_Scene.tscn")
			if err != OK:
				push_error("DayLoop: กลับหน้าแรกไม่ได้ (error %d)" % err)
	_card = Card.NONE


func _on_secondary() -> void:
	if _card == Card.SHIFT_END:
		_close_requested = false
	_card = Card.NONE


func _hide() -> void:
	_panel.visible = false
	_board_panel.visible = false
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


func _card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.94, 0.87, 0.97)
	sb.border_color = Color(0.45, 0.3, 0.15)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	return sb


func _build_ui() -> void:
	# การ์ดเดี่ยว (งานด่วน · ผลงาน · ปิดร้าน · สรุปสัปดาห์ · ฉากจบ)
	_panel = PanelContainer.new()
	_panel.name = "DayCard"
	_panel.position = Vector2(772, 120)
	_panel.custom_minimum_size = Vector2(364, 0)
	_panel.add_theme_stylebox_override("panel", _card_style())
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	var trow := HBoxContainer.new()
	box.add_child(trow)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color(0.35, 0.2, 0.08))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trow.add_child(_title)
	trow.add_child(_hide_button())
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

	# กระดานงาน
	_board_panel = PanelContainer.new()
	_board_panel.name = "JobBoard"
	_board_panel.position = Vector2(596, 100)
	_board_panel.custom_minimum_size = Vector2(540, 0)
	_board_panel.add_theme_stylebox_override("panel", _card_style())
	add_child(_board_panel)
	var bbox := VBoxContainer.new()
	bbox.add_theme_constant_override("separation", 8)
	_board_panel.add_child(bbox)
	var btrow := HBoxContainer.new()
	bbox.add_child(btrow)
	_board_title = Label.new()
	_board_title.add_theme_font_size_override("font_size", 19)
	_board_title.add_theme_color_override("font_color", Color(0.35, 0.2, 0.08))
	_board_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btrow.add_child(_board_title)
	btrow.add_child(_hide_button())
	_board_note = Label.new()
	_board_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board_note.add_theme_font_size_override("font_size", 14)
	_board_note.add_theme_color_override("font_color", Color(0.6, 0.2, 0.1))
	bbox.add_child(_board_note)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(508, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bbox.add_child(scroll)
	_board_list = VBoxContainer.new()
	_board_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_board_list)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 8)
	bbox.add_child(brow)
	_board_wait = Button.new()
	_board_wait.text = "รอลูกค้า (+30 นาที)"
	_board_wait.focus_mode = Control.FOCUS_NONE
	_board_wait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_wait.pressed.connect(wait_slot)
	brow.add_child(_board_wait)
	_board_close = Button.new()
	_board_close.text = "ปิดร้าน"
	_board_close.focus_mode = Control.FOCUS_NONE
	_board_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_close.pressed.connect(close_shop)
	brow.add_child(_board_close)
	_board_panel.visible = false
	_cards_tab = Button.new()
	_cards_tab.name = "CardsTab"
	_cards_tab.focus_mode = Control.FOCUS_NONE
	_cards_tab.position = Vector2(930, 100)
	_cards_tab.custom_minimum_size = Vector2(206, 44)
	_cards_tab.add_theme_font_size_override("font_size", 18)
	_cards_tab.add_theme_stylebox_override("normal", _card_style())
	_cards_tab.add_theme_stylebox_override("hover", _card_style())
	_cards_tab.add_theme_stylebox_override("pressed", _card_style())
	_cards_tab.add_theme_color_override("font_color", Color(0.35, 0.2, 0.08))
	_cards_tab.add_theme_color_override("font_hover_color", Color(0.6, 0.3, 0.05))
	_cards_tab.pressed.connect(func(): set_cards_hidden(false))
	_cards_tab.visible = false
	add_child(_cards_tab)
	_build_time_skip()


## ย่อ/ขยายกระดาษงาน (ดูฉากข้างหลังได้ · กดแถบมุมขวาเพื่อเปิดคืน)
func set_cards_hidden(on: bool) -> void:
	cards_hidden = on
	_card = Card.NONE # บังคับวาดใหม่ตอนเปิดคืน
	_board_dirty = true


func _hide_button() -> Button:
	var b := Button.new()
	b.text = "ย่อ ▾"
	b.tooltip_text = "ซ่อนกระดาษงาน (กดแถบมุมขวาเพื่อเปิดคืน)"
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func(): set_cards_hidden(true))
	return b
