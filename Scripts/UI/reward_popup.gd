class_name RewardPopup extends Control
## [0.2.5 · 8 พ.ย. 2569] ตัวเลขเด้งตอนส่งงาน: "+฿170" ลอยจากเงินบน HUD · "ชื่อเสียง +4" · "XP +100" ลอยจากแถบยศ
## ฉาก Scene/UI/reward_popup.tscn (วางใน day_loop.tscn → PopupLayer ชั้น 106: เหนือ HUD 100 · ปุ่มคลัง 105 · ใต้สรุปเดือน 108 · ข้ามวัน 110)
## DayLoop เรียก pop_result(result) ครั้งเดียวต่องาน ตอนการ์ดผลงานขึ้น · ใช้ pop() เด้งอะไรก็ได้

## ระยะลอยขึ้น (px) และเวลาทั้งหมด (วินาที)
@export var rise := 46.0
@export var seconds := 1.6
## เว้นระหว่างตัวเลขแต่ละอัน (วินาที)
@export var stagger := 0.25
@export var good_color := Color(0.45, 0.9, 0.45)
@export var bad_color := Color(1.0, 0.45, 0.4)
@export var xp_color := Color(1.0, 0.85, 0.35)
@export var font_size := 26
## ตำแหน่งสำรองถ้าหา HUD ไม่เจอ
@export var money_fallback := Vector2(300, 22)
@export var rank_fallback := Vector2(170, 66)

## ตัวเลขที่ลอยอยู่ตอนนี้ (ใช้ในเทส)
var live: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## ผลงานจาก GameState.record_repair: { money, reputation, xp, ... }
func pop_result(r: Dictionary) -> void:
	var money := int(r.get("money", 0))
	var rep := int(r.get("reputation", 0))
	var xp := int(r.get("xp", 0))
	var at_money := _hud_point(^"PanelContainer/HBoxContainer/MoneyLabel", money_fallback)
	var at_rank := _hud_point(^"RankPanel", rank_fallback)
	var delay := 0.0
	if money != 0:
		pop(("+฿%d" % money) if money > 0 else ("−฿%d" % -money), good_color if money > 0 else bad_color, at_money, delay)
		delay += stagger
	if rep != 0:
		pop("ชื่อเสียง %s%d" % ["+" if rep > 0 else "−", absi(rep)], good_color if rep > 0 else bad_color, at_money + Vector2(0, 34), delay)
		delay += stagger
	if xp > 0:
		pop("XP +%d" % xp, xp_color, at_rank + Vector2(60, 18), delay)


func pop(text: String, color: Color, at: Vector2, delay := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_outline_color", Color(0.15, 0.08, 0.02))
	l.add_theme_constant_override(&"outline_size", 8)
	l.modulate.a = 0.0
	add_child(l)
	l.position = at - Vector2(l.get_combined_minimum_size().x * 0.5, 0)
	live.append(l)
	var tw := l.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(l, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(l, "position:y", l.position.y + rise * 0.3, 0.15).from(l.position.y + rise * 0.6)
	tw.tween_interval(seconds * 0.5)
	tw.tween_property(l, "position:y", l.position.y - rise, seconds * 0.4)
	tw.parallel().tween_property(l, "modulate:a", 0.0, seconds * 0.4)
	tw.tween_callback(func() -> void:
		live.erase(l)
		l.queue_free()
	)
	return l


func _hud_point(path: NodePath, fallback: Vector2) -> Vector2:
	var em := get_node_or_null(^"/root/EventManager")
	var ts = em.get("time_system") if em else null
	if not is_instance_valid(ts):
		return fallback
	var n := (ts as Node).get_node_or_null(path) as Control
	if n == null or not n.is_visible_in_tree():
		return fallback
	var r := n.get_global_rect()
	return Vector2(r.get_center().x, r.end.y + 2)
