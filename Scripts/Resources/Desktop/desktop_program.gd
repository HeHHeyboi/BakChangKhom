@tool
class_name DesktopProgram extends Resource
## โปรแกรมที่ติดตั้งในเครื่องลูกค้า — 1 ช่องใน DesktopTask.programs (เดิมเป็น Dictionary)

## ชื่อโปรแกรม (ตั้งแล้วชื่อรายการใน Inspector เปลี่ยนตาม)
@export var name := "":
	set(v):
		name = v
		resource_name = v
@export var publisher := ""
@export var size_mb := 100
## โปรแกรมโฆษณา (ต้องถอนทิ้ง)
@export var adware := false
## ของระบบ (อย่าถอน)
@export var system := false
## มีไอคอนบนเดสก์ท็อป
@export var desktop_icon := false
## เป็นแอปที่ลงเพื่อใช้งาน (ตรงกับ DesktopTask.install_name = ลงสำเร็จแล้ว)
@export var app := false


## สถานะตอนเล่นเป็น Dictionary (DesktopMinigame เติมช่อง installed/icon ต่อเอง)
func to_dict() -> Dictionary:
	return {
		"name": name,
		"publisher": publisher,
		"size_mb": size_mb,
		"adware": adware,
		"system": system,
		"desktop_icon": desktop_icon,
		"app": app,
	}
