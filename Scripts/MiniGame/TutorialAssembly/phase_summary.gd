extends Phase2D
## Phase 4 · SUMMARY — การ์ดกระดาษ: ชิ้นส่วนทั้งหมด ↔ Part ที่จะได้ซ่อม · ปุ่มไปงานซ่อมแรก

var _built := false
var _list: VBoxContainer
var _go: Button


func init():
	if not _built:
		_build()
	for c in _list.get_children():
		c.queue_free()
	for p in owner.parts():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_list.add_child(row)
		var ic := TextureRect.new() # [Claude 10 ต.ค. 2569] รูปชิ้นส่วน (เดิมมีแต่ชื่อ)
		ic.texture = p.texture
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(44, 30)
		row.add_child(ic)
		var a := PhaseUI.label(row, p.data.display_name, 18, PhaseUI.COL_INK)
		a.autowrap_mode = TextServer.AUTOWRAP_OFF
		a.custom_minimum_size.x = 300
		var b := PhaseUI.label(row, "→  " + String(owner.CORE_NAME.get(p.data.core_part, "-")), 18, PhaseUI.COL_HEAD)
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
	var os_row := HBoxContainer.new() # ระบบในเครื่อง — งานบนจอ Lv1
	os_row.add_theme_constant_override("separation", 10)
	_list.add_child(os_row)
	var os_ic := TextureRect.new()
	os_ic.texture = load("res://Assets/MiniGame/Desktop/os_start.png")
	os_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	os_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	os_ic.custom_minimum_size = Vector2(44, 30)
	os_row.add_child(os_ic)
	var oa := PhaseUI.label(os_row, "ระบบ ขมOS", 18, PhaseUI.COL_INK)
	oa.autowrap_mode = TextServer.AUTOWRAP_OFF
	oa.custom_minimum_size.x = 300
	var ob := PhaseUI.label(os_row, "→  งานบนจอ Lv1 · ลงโปรแกรม ลบไฟล์ ถอนโฆษณา", 18, PhaseUI.COL_HEAD)
	ob.autowrap_mode = TextServer.AUTOWRAP_OFF
	_go.disabled = false
	show()
	allow([])
	nav_enabled = false # [Claude 30 ก.ย.] หน้านี้ไม่ต้องสลับมุม
	cam(&"Overview")
	say("ASM_SUMMARY", PibHint.Mood.HAPPY)


func _build() -> void:
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = PhaseUI.SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := PhaseUI.panel(self, Rect2(176, 30, 800, 430), "Card", PhaseUI.COL_PAPER)
	var sb := card.get_theme_stylebox("panel") as StyleBoxFlat
	sb.border_color = PhaseUI.COL_EDGE
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(14)
	var t := PhaseUI.label(card, "ชิ้นส่วนที่ขมจะได้เจอ", 30, PhaseUI.COL_INK)
	t.position = Vector2(40, 20)
	_list = VBoxContainer.new()
	_list.position = Vector2(40, 90)
	_list.size = Vector2(720, 270)
	_list.add_theme_constant_override("separation", 2)
	card.add_child(_list)
	_go = PhaseUI.button(card, "ไปงานซ่อมแรก ►", Rect2(560, 360, 210, 52), _on_go)


func _on_go() -> void:
	if visible:
		_go.disabled = true
		finish()
