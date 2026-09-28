extends Phase
## Phase 5 · INSTALL — วางแรมให้ร่องบากตรงกับสันในสลอต แล้วกดลงจนสลักดีด
## [Claude 29 ก.ย. 2569] โค้ด + UI เบื้องต้นตาม Docs/STORYBOARD.md R5 และ MINIGAME1_DESIGN.md หัวข้อ 6
## ram_ghost.png ยังไม่มี → ใช้ ram_clean โปร่งแสงแทน · ร่องบากวาดเป็นขีดสีดำบนแรม

const RAM_TEX := "res://Assets/MiniGame/PartRam/ram_clean.png"
const SNAP_DIST := 45.0
const PRESS_NEEDED := 2
const NOTCH_X := 0.42 # ร่องบากไม่อยู่กึ่งกลาง (สัดส่วนจากซ้าย)

var _built := false
var _flipped := false
var _snapped := false
var _dragging := false
var _drag_offset := Vector2.ZERO
var _presses := 0
var _done := false

var _ram: TextureRect
var _notch: ColorRect
var _ghost: TextureRect
var _ram_home := Vector2(170, 70)
var _clips: Array[Label] = []
var _chk_notch: Label
var _chk_clip: Label
var _confirm: Button
var _flip_btn: Button


func init():
	if not _built:
		_build()
	_flipped = randf() < 0.5 # สุ่มให้บางรอบเริ่มกลับด้าน ผู้เล่นต้องสังเกตร่องบากเอง
	_snapped = false
	_dragging = false
	_presses = 0
	_done = false
	_ram.position = _ram_home
	_ram.modulate = Color.WHITE
	_flip_btn.disabled = false
	_confirm.disabled = true
	_apply_flip()
	_set_clips(false)
	PhaseUI.set_check(_chk_notch, false)
	PhaseUI.set_check(_chk_clip, false)
	show()
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.INSTALL))


func _build() -> void:
	_built = true
	var rail := PhaseUI.make_frame(self, "ทำความสะอาดแรม — ขั้นที่ 6/8 · ใส่แรมกลับ")
	PhaseUI.label(rail, "เป้าหมาย", 20, PhaseUI.COL_OK)
	PhaseUI.label(rail, "ลากแรมลงสลอตให้ร่องบากตรง แล้วคลิกแรม 2 ครั้งเพื่อกดลง", 18)
	_chk_notch = PhaseUI.check_item(rail, "ร่องบากตรง")
	_chk_clip = PhaseUI.check_item(rail, "สลักดีดล็อก")
	_flip_btn = Button.new()
	_flip_btn.text = "↻ หมุนแรม"
	_flip_btn.add_theme_font_size_override("font_size", 20)
	_flip_btn.pressed.connect(_on_flip)
	rail.add_child(_flip_btn)

	# สลอต + สันในสลอต (ตำแหน่งสันตรงกับร่องบากตอนวางถูกด้าน)
	PhaseUI.placeholder(self, Rect2(150, 360, 560, 60), Color(0.15, 0.15, 0.18), "ram_slot_empty")
	PhaseUI.placeholder(self, Rect2(150 + 560 * NOTCH_X - 4, 352, 8, 16), Color(0.9, 0.8, 0.2))
	var ghost_pos := Vector2(170, 190)
	_ghost = PhaseUI.texture(self, RAM_TEX, Rect2(ghost_pos, Vector2(520, 185)))
	_ghost.modulate = Color(1, 1, 1, 0.25)
	for x in [100.0, 720.0]:
		var c := PhaseUI.label(self, "", 30)
		c.position = Vector2(x, 330)
		_clips.append(c)

	_ram = PhaseUI.texture(self, RAM_TEX, Rect2(_ram_home, Vector2(520, 185)))
	_ram.mouse_filter = Control.MOUSE_FILTER_STOP
	_ram.mouse_default_cursor_shape = Control.CURSOR_DRAG
	_ram.gui_input.connect(_on_ram_input)
	_notch = ColorRect.new()
	_notch.color = Color.BLACK
	_notch.size = Vector2(10, 22)
	_notch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ram.add_child(_notch)

	_confirm = PhaseUI.button(self, "เสร็จแล้ว ►", Rect2(PhaseUI.CONFIRM_POS, Vector2(140, 50)), _on_confirm)


func _apply_flip() -> void:
	_ram.flip_h = _flipped
	var x := NOTCH_X if not _flipped else 1.0 - NOTCH_X
	_notch.position = Vector2(_ram.size.x * x - 5, _ram.size.y - 22)


func _on_flip() -> void:
	if _snapped:
		return
	_flipped = not _flipped
	_apply_flip()


func _set_clips(closed: bool) -> void:
	_clips[0].text = "▮" if closed else "◣"
	_clips[1].text = "▮" if closed else "◢"


func _on_ram_input(event: InputEvent) -> void:
	if not visible or _done:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) and not event is InputEventMouseMotion:
		return
	if _snapped:
		# วางลงร่องแล้ว — คลิกแรม = กดลง
		if event is InputEventMouseButton and event.pressed:
			_press()
		return
	if event is InputEventMouseButton:
		if event.pressed:
			_dragging = true
			_drag_offset = _ram.position - event.global_position
		elif _dragging:
			_dragging = false
			_on_drop()
	elif _dragging:
		_ram.position = event.global_position + _drag_offset


func _on_drop() -> void:
	if _ram.position.distance_to(_ghost.position) > SNAP_DIST:
		return
	if _flipped:
		# กลับด้าน → แดงจาง วางไม่ลง
		_ram.modulate = Color(1, 0.5, 0.5)
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.INSTALL_FLIPPED))
		var tw := create_tween()
		tw.tween_property(_ram, "position", _ram_home, 0.3)
		tw.tween_property(_ram, "modulate", Color.WHITE, 0.3)
		return
	_snapped = true
	_ram.position = _ghost.position
	_ram.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_flip_btn.disabled = true
	_confirm.disabled = false
	PhaseUI.set_check(_chk_notch, true)


func _press() -> void:
	_presses += 1
	var tw := create_tween()
	tw.tween_property(_ram, "position:y", _ghost.position.y + 10, 0.06)
	tw.tween_property(_ram, "position:y", _ghost.position.y + 4 * _presses, 0.06)
	if _presses >= PRESS_NEEDED:
		_set_clips(true)
		PhaseUI.set_check(_chk_clip, true)
		owner.ram_seated = true
		_done = true
		tw.tween_interval(0.4)
		tw.tween_callback(_finish)


## กด "เสร็จแล้ว" ก่อนสลักดีด = ใส่ไม่สุด → VERIFY บูตไม่ผ่าน + หักความเรียบร้อย
func _on_confirm() -> void:
	if _done or not _snapped:
		return
	_done = true
	owner.ram_seated = _presses >= PRESS_NEEDED
	_finish()


func _finish() -> void:
	hide()
	phase_completed.emit()
