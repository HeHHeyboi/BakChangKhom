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


## สร้างแถบหัวข้อ + Info rail ให้ phase แล้วคืน VBoxContainer ใน rail ไว้ใส่ข้อความ
static func make_frame(phase: Control, title: String) -> VBoxContainer:
	phase.set_anchors_preset(Control.PRESET_FULL_RECT)
	phase.position = Vector2.ZERO
	phase.size = SCREEN
	phase.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var header := panel(phase, Rect2(0, 0, SCREEN.x, 56), "Header")
	var t := label(header, title, 26)
	t.position = Vector2(20, 8)

	var rail := panel(phase, RAIL, "InfoRail")
	var box := VBoxContainer.new()
	box.name = "RailBox"
	box.position = Vector2(16, 16)
	box.size = RAIL.size - Vector2(32, 32)
	box.add_theme_constant_override("separation", 10)
	rail.add_child(box)
	return box


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
	return l


static func set_check(l: Label, done: bool) -> void:
	l.text = ("☑ " if done else "☐ ") + String(l.get_meta("text"))
	l.add_theme_color_override("font_color", COL_OK if done else COL_TEXT)


## ให้ปิ๊บพูดข้อความที่ไม่ได้อยู่ในไฟล์บท (เช่น line_* ของ CleanTool)
static func pib_say_text(lines: Array, mood := PibHint.Mood.NORMAL) -> void:
	if Global.cur_pib:
		Global.cur_pib.say(lines, mood)
