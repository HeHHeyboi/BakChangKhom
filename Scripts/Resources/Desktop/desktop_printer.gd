@tool
class_name DesktopPrinter extends Resource
## เครื่องพิมพ์ที่ค้นเจอในเครือข่าย (PRINTER) — 1 ช่องใน DesktopTask.printers (เดิมเป็น Dictionary)

## ชื่อเครื่องพิมพ์ (ตั้งแล้วชื่อรายการใน Inspector เปลี่ยนตาม)
@export var name := "":
	set(v):
		name = v
		resource_name = v
## ที่ตั้ง เช่น "อาคาร 1 · ข้างโต๊ะครู"
@export var note := ""
## เครื่องของห้องลูกค้า (เลือกเครื่องนี้ = ถูก)
@export var right := false
