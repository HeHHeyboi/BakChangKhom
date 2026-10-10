@tool
class_name BenchTask extends Resource
## งานโต๊ะหลังเครื่อง (Lv2) — ซีนเดียว Scene/MiniGame/Bench/back_bench.tscn ต่างกันที่ข้อมูลในไฟล์นี้
## สร้างใหม่: คลิกขวาใน Resources/Bench/ → New Resource → BenchTask · แล้วใส่ใน CustomerCase.bench_task
## LEVEL_DESIGN ข้อ 3 (Lv2) · [Claude 10 ต.ค. 2569]

enum Goal {
	USB_DEVICE, ## เมาส์/คีย์บอร์ดไม่ทำงาน → ย้ายไปช่อง USB ที่ดี (กับดัก: ฝืนเสียบผิดช่อง)
	DISPLAY_CABLE, ## จอไม่ขึ้น → เสียบสายจอที่การ์ดจอ ไม่ใช่ช่องบนเมนบอร์ด (กับดัก: ดึงปลั๊กไฟตอนเครื่องเปิด)
	CLEAN_KEYBOARD, ## ปุ่มติด → ถอดคีย์บอร์ด แปรง + ลูกยางเป่า เสียบกลับ (กับดัก: ใช้ผ้าชุบน้ำ · ทำความสะอาดทั้งที่เสียบอยู่)
}

## ช่องหลังเครื่อง: id → ชนิด
const PORTS := {
	"usb1": "usb", "usb2": "usb", "usb3": "usb", "usb4": "usb",
	"hdmi_mb": "hdmi", "lan": "lan", "audio": "audio",
	"hdmi_gpu": "hdmi", "dp_gpu": "dp", "power": "power",
}
## สายของลูกค้า: id → ชนิดหัว
const PLUGS := { "keyboard": "usb", "mouse": "usb", "monitor": "hdmi", "power": "power" }

@export_group("งาน")
@export var goal: Goal = Goal.USB_DEVICE
@export var title := ""
@export var pc_name := "คอมของลูกค้า"
@export_multiline var request := ""

@export_group("เครื่อง")
## สายเสียบอยู่ช่องไหนตอนเริ่ม (plug id → port id · "" = ไม่ได้เสียบ)
@export var start_plugs: Dictionary = { "keyboard": "usb1", "mouse": "usb3", "monitor": "hdmi_gpu", "power": "power" }
## ช่อง USB ที่เสีย (เสียบแล้วไม่ทำงาน) · "" = ไม่มี
@export var broken_port := ""
## มีการ์ดจอ (ช่องจอบนเมนบอร์ดจะไม่มีภาพ)
@export var has_gpu := true
## คีย์บอร์ดสกปรก: จำนวนจุดเศษขนม
@export var dirt_spots := 0

@export_group("กับดัก")
## &"force_plug" ฝืนเสียบผิดชนิด · &"pull_power" ดึงปลั๊กไฟตอนเครื่องเปิด · &"water" ใช้ผ้าชุบน้ำ · &"clean_plugged" ทำความสะอาดตอนยังเสียบ
@export var traps: Array[StringName] = [&"force_plug", &"pull_power"]

@export_group("ขั้น 1 ฟัง · ขั้น 5 บอก")
@export var ask_options: PackedStringArray = []
@export var ask_best := 0
@export_multiline var ask_answer := ""
@export_multiline var ask_answer_wrong := "เอ… ไม่แน่ใจเหมือนกันนะ ขอแค่ใช้ได้ก็พอ"
@export var ask_note := ""
@export var explain_options: PackedStringArray = []
@export var explain_best := 0

@export_group("ปิ๊บ")
@export var pib_intro: PackedStringArray = []
@export var pib_lesson: PackedStringArray = []


func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if title.strip_edges() == "":
		out.append("BenchTask ไม่มี title")
	if ask_options.size() < 2 or ask_best < 0 or ask_best >= ask_options.size():
		out.append("BenchTask ask_options ต้องมี ≥2 ข้อ และ ask_best อยู่ในช่วง")
	if explain_options.size() < 2 or explain_best < 0 or explain_best >= explain_options.size():
		out.append("BenchTask explain_options ต้องมี ≥2 ข้อ และ explain_best อยู่ในช่วง")
	for k in start_plugs:
		if not PLUGS.has(String(k)):
			out.append("BenchTask start_plugs: ไม่มีสาย %s" % k)
		elif String(start_plugs[k]) != "" and not PORTS.has(String(start_plugs[k])):
			out.append("BenchTask start_plugs: ไม่มีช่อง %s" % start_plugs[k])
	match goal:
		Goal.USB_DEVICE:
			if broken_port == "" or PORTS.get(broken_port, "") != "usb":
				out.append("BenchTask USB_DEVICE ต้องตั้ง broken_port เป็นช่อง usb")
		Goal.CLEAN_KEYBOARD:
			if dirt_spots <= 0:
				out.append("BenchTask CLEAN_KEYBOARD ต้องมี dirt_spots")
	return out
