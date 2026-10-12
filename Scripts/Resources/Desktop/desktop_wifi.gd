@tool
class_name DesktopWifi extends Resource
## เครือข่าย Wi-Fi ที่เห็น (WIFI) — 1 ช่องใน DesktopTask.wifi (เดิมเป็น Dictionary)

## ชื่อเครือข่าย (ตั้งแล้วชื่อรายการใน Inspector เปลี่ยนตาม)
@export var name := "":
	set(v):
		name = v
		resource_name = v
## ต้องใส่รหัส
@export var locked := false
@export var password := ""
## เน็ตบ้านลูกค้า (ต่อเครือข่ายนี้ = ถูก)
@export var right := false
## ความแรงสัญญาณ 1–3 ขีด (เดิมคีย์ "signal")
@export_range(1, 3) var signal_level := 2
