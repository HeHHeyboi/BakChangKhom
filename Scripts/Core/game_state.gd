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
		"bg": "res://Assets/Background/bg_shop_open.jpg",
	},
	{ "title": "ไฟดับ", "file": "res://Assets/Dialog/Chapter8Problem.txt", "bg": "res://Assets/Background/HomeBG.jpg" },
	{
		"title": "สอนที่โรงเรียน",
		"file": "res://Assets/Dialog/Chapter9School.txt",
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

# ---- คลังของ (Docs/STORAGE_SHOP_ECO.md ข้อ 1) [Claude 13 ต.ค. 2569]
signal inventory_changed
## [13 ต.ค.] ได้ของเข้าคลัง (ซื้อ · ได้จากเนื้อเรื่อง/บทสอน · ชิ้นเก่าจากงานซ่อม) → Storage โชว์ป้าย "ได้ … เข้าคลัง"
signal item_received(item: ItemDef, qty: int)
## ข้อความเด้งรวมหลายชิ้น (เช่น ชุดเริ่มต้น) — Storage โชว์ข้อความนี้แทนป้ายทีละชิ้น
signal inventory_note(text: String)

## [13 ต.ค.] ของติดตัวหลังจบบทสอนประกอบคอม (เล่นจบหรือกดข้ามก็ได้) — ให้ครั้งเดียวต่อเกม (story_flags.starter_kit)
## { id ใน Resources/Shop/: จำนวน } · แก้รายการได้ที่นี่
const STARTER_KIT := {
	&"ram_ddr3_4gb_used": 1, # แรมจากคอมเครื่องเก่าของขม
	&"cable_sata": 1,
	&"ipa90": 1,
	&"cable_tie": 1,
}
## เควสต์หลักขั้นที่ (index) ถัดจากบทสอนประกอบคอม — ไปถึงขั้นนี้แล้ว = ได้ชุดเริ่มต้น
const STARTER_KIT_AFTER_STEP := 3
const STORAGE_START := 8
const SUPPLY_STACK_MAX := 99
## ช่องคลังทั้งหมด (อัปเกรดด้วย ItemDef UPGRADE)
var storage_slots := STORAGE_START
## ของในคลัง 1 รายการ = 1 ช่อง: { id, path, qty, condition, reserved_for }
##   PART qty = 1 เสมอ · SUPPLY qty = จำนวนครั้งที่เหลือ (≤ SUPPLY_STACK_MAX)
var inventory: Array[Dictionary] = []
## ร้านขายไปแล้วกี่ชิ้นในสัปดาห์ shop_week (สต็อกร้าน)
var shop_bought: Dictionary = { }
var shop_week := 0
## อัปเกรดที่ซื้อแล้ว (id → true)
var upgrades: Dictionary = { }


func _ready() -> void:
	if has_node(^"/root/EventManager"):
		EventManager.sendUpdatedEvent.connect(_on_quest_updated)
	economy = load(ECONOMY_PATH) as EconomyConfig
	if economy == null:
		push_warning("ไม่พบ %s ใช้ค่าเริ่มต้น" % ECONOMY_PATH)
		economy = EconomyConfig.new()
	reset()


func reset() -> void:
	money = economy.start_money
	satisfaction_history.clear()
	xp = 0
	part_clears.clear()
	story_flags.clear()
	ending = &""
	reputation = economy.reputation_start
	level_stars.clear()
	debt = 0
	village_fund = 0
	storage_slots = STORAGE_START
	inventory.clear()
	shop_bought.clear()
	shop_week = 0
	upgrades.clear()
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
	&"tip": "ทิป",
	&"sell": "ขายของคืน",
	&"damage": "ชดใช้ของเสียหาย",
	&"bill": "บิลรายเดือน",
	&"ot_power": "ค่าไฟล่วงเวลา",
	&"buy": "ซื้อของ",
	&"invest": "ลงทุน",
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


## [0.2.0] เดือนของบท (4 บท = 1 เดือน)
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
		"power": e.month_value(e.power_base, month) + e.power_per_slot * maxi(slots_worked, 0),
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
	if rep.strike:
		missed_months += 1
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


## ยศช่าง 0–4 จาก XP
func rank() -> int:
	var e := economy if economy else EconomyConfig.new()
	var r := 0
	for i in e.rank_xp.size():
		if xp >= e.rank_xp[i]:
			r = i
	return r


## เพิ่ม XP · ข้ามเกณฑ์ยศ → rank_up
func add_xp(gained: int) -> void:
	if gained == 0:
		return
	var before := rank()
	xp = maxi(xp + gained, 0)
	xp_changed.emit(xp, gained)
	var after := rank()
	if after > before:
		rank_up.emit(after, rank_name())


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
	return level_stars.get(level - 1, 0) >= e.unlock_stars_needed


func can_afford(cost: int) -> bool:
	return money >= cost

# ---------------------------------------------------------------- คลังของ + ซื้อของ


func used_slots() -> int:
	return inventory.size()


func free_slots() -> int:
	return maxi(storage_slots - inventory.size(), 0)


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
func add_item(item: ItemDef, qty := 1, force := false, notify := true) -> bool:
	if item == null or (not force and not can_store(item, qty)):
		return false
	match item.kind:
		ItemDef.Kind.UPGRADE:
			upgrades[item.id] = true
			storage_slots = maxi(storage_slots, item.storage_slots_to)
		ItemDef.Kind.PART:
			for i in qty:
				inventory.append({ "id": item.id, "path": item.resource_path, "qty": 1, "condition": item.condition, "reserved_for": "" })
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
				inventory.append({ "id": item.id, "path": item.resource_path, "qty": put, "condition": "", "reserved_for": "" })
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
	return roundi(it.price * (0.8 if String(e.condition) == "new" else 0.5))


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


func _shop_week_now() -> int:
	var ts = EventManager.time_system if has_node(^"/root/EventManager") else null
	return ts.week() if ts else 1


## ร้านเหลือของชิ้นนี้กี่ชิ้นสัปดาห์นี้ (-1 = ไม่จำกัด)
func stock_left(item: ItemDef) -> int:
	if item.weekly_stock <= 0:
		return -1
	var w := _shop_week_now()
	if w != shop_week:
		shop_week = w
		shop_bought.clear()
	return maxi(item.weekly_stock - int(shop_bought.get(item.id, 0)), 0)


## ซื้อไม่ได้เพราะอะไร ("" = ซื้อได้)
func buy_block_reason(item: ItemDef, qty := 1) -> String:
	if item == null or qty <= 0:
		return "เลือกจำนวนก่อน"
	if item.kind == ItemDef.Kind.UPGRADE and (upgrades.has(item.id) or storage_slots >= item.storage_slots_to):
		return "มีแล้ว"
	if rank() < item.unlock_rank:
		var e := economy if economy else EconomyConfig.new()
		return "ล็อก · ต้องเป็น%s" % e.rank_names[clampi(item.unlock_rank, 0, e.rank_names.size() - 1)]
	var left := stock_left(item)
	if left == 0:
		return "ของหมด (มาใหม่สัปดาห์หน้า)"
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
	add_item(item, qty)
	if item.weekly_stock > 0:
		shop_bought[item.id] = int(shop_bought.get(item.id, 0)) + qty
	return ""

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
	add_reputation(rep)
	if level > 0 and grade == Grade.GOOD:
		level_stars[level] = level_stars.get(level, 0) + 1
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
	repair_recorded.emit(result)
	# [9 ต.ค.] เวลาไม่เดินที่นี่แล้ว — DayLoop เดินนาฬิกาตามช่องของงาน (LEVEL_DESIGN 4.2)
	return result


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


## ครบรอบ week → เปิดบทของรอบถัดไป · DayLoop เรียกหลังการ์ดสรุปรอบ
func play_week_chapter(week: int) -> bool:
	if week < 1 or week >= CHAPTERS.size():
		return false
	return _play_story(CHAPTERS[week])


## ครบ 12 รอบ → ตัดสินฉากจบ + Epilogue · DayLoop เรียกหลังการ์ดสรุปรอบ 12
func finish_game() -> void:
	ending = decide_ending()
	_play_story(EPILOGUE)
	game_finished.emit(ending)


## ฉากจบตาม GAME_LOOP §6 · ยศช่างยังไม่มี จึงใช้ XP แทนชั่วคราว
func decide_ending() -> StringName:
	if shop_closed or average_satisfaction() < 40.0 or money < 0 or debt > 0:
		return &"failure"
	match story_flags.get(&"ch11_choice", &"stay"):
		&"city":
			return &"city"
		&"coworking":
			return &"coworking"
	return &"stay" if average_satisfaction() >= 70.0 else &"failure"


func _play_story(ch: Dictionary) -> bool:
	var file: String = ch.get("file", "")
	var bg: String = ch.get("bg", "")
	if not DialogUtil.has_lines(file):
		push_warning("ไม่พบไฟล์บท หรือบทว่าง %s" % file)
		return false
	if bg != "" and not ResourceLoader.exists(bg):
		bg = ""
	return EventManager.play_story_dialog(ch.get("title", ""), file, bg, DialogUtil.speakers_in(file))


## (เก่า) ใช้ DialogUtil.speakers_in แทน — เก็บไว้ให้โค้ดเดิมเรียกได้
func speakers_in(path: String) -> Array[String]:
	return DialogUtil.speakers_in(path)
