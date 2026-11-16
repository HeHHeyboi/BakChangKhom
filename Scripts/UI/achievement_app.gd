class_name AchievementApp extends VBoxContainer
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น J] แอป "ใบประกาศ" ในคอมของขม (ShopPC ใส่ผ่าน DesktopMinigameV2.add_custom_app)
## แสดงผลอย่างเดียว ← Achievements.view() · แยกหมวด · ได้แล้ว = วันที่ได้ · ยังไม่ได้ = ความคืบหน้า · ใบลับ = ???

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
	var h := (str(v) + str(GameState.ach_pinned)).hash()
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
	if bool(r.got):
		sub += " · " + String(r.when)
	elif int(r.target) > 1 and not (bool(r.hidden)):
		sub += " · %d/%d" % [int(r.cur), int(r.target)]
	if String(r.reward) != "" and (bool(r.got) or not bool(r.hidden)):
		sub += " · รางวัล: " + String(r.reward)
	d.text = sub
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override(&"font_size", 12)
	d.add_theme_color_override(&"font_color", font if bool(r.got) else dim)
	box.add_child(d)
	if bool(r.got): # ติดผนังร้านได้ 3 ใบ
		var pinned := GameState.ach_pinned.has(String(r.id))
		var b := Button.new()
		b.name = "Pin"
		b.text = "เอาลง" if pinned else "ติดผนัง"
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = not pinned and GameState.ach_pinned.size() >= 3
		b.tooltip_text = "ติดผนังร้านได้ 3 ใบ"
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override(&"font_size", 13)
		b.pressed.connect(_toggle_pin.bind(String(r.id)))
		hb.add_child(b)
	return p


func _toggle_pin(id: String) -> void:
	if GameState.ach_pinned.has(id):
		GameState.ach_pinned.erase(id)
	elif GameState.ach_pinned.size() < 3:
		GameState.ach_pinned.append(id)
	refresh(true)
