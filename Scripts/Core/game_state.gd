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
	money_changed.emit(money, 0)

# ---------------------------------------------------------------- เงิน


func add_money(delta: int) -> void:
	if delta == 0:
		return
	money += delta
	money_changed.emit(money, delta)


func can_afford(cost: int) -> bool:
	return money >= cost

# ---------------------------------------------------------------- ผลงานซ่อม


## เรียกจาก PartMinigame ตอนจบงานลูกค้า · score 0–100 จากหน้า SUMMARY · damaged = ทำของลูกค้าเสีย · fee −1 = ใช้ค่าจาก economy
func record_repair(part_id: StringName, score: int, damaged := false, fee_override := -1) -> Dictionary:
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

	var fee: int = fee_override if fee_override >= 0 else e.repair_fee.get(part_id, e.default_fee)
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

	add_money(delta)
	satisfaction_history.append(sat)
	xp += gained
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
	}
	repair_recorded.emit(result)
	_advance_after_repair()
	return result


## งานซ่อม 1 งานกินเวลา 1 ช่วง (เช้า → เที่ยง → เย็น) · ไม่ข้ามวันเอง — จบวันต้องนอน
func _advance_after_repair() -> void:
	var ts: TimeSystem = EventManager.time_system
	if ts and not ts.finished and ts.cur_period != TimeSystem.TIME.EVENING:
		EventManager.next_period.emit()


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
	if average_satisfaction() < 40.0 or money < 0:
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
