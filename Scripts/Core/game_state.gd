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

## บทของแต่ละรอบ (index 0 = รอบ 1) · รอบ 1 เล่นผ่านเควสต์หลักแล้ว (main.tres) จึงไม่เปิดซ้ำ
const CHAPTERS := [
	{ "title": "กลับบ้าน", "file": "res://Assets/Dialog/Chapter1ReturnHome.txt", "bg": "" },
	{
		"title": "คอมเก่าของขม",
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
		"title": "สอนคอมพื้นฐาน",
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


func _ready() -> void:
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
	money_changed.emit(money, 0)
	reputation_changed.emit(reputation, 0)

# ---------------------------------------------------------------- เงิน


func add_money(delta: int) -> void:
	if delta == 0:
		return
	money += delta
	if money > MONEY_CAP:
		village_fund += money - MONEY_CAP
		delta -= money - MONEY_CAP
		money = MONEY_CAP
	money_changed.emit(money, delta)


func add_reputation(delta: int) -> void:
	if delta == 0:
		return
	var before := reputation
	reputation = clampi(reputation + delta, 0, 100)
	reputation_changed.emit(reputation, reputation - before)


## จ่ายบิลรายเดือน (TimeSystem.month_ended) · เงินไม่พอ = จ่ายเท่าที่มี ส่วนที่เหลือเป็นหนี้
func pay_month_bill(month: int) -> Dictionary:
	var e := economy if economy else EconomyConfig.new()
	var bill := {
		"month": month,
		"power": e.month_value(e.bill_power, month),
		"grandma": e.bill_grandma,
		"internet": e.bill_internet,
	}
	bill["total"] = int(bill["power"]) + int(bill["grandma"]) + int(bill["internet"]) + debt
	var paid := mini(maxi(money, 0), int(bill["total"]))
	add_money(-paid)
	debt = int(bill["total"]) - paid
	bill["paid"] = paid
	bill["debt"] = debt
	bill_paid.emit(bill)
	return bill


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

# ---------------------------------------------------------------- ผลงานซ่อม


## เรียกจาก PartMinigame ตอนจบงานลูกค้า · score 0–100 จากหน้า SUMMARY · damaged = ทำของลูกค้าเสีย · fee −1 = ใช้ค่าจาก economy
## level 1–5 = ค่าแรงฐาน/XP ตามระดับ (LEVEL_DESIGN ข้อ 2) · 0 = แบบเดิม (repair_fee ต่อ Part)
func record_repair(part_id: StringName, score: int, damaged := false, fee_override := -1, level := 0) -> Dictionary:
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
	add_money(delta)
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
	if average_satisfaction() < 40.0 or money < 0 or debt > 0:
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
