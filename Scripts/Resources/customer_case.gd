@tool
class_name CustomerCase extends Resource
## ลูกค้า 1 คน = งานซ่อม 1 งาน · แก้ทุกช่องได้ใน Inspector (ดับเบิลคลิกไฟล์ใน Resources/Customers/)
## DayLoop เอาไปทำการ์ดลูกค้า → บทพูด → มินิเกม → การ์ดผลงาน · ดู Docs/WEEK1_CUSTOMERS.md
## [Claude 5 ต.ค. 2569]

## มินิเกมของแต่ละ Core Part
const PART_SCENES := {
	"part_ram": "res://Scene/MiniGame/PartRam/part_ram.tscn",
	"part_mainboard": "res://Scene/MiniGame/PartMainboard/part_mainboard.tscn",
	"part_gpu": "res://Scene/MiniGame/PartGpu/part_gpu.tscn",
	"part_front_panel": "res://Scene/MiniGame/PartFrontPanel/part_front_panel.tscn",
	"part_bios": "res://Scene/MiniGame/PartBios/part_bios.tscn",
	"part_desktop": "res://Scene/MiniGame/Desktop/desktop_window.tscn", # ขมOS งานบนจอ Lv1 → ใส่ desktop_task ด้วย
}

@export_group("ลูกค้า")
## รหัสงาน (ไม่ซ้ำกัน) เช่น w1_d1_amnuay
@export var id: StringName
## ชื่อตัวละคร — ต้องตรงกับ key ใน Global._CharacterMap (Scene/Global.tscn) เช่น ลุงอำนวย · ครู · เด็กหญิง
@export var customer: String = "ลุงอำนวย"
## เหตุผลที่ลูกค้ามาร้านขม (บังคับกรอก) — โชว์บนการ์ดลูกค้า เช่น "ยายเล่าว่าขมกลับมาเปิดร้าน"
@export_multiline var reason: String
## เครื่องของลูกค้า เช่น "คอมตั้งโต๊ะเครื่องเก่า ใช้มา 6 ปี"
@export var device: String
## อาการที่ลูกค้าเล่า
@export_multiline var symptom: String

@export_group("ระดับงาน (LEVEL_DESIGN ข้อ 2 · 7.2)")
## 1 ง่าย · 2 ปกติ · 3 ปานกลาง · 4 ยาก · 5 ชำนาญ — ค่าจ้าง/XP จาก economy.tres
@export_range(1, 5) var level := 2
## เวลาที่ประเมินบนการ์ด (ช่อง 30 นาที) · 0 = ใช้ค่าเฉลี่ยของระดับ
@export_range(0, 14) var est_slots := 0
## ต้องรับภายในกี่กะ · 0 = ภายในกะนี้ · หมดเขต = ลูกค้าเดินออก
@export_range(0, 10) var due_shifts := 1

@export_group("งานซ่อม")
## Core Part ที่ต้องซ่อม → เปิดมินิเกมตัวนั้น
@export_enum("part_ram", "part_mainboard", "part_gpu", "part_front_panel", "part_bios", "part_desktop") var part_id: String = "part_ram"
## งานบนจอ (part_desktop) — ข้อมูลเครื่อง/ไฟล์/กับดักในขมOS (Resources/Desktop/*.tres) · [Claude 9 ต.ค. 2569]
@export var desktop_task: DesktopTask
## ชื่องานบนการ์ดผลงาน เช่น "ทำความสะอาดแรม" (การ์ดบนกระดานไม่โชว์ — ผู้เล่นต้องวินิจฉัยเอง)
@export var job_title: String
## ค่าซ่อม (บาท) · −1 = ใช้ค่าจาก Resources/Balance/economy.tres
@export var fee := -1
## มินิเกมอื่นแทนของ part_id (ปกติเว้นว่าง)
@export_file("*.tscn") var scene_override: String

@export_group("บทพูด")
## บทตอนลูกค้าเข้าร้าน (รูปแบบเดียวกับ Assets/Dialog — ชื่อ,ข้อความ)
@export_file("*.txt") var arrive_dialog: String
## ฉากหลังของบท · ว่าง = ร้านขม
@export_file("*.png", "*.jpg") var bg: String = "res://Assets/Background/bg_shop_open.jpg"
## ลูกค้าพูดตอนรับเครื่อง ถ้าซ่อมผ่าน (โชว์บนการ์ดผลงาน)
@export_multiline var thanks_text: String
## ลูกค้าพูดตอนรับเครื่อง ถ้าซ่อมไม่ผ่าน
@export_multiline var complain_text: String

@export_group("Event")
## event บังคับ: บทลูกค้าเล่นเองทันทีที่เข้าร้าน · ปฏิเสธงาน/ปิดร้านไม่ได้ (ใช้กับลูกค้าคนแรกหลัง Tutorial)
@export var forced := false


func scene_path() -> String:
	return scene_override if scene_override != "" else PART_SCENES.get(part_id, "")


func part() -> StringName:
	return StringName(part_id)


const LEVEL_NAMES := ["ง่าย", "ปกติ", "ปานกลาง", "ยาก", "ชำนาญ"]


func level_name() -> String:
	return "Lv%d %s" % [level, LEVEL_NAMES[clampi(level, 1, 5) - 1]]


## เวลาที่ใช้ (ช่อง) · est_slots หรือค่าเฉลี่ยของระดับ
func slots(econ: EconomyConfig = null) -> int:
	if est_slots > 0:
		return est_slots
	if econ:
		return ceili(econ.avg_slots_for_level(level))
	return [2, 3, 5, 7, 10][clampi(level, 1, 5) - 1]


## ช่องที่ขาด — DayLoop เตือนใน Output ตอนเริ่มเกม
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if id == &"":
		out.append("ไม่มี id")
	if customer.strip_edges() == "":
		out.append("ไม่มีชื่อลูกค้า (customer)")
	elif not Engine.is_editor_hint():
		var g := (Engine.get_main_loop() as SceneTree).root.get_node_or_null(^"Global") if Engine.get_main_loop() is SceneTree else null
		if g and g.has_method("hasCharacter") and not g.hasCharacter(customer):
			out.append("ชื่อ \"%s\" ไม่มีใน Global._CharacterMap (บทจะไม่ขึ้นรูป)" % customer)
	if reason.strip_edges() == "":
		out.append("ไม่มีเหตุผลที่ลูกค้ามา (reason)")
	if symptom.strip_edges() == "":
		out.append("ไม่มีอาการ (symptom)")
	if job_title.strip_edges() == "":
		out.append("ไม่มีชื่องาน (job_title)")
	if fee < -1:
		out.append("fee ติดลบ (ใช้ -1 = ค่าจาก economy)")
	if part_id == "part_desktop" and scene_override == "":
		if desktop_task == null:
			out.append("งานบนจอ (part_desktop) ต้องใส่ desktop_task")
		else:
			out.append_array(desktop_task.problems())
	if scene_path() == "" or not ResourceLoader.exists(scene_path()):
		out.append("ไม่พบมินิเกม %s" % scene_path())
	if arrive_dialog != "":
		if not FileAccess.file_exists(arrive_dialog):
			out.append("ไม่พบบท %s" % arrive_dialog)
		elif not DialogUtil.has_lines(arrive_dialog):
			out.append("บท %s ว่าง (ไม่มีบรรทัด ชื่อ,ข้อความ)" % arrive_dialog.get_file())
		else:
			# DialogScene อ่าน ":" เป็นหัว branch ของ Choice — อารมณ์ให้เขียน "ขม (ยิ้ม),..." ไม่ใช่ "ขม:happy,..."
			for n in DialogUtil.colon_lines(arrive_dialog):
				out.append("%s บรรทัด %d มี \":\" (อารมณ์ให้เขียน \"ชื่อ (ยิ้ม),\")" % [arrive_dialog.get_file(), n])
	if bg != "" and not ResourceLoader.exists(bg):
		out.append("ไม่พบฉากหลัง %s" % bg)
	if thanks_text.strip_edges() == "" or complain_text.strip_edges() == "":
		out.append("ไม่มีคำพูดตอนรับเครื่อง (thanks_text / complain_text)")
	return out
