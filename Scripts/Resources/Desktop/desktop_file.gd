@tool
class_name DesktopFile extends Resource
## ไฟล์/โฟลเดอร์ในเครื่องลูกค้า — 1 ช่องใน DesktopTask.files (เดิมเป็น Dictionary)

enum Folder { DESKTOP, DOCUMENTS, PICTURES, DOWNLOADS, SYSTEM, USB }

## ชื่อโฟลเดอร์ที่โชว์ในเกม เรียงตาม enum Folder
const FOLDER_NAMES: PackedStringArray = ["เดสก์ท็อป", "เอกสาร", "รูปภาพ", "ดาวน์โหลด", "ระบบ (C:)", "USB (E:)"]
const USER = "user"
const DUP = "dup"
const SYSTEM = "system"
const JUNK = "junk"
const INSTALLER = "installer"
const FAKE_INSTALLER = "fake_installer"
## ชื่อไฟล์ (ตั้งแล้วชื่อรายการใน Inspector เปลี่ยนตาม)
@export var name := "":
	set(v):
		name = v
		resource_name = v
@export var folder := Folder.DESKTOP
## user ของลูกค้า (ห้ามลบ) · dup ไฟล์ซ้ำ · system ไฟล์ระบบ (ห้ามลบ) · junk ขยะ
## installer ตัวติดตั้งของจริง · fake_installer ตัวติดตั้งปลอม (ได้โปรแกรมโฆษณา)
@export_enum(USER,DUP,SYSTEM,JUNK,INSTALLER,FAKE_INSTALLER) var kind := JUNK
@export var size_mb := 1
## ข้อความตอนเปิดดู
@export_multiline var note := ""
## ชื่อไฟล์ต้นฉบับ (ของ kind = dup)
@export var dup_of := ""
## ลูกค้าตอบเมื่อถามว่าลบได้ไหม ("" = ใช้คำตอบตาม kind)
@export var reply := ""


func folder_name() -> String:
	return FOLDER_NAMES[folder]


## สถานะตอนเล่นเป็น Dictionary (DesktopMinigame เติมช่อง trashed/gone/... ต่อเอง)
func to_dict() -> Dictionary:
	return {
		"name": name,
		"size_mb": size_mb,
		"folder": folder_name(),
		"kind": kind,
		"note": note,
		"dup_of": dup_of,
		"reply": reply,
	}
