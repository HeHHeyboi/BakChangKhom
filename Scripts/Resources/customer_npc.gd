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


@export_group("แยกคนกับงาน (0.6.0 · PLAN_0_6_0 ข้อ 2 · 6)")
## ชนิดคน · SOLO = มาคนเดียว · GROUP = กลุ่มนักเรียน (members) · FAMILY = ยาย
@export_enum("SOLO", "GROUP", "FAMILY") var kind := 0
## ป้ายเรื่องที่คนนี้มักเอามา (จับคู่กับ CustomerCase.npc_tags) เช่น elder · school · gamer · office · student · village
@export var tags: PackedStringArray = []
## ช่วงเวลาที่มาร้าน (นาทีของวัน x = เริ่ม · y = จบ) · ว่าง = ทั้งวัน
@export var windows: Array[Vector2i] = []
## นักเรียน: ช่วงเปิดเทอมมาได้แค่หลังเลิกเรียน (school_after) · ปิดเทอม (EconomyConfig.school_break_months) มาได้ทั้งวัน
@export var school_hours := false
## เริ่มมาร้านตั้งแต่บทไหน (1 = ม.ค.)
@export_range(1, 12) var unlock_chapter := 1
## สมาชิกกลุ่ม (kind = GROUP)
@export var members: Array[CustomerNPC] = []
## ตัวคูณค่าแรง (นักเรียน 0.6)
@export_range(0.1, 3.0, 0.05) var fee_mult := 1.0
## ตัวคูณความสนิทที่ได้ (นักเรียน 1.5)
@export_range(0.1, 3.0, 0.05) var affinity_mult := 1.0
## เครื่องของคนนี้ (ใส่ใน {device} ของงานกลาง · ช่องแรก = เครื่องหลัก)
@export var devices: PackedStringArray = []
## ปลดก่อนบท unlock_chapter ได้ถ้าคนนี้สนิทถึง unlock_by_affinity ("พาเพื่อนมา") · 0 = ไม่ใช้
@export var unlock_by: CustomerNPC
@export_range(0, 100) var unlock_by_affinity := 0
## มาคนเดียวได้เมื่อความสนิทของตัวเองถึงค่านี้ (สมาชิกกลุ่มที่แยกมาเอง) · 0 = มาได้เลย
@export_range(0, 100) var solo_min_affinity := 0

const KIND_SOLO := 0
const KIND_GROUP := 1
const KIND_FAMILY := 2


func is_student() -> bool:
	return school_hours


## [0.6.0] งานกลางนี้คนนี้เอามาได้ไหม (ป้ายตรงกันอย่างน้อย 1 · "any" = ทุกคน · ความสนิทถึง)
func matches(c: CustomerCase, affinity := 0) -> bool:
	if c == null or not c.is_generic():
		return c != null and c.customer == char_key
	if c.min_affinity > 0 and affinity < c.min_affinity:
		return false
	if kind == KIND_GROUP and not c.group_ok:
		return false
	if c.group_ok and c.device_count > 1 and kind != KIND_GROUP:
		return false
	for t in c.npc_tags:
		if t == "any" or tags.has(t):
			return true
	return false


## [0.6.0] มาร้านได้ตอนนาทีนี้ไหม (month 1–12 · school_breaks = เดือนปิดเทอม · school_after = นาทีเลิกเรียน)
func available_at(minute: int, month: int, school_breaks: PackedInt32Array = [], school_after := 960) -> bool:
	if school_hours and not school_breaks.has(month) and minute < school_after:
		return false
	if windows.is_empty():
		return true
	for w in windows:
		if minute >= w.x and minute <= w.y:
			return true
	return false


func unlocked_in(chapter: int) -> bool:
	return chapter >= unlock_chapter


func is_group() -> bool:
	return kind == KIND_GROUP


## id ของสมาชิก (กลุ่ม) · คนเดียว = [id ตัวเอง]
func member_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if kind == KIND_GROUP:
		for m in members:
			if m:
				out.append(m.id)
	else:
		out.append(id)
	return out

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
	if kind == KIND_GROUP:
		if members.size() < 2:
			out.append("กลุ่มต้องมีสมาชิกอย่างน้อย 2 คน")
		for m in members:
			if m == null:
				out.append("สมาชิกกลุ่มว่าง")
			elif not chars.is_empty() and not chars.has(m.char_key):
				out.append("สมาชิก \"%s\" ไม่มีใน _CharacterMap" % m.char_key)
	for w in windows:
		if w.y < w.x:
			out.append("ช่วงเวลา %s จบก่อนเริ่ม" % w)
	if not has_affinity and not stories.is_empty():
		out.append("ไม่มีค่าความสนิท แต่มีเรื่องส่วนตัว")
	return out
