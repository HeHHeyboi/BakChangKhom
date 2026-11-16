class_name DecorShelf
extends HBoxContainer
## [Claude 16 พ.ย. 2569 · 0.8.0 ขั้น F] ของตกแต่งในร้าน (DecorBook.owned) — วางเรียงบนชั้น · spot = ชนิดที่โชว์ (SHELF/WALL/CEILING)
## รูปตอนนี้ = ไอคอน + สีในกรอบ (รออาร์ต: ShopDecor.texture) · ชี้เมาส์ = ชื่อ + ที่มา · กดไม่ได้ (ของโชว์)

@export var spots: Array[int] = [0, 1, 2]
@export var max_items := 6
@export var item_size := Vector2(40, 40)
var _last := ""


func _ready() -> void:
	add_theme_constant_override(&"separation", 4)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_refresh()


func _process(_d: float) -> void:
	if _key() != _last:
		_refresh()


func _key() -> String:
	return str(GameState.achievements.size()) + str(GameState.gifts_received.size())


func shown() -> Array[ShopDecor]:
	var out: Array[ShopDecor] = []
	for d in DecorBook.owned():
		if spots.has(int(d.spot)):
			out.append(d)
	return out.slice(0, max_items)


func _refresh() -> void:
	_last = _key()
	for c in get_children():
		c.queue_free()
	for d in shown():
		var p := PanelContainer.new()
		p.custom_minimum_size = item_size
		var src := ("ของขวัญจาก%s" % _npc_name(d.from_npc)) if d.from_npc != &"" else "รางวัลใบประกาศ"
		p.tooltip_text = "%s\n%s\n(%s)" % [d.title, d.desc, src]
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.14, 0.09, 0.55)
		sb.border_color = Color(0.55, 0.36, 0.12)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.set_content_margin_all(3)
		p.add_theme_stylebox_override(&"panel", sb)
		var ic := TextureRect.new()
		ic.texture = d.image()
		ic.modulate = d.tint if d.texture == null else Color.WHITE
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(ic)
		add_child(p)


static func _npc_name(id: StringName) -> String:
	var n := NpcBook.by_id(id)
	return n.display_name if n else String(id)
