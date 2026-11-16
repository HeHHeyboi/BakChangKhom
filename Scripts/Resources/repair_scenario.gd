class_name RepairScenario
extends Resource
## [Claude 16 พ.ย. 2569 · 0.6.0 ขั้น C] สถานการณ์ซ่อม 1 แบบของ Core Part (PLAN_0_6_0 ข้อ 3 · GDD v1.9 ข้อ 13.3)
## ฉากในมินิเกมเหมือนเดิม — สถานการณ์เปลี่ยน "เรื่อง": อาการที่ลูกค้าเล่า · ปิ๊บพูดอะไรตอนส่องแต่ละจุด · คำถามวินิจฉัย (สาเหตุจริง)
## · ขั้นที่ข้ามได้ในเคสนี้ · อะไหล่ที่ต้องใช้ · สรุปสาเหตุ/วิธีสังเกต · ไฟล์ใน Resources/Scenario/<part>/
## ข้อความทุกช่องห้ามมี "," หรือ ":" (ใช้ในบทพูดกับไฟล์บทปิ๊บ)

@export var id: StringName
## part_ram · part_mainboard · part_gpu · part_front_panel · part_bios (ตรงกับ CustomerCase.part_id)
@export var part: StringName
## ชื่อสั้นในสมุด/learn_log เช่น "R-2 แรมใส่ไม่สุด"
@export var title: String
## อาการที่ลูกค้าเล่า (แทน CustomerCase.symptom)
@export_multiline var symptom: String
## ชื่องานบนการ์ด (ว่าง = ใช้ของเคส)
@export var job_title: String
## สาเหตุจริง 1 ประโยค (ขึ้นตอนสรุป)
@export var cause: String
## บทปิ๊บที่เปลี่ยน { "@HEADER ในไฟล์ *_Pib.txt": "ข้อความ" } · หลายบรรทัดคั่นด้วย "|"
@export var lines: Dictionary[String, String] = {}
## คำถามวินิจฉัยหลังตรวจครบ · ช่องแรก = คำตอบที่ถูก (สลับลำดับตอนแสดง)
@export var diag_choices: PackedStringArray = []
## ปิ๊บพูดเมื่อตอบผิด (ใบ้ให้กลับไปดูเบาะแส)
@export var diag_wrong: String
## ปิ๊บพูดเมื่อตอบถูก
@export var diag_correct: String
## ชื่อ phase (ตาม enum PhaseState ของ Part) ที่เคสนี้ไม่จำเป็น → มีปุ่ม "ข้ามขั้นนี้"
@export var optional_phases: PackedStringArray = []
## อะไหล่ที่ต้องใช้ (แทน CustomerCase.needs_part) · ว่าง = ไม่ใช้อะไหล่
@export var needs_part: StringName
@export var part_alternatives: Array[StringName] = []
@export var part_hint: String
## จุดหลอก — สิ่งที่ดูเหมือนสาเหตุแต่ไม่ใช่ (ปิ๊บเล่าตอนสรุป · นักสืบเห็นเป็นคำเตือน)
@export var decoy: String
## วิธีสังเกต/สิ่งที่ได้เรียน (ขึ้นตอนสรุป + learn_log)
@export var teach: String
## ความลับที่ลูกค้าไม่ได้เล่า (ว่าง = ไม่มี) · ขึ้นในบทตอนรับเครื่องถ้าลูกค้า "มีเรื่องไม่ได้เล่า"
@export var secret: String
## เงื่อนไขพิเศษให้ Part อ่าน เช่น { "ram_clean": true } = แรมสะอาดตั้งแต่ต้น
@export var flags: Dictionary = {}
## น้ำหนักตอนสุ่ม
@export_range(0.0, 5.0, 0.1) var weight := 1.0
## ยศขั้นต่ำ (GameState.rank_level · 0 = ช่างมือใหม่ = ทุกยศ)
@export_range(0, 4) var min_rank := 0


func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if id == &"":
		out.append("ไม่มี id")
	if not CustomerCase.PART_SCENES.has(String(part)):
		out.append("part %s ไม่มี" % part)
	if symptom.strip_edges() == "" or cause.strip_edges() == "" or teach.strip_edges() == "":
		out.append("ต้องมี symptom · cause · teach")
	if diag_choices.size() < 3:
		out.append("คำถามวินิจฉัยต้องมีอย่างน้อย 3 ตัวเลือก")
	var texts: Array[String] = [symptom, cause, diag_wrong, diag_correct, decoy, teach, secret]
	texts.append_array(Array(diag_choices))
	for k in lines:
		texts.append(lines[k])
	for t in texts:
		if t.contains(",") or t.contains(":"):
			out.append("ข้อความมี , หรือ : → %s" % t.left(30))
	return out


## บทปิ๊บของ header นี้เป็น DialogToken (หลายบรรทัดคั่น "|")
func line_tokens(header: String, speaker := "ปิ๊บ") -> Array:
	var out := []
	for t in String(lines.get(header, "")).split("|", false):
		out.append(DialogToken.new(speaker, t.strip_edges()))
	return out
