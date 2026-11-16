class_name CustomerBookApp extends VBoxContainer
## [Claude 16 พ.ย. 2569 · 0.5.0 ขั้น D] แอป "สมุดลูกค้า" ในคอมของขม (ShopPC ใส่ผ่าน DesktopMinigameV2.add_custom_app)
## แสดงลูกค้าประจำ: รูป · หัวใจ · ระดับ · อีกกี่แต้มถึงระดับถัดไป · เคยซ่อมอะไร · เรื่องที่เคยฟัง · แนะนำตัว (PLAN_0_5_0 ข้อ 3)
## แสดงผลอย่างเดียว ← DayLoop.customer_book_view() · คนที่ยังไม่เคยมาร้านขึ้นเป็น "???"

@export var row_style: StyleBox
@export var font := Color(0.35, 0.2, 0.08)
@export var heart := Color(0.72, 0.25, 0.4)
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
	var dl := get_node_or_null(^"/root/DayLoop")
	if dl == null:
		return
	var v: Dictionary = dl.customer_book_view()
	var h := [GameState.npc_affinity.hash(), GameState.npc_history.hash(), GameState.npc_stories_seen.hash(), GameState.npc_last_visit.hash()].hash()
	if h == _last_hash and not force:
		return
	_last_hash = h
	%Head.text = String(v.get("title", ""))
	for n in %List.get_children():
		%List.remove_child(n)
		n.queue_free()
	for r: Dictionary in v.get("rows", []):
		%List.add_child(_row(r))


func _row(r: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.name = "Row_" + String(r.get("id", ""))
	if row_style:
		p.add_theme_stylebox_override(&"panel", row_style)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 10)
	p.add_child(hb)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(56, 56)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pic.texture = r.get("portrait") as Texture2D
	hb.add_child(pic)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override(&"separation", 1)
	hb.add_child(box)
	var met := bool(r.get("met", false))
	if not met:
		pic.modulate = Color(0, 0, 0, 0.25)
		box.add_child(_label("???", 16, dim))
		box.add_child(_label(String(r.get("hint", "")), 13, dim))
		return p
	box.add_child(_label(String(r.get("name", "")), 16, font, "Name"))
	box.add_child(_label("%s  %s · %s" % [r.get("hearts", ""), r.get("tier", ""), r.get("next", "")], 14, heart, "Hearts"))
	if bool(r.get("story_ready", false)):
		box.add_child(_label("♥ มีเรื่องอยากเล่าให้ฟัง — รอตอนมาที่ร้านครั้งหน้า", 13, heart))
	box.add_child(_label(String(r.get("history", "")), 13, font, "History"))
	if String(r.get("stories", "")) != "":
		box.add_child(_label(String(r["stories"]), 13, font, "Stories"))
	if String(r.get("bio", "")) != "":
		box.add_child(_label(String(r["bio"]), 12, dim))
	return p


func _label(text: String, size: int, col: Color, n := "") -> Label:
	var l := Label.new()
	if n != "":
		l.name = n
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", col)
	return l
