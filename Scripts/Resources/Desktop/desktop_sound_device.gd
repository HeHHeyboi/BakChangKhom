@tool
class_name DesktopSoundDevice extends Resource
## อุปกรณ์ส่งเสียงออก (SOUND) — 1 ช่องใน DesktopTask.sound_devices (เดิมเป็น Dictionary)

## ชื่ออุปกรณ์ (ตั้งแล้วชื่อรายการใน Inspector เปลี่ยนตาม)
@export var name := "":
	set(v):
		name = v
		resource_name = v
## ใช้งานได้จริง (เลือกอุปกรณ์นี้ = มีเสียง)
@export var works := false
