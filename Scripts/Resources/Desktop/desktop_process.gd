@tool
class_name DesktopProcess extends Resource
## โปรแกรมที่ทำงานอยู่ (ตัวจัดการงาน CLOSE_HANG / STARTUP) — 1 ช่องใน DesktopTask.processes (เดิมเป็น Dictionary)

## ชื่อโปรแกรม (ตั้งแล้วชื่อรายการใน Inspector เปลี่ยนตาม)
@export var name := "":
	set(v):
		name = v
		resource_name = v
## app โปรแกรมทั่วไป · hang ค้าง (ต้องปิด) · system ของระบบ (อย่าปิด) · unsaved ลูกค้ายังเปิดใช้อยู่/ยังไม่บันทึก (อย่าปิด)
@export_enum("app", "hang", "system", "unsaved") var kind := "app"
## เปิดพร้อมเครื่อง
@export var startup := false
## วินาทีที่หน่วงตอนเปิดเครื่อง (ถ้า startup)
@export var boot_s := 2
@export var cpu := 1


## สถานะตอนเล่นเป็น Dictionary (OsExtra เติมช่อง running/startup_on ต่อเอง)
func to_dict() -> Dictionary:
	return { "name": name, "kind": kind, "startup": startup, "boot_s": boot_s, "cpu": cpu }
