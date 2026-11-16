extends Node
## GameState (autoload) — state ของลูปเกมที่ต้องอยู่ข้ามซีน: เงิน · ความพอใจ · XP · Part ที่ผ่านแล้ว · ธงเนื้อเรื่อง
## + บท Chapter ประจำรอบ / Epilogue / ตัดสินฉากจบ (DayLoop เป็นคนเรียกตอนครบรอบ)
## ดู Docs/GAME_LOOP.md §3 §4 §6 §7 · [Claude 5 ต.ค. 2569]

signal money_changed(money: int, delta: int)
## result: { part_id, score, grade, money, satisfaction, xp, damaged }
signal repair_recorded(result: Dictionary)
## ending: &"stay" · &"city" · &"coworking" · &"failure"
signal game_finished(ending: StringName)

enum Grade {
	GOOD,
	PASS,
	FAIL,
}

const ECONOMY_PATH := "res://Resources/Balance/economy.tres"
## เงินในมือห้ามเกินนี้ (ECONOMY_ENERGY 1.4) — ส่วนเกินเข้ากองทุนหมู่บ้าน
const MONEY_CAP := 50_000

signal reputation_changed(value: int, delta: int)
## [Claude 10 ต.ค. 2569] ได้ XP · เลื่อนยศช่าง (HUD โชว์ป้าย "เลื่อนขั้น!")
signal xp_changed(value: int, delta: int)
signal rank_up(rank: int, rank_name: String)
## บิลรายเดือน { month, power, grandma, internet, total, paid, debt }
signal bill_paid(bill: Dictionary)
## [0.2.0-E] ปิดเดือน: ผลเทียบเป้า (GameState.close_month)
signal month_closed(report: Dictionary)

## บทของแต่ละรอบ (index 0 = รอบ 1) · รอบ 1 เล่นผ่านเควสต์หลักแล้ว (main.tres) จึงไม่เปิดซ้ำ
const CHAPTERS := [
	{ "title": "กลับบ้าน", "file": "res://Assets/Dialog/Chapter1ReturnHome.txt", "bg": "" },
	{
		"title": "คอมพิวเตอร์เก่าของขม",
		"file": "res://Assets/Dialog/Chapter2Rest.txt",
		"bg": "res://Assets/Background/Chapter2_bg.jpg",
	},
	{
		"title": "จัดบ้านเป็นร้าน",
		"file": "res://Assets/Dialog/Chapter3DecorateHouse.txt",
		"bg": "res://Assets/Background/bg_shop_empty.jpg",
	},
	{
		"title": "เปิดร้านวันแรก",
		"file": "res://Assets/Dialog/Chapter4Start.txt",
		"bg": "res://Assets/Background/bg_shop_open.jpg",
	},
	{
		"title": "ร้านเงียบ",
		"file": "res://Assets/Dialog/Chapter5Quiet.txt",
		"bg": "res://Assets/Background/bg_shop_quiet.jpg",
	},
	{
		"title": "ร้านเริ่มคึกคัก",
		"file": "res://Assets/Dialog/Chapter6Happy.txt",
		"bg": "res://Assets/Background/bg_shop_busy.jpg",
	},
	{
		"title": "สอนคอมพิวเตอร์พื้นฐาน",
		"file": "res://Assets/Dialog/Chapter7Teaching.txt",
		"min_rank": 2, ## [0.8.0] ยศต่ำกว่านี้ = ผู้ใหญ่บ้านยังไม่ชวนสอนศาลา (ตรง act_sala.min_rank)
		"low_file": "res://Assets/Dialog/Chapter7Teaching_low.txt",
		"bg": "res://Assets/Background/bg_shop_open.jpg",
	},
	{ "title": "ไฟดับ", "file": "res://Assets/Dialog/Chapter8Problem.txt", "bg": "res://Assets/Background/HomeBG.jpg" },
	{
		"title": "สอนที่โรงเรียน",
		"file": "res://Assets/Dialog/Chapter9School.txt",
		"min_rank": 2, ## [0.8.0] ยศต่ำกว่านี้ = โรงเรียนจ้างร้านอื่น (ตรง cal_school.min_rank)
		"low_file": "res://Assets/Dialog/Chapter9School_low.txt",
		"bg": "res://Assets/Background/bg_school_room.jpg",
	},
	{
		"title": "งานหมู่บ้าน",
		"file": "res://Assets/Dialog/Chapter10Village.txt",
		"bg": "res://Assets/Background/bg_village_day.jpg",
	},
	{
		"title": "ทางแยก",
		"file": "res://Assets/Dialog/Chapter11Path.txt",
		"bg": "res://Assets/Background/bg_path_sunset.jpg",
	},
	{
		"title": "ครบหนึ่งปี",
		"file": "res://Assets/Dialog/Chapter12Year.txt",
		"bg": "res://Assets/Background/bg_year_after.jpg",
	},
]
const EPILOGUE := {
	"title": "บทส่งท้าย",
	"file": "res://Assets/Dialog/Epilogue.txt",
	"bg": "res://Assets/Background/bg_year_after.jpg",
}

var economy: EconomyConfig
var money := 0
## ความพอใจของทุกงานซ่อม (0–100)
var satisfaction_history: Array[int] = []
var xp := 0
## part_id → จำนวนครั้งที่ซ่อมผ่าน (ใช้ปลดล็อก / ข้ามบทสอนครั้งถัดไป)
var part_clears: Dictionary[StringName, int] = { }
## ธงเนื้อเรื่อง เช่น &"ch11_choice": &"stay" | &"city" | &"coworking"
var story_flags: Dictionary = { }
var ending: StringName = &""
## ชื่อเสียง 0–100 (GAME_REDESIGN 7.3)
var reputation := 20
## ระดับงาน → จำนวนงานที่ได้ ⭐⭐ ขึ้นไป (ปลดระดับถัดไป · LEVEL_DESIGN ข้อ 6)
var level_stars: Dictionary[int, int] = { }
## หนี้ค้าง (จ่ายบิลไม่พอ — ไม่ game over)
var debt := 0
## เงินที่ล้น MONEY_CAP
var village_fund := 0
## [0.2.0-E/F] ผลสิ้นเดือนที่ผ่านมา (month_report + strike/shop_closed)
var month_results: Array[Dictionary] = []
## พลาดเป้ากี่เดือน (นับหลังช่วงเรียนรู้) · ค้างบิลติดกันกี่เดือน · ร้านปิดแล้วไหม
var missed_months := 0
var debt_streak := 0
var shop_closed := false
## โหมดช่วย: เป้าเดือนลดลง (help_target_mult) · ไม่มีค่าปรับค้างชำระ
var help_mode := false
## [0.3.0 ขั้น D] งานบนชั้นวาง: ผลซ่อมครั้งถัดไปยังไม่จ่ายเงิน/ความพอใจ/ชื่อเสียง (ลูกค้ามารับเครื่องทีหลัง → pay_pickup)
## DayLoop ตั้งก่อนเปิดมินิเกมงานบนชั้น · record_repair ล้างให้เองทุกครั้ง · XP/สถิติ Part ได้ตอนซ่อมเสร็จเลย
var hold_next_payment := false

# ---- คลังของ (Docs/STORAGE_SHOP_ECO.md ข้อ 1) [Claude 13 ต.ค. 2569]
signal inventory_changed
## [13 ต.ค.] ได้ของเข้าคลัง (ซื้อ · ได้จากเนื้อเรื่อง/บทสอน · ชิ้นเก่าจากงานซ่อม) → Storage โชว์ป้าย "ได้ … เข้าคลัง"
signal item_received(item: ItemDef, qty: int)
## [0.3.0] ชั้นวางเครื่องขยาย (ซื้ออัปเกรด/โหลดเซฟ) → DayLoop.shelf.slots ตาม
signal shelf_slots_changed(slots: int)
## ข้อความเด้งรวมหลายชิ้น (เช่น ชุดเริ่มต้น) — Storage โชว์ข้อความนี้แทนป้ายทีละชิ้น
signal inventory_note(text: String)
## [0.4.0] มีอะไหล่เข้าคลัง (ซื้อตลาด / พัสดุออนไลน์มาถึง) → DayLoop จองให้เครื่องที่รอของ
signal parts_arrived

## [13 ต.ค.] ของติดตัวหลังจบบทสอนประกอบคอม (เล่นจบหรือกดข้ามก็ได้) — ให้ครั้งเดียวต่อเกม (story_flags.starter_kit)
## { id ใน Resources/Shop/: จำนวน } · แก้รายการได้ที่นี่
const STARTER_KIT := {
	&"ram_ddr3_4gb_used": 1, # แรมจากคอมเครื่องเก่าของขม
	&"cable_sata": 1,
	&"ipa90": 1,
	&"cable_tie": 1,
	&"paste_grey": 1, # [0.4.0] ของสิ้นเปลืองหักจริงแล้ว → ให้ครบชุดเริ่มต้น (ซิลิโคน · ลมกระป๋อง)
	&"air_can": 1,
}
## เควสต์หลักขั้นที่ (index) ถัดจากบทสอนประกอบคอม — ไปถึงขั้นนี้แล้ว = ได้ชุดเริ่มต้น
const STARTER_KIT_AFTER_STEP := 3
const STORAGE_START := 8
const SUPPLY_STACK_MAX := 99
## ช่องคลังทั้งหมด (อัปเกรดด้วย ItemDef UPGRADE)
var storage_slots := STORAGE_START
## [0.3.0] ช่องชั้นวางเครื่อง (เริ่ม EconomyConfig.shelf_slots_start · อัปเกรดด้วย ItemDef.shelf_slots_to)
var shelf_slots := 2
## ของในคลัง 1 รายการ = 1 ช่อง: { id, path, qty, condition, reserved_for, cost }
##   PART qty = 1 เสมอ · SUPPLY qty = จำนวนครั้งที่เหลือ (≤ SUPPLY_STACK_MAX)
##   [0.4.0] cost = ราคาที่ขมจ่ายต่อชิ้น (PART · ใช้คิดค่าอะไหล่ที่เก็บลูกค้า · ของได้ฟรี = 0)
var inventory: Array[Dictionary] = []
## ร้านขายไปแล้วกี่ชิ้นในรอบ shop_week (สต็อกตลาด · [0.4.0] 1 รอบ = market_restock_days วันเปิดร้าน · ชื่อตัวแปรเดิมคงไว้ให้เซฟเก่า)
var shop_bought: Dictionary = { }
var shop_week := 0
## [0.4.0] ของที่สั่งออนไลน์ ยังไม่มาถึง: { id, path, qty, cost, slots, arrive } · arrive = shift (วันเปิดร้าน) ที่ของมาถึง
## จองช่องคลังไว้แล้ว (used_slots นับ slots ด้วย)
var pending_orders: Array[Dictionary] = []
## อัปเกรดที่ซื้อแล้ว (id → true)
var upgrades: Dictionary = { }

# ---- [0.5.0] ลูกค้าประจำ + ความสนิท (PLAN_0_5_0 ข้อ 2) · รายชื่อ = NpcBook (Resources/NPC/)
## ความสนิทเปลี่ยน (id ของ CustomerNPC · ค่าใหม่ 0–100 · ส่วนต่าง · เหตุการณ์)
signal affinity_changed(id: StringName, value: int, delta: int, reason: StringName)
## ขึ้นระดับความสนิท (tier 1–4 = รู้จัก … ขาประจำ)
signal affinity_tier_up(id: StringName, tier: int)
## id → ค่า 0–100 (ยังไม่มี = start_affinity ของ NPC)
var npc_affinity: Dictionary[StringName, int] = { }
## id → [{ ch, day, text }] เคยซ่อมอะไร (ล่าสุดอยู่ท้าย · ไม่เกิน npc_history_max)
var npc_history: Dictionary = { }
## id → shift ที่มาร้านล่าสุด (ใช้ลดโอกาสมาซ้ำ)
var npc_last_visit: Dictionary = { }
## id → [at, ...] เรื่องส่วนตัวที่ฟังแล้ว
var npc_stories_seen: Dictionary = { }
## [{ ch, id, delta }] ความสนิทที่ได้/เสียแต่ละครั้ง (สรุปเดือน)
var affinity_log: Array[Dictionary] = []


func _ready() -> void:
	if has_node(^"/root/EventManager"):
		EventManager.sendUpdatedEvent.connect(_on_quest_updated)
	economy = load(ECONOMY_PATH) as EconomyConfig
	if economy == null:
		push_warning("ไม่พบ %s ใช้ค่าเริ่มต้น" % ECONOMY_PATH)
		economy = EconomyConfig.new()
	reset()


## [0.7.0 ขั้น A] seed ของเกมนี้ (สุ่มครั้งเดียวตอนเริ่มเกมใหม่ · เข้าเซฟ) · seed_override ≠ 0 = เทสต์/บอทกำหนดเอง
var run_seed := 1
var seed_override := 0
## [0.7.0 ขั้น B] สถานะอีเวนต์ { last: {key: shift} · done: {id: true} · ตัวนับ (booth · scam_safe · …) } · ประวัติ — เซฟ
var event_state: Dictionary = { }
var event_log: Array[Dictionary] = []
## [0.7.0 ขั้น I] บัญชีดำร้านออนไลน์ { seller id: { why (scammed · reported), lost } } — เซฟ
var seller_blacklist: Dictionary = { }
## [0.7.0 ขั้น J] ใบประกาศที่ได้ { id: { month, day } } · ตัวนับของใบประกาศ (passes · three_<part> · safe_best · no_hint · on_time) — เซฟ
var achievements: Dictionary = { }
var ach_stats: Dictionary = { }
## ใบประกาศที่เลือกติดผนังร้าน (สูงสุด 3) — เซฟ
var ach_pinned: Array = []
## [0.8.0 ขั้น G] ของขวัญสิ้นปีที่ได้รับ { npc_id (String): decor_id (String) } (DecorBook)
var gifts_received: Dictionary = { }
## [0.9.0 ขั้น A] รหัสผู้ทดสอบ (ไม่ล้างตอนเริ่มเกมใหม่ · ถามใหม่ในบิลด์ผู้ทดสอบ) · เวลาเล่นสะสม (วินาที · Playlog นับ) · เปิดฟอร์มก่อน/หลังเล่นแล้ว — เซฟ v10
var tester_id := ""
var playtime_sec := 0.0
var form_pre_opened := false
var form_post_opened := false


func reset() -> void:
	run_seed = seed_override if seed_override != 0 else randi_range(1, 2147483646)
	event_state = { }
	event_log.clear()
	seller_blacklist = { }
	achievements = { }
	ach_stats = { }
	ach_pinned = []
	gifts_received = { }
	playtime_sec = 0.0
	form_pre_opened = false
	form_post_opened = false
	money = economy.start_money
	hold_next_payment = false
	satisfaction_history.clear()
	xp = 0
	rank_level = 0
	exam_last_shift = -1
	perks.clear()
	level_three_stars.clear()
	learn_log.clear()
	scenario_log.clear()
	request_log.clear()
	group_fair_count = 0
	exam_attempts.clear()
	part_clears.clear()
	story_flags.clear()
	ending = &""
	reputation = economy.reputation_start
	level_stars.clear()
	debt = 0
	village_fund = 0
	storage_slots = STORAGE_START
	shelf_slots = economy.shelf_slots_start if economy else 2
	inventory.clear()
	pending_orders.clear()
	shop_bought.clear()
	shop_week = 0
	upgrades.clear()
	npc_affinity.clear()
	npc_history.clear()
	npc_last_visit.clear()
	npc_stories_seen.clear()
	affinity_log.clear()
	ledger.clear()
	month_results.clear()
	missed_months = 0
	debt_streak = 0
	shop_closed = false
	inventory_changed.emit()
	money_changed.emit(money, 0)
	reputation_changed.emit(reputation, 0)

# ---------------------------------------------------------------- เงิน


## เปลี่ยนเงิน + จดลง ledger · kind = หมวด (MONEY_KINDS) · note = ข้อความสั้น เช่น ชื่อของ
## chapter > 0 = บังคับบทที่จด (ใช้ตอนจ่ายบิล ซึ่งยิงหลัง TimeSystem ขึ้นบทใหม่แล้ว)
func add_money(delta: int, kind: StringName = &"other", note := "", chapter := 0) -> void:
	if delta == 0:
		return
	money += delta
	if money > MONEY_CAP:
		village_fund += money - MONEY_CAP
		delta -= money - MONEY_CAP
		money = MONEY_CAP
	if delta != 0:
		var when := _ledger_when()
		ledger.append({
			"ch": chapter if chapter > 0 else when.x,
			"day": when.y if chapter <= 0 else 0,
			"kind": kind if MONEY_KINDS.has(kind) else &"other",
			"amount": delta,
			"note": note,
		})
	money_changed.emit(money, delta)

# ---------------------------------------------------------------- [0.2.0-C] บันทึกรายรับ–รายจ่าย (ledger)
# Docs/ROADMAP_1_0_0.md ข้อ 8.1 C · กำไรของบท = รายรับ − รายจ่าย (ไม่นับหมวด "ลงทุน" = ของที่อยู่ถาวร เช่น ชั้น/ตู้คลัง)

## หมวดเงิน → ชื่อบนจอ
const MONEY_KINDS := {
	&"fee": "ค่าแรง",
	&"part_fee": "ค่าอะไหล่จากลูกค้า",
	&"tip": "ทิป",
	&"sell": "ขายของคืน",
	&"damage": "ชดใช้ของเสียหาย",
	&"bill": "บิลรายเดือน",
	&"ot_power": "ค่าไฟล่วงเวลา",
	&"buy": "ซื้ออะไหล่/ของ",
	&"invest": "ลงทุน",
	&"scam": "โดนโกง", # [0.7.0] มิจฉาชีพ · ร้านออนไลน์ปลอม
	&"other": "อื่น ๆ",
}

## รายการเงินเข้า/ออกทั้งเกม: { ch = บท 1–12 (0 = ไม่รู้บท), day = วันที่ 1–5 ของบท (0 = สิ้นบท), kind, amount (+ เข้า / − ออก), note }
var ledger: Array[Dictionary] = []


func _ledger_when() -> Vector2i:
	var em := get_node_or_null(^"/root/EventManager")
	var ts = em.get("time_system") if em else null
	if not is_instance_valid(ts):
		return Vector2i.ZERO
	return Vector2i((ts as TimeSystem).chapter(), (ts as TimeSystem).shift_in_week())


## รายการของบท ch
func chapter_entries(ch: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in ledger:
		if int(e.ch) == ch:
			out.append(e)
	return out


## ยอดรวมต่อหมวดของบท ch → { kind: amount }
func chapter_by_kind(ch: int) -> Dictionary:
	var out := { }
	for e in chapter_entries(ch):
		out[e.kind] = int(out.get(e.kind, 0)) + int(e.amount)
	return out


## รายรับของบท (เงินเข้า ไม่นับลงทุน)
func chapter_income(ch: int) -> int:
	var n := 0
	for e in chapter_entries(ch):
		if int(e.amount) > 0 and e.kind != &"invest":
			n += int(e.amount)
	return n


## รายจ่ายของบท (เป็นบวก ไม่นับลงทุน)
func chapter_expense(ch: int) -> int:
	var n := 0
	for e in chapter_entries(ch):
		if int(e.amount) < 0 and e.kind != &"invest":
			n -= int(e.amount)
	return n


## เงินลงทุนของบท (เป็นบวก)
func chapter_invest(ch: int) -> int:
	var n := 0
	for e in chapter_entries(ch):
		if e.kind == &"invest":
			n -= int(e.amount)
	return n


## กำไรของบท = รายรับ − รายจ่าย (ใช้เทียบเป้าเดือน · ไม่นับลงทุน)
func chapter_profit(ch: int) -> int:
	return chapter_income(ch) - chapter_expense(ch)


## [0.2.0] เดือนของบท · [0.2.5] 1 บท = 1 เดือน (TimeSystem.WEEKS_PER_MONTH = 1) → คืนบทเดิม
static func month_of(ch: int) -> int:
	return floori((maxi(ch, 1) - 1) / float(TimeSystem.WEEKS_PER_MONTH)) + 1


## รายการของเดือน m (รวมทุกบทในเดือน)
func month_entries(m: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in ledger:
		if int(e.ch) > 0 and month_of(int(e.ch)) == m:
			out.append(e)
	return out


func month_by_kind(m: int) -> Dictionary:
	var out := { }
	for e in month_entries(m):
		out[e.kind] = int(out.get(e.kind, 0)) + int(e.amount)
	return out


func month_income(m: int) -> int:
	var n := 0
	for e in month_entries(m):
		if int(e.amount) > 0 and e.kind != &"invest":
			n += int(e.amount)
	return n


func month_expense(m: int) -> int:
	var n := 0
	for e in month_entries(m):
		if int(e.amount) < 0 and e.kind != &"invest":
			n -= int(e.amount)
	return n


func month_invest(m: int) -> int:
	var n := 0
	for e in month_entries(m):
		if e.kind == &"invest":
			n -= int(e.amount)
	return n


## กำไรของเดือน (เทียบเป้าเดือน · ไม่นับลงทุน)
func month_profit(m: int) -> int:
	return month_income(m) - month_expense(m)


func add_reputation(delta: int) -> void:
	if delta == 0:
		return
	var before := reputation
	reputation = clampi(reputation + delta, 0, 100)
	reputation_changed.emit(reputation, reputation - before)


## จ่ายบิลรายเดือน (TimeSystem.month_ended) · เงินไม่พอ = จ่ายเท่าที่มี ส่วนที่เหลือเป็นหนี้
## [0.2.0] บิลสิ้นบท (1 บท = 1 เดือน) · slots_worked = เทิร์นที่ทำงานในบทนี้ (ใช้คิดค่าไฟ)
## คืน { month, rent, power, water, internet, prev_debt, total, paid, debt }
func pay_month_bill(month: int, slots_worked := 0) -> Dictionary:
	var e := economy if economy else EconomyConfig.new()
	var bill := {
		"month": month,
		"rent": e.month_value(e.bill_rent, month),
		"power": roundi((e.month_value(e.power_base, month) + e.power_per_slot * maxi(slots_worked, 0)) * (e.perk_power_mult if has_perk(&"power_saver") else 1.0)),
		"water": e.bill_water,
		"internet": e.bill_internet,
		"prev_debt": debt,
		# [0.2.0-F] ค้างชำระเดือนก่อน → ค่าปรับ (โหมดช่วยไม่มี)
		"late_fee": 0 if help_mode or debt <= 0 else ceili(debt * e.late_fee_rate),
	}
	bill["total"] = int(bill["rent"]) + int(bill["power"]) + int(bill["water"]) + int(bill["internet"]) + debt + int(bill["late_fee"])
	var paid := mini(maxi(money, 0), int(bill["total"]))
	# จดเข้าบทสุดท้ายของเดือนนั้น (บิลจ่ายตอน TimeSystem ขึ้นเดือนใหม่แล้ว)
	add_money(-paid, &"bill", "บิลเดือนที่ %d" % month, month * TimeSystem.WEEKS_PER_MONTH)
	debt = int(bill["total"]) - paid
	bill["paid"] = paid
	bill["debt"] = debt
	bill_paid.emit(bill)
	return bill


# ---------------------------------------------------------------- [0.2.0-E/F] ผลสิ้นเดือน


## เป้ากำไรของเดือน m (โหมดช่วยลดลง)
func target_of(m: int) -> int:
	var e := economy if economy else EconomyConfig.new()
	var t := e.target_for(m)
	return roundi(t * e.help_target_mult) if help_mode else t


## สรุปเดือน m (ไม่เปลี่ยนสถานะอะไร) — ใช้ทำหน้าสรุปเดือนและแถบเป้า
## { m, income, expense, invest, profit, target, ratio, reached, over, debt, by_kind, hint }
func month_report(m: int) -> Dictionary:
	var e := economy if economy else EconomyConfig.new()
	var target := maxi(target_of(m), 1)
	var profit := month_profit(m)
	var rep := {
		"m": m,
		"income": month_income(m),
		"expense": month_expense(m),
		"invest": month_invest(m),
		"profit": profit,
		"target": target,
		"ratio": float(profit) / target,
		"reached": profit >= target,
		"over": profit >= roundi(target * e.over_target_ratio),
		"debt": debt,
		"by_kind": month_by_kind(m),
	}
	rep["hint"] = _month_hint(rep)
	return rep


## ปิดเดือน m (เรียกหลังจ่ายบิล): นับพลาดเป้า/ค้างบิล → ร้านปิดไหม · เก็บผลไว้ใน month_results
func close_month(m: int) -> Dictionary:
	var e := economy if economy else EconomyConfig.new()
	var rep := month_report(m)
	var counted := m > e.grace_months
	rep["counted"] = counted
	rep["strike"] = counted and not bool(rep.reached)
	# [0.2.5] นับพลาดเป้า "ติดกัน" — ถึงเป้าเดือนไหนเริ่มนับใหม่ (เกม 12 เดือน ให้โอกาสแก้ตัว)
	if rep.strike:
		missed_months += 1
	elif counted:
		missed_months = 0
	debt_streak = debt_streak + 1 if debt > 0 else 0
	shop_closed = shop_closed or missed_months >= e.fail_missed_months or debt_streak >= e.fail_debt_months
	rep["missed_months"] = missed_months
	rep["debt_streak"] = debt_streak
	rep["shop_closed"] = shop_closed
	if bool(rep.reached):
		add_reputation(e.rep_month_goal)
	month_results.append(rep)
	month_closed.emit(rep)
	return rep


## ปิ๊บบอกสาเหตุ 1 ข้อ
func _month_hint(rep: Dictionary) -> String:
	var by: Dictionary = rep.by_kind
	var income := maxi(int(rep.income), 1)
	if int(rep.debt) > 0:
		return "เงินไม่พอจ่ายบิล ยอดที่ค้างจะโดนค่าปรับเดือนหน้า เก็บเงินไว้จ่ายบิลก่อนซื้อของที่ยังไม่จำเป็นนะ"
	if bool(rep.over):
		return "เกินเป้าไปเยอะเลย! ลองเก็บเงินส่วนหนึ่งไว้ลงทุนกับร้านดูไหม"
	if bool(rep.reached):
		return "ถึงเป้าแล้ว เดือนหน้าเป้าจะสูงขึ้น รับงานที่ยากขึ้นได้แล้วนะ"
	if -int(by.get(&"damage", 0)) > 0:
		return "เดือนนี้ต้องชดใช้ของลูกค้าที่เสีย เลือกเครื่องมือให้ถูกและทำตามขั้นตอนจะไม่พลาดนะ"
	if -int(by.get(&"buy", 0)) > income * 0.3:
		return "เดือนนี้ซื้อของเยอะ ลองซื้อเฉพาะที่ต้องใช้กับงานก่อนนะ"
	if -int(by.get(&"ot_power", 0)) > income * 0.1:
		return "ทำงานล่วงเวลาบ่อย ค่าไฟเลยแพง ลองเลือกงานให้พอดีกับเวลาในวันนะ"
	return "รายได้ยังน้อย ลองรับงานให้มากขึ้น หรือทำให้ได้ 3 ดาวจะได้ทิปด้วยนะ"


## ---------------------------------------------------------------- [0.5.0] ความสนิท


func _econ() -> EconomyConfig:
	return economy if economy else EconomyConfig.new()


## ค่าความสนิท 0–100 (ลูกค้าขาจร/ไม่มีค่าความสนิท = 0)
func affinity(id: StringName) -> int:
	var g := NpcBook.by_id(id)
	if g and g.is_group(): # [0.6.0 ขั้น I] ความสนิทกลุ่ม = เฉลี่ยสมาชิก
		var ids := g.member_ids()
		var sum := 0
		for m in ids:
			sum += affinity(m)
		return roundi(float(sum) / maxi(ids.size(), 1))
	if npc_affinity.has(id):
		return npc_affinity[id]
	var n := NpcBook.by_id(id)
	return n.start_affinity if n and n.has_affinity else 0


## ระดับ 0–4 (แปลกหน้า … ขาประจำ)
func affinity_tier(id: StringName) -> int:
	return _econ().affinity_tier(affinity(id))


func affinity_tier_name(id: StringName) -> String:
	return _econ().affinity_tier_name(affinity_tier(id))


## หัวใจ 0–5 ดวง (ครึ่งดวงได้)
func affinity_hearts(id: StringName) -> float:
	return snappedf(affinity(id) / 20.0, 0.5)


func has_affinity(id: StringName) -> bool:
	var n := NpcBook.by_id(id)
	return n != null and (n.has_affinity or n.is_group()) # [0.6.0] กลุ่ม = ค่าเฉลี่ยของสมาชิก


## เปลี่ยนความสนิท · คืนส่วนต่างที่เปลี่ยนจริง (ชนเพดาน/ไม่มีค่าความสนิท = 0)
func add_affinity(id: StringName, delta: int, reason: StringName = &"") -> int:
	var grp := NpcBook.by_id(id)
	if grp and grp.is_group() and delta != 0: # [0.6.0 ขั้น I] ผลงานของกลุ่มเข้าทุกคนที่มา · คืนค่าเฉลี่ย
		var total := 0
		for m in grp.member_ids():
			total += add_affinity(m, delta, reason)
		return roundi(float(total) / maxi(grp.member_ids().size(), 1))
	if delta == 0 or not has_affinity(id):
		return 0
	if delta > 0 and has_perk(&"sweet_talk"): # [ขั้น I] ปากหวาน
		delta = ceili(delta * _econ().perk_affinity_mult)
	var npc := NpcBook.by_id(id) # [0.6.0 ขั้น H] นักเรียนจำคนใจดีได้ ×1.5
	if delta > 0 and npc and npc.affinity_mult != 1.0:
		delta = ceili(delta * npc.affinity_mult)
	var before := affinity(id)
	var after := clampi(before + delta, 0, 100)
	if after == before:
		return 0
	npc_affinity[id] = after
	var when := _ledger_when()
	affinity_log.append({ "ch": when.x, "id": String(id), "delta": after - before })
	affinity_changed.emit(id, after, after - before, reason)
	var e := _econ()
	if e.affinity_tier(after) > e.affinity_tier(before):
		affinity_tier_up.emit(id, e.affinity_tier(after))
	return after - before


## ความสนิทตามเหตุการณ์ (EconomyConfig.affinity_gain) · times = จำนวนครั้ง (เช่น เลยนัดกี่วัน)
func affinity_event(id: StringName, event: StringName, times := 1) -> int:
	return add_affinity(id, int(_econ().affinity_gain.get(event, 0)) * times, event)


## ความสนิทที่ได้/เสียในบท ch: { id: delta }
func affinity_gains(ch: int) -> Dictionary:
	var out := { }
	for r in affinity_log:
		if int(r.ch) == ch:
			out[StringName(r.id)] = int(out.get(StringName(r.id), 0)) + int(r.delta)
	return out


## หัวใจเป็นตัวอักษร "♥♥♡♡♡" (ปัดลง)
func affinity_hearts_text(id: StringName) -> String:
	var n := clampi(floori(affinity(id) / 20.0), 0, 5)
	return "♥".repeat(n) + "♡".repeat(5 - n)


## ขึ้นระดับถัดไปอีกกี่แต้ม (-1 = สูงสุดแล้ว)
func affinity_to_next(id: StringName) -> int:
	var e := _econ()
	var t := affinity_tier(id)
	return e.affinity_tiers[t] - affinity(id) if t < e.affinity_tiers.size() else -1


## สรุปความสนิทที่ขึ้น/ลงในบท ch: "ลุงอำนวย ♥+16 · ครู ♥−3" (เรียงจากขึ้นมากสุด)
func affinity_summary(ch: int) -> String:
	var g := affinity_gains(ch)
	var ids := g.keys()
	ids.sort_custom(func(a, b) -> bool: return int(g[a]) > int(g[b]))
	var parts := PackedStringArray()
	for id in ids:
		var d := int(g[id])
		if d == 0:
			continue
		var n := NpcBook.by_id(id)
		parts.append("%s ♥%s%d" % [n.display_name if n else String(id), "+" if d > 0 else "−", absi(d)])
	return " · ".join(parts)


## จดว่ามาร้าน (shift = วันเปิดร้านที่มา)
func note_visit(id: StringName, shift: int) -> void:
	if id != &"":
		npc_last_visit[id] = shift


func met(id: StringName) -> bool:
	return npc_last_visit.has(id)


## มาร้านภายใน affinity_recent_days วันเปิดร้านก่อน shift นี้ไหม
func visited_recently(id: StringName, shift: int) -> bool:
	if not npc_last_visit.has(id):
		return false
	var gap := shift - int(npc_last_visit[id])
	return gap >= 0 and gap <= _econ().affinity_recent_days


## จดประวัติเครื่อง ("แรม · ม.ค.")
func add_npc_history(id: StringName, text: String) -> void:
	if id == &"" or text.is_empty():
		return
	var when := _ledger_when()
	var arr: Array = npc_history.get(id, [])
	arr.append({ "ch": when.x, "day": when.y, "text": text })
	while arr.size() > _econ().npc_history_max:
		arr.pop_front()
	npc_history[id] = arr


func story_seen(id: StringName, at: int) -> bool:
	return (npc_stories_seen.get(id, []) as Array).has(at)


func mark_story_seen(id: StringName, at: int) -> void:
	var arr: Array = npc_stories_seen.get(id, [])
	if not arr.has(at):
		arr.append(at)
	npc_stories_seen[id] = arr


## [0.5.0 ขั้น F] ยศช่าง 0–4 = ยศที่สอบผ่านแล้ว (rank_level) · XP ถึงเกณฑ์ = มีสิทธิ์สอบ (rank_ready) · สอบผ่าน → promote()
var rank_level := 0
## XP ครบเกณฑ์ยศถัดไปแล้ว รอสอบ (ยิงครั้งเดียวตอนข้ามเกณฑ์)
signal rank_exam_ready(target: int)
## [ขั้น G] ผลสอบรายข้อ { ch, day, target, attempt, qid, part, chosen, correct } — เซฟ + user://learn_log.csv
var learn_log: Array[Dictionary] = []
## [0.6.0 ขั้น C] ผลสถานการณ์ซ่อม { ch, day, id, part, first_try, wrong, skipped, did_optional, score, gave_up } — เซฟ + user://scenario_log.csv
var scenario_log: Array[Dictionary] = []
## [0.6.0 ขั้น G] ผลคำขอ { ch, day, id, kind, topic, right, steps, npc } — เซฟ
var request_log: Array[Dictionary] = []
## [0.6.0 ขั้น I] ตัดสินความเห็นไม่ตรงกันของกลุ่มแบบทุกคนพอใจ (Achievement R05 ใน 0.7.0) — เซฟ
var group_fair_count := 0
## ยศเป้าหมาย → สอบมาแล้วกี่ครั้ง
var exam_attempts: Dictionary = { }
## วันเปิดร้าน (shift) ที่สอบล่าสุด — สอบได้วันละครั้ง
var exam_last_shift := -1
## [ขั้น I] ความสามารถช่างที่เลือก: ยศ (1–4) → id
var perks: Dictionary = { }
## [ขั้น J] ระดับงาน → จำนวนงานที่ได้ ⭐⭐⭐ (มิ้นเรียนจากงานที่ขมทำดี)
var level_three_stars: Dictionary = { }
signal perk_chosen(rank: int, id: StringName)


func has_perk(id: StringName) -> bool:
	return perks.values().has(id) or perks.values().has(String(id))


## ยศที่ยังไม่ได้เลือกความสามารถ (ต่ำสุดก่อน · 0 = ไม่มีค้าง)
func perk_pending() -> int:
	for r in range(1, rank_level + 1):
		if not perks.has(r) and _econ().perk_options.has(r):
			return r
	return 0


func perk_options(r: int) -> Array:
	return _econ().perk_options.get(r, [])


func choose_perk(r: int, id: StringName) -> bool:
	if perks.has(r) or r > rank_level or not perk_options(r).any(func(o: Dictionary) -> bool: return String(o.id) == String(id)):
		return false
	perks[r] = id
	perk_chosen.emit(r, id)
	return true


func rank() -> int:
	return rank_level


## ยศที่ XP ถึงเกณฑ์ (ไม่สนว่าสอบหรือยัง)
func xp_rank() -> int:
	var e := economy if economy else EconomyConfig.new()
	var r := 0
	for i in e.rank_xp.size():
		if xp >= e.rank_xp[i]:
			r = i
	return r


## XP ครบเกณฑ์ยศถัดไปแล้ว (สอบได้)
func rank_ready() -> bool:
	return xp_rank() > rank_level


## สอบผ่าน → ขึ้นยศ 1 ขั้น (ไม่เกิน xp_rank) · ยิง rank_up (ป้าย "เลื่อนขั้น!")
func promote() -> bool:
	if not rank_ready():
		return false
	rank_level += 1
	rank_up.emit(rank_level, rank_name())
	return true


## ตั้งยศตรง ๆ (เทสต์/บอท/โหลดเซฟเก่า) · XP ไม่พอก็เติมให้ถึงเกณฑ์
func set_rank(r: int) -> void:
	var e := economy if economy else EconomyConfig.new()
	rank_level = clampi(r, 0, e.rank_xp.size() - 1)
	xp = maxi(xp, e.rank_xp[rank_level])


## เพิ่ม XP · ข้ามเกณฑ์ยศถัดไป → rank_exam_ready (ยังไม่เลื่อน ต้องสอบก่อน)
func add_xp(gained: int) -> void:
	if gained == 0:
		return
	var was_ready := rank_ready()
	xp = maxi(xp + gained, 0)
	xp_changed.emit(xp, gained)
	if not was_ready and rank_ready():
		rank_exam_ready.emit(rank_level + 1)


## XP ที่ต้องมีเพื่อขึ้นยศถัดไป (-1 = ยศสูงสุดแล้ว)
func xp_next() -> int:
	var e := economy if economy else EconomyConfig.new()
	var r := rank()
	return e.rank_xp[r + 1] if r + 1 < e.rank_xp.size() else -1


## ความคืบหน้าในยศปัจจุบัน 0–1 (ยศสูงสุด = 1)
func rank_progress() -> float:
	var e := economy if economy else EconomyConfig.new()
	var nxt := xp_next()
	if nxt < 0:
		return 1.0
	var cur: int = e.rank_xp[rank()]
	return clampf(float(xp - cur) / float(maxi(nxt - cur, 1)), 0.0, 1.0)


func rank_name() -> String:
	var e := economy if economy else EconomyConfig.new()
	return e.rank_names[clampi(rank(), 0, e.rank_names.size() - 1)]


## งานระดับนี้ขึ้นกระดานได้ไหม · Lv1–2 เปิดตั้งแต่แรก · Lv n+1 ต้องได้ ⭐⭐ ใน Lv n ครบ unlock_stars_needed งาน
func level_unlocked(level: int) -> bool:
	if level <= 2:
		return true
	var e := economy if economy else EconomyConfig.new()
	return level_stars.get(level - 1, 0) >= e.unlock_stars_needed and rank_level >= _rank_for_level(level)


## [0.5.0 ขั้น H] ยศขั้นต่ำของงานระดับนี้
func _rank_for_level(level: int) -> int:
	var e := _econ()
	return e.rank_job_level[clampi(level, 1, e.rank_job_level.size()) - 1] if not e.rank_job_level.is_empty() else 0


## ทำไมงานระดับนี้ยังล็อก ("" = ปลดแล้ว)
func level_lock_reason(level: int) -> String:
	if level_unlocked(level):
		return ""
	var e := _econ()
	var why := PackedStringArray()
	if level > 2 and level_stars.get(level - 1, 0) < e.unlock_stars_needed:
		why.append("ทำ Lv%d ให้ได้ ⭐⭐ อีก %d งาน" % [level - 1, e.unlock_stars_needed - level_stars.get(level - 1, 0)])
	if rank_level < _rank_for_level(level):
		why.append("เป็น%s" % e.rank_names[_rank_for_level(level)])
	return "ต้อง" + " และ".join(why)


## [0.5.0 ขั้น H] สิ่งที่ยศนี้ปลด (การ์ดหลังสอบผ่าน)
## [0.6.0 ขั้น J] มีเครื่องมือนี้แล้ว (ได้ตอนเลื่อนยศ)
func has_tool(id: StringName) -> bool:
	var e := _econ()
	for r in e.rank_tools:
		if int(r) <= rank_level and (e.rank_tools[r] as Array).has(id):
			return true
	return false


func rank_unlock_lines(r: int) -> PackedStringArray:
	var e := _econ()
	var out := PackedStringArray()
	for t in e.rank_tools.get(r, []): # [0.6.0 ขั้น J]
		out.append("เครื่องมือ: %s — %s" % [EconomyConfig.TOOL_NAMES.get(t, String(t)), EconomyConfig.TOOL_NOTES.get(t, "")])
	if r == e.guide_hint_rank:
		out.append("ไกด์ขึ้นเมื่อขอคำใบ้เท่านั้น · ทำเองไม่ขอคำใบ้ คะแนน +%d" % e.self_bonus)
	for lv in range(1, 6):
		if _rank_for_level(lv) == r and r > 0:
			out.append("งาน Lv%d %s" % [lv, CustomerCase.LEVEL_NAMES[lv - 1]])
	var items := PackedStringArray()
	for f in DirAccess.get_files_at("res://Resources/Shop/"):
		var p := "res://Resources/Shop/" + f.trim_suffix(".remap")
		if p.ends_with(".tres"):
			var it := load(p) as ItemDef
			if it and it.unlock_rank == r and r > 0:
				items.append(it.display_name)
	if not items.is_empty():
		out.append("ซื้อ " + " · ".join(items))
	if r == e.announce_rank:
		out.append("ผู้ใหญ่บ้านประกาศเสียงตามสาย (ต้นเดือนลูกค้า +%d)" % e.announce_extra_visitors)
	if r == e.helper_rank:
		out.append("มิ้นเป็นลูกมือ (ฝากงานขมOS วันละ 1)")
	out.append("ค่าอะไหล่ +%s%%" % String.num(e.part_markup(r) * 100.0, 1).trim_suffix(".0"))
	return out


func can_afford(cost: int) -> bool:
	return money >= cost

# ---------------------------------------------------------------- คลังของ + ซื้อของ


func used_slots() -> int:
	var n := inventory.size()
	for o in pending_orders:
		n += int(o.get("slots", 0))
	return n


func free_slots() -> int:
	return maxi(storage_slots - used_slots(), 0)


## ItemDef ของรายการในคลัง
func item_of(entry: Dictionary) -> ItemDef:
	var p := String(entry.get("path", ""))
	return load(p) as ItemDef if p != "" and ResourceLoader.exists(p) else null


## ต้องใช้ช่องเพิ่มกี่ช่องถ้าเก็บ item × qty
func slots_needed(item: ItemDef, qty := 1) -> int:
	if item == null or item.kind == ItemDef.Kind.UPGRADE:
		return 0
	if item.kind == ItemDef.Kind.PART:
		return qty
	var add := item.uses * qty
	for e in inventory:
		if e.id == item.id:
			add -= SUPPLY_STACK_MAX - int(e.qty)
	return maxi(ceili(add / float(SUPPLY_STACK_MAX)), 0)


func can_store(item: ItemDef, qty := 1) -> bool:
	return slots_needed(item, qty) <= free_slots()


## เก็บเข้าคลัง (ไม่หักเงิน) · ช่องไม่พอ = false · force = ยัดเข้าไปเลยแม้ช่องเต็ม (ใช้กับ give_item)
## [0.4.0] cost = ราคาที่จ่ายต่อชิ้น (PART) · -1 = ของได้ฟรี (0)
func add_item(item: ItemDef, qty := 1, force := false, notify := true, cost := -1) -> bool:
	if item == null or (not force and not can_store(item, qty)):
		return false
	match item.kind:
		ItemDef.Kind.UPGRADE:
			upgrades[item.id] = true
			storage_slots = maxi(storage_slots, item.storage_slots_to)
			if item.shelf_slots_to > shelf_slots:
				set_shelf_slots(item.shelf_slots_to)
		ItemDef.Kind.PART:
			for i in qty:
				inventory.append({ "id": item.id, "path": item.resource_path, "qty": 1, "condition": item.condition, "reserved_for": "", "cost": maxi(cost, 0) })
		ItemDef.Kind.SUPPLY:
			var left := item.uses * qty
			for e in inventory:
				if left <= 0:
					break
				if e.id == item.id and int(e.qty) < SUPPLY_STACK_MAX:
					var put := mini(SUPPLY_STACK_MAX - int(e.qty), left)
					e.qty = int(e.qty) + put
					left -= put
			while left > 0:
				var put := mini(SUPPLY_STACK_MAX, left)
				inventory.append({ "id": item.id, "path": item.resource_path, "qty": put, "condition": "", "reserved_for": "", "cost": 0 })
				left -= put
	inventory_changed.emit()
	if notify:
		item_received.emit(item, qty)
	return true


## [13 ต.ค.] ได้ชิ้นส่วนมา (เนื้อเรื่อง · บทสอน · ของแถม · ชิ้นเก่าที่ถอดออก) → ยัดเข้าคลังทันที ไม่สนว่าอยู่ในบทสอน/มินิเกมหรือช่องเต็ม
## ช่องเกิน = คลังโชว์ตัวเลขสีแดง และซื้อของเพิ่มไม่ได้จนกว่าจะขาย/ใช้ออก · รับได้ทั้ง ItemDef หรือ id ไฟล์ใน Resources/Shop/
func give_item(item_or_id: Variant, qty := 1, notify := true) -> bool:
	var item: ItemDef = item_or_id as ItemDef if item_or_id is ItemDef else null
	if item == null:
		var p := "res://Resources/Shop/%s.tres" % String(item_or_id)
		item = load(p) as ItemDef if ResourceLoader.exists(p) else null
	if item == null:
		push_warning("give_item: ไม่พบของ %s" % str(item_or_id))
		return false
	return add_item(item, qty, true, notify)


## ให้ชุดเริ่มต้น (ครั้งเดียว) · เรียกจากจบบทสอนประกอบคอม / เควสต์หลักเลยขั้นนั้นไปแล้ว (รวม Debug jump · เซฟเก่า)
func ensure_starter_kit() -> void:
	if story_flags.get(&"starter_kit", false):
		return
	story_flags[&"starter_kit"] = true
	var names: Array[String] = []
	for id in STARTER_KIT:
		if give_item(id, int(STARTER_KIT[id]), false):
			var it := load("res://Resources/Shop/%s.tres" % String(id)) as ItemDef
			names.append(it.display_name.get_slice(" (", 0) if it else String(id))
	if not names.is_empty():
		inventory_note.emit("ได้ของติดตัวเข้าคลัง: " + ", ".join(names))


func _on_quest_updated(id, event) -> void:
	if not has_node(^"/root/EventManager") or id != EventManager.EventID.MAIN:
		return
	if event == null or event.isDone or int(event.currentTask) >= STARTER_KIT_AFTER_STEP:
		ensure_starter_kit()


## จำนวนในคลัง (PART = ชิ้น · SUPPLY = ครั้ง)
func count_item(id: StringName) -> int:
	var n := 0
	for e in inventory:
		if e.id == id:
			n += int(e.qty)
	return n


## ใช้/หยิบออก (PART = ชิ้น · SUPPLY = ครั้ง) · ข้ามชิ้นที่จองไว้ให้งานอื่น · ไม่พอ = false (ไม่หักอะไรเลย)
func take_item(id: StringName, qty := 1) -> bool:
	var free := 0
	for e in inventory:
		if e.id == id and String(e.reserved_for) == "":
			free += int(e.qty)
	if free < qty:
		return false
	for i in range(inventory.size() - 1, -1, -1):
		if qty <= 0:
			break
		var e: Dictionary = inventory[i]
		if e.id != id or String(e.reserved_for) != "":
			continue
		var t := mini(int(e.qty), qty)
		e.qty = int(e.qty) - t
		qty -= t
		if int(e.qty) <= 0:
			inventory.remove_at(i)
	inventory_changed.emit()
	return true


## ราคาขายคืนของช่องนี้ (อะไหล่มือสอง 50% · ใหม่ 80% · ของสิ้นเปลือง 0 = ทิ้งได้อย่างเดียว)
func sell_price(index: int) -> int:
	if index < 0 or index >= inventory.size():
		return 0
	var e := inventory[index]
	var it := item_of(e)
	if it == null or it.kind != ItemDef.Kind.PART:
		return 0
	# [0.9.0 ขั้น D] คิดจากราคาที่จ่ายจริงถ้าถูกกว่าราคาตลาด (ของออนไลน์/ลดราคา) — กันซื้อถูกแล้วขายคืนกินส่วนต่าง
	var base := it.price
	var paid := int(e.get("cost", 0))
	if paid > 0:
		base = mini(base, paid)
	return roundi(base * (0.8 if String(e.condition) == "new" else 0.5))


## ขายคืน/ทิ้งของในช่อง index · ของที่จองไว้ขายไม่ได้ · คืนเงินที่ได้ (-1 = ทำไม่ได้)
func sell_back(index: int) -> int:
	if index < 0 or index >= inventory.size() or String(inventory[index].reserved_for) != "":
		return -1
	var got := sell_price(index)
	var sold := item_of(inventory[index])
	var it_name := sold.display_name if sold else ""
	inventory.remove_at(index)
	if got > 0:
		add_money(got, &"sell", it_name)
	inventory_changed.emit()
	return got


## [0.4.0] วันเปิดร้านที่เท่าไรของทั้งเกม (1–48) · ไม่มี TimeSystem = 1
func current_shift() -> int:
	var ts = EventManager.time_system if has_node(^"/root/EventManager") else null
	return int(ts.shift) if ts else 1


## [0.4.0] รอบสต็อกตลาด: ทุก market_restock_days วันเปิดร้าน (2 = วันที่ 4 · 18 ของทุกเดือน)
static func restock_period(shift: int, every: int) -> int:
	return floori((maxi(shift, 1) - 1) / float(maxi(every, 1))) + 1


func _shop_week_now() -> int:
	var e := economy if economy else EconomyConfig.new()
	return restock_period(current_shift(), e.market_restock_days)


## [0.4.0] ข้อความว่าตลาดเติมของเมื่อไร ("วันที่ 18" / "เดือนหน้า")
func restock_text() -> String:
	var e := economy if economy else EconomyConfig.new()
	var s := current_shift()
	var next := restock_period(s, e.market_restock_days) * maxi(e.market_restock_days, 1) + 1
	var per_month: int = TimeSystem.SHIFTS_PER_WEEK * TimeSystem.WEEKS_PER_MONTH
	if (next - 1) / per_month != (s - 1) / per_month:
		return "เดือนหน้า"
	return "วันที่ %d" % TimeSystem.PLAY_DATES[(next - 1) % TimeSystem.PLAY_DATES.size()]


## ร้านเหลือของชิ้นนี้กี่ชิ้นรอบนี้ (-1 = ไม่จำกัด)
func stock_left(item: ItemDef) -> int:
	if item.weekly_stock <= 0:
		return -1
	var w := _shop_week_now()
	if w != shop_week:
		shop_week = w
		shop_bought.clear()
	return maxi(item.weekly_stock - int(shop_bought.get(item.id, 0)), 0)


## [0.3.0] ตั้งจำนวนช่องชั้นวางเครื่อง (ซื้ออัปเกรด/โหลดเซฟ)
func set_shelf_slots(n: int) -> void:
	shelf_slots = n
	shelf_slots_changed.emit(n)


## ซื้อไม่ได้เพราะอะไร ("" = ซื้อได้)
func buy_block_reason(item: ItemDef, qty := 1) -> String:
	if item == null or qty <= 0:
		return "เลือกจำนวนก่อน"
	if item.kind == ItemDef.Kind.UPGRADE and (upgrades.has(item.id) or (item.shelf_slots_to > 0 and shelf_slots >= item.shelf_slots_to) or (item.shelf_slots_to <= 0 and storage_slots >= item.storage_slots_to)):
		return "มีแล้ว"
	if rank() < item.unlock_rank:
		var e := economy if economy else EconomyConfig.new()
		return "ล็อก · ต้องเป็น%s" % e.rank_names[clampi(item.unlock_rank, 0, e.rank_names.size() - 1)]
	var left := stock_left(item)
	if left == 0:
		return "ของหมด (มาใหม่%s)" % restock_text()
	if left > 0 and qty > left:
		return "ร้านเหลือแค่ %d" % left
	if not can_afford(item.price * qty):
		return "เงินไม่พอ"
	if not can_store(item, qty):
		return "คลังเต็ม %d/%d" % [used_slots(), storage_slots]
	return ""


## ซื้อ: หักเงิน + เข้าคลัง · คืนข้อความเหตุผลถ้าซื้อไม่ได้ ("" = สำเร็จ)
func buy(item: ItemDef, qty := 1) -> String:
	var why := buy_block_reason(item, qty)
	if why != "":
		return why
	# ของที่อยู่ถาวร (อัปเกรดคลัง) = ลงทุน ไม่นับเป็นค่าใช้จ่ายของเดือน
	add_money(-item.price * qty, &"invest" if item.kind == ItemDef.Kind.UPGRADE else &"buy", "%s ×%d" % [item.display_name, qty])
	add_item(item, qty, false, true, item.price)
	if item.weekly_stock > 0:
		shop_bought[item.id] = int(shop_bought.get(item.id, 0)) + qty
	if item.kind == ItemDef.Kind.PART:
		parts_arrived.emit()
	return ""

# ---------------------------------------------------------------- [0.4.0] ร้านออนไลน์ (PLAN_0_4_0 ข้อ 4)


## สั่งออนไลน์ไม่ได้เพราะอะไร ("" = สั่งได้) · lines = [[ItemDef, qty], …] (ตะกร้าเดียว จ่ายค่าส่งครั้งเดียว)
func order_block_reason(lines: Array) -> String:
	var e := economy if economy else EconomyConfig.new()
	if lines.is_empty():
		return "ยังไม่ได้เลือกของ"
	var total := e.online_ship_fee
	var slots := 0
	for l in lines:
		var it := l[0] as ItemDef
		var q := int(l[1])
		if it == null or q <= 0:
			return "เลือกจำนวนก่อน"
		if not it.online or it.kind == ItemDef.Kind.UPGRADE:
			return "%s ไม่มีขายออนไลน์" % it.display_name
		if rank() < it.unlock_rank:
			return "ล็อก · ต้องเป็น%s" % e.rank_names[clampi(it.unlock_rank, 0, e.rank_names.size() - 1)]
		total += it.online_cost() * q
		slots += slots_needed(it, q)
	if not can_afford(total):
		return "เงินไม่พอ"
	if slots > free_slots():
		return "คลังเต็ม %d/%d (ของที่สั่งต้องมีช่องรอ)" % [used_slots(), storage_slots]
	return ""


## ราคารวมตะกร้า (รวมค่าส่ง)
func order_total(lines: Array) -> int:
	var e := economy if economy else EconomyConfig.new()
	var total := e.online_ship_fee if not lines.is_empty() else 0
	for l in lines:
		if l[0] is ItemDef:
			total += (l[0] as ItemDef).online_cost() * int(l[1])
	return total


## สั่งออนไลน์: จ่ายทันที (ของ + ค่าส่ง) · จองช่องคลัง · ของมาถึงตอนเปิดร้านอีก online_delay_days วัน · คืนเหตุผลถ้าสั่งไม่ได้ ("" = สำเร็จ)
func order_online(lines: Array) -> String:
	var why := order_block_reason(lines)
	if why != "":
		return why
	var e := economy if economy else EconomyConfig.new()
	var arrive := current_shift() + maxi(e.online_delay_days, 1)
	var names: Array[String] = []
	for l in lines:
		var it := l[0] as ItemDef
		var q := int(l[1])
		pending_orders.append({ "id": it.id, "path": it.resource_path, "qty": q, "cost": it.online_cost(), "slots": slots_needed(it, q), "arrive": arrive })
		names.append("%s ×%d" % [it.display_name, q])
	add_money(-order_total(lines), &"buy", "สั่งออนไลน์: " + ", ".join(names))
	inventory_changed.emit()
	return ""


## ของที่สั่งแล้วยังไม่มา (ไว้โชว์ในแอป/คลัง)
func pending_count(id: StringName) -> int:
	var n := 0
	for o in pending_orders:
		if o.id == id:
			n += int(o.qty)
	return n


## เปิดร้านวัน shift → ของที่ถึงกำหนดเข้าคลัง (ยัดเข้าได้เสมอ เพราะจองช่องไว้แล้ว) · คืนรายการที่มาถึง [{item, qty}]
func deliver_orders(shift: int) -> Array[Dictionary]:
	var got: Array[Dictionary] = []
	var due := pending_orders.filter(func(o: Dictionary) -> bool: return int(o.arrive) <= shift)
	pending_orders = pending_orders.filter(func(o: Dictionary) -> bool: return int(o.arrive) > shift)
	for o in due:
		var it: ItemDef = load(String(o.path)) as ItemDef if ResourceLoader.exists(String(o.path)) else null
		if it == null:
			continue
		add_item(it, int(o.qty), true, false, int(o.cost))
		got.append({ "item": it, "qty": int(o.qty) })
	if not got.is_empty():
		parts_arrived.emit()
	return got

# ---------------------------------------------------------------- [0.4.0] อะไหล่ผูกกับงาน (PLAN_0_4_0 ข้อ 2 · PART_JOB_LINK)


## ของ id นี้ที่ยังไม่ถูกจอง (PART = ชิ้น · SUPPLY = ครั้ง)
func free_count(id: StringName) -> int:
	var n := 0
	for e in inventory:
		if e.id == id and String(e.reserved_for) == "":
			n += int(e.qty)
	return n


## จองอะไหล่ชิ้นแรกที่ว่างตามลำดับ ids (ตัวหลักก่อน แล้วของแทน) ให้งาน key · จองไว้แล้ว = คืน index เดิม · ไม่มี = -1
func reserve(ids: Array, key: String) -> int:
	if key == "":
		return -1
	var have := reserved_index(key)
	if have >= 0:
		return have
	for id in ids:
		for i in inventory.size():
			var e: Dictionary = inventory[i]
			if e.id == StringName(id) and String(e.reserved_for) == "":
				var it := item_of(e)
				if it and it.kind != ItemDef.Kind.PART:
					continue
				e.reserved_for = key
				inventory_changed.emit()
				return i
	return -1


## index ของชิ้นที่จองให้งาน key (-1 = ไม่มี)
func reserved_index(key: String) -> int:
	if key == "":
		return -1
	for i in inventory.size():
		if String(inventory[i].reserved_for) == key:
			return i
	return -1


## ปลดจองทุกชิ้นของงาน key (ยอมแพ้ · ปฏิเสธ · ลูกค้าเอาคืน) → กลับเป็นของว่าง
func release(key: String) -> void:
	if key == "":
		return
	var changed := false
	for e in inventory:
		if String(e.reserved_for) == key:
			e.reserved_for = ""
			changed = true
	if changed:
		inventory_changed.emit()


## ใช้ชิ้นที่จองไว้ (ลบออกจากคลัง) · คืน { item, cost } ของชิ้นที่ใช้ (ว่าง = ไม่มีของจอง)
func consume_reserved(key: String) -> Dictionary:
	var i := reserved_index(key)
	if i < 0:
		return { }
	var e: Dictionary = inventory[i]
	var out := { "item": item_of(e), "cost": int(e.get("cost", 0)) }
	inventory.remove_at(i)
	inventory_changed.emit()
	return out


## ค่าอะไหล่ที่เก็บลูกค้า = ราคาที่ซื้อ × (1 + ค่าบวกตามยศช่างตอนนี้) ปัดขึ้น
func part_charge(cost: int) -> int:
	if cost <= 0:
		return 0
	var e := economy if economy else EconomyConfig.new()
	return ceili(cost * (1.0 + e.part_markup(rank())) - 0.0001)


## ของสิ้นเปลืองพอไหม need = { id: ครั้ง }
func has_supplies(need: Dictionary) -> bool:
	return missing_supplies(need).is_empty()


## ของสิ้นเปลืองที่ขาด { id: ขาดกี่ครั้ง }
func missing_supplies(need: Dictionary) -> Dictionary:
	var miss := { }
	for id in need:
		var lack := int(need[id]) - free_count(StringName(id))
		if lack > 0:
			miss[StringName(id)] = lack
	return miss


## หักของสิ้นเปลือง: หักเท่าที่มี (ชนิดไหนไม่พอ = หักที่เหลือจนหมด) · คืน { id: ขาดกี่ครั้ง } (ว่าง = ครบ)
func use_supplies(need: Dictionary) -> Dictionary:
	var miss := missing_supplies(need)
	for id in need:
		var want := int(need[id]) - int(miss.get(StringName(id), 0))
		if want > 0:
			take_item(StringName(id), want)
	return miss


## มูลค่าของในคลัง (ราคาที่จ่ายจริงของอะไหล่ + ของสิ้นเปลืองคิดตามสัดส่วนครั้งที่เหลือ) — โชว์ในคลัง/สรุปเดือนให้เห็นเงินจม
func inventory_value() -> int:
	var v := 0.0
	for e in inventory:
		var it := item_of(e)
		if it == null:
			continue
		if it.kind == ItemDef.Kind.PART:
			v += int(e.get("cost", 0))
		elif it.kind == ItemDef.Kind.SUPPLY and it.uses > 0:
			v += it.price * int(e.qty) / float(it.uses)
	for o in pending_orders:
		v += int(o.cost) * int(o.qty)
	return roundi(v)

# ---------------------------------------------------------------- ผลงานซ่อม


## เรียกจาก PartMinigame ตอนจบงานลูกค้า · score 0–100 จากหน้า SUMMARY · damaged = ทำของลูกค้าเสีย · fee −1 = ใช้ค่าจาก economy
## level 1–5 = ค่าแรงฐาน/XP ตามระดับ (LEVEL_DESIGN ข้อ 2) · 0 = แบบเดิม (repair_fee ต่อ Part)
## gave_up = ผู้เล่นกด "ยอมแพ้งานนี้" (Task Fail · STORAGE_SHOP_ECO 3.4) — ผลเหมือนไม่ผ่าน + DayLoop เอางานกลับขึ้นกระดานวันถัดไป
func record_repair(part_id: StringName, score: int, damaged := false, fee_override := -1, level := 0, gave_up := false) -> Dictionary:
	var e := economy
	if e == null:
		e = EconomyConfig.new()
	score = clampi(score, 0, 100)
	var grade: Grade
	if damaged or score < e.pass_score:
		grade = Grade.FAIL
	elif score < e.good_score:
		grade = Grade.PASS
	else:
		grade = Grade.GOOD

	var fee: int = fee_override
	if fee < 0:
		fee = e.fee_for_level(level) if level > 0 else e.repair_fee.get(part_id, e.default_fee)
	var xp_mult := e.xp_mult_for_level(level) if level > 0 else 1.0
	var delta := 0
	var sat := 0
	var gained := 0
	match grade:
		Grade.GOOD:
			delta = fee + (e.tip_three_star if score >= e.three_star_score else 0)
			sat = e.satisfaction_good
			gained = e.xp_base
		Grade.PASS:
			delta = fee
			sat = e.satisfaction_pass
			gained = roundi(e.xp_base * e.xp_mult_pass)
		Grade.FAIL:
			delta = -int(e.damage_penalty.get(part_id, e.default_penalty)) if damaged else 0
			sat = e.satisfaction_fail
			gained = roundi(e.xp_base * e.xp_mult_fail)

	gained = roundi(gained * xp_mult)
	# [0.2.0-C] จดแยกหมวด: ค่าแรง · ทิป · ชดใช้ของเสีย (รวมกันเท่ากับ delta เดิม)
	var tip := e.tip_three_star if grade == Grade.GOOD and score >= e.three_star_score else 0
	var label := String(part_id)
	var hold := hold_next_payment
	hold_next_payment = false
	if not hold:
		if delta > 0:
			add_money(delta - tip, &"fee", label)
			add_money(tip, &"tip", label)
		elif delta < 0:
			add_money(delta, &"damage", label)
		satisfaction_history.append(sat)
	add_xp(gained)
	var rep := 0
	match grade:
		Grade.GOOD:
			rep = e.rep_three_star if score >= e.three_star_score else e.rep_good
		Grade.FAIL:
			rep = e.rep_damaged if damaged else e.rep_fail
			if damaged and has_perk(&"careful"): # [ขั้น I] ตาถึง
				rep = int(rep / 2.0)
	if not hold:
		add_reputation(rep)
	if level > 0 and grade == Grade.GOOD:
		level_stars[level] = level_stars.get(level, 0) + 1
		if score >= e.three_star_score:
			level_three_stars[level] = int(level_three_stars.get(level, 0)) + 1
	if grade != Grade.FAIL:
		part_clears[part_id] = part_clears.get(part_id, 0) + 1

	var result := {
		"part_id": part_id,
		"score": score,
		"grade": grade,
		"money": delta,
		"satisfaction": sat,
		"xp": gained,
		"damaged": damaged,
		"level": level,
		"reputation": rep,
		"gave_up": gave_up,
	}
	if hold:
		# [0.3.0] งานบนชั้น: เก็บยอดไว้จ่ายตอนลูกค้ามารับ (pay_pickup) · ผลที่ส่งออกไปยังไม่มีเงิน/ชื่อเสียง
		result["held"] = true
		result["money_due"] = delta
		result["tip_due"] = tip
		result["rep_due"] = rep
		result["money"] = 0
		result["reputation"] = 0
	repair_recorded.emit(result)
	# [9 ต.ค.] เวลาไม่เดินที่นี่แล้ว — DayLoop เดินนาฬิกาตามช่องของงาน (LEVEL_DESIGN 4.2)
	return result


## [0.3.0 ขั้น D] ลูกค้ามารับเครื่องจากชั้นวาง → จ่ายยอดที่เก็บไว้ (record_repair แบบ hold)
## mult = ค่าแรงคูณจากวันนัด/ความช้า (RepairShelf.pickup) — คูณเฉพาะค่าแรง+ทิป ไม่คูณค่าชดใช้ของเสีย
## sat_delta = ทันนัด +/ช้า − บวกกับความพอใจของงาน · คืน { money, reputation, satisfaction }
func pay_pickup(held: Dictionary, mult := 1.0, sat_delta := 0, label := "") -> Dictionary:
	var due := int(held.get("money_due", held.get("money", 0)))
	var tip := int(held.get("tip_due", 0))
	var lbl := label if label != "" else String(held.get("part_id", ""))
	var paid := 0
	if due > 0:
		var fee := roundi((due - tip) * mult)
		var t := roundi(tip * mult)
		add_money(fee, &"fee", lbl)
		add_money(t, &"tip", lbl)
		paid = fee + t
	elif due < 0:
		add_money(due, &"damage", lbl)
		paid = due
	var sat := clampi(int(held.get("satisfaction", 0)) + sat_delta, 0, 100)
	satisfaction_history.append(sat)
	var rep := int(held.get("rep_due", held.get("reputation", 0)))
	add_reputation(rep)
	return { "money": paid, "reputation": rep, "satisfaction": sat }


func average_satisfaction() -> float:
	if satisfaction_history.is_empty():
		return 100.0
	var sum := 0
	for s in satisfaction_history:
		sum += s
	return float(sum) / satisfaction_history.size()


func has_cleared(part_id: StringName) -> bool:
	return part_clears.get(part_id, 0) > 0

# ---------------------------------------------------------------- ลูปรอบ / ฉากจบ


## [0.8.0] ทางแยกบท 11 (ตอบอีกครั้งได้ในบท 12) → story_flags["ch11_choice"] · เปิดให้ทุกคน ไม่ผูกยศ
const PATH_CHOICES := {
	"อยู่ที่หมู่บ้านต่อ": "stay",
	"ทำงานกับบริษัทแบบออนไลน์จากร้าน": "coworking",
	"กลับไปทำงานในเมือง": "city",
}
## [0.8.0] ตัวเลือกในบทต้นเดือน → ความสนิทเล็กน้อย (ไม่มีคำตอบผิด)
const CHAPTER_CHOICE_AFFINITY := {
	"ชวนลูกหลานพาพ่อแม่มาเรียนใช้เครื่อง": { &"amnuay": 2 },
	"ตั้งป้ายรับซ่อมช่วงสงกรานต์": { &"min": 2 },
	"ทำโฆษณาบนเพจชุมชน": { &"min": 2 },
	"ถามผู้ใหญ่บ้านเรื่องงานบุญเพิ่ม": { &"headman": 2 },
	"เริ่มจากเรื่องที่ผู้สูงอายุอยากทำ": { &"headman": 2 },
	"เริ่มจากพื้นฐานทีละขั้น": { &"headman": 2 },
	"เขียนหนังสือถึง อบต. เรื่องไฟดับบ่อย": { &"min": 2 },
	"ชวนเด็ก ๆ มาทำการบ้านที่ศาลาตอนกลางวัน": { &"bew": 2, &"fai": 2 },
	"ชวนชมรมมาดูตอนซ่อมที่ร้าน": { &"phum": 3, &"oat": 3 },
	"ให้ชมรมลองวางแผนสเปกตามงบก่อน": { &"fern": 3, &"namwan": 3 },
	"ซ้อมให้ถูกขั้นตอนก่อนค่อยเร็ว": { &"fern": 2, &"namwan": 2 },
	"ซ้อมจับเวลาให้ชินกับความกดดัน": { &"oat": 2, &"phum": 2 },
}


## ครบรอบ week → เปิดบทของรอบถัดไป · DayLoop เรียกหลังการ์ดสรุปรอบ
func play_week_chapter(week: int) -> bool:
	if week < 1 or week >= CHAPTERS.size():
		return false
	var ch := chapter_story(week + 1)
	if not _play_story(ch):
		return false
	if not DialogScene.on_dialog_finish.is_connected(_on_chapter_done):
		DialogScene.on_dialog_finish.connect(_on_chapter_done.bind(week + 1), CONNECT_ONE_SHOT)
	return true


## [0.8.0] บทต้นเดือนของบท n (1–12) · บทที่ขึ้นกับยศใช้ low_file เมื่อยศยังไม่ถึง
func chapter_story(n: int) -> Dictionary:
	var ch: Dictionary = (CHAPTERS[clampi(n, 1, CHAPTERS.size()) - 1] as Dictionary).duplicate()
	if ch.has("low_file") and rank() < int(ch.get("min_rank", 0)):
		ch["file"] = ch["low_file"]
	return ch


## [0.8.0] จบบทต้นเดือน → จำตัวเลือก (ch<n>_pick) · ทางแยก · ความสนิท
func _on_chapter_done(n: int) -> void:
	chapter_choice(n, DialogScene.last_choice)


func chapter_choice(n: int, choice: String) -> void:
	if choice == "":
		return
	story_flags["ch%d_pick" % n] = choice
	if PATH_CHOICES.has(choice):
		story_flags["ch11_choice"] = PATH_CHOICES[choice]
	var aff: Dictionary = CHAPTER_CHOICE_AFFINITY.get(choice, { })
	for id in aff:
		if has_affinity(id):
			add_affinity(id, int(aff[id]), &"chapter")


## ครบ 12 รอบ → ตัดสินฉากจบ → บทฉากจบที่ประกอบจากการเล่นจริง (EndingBook) · DayLoop เรียกหลังการ์ดสรุปรอบ 12
func finish_game() -> void:
	ending = decide_ending()
	EndingBook.log_ending()
	var path := EndingBook.build(ending)
	_play_story({ "title": EndingBook.title(ending), "file": path, "bg": EndingBook.bg(ending) })
	game_finished.emit(ending)


## [0.8.0] ร้านปิด (พลาดเป้า 3 เดือนติด / ค้างบิล 2 เดือนติด) = failure · ที่เหลือตามที่ผู้เล่นเลือกในบท 11–12 (ไม่เลือก = อยู่ต่อ)
func decide_ending() -> StringName:
	if shop_closed:
		return &"failure"
	match String(story_flags.get("ch11_choice", "stay")):
		"city":
			return &"city"
		"coworking":
			return &"coworking"
	return &"stay"


func _play_story(ch: Dictionary) -> bool:
	var file: String = ch.get("file", "")
	var bg: String = ch.get("bg", "")
	if not DialogUtil.has_lines(file):
		push_warning("ไม่พบไฟล์บท หรือบทว่าง %s" % file)
		return false
	if bg != "" and not ResourceLoader.exists(bg):
		bg = ""
	# [0.8.0] ขึ้นรูปไว้ก่อนแค่ 2 คนแรก (บทยาวมีคนพูด 5–8 คน เดิมขึ้นซ้อนกัน 4 รูป) · คนที่เหลือขึ้นตอนพูด (DialogScene._show_speaker)
	return EventManager.play_story_dialog(ch.get("title", ""), file, bg, DialogUtil.speakers_in(file).slice(0, 2))


## (เก่า) ใช้ DialogUtil.speakers_in แทน — เก็บไว้ให้โค้ดเดิมเรียกได้
func speakers_in(path: String) -> Array[String]:
	return DialogUtil.speakers_in(path)
