class_name CustomerNPC
extends Resource
## [Claude 15 พ.ย. 2569 · 0.5.0] ลูกค้าประจำ 1 คน (PLAN_0_5_0 ข้อ 2) · ไฟล์ใน Resources/NPC/
## โยงกับ CustomerCase ด้วยชื่อ: `char_key` = `CustomerCase.customer` (เคสเดิมไม่ต้องแก้) · ชื่อที่ไม่มีไฟล์ NPC = ลูกค้าขาจร
## ค่าความสนิทเก็บที่ GameState.npc_affinity · ระดับ/ตัวเลขอยู่ใน EconomyConfig กลุ่ม "ลูกค้าประจำ + ยศ"

@export var id: StringName
## ชื่อบนการ์ด/สมุดลูกค้า
@export var display_name: String
## ตรงกับ Global._CharacterMap และ CustomerCase.customer
@export var char_key: String
@export_range(0, 100) var start_affinity := 0
## น้ำหนักตอนสุ่มลูกค้า (คูณกับตัวคูณระดับความสนิท)
@export_range(0.0, 5.0, 0.05) var base_weight := 1.0
## false = ไม่มีค่าความสนิท ไม่ขึ้นหัวใจ (ยาย — เนื้อเรื่องหลักดูแล)
@export var has_affinity := true
## เรื่องส่วนตัว เรียงตาม at
@export var stories: Array[NpcStory] = []
## บรรทัดแนะนำในสมุดลูกค้า
@export_multiline var bio: String


## ปัญหาของข้อมูล (ว่าง = ใช้ได้) · chars = คีย์ของ Global._CharacterMap
func problems(chars: Array = []) -> PackedStringArray:
	var out := PackedStringArray()
	if id == &"":
		out.append("ไม่มี id")
	if display_name.is_empty():
		out.append("ไม่มีชื่อ")
	if not chars.is_empty() and not chars.has(char_key):
		out.append("char_key \"%s\" ไม่มีใน _CharacterMap" % char_key)
	var last := 0
	for s in stories:
		if s == null:
			out.append("เรื่องส่วนตัวว่าง")
			continue
		if s.at <= last:
			out.append("เรื่องส่วนตัวต้องเรียง at จากน้อยไปมาก")
		last = s.at
		if s.dialog != "" and not ResourceLoader.exists(s.dialog) and not FileAccess.file_exists(s.dialog):
			out.append("ไม่พบไฟล์บท %s" % s.dialog)
	if not has_affinity and not stories.is_empty():
		out.append("ไม่มีค่าความสนิท แต่มีเรื่องส่วนตัว")
	return out
