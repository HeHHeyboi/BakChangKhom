class_name ShopEvent
extends Resource
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น B] อีเวนต์ของร้าน (PLAN_0_7_0 ข้อ 2–3 · GDD v1.9 ข้อ 13.9)
## CALENDAR = เกิดแน่นอนตามเดือน (day 1–4 = วันเปิดร้านที่เท่าไรของเดือน · 0 = ทั้งเดือน)
## RANDOM = สุ่มตอนเปิดร้าน (≤ 1 ครั้ง/วัน · ไม่เกิดวันที่ 1 ของเดือน/วันที่มีอีเวนต์ปฏิทินรายวัน · group เดียวกันไม่ซ้ำภายใน cooldown_days วันที่เล่น)
## ACTIVITY = กิจกรรมเลือกทำที่โค้ดเสนอเอง (คลาสศาลา)
## QUIZ = คำถามสั้นที่อีเวนต์หยิบไปใช้ (บูธงานบุญ · คลาสศาลา · เด็กขอดูซ่อม) — ตัวเลือก good_count ช่องแรก = คำตอบที่ดี (สลับลำดับตอนแสดง)
## ผลของแต่ละอีเวนต์อยู่ในโค้ด DayLoop (ส่วน "อีเวนต์") ตาม id · ไฟล์นี้เก็บข้อความ/เงื่อนไขให้ทีมแก้ใน Inspector
## ห้ามมี , หรือ : ในข้อความที่จะไปอยู่ในบทพูด (ask · explain) — ใช้ · แทน

enum Kind { CALENDAR, RANDOM, QUIZ, ACTIVITY }

@export var id: StringName
@export var kind: Kind = Kind.RANDOM
## กลุ่ม (กันซ้ำ · ชุดคำถาม) เช่น &"scam" · &"booth" · &"sala" · &"kids" · ว่าง = ใช้ id
@export var group: StringName
## ชื่อบนป้าย/การ์ด
@export var title: String
## รายละเอียดบนป้าย (ผลต่อเกม)
@export_multiline var note: String
## CALENDAR: เดือน 1–12
@export_range(0, 12) var month := 0
## CALENDAR: วันเปิดร้านที่ 1–4 ของเดือน · 0 = ทั้งเดือน
@export_range(0, 4) var day := 0
## RANDOM: เดือนที่เกิดได้ (ว่าง = ทุกเดือน)
@export var months: PackedInt32Array = []
## RANDOM: น้ำหนัก
@export var weight := 1.0
## RANDOM: เดือนที่น้ำหนัก ×2 (เช่น ไฟตก มี.ค./ส.ค.)
@export var boost_months: PackedInt32Array = []
## เกิดครั้งเดียวทั้งเกม
@export var once := false
## group เดียวกันไม่ซ้ำภายในกี่วันที่เล่น
@export var cooldown_days := 5
## ยศขั้นต่ำ (GameState.rank_level)
@export_range(0, 4) var min_rank := 0
## ผู้พูดบนการ์ด (ต้องตรง Global._CharacterMap ถ้าอยากได้รูป) · ว่าง = ปิ๊บ
@export var speaker: String
## ข้อความที่คนพูด/เหตุการณ์ (การ์ด)
@export_multiline var ask: String
@export_multiline var question: String
@export var choices: PackedStringArray = []
## ตัวเลือกช่องแรกกี่ช่องที่ถือว่าดี
@export_range(0, 4) var good_count := 1
## ปิ๊บอธิบายหลังตอบ (ตอบดี)
@export_multiline var explain: String
## ปิ๊บอธิบายเมื่อเลือกไม่ดี (ว่าง = ใช้ explain)
@export_multiline var explain_bad: String


func key() -> StringName:
	return group if group != &"" else id


func is_good(choice_text: String) -> bool:
	var i := Array(choices).find(choice_text)
	return i >= 0 and i < good_count


func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if id == &"":
		out.append("ไม่มี id")
	if title == "" and kind != Kind.QUIZ:
		out.append("ไม่มี title")
	if kind == Kind.CALENDAR and (month < 1 or month > 12):
		out.append("CALENDAR ต้องมี month 1–12")
	if kind == Kind.QUIZ and (choices.size() < 2 or question == ""):
		out.append("QUIZ ต้องมีคำถาม + ตัวเลือก ≥ 2")
	if choices.size() > 0 and good_count > choices.size():
		out.append("good_count เกินจำนวนตัวเลือก")
	for t in [ask, explain, explain_bad]:
		if t.contains(",") or t.contains(":"):
			out.append("ข้อความมี , หรือ : (%s…)" % t.left(20))
	return out
