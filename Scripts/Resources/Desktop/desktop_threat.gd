@tool
class_name DesktopThreat extends Resource
## ไวรัสที่สแกนเจอ (VIRUS_SCAN) — 1 ช่องใน DesktopTask.threats (เดิมเป็น Dictionary)

## ชื่อไวรัส (ตั้งแล้วชื่อรายการใน Inspector เปลี่ยนตาม)
@export var name := "":
	set(v):
		name = v
		resource_name = v
## ตำแหน่งที่เจอ เช่น "ดาวน์โหลด › ธีมเกมฟรี.exe"
@export var where := ""
