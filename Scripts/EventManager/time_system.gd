class_name TimeSystem extends CanvasLayer
## เวลาในเกม — กะ · สัปดาห์ · เดือน ตาม Docs/LEVEL_DESIGN.md ข้อ 4 · 7.1
## 1 กะ = 08:30–18:30 (ช่อง 30 นาที · ทำงานได้ 16 ช่อง) · พัก 12:00–13:00 และ 15:30–16:00
## [15 ต.ค. 2569 · 0.2.0 ตัดสินใหม่] 1 บท (Chapter) = 1 สัปดาห์ · **ร้านเปิด 3 วัน: จ. · พ. · ศ.** (อ. · พฤ. ขมไปช่วยยาย/ซื้อของ) · 4 สัปดาห์ = 1 เดือน
##   12 บท = 12 สัปดาห์ = ม.ค.–มี.ค. 2570 = 36 วันเล่น · ปฏิทินจริงปี 2570 (ค.ศ. 2027): เริ่ม จ. 4 ม.ค. → ทุกเดือนลงตัว 4 สัปดาห์พอดี
##   จ. → พ. ข้าม 2 วัน · ศุกร์ → จันทร์ ข้าม 3 วัน · บิล/เป้ากำไร = รายเดือน (ทุก 4 บท) · ดู Docs/ROADMAP_1_0_0.md ข้อ 1
##   (เดิมเปิด จ.–ศ. 5 วัน = 60 วันเล่น → ทีมเห็นว่านานไป: เล่นทั้งเกม 12–20 ชม. · กว่าจะเห็นสรุปเดือนแรก 4–7 ชม.)
## นาฬิกาเดินตามการกระทำเท่านั้น (advance_minutes) ไม่เดินเอง
## [Claude 9 ต.ค. 2569] เขียนใหม่จาก "วันที่ 1, 2, 3…" — commit 3a1375b ลบ week_ended ไป ตอนนี้กลับมาในรูปกะ/สัปดาห์

const SLOT_MIN := 30
const OPEN := 8 * 60 + 30 # 08:30 เปิดร้าน (08:30–09:00 = วางแผน ไม่นับเวลางาน)
const WORK_START := 9 * 60 # 09:00
const CLOSE := 18 * 60 + 30 # 18:30
const OT_LIMIT := 19 * 60 + 30 # 19:30 (ล่วงเวลาได้ ≤ 2 ช่อง)
## [เริ่ม, จบ, ชื่อ] — ช่วงพัก ไม่นับเวลางาน · งานที่ทำค้างข้ามพักต่อหลังพักเอง
const BREAKS := [[12 * 60, 13 * 60, &"lunch"], [15 * 60 + 30, 16 * 60, &"afternoon"]]
const SHIFTS_PER_WEEK := 3
## [0.2.0] วันที่ร้านเปิดในสัปดาห์ (0 = จ. … 4 = ศ.) · จำนวนต้องเท่ากับ SHIFTS_PER_WEEK
const OPEN_WEEKDAYS := [0, 2, 4]
const WEEKS_PER_MONTH := 4
const MONTHS := 3
const TOTAL_SHIFTS := SHIFTS_PER_WEEK * WEEKS_PER_MONTH * MONTHS # 36
const WORK_SLOTS_PER_SHIFT := 16
## [0.2.0] ปฏิทินจริง พ.ศ. 2570 (ค.ศ. 2027 ไม่ใช่ปีอธิกสุรทิน) · วันแรกของเกม = จันทร์ 4 ม.ค. (วันที่ 4 ของปี)
const YEAR_BE := 2570
const START_DAY_OF_YEAR := 4
const MONTH_DAYS := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const WEEKDAY_SHORT := ["จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส.", "อา."]
const WEEKDAY_FULL := ["จันทร์", "อังคาร", "พุธ", "พฤหัสบดี", "ศุกร์", "เสาร์", "อาทิตย์"]

enum TIME {
	MORNING, # ช่วงเช้า 09:00
	NOON, # ช่วงบ่าย 13:00
	EVENING, # ช่วงเย็น 16:00
}
const PERIOD_START := { TIME.MORNING: 9 * 60, TIME.NOON: 13 * 60, TIME.EVENING: 16 * 60 }
const PERIOD_NAME := { TIME.MORNING: "ช่วงเช้า", TIME.NOON: "ช่วงบ่าย", TIME.EVENING: "ช่วงเย็น" }
const MONTH_NAME := ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."] # เกมเริ่มเดือนมกราคม · 4 บท (สัปดาห์) = 1 เดือน

## ช่วงเวลาเปลี่ยน (เช้า → บ่าย → เย็น)
signal period_changed(period: TIME)
## นาฬิกาเปลี่ยน
signal clock_changed(minute: int)
## เริ่มกะใหม่ (หลังปิดร้านกะก่อน) · month = week = บท 1–12 · shift_in_week = วันที่ 1–5 ของบท
signal shift_started(month: int, week: int, shift_in_week: int)
## เดินเวลาข้ามช่วงพัก · kind = &"lunch" / &"afternoon"
signal break_started(kind: StringName)
## นาฬิกาถึง 18:30
signal shift_closed
## ครบ 3 กะ (จ. พ. ศ.) (ยิงก่อน shift_started ของสัปดาห์ถัดไป) · DayLoop ใช้ทำสรุปสัปดาห์ + Chapter
signal week_ended(week: int)
## ครบ 4 บท (1 เดือน) · ยิงต่อจาก week_ended · DayLoop จ่ายบิลรายเดือน (GameState.pay_month_bill)
signal month_ended(month: int)
## ครบ 60 กะ → ฉากจบ
signal game_ended

@onready var timeText = $PanelContainer/HBoxContainer/Time as Label ## [Claude 10 ต.ค. 2569] เดิม RichTextLabel — engine แจ้ง "Rect2i size is negative" กับข้อความไทย
@onready var dateText = $PanelContainer/HBoxContainer/Date as Label

## กะที่เท่าไรของทั้งเกม 1–60 (ไม่โชว์ผู้เล่น)
var shift := 1
## [Claude 10 ต.ค. 2569] true = HUD/การ์ดบอกเวลาเป็นนาฬิกา (แบบเดิม) · false = บอกเป็น "เทิร์น" แบบ Volcano Princess
## 1 เทิร์น = 1 ช่อง 30 นาที (SLOT_MIN) · วันหนึ่งมี 16 เทิร์น · 1 บท = 1 สัปดาห์ (เปิดร้าน จ. พ. ศ.)
@export var show_clock := false

var current_minute := OPEN
var cur_period: TIME = TIME.MORNING
var finished := false
## อนุญาตให้เดินเลย 18:30 ในกะนี้ (DayLoop เปิดตอนรับงานล่วงเวลา)
var overtime := false
## นาทีที่ทำงานไปแล้วในเดือนนี้ (แถบ ชม.งาน x/160)
var worked_minutes_month := 0
var _closed_emitted := false

## (เดิม) ใช้กับโค้ดเก่า — กะในสัปดาห์ / สัปดาห์
var current_day: int:
	get:
		return shift_in_week()
var current_week: int:
	get:
		return week()


func _enter_tree() -> void:
	if not EventManager.next_period.is_connected(change_period):
		EventManager.next_period.connect(change_period)
	if not EventManager.next_day.is_connected(change_day):
		EventManager.next_day.connect(change_day)


func _exit_tree() -> void:
	if EventManager.next_period.is_connected(change_period):
		EventManager.next_period.disconnect(change_period)
	if EventManager.next_day.is_connected(change_day):
		EventManager.next_day.disconnect(change_day)


func _ready() -> void:
	if dateText:
		dateText.add_theme_font_size_override("font_size", 14) # [10 ต.ค.] ย่อ HUD
	set_shift(1)

# ---------------------------------------------------------------- ปฏิทิน


func week() -> int:
	return clampi(floori((shift - 1) / float(SHIFTS_PER_WEEK)) + 1, 1, WEEKS_PER_MONTH * MONTHS)


func month() -> int:
	return clampi(floori((week() - 1) / float(WEEKS_PER_MONTH)) + 1, 1, MONTHS)


func shift_in_week() -> int:
	return (shift - 1) % SHIFTS_PER_WEEK + 1


func is_last_shift_of_week() -> bool:
	return shift_in_week() == SHIFTS_PER_WEEK


func work_slots_used_this_month() -> int:
	return floori(worked_minutes_month / float(SLOT_MIN))


func work_slots_per_month() -> int:
	return WORK_SLOTS_PER_SHIFT * SHIFTS_PER_WEEK * WEEKS_PER_MONTH # 320

# ---------------------------------------------------------------- นาฬิกา


## เวลางานจริงระหว่าง a ถึง b (นาที) — ไม่นับก่อน 09:00 และช่วงพัก
## เทิร์นที่เหลือของวันนี้ (with_ot = นับช่วงล่วงเวลาด้วย)
func turns_left(with_ot := false) -> int:
	return floori(remaining_work_minutes(with_ot) / float(SLOT_MIN))


## เทิร์นเต็มของ 1 วัน
static func turns_per_shift() -> int:
	return floori(work_minutes_between(OPEN, CLOSE) / float(SLOT_MIN))


static func turns_text(n: int) -> String:
	return "%d เทิร์น" % n


## บทที่ 1–12 (1 บท = 1 สัปดาห์)
func chapter() -> int:
	return week()


## เหลืออีกกี่วันจบบท (วันนี้ไม่นับ)
func days_left_in_chapter() -> int:
	return SHIFTS_PER_WEEK - shift_in_week()


## สัปดาห์ที่เท่าไรของเดือน 1–4
func week_in_month() -> int:
	return (week() - 1) % WEEKS_PER_MONTH + 1


## วันทำการที่เหลือในเดือนนี้ (วันนี้ไม่นับ)
func days_left_in_month() -> int:
	return (WEEKS_PER_MONTH - week_in_month()) * SHIFTS_PER_WEEK + days_left_in_chapter()


## [0.2.0] วันที่ของปี (1 = 1 ม.ค.) ของวันที่เล่นวันนี้ · จ. พ. ศ. ของแต่ละสัปดาห์
func day_of_year() -> int:
	return START_DAY_OF_YEAR + (week() - 1) * 7 + weekday()


## [0.2.0] วันที่ในปฏิทิน → Vector2i(วัน, เดือน 1–12)
func calendar_date() -> Vector2i:
	var d := day_of_year()
	var m := 1
	while m < 12 and d > days_in_month(m):
		d -= days_in_month(m)
		m += 1
	return Vector2i(d, m)


func calendar_day() -> int:
	return calendar_date().x


## 0 = จันทร์ … 4 = ศุกร์ (เฉพาะวันที่ร้านเปิด: จ. พ. ศ.)
func weekday() -> int:
	return OPEN_WEEKDAYS[clampi(shift_in_week(), 1, SHIFTS_PER_WEEK) - 1]


## [0.2.0] "อ. 5 ม.ค."
func date_text() -> String:
	var c := calendar_date()
	return "%s %d %s" % [WEEKDAY_SHORT[weekday()], c.x, MONTH_NAME[c.y - 1]]


## [0.2.0] ผ่านไปกี่วันในปฏิทินจากวันที่เล่นครั้งก่อน · จ.→พ. / พ.→ศ. = 2 · ศุกร์ → จันทร์ = 3 (ข้ามเสาร์–อาทิตย์) · วันแรกของเกม = 0
func days_since_last_play() -> int:
	if shift <= 1:
		return 0
	var i := shift_in_week() - 1
	if i == 0:
		return 7 - OPEN_WEEKDAYS[SHIFTS_PER_WEEK - 1] + OPEN_WEEKDAYS[0]
	return OPEN_WEEKDAYS[i] - OPEN_WEEKDAYS[i - 1]


## วันที่ของปีของ (วัน, เดือน)
static func day_of_year_of(day: int, month: int) -> int:
	var n := day
	for m in range(1, clampi(month, 1, 12)):
		n += days_in_month(m)
	return n


## 0 = จันทร์ … 6 = อาทิตย์ ของ (วัน, เดือน) ปี 2570
static func weekday_of(day: int, month: int) -> int:
	return posmod(day_of_year_of(day, month) - START_DAY_OF_YEAR, 7)


## [0.2.0] ป้ายสั้นของกะ (ไม่ต้องมีโหนด) เช่นปุ่มเล่นต่อ: "บทที่ 1 · อ. 5 ม.ค."
static func shift_label(s: int) -> String:
	s = clampi(s, 1, TOTAL_SHIFTS)
	var wk := floori((s - 1) / float(SHIFTS_PER_WEEK)) + 1
	var wd: int = OPEN_WEEKDAYS[(s - 1) % SHIFTS_PER_WEEK]
	var doy := START_DAY_OF_YEAR + (wk - 1) * 7 + wd
	var m := 1
	while m < 12 and doy > days_in_month(m):
		doy -= days_in_month(m)
		m += 1
	return "บทที่ %d · %s %d %s" % [wk, WEEKDAY_SHORT[wd], doy, MONTH_NAME[m - 1]]


static func days_in_month(m: int) -> int:
	return MONTH_DAYS[clampi(m, 1, 12) - 1]


static func work_minutes_between(a: int, b: int) -> int:
	var lo := maxi(a, WORK_START)
	if b <= lo:
		return 0
	var total := b - lo
	for br in BREAKS:
		total -= maxi(0, mini(b, br[1]) - maxi(lo, br[0]))
	return maxi(total, 0)


## เวลางานที่เหลือในกะนี้ (นาที) · with_ot = นับถึง 19:30
func remaining_work_minutes(with_ot := false) -> int:
	return work_minutes_between(current_minute, OT_LIMIT if with_ot else CLOSE)


func in_break() -> StringName:
	for br in BREAKS:
		if current_minute >= br[0] and current_minute < br[1]:
			return br[2]
	return &""


## ทำงาน m นาที (นับเฉพาะเวลางาน) — ข้ามช่วงพักให้เอง (ยิง break_started) · หยุดที่ 18:30 (หรือ 19:30 ถ้า overtime)
## คืนนาทีที่ทำได้จริง (น้อยกว่า m ถ้าชนเวลาปิด)
func advance_minutes(m: int) -> int:
	if finished or m <= 0:
		return 0
	var limit := OT_LIMIT if overtime else CLOSE
	var t := maxi(current_minute, WORK_START)
	var remaining := m
	var worked := 0
	var guard := 0
	while remaining > 0 and t < limit and guard < 16:
		guard += 1
		var jumped := false
		for br in BREAKS:
			if t >= br[0] and t < br[1]:
				t = br[1]
				break_started.emit(br[2])
				jumped = true
				break
		if jumped:
			continue
		var stop := limit
		for br in BREAKS:
			if br[0] > t:
				stop = mini(stop, br[0])
		var step := mini(remaining, stop - t)
		t += step
		remaining -= step
		worked += step
	worked_minutes_month += worked
	set_clock(t)
	return worked


## ปัดนาฬิกาขึ้นเป็น :00 / :30 ถัดไป (จบงานแล้ว — เวลาบนกระดานเป็นช่องเสมอ)
func snap_to_slot() -> void:
	var r := current_minute % SLOT_MIN
	if r != 0:
		set_clock(current_minute + SLOT_MIN - r)


func set_clock(minute: int) -> void:
	if finished:
		return
	current_minute = clampi(minute, 0, 24 * 60 - 1)
	var p: TIME = TIME.MORNING
	if current_minute >= PERIOD_START[TIME.EVENING]:
		p = TIME.EVENING
	elif current_minute >= PERIOD_START[TIME.NOON]:
		p = TIME.NOON
	if p != cur_period:
		cur_period = p
		period_changed.emit(cur_period)
	updateTime()
	clock_changed.emit(current_minute)
	if current_minute >= CLOSE and not _closed_emitted:
		_closed_emitted = true
		shift_closed.emit()


## ปิดร้าน → กะถัดไป 08:30 · ยิง week_ended / month_ended / game_ended ตามรอยต่อ แล้วค่อย shift_started
func end_shift() -> void:
	if finished:
		return
	var prev_week := week()
	var prev_month := month()
	shift += 1
	overtime = false
	_closed_emitted = false
	current_minute = OPEN
	cur_period = TIME.MORNING
	if shift > TOTAL_SHIFTS:
		shift = TOTAL_SHIFTS
		finished = true
		updateTime()
		week_ended.emit(prev_week)
		month_ended.emit(prev_month)
		game_ended.emit()
		return
	if week() != prev_week:
		week_ended.emit(prev_week)
	if month() != prev_month:
		month_ended.emit(prev_month)
		worked_minutes_month = 0
	updateTime()
	period_changed.emit(cur_period)
	clock_changed.emit(current_minute)
	shift_started.emit(month(), week(), shift_in_week())


## ตั้งกะ/เวลาตรง ๆ (โหลดเซฟ · debug · เริ่มเกมใหม่) — ไม่ยิง week_ended
func set_shift(s: int, minute := OPEN) -> void:
	shift = clampi(s, 1, TOTAL_SHIFTS)
	finished = false
	overtime = false
	_closed_emitted = minute >= CLOSE
	current_minute = clampi(minute, 0, 24 * 60 - 1)
	cur_period = TIME.MORNING
	set_clock(current_minute)
	period_changed.emit(cur_period)

# ---------------------------------------------------------------- ของเดิม (debug / EventManager.next_period · next_day)


## ข้ามไปช่วงถัดไปโดยไม่นับเวลางาน (debug) · เย็นแล้วไปต่อ = 18:30
func change_period() -> void:
	match cur_period:
		TIME.MORNING:
			set_clock(PERIOD_START[TIME.NOON])
		TIME.NOON:
			set_clock(PERIOD_START[TIME.EVENING])
		TIME.EVENING:
			set_clock(CLOSE)


## (เดิม "นอน → วันถัดไป") = ปิดร้าน → กะถัดไป
func change_day() -> void:
	end_shift()


func set_period(time: TIME) -> void:
	if not PERIOD_START.has(time):
		push_warning("TimeSystem.set_period: ช่วงเวลาไม่ถูกต้อง %s" % time)
		return
	set_clock(maxi(current_minute, PERIOD_START[time]))


## (เดิม) day = กะที่ของทั้งเกม
func set_date(day: int, period: TIME = TIME.MORNING) -> void:
	set_shift(day, PERIOD_START.get(period, OPEN) if period != TIME.MORNING else OPEN)


static func clock_text(minute: int) -> String:
	minute = clampi(minute, 0, 24 * 60 - 1)
	return "%02d:%02d" % [floori(minute / 60.0), minute % 60]


## "1½ ชม." · "30 นาที"
static func slots_text(slots: int) -> String:
	if slots <= 1:
		return "30 นาที"
	var h := floori(slots / 2.0)
	return ("%d½ ชม." % h) if slots % 2 == 1 else ("%d ชม." % h)


func updateTime() -> void:
	if timeText == null or dateText == null:
		return
	if not show_clock:
		_update_turns()
		return
	var br := in_break()
	var col := Color.LIGHT_YELLOW
	var txt := ""
	if current_minute < WORK_START:
		txt = "เปิดร้าน"
	elif br != &"":
		col = Color.LIGHT_GREEN
		txt = "พักเที่ยง" if br == &"lunch" else "พักบ่าย"
	elif current_minute >= CLOSE:
		col = Color.SALMON
		txt = "ล่วงเวลา" if current_minute > CLOSE else "ปิดร้าน"
	else:
		match cur_period:
			TIME.NOON:
				col = Color.YELLOW
			TIME.EVENING:
				col = Color.ORANGE
		txt = PERIOD_NAME[cur_period].trim_prefix("ช่วง")
	timeText.add_theme_color_override("font_color", col)
	timeText.text = txt
	dateText.text = (
		"%s · สัปดาห์ %d · กะ %d/%d\n%s น. · ชม.งาน %d/%d"
		% [
			MONTH_NAME[month() - 1],
			week(),
			shift_in_week(),
			SHIFTS_PER_WEEK,
			clock_text(current_minute),
			floori(worked_minutes_month / 60.0),
			floori(work_slots_per_month() / 2.0),
		]
	)


## [10 ต.ค.] HUD แบบเทิร์น: "12 เทิร์น" · "อังคาร 5 ม.ค." / "บทที่ 1 · สัปดาห์ที่ 1 ของ ม.ค." ([0.2.0])
func _update_turns() -> void:
	var br := in_break()
	var n := turns_left()
	var col := Color.LIGHT_YELLOW
	var txt := turns_text(n)
	if br != &"":
		col = Color.LIGHT_GREEN
		txt = "พักเที่ยง" if br == &"lunch" else "พักบ่าย"
	elif current_minute >= CLOSE:
		col = Color.SALMON
		txt = "ล่วงเวลา" if current_minute > CLOSE else "ปิดร้าน"
	elif n <= 4:
		col = Color.ORANGE
	timeText.add_theme_color_override("font_color", col)
	timeText.text = txt
	# [0.2.0] "อังคาร 5 ม.ค." / "บทที่ 1 · สัปดาห์ที่ 1 ของ ม.ค." — เลิกใช้ "วันที่ 2/5 · อีก 3 วันจบบท" (ทีมบอกว่างง)
	var c := calendar_date()
	dateText.text = "%s %d %s\nบทที่ %d · สัปดาห์ที่ %d ของ %s" % [
		WEEKDAY_FULL[weekday()],
		c.x,
		MONTH_NAME[c.y - 1],
		chapter(),
		week_in_month(),
		MONTH_NAME[clampi(month(), 1, MONTH_NAME.size()) - 1],
	]
