@tool
class_name DesktopResolution extends Resource
## ความละเอียดหน้าจอที่เลือกได้ (DISPLAY) — 1 ช่องใน DesktopTask.resolutions (เดิมเป็น Dictionary)

## ชื่อความละเอียด เช่น "1366 × 768" (ตั้งแล้วชื่อรายการใน Inspector เปลี่ยนตาม)
@export var name := "":
	set(v):
		name = v
		resource_name = v
## จอรองรับ (false = เลือกแล้วจอดับ ต้องกดคืนค่าเดิม)
@export var ok := true
## ค่าที่แนะนำ (เลือกอันนี้ = ถูก)
@export var best := false
