class_name PhaseUI extends RefCounted
## ตัวช่วยสร้าง UI เบื้องต้น (placeholder) ตามเลย์เอาต์กลางใน Docs/STORYBOARD.md หัวข้อ 0
##   แถบหัวข้อ y 0–56 · Play area x 0–860 / y 56–476 · Info rail x 860–1152 / y 56–476 · แถบปิ๊บ y 476–648 (PibHint)
## เขียนโดย Claude 29 ก.ย. 2569 — เมื่อมีรูปจริงแล้วจะย้าย node ไปวางใน Editor แทนก็ได้ ฟังก์ชันพวกนี้แค่ช่วยให้เล่นได้ก่อน

const SCREEN := Vector2(1152, 648)
const PLAY := Rect2(0, 56, 860, 420)
const RAIL := Rect2(860, 56, 292, 420)
const CONFIRM_POS := Vector2(700, 410)

const COL_PANEL := Color(0.10, 0.10, 0.12, 0.78)
const COL_TEXT := Color(1, 1, 1)
const COL_OK := Color(0.45, 0.85, 0.45)
const COL_BAD := Color(0.95, 0.35, 0.35)
const COL_GOAL := Color(1.0, 0.86, 0.45)

## สมุดคู่มือ (30 ก.ย.) — ไอคอนหนังสือมุมขวาบน · กดแล้วเปิดหน้ากระดาษกลางจอ (แนว Volcano Princess)
##   ในสมุด: 1) ภาพฉากตอนนี้ + วงกลมตรงที่ต้องคลิก 2) ขั้นตอน ☑/☐ 3) บันทึกของปิ๊บ
##   แถบหัวข้อโชว์ "เป้าหมาย" = ข้อแรกในเช็กลิสต์ที่ยังไม่ติ๊ก → ผู้เล่นรู้ว่าต้องทำอะไรโดยไม่ต้องเปิดสมุด
##   แผงข้าง (Info rail) โชว์เฉพาะตอนมีปุ่ม/อุปกรณ์ให้กด · ไม่มี → ซ่อน และขยายฉาก 3D เต็มความกว้างจอ
const BOOK_ICON := "res://Assets/MiniGame/PartCommon/ui_icon_guidebook.png"
const BOOK_RECT := Rect2(1092, 4, 48, 48)


## สร้างแถบหัวข้อ + Info rail ให้ phase แล้วคืน VBoxContainer ใน rail ไว้ใส่ข้อความ
static func make_frame(phase: Control, title: String) -> VBoxContainer:
	phase.set_anchors_preset(Control.PRESET_FULL_RECT)
	phase.position = Vector2.ZERO
	phase.size = SCREEN
	phase.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var header := panel(phase, Rect2(0, 0, SCREEN.x, 56), "Header")
	var t := label(header, title, 24)
	t.position = Vector2(20, 10)
	phase.set_meta("title_label", t)
	var goal := label(header, "", 20, COL_GOAL)
	goal.name = "Goal"
	goal.position = Vector2(500, 14)

	var rail := panel(phase, RAIL, "InfoRail")
	var box := VBoxContainer.new()
	box.name = "RailBox"
	box.position = Vector2(16, 16)
	box.size = RAIL.size - Vector2(32, 32)
	box.add_theme_constant_override("separation", 10)
	rail.add_child(box)
	box.set_meta("phase", phase)
	phase.set_meta("rail", rail)
	phase.set_meta("rail_box", box)
	phase.set_meta("goal", goal)
	phase.set_meta("book", _make_book(phase, header))
	phase.visibility_changed.connect(func():
		if phase.visible:
			_auto_rail.call_deferred(phase))
	_auto_rail.call_deferred(phase) # ครั้งแรก phase โชว์ก่อนสร้าง frame → สัญญาณข้างบนยังไม่ทันต่อ
	return box


static func _make_book(phase: Control, header: Control) -> TextureButton:
	var b := TextureButton.new()
	b.name = "GuideBook"
	if ResourceLoader.exists(BOOK_ICON):
		b.texture_normal = load(BOOK_ICON)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.position = BOOK_RECT.position
	b.size = BOOK_RECT.size
	b.pivot_offset = BOOK_RECT.size / 2
	b.tooltip_text = "สมุดคู่มือ — ต้องทำอะไรบ้าง"
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	header.add_child(b)
	var dot := panel(b, Rect2(34, -2, 16, 16), "Badge", COL_BAD)
	dot.visible = false
	b.pressed.connect(func(): open_book(phase))
	return b


## เปิด/ปิดสมุด (Info rail)
static func set_rail_open(phase: Control, open: bool) -> void:
	if not phase.has_meta("rail"):
		return
	var rail := phase.get_meta("rail") as Control
	rail.visible = open
	var book := phase.get_meta("book") as Control
	if open:
		phase.set_meta("unread", false)
		book.get_node("Badge").visible = false
		rail.modulate.a = 0.0
		phase.create_tween().tween_property(rail, "modulate:a", 1.0, 0.15)


## มีของให้กดใน rail → เปิด · มีแต่ข้อความ → ปิด + ฉาก 3D กว้างเต็มจอ (เห็นเครื่องชัดสุด)
static func refresh(phase: Control) -> void:
	_auto_rail(phase)


static func _auto_rail(phase: Control) -> void:
	if not phase.has_meta("rail") or not phase.visible:
		return
	var rail := phase.get_meta("rail") as Node
	var open := _has_button(rail)
	set_rail_open(phase, open)
	var st = phase.owner.get("stage") if phase.owner else null
	if st is Control:
		(st as Control).size.x = RAIL.position.x if open else SCREEN.x
	if phase.get_meta("unread", false):
		ping_book(phase)
	_refresh_goal(phase.get_meta("rail_box"))


static func _has_button(n: Node) -> bool:
	for c in n.get_children():
		if c is CanvasItem and not c.visible:
			continue
		if c is BaseButton or _has_button(c):
			return true
	return false


## เด้งไอคอนหนังสือ + จุดแดง (มีของใหม่ในสมุด)
static func ping_book(phase: Control) -> void:
	if not phase.has_meta("book"):
		return
	var book := phase.get_meta("book") as Control
	if (phase.get_meta("rail") as Control).visible:
		return
	book.get_node("Badge").visible = true
	var tw := phase.create_tween()
	tw.tween_property(book, "scale", Vector2(1.3, 1.3), 0.12)
	tw.tween_property(book, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


## ตั้งข้อความเป้าหมายบนแถบหัวข้อเอง (phase ที่ไม่มีเช็กลิสต์)
static func set_goal(phase: Control, text: String) -> void:
	if phase.has_meta("goal"):
		(phase.get_meta("goal") as Label).text = ("▶ " + text) if text != "" else ""


static func _refresh_goal(box: Node) -> void:
	if box == null or not box.has_meta("phase"):
		return
	var items := 0
	for c in box.get_children():
		if c is Label and c.has_meta("text"):
			items += 1
			if not c.get_meta("done", false):
				set_goal(box.get_meta("phase"), String(c.get_meta("text")))
				return
	if items > 0:
		set_goal(box.get_meta("phase"), "เรียบร้อย ✓")


## บันทึกของปิ๊บในสมุด — บทยาว ๆ ย้ายมาอยู่ที่นี่แทนการให้คลิกผ่านทีละบรรทัด
static func note(phase: Control, lines: Array) -> void:
	if not phase.has_meta("rail_box"):
		return
	var box := phase.get_meta("rail_box") as VBoxContainer
	if box.get_node_or_null("NotesTitle") == null:
		label(box, "บันทึกของปิ๊บ", 18, COL_GOAL).name = "NotesTitle"
	var seen: Array = phase.get_meta("notes", [])
	for line in lines:
		if seen.has(line):
			continue
		seen.append(line)
		label(box, "• " + String(line), 15)
	phase.set_meta("notes", seen)
	phase.set_meta("unread", true)
	ping_book(phase)


static func panel(parent: Node, rect: Rect2, p_name := "Panel", color := COL_PANEL) -> Panel:
	var p := Panel.new()
	p.name = p_name
	p.position = rect.position
	p.size = rect.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


static func label(parent: Node, text: String, font_size := 20, color := COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	# ตัดบรรทัดเฉพาะตอนอยู่ใน Container (ได้ความกว้างจาก Container) — label ลอย ๆ ไม่มีความกว้างจะตัดทีละตัวอักษร
	if parent is Container:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


static func button(parent: Node, text: String, rect: Rect2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## กล่องสีทึบแทนรูปที่ยังไม่มี (ชื่อไฟล์รูปจริงเขียนไว้ในกล่อง)
static func placeholder(parent: Node, rect: Rect2, color: Color, caption := "") -> ColorRect:
	var c := ColorRect.new()
	c.position = rect.position
	c.size = rect.size
	c.color = color
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	if caption != "":
		var l := label(c, caption, 14, Color(1, 1, 1, 0.7))
		l.position = Vector2(6, 4)
	return c


static func texture(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(path):
		t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = rect.position
	t.size = rect.size
	t.pivot_offset = rect.size / 2
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


## เช็กลิสต์ใน rail: คืน Label ไว้เรียก set_check() ทีหลัง
static func check_item(box: VBoxContainer, text: String) -> Label:
	var l := label(box, "☐ " + text, 18)
	l.set_meta("text", text)
	_refresh_goal(box)
	return l


static func set_check(l: Label, done: bool) -> void:
	l.text = ("☑ " if done else "☐ ") + String(l.get_meta("text"))
	l.add_theme_color_override("font_color", COL_OK if done else COL_TEXT)
	l.set_meta("done", done)
	_refresh_goal(l.get_parent())


## ให้ปิ๊บพูดข้อความที่ไม่ได้อยู่ในไฟล์บท (เช่น line_* ของ CleanTool)
static func pib_say_text(lines: Array, mood := PibHint.Mood.NORMAL) -> void:
	if Global.cur_pib:
		Global.cur_pib.say(lines, mood)


# ---------------------------------------------------------------- หน้าสมุดคู่มือ (popup)

const COL_PAPER := Color(0.97, 0.92, 0.80)
const COL_EDGE := Color(0.55, 0.36, 0.18)
const COL_INK := Color(0.25, 0.16, 0.08)
const COL_HEAD := Color(0.85, 0.50, 0.15)
const BOOK_SIZE := Vector2(620, 580)


static func open_book(phase: Control) -> void:
	if phase.get_node_or_null("BookPage"):
		return
	phase.set_meta("unread", false)
	(phase.get_meta("book") as Control).get_node("Badge").visible = false
	var layer := CanvasLayer.new() # อยู่เหนือแถบปิ๊บ (PibHint เป็น CanvasLayer)
	layer.name = "BookPage"
	layer.layer = 128
	layer.add_to_group("modal") # ViewNav ไม่รับ Esc ตอนสมุดเปิด
	phase.add_child(layer)
	var root := Control.new()
	root.size = SCREEN
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.tree_exited.connect(layer.queue_free)
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: root.queue_free())
	root.add_child(dim)

	var page := Panel.new()
	page.position = (SCREEN - BOOK_SIZE) / 2 - Vector2(0, 10)
	page.size = BOOK_SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PAPER
	sb.border_color = COL_EDGE
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(14)
	sb.shadow_size = 10
	sb.shadow_color = Color(0, 0, 0, 0.4)
	page.add_theme_stylebox_override("panel", sb)
	root.add_child(page)
	for c in [Vector2(10, 10), Vector2(BOOK_SIZE.x - 34, 10), Vector2(10, BOOK_SIZE.y - 34), Vector2(BOOK_SIZE.x - 34, BOOK_SIZE.y - 34)]:
		var o := ColorRect.new() # มุมตกแต่ง (placeholder — แทนด้วยรูปได้)
		o.color = Color(COL_HEAD, 0.55)
		o.position = c
		o.size = Vector2(24, 24)
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.add_child(o)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(36, 26)
	scroll.size = BOOK_SIZE - Vector2(72, 100)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = scroll.size.x - 14
	v.add_theme_constant_override("separation", 8)
	scroll.add_child(v)

	var box := phase.get_meta("rail_box") as Node
	var title := String((phase.get_meta("title_label") as Label).text) if phase.has_meta("title_label") else "สมุดคู่มือ"
	_book_label(v, title.get_slice("·", title.get_slice_count("·") - 1).strip_edges(), 28, COL_INK, true)
	_book_label(v, (phase.get_meta("goal") as Label).text, 18, COL_HEAD, true)

	_book_label(v, "1. ตอนนี้ต้องทำตรงนี้", 22, COL_HEAD)
	_book_snapshot(phase, v)

	var steps := []
	var notes := []
	for c in box.get_children():
		if c is Label and c.has_meta("text"):
			steps.append(("✔ " if c.get_meta("done", false) else "☐ ") + String(c.get_meta("text")))
	for n in phase.get_meta("notes", []):
		notes.append("• " + String(n))
	if not steps.is_empty():
		_book_label(v, "2. ขั้นตอน", 22, COL_HEAD)
		for t in steps:
			_book_label(v, t, 18, COL_OK.darkened(0.35) if t.begins_with("✔") else COL_INK)
	if not notes.is_empty():
		_book_label(v, ("3" if not steps.is_empty() else "2") + ". ปิ๊บบอกว่า", 22, COL_HEAD)
		for t in notes:
			_book_label(v, t, 16, COL_INK)

	var close := Button.new()
	close.text = "ปิด"
	close.add_theme_font_size_override("font_size", 22)
	close.add_theme_color_override("font_color", COL_PAPER)
	var cb := StyleBoxFlat.new()
	cb.bg_color = COL_HEAD
	cb.border_color = COL_EDGE
	cb.set_border_width_all(3)
	cb.set_corner_radius_all(12)
	close.add_theme_stylebox_override("normal", cb)
	close.add_theme_stylebox_override("hover", cb)
	close.add_theme_stylebox_override("pressed", cb)
	close.size = Vector2(160, 48)
	close.position = Vector2((BOOK_SIZE.x - 160) / 2, BOOK_SIZE.y - 66)
	close.pressed.connect(root.queue_free)
	page.add_child(close)
	root.modulate.a = 0.0
	phase.create_tween().tween_property(root, "modulate:a", 1.0, 0.15)


static func _book_label(v: Container, text: String, fs: int, col: Color, center := false) -> Label:
	var l := label(v, text, fs, col)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## ภาพฉาก 3D ตอนนี้ (snapshot) + วงกลมตรงชิ้นที่ต้องคลิก (จาก Phase3D.hint)
static func _book_snapshot(phase: Control, v: Container) -> void:
	var st = phase.owner.get("stage") if phase.owner else null
	if not (st is PartStage3D):
		return
	var img: Image = st.viewport.get_texture().get_image()
	var w: float = v.custom_minimum_size.x
	var h: float = w * img.get_height() / img.get_width()
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(w, h)
	var fsb := StyleBoxFlat.new()
	fsb.bg_color = Color(0.2, 0.2, 0.22)
	fsb.border_color = COL_EDGE
	fsb.set_border_width_all(3)
	frame.add_theme_stylebox_override("panel", fsb)
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(frame)
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size = Vector2(w, h)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(tr)
	var t = phase.get_meta("hint_target", null)
	if t is Node3D and is_instance_valid(t):
		var p: Vector2 = st.camera.unproject_position(t.global_position)
		var m := GuideMarker.new()
		m.text = ""
		m.radius = 20
		m.position = p * Vector2(w, h) / Vector2(st.viewport.size)
		frame.add_child(m)
		m.top_level = false


# ---------------------------------------------------------------- การ์ดชิ้นส่วน [30 ก.ย.]

const CARD_RECT := Rect2(16, 300, 440, 168)


## การ์ดกระดาษมุมซ้ายล่างของฉาก: ชื่อชิ้น · หน้าที่ · "จะได้ซ่อมใน Part ___" (footer ว่าง = ไม่โชว์)
static func part_card(phase: Control, title: String, body: String, footer := "") -> Panel:
	var old := phase.get_node_or_null("PartCard")
	if old:
		old.free()
	var p := Panel.new()
	p.name = "PartCard"
	p.position = CARD_RECT.position
	p.size = CARD_RECT.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PAPER
	sb.border_color = COL_EDGE
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(12)
	p.add_theme_stylebox_override("panel", sb)
	phase.add_child(p)
	var v := VBoxContainer.new()
	v.position = Vector2(18, 12)
	v.size = CARD_RECT.size - Vector2(36, 24)
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	label(v, title, 22, COL_HEAD)
	label(v, body, 16, COL_INK)
	if footer != "":
		label(v, footer, 16, COL_OK.darkened(0.4))
	p.modulate.a = 0.0
	phase.create_tween().tween_property(p, "modulate:a", 1.0, 0.15)
	return p


static func hide_card(phase: Control) -> void:
	var old := phase.get_node_or_null("PartCard")
	if old:
		old.queue_free()
