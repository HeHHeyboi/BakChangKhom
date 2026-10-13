@tool
class_name OsSpinner extends Control
## จุดหมุนเป็นวงตอนเครื่องกำลังเริ่ม (แอนิเมชันโหลดทั่วไป) · ปรับสี/ขนาด/จำนวนจุดใน Inspector · [Claude 13 ต.ค. 2569]

@export var dot_color := Color(1, 1, 1)
@export var dots := 5
@export var dot_radius := 5.0
@export var ring_radius := 24.0
## วินาทีต่อรอบ
@export var period := 1.6

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	for i in dots:
		# จุดวิ่งตามกันแบบเร่ง-ผ่อน (ตัวหน้าเร็ว ตัวหลังตาม)
		var ph := fposmod(_t / period - i * 0.11, 1.0)
		var eased := ph - sin(ph * TAU) / TAU * 0.85
		var a := -PI / 2.0 + eased * TAU
		var fade := 1.0 - i * 0.12
		draw_circle(c + Vector2(cos(a), sin(a)) * ring_radius, dot_radius, Color(dot_color, fade))
