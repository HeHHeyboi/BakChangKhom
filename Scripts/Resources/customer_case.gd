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

@export_group("งานซ่อม")
## Core Part ที่ต้องซ่อม → เปิดมินิเกมตัวนั้น
@export_enum("part_ram", "part_mainboard", "part_gpu", "part_front_panel", "part_bios") var part_id: String = "part_ram"
## ชื่องานบนการ์ด เช่น "ทำความสะอาดแรม"
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


## ช่องที่ขาด — DayLoop เตือนใน Output ตอนเริ่มเกม
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if reason.strip_edges() == "":
		out.append("ไม่มีเหตุผลที่ลูกค้ามา (reason)")
	if symptom.strip_edges() == "":
		out.append("ไม่มีอาการ (symptom)")
	if scene_path() == "" or not ResourceLoader.exists(scene_path()):
		out.append("ไม่พบมินิเกม %s" % scene_path())
	if arrive_dialog != "" and not FileAccess.file_exists(arrive_dialog):
		out.append("ไม่พบบท %s" % arrive_dialog)
	elif arrive_dialog != "":
		# DialogScene อ่าน ":" เป็นหัว branch ของ Choice — อารมณ์ให้เขียน "ขม (ยิ้ม),..." ไม่ใช่ "ขม:happy,..."
		var f := FileAccess.open(arrive_dialog, FileAccess.READ)
		var n := 0
		while not f.eof_reached():
			var line := f.get_line().strip_edges()
			n += 1
			if line != "" and not line.begins_with("#") and line.find(":") > -1 and not line.begins_with("Choice:"):
				out.append("%s บรรทัด %d มี \":\" (อารมณ์ให้เขียน \"ชื่อ (ยิ้ม),\")" % [arrive_dialog.get_file(), n])
	return out
