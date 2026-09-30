@tool
class_name MiniSpot2D extends Control
## ภาพย่อของชิ้นที่เสียบอยู่ใน socket ของอีกมุมหนึ่ง (เช่นแรมตัวเล็ก ๆ บนเมนบอร์ดตอนมองทั้งเคส)
## ใช้หน้าตา "mini" (หรือ "mini@สถานะ") ของชิ้นนั้น · socket ว่าง = ไม่วาด

@export var socket: Socket2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if socket == null:
		if Engine.is_editor_hint():
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.6, 1, 0.3))
		return
	var it := socket.occupant
	if it == null:
		return
	var t := it.texture_for("mini", it.state)
	if t == it.texture and not it.looks.has("mini"):
		return
	if t:
		draw_texture_rect(t, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, it.modulate.a))
