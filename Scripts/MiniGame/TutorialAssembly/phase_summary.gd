extends Phase3D
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
		_list.add_child(row)
		var a := PhaseUI.label(row, p.data.display_name, 18, PhaseUI.COL_INK)
		a.autowrap_mode = TextServer.AUTOWRAP_OFF
		a.custom_minimum_size.x = 300
		var b := PhaseUI.label(row, "→  " + String(owner.CORE_NAME.get(p.data.core_part, "-")), 18, PhaseUI.COL_HEAD)
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
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
	_list.size = Vector2(720, 260)
	_list.add_theme_constant_override("separation", 8)
	card.add_child(_list)
	_go = PhaseUI.button(card, "ไปงานซ่อมแรก ►", Rect2(560, 360, 210, 52), _on_go)


func _on_go() -> void:
	if visible:
		_go.disabled = true
		finish()
