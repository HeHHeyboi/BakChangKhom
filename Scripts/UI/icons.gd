class_name Icons
extends RefCounted
## ไอคอนเล็กวาดเอง แทนอีโมจิ (เวอร์ชันเว็บไม่มีฟอนต์อีโมจิ → อีโมจิขึ้นเป็นกล่อง) · [Claude 20 ต.ค. 2569]
## ภาพ: Assets/UI/Icons/icon_<id>.png 64×64 · ต้นฉบับ SVG + ตัวสร้าง: Assets/UI/Icons/src/gen_icons.py
## id: clock · clipboard · phone · star · lock · download · speaker · book · shelf
## ขนาด: ส่ง px = ขนาดฟอนต์ของข้อความข้าง ๆ → ไอคอนสูงเท่าตัวอักษร (เท่าอีโมจิเดิม)

const DIR := "res://Assets/UI/Icons/"


static func path(id: StringName) -> String:
	return DIR + "icon_%s.png" % id


static func tex(id: StringName) -> Texture2D:
	return load(path(id)) as Texture2D


static var _cache: Dictionary = { } # "id@px" -> ImageTexture


## ภาพย่อเหลือ px×px จริง (ไม่ใช่แค่วาดย่อ) → ปุ่มไม่ขยายตามภาพ 64px และภาพเล็กคมกว่า
static func sized(id: StringName, px: int) -> Texture2D:
	var key := "%s@%d" % [id, px]
	if _cache.has(key):
		return _cache[key]
	var img := tex(id).get_image()
	if img.is_compressed():
		img.decompress()
	img.resize(px, px, Image.INTERPOLATE_LANCZOS)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## ใส่ไอคอนหน้าข้อความของปุ่ม · px <= 0 = ใช้ขนาดฟอนต์ของปุ่ม
static func on_button(b: Button, id: StringName, px: int = 0) -> Button:
	if px <= 0:
		px = b.get_theme_font_size(&"font_size") + 2
	b.icon = sized(id, px)
	b.expand_icon = false
	b.add_theme_constant_override(&"h_separation", 6)
	# ไอคอนชิดซ้ายเสมอ (Godot) → ให้ข้อความชิดตามไอคอน ไม่ลอยไปกลางปุ่ม
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return b


## [8 พ.ย. 2569] [ไอคอน ข้อความ] เป็นกลุ่มเดียวกันกลางปุ่ม (Godot วางไอคอนชิดขอบซ้ายเสมอถ้าจัดข้อความกลาง)
## ข้อความย้ายไปอยู่ใน Label ลูก "IconRow" · สีตัวอักษรตามสถานะปุ่ม (ปกติ/ชี้/กด) · อ่านข้อความเดิมได้จาก get_meta("label")
static func on_button_center(b: Button, id: StringName, px: int = 0) -> Button:
	if px <= 0:
		px = b.get_theme_font_size(&"font_size") + 2
	var old := b.get_node_or_null(^"IconRow")
	if old:
		old.queue_free()
	var lbl := Label.new()
	lbl.text = b.text
	lbl.add_theme_font_size_override(&"font_size", b.get_theme_font_size(&"font_size"))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(rect(id, px))
	h.add_child(lbl)
	var c := CenterContainer.new()
	c.name = "IconRow"
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# เว้นขอบล่างให้เท่าขอบในของปุ่ม (ปุ่มลายไม้ขอบบน 15 ล่าง 9)
	var sb := b.get_theme_stylebox(&"normal")
	if sb:
		c.offset_top = sb.content_margin_top - sb.content_margin_bottom
	c.add_child(h)
	b.set_meta(&"label", b.text)
	b.text = ""
	b.icon = null
	b.add_child(c)
	var col := func(state: StringName) -> void:
		lbl.add_theme_color_override(&"font_color", b.get_theme_color(state))
	col.call(&"font_color")
	b.mouse_entered.connect(func() -> void: col.call(&"font_hover_color"))
	b.mouse_exited.connect(func() -> void: col.call(&"font_color"))
	b.button_down.connect(func() -> void: col.call(&"font_pressed_color"))
	b.button_up.connect(func() -> void: col.call(&"font_hover_color" if b.is_hovered() else &"font_color"))
	return b


## TextureRect สี่เหลี่ยม px×px ไว้วางหน้า Label ใน HBoxContainer
static func rect(id: StringName, px: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = sized(id, px)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## แถว [ไอคอน][ข้อความ] — คืน HBox · ข้อความอยู่ที่ get_meta("label")
static func row(id: StringName, label: Label, px: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", maxi(4, int(px / 4.0)))
	h.add_child(rect(id, px))
	h.add_child(label)
	h.set_meta(&"label", label)
	return h


## ดาว n ดวงเรียงกัน (เกรดหลังจบงาน)
static func stars(n: int, px: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override(&"separation", 2)
	for i in n:
		h.add_child(rect(&"star", px))
	return h
