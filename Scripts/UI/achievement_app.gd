class_name AchievementApp extends VBoxContainer
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น J] หน้า "ความสำเร็จ" (ใบประกาศ)
## [0.9.0 ขั้น 0] ย้ายจากแอปในคอมขมมาอยู่ในเมนูพัก (PauseMenu → ความสำเร็จ) ที่เดียว · ไม่มีติดผนัง/รางวัลของตกแต่งแล้ว
## แสดงผลอย่างเดียว ← Achievements.view() · แยกหมวด · ได้แล้ว = วันที่ได้ · ยังไม่ได้ = ความคืบหน้า · ใบลับ = ???
## ท้ายหน้า = ของขวัญส่งท้ายปีที่ได้รับ (GameState.gifts_received)

@export var row_style: StyleBox
@export var font := Color(0.35, 0.2, 0.08)
@export var gold := Color(0.62, 0.42, 0.08)
@export var dim := Color(0.55, 0.5, 0.44)
## [0.9.5] true = ดูจากโปรไฟล์ทุกเซฟ (เมนูหลัก) · false = เซฟที่เล่นอยู่ (เมนูพัก)
@export var source_profile := false
## หมวดที่เปิดอยู่ (Achievement.Category) · -1 = ทั้งหมด (ค่าเริ่ม) · ของขวัญส่งท้ายปีอยู่ท้ายหมวดลูกค้าและชุมชน
var category := -1
const ALL := -1
const GIFT_CATEGORY := Achievement.Category.PEOPLE

var _last_hash := 0
var _t := 0.0
var _tabs: HBoxContainer


func _ready() -> void:
	# [0.9.5] แถบหมวด 5 หมวด (สร้างจากโค้ด ต่อจากหัวข้อ)
	_tabs = HBoxContainer.new() # หมวดอยู่บรรทัดเดียว (ผู้ใช้ 16 พ.ย.)
	_tabs.name = "Tabs"
	_tabs.add_theme_constant_override(&"separation", 4)
	add_child(_tabs)
	move_child(_tabs, %Head.get_index() + 1)
	for i in range(-1, Achievement.CATEGORY_NAME.size()): # -1 = ทั้งหมด
		var b := Button.new()
		b.name = "TabAll" if i == ALL else "Tab%d" % i
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override(&"font_size", 12)
		b.custom_minimum_size.y = 30
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for st in [&"normal", &"hover", &"pressed", &"hover_pressed"]: # ปุ่มเตี้ย ขอบบาง (ธีมเมนูขอบไม้หนาเกินไปสำหรับ 5 ปุ่มในบรรทัดเดียว)
			var ts := StyleBoxFlat.new()
			ts.bg_color = Color(0.85, 0.5, 0.18) if st in [&"pressed", &"hover_pressed"] else (Color(1, 0.88, 0.66) if st == &"hover" else Color(0.98, 0.93, 0.82))
			ts.border_color = Color(0.55, 0.38, 0.22)
			ts.set_border_width_all(2)
			ts.set_corner_radius_all(14)
			ts.content_margin_left = 4
			ts.content_margin_right = 4
			ts.content_margin_top = 3
			ts.content_margin_bottom = 3
			b.add_theme_stylebox_override(st, ts)
		b.add_theme_color_override(&"font_color", Color(0.35, 0.22, 0.1))
		b.add_theme_color_override(&"font_hover_color", Color(0.35, 0.22, 0.1))
		b.add_theme_color_override(&"font_pressed_color", Color.WHITE)
		b.add_theme_color_override(&"font_hover_pressed_color", Color.WHITE)
		b.pressed.connect(select_category.bind(i))
		_tabs.add_child(b)
	refresh()


func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.5:
		_t = 0.0
		refresh()


func select_category(i: int) -> void:
	category = clampi(i, ALL, Achievement.CATEGORY_NAME.size() - 1)
	refresh(true)


func refresh(force := false) -> void:
	var a := get_node_or_null(^"/root/Achievements")
	if a == null:
		return
	var v: Dictionary = a.view(source_profile)
	var h := (str(v) + str(GameState.gifts_received) + str(category)).hash()
	if h == _last_hash and not force:
		return
	_last_hash = h
	%Head.text = String(v.get("title", ""))
	var cats: Array = v.get("cats", [])
	for k in _tabs.get_child_count():
		var b := _tabs.get_child(k) as Button
		var i := k - 1 # ปุ่มแรก = ทั้งหมด
		if i == ALL:
			b.text = "ทั้งหมด %d/%d" % [int(v.get("got", 0)), int(v.get("total", 0))]
		elif i < cats.size():
			b.text = "%s %d/%d" % [cats[i].name, int(cats[i].got), int(cats[i].total)]
		b.set_pressed_no_signal(i == category)
	for n in %List.get_children():
		%List.remove_child(n)
		n.queue_free()
	var head := -2
	for r: Dictionary in v.get("rows", []):
		var c := int(r.get("cat", 0))
		if category != ALL and c != category:
			continue
		if category == ALL and c != head: # ทั้งหมด = มีหัวหมวดคั่น
			head = c
			var hd := Label.new()
			hd.text = String(r.category)
			hd.add_theme_font_size_override(&"font_size", 15)
			hd.add_theme_color_override(&"font_color", font)
			%List.add_child(hd)
		%List.add_child(_row(r))
	if (category == GIFT_CATEGORY or category == ALL) and not source_profile:
		_add_gifts()


func _row(r: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.name = "Row_" + String(r.get("id", ""))
	if row_style:
		var sb := row_style.duplicate() as StyleBox
		if sb is StyleBoxFlat and bool(r.got):
			(sb as StyleBoxFlat).bg_color = Color(1, 0.95, 0.78)
			(sb as StyleBoxFlat).border_color = Color(0.78, 0.6, 0.2)
		p.add_theme_stylebox_override(&"panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 10)
	p.add_child(hb)
	var ic := TextureRect.new()
	ic.texture = Icons.tex(&"trophy") if bool(r.got) else Icons.tex(&"lock")
	ic.modulate = Color.WHITE if bool(r.got) else Color(1, 1, 1, 0.45)
	ic.custom_minimum_size = Vector2(24, 24)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hb.add_child(ic)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override(&"separation", 0)
	hb.add_child(box)
	var t := Label.new()
	t.text = String(r.title)
	t.add_theme_font_size_override(&"font_size", 15)
	t.add_theme_color_override(&"font_color", gold if bool(r.got) else Color(0.2, 0.16, 0.12))
	box.add_child(t)
	var d := Label.new()
	d.name = "Desc"
	d.visible = false # [0.9.5] กดแถวถึงขึ้นคำอธิบาย (ผู้ใช้ 16 พ.ย.)
	var sub := String(r.desc)
	if bool(r.got) and String(r.when) != "":
		sub += " · " + String(r.when)
	elif int(r.target) > 1 and not (bool(r.hidden)):
		sub += " · %d/%d" % [int(r.cur), int(r.target)]
	d.text = sub
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override(&"font_size", 14)
	d.add_theme_color_override(&"font_color", font if bool(r.got) else dim)
	box.add_child(d)
	var arrow := Label.new()
	arrow.text = "▾"
	arrow.add_theme_font_size_override(&"font_size", 14)
	arrow.add_theme_color_override(&"font_color", dim)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(arrow)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			d.visible = not d.visible
			arrow.text = "▴" if d.visible else "▾")
	return p


## ของขวัญส่งท้ายปี (ได้วันเปิดร้านวันสุดท้าย) · ยังไม่ได้ = ไม่ขึ้นหัวข้อ
func _add_gifts() -> void:
	if GameState.gifts_received.is_empty():
		return
	var hd := Label.new()
	hd.name = "GiftHead"
	hd.text = "%s (%d ชิ้น)" % [DecorBook.GIFT_TITLE, GameState.gifts_received.size()]
	hd.add_theme_font_size_override(&"font_size", 15)
	hd.add_theme_color_override(&"font_color", font)
	%List.add_child(hd)
	for npc_id in GameState.gifts_received:
		var d := DecorBook.by_id(StringName(GameState.gifts_received[npc_id]))
		var n := NpcBook.by_id(StringName(npc_id))
		var who := n.display_name if n else String(npc_id)
		%List.add_child(_row({
			"id": "gift_" + String(npc_id), "title": d.title if d else String(GameState.gifts_received[npc_id]),
			"desc": "จาก" + who, "got": true, "when": "", "hidden": false, "cur": 0, "target": 1,
		}))
