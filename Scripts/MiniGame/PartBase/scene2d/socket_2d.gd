@tool
class_name Socket2D extends Control
## จุดวางชิ้นส่วน (กรอบสี่เหลี่ยมในมุมภาพ) — ชิ้นที่วางลงจะย้ายมาอยู่ในกรอบนี้ และใช้หน้าตาตาม look
## ตรวจตามกฎ TUTORIAL_ASSEMBLY_DESIGN.md ข้อ 4 · ใน Editor เห็นเป็นกรอบฟ้าจาง ๆ
## [Claude 30 ก.ย. 2569] แทน Socket3D/Socket25D

enum Result { OK, WRONG_SOCKET, WRONG_ORDER, WRONG_ORIENTATION, OCCUPIED, LOCKED }

@export var socket_type: StringName
@export var accept_any := false ## ถาดพักชิ้นส่วน: รับทุกชิ้น
## ทิศที่ต้องหัน (0 หรือ 180) · < 0 = ไม่สนทิศ
@export var required_yaw := -1.0
@export var locks: Array[Item2D] = [] ## สลักที่ต้อง "เปิด" ก่อนถอด/ใส่
@export var start_occupant: Item2D
## ชิ้นที่วางในกรอบนี้ใช้หน้าตาชื่อนี้ (Item2D.looks) เช่น "slot" · "mat" · "case"
@export var look := ""

var occupant: Item2D
var _hl := 0 # 0 ปิด · 1 เขียว · 2 แดง · 3 ใบ้ (ถือชิ้นที่ใส่ได้)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_locked() -> bool:
	for l in locks:
		if l and not l.toggle_on:
			return true
	return false


func check(part: Item2D, installed_ids: Array) -> Result:
	if occupant and occupant != part:
		return Result.OCCUPIED
	if not accept_any and (part.data == null or part.data.socket_type != socket_type):
		return Result.WRONG_SOCKET
	if not accept_any:
		for r in part.data.requires:
			if not installed_ids.has(r):
				return Result.WRONG_ORDER
		if required_yaw >= 0.0 and part.data.needs_orientation \
				and not is_equal_approx(fposmod(part.yaw_deg, 360.0), fposmod(required_yaw, 360.0)):
			return Result.WRONG_ORIENTATION
	if is_locked():
		return Result.LOCKED
	return Result.OK


## 0 = ปิด · 1 = เขียว (ใส่ได้) · 2 = แดง (ผิด) · 3 = กรอบประให้รู้ว่าวางตรงนี้ได้
func highlight(state: int) -> void:
	_hl = state
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-2)
	match _hl:
		1:
			draw_rect(r, Color(0.3, 1, 0.45, 0.28))
			draw_rect(r, Color(0.3, 1, 0.45, 0.9), false, 3)
		2:
			draw_rect(r, Color(1, 0.3, 0.3, 0.28))
			draw_rect(r, Color(1, 0.3, 0.3, 0.9), false, 3)
		3:
			var c := Color(1, 0.9, 0.5, 0.85)
			var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
			for i in 4:
				draw_dashed_line(pts[i], pts[i + 1], c, 2.5, 8.0)
		_:
			if Engine.is_editor_hint():
				draw_rect(r, Color(0.3, 0.6, 1, 0.18))
				draw_rect(r, Color(0.3, 0.6, 1, 0.6), false, 2)
