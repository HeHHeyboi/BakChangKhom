class_name WallCertificates
extends VBoxContainer
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น J] กรอบใบประกาศบนผนังร้าน (สูงสุด 3 ใบ) — ใบที่ติดผนังในแอปใบประกาศ (GameState.ach_pinned) · ยังไม่ได้เลือก = ใบล่าสุด
## รูปกรอบวาดจากโค้ดชั่วคราว (รออาร์ตกรอบ) · ชี้เมาส์ = ชื่อใบประกาศ

const MAX := 3
var _last := ""


func _ready() -> void:
	add_theme_constant_override(&"separation", 6)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_refresh()


func _process(_d: float) -> void:
	var key := str(GameState.ach_pinned) + str(GameState.achievements.size())
	if key != _last:
		_refresh()


static func shown_ids() -> Array:
	var ids: Array = GameState.ach_pinned.filter(func(x) -> bool: return GameState.achievements.has(String(x)))
	if ids.is_empty():
		var all := GameState.achievements.keys()
		all.sort_custom(func(a, b) -> bool:
			var wa: Dictionary = GameState.achievements[a]
			var wb: Dictionary = GameState.achievements[b]
			return int(wa.get("month", 0)) * 10 + int(wa.get("day", 0)) > int(wb.get("month", 0)) * 10 + int(wb.get("day", 0)))
		ids = all
	return ids.slice(0, MAX)


func _refresh() -> void:
	_last = str(GameState.ach_pinned) + str(GameState.achievements.size())
	for c in get_children():
		c.queue_free()
	var A := get_node_or_null(^"/root/Achievements")
	for id in shown_ids():
		var a: Achievement = A.by_id(StringName(id)) if A else null
		if a == null:
			continue
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(46, 38)
		p.tooltip_text = "ใบประกาศ: %s\n%s" % [a.title, a.desc]
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.98, 0.94, 0.82)
		sb.border_color = Color(0.55, 0.36, 0.12)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(2)
		sb.set_content_margin_all(3)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 3
		p.add_theme_stylebox_override(&"panel", sb)
		var ic := TextureRect.new()
		ic.texture = Icons.tex(&"trophy")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(ic)
		add_child(p)
