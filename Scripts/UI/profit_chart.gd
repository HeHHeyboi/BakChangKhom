class_name ProfitChart extends Control
## [0.2.5 · 8 พ.ย. 2569] กราฟแท่งกำไร 12 เดือน (ม.ค.–ธ.ค.) ในหน้าสรุปเดือน — ให้เห็นว่าร้านโตขึ้นหรือแย่ลง
## อยู่ใน Scene/UI/month_summary.tscn → Card/VBox/ChartBox/ProfitChart · MonthSummary เรียก set_data()
## แท่ง = กำไรเดือนนั้น (ติดลบลงใต้เส้น) · ขีดดำ = เป้า · เขียว = ถึงเป้า · ส้ม = ไม่ถึง · แดง = ขาดทุน · กรอบ = เดือนนี้ · เดือนที่ยังไม่ถึง = ว่าง

@export var good_color := Color(0.25, 0.62, 0.3)
@export var warn_color := Color(0.9, 0.58, 0.15)
@export var bad_color := Color(0.78, 0.25, 0.18)
@export var target_color := Color(0.25, 0.17, 0.1)
@export var empty_color := Color(0.25, 0.17, 0.1, 0.12)
@export var text_color := Color(0.35, 0.25, 0.15)
@export var label_font_size := 11
## ความสูงที่เว้นไว้ใต้แท่งสำหรับชื่อเดือน
@export var label_h := 16.0

## [{ m, profit, target, reached }] · ใช้ GameState.month_results ได้ตรง ๆ
var months: Array = []
var current := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_data(results: Array, current_month: int) -> void:
	months = results
	current = current_month
	queue_redraw()


## ค่าของเดือน m (null = ยังไม่มีผล)
func value_of(m: int):
	for r in months:
		if int(r.get("m", 0)) == m:
			return r
	return null


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x / 12.0
	var plot_h := size.y - label_h
	var hi := 1
	var lo := 0
	for r in months:
		hi = maxi(hi, maxi(int(r.get("profit", 0)), int(r.get("target", 0))))
		lo = mini(lo, int(r.get("profit", 0)))
	var span := float(hi - lo)
	var base_y := plot_h * (hi / span)
	var y_of := func(v: int) -> float: return plot_h * (hi - v) / span
	draw_line(Vector2(0, base_y), Vector2(size.x, base_y), Color(target_color, 0.35), 1.0)
	for i in 12:
		var m := i + 1
		var x0 := i * w + w * 0.18
		var bw := w * 0.64
		var r = value_of(m)
		if r == null:
			draw_rect(Rect2(x0, base_y - 3, bw, 3), empty_color)
		else:
			var p := int(r.get("profit", 0))
			var t := int(r.get("target", 0))
			var col := good_color if bool(r.get("reached", false)) else (bad_color if p < 0 else warn_color)
			var y: float = y_of.call(p)
			var rect := Rect2(x0, minf(y, base_y), bw, maxf(absf(base_y - y), 2.0))
			draw_rect(rect, col)
			if m == current:
				draw_rect(rect.grow(2), target_color, false, 2.0)
			if t > 0:
				var ty: float = y_of.call(t)
				draw_line(Vector2(x0 - 3, ty), Vector2(x0 + bw + 3, ty), target_color, 2.0)
		var name: String = TimeSystem.MONTH_NAME[i]
		var sz := font.get_string_size(name, HORIZONTAL_ALIGNMENT_CENTER, -1, label_font_size)
		var tc := text_color if m <= maxi(current, 1) else Color(text_color, 0.4)
		draw_string(font, Vector2(i * w + (w - sz.x) * 0.5, size.y - 3), name, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, tc)
