class_name RequestTask
extends Resource
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น G] เรื่องที่ลูกค้าเอามาที่ไม่ใช่งานซ่อม (PLAN_0_6_0 ข้อ 5 · V2_0_0_PLAN ข้อ 2.2)
## ขอคำปรึกษา (ยศฝึกหัดขึ้นไป) · ขอให้ช่วย (ทุกยศ) — 1 เทิร์น · ตอบคำถาม 1 ข้อ (บางเรื่องมีข้อต่อ) · ได้ความสนิทมาก เงินน้อย/ไม่มี
## ไฟล์ใน Resources/Request/ · ตัวเลือกช่องแรก = คำตอบที่ถูก (สลับลำดับตอนแสดง) · ห้ามซ้ำแบบทดสอบภาคผนวก ก และคลังสอบช่าง

enum Kind { CONSULT, FAVOR }

@export var id: StringName
@export var kind: Kind = Kind.FAVOR
## ป้ายคน (ตรงกับ CustomerNPC.tags) · "any" = ใครก็ได้
@export var npc_tags: PackedStringArray = ["any"]
## ยศขั้นต่ำ (GameState.rank_level) · ขอคำปรึกษาเริ่มยศฝึกหัด (1)
@export_range(0, 4) var min_rank := 0
## ชื่อเรื่องบนการ์ด เช่น "ช่วยดูว่า SMS นี้หลอกไหม"
@export var title: String
## ลูกค้าเล่า/ถาม
@export_multiline var ask: String
## คำถามที่ขมต้องตอบ
@export_multiline var question: String
@export var choices: PackedStringArray = []
## ปิ๊บอธิบายหลังตอบ (ทั้งถูกและผิด)
@export_multiline var explain: String
## ข้อต่อ (ว่าง = ไม่มี) · ถามเมื่อข้อแรกถูก
@export_multiline var question2: String
@export var choices2: PackedStringArray = []
@export_multiline var explain2: String
## ค่าปรึกษา (ขอให้ช่วย = 0)
@export_range(0, 200) var fee := 0
## ลูกค้าขอบคุณตอนตอบดี
@export var thanks: String
## หมวดความรู้ (ขึ้นในสมุด/learn_log) เช่น "ความปลอดภัยไซเบอร์" · "เลือกสเปกตามงบ"
@export var topic: String


func is_consult() -> bool:
	return kind == Kind.CONSULT


func kind_name() -> String:
	return "ขอคำปรึกษา" if is_consult() else "ขอให้ช่วย"


func steps() -> int:
	return 2 if question2.strip_edges() != "" and choices2.size() >= 2 else 1


func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if id == &"":
		out.append("ไม่มี id")
	if title.strip_edges() == "" or ask.strip_edges() == "" or question.strip_edges() == "" or explain.strip_edges() == "":
		out.append("ต้องมี title · ask · question · explain")
	if choices.size() < 3:
		out.append("ตัวเลือกต้องมีอย่างน้อย 3")
	if question2.strip_edges() != "" and (choices2.size() < 2 or explain2.strip_edges() == ""):
		out.append("ข้อต่อต้องมีตัวเลือก 2 ข้อขึ้นไป + explain2")
	if is_consult() and min_rank < 1:
		out.append("ขอคำปรึกษาต้องเริ่มยศฝึกหัด (min_rank 1)")
	if not is_consult() and fee > 0:
		out.append("ขอให้ช่วยไม่คิดเงิน")
	return out
