@tool
class_name View2D extends Control
## "มุม" 1 มุมของมินิเกม = รูปพื้นหลัง 1 ใบ + ชิ้น/จุดกด/socket ที่อยู่ในมุมนี้ (ลูกของ node นี้)
## ขนาดออกแบบ 1152 × 420 (พื้นที่เล่นระหว่างแถบหัวข้อกับแถบปิ๊บ) · ถ้าจอแคบลง (มีแผงข้าง) จะตัดขอบ โดยยึด focus_x ไว้กลางจอ
## แนวภาพ: ภาพรวมร้าน = 2D (Volcano Princess) · ในเคส = 2.5D (Lil' Guardsman) — เป็นแค่รูปคนละแบบ ระบบเหมือนกัน

const DESIGN := Vector2(1152, 420)

@export var background: Texture2D:
	set(v):
		background = v
		queue_redraw()
## เลื่อน/ขยายรูปพื้นหลัง (รูปใหญ่กว่ากรอบ เช่นฉากร้าน 1152×648 ใช้แค่แถบกลาง)
@export var bg_offset := Vector2.ZERO:
	set(v):
		bg_offset = v
		queue_redraw()
@export var bg_scale := 1.0:
	set(v):
		bg_scale = v
		queue_redraw()
## ชื่อบนปุ่มสลับมุม (แถบบนซ้าย) · ว่าง = ไม่มีปุ่ม
@export var label := ""
## ชื่อเก่าของมุมที่ให้พามาที่นี่ (เช่น "SlotClose" → Slots) — phase เดิมเรียกได้ไม่ต้องแก้
@export var aliases: PackedStringArray = []
## จุดที่ต้องเห็นเสมอเมื่อจอแคบ (พิกัด x ในมุมนี้)
@export var focus_x := 576.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	size = DESIGN


func _draw() -> void:
	if background:
		draw_texture_rect(background, Rect2(bg_offset, background.get_size() * bg_scale), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.14, 0.1))
