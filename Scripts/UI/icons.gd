class_name Icons
extends RefCounted
## ไอคอนเล็กวาดเอง แทนอีโมจิ (เวอร์ชันเว็บไม่มีฟอนต์อีโมจิ → อีโมจิขึ้นเป็นกล่อง) · [Claude 20 ต.ค. 2569]
## ภาพ: Assets/UI/Icons/icon_<id>.png 64×64 · ต้นฉบับ SVG + ตัวสร้าง: Assets/UI/Icons/src/gen_icons.py
## id: clock · clipboard · phone · star · lock · download · speaker · book
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
