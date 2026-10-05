extends Node
## GameState (autoload) — state ของลูปเกมที่ต้องอยู่ข้ามซีน: เงิน · ความพอใจ · XP · Part ที่ผ่านแล้ว · ธงเนื้อเรื่อง
## + กาวของลูปรอบ: ครบ 7 วัน → เปิดบท Chapter ของรอบถัดไป · ครบ 12 รอบ → Epilogue + ฉากจบ
## ดู Docs/GAME_LOOP.md §3 §4 §6 §7 · [Claude 5 ต.ค. 2569]

signal money_changed(money: int, delta: int)
## result: { part_id, score, grade, money, satisfaction, xp, damaged }
signal repair_recorded(result: Dictionary)
## ending: &"stay" · &"city" · &"coworking" · &"failure"
signal game_finished(ending: StringName)

enum Grade { GOOD, PASS, FAIL }

const ECONOMY_PATH := "res://Resources/Balance/economy.tres"

## บทของแต่ละรอบ (index 0 = รอบ 1) · รอบ 1 เล่นผ่านเควสต์หลักแล้ว (main.tres) จึงไม่เปิดซ้ำ
const CHAPTERS := [
	{ "title": "กลับบ้าน", "file": "res://Assets/Dialog/Chapter1ReturnHome.txt", "bg": "" },
	{ "title": "คอมเก่าของขม", "file": "res://Assets/Dialog/Chapter2Rest.txt", "bg": "res://Assets/Background/Chapter2_bg.jpg" },
	{ "title": "จัดบ้านเป็นร้าน", "file": "res://Assets/Dialog/Chapter3DecorateHouse.txt", "bg": "res://Assets/Background/bg_shop_empty.jpg" },
	{ "title": "เปิดร้านวันแรก", "file": "res://Assets/Dialog/Chapter4Start.txt", "bg": "res://Assets/Background/bg_shop_open.jpg" },
	{ "title": "ร้านเงียบ", "file": "res://Assets/Dialog/Chapter5Quiet.txt", "bg": "res://Assets/Background/bg_shop_quiet.jpg" },
	{ "title": "ร้านเริ่มคึกคัก", "file": "res://Assets/Dialog/Chapter6Happy.txt", "bg": "res://Assets/Background/bg_shop_busy.jpg" },
	{ "title": "สอนคอมพื้นฐาน", "file": "res://Assets/Dialog/Chapter7Teaching.txt", "bg": "res://Assets/Background/bg_shop_open.jpg" },
	{ "title": "ไฟดับ", "file": "res://Assets/Dialog/Chapter8Problem.txt", "bg": "res://Assets/Background/HomeBG.jpg" },
	{ "title": "สอนที่โรงเรียน", "file": "res://Assets/Dialog/Chapter9School.txt", "bg": "res://Assets/Background/bg_school_room.jpg" },
	{ "title": "งานหมู่บ้าน", "file": "res://Assets/Dialog/Chapter10Village.txt", "bg": "res://Assets/Background/bg_village_day.jpg" },
	{ "title": "ทางแยก", "file": "res://Assets/Dialog/Chapter11Path.txt", "bg": "res://Assets/Background/bg_path_sunset.jpg" },
	{ "title": "ครบหนึ่งปี", "file": "res://Assets/Dialog/Chapter12Year.txt", "bg": "res://Assets/Background/bg_year_after.jpg" },
]
const EPILOGUE := { "title": "บทส่งท้าย", "file": "res://Assets/Dialog/Epilogue.txt", "bg": "res://Assets/Background/bg_year_after.jpg" }

var economy: EconomyConfig
var money := 0
## ความพอใจของทุกงานซ่อม (0–100)
var satisfaction_history: Array[int] = []
var xp := 0
## part_id → จำนวนครั้งที่ซ่อมผ่าน (ใช้ปลดล็อก / ข้ามบทสอนครั้งถัดไป)
var part_clears: Dictionary[StringName, int] = {}
## ธงเนื้อเรื่อง เช่น &"ch11_choice": &"stay" | &"city" | &"coworking"
var story_flags: Dictionary = {}
var ending: StringName = &""


func _ready() -> void:
	economy = load(ECONOMY_PATH) as EconomyConfig
	if economy == null:
		push_warning("ไม่พบ %s ใช้ค่าเริ่มต้น" % ECONOMY_PATH)
		economy = EconomyConfig.new()
	reset()
	# EventManager เป็น autoload ก่อนหน้า · รอให้ทุก autoload พร้อมก่อนค่อยผูกสัญญาณ
	_connect_time.call_deferred()


func _connect_time() -> void:
	var ts: TimeSystem = EventManager.time_system
	if ts == null:
		push_error("GameState: ไม่พบ EventManager.time_system")
		return
	ts.week_ended.connect(_on_week_ended)
	ts.all_weeks_ended.connect(_on_all_weeks_ended)


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

## เรียกจาก PartMinigame ตอนจบมินิเกม · score 0–100 จากหน้า SUMMARY · damaged = ทำของลูกค้าเสีย
func record_repair(part_id: StringName, score: int, damaged := false) -> Dictionary:
	var e := economy
	var grade: Grade
	if damaged or score < e.pass_score:
		grade = Grade.FAIL
	elif score < e.good_score:
		grade = Grade.PASS
	else:
		grade = Grade.GOOD

	var fee: int = e.repair_fee.get(part_id, e.default_fee)
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
		"part_id": part_id, "score": score, "grade": grade, "money": delta,
		"satisfaction": sat, "xp": gained, "damaged": damaged,
	}
	repair_recorded.emit(result)
	_advance_after_repair()
	return result


## งานซ่อม 1 งานกินเวลา 1 ช่วง (เช้า → เที่ยง → เย็น) · ไม่ข้ามวันเอง — จบวันต้องนอน
func _advance_after_repair() -> void:
	var ts: TimeSystem = EventManager.time_system
	if ts and ts.cur_period != TimeSystem.TIME.EVENING:
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

func _on_week_ended(week: int) -> void:
	# ครบรอบ week → เปิดบทของรอบถัดไป (รอบ 12 จบไปต่อที่ _on_all_weeks_ended)
	if week < CHAPTERS.size():
		_play_story(CHAPTERS[week])


func _on_all_weeks_ended() -> void:
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


func _play_story(ch: Dictionary) -> void:
	if not FileAccess.file_exists(ch["file"]):
		push_warning("ไม่พบไฟล์บท %s" % ch["file"])
		return
	var bg: String = ch["bg"]
	if bg != "" and not ResourceLoader.exists(bg):
		bg = ""
	EventManager.play_story_dialog(ch["title"], ch["file"], bg, speakers_in(ch["file"]))


## ดึงชื่อคนพูดทุกคนจากไฟล์บท (ช่องแรกก่อน ",") — DialogScene ข้ามชื่อที่ไม่มีใน _CharacterMap ให้เอง
static func speakers_in(path: String) -> Array[String]:
	var out: Array[String] = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#") or line.begins_with("Choice:") or line.ends_with(":"):
			continue
		var comma := line.find(",")
		if comma <= 0:
			continue
		var who := line.substr(0, comma).strip_edges().split(":")[0]
		if who != "" and not out.has(who):
			out.append(who)
	return out
