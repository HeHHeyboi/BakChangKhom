class_name AchievementApp extends VBoxContainer
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น J] หน้า "ความสำเร็จ" (ใบประกาศ)
## [0.9.0 ขั้น 0] ย้ายจากแอปในคอมขมมาอยู่ในเมนูพัก (PauseMenu → ความสำเร็จ) ที่เดียว · ไม่มีติดผนัง/รางวัลของตกแต่งแล้ว
## แสดงผลอย่างเดียว ← Achievements.view() · แยกหมวด · ได้แล้ว = วันที่ได้ · ยังไม่ได้ = ความคืบหน้า · ใบลับ = ???
## ท้ายหน้า = ของขวัญส่งท้ายปีที่ได้รับ (GameState.gifts_received)

@export var row_style: StyleBox
@export var font := Color(0.35, 0.2, 0.08)
@export var gold := Color(0.62, 0.42, 0.08)
@export var dim := Color(0.55, 0.5, 0.44)

var _last_hash := 0
var _t := 0.0


func _ready() -> void:
	refresh()


func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.5:
		_t = 0.0
		refresh()


func refresh(force := false) -> void:
	var a := get_node_or_null(^"/root/Achievements")
	if a == null:
		return
	var v: Dictionary = a.view()
	var h := (str(v) + str(GameState.gifts_received)).hash()
	if h == _last_hash and not force:
		return
	_last_hash = h
	%Head.text = String(v.get("title", ""))
	for n in %List.get_children():
		%List.remove_child(n)
		n.queue_free()
	var cat := ""
	for r: Dictionary in v.get("rows", []):
		if String(r.category) != cat:
			cat = String(r.category)
			var hd := Label.new()
			hd.text = cat
			hd.add_theme_font_size_override(&"font_size", 15)
			hd.add_theme_color_override(&"font_color", font)
			%List.add_child(hd)
		%List.add_child(_row(r))
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
	ic.custom_minimum_size = Vector2(34, 34)
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
	var sub := String(r.desc)
	if bool(r.got) and String(r.when) != "":
		sub += " · " + String(r.when)
	elif int(r.target) > 1 and not (bool(r.hidden)):
		sub += " · %d/%d" % [int(r.cur), int(r.target)]
	d.text = sub
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override(&"font_size", 12)
	d.add_theme_color_override(&"font_color", font if bool(r.got) else dim)
	box.add_child(d)
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
