extends CanvasLayer
## DayLoop (autoload: Scene/Core/day_loop.tscn) — ลูปกะของร้านซ่อม ตาม Docs/LEVEL_DESIGN.md ข้อ 4–6 · 7.4
## [Claude 9 ต.ค. 2569] เขียนใหม่จาก "ลูกค้าวันละ 1 คน" เป็น "กระดานงานหลายใบ + เวลาเป็นช่อง 30 นาที"
##
## 1 กะ (08:30–18:30): เปิดร้าน → กระดานงาน (งานใหม่ตามสัดส่วน Lv1–Lv5 ของสัปดาห์ + งานค้าง)
##   เลือกรับ/ปฏิเสธ · การ์ดบอกแค่อาการ ไม่บอก Part · รับงาน → บทลูกค้า → มินิเกม → นาฬิกาเดินตามช่องของงาน → การ์ดผลงาน
##   พักบ่าย 15:30 มีงานโทรเข้า · 18:30 ปิดร้าน (ล่วงเวลาได้ ≤ 2 ช่อง · ≤ 2 กะ/สัปดาห์) → กะถัดไป
## งานหมดเขต (due_shifts) = ลูกค้าเดินออก ชื่อเสียงลด · งาน Lv n+1 ขึ้นกระดานเมื่อได้ ⭐⭐ ใน Lv n ครบ 2 งาน
## [0.2.5] ครบ 4 วัน (วันที่ 4 · 11 · 18 · 25) = จบบท = สิ้นเดือน → บิล + หน้าสรุปเดือน → บท Chapter ถัดไป · ครบ 48 วัน (12 เดือน) = Epilogue + ฉากจบ
## งานบังคับรายกะ (WeekPlan.shifts) ที่เป็น forced: ลูกค้าเดินเข้ามาเอง ปฏิเสธไม่ได้ (กะแรก = ลุงอำนวย หลังบทพัก Tutorial)
## [0.3.0 ขั้น B] กระดานงาน → ลูกค้ายืนหน้าประตูทีละคน (door_queue) · รับเครื่อง / นัดวันเปิดร้านถัดไป / ปฏิเสธ
##   รับลูกค้าใหม่ได้ daily_cap คน/วัน · รอได้ patience เทิร์นแล้วเดินกลับ · คนนัดมาก่อนรอบ 08:30 วันถัดไป · โทรเข้า = นัดอย่างเดียว
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
## [13 ต.ค.] บทพักเกิดในห้องของขม (ยายเรียกลงไปกินขนม) → ใช้ภาพห้องชุดใหม่แทน HomeBG ลายเส้นเดิม
@export_file("*.png", "*.jpg") var break_bg := "res://Assets/Background/bg_khom_room.jpg"
@export var break_title := "ห้องของขม"
## หลังบทพัก เวลาในเกมเดินไปกี่นาที (08:30 → 09:00 เริ่มงาน)
@export var break_minutes := 30
## แอนิเมชันเวลาหมุนยาวกี่วินาที (เวลาจริง)
@export var time_skip_seconds := 1.0

@export_group("เดโม")
## [Claude 10 ต.ค. 2569] เดโม: ครบกี่กะแล้วจบการเล่น (0 = เล่นเต็ม 60 กะ) → การ์ดสรุป → กลับบ้าน + ป้าย "กำลังพัฒนาให้ครบลูป"
@export var demo_shifts := 8 ## [0.2.5] 8 = จบบทที่ 2 (ครบ ม.ค.–ก.พ. = เห็นสรุปเดือน 2 ครั้ง) · 4 = จบบทที่ 1
## ว่าง = "จบบทที่ n" ตามบทของ demo_shifts
@export var demo_banner_title := ""
## {n} = บทที่จบ · {next} = บทถัดไป
@export_multiline var demo_banner_text := "ขอบคุณที่เปิดร้านบักช่างขมมาด้วยกัน {n} เดือนนะ!\nบทที่ {next} กำลังพัฒนาให้ครบปี\nแล้วพบกันเร็ว ๆ นี้"
## บทปิดท้ายเมื่อกลับถึงบ้าน (ว่าง = ข้าม)
@export_file("*.txt") var chapter_end_dialog := "res://Assets/Dialog/Chapter2End.txt"

## สัดส่วนงาน Lv1/2/3/4/5 (%) ต่อบท 1–12 ([0.2.5] 1 บท = 1 เดือน · LEVEL_DESIGN ข้อ 6) · WeekPlan.level_weights ทับได้
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
	DOOR, ## [0.3.0] ลูกค้าหน้าประตู (แทนกระดานงาน) · ฉาก DoorCard
	WORK_ORDER, ## [0.3.0] ใบรับเครื่อง (เลือกวันนัด) · ฉาก WorkOrderCard
	JOB_FORCED,
	RESULT,
	SHIFT_END,
	WEEK_SUMMARY,
	ENDING,
	DEMO_END,
}

## [0.3.0] ลูกค้ายืนหน้าประตู เรียงคิว (คนแรก = คนที่กำลังคุย) — ดู door_entry()
## { "case": CustomerCase, "phone": bool (โทรเข้า = นัดได้อย่างเดียว), "appointed": bool (นัดไว้ เลื่อนอีกไม่ได้),
##   "free": bool (ไม่นับโควตา: งานเนื้อเรื่องที่ไม่บังคับ/เอาเครื่องมาลองใหม่), "waited": int (นาทีงานที่ยืนรอแล้ว) }
## ไม่ได้รับภายในวัน = กลับบ้านตอนปิดร้าน (rep_left_unserved) · รอเกินความอดทน = เดินกลับ (rep_door_walkout)
var door_queue: Array[Dictionary] = []
## [0.3.0] ลูกค้าที่นัดวันเปิดร้านถัดไป [{ "case", "free" }] → ยืนหน้าประตูเป็นคิวแรกตอนเปิดร้าน (ก่อนรอบ 08:30)
var appointments: Array[Dictionary] = []
## [0.3.0] วันนี้รับลูกค้าใหม่ไปแล้วกี่คน (เทียบ EconomyConfig.daily_cap · คนนัดนับวันที่เขามา · งานเนื้อเรื่อง/free ไม่นับ)
var accepted_today := 0
## [0.3.0] ใบรับเครื่อง + ชั้นวาง (ข้อมูลล้วน · UI ขั้น D) · door_accept(promise >= 0) วางเครื่องงานฮาร์ดแวร์ไว้ที่นี่
var shelf: RepairShelf
## นาทีล่าสุดที่นับความอดทนของคนหน้าประตู (-1 = ยังไม่เริ่ม)
var _door_tick := -1
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
## [0.3.0] วันนี้ใครยืนรอหน้าประตูนานเกินจนเดินกลับ
var walkouts: PackedStringArray = []
## [0.2.5] ลูกค้าที่ไม่ได้รับงานเมื่อวันก่อน กลับบ้านไปแล้ว (แสดงบนกระดานวันถัดไป)
var left_home: PackedStringArray = []
## [0.2.5] ลูกค้ารอบที่ยังไม่มา [{ "minute": int, "count": int }] · รอบแรกมาตอนเปิดร้าน
var visitor_waves: Array[Dictionary] = []
## [0.2.5] ลูกค้าทั้งหมดของวันนี้ (ตามชื่อเสียง) / มาถึงแล้ว
var visitors_today := 0
var visitors_arrived := 0
## [0.2.5] งานที่เพิ่งขึ้นกระดาน (กันซ้ำ) · จำได้กี่งาน
var _recent: Array[CustomerCase] = []
const RECENT_MEMORY := 10
## [0.2.5] ป้ายแจ้งลูกค้าเข้าร้าน (Scene/UI/visitor_toast.tscn ใน ToastLayer ชั้น 104)
const VISITOR_TOAST_SCENE := preload("res://Scene/UI/visitor_toast.tscn")
var visitor_toast: VisitorToast
## [8 พ.ย.] ปุ่ม "งาน" ระหว่างซ่อม (Scene/UI/job_reminder.tscn ใน ReminderLayer ชั้น 11)
const JOB_REMINDER_SCENE := preload("res://Scene/UI/job_reminder.tscn")
var job_reminder: JobReminder
## [0.2.5] ตัวเลขเด้งตอนส่งงาน (Scene/UI/reward_popup.tscn ใน PopupLayer ชั้น 106)
const REWARD_POPUP_SCENE := preload("res://Scene/UI/reward_popup.tscn")
## [0.3.0 ขั้น C–D] ฉากแยก: การ์ดหน้าประตู (DoorLayer 90) · ใบรับเครื่อง (WorkOrderLayer 91) · แผงชั้นวาง (ShelfLayer 95)
const DOOR_CARD_SCENE := preload("res://Scene/UI/door_card.tscn")
## [0.5.0 ขั้น I] หน้าเลื่อนยศ + เลือกความสามารถช่าง (PerkLayer ชั้น 112)
const PERK_PICKER_SCENE := preload("res://Scene/UI/perk_picker.tscn")
var perk_picker: PerkPicker
const WORK_ORDER_SCENE := preload("res://Scene/UI/work_order_card.tscn")
const SHELF_PANEL_SCENE := preload("res://Scene/UI/repair_shelf.tscn")
## [0.4.0 ขั้น J] รถขายของ (VendorLayer ชั้น 92)
const VENDOR_PANEL_SCENE := preload("res://Scene/UI/vendor_panel.tscn")
var vendor_panel: VendorPanel
## รถขายของวันนี้ { items: [id], sold: [bool], arrive: นาที, leave: นาที, told: bool } · ว่าง = ไม่มา
var door_card: DoorCard
var work_order: WorkOrderCard
var shelf_panel: RepairShelfPanel
var vendor: Dictionary = { }
## ใบรับเครื่องเปิดอยู่ (ของคนหน้าประตูตอนนี้)
var _work_order_open := false
## แถวในแผงชั้นวางตอนนี้ (index = แถว) → กด "ซ่อม" แถวไหน
var _shelf_rows: Array[RepairShelf.Order] = []
## [0.3.0] งานบนชั้นล่าสุดที่ซ่อมเสร็จ: { order, pickup: {} (ว่าง = ยังไม่มารับ), paid: {} }
var last_shelf: Dictionary = { }
## [0.3.0] เช้านี้ใครมารับเครื่อง/มาเอาคืน (ข้อความสั้น ไว้โชว์ในการ์ดหน้าร้าน)
var shelf_news: PackedStringArray = []
## [0.3.0 ขั้น E] ส่งมอบเครื่องล่าสุด { order, pickup, paid }
var last_handover: Dictionary = { }
var reward_popup: RewardPopup
var _result_popped := false
var _ot_this_shift := false
var _result_pending := false
## [13 ต.ค.] งานที่ยอมแพ้ → ขึ้นกระดานใหม่ต้นกะถัดไป · _retried = เคยให้ลองใหม่แล้ว (ให้ครั้งเดียว)
var retry_cases: Array[CustomerCase] = []
var _retried: Array[CustomerCase] = []
var _close_requested := false
var _parts_seen: Dictionary = { } # part_id → true (ครั้งแรกใช้เวลา +1 ช่อง)
var _last_bill: Dictionary = { }
## [0.2.0-E] ผลสิ้นเดือนล่าสุด (GameState.close_month) — แสดงในการ์ดสรุปบทที่เป็นสิ้นเดือน
var _last_month: Dictionary = { }
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
var _skip_tw: Tween # [0.2.0] เก็บไว้ให้ debug_goto หยุดได้
## [0.2.0] ข้ามวันระหว่างวันที่ได้เล่น (ปิ๊บ + ปฏิทิน) · รอเล่นตอนการ์ดกระดานจะขึ้นครั้งแรกของวัน
var _day_skip: DaySkip
const DAY_SKIP_SCENE := preload("res://Scene/UI/day_skip.tscn")
const GOAL_BAR_SCENE := preload("res://Scene/UI/month_goal_bar.tscn")
## [0.2.0-D] แถบเป้ากำไรเดือนนี้ (Scene/UI/month_goal_bar.tscn)
var goal_bar: MonthGoalBar
## [0.2.0-E] หน้าสรุปสิ้นเดือน (Scene/UI/month_summary.tscn ใน SummaryLayer ชั้น 108)
const MONTH_SUMMARY_SCENE := preload("res://Scene/UI/month_summary.tscn")
var month_summary: MonthSummary
var _day_skip_pending := false
## เวลาแอนิเมชันข้ามวัน (วินาที) · 0 = ไม่เล่น (เทสต์ตั้งเองได้)
@export var day_skip_seconds := 2.4
## วันธรรมดา (ข้าม 1 วัน ไม่มีเรื่องเกิด) ใช้เวลากี่เท่าของ day_skip_seconds
@export_range(0.1, 1.0) var day_skip_short_ratio := 0.5
## เรื่องที่เกิดระหว่างข้ามวัน (ระบบอื่นใส่ก่อนเปิดร้าน เช่น ของมาถึง · ลูกค้ามารับเครื่อง) — ล้างหลังแสดง
var day_skip_notes := PackedStringArray()
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
var _card := Card.NONE
## [10 ต.ค.] ย่อกระดาษงาน (กระดานงาน · การ์ดงานด่วน/ผลงาน/ปิดร้าน) → เหลือแถบ "กระดานงาน" ให้กดเปิดคืน
var cards_hidden := false
var _cards_tab: Button
const HIDEABLE := [Card.DOOR, Card.JOB_FORCED, Card.RESULT, Card.SHIFT_END]


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
		[GameState.shelf_slots_changed, _on_shelf_slots_changed],
		[GameState.parts_arrived, _on_parts_arrived],
		[GameState.affinity_tier_up, _on_affinity_tier_up],
		[GameState.rank_exam_ready, func(_t: int) -> void: _exam_reminder()],
		[SceneRouter.location_changed, _on_location_changed],
	]
	for l in links:
		if not (l[0] as Signal).is_connected(l[1]):
			(l[0] as Signal).connect(l[1])
	week_start_money = GameState.money
	if shelf == null:
		shelf = RepairShelf.new(_econ())
		shelf.slots = maxi(shelf.slots, GameState.shelf_slots)
	_on_shift_started(ts.month(), ts.week(), ts.shift_in_week())
	_day_skip_pending = false # เริ่มเกม/โหลดเซฟ ไม่ต้องเล่นข้ามวัน
	day_skip_notes.clear()


## [0.2.5] "ชื่อเสียง 25 (ปกติ) · ลูกค้าวันนี้ 3/5 คน · รอบถัดไปอีก 4 เทิร์น"
func visitors_line() -> String:
	var e := _econ()
	var t := e.rep_tier(GameState.reputation)
	var nxt := next_wave_turns()
	var ts := _ts()
	var ev := e.month_event(ts.month() if ts else 1)
	var b := int(ev.bonus)
	return "ชื่อเสียง %d (%s) · ลูกค้าวันนี้มาแล้ว %d/%d คน%s%s" % [
		GameState.reputation,
		e.rep_tier_names[clampi(t, 0, e.rep_tier_names.size() - 1)],
		visitors_arrived,
		visitors_today,
		(" · รอบถัดไปอีก %s" % TimeSystem.turns_text(nxt)) if nxt >= 0 else "",
		("\nเดือนนี้: %s%s" % [ev.name, (" (ลูกค้า %s%d/วัน)" % ["+" if b > 0 else "−", absi(b)]) if b != 0 else ""]) if String(ev.name) != "" else "",
	]


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
	var ts := _ts()
	var m := ts.month() if ts else 1
	for c in random_pool:
		if c == null or c.forced or c.level != lv or not c.in_month(m): # [0.2.5] งานตามฤดู
			continue
		if exclude_board and (is_case_busy(c) or c == today_case):
			continue
		out.append(c)
	return out


## [0.2.5] เลือกงานจากคลังให้หลากหลาย: ไม่เอาคนที่ยืนรอ/นัดไว้/มีเครื่องบนชั้นอยู่แล้ว · ไม่เอางานที่เพิ่งมาไม่นาน (_recent) · ไม่มีให้เลือกค่อยยอมซ้ำ
func _pick_case(pool: Array[CustomerCase]) -> CustomerCase:
	var waiting := { }
	for c in busy_cases():
		waiting[c.customer] = true
	var best: Array[CustomerCase] = pool.filter(func(c: CustomerCase) -> bool: return not waiting.has(c.customer) and not _recent.has(c))
	if best.is_empty():
		best = pool.filter(func(c: CustomerCase) -> bool: return not _recent.has(c))
	if best.is_empty():
		best = pool
	var c := _pick_by_npc(best)
	_recent.append(c)
	while _recent.size() > RECENT_MEMORY:
		_recent.pop_front()
	return c


## [0.5.0 ขั้น C] เลือกคนก่อน (น้ำหนักตามความสนิท · เพิ่งมาไม่นานลดลง) แล้วสุ่มเคสของคนนั้น — คนที่มีเคสเยอะไม่ได้มาบ่อยกว่าคนอื่น
## ไม่เปลี่ยนสัดส่วนระดับงาน (เลือกระดับมาก่อนแล้ว) → ไม่กระทบรายได้
func _pick_by_npc(cases: Array[CustomerCase]) -> CustomerCase:
	var groups := { }
	for c in cases:
		if not groups.has(c.customer):
			groups[c.customer] = []
		(groups[c.customer] as Array).append(c)
	var keys := groups.keys()
	var weights: Array[float] = []
	var total := 0.0
	for k in keys:
		var w := npc_weight(groups[k][0])
		weights.append(w)
		total += w
	var pick: Array = groups[keys[0]]
	var r := _rng.randf() * total
	for i in keys.size():
		r -= weights[i]
		if r <= 0.0:
			pick = groups[keys[i]]
			break
	return pick[_rng.randi_range(0, pick.size() - 1)]


## น้ำหนักที่คนเจ้าของเคสจะเดินมาร้าน (ลูกค้าขาจร = 1)
func npc_weight(c: CustomerCase) -> float:
	var n := NpcBook.of_case(c)
	if n == null:
		return 1.0
	var e := _econ()
	var w := n.base_weight
	if n.has_affinity:
		w *= e.affinity_mult(GameState.affinity_tier(n.id))
	var ts := _ts()
	if ts and GameState.visited_recently(n.id, ts.shift):
		w *= e.affinity_recent_mult
	return maxf(w, 0.001)


## [0.3.0] เคสที่มีเจ้าของอยู่ในร้านแล้ว (ยืนหน้าประตู · นัดไว้ · เครื่องอยู่บนชั้น) — ไม่สุ่มซ้ำ
func busy_cases() -> Array[CustomerCase]:
	var out: Array[CustomerCase] = []
	for j in door_queue:
		out.append(j["case"] as CustomerCase)
	for a in appointments:
		out.append(a["case"] as CustomerCase)
	if shelf:
		for o: RepairShelf.Order in shelf.orders:
			out.append(o.case)
	return out


func is_case_busy(c: CustomerCase) -> bool:
	return busy_cases().has(c)


## [0.3.0] ลูกค้า 1 คนหน้าประตู
func door_entry(c: CustomerCase, phone := false, appointed := false, free := false, waited := 0) -> Dictionary:
	var ts := _ts()
	GameState.note_visit(npc_id(c), ts.shift if ts else 0) # [0.5.0] มาร้าน (ลดโอกาสมาซ้ำ 2 วัน)
	return { "case": c, "phone": phone, "appointed": appointed, "free": free, "waited": waited }


## [0.3.0] สุ่มลูกค้าใหม่ n คนมายืนต่อคิวหน้าประตู (ไม่ซ้ำคนที่อยู่ในร้าน · คิวยาวสุด board_max) · คืนจำนวนที่มาได้จริง
## waited = มาถึงก่อนตอนนี้กี่นาทีงาน (รอบที่มาระหว่างผู้เล่นทำงานอยู่) · ทุกคนได้ยืนให้เห็นอย่างน้อย 1 เทิร์น
func add_visitors(n: int, phone := false, waited := 0) -> int:
	var ts := _ts()
	if ts == null:
		return 0
	var e := _econ()
	var added := 0
	for k in n:
		if door_queue.size() >= e.board_max:
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
		var c := _pick_case(pool)
		var cap_wait := maxi(door_patience_slots(c) - 1, 0) * TimeSystem.SLOT_MIN
		door_queue.append(door_entry(c, phone, false, false, clampi(waited, 0, cap_wait)))
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
	_day_skip_pending = ts.shift > 1 and day_skip_seconds > 0.0
	# [0.3.0] ลูกค้าที่ยังยืนหน้าประตูตอนปิดร้านเมื่อวันก่อน = กลับบ้าน · ล้างโควตา
	walkouts.clear()
	left_home.clear()
	pending_story = { }
	story_today = false
	helper_used_today = 0
	_auto_handover()
	for j in door_queue:
		left_home.append((j["case"] as CustomerCase).customer)
		GameState.add_reputation(_econ().rep_left_unserved)
		affinity_for(j["case"], &"walk_out")
	door_queue.clear()
	accepted_today = 0
	# คิวแรกของวัน (ก่อนรอบ 08:30): คนที่นัดไว้ → งานเนื้อเรื่องที่ไม่บังคับ → คนเอาเครื่องมาลองใหม่
	for a in appointments:
		door_queue.append(door_entry(a["case"], false, true, bool(a.get("free", false))))
	appointments.clear()
	var fc := case_for(week, shift_in_week)
	forced_case = fc if fc and fc.forced else null
	if fc and not fc.forced and not is_case_busy(fc):
		door_queue.append(door_entry(fc, false, false, true))
	for rc in retry_cases:
		if rc and not is_case_busy(rc):
			door_queue.append(door_entry(rc, false, false, true))
	retry_cases.clear()
	close_work_order()
	_deliver_parcels(ts)
	_open_shelf_day(ts)
	assign_parts()
	_plan_vendor(ts)
	_door_tick = ts.current_minute
	_plan_visitors(ts)
	_board_dirty = true
	autosave.call_deferred()


## [0.2.5] ลูกค้าวันนี้ = ฐานของเดือน + โบนัสชื่อเสียง → แบ่งเป็นรอบ (08:30 · 11:00 · 14:00) · รอบแรกเข้าทันที
func _plan_visitors(ts: TimeSystem) -> void:
	var e := _econ()
	visitors_today = e.visitors_for(ts.month(), GameState.reputation)
	# [0.5.0 ขั้น H] ยศประจำหมู่บ้านขึ้นไป: ผู้ใหญ่บ้านประกาศเสียงตามสายวันแรกของเดือน
	var announced := GameState.rank() >= e.announce_rank and ts.shift_in_week() == 1
	if announced:
		visitors_today += e.announce_extra_visitors
	visitors_arrived = 0
	visitor_waves.clear()
	var counts := e.split_waves(visitors_today)
	for i in counts.size():
		if counts[i] > 0:
			visitor_waves.append({ "minute": e.visitor_waves[i] if i < e.visitor_waves.size() else TimeSystem.OPEN, "count": counts[i] })
	var tier := e.rep_tier(GameState.reputation)
	if visitor_toast:
		visitor_toast.clear()
		# [0.2.5] วันแรกของเดือน → ป้ายเทศกาลก่อน
		var ev := e.month_event(ts.month())
		if ts.shift_in_week() == 1 and String(ev.name) != "":
			visitor_toast.show_message("%s · %s" % [TimeSystem.MONTH_FULL[clampi(ts.month(), 1, 12) - 1], ev.name], String(ev.note))
		if announced:
			visitor_toast.show_message("ผู้ใหญ่บ้านประกาศเสียงตามสาย", "\"ใครคอมเสีย ไปร้านขมได้เด้อ\" · วันนี้ลูกค้า +%d" % e.announce_extra_visitors)
		visitor_toast.show_message(
			"วันนี้มีลูกค้า %d คน" % visitors_today,
			"ชื่อเสียงร้าน %d (%s) · ทยอยมาตลอดวัน" % [GameState.reputation, e.rep_tier_names[clampi(tier, 0, e.rep_tier_names.size() - 1)]],
		)
	_check_waves(ts, false)
	_exam_reminder()


## [0.2.5] ลูกค้ารอบที่ถึงเวลาแล้วเดินเข้าร้าน · เลยเวลาปิดร้านแล้ว = ไม่มา (ไม่หักชื่อเสียง)
func _check_waves(ts: TimeSystem, notify := true) -> void:
	if ts == null or visitor_waves.is_empty():
		return
	if ts.current_minute >= TimeSystem.CLOSE:
		visitor_waves.clear()
		return
	var came := 0
	while not visitor_waves.is_empty() and int(visitor_waves[0]["minute"]) <= ts.current_minute:
		var w: Dictionary = visitor_waves.pop_front()
		var late := TimeSystem.work_minutes_between(int(w["minute"]), ts.current_minute) if int(w["minute"]) > TimeSystem.OPEN else 0
		came += add_visitors(int(w["count"]), false, late)
	if came <= 0:
		return
	visitors_arrived += came
	_board_dirty = true
	if notify and visitor_toast:
		visitor_toast.show_message("มีลูกค้ามารอหน้าร้าน %d คน" % came, door_toast_note())


## [0.2.5] รอบถัดไปมาอีกกี่เทิร์น (-1 = ไม่มีแล้ว)
func next_wave_turns() -> int:
	var ts := _ts()
	if ts == null or visitor_waves.is_empty():
		return -1
	return floori(TimeSystem.work_minutes_between(ts.current_minute, int(visitor_waves[0]["minute"])) / float(TimeSystem.SLOT_MIN))


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
		var n := add_visitors(_econ().board_phone_jobs, true)
		if n > 0 and visitor_toast:
			visitor_toast.show_message("โทรศัพท์ดัง! ลูกค้าโทรมา %d สาย" % n, "โทรมาขอนัดเอาเครื่องมาวันเปิดร้านถัดไป")


func _on_clock_changed(_minute: int) -> void:
	_board_dirty = true
	_tick_door(_ts())
	_check_waves(_ts())
	_check_vendor(_ts())


## [0.3.0] "ยืนรอหน้าประตู · วันนี้รับได้อีก 2 คน" / "วันนี้คิวเต็มแล้ว นัดวันถัดไปได้"
func door_toast_note() -> String:
	var left := quota_left()
	return "ยืนรอหน้าประตู · วันนี้รับได้อีก %d คน" % left if left > 0 else "วันนี้รับครบแล้ว — นัดวันเปิดร้านถัดไปได้"


## [0.3.0] ความอดทนเดินตามเวลางาน (ไม่นับพักเที่ยง/พักบ่าย) · ระหว่างงานเนื้อเรื่องบังคับ/บทพักไม่นับ (ผู้เล่นเลือกไม่ได้)
## รอครบ patience เทิร์น → เดินกลับ ชื่อเสียง rep_door_walkout · เวลาถอยหลัง (Debug/เทส set_clock) = เริ่มนับใหม่
func _tick_door(ts: TimeSystem) -> void:
	if ts == null:
		return
	var now := ts.current_minute
	var prev := _door_tick
	_door_tick = now
	if prev < 0 or now <= prev or forced_case != null or door_queue.is_empty():
		return
	var dt := TimeSystem.work_minutes_between(prev, now)
	if dt <= 0:
		return
	var e := _econ()
	var gone: Array[Dictionary] = []
	for j in door_queue:
		if is_pickup(j):
			continue
		j["waited"] = int(j.get("waited", 0)) + dt
		if int(j["waited"]) >= door_patience_slots(j["case"]) * TimeSystem.SLOT_MIN:
			gone.append(j)
	for j in gone:
		door_queue.erase(j)
		var who := (j["case"] as CustomerCase).customer
		walkouts.append(who)
		GameState.add_reputation(e.rep_door_walkout)
		affinity_for(j["case"], &"walk_out")
		if visitor_toast:
			visitor_toast.show_message("%s รอนานเกินไป เดินกลับแล้ว" % who, "ชื่อเสียง %d" % e.rep_door_walkout)
	if not gone.is_empty():
		_board_dirty = true


## [0.3.0] รอได้อีกกี่เทิร์น (ปัดลง)
func door_patience_left(j: Dictionary) -> int:
	var c: CustomerCase = j["case"]
	return maxi(door_patience_slots(c) - floori(int(j.get("waited", 0)) / float(TimeSystem.SLOT_MIN)), 0)


func _on_week_ended(week: int) -> void:
	_pending_summary_week = week
	ot_this_week = 0


func _on_month_ended(month: int) -> void:
	# [0.2.5] ยิงทุกบท (1 บท = 1 เดือน) · ยิงก่อน TimeSystem ล้าง worked_minutes_month จึงยังอ่านเทิร์นของบทนี้ได้
	_last_bill = GameState.pay_month_bill(month, _ts().work_slots_used_this_month() if _ts() else 0)
	# [0.2.0-E/F] ปิดเดือน: เทียบกำไรกับเป้า · นับพลาดเป้า/ค้างบิล · ร้านปิด → ไปฉากจบ
	_last_month = GameState.close_month(month)
	if bool(_last_month.get("shop_closed", false)):
		_game_over = true


func _on_game_ended() -> void:
	_game_over = true


func _on_repair_recorded(result: Dictionary) -> void:
	var c := today_case
	var order: RepairShelf.Order = current_job.get("order") as RepairShelf.Order
	# [13 ต.ค.] ยอมแพ้งาน → ลูกค้าเอาเครื่องกลับมาให้ลองใหม่วันถัดไป 1 ครั้ง (งานเนื้อเรื่อง forced ไม่วนซ้ำ · งานบนชั้นคืนตามสภาพตอนมารับ)
	if c and order == null and result.get("gave_up", false) and not c.forced and not _retried.has(c):
		_retried.append(c)
		retry_cases.append(c)
	if c:
		var ts := _ts()
		if ts:
			ts.advance_minutes(job_slots(c) * TimeSystem.SLOT_MIN)
			ts.snap_to_slot()
		_parts_seen[c.part_id] = true
		if c == forced_case:
			forced_case = null
	# [0.4.0 ขั้น F] ของสิ้นเปลืองหักจริงตอนซ่อมจบ (เวลาเดินไปแล้วตาม job_slots ซึ่งนับ +เทิร์นถ้าของขาด)
	if c and not result.get("gave_up", false):
		GameState.use_supplies(c.supply_need(_econ()))
	# [0.3.0 ขั้น D] งานบนชั้น: เก็บผลไว้ · ถึง/เลยนัดแล้ว → ลูกค้ามารับเลย จ่ายเงินตอนนี้
	last_shelf = { }
	if order and _order_damaged(order, result):
		# [0.4.0 ขั้น G] ทำของเสีย + มีอะไหล่ชดใช้ → เครื่องกลับไปรอของ ไม่ปิดงาน
		result = result.duplicate()
		result["replace"] = order.replace_part
		result["reputation"] = int(result.get("rep_due", 0))
		last_shelf = { "order": order, "pickup": { }, "paid": { }, "replace": order.replace_part }
	elif order:
		var ts := _ts()
		result = _settle_parts(order, result)
		var p := shelf.finish(order, result, ts.shift if ts else 1)
		last_shelf = { "order": order, "pickup": p, "paid": { } }
		if not p.is_empty():
			var paid := _pay_pickup(p)
			last_shelf["paid"] = paid
			result = result.duplicate()
			result["money"] = paid["money"]
			result["reputation"] = paid["reputation"]
			result["satisfaction"] = paid["satisfaction"]
			result["affinity"] = paid.get("affinity", 0)
			result["npc_name"] = paid.get("npc_name", "")
	# [0.5.0 ขั้น B] งานต่อหน้าลูกค้า (ขมOS · งานเนื้อเรื่อง) → ความสนิท + ทิปคนสนิทตอนนี้ · งานบนชั้นคิดตอนมารับ (_pay_pickup)
	if c and order == null:
		var aff := affinity_result(c, result)
		result = result.duplicate()
		result["affinity"] = aff["delta"]
		result["npc_name"] = aff["name"]
		if int(aff["tip"]) > 0:
			result["money"] = int(result.get("money", 0)) + int(aff["tip"])
	current_job = { }
	last_result = result
	_result_pending = true
	_result_popped = false
	shift_results.append(result)
	week_results.append(result)
	_working = false

# ---------------------------------------------------------------- งาน


## เวลาของงาน (ช่อง) · ครั้งแรกที่เจอมินิเกมนั้น +1 ช่อง (ปิ๊บสอนเต็ม)
func job_slots(c: CustomerCase) -> int:
	if c == null:
		return 0
	var e := _econ()
	var extra := e.no_supply_extra_slots if not GameState.has_supplies(c.supply_need(e)) else 0
	return c.slots(e) + (e.first_time_extra_slots if not _parts_seen.has(c.part_id) else 0) + extra


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


# ---------------------------------------------------------------- หน้าประตู (0.3.0)


## คนที่ยืนหน้าประตูตอนนี้ ({} = ไม่มี)
func door_front() -> Dictionary:
	return door_queue[0] if not door_queue.is_empty() else { }


## วันนี้รับลูกค้าใหม่ได้อีกกี่คน
func quota_left() -> int:
	return maxi(_econ().daily_cap - accepted_today, 0)


## รับคนหน้าประตูได้ไหม: promise < 0 = ซ่อมเลยตอนนี้ · promise >= 0 = ออกใบรับเครื่อง (index ของ promise_days) วางบนชั้น
## &"ok" · &"ot" (ต้องล่วงเวลา) · &"no" (เทิร์นไม่พอ) · &"full" (ครบโควตาวันนี้) · &"phone" (โทรมา นัดได้อย่างเดียว) · &"shelf_full" · &"none"
func door_accept_state(promise := -1) -> StringName:
	var j := door_front()
	if j.is_empty() or _working:
		return &"none"
	if is_pickup(j):
		return &"pickup"
	if bool(j.get("phone", false)):
		return &"phone"
	if not bool(j.get("free", false)) and quota_left() <= 0:
		return &"full"
	var c: CustomerCase = j["case"]
	if promise >= 0 and c.takes_machine():
		return &"shelf_full" if shelf == null or shelf.is_full() else &"ok"
	return job_fit(c)


## รับเครื่องคนหน้าประตู → นับโควตา (ยกเว้น free)
## promise < 0 หรืองานขมOS: บทลูกค้า → มินิเกมเลย (เหมือนกระดานงานเดิม) · promise >= 0 + งานฮาร์ดแวร์: ใบรับเครื่องขึ้นชั้น แล้วบทลูกค้า (ไม่ซ่อมตอนนี้)
func door_accept(promise := -1) -> bool:
	var st := door_accept_state(promise)
	if st not in [&"ok", &"ot"]:
		return false
	var j: Dictionary = door_queue.pop_front()
	var c: CustomerCase = j["case"]
	if not bool(j.get("free", false)):
		accepted_today += 1
	if bool(j.get("appointed", false)):
		affinity_for(c, &"kept_appointment") # [0.5.0] นัดแล้วรับจริง
	_board_dirty = true
	if promise >= 0 and c.takes_machine():
		var ts := _ts()
		var o := shelf.add(c, ts.shift if ts else 1, promise)
		if o == null:
			return false
		assign_parts(false)
		today_case = c
		play_arrival(false)
		return true
	if st == &"ot":
		var ts := _ts()
		ts.overtime = true
		if not _ot_this_shift:
			_ot_this_shift = true
			ot_this_week += 1
	current_job = j
	today_case = c
	play_arrival(true)
	return true


## นัดคนหน้าประตูมาเป็นคิวแรกของวันเปิดร้านถัดไป · ไม่กินโควตาวันนี้ ไม่หักชื่อเสียง · คนที่นัดไว้แล้วเลื่อนอีกไม่ได้ · วันสุดท้ายของเกมนัดไม่ได้
func door_can_appoint() -> bool:
	var j := door_front()
	var ts := _ts()
	return not j.is_empty() and not _working and not is_pickup(j) and not bool(j.get("appointed", false)) and ts != null and ts.shift < TimeSystem.TOTAL_SHIFTS


func door_appoint() -> bool:
	if not door_can_appoint():
		return false
	var j: Dictionary = door_queue.pop_front()
	appointments.append({ "case": j["case"], "free": bool(j.get("free", false)) })
	_board_dirty = true
	return true


## ปฏิเสธคนหน้าประตู → ชื่อเสียง rep_reject
func door_reject() -> bool:
	if door_queue.is_empty() or _working or is_pickup(door_front()):
		return false
	var rj: Dictionary = door_queue.pop_front()
	GameState.add_reputation(_econ().rep_reject)
	affinity_for(rj["case"], &"reject")
	_board_dirty = true
	return true


## ไม่มีงานที่อยากรับ — รอลูกค้า 30 นาที
func wait_slot() -> void:
	var ts := _ts()
	if ts:
		ts.advance_minutes(TimeSystem.SLOT_MIN)


## [0.3.0 ขั้น I] บอทปรับสมดุล/เทสต์: ไม่เล่นบทลูกค้า (รับเครื่องขึ้นชั้นได้ทันที)
var quiet := false


## ลูกค้าเดินเข้าร้าน → บทพูด · then_repair = จบบทแล้วเปิดมินิเกมต่อเลย
func play_arrival(then_repair: bool) -> void:
	if today_case == null:
		return
	if quiet and not then_repair:
		arrived_today = true
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
		and EventManager.play_story_dialog("", path, bg, DialogUtil.speakers_in(path))
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
	GameState.hold_next_payment = false # ปิดมินิเกมโดยไม่มีผล → อย่าให้ค้างไปงานถัดไป
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
	if EventManager.play_story_dialog(break_title, break_dialog, break_bg, DialogUtil.speakers_in(break_dialog)):
		_wait_dialog(_after_break)
	else:
		_after_break()


## [0.3.0 ขั้น J] บทสอนครั้งแรกต่อเกม (เก็บใน GameState.story_flags เข้าเซฟ) · ปิดได้ด้วย tutorials = false (เทสต์/บอท)
@export var tutorials := true
const TUTORIALS := {
	"tut_pickup": "res://Assets/Dialog/Tutorial/pickup_first.txt",
	"tut_door": "res://Assets/Dialog/Tutorial/door_first.txt",
	"tut_shelf": "res://Assets/Dialog/Tutorial/shelf_first.txt",
	# [0.4.0 ขั้น K] อะไหล่
	"tut_part_missing": "res://Assets/Dialog/Tutorial/part_missing_first.txt",
	"tut_parcel": "res://Assets/Dialog/Tutorial/parcel_first.txt",
	"tut_part_pay": "res://Assets/Dialog/Tutorial/part_pay_first.txt",
	"tut_damage_replace": "res://Assets/Dialog/Tutorial/damage_replace_first.txt",
	"tut_vendor": "res://Assets/Dialog/Tutorial/vendor_first.txt",
	# [0.5.0 ขั้น L] ลูกค้าประจำ + ยศ
	"tut_affinity": "res://Assets/Dialog/Tutorial/affinity_first.txt",
	"tut_story": "res://Assets/Dialog/Tutorial/story_first.txt",
	"tut_exam": "res://Assets/Dialog/Tutorial/exam_first.txt",
	"tut_helper": "res://Assets/Dialog/Tutorial/helper_first.txt",
}


## คืน true = เปิดบทสอนแล้ว (เฟรมนี้ไม่ต้องโชว์การ์ด)
func _maybe_tutorial(want: Card) -> bool:
	if not tutorials or quiet or _working or not _in_shop() or Global.in_minigame or DialogScene.visible:
		return false
	var flag := ""
	if want == Card.DOOR and not door_queue.is_empty():
		flag = "tut_pickup" if is_pickup(door_front()) else "tut_door"
	if (flag == "" or GameState.story_flags.get(flag, false)) and not shelf.orders.is_empty() and want in [Card.DOOR, Card.NONE]:
		flag = "tut_shelf"
	# [0.4.0 ขั้น K] อะไหล่: เครื่องรอของครั้งแรก · พัสดุมาครั้งแรก · ลูกค้ามารับพร้อมจ่ายค่าอะไหล่ครั้งแรก · ทำของเสียต้องชดใช้ · รถขายของ
	if want in [Card.DOOR, Card.NONE] and (flag == "" or GameState.story_flags.get(flag, false)):
		for f in _part_tutorials() + _npc_tutorials():
			if not GameState.story_flags.get(f, false):
				flag = f
				break
	if flag == "" or GameState.story_flags.get(flag, false):
		return false
	GameState.story_flags[flag] = true
	var path: String = TUTORIALS[flag]
	_working = true
	_hide()
	if EventManager.play_story_dialog("", path, "res://Assets/Background/bg_shop_open.jpg", DialogUtil.speakers_in(path)):
		_wait_dialog(func() -> void:
			_pending_cb = Callable()
			_working = false)
	else:
		_working = false
	return true


## บทสอนอะไหล่ที่ถึงเงื่อนไขตอนนี้ (เรียงตามลำดับที่ควรเจอ)
func _part_tutorials() -> Array[String]:
	var out: Array[String] = []
	if not last_shelf.is_empty() and last_shelf.get("replace", &"") != &"" and not _result_pending:
		out.append("tut_damage_replace")
	for o in shelf.orders:
		if not order_has_parts(o) and o.replace_part == &"":
			out.append("tut_part_missing")
			break
	if shelf_news.size() > 0 and Array(shelf_news).any(func(n: String) -> bool: return n.begins_with("พัสดุมาส่ง")):
		out.append("tut_parcel")
	var j := door_front()
	if not j.is_empty() and is_pickup(j) and int((j["pickup"]["order"] as RepairShelf.Order).result.get("part_due", 0)) > 0:
		out.append("tut_part_pay")
	if vendor_here():
		out.append("tut_vendor")
	return out


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
	if ts.show_clock:
		_skip_caption.text = ("%d นาทีต่อมา…" % minutes) if minutes < 60 else ("%d ชั่วโมงต่อมา…" % floori(minutes / 60.0))
	else:
		_skip_caption.text = "เวลาผ่านไป…"
	_skip_clock.text = _skip_text(from)
	_skip_overlay.modulate.a = 0.0
	_skip_overlay.visible = true
	var tw := create_tween()
	_skip_tw = tw
	tw.tween_property(_skip_overlay, "modulate:a", 1.0, 0.2)
	tw.tween_method(_skip_step, float(from), float(to), maxf(seconds, 0.05))
	tw.tween_interval(0.15)
	tw.tween_property(_skip_overlay, "modulate:a", 0.0, 0.2)
	await tw.finished
	if is_instance_valid(ts):
		ts.set_clock(to)
	_skip_overlay.visible = false
	_skipping = false


## [0.2.0-E] ข้อความสรุปเดือน (ใช้ในการ์ดสรุปบทที่เป็นสิ้นเดือน)
func month_summary_text(rep: Dictionary, bill: Dictionary = { }) -> String:
	var by: Dictionary = rep.get("by_kind", { })
	var b := func(n: int) -> String: return MonthGoalBar._baht(n)
	var parts_in := PackedStringArray()
	var parts_out := PackedStringArray()
	for k in [&"fee", &"part_fee", &"tip", &"sell", &"other"]:
		if int(by.get(k, 0)) > 0:
			parts_in.append("%s %s" % [GameState.MONEY_KINDS[k], b.call(int(by[k]))])
	for k in [&"bill", &"buy", &"ot_power", &"damage", &"other"]:
		if int(by.get(k, 0)) < 0:
			parts_out.append("%s %s" % [GameState.MONEY_KINDS[k], b.call(-int(by[k]))])
	var lines := PackedStringArray()
	lines.append("รายรับ %s%s" % [b.call(int(rep.income)), (" (" + " · ".join(parts_in) + ")") if not parts_in.is_empty() else ""])
	lines.append("รายจ่าย %s%s" % [b.call(int(rep.expense)), (" (" + " · ".join(parts_out) + ")") if not parts_out.is_empty() else ""])
	if not bill.is_empty():
		lines.append("   บิล: ค่าเช่าที่ %s · ไฟ %s · น้ำ %s · เน็ต %s%s%s" % [
			b.call(int(bill.get("rent", 0))), b.call(int(bill.get("power", 0))), b.call(int(bill.get("water", 0))), b.call(int(bill.get("internet", 0))),
			(" · ยอดค้างเดิม " + b.call(int(bill.prev_debt))) if int(bill.get("prev_debt", 0)) > 0 else "",
			(" · ค่าปรับ " + b.call(int(bill.late_fee))) if int(bill.get("late_fee", 0)) > 0 else "",
		])
	if int(rep.invest) > 0:
		lines.append("ลงทุน %s (ไม่นับในกำไร)" % b.call(int(rep.invest)))
	if GameState.inventory_value() > 0:
		lines.append("ของในคลังมูลค่า %s (ซื้อไว้ยังไม่ได้ใช้)" % b.call(GameState.inventory_value()))
	var aff := GameState.affinity_summary(int(rep.get("m", 0)))
	if aff != "":
		lines.append("ความสนิทเดือนนี้: " + aff)
	var result := ""
	if bool(rep.get("over", false)):
		result = "เกินเป้า!"
	elif bool(rep.reached):
		result = "ถึงเป้าแล้ว!"
	elif not bool(rep.get("counted", true)):
		result = "ยังไม่ถึงเป้า (ช่วงเรียนรู้ ยังไม่นับ)"
	else:
		result = "ไม่ถึงเป้า (พลาด %d/%d เดือนติด)" % [int(rep.get("missed_months", 0)), _econ().fail_missed_months]
	lines.append("กำไร %s / เป้า %s → %s" % [b.call(int(rep.profit)), b.call(int(rep.target)), result])
	if int(rep.get("debt", 0)) > 0:
		lines.append("ค้างบิล %s (ค้าง %d/%d เดือนติด)" % [b.call(int(rep.debt)), int(rep.get("debt_streak", 0)), _econ().fail_debt_months])
	if bool(rep.get("shop_closed", false)):
		lines.append("ร้านไปต่อไม่ไหวแล้ว…")
	lines.append("ปิ๊บ: " + String(rep.get("hint", "")))
	return "\n".join(lines)


func _play_day_skip() -> void:
	var ts := _ts()
	if ts == null or _day_skip == null:
		return
	_skipping = true
	_hide()
	var gap := ts.days_since_last_play()
	var today := ts.calendar_date()
	var from_day := today.x - gap
	if from_day < 1:
		from_day += TimeSystem.days_in_month(today.y - 1 if today.y > 1 else 12)
	var notes := day_skip_notes.duplicate()
	day_skip_notes.clear()
	# [0.2.5] ในเดือนเดียวกัน (7 วัน) เล่นสั้นกว่า · ข้ามเดือน (9–10 วัน) เล่นเต็ม
	var secs := day_skip_seconds * (day_skip_short_ratio if gap <= 7 and notes.is_empty() else 1.0)
	await _day_skip.play(from_day, today.x, today.y, gap, notes, secs)
	_skipping = false


## [0.2.0 · Debug] กระโดดไปกะ s เวลา minute แบบเริ่มวันใหม่จริง (กระดานงาน/ลูกค้าบังคับของวันนั้น)
## เดิม Debug ใช้ ts.set_shift() เฉย ๆ → แอนิเมชันเวลาหมุนที่ค้างอยู่เขียนเวลากลับเป็น 09:00 และลูกค้าบังคับของวันเดิมโผล่มา
## ห้ามเรียกตอนบทพูด/มินิเกมเปิดอยู่ (ปิดบทก่อน ไม่งั้น callback ของบทจะทำงานผิดวัน)
func debug_goto(s: int, minute := TimeSystem.CLOSE) -> bool:
	var ts := _ts()
	if ts == null or DialogScene.visible or Global.in_minigame or is_instance_valid(_minigame):
		push_warning("debug_goto: ปิดบทพูด/มินิเกมก่อน")
		return false
	if _skip_tw and _skip_tw.is_valid():
		_skip_tw.kill()
	_skip_overlay.visible = false
	_skipping = false
	_break_done = true
	_working = false
	_result_pending = false
	_pending_summary_week = 0
	ts.set_shift(s)
	_on_shift_started(ts.month(), ts.week(), ts.shift_in_week())
	_day_skip_pending = false
	forced_case = null
	today_case = null
	ts.set_clock(minute)
	_board_dirty = true
	return true


func _skip_step(v: float) -> void:
	var ts := _ts()
	if ts:
		ts.set_clock(int(v))
	_skip_clock.text = _skip_text(int(v))


## ข้อความใหญ่ตอนเวลาหมุน: นาฬิกา หรือ "เหลือ N เทิร์น"
func _skip_text(minute: int) -> String:
	var ts := _ts()
	if ts == null or ts.show_clock:
		return TimeSystem.clock_text(minute)
	return "เหลือ " + TimeSystem.turns_text(floori(TimeSystem.work_minutes_between(minute, TimeSystem.CLOSE) / float(TimeSystem.SLOT_MIN)))


## เวลาที่งานใช้: "3 เทิร์น" (โหมดเทิร์น) หรือ "~3 ช่อง (1½ ชม.)" (โหมดนาฬิกา)
func _cost_text(slots: int) -> String:
	var ts := _ts()
	if ts and not ts.show_clock:
		return TimeSystem.turns_text(slots)
	return "~%d ช่อง (%s)" % [slots, TimeSystem.slots_text(slots)]


## ตอนนี้: นาฬิกา หรือ "เหลือ N เทิร์น"
func _now_text() -> String:
	var ts := _ts()
	if ts == null:
		return ""
	return (TimeSystem.clock_text(ts.current_minute) + " น.") if ts.show_clock else ("เหลือ " + TimeSystem.turns_text(ts.turns_left()))


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
	_auto_handover()
	var ot := ot_slots_now()
	if ot > 0:
		GameState.add_money(-ot * _econ().ot_cost_per_slot, &"ot_power", "ล่วงเวลา %d เทิร์น" % ot)
	if is_demo_last_shift():
		demo_over = true
		_close_requested = false
		_board_dirty = true
		return
	ts.end_shift()


## [0.2.5] บทที่เดโมจบ (จาก demo_shifts)
func demo_chapter() -> int:
	return clampi(floori((maxi(demo_shifts, 1) - 1) / float(TimeSystem.SHIFTS_PER_WEEK)) + 1, 1, 12)


## [0.2.5] ชื่อหัวป้ายจบเดโม ("จบบทที่ 2" ถ้า demo_banner_title ว่าง)
func demo_title() -> String:
	return demo_banner_title if demo_banner_title != "" else "จบบทที่ %d" % demo_chapter()


## กะนี้เป็นกะสุดท้ายของเดโมไหม
func is_demo_last_shift() -> bool:
	var ts := _ts()
	return demo_shifts > 0 and ts != null and ts.shift >= demo_shifts


## การ์ดจบเดโม → กลับบ้าน → ป้าย "กำลังพัฒนาให้ครบลูป"
func finish_demo() -> void:
	_demo_ack = true
	_hide()
	await SceneRouter.go(SceneRouter.HOME) # เปลี่ยนฉาก → autosave
	# [10 ต.ค.] บทปิดบทกับยาย ก่อนขึ้นหน้าจบบท
	if chapter_end_dialog != "" and EventManager.play_story_dialog(demo_title(), chapter_end_dialog, "res://Assets/Background/bg_home_inside.jpg", ["ขม", "ยาย"]):
		await DialogScene.on_dialog_finish
	_show_demo_banner(true)


## [10 ต.ค.] หน้าจบเดโม: พื้นมืด + การ์ดกลางจอ ตัวใหญ่ (ชั้น 115 เหนือ HUD) · "อยู่ในบ้านต่อ" = ย่อเป็นป้ายเล็กด้านล่าง
func _show_demo_banner(on: bool) -> void:
	if not is_instance_valid(_demo_banner):
		_build_demo_banner()
	(_demo_card.find_child("Text", true, false) as Label).text = demo_banner_text.replace("{n}", str(demo_chapter())).replace("{next}", str(demo_chapter() + 1))
	(_demo_card.find_child("Title", true, false) as Label).text = demo_title()
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
	_demo_badge.text = "★ %s · กดเพื่อดูอีกครั้ง" % demo_title()
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
	_last_month = { }
	week_start_money = GameState.money
	if _game_over:
		GameState.finish_game()
	else:
		GameState.play_week_chapter(week)


## เริ่มเกมใหม่หลังฉากจบ: เงิน/คะแนน/เวลา กลับค่าเริ่มต้น
func _reset_run() -> void:
	exam = { }
	pending_story = { }
	story_today = false
	_game_over = false
	_working = false
	_result_pending = false
	cards_hidden = false
	demo_over = false
	_demo_ack = false
	_show_demo_banner(false)
	_pending_summary_week = 0
	week_results.clear()
	door_queue.clear()
	appointments.clear()
	accepted_today = 0
	_door_tick = -1
	shelf = RepairShelf.new(_econ())
	vendor = { }
	_last_location = -1
	_work_order_open = false
	_pending_repair = null
	quiet = false
	last_shelf = { }
	last_handover = { }
	shelf_news.clear()
	retry_cases.clear()
	_retried.clear()
	walkouts.clear()
	left_home.clear()
	_recent.clear()
	visitor_waves.clear()
	visitors_today = 0
	visitors_arrived = 0
	_parts_seen.clear()
	_last_bill = { }
	_last_month = { }
	ot_this_week = 0
	last_result = { }
	current_job = { }
	today_case = null
	force_active = false
	_break_done = false
	GameState.reset()
	shelf.slots = GameState.shelf_slots
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
	if shelf_panel:
		shelf_panel.show_view(shelf_view())
	if vendor_panel:
		vendor_panel.show_view(vendor_view())
	_run_pending_repair(delta)
	var want := _decide_card()
	# [0.2.0] วันใหม่: ปิ๊บบอก "ผ่านไป n วัน" ก่อนการ์ดแรกของวัน (หลังสรุปเดือน/บทเนื้อเรื่องจบแล้ว)
	if _day_skip_pending and want in [Card.DOOR, Card.JOB_FORCED, Card.SHIFT_END]:
		_day_skip_pending = false
		_play_day_skip()
		return
	# ก่อนลูกค้าคนแรก: บทพัก → เวลาหมุน break_minutes นาที (ครั้งเดียวต่อเกม)
	if want == Card.JOB_FORCED and not arrived_today and not _break_done and break_dialog != "":
		_play_break()
		return
	# [0.3.0 ขั้น J] บทสอนสั้นครั้งแรก (หน้าประตู · ชั้นวาง · มารับเครื่อง)
	if _maybe_tutorial(want):
		return
	# [0.5.0 ขั้น E] เรื่องส่วนตัวของลูกค้าประจำ (หลังส่งงาน/ส่งมอบเครื่อง)
	if _maybe_story(want):
		return
	# [0.5.0 ขั้น I] เลื่อนยศแล้วยังไม่เลือกความสามารถ → หน้าเลือก (บังการ์ดจนกว่าจะเลือก)
	if _maybe_perk():
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
		_avoid_goal_card()
		return
	if cards_hidden and want in HIDEABLE:
		_panel.visible = false
		_board_panel.visible = false
		work_order.visible = false
		_cards_tab.visible = true
		_cards_tab.text = "หน้าร้าน (%d)" % door_queue.size() if want == Card.DOOR else "ดูการ์ดงาน"
		_place_cards_tab()
		return
	_cards_tab.visible = false
	_avoid_goal_card()
	if want != _card or (want in [Card.DOOR, Card.WORK_ORDER] and _board_dirty) or not (_board_panel.visible or _panel.visible or work_order.visible or (month_summary and month_summary.visible)):
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
	if _work_order_open:
		var j := door_front()
		if not j.is_empty() and (j["case"] as CustomerCase).takes_machine():
			return Card.WORK_ORDER
		_work_order_open = false
	return Card.DOOR


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
	if card == Card.DOOR:
		_panel.visible = false
		work_order.visible = false
		_board_panel.visible = true
		_fill_door()
		return
	if card == Card.WORK_ORDER:
		_panel.visible = false
		_board_panel.visible = false
		work_order.show_view(work_order_view())
		return
	work_order.visible = false
	_board_panel.visible = false
	_panel.visible = true
	_secondary.visible = false
	if month_summary:
		month_summary.visible = false
	var ts := _ts()
	var c := today_case
	match card:
		Card.JOB_FORCED:
			c = forced_case
			_title.text = "งานด่วน! · %s" % c.level_name()
			_body.text = "%s รอเครื่องอยู่\nเครื่อง: %s\nอาการ: %s\nใช้ %s · ค่าแรง ฿%d" % [
				c.customer,
				c.device,
				c.symptom,
				_cost_text(job_slots(c)),
				_fee(c),
			]
			_primary.text = "เริ่มซ่อม"
		Card.RESULT:
			_title.text = "ส่งเครื่องคืนลูกค้า · %s" % _now_text()
			var r := last_result
			if not _result_popped and reward_popup:
				_result_popped = true
				reward_popup.pop_result(r)
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
			if r.get("gave_up", false):
				_title.text = "Task Fail · ส่งเครื่องคืนตามสภาพ"
				_body.text += "\n\nไม่เป็นไรนะ! ลูกค้าจะเอาเครื่องกลับมาให้ลองใหม่วันพรุ่งนี้" if c and not c.forced and last_shelf.is_empty() else ""
			# [0.3.0 ขั้น D] งานบนชั้น: ลูกค้ามารับเลย (ถึง/เลยนัด) หรือวางรอบนชั้นจนวันนัด
			if not last_shelf.is_empty():
				var o: RepairShelf.Order = last_shelf["order"]
				var p: Dictionary = last_shelf["pickup"]
				if last_shelf.get("replace", &"") != &"":
					# [0.4.0 ขั้น G] ทำของเสีย → ต้องหาอะไหล่มาชดใช้ก่อนซ่อมใหม่
					_title.text = "ทำของลูกค้าเสีย · ต้องหาของมาชดใช้"
					_body.text = "%sคะแนน %d/100 · ชื่อเสียง %d · XP +%d\n\nต้องหา %s มาเปลี่ยนให้%s (ขมจ่ายเอง ลูกค้าไม่จ่ายค่าชิ้นนี้)\nได้ของแล้วซ่อมใหม่ได้ · นัดรับเดิม %s\nถ้าไม่หาของจนลูกค้ามาเอาคืน ต้องจ่ายค่าเสียหายเท่าราคาของ" % [
						(c.job_title + " — ") if c and c.job_title != "" else "",
						int(r.get("score", 0)),
						int(r.get("rep_due", 0)),
						int(r.get("xp", 0)),
						part_name(last_shelf["replace"]),
						o.case.customer,
						due_text(o.due),
					]
				elif p.is_empty():
					_title.text = "ซ่อมเสร็จ · วางรอบนชั้น" if not r.get("gave_up", false) else "Task Fail · วางเครื่องคืนบนชั้น"
					_body.text = "%s%s\nคะแนน %d/100%s · XP +%d\n\n%s มารับเครื่อง %s\nค่าแรง ~฿%d ได้ตอนลูกค้ามารับ" % [
						(c.job_title + " — ") if c and c.job_title != "" else "",
						GRADE_TEXT[grade],
						int(r.get("score", 0)),
						"  (ทำของเสีย!)" if r.get("damaged", false) else "",
						int(r.get("xp", 0)),
						o.case.customer,
						due_text(o.due),
						roundi(maxi(int(r.get("money_due", 0)), 0) * _econ().promise_mult(o.promise)),
					]
					if int(r.get("part_due", 0)) > 0:
						_body.text += " + ค่าอะไหล่ ฿%d" % int(r.get("part_due", 0))
				else:
					_title.text = "%s มารับเครื่อง · %s" % [o.case.customer, "ทันนัด" if p["on_time"] else "ช้า %d วัน" % int(p["late"])]
					_body.text += "\n%s" % ("ทันนัด ความพอใจ +%d" % int(p["sat_delta"]) if p["on_time"] else "ช้ากว่านัด ค่าแรง ×%.2f · ความพอใจ %d" % [float(p["mult"]), int(p["sat_delta"])])
			_primary.text = "กลับหน้าร้าน"
		Card.SHIFT_END:
			var earned := GameState.money - shift_start_money
			var ot := ot_slots_now()
			_title.text = "ปิดร้าน · %s %d/%d%s" % ["กะ" if ts.show_clock else "วันที่", ts.shift_in_week(), TimeSystem.SHIFTS_PER_WEEK, (" · " + TimeSystem.clock_text(ts.current_minute) + " น.") if ts.show_clock else ""]
			# [0.3.0] คนที่ยังยืนหน้าประตู → กลับบ้านตอนปิดร้าน · คนที่นัดไว้มาวันเปิดร้านถัดไป
			var unserved := door_queue.filter(func(q: Dictionary) -> bool: return not is_pickup(q)).size()
			var waiting_pickup := door_queue.size() - unserved
			var board_line := "ลูกค้าหน้าร้าน %d คนยังไม่ได้คุย จะกลับบ้าน (ชื่อเสียง %d)" % [unserved, unserved * _econ().rep_left_unserved] if unserved > 0 else "คุยกับลูกค้าหน้าร้านครบทุกคน"
			if waiting_pickup > 0:
				board_line += "\nลูกค้ารอรับเครื่อง %d คน — ปิดร้านแล้วส่งมอบให้เลย" % waiting_pickup
			if not walkouts.is_empty():
				board_line += "\nรอนานจนเดินกลับ %d คน" % walkouts.size()
			if not appointments.is_empty():
				board_line += "\nนัดไว้วันเปิดร้านถัดไป %d คน" % appointments.size()
			_body.text = "งานเสร็จวันนี้ %d งาน · รายได้ %s฿%d\n%s%s\nชื่อเสียง %d · %s" % [
				shift_results.size(),
				"+" if earned >= 0 else "−",
				absi(earned),
				board_line,
				("\nล่วงเวลา %s · ค่าไฟ ฿%d" % [_cost_text(ot), ot * _econ().ot_cost_per_slot]) if ot > 0 else "",
				GameState.reputation,
				GameState.rank_name(),
			]
			_primary.text = "ปิดร้าน → สรุปเดือน" if ts.is_last_shift_of_week() else "ปิดร้าน → วันถัดไป"
			if is_demo_last_shift():
				_primary.text = "ปิดร้าน → จบบทที่ %d" % ts.chapter()
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
			var mi := clampi(GameState.month_of(_pending_summary_week), 1, TimeSystem.MONTH_NAME.size()) - 1
			var week_line := "งานที่ซ่อม %d งาน · ความพอใจเฉลี่ย %d · ชื่อเสียง %d · ยศ %s (XP %d)" % [
				week_results.size(), roundi(sat), GameState.reputation, GameState.rank_name(), GameState.xp,
			]
			if _last_month.is_empty():
				_title.text = "สรุปบทที่ %d (%s)" % [_pending_summary_week, TimeSystem.MONTH_FULL[mi]]
				_body.text = "%s\nเงินเพิ่ม/ลดเดือนนี้ %s%s" % [week_line, "+" if earned >= 0 else "", MonthGoalBar._baht(earned)]
			else:
				# [0.2.0-E] สิ้นเดือน: รายรับ/รายจ่ายแยกหมวด · ลงทุน · กำไรเทียบเป้า · ผล · ปิ๊บบอกสาเหตุ
				_title.text = "สิ้นเดือน %s · สรุปบทที่ %d" % [TimeSystem.MONTH_NAME[mi], _pending_summary_week]
				_body.text = "%s\n\n%s" % [week_line, month_summary_text(_last_month, _last_bill)]
			_primary.text = ("ร้านไปต่อไม่ไหว… ดูฉากจบ" if GameState.shop_closed else "ดูฉากจบ") if _game_over else "ไปต่อ (บทที่ %d)" % (_pending_summary_week + 1)
			if not _last_month.is_empty() and month_summary:
				# สิ้นเดือน → ใช้หน้าสรุปแบบตาราง (ฉากแยก) แทนการ์ดข้อความ
				_panel.visible = false
				month_summary.show_report(_title.text, week_line, _last_month, _last_bill, _primary.text)
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
			var nxt := GameState.xp_next()
			_title.text = "%s · เปิดร้านครบ %d วัน" % [demo_title(), demo_shifts]
			_body.text = "ขมเปิดร้านมาครบ %d วันแล้ว!\n\nซ่อมไปทั้งหมด %d งาน · เงิน ฿%d\nชื่อเสียง %d · ความพอใจเฉลี่ย %d\nยศช่าง: %s (%s)%s\n\nกลับบ้านไปเล่าให้ยายฟังกันเถอะ" % [
				demo_shifts,
				GameState.satisfaction_history.size(),
				GameState.money,
				GameState.reputation,
				roundi(GameState.average_satisfaction()),
				GameState.rank_name(),
				("XP %d/%d" % [GameState.xp, nxt]) if nxt > 0 else "XP %d" % GameState.xp,
				"  ★ เลื่อนขั้นแล้ว!" if GameState.rank() > 0 else "",
			]
			_primary.text = "กลับบ้าน"


## [0.3.0 ขั้น C] การ์ดหน้าประตู (ฉาก DoorCard) ← door_view()
func _fill_door() -> void:
	door_card.show_view(door_view())


## ข้อมูลที่การ์ดหน้าประตูแสดง (ดู DoorCard.show_view)
func door_view() -> Dictionary:
	var ts := _ts()
	var e := _econ()
	var v := { }
	if ts.show_clock:
		v["title"] = "หน้าร้าน · กะ %d/%d · %s น. · เหลือ %s" % [
			ts.shift_in_week(),
			TimeSystem.SHIFTS_PER_WEEK,
			TimeSystem.clock_text(ts.current_minute),
			TimeSystem.slots_text(floori(ts.remaining_work_minutes() / float(TimeSystem.SLOT_MIN))),
		]
	else:
		v["title"] = "หน้าร้าน · วันที่ %d/%d · เหลือ %s" % [ts.shift_in_week(), TimeSystem.SHIFTS_PER_WEEK, TimeSystem.turns_text(ts.turns_left())]
	v["quota"] = "รับแล้ว %d/%d" % [accepted_today, e.daily_cap]
	v["quota_full"] = quota_left() <= 0
	var note := visitors_line()
	if quota_left() <= 0:
		note += "\nวันนี้คิวเต็มแล้ว — นัดลูกค้าวันเปิดร้านถัดไปได้"
	for s in shelf_news:
		note += "\n" + s
	if not left_home.is_empty():
		note += "\nวันก่อนไม่ได้คุย กลับบ้านไป: %s (ชื่อเสียง %d/คน)" % [", ".join(left_home), e.rep_left_unserved]
	if not walkouts.is_empty():
		note += "\nรอนานเกินจนเดินกลับ: %s" % ", ".join(walkouts)
	v["note"] = note
	v["empty"] = "ยังไม่มีลูกค้าหน้าร้าน — ซ่อมเครื่องบนชั้นวาง รอรอบถัดไป หรือปิดร้าน (ช่วงพักบ่ายมักมีโทรเข้า)"
	v["front"] = _door_front_view(door_front())
	if door_queue.size() > 1:
		var rest := PackedStringArray()
		for k in range(1, door_queue.size()):
			var j: Dictionary = door_queue[k]
			rest.append("%s%s (รอได้อีก %s)" % [
				(j["case"] as CustomerCase).customer,
				" [โทรมา]" if bool(j.get("phone", false)) else (" [นัดไว้]" if bool(j.get("appointed", false)) else ""),
				TimeSystem.turns_text(door_patience_left(j)),
			] if not is_pickup(j) else "%s [มารับเครื่อง]" % (j["case"] as CustomerCase).customer)
		v["queue"] = "รอคิวอีก %d คน: %s" % [door_queue.size() - 1, " · ".join(rest)]
	else:
		v["queue"] = ""
	v["wait_disabled"] = ts.remaining_work_minutes() <= 0
	return v


func _door_front_view(j: Dictionary) -> Dictionary:
	if j.is_empty():
		return { }
	if is_pickup(j):
		return _pickup_front_view(j)
	var c: CustomerCase = j["case"]
	var phone := bool(j.get("phone", false))
	var f := { }
	f["name"] = "%s · %s %s%s" % [npc_name(c), c.level_name(), _stars(c.level), "  · นัดไว้" if bool(j.get("appointed", false)) else ""]
	f["bond"] = bond_line(c)
	f["detail"] = "%sอาการ: %s\nมาเพราะ: %s\nใช้ %s · ค่าแรง ฿%d · %s" % [
		("เครื่อง: %s\n" % c.device) if c.device != "" else "",
		c.symptom,
		c.reason,
		_cost_text(job_slots(c)),
		_fee(c),
		"รับเครื่องไว้ซ่อมบนชั้น" if c.takes_machine() else "ทำต่อหน้าลูกค้า (ขมOS)",
	]
	var pl := part_line(c)
	if pl != "":
		f["detail"] += "\n" + pl
	f["portrait"] = Global.getCharacterTexture(c.customer) if Global.hasCharacter(c.customer) else null
	f["patience_left"] = door_patience_left(j)
	f["patience_max"] = door_patience_slots(c)
	f["phone"] = phone
	var acc := { "text": "รับเครื่อง", "disabled": false, "visible": true, "tooltip": "" }
	var st := door_accept_state(1 if c.takes_machine() else -1)
	match st:
		&"ok":
			acc["text"] = "รับเครื่อง" if c.takes_machine() else "รับงาน\n(ทำเลย)"
			acc["tooltip"] = "ออกใบรับเครื่อง เลือกวันนัด แล้ววางเครื่องบนชั้น" if c.takes_machine() else "นั่งทำงานขมOS ต่อหน้าลูกค้าเลย"
		&"ot":
			acc["text"] = "รับงาน\n(ล่วงเวลา)"
		&"full":
			acc["text"] = "วันนี้คิวเต็ม"
			acc["disabled"] = true
			acc["tooltip"] = "รับลูกค้าใหม่ได้วันละ %d คน" % _econ().daily_cap
		&"shelf_full":
			acc["text"] = "ชั้นเต็ม"
			acc["disabled"] = true
			acc["tooltip"] = "ชั้นวางเต็ม %d/%d — ซ่อมเครื่องบนชั้นให้ลูกค้ามารับก่อน" % [shelf.used(), shelf.slots]
		&"phone":
			acc["visible"] = false
		_:
			acc["text"] = "เทิร์นไม่พอ"
			acc["disabled"] = true
	f["accept"] = acc
	var app := { "text": "นัดวันเปิด\nร้านถัดไป", "disabled": not door_can_appoint(), "tooltip": "" }
	if bool(j.get("appointed", false)):
		app["tooltip"] = "นัดไว้แล้ว เลื่อนอีกไม่ได้"
	f["appoint"] = app
	f["reject_disabled"] = _working
	f["helper"] = helper_button(j)
	return f


## [0.3.0 ขั้น E] ลูกค้ามารับเครื่อง: บอกผลซ่อม · ค่าแรงที่จะได้ (ทันนัด/ช้า) · ปุ่ม "ส่งมอบเครื่อง" อย่างเดียว
func _pickup_front_view(j: Dictionary) -> Dictionary:
	var p: Dictionary = j["pickup"]
	var o: RepairShelf.Order = p["order"]
	var c := o.case
	var failed := int(o.result.get("grade", 0)) == GameState.Grade.FAIL
	var m := pickup_money(p)
	var when := "ทันนัด ความพอใจ +%d" % int(p["sat_delta"]) if p["on_time"] else "ช้ากว่านัด %d วัน ค่าแรง ×%.2f ความพอใจ %d" % [int(p["late"]), float(p["mult"]), int(p["sat_delta"])]
	return {
		"name": "%s · มารับเครื่อง" % npc_name(c),
		"bond": bond_line(c),
		"detail": "%s%s\n%s\n%s" % [
			("เครื่อง: %s\n" % c.device) if c.device != "" else "",
			"งานไม่ผ่าน — คืนเครื่องตามสภาพ" if failed else "ซ่อมเสร็จแล้ว (คะแนน %d/100)" % int(o.result.get("score", 0)),
			(("ค่าแรง ฿%d" % (m - int(o.result.get("part_due", 0)))) + ((" + ค่าอะไหล่ ฿%d" % int(o.result.get("part_due", 0))) if int(o.result.get("part_due", 0)) > 0 else "")) if m >= 0 else ("ชดใช้ของเสีย −฿%d" % -m),
			when,
		],
		"portrait": Global.getCharacterTexture(c.customer) if Global.hasCharacter(c.customer) else null,
		"phone": false,
		"patience_text": "รอรับเครื่องอยู่หน้าร้าน",
		"accept": { "text": "ส่งมอบเครื่อง", "disabled": _working, "visible": true, "tooltip": "ส่งเครื่องคืนลูกค้า แล้วรับค่าแรง" },
		"appoint": { "visible": false },
		"reject_hidden": true,
	}


## ปุ่ม "รับเครื่อง" ที่การ์ดหน้าประตู: งานฮาร์ดแวร์ → เปิดใบรับเครื่อง · งานขมOS → ทำเลย
func _on_door_accept() -> void:
	var j := door_front()
	if j.is_empty():
		return
	var c: CustomerCase = j["case"]
	if is_pickup(j):
		door_handover()
	elif c.takes_machine():
		open_work_order()
	else:
		door_accept(-1)


# ---------------------------------------------------------------- ชั้นวางเครื่อง (0.3.0 ขั้น D)


## [0.3.0 ขั้น F] ซื้ออัปเกรดชั้นวาง/โหลดเซฟ → ชั้นขยาย
func _on_shelf_slots_changed(n: int) -> void:
	if shelf:
		shelf.slots = maxi(n, shelf.used())
	_board_dirty = true


## ซ่อมเครื่องบนชั้นได้ไหม: &"ok" · &"ot" (ล่วงเวลา) · &"no" (เทิร์นไม่พอ) · &"busy" (มีงาน/การ์ดอื่นค้าง · ไม่ได้อยู่ในร้าน) · &"done" (ซ่อมแล้ว)
func shelf_repair_state(o: RepairShelf.Order) -> StringName:
	if o == null or not shelf.orders.has(o):
		return &"busy"
	if o.state != RepairShelf.State.WAITING:
		return &"done"
	if not order_has_parts(o):
		return &"no_part"
	if _working or _work_order_open or _decide_card() != Card.DOOR:
		return &"busy"
	return job_fit(o.case)


## ซ่อมเครื่องบนชั้น → มินิเกม (ลูกค้าไม่อยู่ ไม่มีบทพูด) · ผลเก็บไว้จ่ายตอนลูกค้ามารับ (GameState.hold_next_payment)
func shelf_repair(o: RepairShelf.Order) -> bool:
	var st := shelf_repair_state(o)
	if st not in [&"ok", &"ot"]:
		return false
	if st == &"ot":
		var ts := _ts()
		ts.overtime = true
		if not _ot_this_shift:
			_ot_this_shift = true
			ot_this_week += 1
	current_job = { "case": o.case, "order": o }
	today_case = o.case
	GameState.hold_next_payment = true
	start_repair()
	if not is_instance_valid(_minigame):
		GameState.hold_next_payment = false
		current_job = { }
		return false
	if shelf_panel:
		shelf_panel.close()
	return true


func _on_shelf_repair_pressed(i: int) -> void:
	if i >= 0 and i < _shelf_rows.size():
		shelf_repair(_shelf_rows[i])


## ลูกค้ามารับเครื่อง → จ่ายเงิน (RepairShelf.pickup) · คืนข้อความสั้น "ครู มารับเครื่อง +฿150 (ทันนัด)"
func _pay_pickup(p: Dictionary) -> Dictionary:
	var o: RepairShelf.Order = p["order"]
	var paid := GameState.pay_pickup(o.result, float(p["mult"]), int(p["sat_delta"]), String(o.case.part_id))
	# [0.4.0] ค่าอะไหล่ (ราคาที่ซื้อ + ค่าบวกตามยศ) — ลูกค้าจ่ายเต็ม ไม่คูณตามความช้า
	var part_due := int(o.result.get("part_due", 0))
	if part_due > 0:
		GameState.add_money(part_due, &"part_fee", String(o.result.get("part_name", "")))
		paid["money"] = int(paid["money"]) + part_due
	paid["part"] = part_due
	# [0.5.0 ขั้น B] ความสนิทตอนมารับ: ผลงาน + ทันนัด/เลยนัด · ทิปคนสนิท
	var aff := affinity_result(o.case, o.result, bool(p["on_time"]), int(p["late"]))
	paid["affinity"] = aff["delta"]
	paid["npc_name"] = aff["name"]
	paid["money"] = int(paid["money"]) + int(aff["tip"])
	_release_order(o)
	var m := int(paid["money"])
	paid["text"] = "%s มารับเครื่อง %s (%s)" % [
		o.case.customer,
		("+฿%d" % m) if m >= 0 else ("−฿%d" % -m),
		"ทันนัด" if p["on_time"] else "ช้า %d วัน" % int(p["late"]),
	]
	return paid


## เปิดร้าน: ลูกค้าที่เครื่องซ่อมเสร็จและถึงนัด → เดินมายืนหน้าประตูเป็นคิวแรก (กด "ส่งมอบเครื่อง" ถึงได้เงิน)
## เครื่องค้างเลยผ่อนผัน → มาเอาคืน (ชื่อเสียง rep_returned) · บอกงานที่ครบนัด/เลยนัด · ปิ๊บบอกตอนข้ามวัน (day_skip_notes)
func _open_shelf_day(ts: TimeSystem) -> void:
	shelf_news.clear()
	if shelf == null or ts == null:
		return
	var e := _econ()
	var od := shelf.open_day(ts.shift)
	var picked: Array = od["picked"]
	var front: Array[Dictionary] = []
	for p: Dictionary in picked:
		var o: RepairShelf.Order = p["order"]
		front.append(pickup_entry(p))
		_skip_note("วันนี้%sจะมารับเครื่อง" % o.case.customer)
	for k in range(front.size() - 1, -1, -1):
		door_queue.push_front(front[k])
	for o: RepairShelf.Order in od["returned"]:
		if o.replace_part != &"":
			# [0.4.0 ขั้น G] ทำของเสียแล้วไม่หาของมาชดใช้ → ลูกค้ามาเอาคืน + จ่ายค่าของแทน
			var rep_item := part_item(o.replace_part)
			var pen := rep_item.online_cost() if rep_item else e.default_penalty
			GameState.add_money(-pen, &"damage", "ชดใช้%s" % (rep_item.display_name if rep_item else ""))
			shelf_news.append("%s มาเอาเครื่องคืน ไม่ได้ของชดใช้ — จ่ายค่าเสียหาย ฿%d" % [o.case.customer, pen])
		_release_order(o)
		GameState.add_reputation(e.rep_returned)
		affinity_for(o.case, &"reclaimed")
		GameState.satisfaction_history.append(e.returned_satisfaction)
		shelf_news.append("%s มาเอาเครื่องคืน (ไม่ได้ซ่อม เลยนัด) ชื่อเสียง %d" % [o.case.customer, e.rep_returned])
		_skip_note("%sรอไม่ไหว มาเอาเครื่องคืนแล้ว…" % o.case.customer)
	for o: RepairShelf.Order in od["late_waiting"]:
		shelf_news.append("เลยนัด %s %d วัน! ซ่อมให้เสร็จวันนี้" % [o.case.customer, o.late_days(ts.shift)])
		_skip_note("เครื่องของ%sเลยนัดมา %d วันแล้ว!" % [o.case.customer, o.late_days(ts.shift)])
	for o: RepairShelf.Order in od["due_today"]:
		shelf_news.append("วันนี้ครบนัด %s — ซ่อมเสร็จลูกค้ามารับเลย" % o.case.customer)
		_skip_note("วันนี้ครบนัด%s แต่เครื่องยังไม่ได้ซ่อมนะ" % o.case.customer)
	if not picked.is_empty() and visitor_toast:
		visitor_toast.show_message("ลูกค้ามารับเครื่อง %d คน" % picked.size(), "ยืนรอหน้าร้าน — กด \"ส่งมอบเครื่อง\"")


# ---------------------------------------------------------------- อะไหล่ผูกกับงาน (0.4.0 · PLAN_0_4_0 ข้อ 2)


static func part_item(id: StringName) -> ItemDef:
	if id == &"":
		return null
	var p := "res://Resources/Shop/%s.tres" % id
	return load(p) as ItemDef if ResourceLoader.exists(p) else null


## ชื่ออะไหล่สั้น ๆ (ตัดวงเล็บท้าย)
static func part_name(id: StringName) -> String:
	var it := part_item(id)
	return it.display_name if it else String(id)


## ของชดใช้เมื่อทำของลูกค้าเสียใน Part นี้ (ItemDef.replaces) · null = ไม่มี (หักค่าปรับแบบเดิม)
static func replacement_for(part_id: StringName) -> ItemDef:
	for f in DirAccess.get_files_at("res://Resources/Shop/"):
		var path := "res://Resources/Shop/" + f.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var it := load(path) as ItemDef
		if it and it.replaces == part_id and it.kind == ItemDef.Kind.PART:
			return it
	return null


## เครื่องนี้มีอะไหล่ครบ (จองไว้แล้ว / ไม่ต้องใช้) พร้อมซ่อมไหม
func order_has_parts(o: RepairShelf.Order) -> bool:
	if o == null:
		return false
	if not o.part_ids().is_empty() and GameState.reserved_index(o.key) < 0:
		return false
	if o.replace_part != &"" and GameState.reserved_index(o.replace_key()) < 0:
		return false
	return true


## อะไหล่ที่เครื่องนี้ยังขาด (ชื่อ) · ว่าง = ครบ
func order_missing_parts(o: RepairShelf.Order) -> PackedStringArray:
	var out := PackedStringArray()
	if o == null:
		return out
	var ids := o.part_ids()
	if not ids.is_empty() and GameState.reserved_index(o.key) < 0:
		out.append(part_name(ids[0]))
	if o.replace_part != &"" and GameState.reserved_index(o.replace_key()) < 0:
		out.append("%s (ชดใช้)" % part_name(o.replace_part))
	return out


## ข้อความรอของ: "ถ่าน CMOS (สั่งแล้ว มาวันเปิดร้านถัดไป)" / "การ์ดจอมือสอง (ชดใช้) — สั่งออนไลน์" / "… — ซื้อที่ตลาดหรือสั่งออนไลน์"
func missing_note(o: RepairShelf.Order) -> String:
	var ids := waiting_ids(o)
	if ids.is_empty():
		return ""
	var it := part_item(ids[0])
	var name := (it.display_name if it else String(ids[0])) + (" (ชดใช้)" if o.replace_part == ids[0] else "")
	for id in ids:
		if GameState.pending_count(id) > 0:
			return "%s · สั่งแล้ว มาวันเปิดร้านถัดไป" % name
	if it and not it.market:
		return "%s — สั่งในแอปร้านออนไลน์" % name
	return "%s — ซื้อที่ตลาดหรือสั่งออนไลน์" % name


## จองอะไหล่ในคลังให้เครื่องที่ยังรอของ (นัดใกล้สุดก่อน) · คืนข้อความที่จองได้
func assign_parts(notify := true) -> PackedStringArray:
	var done := PackedStringArray()
	if shelf == null:
		return done
	for o in shelf.waiting():
		var ids := o.part_ids()
		if not ids.is_empty() and GameState.reserved_index(o.key) < 0:
			var i := GameState.reserve(ids, o.key)
			if i >= 0:
				done.append("จอง%sให้เครื่อง%sแล้ว" % [part_name(GameState.inventory[i].id), o.case.customer])
		if o.replace_part != &"" and GameState.reserved_index(o.replace_key()) < 0:
			if GameState.reserve([o.replace_part], o.replace_key()) >= 0:
				done.append("ได้%sมาชดใช้ให้%sแล้ว ซ่อมใหม่ได้" % [part_name(o.replace_part), o.case.customer])
	if not done.is_empty():
		_board_dirty = true
		if notify and visitor_toast and not quiet:
			visitor_toast.show_message("อะไหล่พร้อมแล้ว", " · ".join(done))
	return done


# ---------------------------------------------------------------- รถขายของ (0.4.0 ขั้น J · PLAN_0_4_0 ข้อ 6)


## เปิดร้าน: สุ่มว่ารถขายของมาไหม (ไม่มาวันแรกของบท) · ของสุ่ม vendor_items ชิ้นจากอะไหล่ที่ขายออนไลน์
func _plan_vendor(ts: TimeSystem) -> void:
	vendor = { }
	var e := _econ()
	var chance := e.perk_vendor_chance if GameState.has_perk(&"connected") else e.vendor_chance # [0.5.0] มีเส้นสาย
	if ts == null or ts.shift_in_week() == 1 or chance <= 0.0 or _rng.randf() >= chance:
		return
	var n_items := e.perk_vendor_items if GameState.has_perk(&"connected") else e.vendor_items
	var pool: Array[ItemDef] = online_catalog().filter(func(it: ItemDef) -> bool: return it.kind == ItemDef.Kind.PART)
	var ids: Array = []
	while not pool.is_empty() and ids.size() < n_items:
		var it: ItemDef = pool.pop_at(_rng.randi_range(0, pool.size() - 1))
		ids.append(String(it.id))
	if ids.is_empty():
		return
	vendor = { "items": ids, "sold": ids.map(func(_x) -> bool: return false), "arrive": e.vendor_arrive_minute, "leave": e.vendor_arrive_minute + e.vendor_stay_slots * TimeSystem.SLOT_MIN, "told": false }


## รถจอดหน้าร้านตอนนี้ไหม
func vendor_here() -> bool:
	var ts := _ts()
	return not vendor.is_empty() and ts != null and ts.current_minute >= int(vendor.arrive) and ts.current_minute < int(vendor.leave)


## ราคารถขายของ = ราคาออนไลน์ − vendor_discount
func vendor_price(it: ItemDef) -> int:
	return maxi(roundi(it.online_cost() * (1.0 - _econ().vendor_discount)), 1)


func _check_vendor(ts: TimeSystem) -> void:
	if vendor_here() and not bool(vendor.get("told", false)):
		vendor["told"] = true
		if visitor_toast and not quiet:
			visitor_toast.show_message("รถขายของมาจอดหน้าร้าน!", "อะไหล่ลดราคา %d%% อยู่ %s · กดปุ่มรถที่มุมล่าง" % [roundi(_econ().vendor_discount * 100.0), TimeSystem.turns_text(_econ().vendor_stay_slots)])


## ซื้อของชิ้นที่ i จากรถ · คืนเหตุผล ("" = สำเร็จ)
func vendor_buy(i: int) -> String:
	if not vendor_here():
		return "รถไปแล้ว"
	var ids: Array = vendor.get("items", [])
	if i < 0 or i >= ids.size() or bool(vendor.sold[i]):
		return "ขายไปแล้ว"
	var it := part_item(StringName(ids[i]))
	if it == null:
		return "ไม่มีของ"
	var price := vendor_price(it)
	if not GameState.can_afford(price):
		return "เงินไม่พอ"
	if not GameState.can_store(it):
		return "คลังเต็ม"
	GameState.add_money(-price, &"buy", "รถขายของ: %s" % it.display_name)
	GameState.add_item(it, 1, false, true, price)
	vendor.sold[i] = true
	GameState.parts_arrived.emit()
	_board_dirty = true
	return ""


## ข้อมูลแผงรถขายของ (ดู VendorPanel.show_view)
func vendor_view() -> Dictionary:
	var ts := _ts()
	var show := (
		vendor_here() and _loop_active() and _in_shop() and not Global.in_minigame and not DialogScene.visible
		and not _skipping and not _game_over and not demo_over and not (_day_skip and _day_skip.visible)
	)
	if not show:
		return { "show": false }
	var left := floori((int(vendor.leave) - ts.current_minute) / float(TimeSystem.SLOT_MIN))
	var rows: Array[Dictionary] = []
	var ids: Array = vendor.get("items", [])
	for i in ids.size():
		var it := part_item(StringName(ids[i]))
		if it == null:
			continue
		var price := vendor_price(it)
		var sold := bool(vendor.sold[i])
		var wait := waiting_for(it.id)
		var why := ""
		if sold:
			why = "ขายแล้ว"
		elif not GameState.can_afford(price):
			why = "เงินไม่พอ"
		elif not GameState.can_store(it):
			why = "คลังเต็ม"
		rows.append({
			"name": "%s · ฿%d" % [it.display_name, price],
			"status": "ออนไลน์ ฿%d%s · ในคลัง %d%s" % [it.online_cost(), (" · ตลาด ฿%d" % it.price) if it.market else "", GameState.count_item(it.id), (" · เครื่องของ%sรอชิ้นนี้" % ", ".join(wait)) if not wait.is_empty() else ""],
			"warn": not wait.is_empty(),
			"icon": it.icon,
			"buy": { "text": why if why != "" else "ซื้อ", "disabled": why != "" },
		})
	return {
		"show": true,
		"button": "รถขายของ · อีก %s" % TimeSystem.turns_text(left),
		"title": "รถขายของลุงสมพร",
		"note": "ของมือสองลด %d%% จากราคาออนไลน์ · มีชิ้นละ 1 · ไม่ซื้อตอนนี้ รถไปแล้วไม่รู้จะมาอีกเมื่อไร" % roundi(_econ().vendor_discount * 100.0),
		"rows": rows,
	}


## [0.4.0 ขั้น E] ของในร้านออนไลน์ (อะไหล่ก่อน แล้วของสิ้นเปลือง · ไม่รวมอัปเกรด)
static func online_catalog() -> Array[ItemDef]:
	var out: Array[ItemDef] = []
	for f in DirAccess.get_files_at("res://Resources/Shop/"):
		var path := "res://Resources/Shop/" + f.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var it := load(path) as ItemDef
		if it and it.online and it.kind != ItemDef.Kind.UPGRADE:
			out.append(it)
	out.sort_custom(func(a: ItemDef, b: ItemDef) -> bool: return a.kind < b.kind or (a.kind == b.kind and a.online_cost() < b.online_cost()))
	return out


## เครื่องบนชั้นที่ยังรอของชิ้นนี้ (ชื่อลูกค้า)
func waiting_for(id: StringName) -> PackedStringArray:
	var out := PackedStringArray()
	if shelf == null:
		return out
	for o in shelf.waiting():
		var ids := o.part_ids()
		if ids.has(id) and GameState.reserved_index(o.key) < 0:
			out.append(o.case.customer)
		elif o.replace_part == id and GameState.reserved_index(o.replace_key()) < 0:
			out.append(o.case.customer + " (ชดใช้)")
	return out


## [0.4.0 ขั้น H] ไปตลาดระหว่างเปิดร้าน = เดินไปกลับ market_walk_slots เทิร์น (ลูกค้าหน้าประตูรอต่อตามความอดทน)
## สถานที่ก่อนหน้า (-1 = เพิ่งโหลดเซฟ/เริ่มเกม → ไม่คิดเวลาเดิน)
var _last_location := -1


func _on_location_changed(id) -> void:
	var prev := _last_location
	_last_location = int(id)
	if id == SceneRouter.MARKET and prev >= 0 and prev in shop_locations:
		market_trip()
	autosave()


## หักเวลาไปตลาด · คืนจำนวนเทิร์นที่ใช้ (0 = ร้านไม่ได้เปิดอยู่ ไม่เสียเวลา)
func market_trip() -> int:
	var ts := _ts()
	var e := _econ()
	if ts == null or e.market_walk_slots <= 0 or not _loop_active() or _game_over or demo_over:
		return 0
	if _close_requested or ts.current_minute >= TimeSystem.CLOSE or ts.remaining_work_minutes(false) <= 0:
		return 0
	var n := mini(e.market_walk_slots, floori(ts.remaining_work_minutes(false) / float(TimeSystem.SLOT_MIN)))
	if n <= 0:
		return 0
	ts.advance_minutes(n * TimeSystem.SLOT_MIN)
	ts.snap_to_slot()
	if visitor_toast:
		visitor_toast.show_message("เดินไปตลาด ใช้ %s" % TimeSystem.turns_text(n), "ลูกค้าหน้าร้านยังรออยู่ — ซื้อเสร็จรีบกลับนะ")
	return n


## id อะไหล่ที่เครื่องนี้ยังรอ (ตัวหลัก/ของแทน หรือของชดใช้) · ว่าง = ครบแล้ว
func waiting_ids(o: RepairShelf.Order) -> Array[StringName]:
	var out: Array[StringName] = []
	if o.replace_part != &"" and GameState.reserved_index(o.replace_key()) < 0:
		out.append(o.replace_part)
	elif not o.part_ids().is_empty() and GameState.reserved_index(o.key) < 0:
		out.append_array(o.part_ids())
	return out


## ชื่อลูกค้าของรหัสใบรับเครื่อง (ใช้ในหน้าคลัง "จองไว้ให้…")
func reservation_owner(key: String) -> String:
	if shelf:
		for o in shelf.orders:
			if key == o.key or key == o.replace_key():
				return o.case.customer
	return "งานอื่น"


func _on_parts_arrived() -> void:
	assign_parts.call_deferred()


## ปลดอะไหล่ที่จองไว้ให้เครื่องนี้ (ส่งคืนลูกค้าแล้ว/มาเอาคืน)
func _release_order(o: RepairShelf.Order) -> void:
	GameState.release(o.key)
	GameState.release(o.replace_key())


## ซ่อมเสร็จ: ผ่าน → ใช้อะไหล่ที่จอง (ลูกค้าจ่ายราคาซื้อ + ค่าบวกตามยศตอนมารับ) · ของชดใช้ใช้ไปฟรี · ไม่ผ่าน/ยอมแพ้ → ปลดจอง
func _settle_parts(o: RepairShelf.Order, result: Dictionary) -> Dictionary:
	var r := result.duplicate()
	var ok: bool = int(r.get("grade", GameState.Grade.FAIL)) != GameState.Grade.FAIL and not r.get("gave_up", false)
	if not ok:
		_release_order(o)
		return r
	var used := GameState.consume_reserved(o.key)
	if not used.is_empty():
		var it: ItemDef = used.get("item")
		r["part_cost"] = int(used.get("cost", 0))
		r["part_due"] = GameState.part_charge(int(used.get("cost", 0)))
		r["part_name"] = it.display_name if it else ""
	if o.replace_part != &"":
		GameState.consume_reserved(o.replace_key())
		o.replace_part = &""
	return r


## ทำของลูกค้าเสีย และมีอะไหล่ชดใช้ → ใบรับเครื่องกลับไปรอของชดใช้ (ชื่อเสียงหักตอนนี้ · ความพอใจตอนมารับลด) · true = จัดการแล้ว
func _order_damaged(o: RepairShelf.Order, result: Dictionary) -> bool:
	if not result.get("damaged", false) or o.replace_part != &"":
		return false
	var it := replacement_for(StringName(o.case.part_id))
	if it == null:
		return false
	o.replace_part = it.id
	o.sat_adjust -= _econ().damage_replace_sat
	GameState.add_reputation(int(result.get("rep_due", _econ().rep_damaged)))
	GameState.satisfaction_history.append(_econ().satisfaction_fail)
	GameState.add_affinity(npc_id(o.case), int(_econ().affinity_gain.get(&"damage", 0) / (2.0 if GameState.has_perk(&"careful") else 1.0)), &"damage")
	assign_parts(false)
	shelf_news.append("ทำ%sของ%sเสีย — ต้องหา%sมาเปลี่ยนให้ก่อน" % [o.case.job_title if o.case.job_title != "" else "ของ", o.case.customer, it.display_name])
	_board_dirty = true
	return true


## เปิดร้าน: พัสดุที่สั่งออนไลน์มาส่ง
func _deliver_parcels(ts: TimeSystem) -> void:
	var got := GameState.deliver_orders(ts.shift)
	if got.is_empty():
		return
	var names := PackedStringArray()
	for g in got:
		names.append("%s ×%d" % [(g["item"] as ItemDef).display_name, int(g["qty"])])
	shelf_news.append("พัสดุมาส่ง: " + ", ".join(names))
	_skip_note("พัสดุที่สั่งไว้มาถึงแล้ว: " + ", ".join(names))
	if visitor_toast:
		visitor_toast.show_message("พัสดุมาส่ง", ", ".join(names))


## บรรทัดอะไหล่บนการ์ด: "ต้องใช้: ถ่าน CMOS · ในคลังมี ✓" / "✗ ยังไม่มี — ตลาด ฿30 (เหลือ 2) · ออนไลน์ ฿25"
func part_line(c: CustomerCase) -> String:
	var ids := c.part_ids() if c else ([] as Array[StringName])
	if ids.is_empty():
		return ""
	var it := part_item(ids[0])
	var have := 0
	for id in ids:
		have += GameState.free_count(id)
	var head := "ต้องเปลี่ยน: %s" % (it.display_name if it else String(ids[0]))
	if c.part_hint.strip_edges() != "":
		head = "ปิ๊บ: %s" % c.part_hint
	if have > 0:
		return "%s\nอะไหล่: มีในคลัง ✓ (ว่าง %d) · ลูกค้าจ่ายค่าอะไหล่ตอนมารับ" % [head, have]
	var where := PackedStringArray()
	if it and it.market:
		var left := GameState.stock_left(it)
		where.append("ตลาด ฿%d%s" % [it.price, (" (เหลือ %d)" % left) if left > 0 else (" (หมด · มาใหม่%s)" % GameState.restock_text() if left == 0 else "")])
	if it and it.online:
		where.append("ออนไลน์ ฿%d (ถึงวันเปิดร้านถัดไป)" % it.online_cost())
	return "%s\nอะไหล่: ✗ ยังไม่มีในคลัง — %s" % [head, " · ".join(where)]


## ปิ๊บบอกตอนข้ามวัน (เฉพาะวันที่เล่นแอนิเมชันข้ามวัน)
func _skip_note(s: String) -> void:
	if _day_skip_pending:
		day_skip_notes.append(s)


## [0.3.0 ขั้น E] ลูกค้ามารับเครื่องที่หน้าประตู (ไม่นับโควตา · ไม่หมดความอดทน) · p = RepairShelf.pickup()
func pickup_entry(p: Dictionary) -> Dictionary:
	var o: RepairShelf.Order = p["order"]
	var j := door_entry(o.case, false, false, true)
	j["kind"] = &"pickup"
	j["pickup"] = p
	return j


static func is_pickup(j: Dictionary) -> bool:
	return j.get("kind", &"") == &"pickup"


## เงินที่จะได้ตอนส่งมอบ (คิดแบบเดียวกับ GameState.pay_pickup)
static func pickup_money(p: Dictionary) -> int:
	var o: RepairShelf.Order = p["order"]
	var due := int(o.result.get("money_due", 0))
	var tip := int(o.result.get("tip_due", 0))
	var part := int(o.result.get("part_due", 0))
	if due <= 0:
		return due + part
	var m := float(p["mult"])
	return roundi((due - tip) * m) + roundi(tip * m) + part


## ส่งมอบเครื่องให้คนหน้าประตู (ลูกค้ามารับ) → จ่ายเงิน · ป้าย/ตัวเลขเด้ง · คำขอบคุณ/บ่นของลูกค้า
func door_handover() -> bool:
	var j := door_front()
	if j.is_empty() or not is_pickup(j) or _working:
		return false
	door_queue.pop_front()
	_board_dirty = true
	var p: Dictionary = j["pickup"]
	var o: RepairShelf.Order = p["order"]
	var paid := _pay_pickup(p)
	last_handover = { "order": o, "pickup": p, "paid": paid }
	if reward_popup:
		reward_popup.pop_result({ "money": paid["money"], "reputation": paid["reputation"], "affinity": paid.get("affinity", 0), "npc_name": paid.get("npc_name", "") })
	if visitor_toast:
		var failed := int(o.result.get("grade", 0)) == GameState.Grade.FAIL
		var line := o.case.complain_text if failed else o.case.thanks_text
		visitor_toast.show_message(String(paid["text"]), ("%s: \"%s\"" % [o.case.customer, line]) if line.strip_edges() != "" else "")
	autosave.call_deferred()
	return true


## ปิดร้าน/เปิดวันใหม่: ลูกค้ามารับที่ยังไม่ได้ส่งมอบ → ส่งให้อัตโนมัติ (เงินเข้าวันนั้น)
func _auto_handover() -> void:
	for j: Dictionary in door_queue.duplicate():
		if is_pickup(j):
			door_queue.erase(j)
			_pay_pickup(j["pickup"])


## ข้อมูลแผงชั้นวาง (ดู RepairShelfPanel.show_view)
func shelf_view() -> Dictionary:
	var ts := _ts()
	var show := (
		ts != null and shelf != null and _loop_active() and _in_shop()
		and not Global.in_minigame and not DialogScene.visible and not _skipping
		and not _game_over and not demo_over and not (_day_skip and _day_skip.visible)
	)
	if not show:
		return { "show": false }
	var today := ts.shift
	_shelf_rows.clear()
	var list := shelf.orders.duplicate()
	list.sort_custom(func(a: RepairShelf.Order, b: RepairShelf.Order) -> bool: return a.state < b.state or (a.state == b.state and a.due < b.due))
	var rows: Array[Dictionary] = []
	var alert := false
	for o: RepairShelf.Order in list:
		_shelf_rows.append(o)
		var c := o.case
		var r := { "name": "%s · %s" % [c.customer, c.device if c.device != "" else c.symptom], "state": &"wait", "warn": false }
		if o.state == RepairShelf.State.DONE:
			r["state"] = &"done"
			r["status"] = "ซ่อมเสร็จ · ลูกค้ามารับ %s" % due_text(o.due)
			r["repair"] = { "text": "เสร็จแล้ว", "disabled": true }
		else:
			var late := o.late_days(today)
			var fee := roundi(_fee(c) * _econ().promise_mult(o.promise) * maxf(1.0 - late * _econ().late_pay_cut_per_day, 0.0))
			if late > 0:
				r["status"] = "เลยนัดมา %d วัน! · ค่าแรงเหลือ ฿%d · อีก %d วันลูกค้ามาเอาคืน" % [late, fee, _econ().late_grace_days - late + 1]
				r["warn"] = true
			elif o.due == today:
				r["status"] = "ครบนัดวันนี้ — ซ่อมเสร็จลูกค้ามารับเลย · ค่าแรง ฿%d" % fee
				r["warn"] = true
			else:
				r["status"] = "รอซ่อม · นัดรับ %s · ค่าแรง ฿%d" % [due_text(o.due), fee]
			alert = alert or bool(r["warn"])
			var miss := order_missing_parts(o)
			if not miss.is_empty():
				r["status"] = "รอของ: %s · %s" % [missing_note(o), r["status"]]
				r["warn"] = true
			elif not o.part_ids().is_empty():
				r["status"] += " · อะไหล่พร้อม ✓"
			var rp := { "text": "ซ่อม (%s)" % _cost_text(job_slots(c)), "disabled": false, "tooltip": "" }
			match shelf_repair_state(o):
				&"no_part":
					rp["text"] = "รอของ"
					rp["disabled"] = true
					rp["tooltip"] = "ยังไม่มี %s ในคลัง — ซื้อแล้วระบบจองให้เครื่องนี้เอง" % ", ".join(miss)
				&"ot":
					rp["text"] = "ซ่อม\n(ล่วงเวลา)"
				&"no":
					rp["text"] = "เทิร์นไม่พอ"
					rp["disabled"] = true
				&"busy":
					rp["disabled"] = true
					rp["tooltip"] = "ทำงานที่ค้างอยู่ให้เสร็จก่อน"
			r["repair"] = rp
		rows.append(r)
	return {
		"show": true,
		"button": "ชั้นวาง %d/%d" % [shelf.used(), shelf.slots],
		"alert": alert,
		"title": "ชั้นวางเครื่อง %d/%d" % [shelf.used(), shelf.slots],
		"note": "ซ่อมเสร็จก่อนวันนัด → ลูกค้ามารับตอนเปิดร้านวันนัด · ถึง/เลยนัดแล้ว → มารับทันทีที่ซ่อมเสร็จ · เงินเข้าตอนลูกค้ามารับ",
		"empty": "ชั้นว่าง — รับเครื่องจากลูกค้าหน้าร้านแล้วเครื่องจะมาวางที่นี่",
		"rows": rows,
	}


# ---------------------------------------------------------------- แอปงานซ่อมในคอมของขม (0.3.0)


## แถวในแอปตอนนี้ (index = แถว) → กดปุ่มแถวไหน
var _app_rows: Array[RepairShelf.Order] = []
## กด "ไปซ่อม" ในแอป → ปิดคอมแล้วเปิดมินิเกมเครื่องนี้ (รอจนกลับมาที่หน้าร้าน)
var _pending_repair: RepairShelf.Order
var _pending_repair_time := 0.0


## ซ่อมได้ไหม (ไม่สนว่าคอมเปิดอยู่) · &"ok" · &"ot" · &"no" · &"busy" · &"done"
func app_repair_state(o: RepairShelf.Order) -> StringName:
	if o == null or not shelf.orders.has(o):
		return &"busy"
	if o.state != RepairShelf.State.WAITING:
		return &"done"
	if not order_has_parts(o):
		return &"no_part"
	var ts := _ts()
	if forced_case or _result_pending or _close_requested or ts == null or ts.current_minute >= TimeSystem.CLOSE:
		return &"busy"
	return job_fit(o.case)


## กด "ไปซ่อม" จากแอป: จำไว้ → ปิดคอม (ผู้เรียก) → _process เปิดมินิเกมเมื่อกลับมาที่หน้าร้าน
func request_shelf_repair(o: RepairShelf.Order) -> bool:
	if app_repair_state(o) not in [&"ok", &"ot"]:
		return false
	_pending_repair = o
	_pending_repair_time = 0.0
	return true


func _run_pending_repair(delta: float) -> void:
	if _pending_repair == null:
		return
	_pending_repair_time += delta
	if _pending_repair_time > 6.0: # รอนานเกิน (เช่นมีบทขึ้น) → ยกเลิก
		_pending_repair = null
		return
	if Global.in_minigame or DialogScene.visible or _working or _decide_card() != Card.DOOR:
		return
	var o := _pending_repair
	_pending_repair = null
	shelf_repair(o)


## เลื่อนนัด +1 วันเปิดร้าน (โทรหาลูกค้า)
func shelf_postpone(o: RepairShelf.Order) -> bool:
	var ts := _ts()
	if ts == null or not shelf.postpone(o, ts.shift, TimeSystem.TOTAL_SHIFTS):
		return false
	if visitor_toast:
		visitor_toast.show_message("โทรขอเลื่อนนัด%sแล้ว" % o.case.customer, "นัดรับใหม่ %s · ความพอใจ −%d" % [due_text(o.due), _econ().postpone_sat_penalty])
	_board_dirty = true
	autosave.call_deferred()
	return true


## ซ่อมเสร็จก่อนนัด → โทรเรียกมารับวันนี้ (ลูกค้าเดินมายืนหน้าประตู · กดส่งมอบได้เงิน)
func shelf_call_early(o: RepairShelf.Order) -> bool:
	var ts := _ts()
	if ts == null or ts.current_minute >= TimeSystem.CLOSE:
		return false
	var p := shelf.call_early(o, ts.shift)
	if p.is_empty():
		return false
	door_queue.push_front(pickup_entry(p))
	affinity_for(o.case, &"call_early")
	if visitor_toast:
		visitor_toast.show_message("โทรบอก%sแล้ว" % o.case.customer, "กำลังมารับเครื่องที่หน้าร้าน · ความพอใจ +%d" % _econ().early_call_sat_bonus)
	_board_dirty = true
	autosave.call_deferred()
	return true


## กดปุ่มในแอป: id = &"repair" · &"postpone" · &"call" · คืน true = สำเร็จ (repair = ผู้เรียกต้องปิดคอม)
func work_app_action(i: int, id: StringName) -> bool:
	if i < 0 or i >= _app_rows.size():
		return false
	var o := _app_rows[i]
	match id:
		&"repair":
			return request_shelf_repair(o)
		&"postpone":
			return shelf_postpone(o)
		&"call":
			return shelf_call_early(o)
	return false


## ข้อมูลแอปงานซ่อม (ดู WorkOrderApp.show_view): แบ่งตามวันนัด · เลยนัดอยู่บนสุด · คนนัดมาหน้าร้าน/คนรอรับหน้าร้านด้วย
func work_app_view() -> Dictionary:
	var ts := _ts()
	var e := _econ()
	var today := ts.shift if ts else 1
	_app_rows.clear()
	var list: Array = shelf.orders.duplicate()
	list.sort_custom(func(a: RepairShelf.Order, b: RepairShelf.Order) -> bool: return a.due < b.due or (a.due == b.due and a.state > b.state))
	var groups := { } # วันนัด -> แถว
	var order_keys: Array[int] = []
	for o: RepairShelf.Order in list:
		var key := today - 1 if o.due < today else o.due
		if not groups.has(key):
			groups[key] = []
			order_keys.append(key)
		var i := _app_rows.size()
		_app_rows.append(o)
		groups[key].append(_app_row(i, o, today))
	var sections: Array[Dictionary] = []
	for k in order_keys:
		var t := "เลยนัดแล้ว!" if k < today else ("วันนี้ · %s" % shift_date_text(k) if k == today else due_text(k))
		sections.append({ "title": t, "warn": k <= today, "rows": groups[k] })
	# คนรอรับหน้าร้านตอนนี้ / คนที่นัดมาหน้าร้านวันเปิดร้านถัดไป (ไม่มีปุ่ม)
	var at_door := door_queue.filter(func(q: Dictionary) -> bool: return is_pickup(q))
	if not at_door.is_empty():
		var rows: Array[Dictionary] = []
		for q: Dictionary in at_door:
			rows.append({ "name": "%s · รอรับเครื่องอยู่หน้าร้าน" % (q["case"] as CustomerCase).customer, "status": "ไปกด \"ส่งมอบเครื่อง\" ที่การ์ดหน้าร้าน · ได้ ฿%d" % pickup_money(q["pickup"]), "state": &"done", "actions": [] })
		sections.push_front({ "title": "รอรับเครื่องหน้าร้านตอนนี้", "warn": false, "rows": rows })
	if not appointments.is_empty():
		var rows2: Array[Dictionary] = []
		for a in appointments:
			var c: CustomerCase = a["case"]
			rows2.append({ "name": "%s · นัดมาหน้าร้าน" % c.customer, "status": "%s · %s" % [c.device if c.device != "" else c.symptom, due_text(today + 1)], "state": &"wait", "actions": [] })
		sections.append({ "title": "นัดมาหน้าร้าน %s" % due_text(today + 1), "warn": false, "rows": rows2 })
	return {
		"title": "ใบรับเครื่องทั้งหมด · วันนี้ %s" % shift_date_text(today),
		"shelf": "ชั้นวาง %d/%d" % [shelf.used(), shelf.slots],
		"sections": sections,
		"empty": "ยังไม่มีเครื่องที่รับไว้ — รับเครื่องจากลูกค้าหน้าร้านก่อนนะ",
		"note": "ซ่อมก่อนนัดได้เสมอ · เลื่อนนัดได้ครั้งเดียวต่อเครื่อง (ความพอใจ −%d) · ซ่อมเสร็จแล้วโทรเรียกมารับก่อนได้ (ความพอใจ +%d)" % [e.postpone_sat_penalty, e.early_call_sat_bonus],
	}


func _app_row(i: int, o: RepairShelf.Order, today: int) -> Dictionary:
	var c := o.case
	var e := _econ()
	var late := o.late_days(today)
	var fee := roundi(_fee(c) * e.promise_mult(o.promise) * maxf(1.0 - late * e.late_pay_cut_per_day, 0.0))
	var r := { "index": i, "name": "%s · %s" % [c.customer, c.device if c.device != "" else c.symptom], "state": &"wait", "warn": late > 0, "actions": [] }
	var actions: Array[Dictionary] = []
	if o.state == RepairShelf.State.DONE:
		r["state"] = &"done"
		r["status"] = "ซ่อมเสร็จแล้ว · ลูกค้ามารับ %s" % due_text(o.due)
		actions.append({ "id": &"call", "text": "โทรเรียกมารับเลย", "disabled": not shelf.can_call_early(o, today), "tooltip": "ลูกค้ามารับวันนี้ ได้เงินเร็วขึ้น ความพอใจ +%d" % e.early_call_sat_bonus })
	else:
		var st := "เลยนัดมา %d วัน! ค่าแรงเหลือ ฿%d" % [late, fee] if late > 0 else "รอซ่อม · ค่าแรง ฿%d · ใช้ %s" % [fee, _cost_text(job_slots(c))]
		if o.postponed:
			st += " · เลื่อนนัดแล้ว"
		r["status"] = st
		var miss := order_missing_parts(o)
		if not miss.is_empty():
			r["status"] = "รอของ: %s · %s" % [missing_note(o), r["status"]]
			r["warn"] = true
		var rs := app_repair_state(o)
		actions.append({
			"id": &"repair",
			"text": "รอของ" if rs == &"no_part" else ("ไปซ่อม" if rs == &"ok" else ("ไปซ่อม (ล่วงเวลา)" if rs == &"ot" else ("เทิร์นไม่พอ" if rs == &"no" else "ไปซ่อม"))),
			"disabled": rs not in [&"ok", &"ot"],
			"tooltip": "ปิดคอมแล้วเปิดเครื่องนี้ซ่อมเลย" if rs in [&"ok", &"ot"] else ("สั่งอะไหล่ในแอปร้านออนไลน์ หรือซื้อที่ตลาด" if rs == &"no_part" else "ทำงานที่ค้างอยู่ให้เสร็จก่อน"),
		})
		var can := shelf.can_postpone(o, today, TimeSystem.TOTAL_SHIFTS)
		actions.append({
			"id": &"postpone",
			"text": "เลื่อนนัด +1 วัน",
			"disabled": not can,
			"tooltip": ("โทรขอเลื่อนเป็น %s · ความพอใจ −%d" % [due_text(o.due + 1), e.postpone_sat_penalty]) if can else ("เลื่อนไปแล้ว" if o.postponed else "เลยนัดแล้ว เลื่อนไม่ได้"),
		})
	r["actions"] = actions
	return r


# ---------------------------------------------------------------- ใบรับเครื่อง (0.3.0 ขั้น C)


## เปิดใบรับเครื่องของคนหน้าประตู (งานฮาร์ดแวร์ · ยังไม่ครบโควตา · ชั้นยังว่าง)
func open_work_order() -> bool:
	var j := door_front()
	if j.is_empty() or not (j["case"] as CustomerCase).takes_machine() or door_accept_state(1) != &"ok":
		return false
	_work_order_open = true
	_board_dirty = true
	return true


func close_work_order() -> void:
	_work_order_open = false
	_board_dirty = true
	if work_order:
		work_order.visible = false


func _on_work_order_confirmed(promise_index: int) -> void:
	close_work_order()
	var j := door_front()
	if j.is_empty():
		return
	var c: CustomerCase = j["case"]
	if door_accept(promise_index) and visitor_toast:
		var o := _order_of(c)
		if o:
			visitor_toast.show_message("%s ฝากเครื่องไว้บนชั้น" % c.customer, "นัดรับ %s" % due_text(o.due))


## ตัวเลือกวันนัด · "ด่วน วันนี้" ซ่อนถ้าวันนี้ซ่อมไม่ทัน (ไม่ล่วงเวลา)
func promise_options_for(c: CustomerCase) -> Array[Dictionary]:
	var ts := _ts()
	var today := ts.shift if ts else 1
	var opts := shelf.promise_options(today, job_fit(c) == &"ok")
	return opts.filter(func(o: Dictionary) -> bool: return int(o["due"]) <= TimeSystem.TOTAL_SHIFTS)


## ข้อมูลใบรับเครื่อง (ดู WorkOrderCard.show_view)
func work_order_view() -> Dictionary:
	var j := door_front()
	if j.is_empty():
		return { }
	var c: CustomerCase = j["case"]
	var e := _econ()
	var opts: Array[Dictionary] = []
	var sel := -1
	var have_part := c.part_ids().is_empty()
	for id in c.part_ids():
		have_part = have_part or GameState.free_count(id) > 0
	for o in promise_options_for(c):
		var i := int(o["index"])
		opts.append({
			"index": i,
			"label": "%s · ค่าแรง ฿%d%s" % [o["name"], roundi(_fee(c) * float(o["mult"])), (" (×%.1f)" % float(o["mult"])) if not is_equal_approx(float(o["mult"]), 1.0) else ""],
			"sub": "ลูกค้ามารับ %s" % due_text(int(o["due"])) + (" — ต้องซ่อมให้เสร็จวันนี้" if int(o["days"]) == 0 else "") + (" · ยังไม่มีอะไหล่ ต้องไปซื้อที่ตลาดวันนี้" if int(o["days"]) == 0 and not have_part else ""),
		})
		if sel < 0 or int(o["days"]) == 1:
			sel = i
	return {
		"title": "ใบรับเครื่อง · %s" % c.customer,
		"shelf": "ชั้นวาง %d/%d" % [shelf.used(), shelf.slots],
		"detail": "เครื่อง: %s\nอาการ: %s\nงาน %s · ใช้ %s · ค่าแรงตั้งต้น ฿%d" % [c.device if c.device != "" else "-", c.symptom, c.level_name(), _cost_text(job_slots(c)), _fee(c)] + (("\n" + part_line(c)) if part_line(c) != "" else ""),
		"hint": "เงินเข้าตอนลูกค้ามารับเครื่อง · เลยนัดได้อีก %d วันเปิดร้าน (ค่าแรง −%d%% และความพอใจ −%d ต่อวัน) · เลยกว่านั้นลูกค้ามาเอาเครื่องคืน ชื่อเสียง %d" % [
			e.late_grace_days, roundi(e.late_pay_cut_per_day * 100.0), e.late_sat_per_day, e.rep_returned,
		],
		"options": opts,
		"selected": sel,
	}


## "วันนี้" · "วันเปิดร้านถัดไป (อา. 11 ม.ค.)" · "อีก 2 วันเปิดร้าน (อา. 18 ม.ค.)"
func due_text(due: int) -> String:
	var ts := _ts()
	var d := due - (ts.shift if ts else 1)
	var date := shift_date_text(due)
	if d <= 0:
		return "วันนี้" if d == 0 else "เลยนัดมา %d วัน (%s)" % [-d, date]
	if d == 1:
		return "วันเปิดร้านถัดไป (%s)" % date
	return "อีก %d วันเปิดร้าน (%s)" % [d, date]


## "อา. 11 ม.ค." ของวันเปิดร้าน s
static func shift_date_text(s: int) -> String:
	s = clampi(s, 1, TimeSystem.TOTAL_SHIFTS)
	var ch := floori((s - 1) / float(TimeSystem.SHIFTS_PER_WEEK)) + 1
	var d: int = TimeSystem.PLAY_DATES[(s - 1) % TimeSystem.SHIFTS_PER_WEEK]
	return "%s %d %s" % [TimeSystem.WEEKDAY_SHORT[TimeSystem.weekday_of(d, ch)], d, TimeSystem.MONTH_NAME[ch - 1]]


func _order_of(c: CustomerCase) -> RepairShelf.Order:
	for o: RepairShelf.Order in shelf.orders:
		if o.case == c:
			return o
	return null


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
	if month_summary:
		month_summary.visible = false
	_panel.visible = false
	_board_panel.visible = false
	if work_order:
		work_order.visible = false
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
	# [0.2.0] ฉากข้ามวัน + แถบเป้าเดือน วางใน day_loop.tscn (ปรับใน Editor ได้) · DaySkipLayer ชั้น 110 (เหนือ HUD 100 / ปุ่มคลัง 105 ใต้บทพูด 128) · GoalLayer ชั้น 100
	_day_skip = _ensure_ui(^"DaySkipLayer", 110, DAY_SKIP_SCENE) as DaySkip
	goal_bar = _ensure_ui(^"GoalLayer", 100, GOAL_BAR_SCENE) as MonthGoalBar
	# [0.2.0-E] SummaryLayer ชั้น 108 (เหนือ HUD/แถบเป้า 100 · ปุ่มคลัง 105 · ใต้ข้ามวัน 110)
	month_summary = _ensure_ui(^"SummaryLayer", 108, MONTH_SUMMARY_SCENE) as MonthSummary
	# [0.2.5] ToastLayer ชั้น 104 (เหนือ HUD/แถบเป้า 100 · ใต้ปุ่มคลัง 105 · สรุปเดือน 108)
	visitor_toast = _ensure_ui(^"ToastLayer", 104, VISITOR_TOAST_SCENE) as VisitorToast
	# [8 พ.ย.] ReminderLayer ชั้น 11 (เหนือมินิเกม overlay_stack 10 · ใต้ HUD 100) — ปุ่มดูงานของลูกค้าซ้ำระหว่างซ่อม
	job_reminder = _ensure_ui(^"ReminderLayer", 11, JOB_REMINDER_SCENE) as JobReminder
	# [0.2.5] PopupLayer ชั้น 106 (เหนือ HUD 100 · ปุ่มคลัง 105 · ใต้สรุปเดือน 108)
	reward_popup = _ensure_ui(^"PopupLayer", 106, REWARD_POPUP_SCENE) as RewardPopup
	# [0.3.0 ขั้น C] DoorLayer ชั้น 90 การ์ดลูกค้าหน้าประตู (แทนกระดานงาน) · WorkOrderLayer ชั้น 91 ใบรับเครื่อง (ทับการ์ดหน้าประตู)
	door_card = _ensure_ui(^"DoorLayer", 90, DOOR_CARD_SCENE) as DoorCard
	_board_panel = door_card
	door_card.visible = false
	door_card.accept_pressed.connect(_on_door_accept)
	door_card.appoint_pressed.connect(func() -> void: door_appoint())
	door_card.reject_pressed.connect(func() -> void: door_reject())
	door_card.helper_pressed.connect(func() -> void: door_helper())
	door_card.wait_pressed.connect(wait_slot)
	door_card.close_pressed.connect(close_shop)
	door_card.hide_pressed.connect(func() -> void: set_cards_hidden(true))
	work_order = _ensure_ui(^"WorkOrderLayer", 91, WORK_ORDER_SCENE) as WorkOrderCard
	work_order.visible = false
	work_order.confirmed.connect(_on_work_order_confirmed)
	work_order.cancelled.connect(close_work_order)
	# [0.3.0 ขั้น D] ShelfLayer ชั้น 95 แผงชั้นวางเครื่อง (เหนือการ์ดงาน 90–91 · ใต้ HUD 100)
	shelf_panel = _ensure_ui(^"ShelfLayer", 95, SHELF_PANEL_SCENE) as RepairShelfPanel
	shelf_panel.repair_pressed.connect(_on_shelf_repair_pressed)
	# [0.4.0 ขั้น J] VendorLayer ชั้น 92 รถขายของ (ปุ่มลอยข้างปุ่มชั้นวาง + แผงของ 3 ชิ้น)
	vendor_panel = _ensure_ui(^"VendorLayer", 92, VENDOR_PANEL_SCENE) as VendorPanel
	if not vendor_panel.buy_pressed.is_connected(vendor_buy):
		vendor_panel.buy_pressed.connect(func(i: int) -> void: vendor_buy(i))
	perk_picker = _ensure_ui(^"PerkLayer", 112, PERK_PICKER_SCENE) as PerkPicker
	if not perk_picker.chosen.is_connected(_on_perk_chosen):
		perk_picker.chosen.connect(_on_perk_chosen)
	if not month_summary.continue_pressed.is_connected(_on_primary):
		month_summary.continue_pressed.connect(_on_primary)


## หาโหนด UI ที่วางไว้ใน day_loop.tscn · ถ้าไม่มี (เช่นฉากเก่า) สร้างชั้น + ฉากให้เอง
func _ensure_ui(layer_name: NodePath, layer_no: int, scene: PackedScene) -> Node:
	var layer := get_node_or_null(layer_name) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = String(layer_name)
		layer.layer = layer_no
		add_child(layer)
	if layer.get_child_count() > 0:
		return layer.get_child(0)
	var n := scene.instantiate()
	layer.add_child(n)
	return n


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

	_cards_tab = Button.new()
	_cards_tab.name = "CardsTab"
	_cards_tab.focus_mode = Control.FOCUS_NONE
	_cards_tab.position = Vector2(930, 100)
	_cards_tab.custom_minimum_size = Vector2(206, 44)
	_cards_tab.add_theme_font_size_override("font_size", 18)
	Icons.on_button(_cards_tab, &"clipboard", 22) # [20 ต.ค.] แทนอีโมจิ 📋
	_cards_tab.add_theme_stylebox_override("normal", _card_style())
	_cards_tab.add_theme_stylebox_override("hover", _card_style())
	_cards_tab.add_theme_stylebox_override("pressed", _card_style())
	_cards_tab.add_theme_color_override("font_color", Color(0.35, 0.2, 0.08))
	_cards_tab.add_theme_color_override("font_hover_color", Color(0.6, 0.3, 0.05))
	_cards_tab.pressed.connect(func(): set_cards_hidden(false))
	_cards_tab.visible = false
	add_child(_cards_tab)
	_build_time_skip()


## [14 พ.ย.] การ์ดงาน/กระดานงาน (ชั้น 90) วางต่อใต้การ์ดเป้าหมาย (ชั้น 100) ไม่ให้ถูกทับ
## สูงไม่พอ → พับการ์ดเป้าหมายให้ชั่วคราว แล้วกางคืนเมื่อการ์ดงานปิด (ถ้าผู้เล่นไม่ได้พับเอง)
const CARD_Y := { "DayCard": 120.0, "DoorCard": 100.0, "WorkOrderCard": 100.0 }
## ขอบล่างที่การ์ดงานห้ามเลย (จอ 648 เว้น 8)
const CARD_BOTTOM := 640.0
var _goal_auto_collapsed := false


func _avoid_goal_card() -> void:
	var qb = EventManager.questboard if EventManager and "questboard" in EventManager else null
	var has_qb: bool = qb != null and qb.has_method(&"bottom_y")
	var any := false
	for p: Control in [_panel, _board_panel, work_order]:
		if p == null or not p.visible:
			continue
		any = true
		var base: float = CARD_Y.get(String(p.name), 100.0)
		# [0.3.0] Container ไม่หดเอง (ข้อความตัดบรรทัดวัดตอนกว้างยังไม่ถูก → สูงเกินจริง) → หดให้เท่าเนื้อหา
		if p.size.y > p.get_combined_minimum_size().y + 1.0:
			p.reset_size()
		var y := maxf(base, qb.bottom_y() + 10.0) if has_qb else base
		if has_qb and y + p.get_combined_minimum_size().y > CARD_BOTTOM and not qb.collapsed:
			qb.set_collapsed(true)
			_goal_auto_collapsed = true
			y = maxf(base, qb.bottom_y() + 10.0)
		# [0.3.0] การ์ดสูงกว่าที่เหลือบนจอ → ดันขึ้น (ไม่ให้ปุ่มล่างล้นจอ)
		p.position.y = maxf(minf(y, CARD_BOTTOM - p.get_combined_minimum_size().y), 60.0)
	if not has_qb:
		return
	# [15 พ.ย.] ไม่มีการ์ดชั่วครู่ (เวลาหมุน · บทพัก · บทลูกค้า · มินิเกม) ยังอยู่ในร้าน → คงพับไว้ ไม่งั้นการ์ดเป้าหมายกาง-พับกระพริบ
	# กางคืนเมื่อออกจากร้าน/ร้านไม่ได้เปิด (การ์ดงานจะไม่กลับมาอีกพักใหญ่)
	if not any and _goal_auto_collapsed and not (_loop_active() and _in_shop()):
		_goal_auto_collapsed = false
		if qb.collapsed:
			qb.set_collapsed(false)


## [13 พ.ย.] ปุ่ม "ดูการ์ดงาน" ชิดขวา ต่อใต้การ์ดเป้าหมาย (QuestBoard) — การ์ดสูงเปลี่ยนตามจำนวนเควสต์
func _place_cards_tab() -> void:
	var y := 100.0
	var qb = EventManager.questboard if EventManager and "questboard" in EventManager else null
	if qb and qb.has_method(&"bottom_y"):
		y = maxf(qb.bottom_y() + 10.0, 60.0)
	_cards_tab.position = Vector2(1152.0 - 8.0 - _cards_tab.size.x, y)


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


# ---------------------------------------------------------------- [0.5.0 ขั้น B] ลูกค้าประจำ + ความสนิท (PLAN_0_5_0 ข้อ 2.4)


## id ของลูกค้าประจำจากเคส (&"" = ลูกค้าขาจร)
static func npc_id(c: CustomerCase) -> StringName:
	var n := NpcBook.of_case(c)
	return n.id if n else &""


## ชื่อบนการ์ด (น้องฝ้าย) · ขาจร = ชื่อในเคส
static func npc_name(c: CustomerCase) -> String:
	var n := NpcBook.of_case(c)
	return n.display_name if n else (c.customer if c else "")


## ลูกค้ารอหน้าประตูได้กี่เทิร์น · ระดับคุ้นเคยขึ้นไป +1
func door_patience_slots(c: CustomerCase) -> int:
	var e := _econ()
	var n := c.patience_slots(e)
	var id := npc_id(c)
	if id != &"" and GameState.has_affinity(id) and GameState.affinity_tier(id) >= e.affinity_patience_tier:
		n += 1
	if GameState.has_perk(&"patient"): # [0.5.0] ใจเย็น
		n += 1
	return n


## ความสนิทตามเหตุการณ์ของลูกค้าเคสนี้ · คืนส่วนต่าง
func affinity_for(c: CustomerCase, event: StringName, times := 1) -> int:
	var id := npc_id(c)
	return GameState.affinity_event(id, event, times) if id != &"" else 0


## ผลงานซ่อม → ความสนิท (ผ่าน/ไม่ผ่าน/ทำเสีย/⭐⭐⭐ + ทันนัด/เลยนัด) · จดประวัติเครื่อง · ทิปคนสนิท (เข้า ledger แล้ว)
## คืน { delta, name, tip }
func affinity_result(c: CustomerCase, result: Dictionary, on_time := false, late_days := 0) -> Dictionary:
	var out := { "delta": 0, "name": npc_name(c), "tip": 0 }
	var id := npc_id(c)
	if id == &"" or not GameState.has_affinity(id):
		return out
	var e := _econ()
	var gs := GameState
	var failed := bool(result.get("gave_up", false)) or int(result.get("grade", GameState.Grade.PASS)) == GameState.Grade.FAIL
	var d := 0
	if bool(result.get("damaged", false)):
		d += gs.add_affinity(id, int(e.affinity_gain.get(&"damage", 0) / (2.0 if gs.has_perk(&"careful") else 1.0)), &"damage")
	elif failed:
		d += gs.affinity_event(id, &"fail")
	else:
		var tier_before := gs.affinity_tier(id)
		d += gs.affinity_event(id, &"pass")
		if int(result.get("score", 0)) >= e.three_star_score:
			d += gs.affinity_event(id, &"three_star")
		if tier_before >= e.affinity_tip_tier and e.affinity_tip > 0:
			var tip := e.affinity_tip * (2 if gs.has_perk(&"beloved") else 1) # [0.5.0] ขวัญใจหมู่บ้าน
			gs.add_money(tip, &"tip", "ทิปจาก%s" % out["name"])
			out["tip"] = tip
	if on_time:
		d += gs.affinity_event(id, &"on_time")
	elif late_days > 0:
		d += gs.affinity_event(id, &"late_day", late_days)
	gs.add_npc_history(id, c.job_title + (" (ไม่ผ่าน)" if failed else ""))
	out["delta"] = d
	_queue_story(c)
	return out


## ขึ้นระดับความสนิท → ป้ายบอกว่าปลดอะไร
func _on_affinity_tier_up(id: StringName, tier: int) -> void:
	if visitor_toast == null or quiet:
		return
	var n := NpcBook.by_id(id)
	if n == null:
		return
	var e := _econ()
	var perks := {
		1: "การ์ดหน้าร้านจะบอกว่าเคยซ่อมอะไร",
		2: "รอหน้าร้านได้นานขึ้น 1 เทิร์น · มีเรื่องอยากเล่าให้ฟัง",
		3: "ให้ทิปเพิ่มตอนงานผ่าน ฿%d · มีเรื่องอยากเล่าอีก" % e.affinity_tip,
		4: "เป็นขาประจำของร้านแล้ว!",
	}
	visitor_toast.show_message("♥ %s: %s" % [n.display_name, e.affinity_tier_name(tier)], perks.get(tier, ""))


# ---------------------------------------------------------------- [0.5.0 ขั้น D] UI ความสนิท


## บรรทัดความสนิทบนการ์ดหน้าประตู: "♥♥♡♡♡ รู้จัก · เคยซ่อม: ทำความสะอาดแรม (ม.ค.)" · ขาจร/ยาย = ""
func bond_line(c: CustomerCase) -> String:
	var id := npc_id(c)
	if id == &"" or not GameState.has_affinity(id):
		return ""
	var e := _econ()
	var tier := GameState.affinity_tier(id)
	var line := "%s %s" % [GameState.affinity_hearts_text(id), e.affinity_tier_name(tier)]
	var hist: Array = GameState.npc_history.get(id, [])
	if tier >= 1 and not hist.is_empty():
		var h: Dictionary = hist[-1]
		line += " · เคยซ่อม: %s%s" % [String(h.text), (" (%s)" % TimeSystem.MONTH_NAME[clampi(int(h.ch), 1, 12) - 1]) if int(h.ch) > 0 else ""]
	if next_story(id) != null:
		line += "\n♥ มีเรื่องอยากเล่าให้ฟัง (ส่งงานเสร็จแล้วจะเล่า)"
	return line


## เรื่องส่วนตัวถัดไปที่ฟังได้แล้ว (ความสนิทถึง · ยังไม่ฟัง · ฟังเรื่องก่อนหน้าแล้ว) · null = ไม่มี
func next_story(id: StringName) -> NpcStory:
	var n := NpcBook.by_id(id)
	if n == null or not n.has_affinity:
		return null
	for s in n.stories:
		if s == null:
			continue
		if GameState.story_seen(id, s.at):
			continue
		return s if GameState.affinity(id) >= s.at else null
	return null


## ข้อมูลแอป "สมุดลูกค้า" (CustomerBookApp): รายการคนที่มีความสนิท เรียงคนที่เคยเจอก่อน แล้วตามความสนิท
func customer_book_view() -> Dictionary:
	var e := _econ()
	var rows: Array[Dictionary] = []
	for n in NpcBook.with_affinity():
		var id := n.id
		var met := GameState.met(id) or GameState.npc_history.has(id) or GameState.npc_affinity.has(id)
		var r := { "id": String(id), "met": met, "name": n.display_name if met else "???", "aff": GameState.affinity(id) }
		if met:
			var tier := GameState.affinity_tier(id)
			var nxt := GameState.affinity_to_next(id)
			r["portrait"] = Global.getCharacterTexture(n.char_key) if Global.hasCharacter(n.char_key) else null
			r["hearts"] = GameState.affinity_hearts_text(id)
			r["tier"] = "%s (%d)" % [e.affinity_tier_name(tier), GameState.affinity(id)]
			r["next"] = ("อีก %d แต้มถึง \"%s\"" % [nxt, e.affinity_tier_name(tier + 1)]) if nxt > 0 else "สนิทสุดแล้ว"
			r["bio"] = n.bio
			var hist := PackedStringArray()
			for h in GameState.npc_history.get(id, []):
				hist.append("%s%s" % [String(h.text), (" (%s)" % TimeSystem.MONTH_NAME[clampi(int(h.ch), 1, 12) - 1]) if int(h.ch) > 0 else ""])
			r["history"] = ("เคยซ่อม: " + " · ".join(hist)) if not hist.is_empty() else "ยังไม่เคยซ่อมให้"
			var heard := PackedStringArray()
			for s in n.stories:
				if s and GameState.story_seen(id, s.at):
					heard.append(s.title)
			r["stories"] = ("เรื่องที่เคยฟัง: " + " · ".join(heard)) if not heard.is_empty() else ""
			r["story_ready"] = next_story(id) != null
		else:
			r["hint"] = "ยังไม่เคยมาร้าน"
		rows.append(r)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.met != b.met:
			return a.met
		return int(a.aff) > int(b.aff))
	var met_n := rows.filter(func(r: Dictionary) -> bool: return r.met).size()
	return { "title": "สมุดลูกค้า · รู้จักแล้ว %d/%d คน" % [met_n, rows.size()], "rows": rows }


# ---------------------------------------------------------------- [0.5.0 ขั้น E] เรื่องส่วนตัว (PLAN_0_5_0 ข้อ 4)

## ตัวเลือกในไฟล์เรื่องส่วนตัว (Assets/Dialog/NPC/*.txt) ที่แปลว่า "ไว้ฟังครั้งหน้า"
const STORY_BUSY := "ขอโทษนะ วันนี้ยุ่ง"
## เรื่องที่รอเล่น { id, story } — ตั้งตอนคิดความสนิทหลังส่งงาน · เล่นเมื่อการ์ดว่าง (_maybe_story)
var pending_story: Dictionary = { }
## วันนี้ถามไปแล้ว 1 เรื่อง (ฟังหรือไม่ฟังก็นับ)
var story_today := false


func _queue_story(c: CustomerCase) -> void:
	if story_today or not pending_story.is_empty() or c == null or c.forced:
		return
	var id := npc_id(c)
	var s := next_story(id)
	if s != null:
		pending_story = { "id": id, "story": s }


func _maybe_story(want: Card) -> bool:
	if pending_story.is_empty() or quiet or _working or _result_pending or not _in_shop() or Global.in_minigame or DialogScene.visible:
		return false
	# ไม่เล่นตอนปิดร้านแล้ว (การ์ดปิดร้าน/เลยเวลา) — ค้างไว้ไม่ได้ข้ามวัน เล่าใหม่ครั้งหน้าที่มาส่งงาน
	if want not in [Card.DOOR, Card.NONE] or _ts().current_minute >= TimeSystem.CLOSE:
		return false
	var s: NpcStory = pending_story["story"]
	var n := NpcBook.by_id(pending_story["id"])
	story_today = true
	_working = true
	_hide()
	if EventManager.play_story_dialog("เรื่องของ%s · %s" % [n.display_name if n else "", s.title], s.dialog, "res://Assets/Background/bg_shop_open.jpg", DialogUtil.speakers_in(s.dialog)):
		_wait_dialog(func() -> void:
			_pending_cb = Callable()
			_working = false
			story_finish(DialogScene.last_choice))
	else:
		_working = false
		pending_story = { }
	return true


## จบบทเรื่องส่วนตัว (choice = ตัวเลือกสุดท้ายที่กด) → ฟังแล้ว: จดว่าฟัง · ความสนิท (จบดี/ธรรมดา) · ของฝาก · ธง · เวลา story_slots เทิร์น
## เลือก "ขอโทษนะ วันนี้ยุ่ง" = ไว้ครั้งหน้า (ไม่เสียอะไร) · คืน { heard, good, delta }
func story_finish(choice: String) -> Dictionary:
	if pending_story.is_empty():
		return { }
	var id: StringName = pending_story["id"]
	var s: NpcStory = pending_story["story"]
	pending_story = { }
	var n := NpcBook.by_id(id)
	var who := n.display_name if n else String(id)
	if choice == STORY_BUSY:
		if visitor_toast:
			visitor_toast.show_message("ไว้ฟังเรื่องของ%sครั้งหน้า" % who, "")
		return { "heard": false }
	GameState.mark_story_seen(id, s.at)
	var good := s.good_choice == "" or choice == s.good_choice
	var d := GameState.affinity_event(id, &"story_good" if good else &"story_plain")
	var gift := ""
	if s.reward_item != &"":
		var it := part_item(s.reward_item)
		if it and GameState.give_item(it, 1, false):
			gift = it.display_name
	if gift == "" and good and GameState.has_perk(&"beloved"): # [0.5.0] ขวัญใจหมู่บ้าน: ของฝาก
		var g := part_item(&"ipa90")
		if g and GameState.give_item(g, 1, false):
			gift = g.display_name
	if s.flag != &"":
		GameState.story_flags[s.flag] = true
	var ts := _ts()
	if ts and _econ().story_slots > 0:
		ts.advance_minutes(_econ().story_slots * TimeSystem.SLOT_MIN)
		ts.snap_to_slot()
	if visitor_toast and not quiet:
		visitor_toast.show_message("♥ ฟังเรื่องของ%sแล้ว (%s%d)" % [who, "+" if d >= 0 else "−", absi(d)], ("ได้%sเข้าคลัง" % gift) if gift != "" else ("ตอบได้ใส่ใจมาก" if good else "ครั้งหน้าลองตอบให้ใส่ใจกว่านี้นะ"))
	_board_dirty = true
	autosave.call_deferred()
	return { "heard": true, "good": good, "delta": d }


# ---------------------------------------------------------------- [0.5.0 ขั้น F–G] สอบเลื่อนยศ — แอป "สอบช่าง" ในคอมของขม (RankExamApp · PLAN_0_5_0 ข้อ 5)
# XP ครบ → ป้ายเตือนให้เปิดคอมไปสอบ · สอบได้วันละครั้ง · 3 ข้อ ถูก ≥ exam_pass = เลื่อนยศ (ปิดคอมแล้วขึ้นหน้าเลือกความสามารถ)

## สอบที่กำลังทำ { target, questions: Array[ExamQuestion], orders: Array, i, right, attempt, last } · จบแล้ว = { done, passed, right, total, target }
var exam: Dictionary = { }
var _exam_rng := RandomNumberGenerator.new()


## เริ่มสอบได้ไหม: XP ครบ · วันนี้ยังไม่ได้สอบ · ไม่ได้สอบค้างอยู่
func exam_can_start() -> bool:
	var ts := _ts()
	return GameState.rank_ready() and (ts == null or GameState.exam_last_shift != ts.shift) and not exam_running()


func exam_running() -> bool:
	return not exam.is_empty() and not bool(exam.get("done", false))


## เริ่มสอบ: สุ่มข้อตาม Part ที่ซ่อมผ่านแล้ว · นับว่าวันนี้สอบแล้ว · คืนรายการข้อ
func exam_begin() -> Array[ExamQuestion]:
	var e := _econ()
	var ts := _ts()
	var target := GameState.rank_level + 1
	# สุ่มใหม่ทุกครั้งภายในคลังของยศนี้ · ไม่เอาข้อชุดที่แล้ว (สอบซ้ำจะได้ไม่เจอข้อเดิม)
	var last_set := { }
	if not GameState.learn_log.is_empty():
		var lr: Dictionary = GameState.learn_log[-1]
		for r in GameState.learn_log:
			if int(r.get("target", 0)) == int(lr.get("target", 0)) and int(r.get("attempt", 0)) == int(lr.get("attempt", 0)):
				last_set[StringName(r.get("qid", ""))] = true
	var qs := RankExam.pick(target, e.exam_questions, _exam_rng, GameState.part_clears.keys(), last_set)
	var orders: Array = []
	for q in qs:
		orders.append(RankExam.shuffled(q, _exam_rng))
	GameState.exam_attempts[target] = int(GameState.exam_attempts.get(target, 0)) + 1
	GameState.exam_last_shift = ts.shift if ts else 0
	exam = { "target": target, "questions": qs, "orders": orders, "i": 0, "right": 0, "attempt": GameState.exam_attempts[target], "last": { }, "marks": [] }
	return qs


## ข้อปัจจุบันสำหรับแอป { i (เริ่ม 1), total, question, part, choices: ข้อความตามลำดับที่สลับแล้ว } · ว่าง = ไม่มีข้อ
func exam_question_view() -> Dictionary:
	if not exam_running():
		return { }
	var i := int(exam.i)
	var qs: Array = exam.questions
	if i >= qs.size():
		return { }
	var q: ExamQuestion = qs[i]
	var opts := PackedStringArray()
	for k in exam.orders[i]:
		opts.append(q.choices[k])
	return { "i": i + 1, "total": qs.size(), "question": q.question, "part": String(q.part), "choices": opts, "image": q.image, "domain": q.domain_name() }


## ตอบข้อปัจจุบัน (ข้อความตัวเลือก) → จดลง learn_log + CSV · คืน { correct, answer, explain } (exam.last)
func exam_answer(choice: String) -> bool:
	if not exam_running() or int(exam.i) >= (exam.questions as Array).size():
		return false
	var q: ExamQuestion = exam.questions[int(exam.i)]
	var ok := choice == q.correct_text()
	var when := GameState._ledger_when()
	var row := { "ch": when.x, "day": when.y, "target": int(exam.target), "attempt": int(exam.attempt), "qid": String(q.id), "part": String(q.part), "chosen": choice, "correct": ok }
	GameState.learn_log.append(row)
	if not quiet:
		RankExam.append_csv(row)
	exam["i"] = int(exam.i) + 1
	if ok:
		exam["right"] = int(exam.right) + 1
	exam["last"] = { "correct": ok, "chosen": choice, "answer": q.correct_text(), "explain": q.explain }
	(exam["marks"] as Array).append({ "domain": q.domain_name(), "correct": ok })
	return ok


## ตอบครบแล้วหรือยัง
func exam_answered_all() -> bool:
	return exam_running() and int(exam.i) >= (exam.questions as Array).size()


## ครบทุกข้อ → ถูก ≥ exam_pass = เลื่อนยศ · คืน true = ผ่าน
func exam_finish() -> bool:
	if not exam_running():
		return false
	var right := int(exam.right)
	var total := (exam.questions as Array).size()
	var passed := right >= _econ().exam_pass
	var target := int(exam.target)
	# ใบแจ้งผลแยกหมวด (แบบข้อสอบใบรับรองช่าง): หมวด → [ถูก, ทั้งหมด]
	var report := { }
	for m: Dictionary in exam.get("marks", []):
		var r: Array = report.get(m.domain, [0, 0])
		r[1] += 1
		if bool(m.correct):
			r[0] += 1
		report[m.domain] = r
	exam = { "done": true, "passed": passed, "right": right, "total": total, "target": target, "report": report }
	if passed:
		GameState.promote()
	autosave.call_deferred()
	return passed


## ประวัติสอบ (ใหม่สุดก่อน): "ช่างฝึกหัด ครั้งที่ 2 · ถูก 2/3 ผ่าน"
func exam_history() -> PackedStringArray:
	var e := _econ()
	var groups := { }
	var order: Array = []
	for r in GameState.learn_log:
		var k := "%d_%d" % [int(r.get("target", 0)), int(r.get("attempt", 0))]
		if not groups.has(k):
			groups[k] = [int(r.get("target", 0)), int(r.get("attempt", 0)), 0, 0]
			order.append(k)
		groups[k][3] += 1
		if bool(r.get("correct", false)):
			groups[k][2] += 1
	var out := PackedStringArray()
	for idx in range(order.size() - 1, -1, -1):
		var g: Array = groups[order[idx]]
		out.append("%s ครั้งที่ %d · ถูก %d/%d %s" % [e.rank_names[clampi(g[0], 0, e.rank_names.size() - 1)], g[1], g[2], g[3], "ผ่าน" if g[2] >= e.exam_pass else "ยังไม่ผ่าน"])
	return out


## หน้าแรกของแอปสอบช่าง (ตอนไม่ได้สอบอยู่) { state: max|wait|ready|done_today, title, sub, unlocks, button, history }
func exam_app_view() -> Dictionary:
	var e := _econ()
	var gs := GameState
	var v := { "rank": "%s · %d XP" % [gs.rank_name(), gs.xp], "history": exam_history(), "unlocks": PackedStringArray() }
	var nxt := gs.rank_level + 1
	if nxt >= e.rank_xp.size():
		v.merge({ "state": "max", "title": "ยศสูงสุดแล้ว", "sub": "ไม่ต้องสอบเพิ่ม" })
		return v
	var n_pool := RankExam.pool(nxt, gs.part_clears.keys(), e.exam_questions).size()
	var rules := "สุ่ม %d ข้อ (มีข้อดูภาพ) จาก %d ข้อ · ถูก %d ผ่าน · วันละครั้ง" % [e.exam_questions, n_pool, e.exam_pass]
	v["unlocks"] = gs.rank_unlock_lines(nxt)
	if not gs.rank_ready():
		v.merge({ "state": "wait", "title": "สอบเป็น%s" % e.rank_names[nxt], "sub": "ต้องมี XP อีก %d (%d/%d)" % [e.rank_xp[nxt] - gs.xp, gs.xp, e.rank_xp[nxt]] })
	elif not exam_can_start():
		v.merge({ "state": "done_today", "title": "สอบเป็น%s" % e.rank_names[nxt], "sub": "วันนี้สอบแล้ว · สอบใหม่ได้วันเปิดร้านถัดไป" })
	else:
		v.merge({ "state": "ready", "title": "พร้อมสอบเป็น%s!" % e.rank_names[nxt], "sub": rules, "button": "เริ่มสอบ" })
	return v


## XP ครบ / เปิดร้านวันใหม่ที่ยังสอบได้ → ป้ายเตือนให้เปิดคอมไปสอบ
func _exam_reminder() -> void:
	if quiet or visitor_toast == null or not exam_can_start():
		return
	visitor_toast.show_message("XP ครบแล้ว! สอบเลื่อนยศได้", "เปิดคอมของขม → แอป \"สอบช่าง\" · ผ่านแล้วเป็น%s" % _econ().rank_names[GameState.rank_level + 1])


# ---------------------------------------------------------------- [0.5.0 ขั้น J] มิ้นเป็นลูกมือ (PLAN_0_5_0 ข้อ 6.1)

var helper_used_today := 0


## มิ้นทำงานนี้ได้ไหม: ยศเชี่ยวชาญ · งานขมOS Lv1 (ครูช่าง = Lv2 ด้วย) · ไม่ใช่งานเนื้อเรื่อง · วันละ helper_per_day งาน
func helper_can(c: CustomerCase) -> bool:
	var e := _econ()
	if c == null or c.forced or GameState.rank() < e.helper_rank or helper_used_today >= e.helper_per_day:
		return false
	if c.part_id != CustomerCase.PART_DESKTOP:
		return false
	return c.level <= (2 if GameState.has_perk(&"mentor") else 1)


## โอกาสที่มิ้นทำผ่าน = ฐาน + ต่อ ⭐⭐⭐ ที่ขมเคยได้ในงานระดับนี้ ("ขมสอนมิ้นมาแล้วกี่ครั้ง")
func helper_chance(c: CustomerCase) -> float:
	var e := _econ()
	var stars := int(GameState.level_three_stars.get(c.level, 0))
	var p := e.helper_base + e.helper_per_star * stars + (e.perk_helper_bonus if GameState.has_perk(&"mentor") else 0.0)
	return clampf(p, 0.0, e.helper_max)


func helper_button(j: Dictionary) -> Dictionary:
	if j.is_empty() or is_pickup(j) or bool(j.get("phone", false)):
		return { "visible": false }
	var c: CustomerCase = j["case"]
	if not helper_can(c):
		return { "visible": false }
	return {
		"visible": true,
		"text": "ให้มิ้นทำ\n(%d%%)" % roundi(helper_chance(c) * 100.0),
		"disabled": _working,
		"tooltip": "มิ้นทำแทน ไม่ใช้เวลาขม ไม่นับโควตา · ร้านได้ค่าแรง %d%% · ไม่ได้ XP\nโอกาสผ่านขึ้นกับว่าขมเคยทำงานระดับนี้ได้ 3 ดาวกี่ครั้ง (สอนมิ้นมาแล้ว)" % roundi(_econ().helper_fee_share * 100.0),
	}


## ให้มิ้นทำงานคนหน้าประตู → คืน { ok, money, affinity } (ว่าง = ทำไม่ได้)
func door_helper() -> Dictionary:
	var j := door_front()
	if j.is_empty() or is_pickup(j) or _working:
		return { }
	var c: CustomerCase = j["case"]
	if not helper_can(c):
		return { }
	door_queue.pop_front()
	helper_used_today += 1
	_board_dirty = true
	var e := _econ()
	var ok := _rng.randf() < helper_chance(c)
	var id := npc_id(c)
	var money := 0
	var aff := 0
	if ok:
		money = roundi(_fee(c) * e.helper_fee_share)
		GameState.add_money(money, &"fee", "มิ้นทำ: %s" % c.job_title)
		GameState.satisfaction_history.append(e.satisfaction_pass)
		if id != &"" and GameState.has_affinity(id):
			aff = GameState.add_affinity(id, ceili(e.affinity_gain.get(&"pass", 0) / 2.0), &"helper")
			GameState.add_npc_history(id, c.job_title + " (มิ้นทำ)")
	else:
		GameState.add_reputation(-1)
		if id != &"" and GameState.has_affinity(id):
			aff = GameState.add_affinity(id, floori(e.affinity_gain.get(&"fail", 0) / 2.0), &"helper")
	if visitor_toast:
		visitor_toast.show_message(
			("มิ้นทำงานของ%sเสร็จ +฿%d" % [npc_name(c), money]) if ok else ("มิ้นทำงานของ%sไม่สำเร็จ ลูกค้ากลับไปก่อน" % npc_name(c)),
			"ขมสอนมิ้นมาแล้ว %d ครั้ง · ทำงานระดับนี้ได้ 3 ดาวบ่อย ๆ มิ้นจะเก่งขึ้น" % int(GameState.level_three_stars.get(c.level, 0)))
	if reward_popup:
		reward_popup.pop_result({ "money": money, "reputation": 0 if ok else -1, "affinity": aff, "npc_name": npc_name(c) })
	GameState.story_flags[&"helper_used"] = true
	autosave.call_deferred()
	return { "ok": ok, "money": money, "affinity": aff }


# ---------------------------------------------------------------- [0.5.0 ขั้น H–I] หน้าเลื่อนยศ + ความสามารถช่าง


## ข้อมูลหน้าเลือก (ยศที่ยังไม่ได้เลือกต่ำสุด)
func perk_view() -> Dictionary:
	var r := GameState.perk_pending()
	if r <= 0:
		return { }
	var e := _econ()
	return { "rank": r, "title": "เลื่อนยศเป็น%s!" % e.rank_names[r], "unlocks": GameState.rank_unlock_lines(r), "options": GameState.perk_options(r) }


func _maybe_perk() -> bool:
	if perk_picker == null:
		return false
	if perk_picker.visible:
		_hide()
		return true
	if GameState.perk_pending() <= 0 or _working or not _in_shop() or Global.in_minigame or DialogScene.visible:
		return false
	if quiet: # บอท/เทสต์: เลือกทาง A ให้เอง
		var r := GameState.perk_pending()
		GameState.choose_perk(r, StringName(GameState.perk_options(r)[0].id))
		return false
	_hide()
	perk_picker.show_view(perk_view())
	return true


func _on_perk_chosen(r: int, id: StringName) -> void:
	if GameState.choose_perk(r, id) and visitor_toast:
		for o: Dictionary in GameState.perk_options(r):
			if String(o.id) == String(id):
				visitor_toast.show_message("ความสามารถช่าง: %s" % o.name, String(o.desc))
	_board_dirty = true
	autosave.call_deferred()


## [0.5.0 ขั้น L] บทสอนครั้งแรกของลูกค้าประจำ/ยศ ที่ถึงเงื่อนไขตอนนี้
func _npc_tutorials() -> Array[String]:
	var out: Array[String] = []
	if GameState.affinity_log.any(func(r: Dictionary) -> bool: return int(r.delta) > 0):
		out.append("tut_affinity")
	if not pending_story.is_empty() and not _result_pending:
		out.append("tut_story")
	if GameState.rank_ready():
		out.append("tut_exam")
	var j := door_front()
	if not j.is_empty() and helper_button(j).get("visible", false):
		out.append("tut_helper")
	return out
