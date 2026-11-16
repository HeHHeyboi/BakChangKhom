class_name ExamQuestion
extends Resource
## [Claude 16 พ.ย. 2569 · 0.5.0 ขั้น G] ข้อสอบเลื่อนยศ 1 ข้อ (PLAN_0_5_0 ข้อ 5.2) · ไฟล์ใน Resources/Exam/
## ปิ๊บถามตอนปิดร้านวันที่ XP ครบ · ตัวเลือกสลับลำดับทุกครั้ง · ⚠ ห้ามซ้ำกับแบบทดสอบก่อน–หลังเล่น (ภาคผนวก ก ในเล่มรายงาน)
## ข้อความทุกช่องห้ามมี , หรือ : (บทพูดใช้ 2 ตัวนี้แบ่งช่อง)

@export var id: StringName
## Part ที่ถาม (part_ram · part_mainboard · part_gpu · part_front_panel · part_bios · part_desktop · part_bench) · &"general" = ความปลอดภัย/ขั้นตอน
@export var part: StringName = &"general"
## ใช้กับการสอบขึ้นยศ index นี้ขึ้นไป (1 = ฝึกหัด … 4 = มือโปร)
@export_range(1, 4) var level := 1
@export_multiline var question: String
@export var choices: PackedStringArray = []
## index ของคำตอบที่ถูกใน choices
@export var answer := 0
## เฉลยสั้น ๆ ที่ปิ๊บพูดหลังตอบ
@export_multiline var explain: String
## [0.5.0] ภาพประกอบ (ข้อแบบดูภาพ · คล้ายข้อสอบใบรับรองช่าง) · ว่าง = ข้อความอย่างเดียว
@export var image: Texture2D
## หมวดบนหัวข้อ/ใบแจ้งผล · ว่าง = ตาม Part (ฮาร์ดแวร์ · ซอฟต์แวร์ · ขั้นตอนการทำงาน)
@export var domain: String


const DOMAIN_HW := "ฮาร์ดแวร์"
const DOMAIN_SW := "ซอฟต์แวร์และระบบ"
const DOMAIN_OPS := "ขั้นตอนการทำงาน"
const DOMAIN_SEC := "ความปลอดภัย"


func domain_name() -> String:
	if domain != "":
		return domain
	match String(part):
		"general":
			return DOMAIN_OPS
		"part_desktop", "part_bios":
			return DOMAIN_SW
	return DOMAIN_HW


func correct_text() -> String:
	return choices[answer] if answer >= 0 and answer < choices.size() else ""


func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if id == &"":
		out.append("ไม่มี id")
	if choices.size() < 2 or answer < 0 or answer >= choices.size():
		out.append("ตัวเลือก/คำตอบไม่ถูก")
	var seen := { }
	for t in [question, explain] + Array(choices):
		if String(t).contains(",") or String(t).contains(":"):
			out.append("มี , หรือ : ใน \"%s\"" % t)
	for c in choices:
		if seen.has(c):
			out.append("ตัวเลือกซ้ำ \"%s\"" % c)
		seen[c] = true
	return out
