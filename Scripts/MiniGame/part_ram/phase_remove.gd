extends Phase
## Phase 3 · REMOVE — ปลดสลักซ้าย/ขวา แล้วลากแรมขึ้นตรง ๆ
## [Claude 29 ก.ย. 2569] โค้ด + UI เบื้องต้นตาม Docs/STORYBOARD.md R3 และ MINIGAME1_DESIGN.md หัวข้อ 6
## รูปที่ยังไม่มี (ram_slot_empty / ram_clip_closed / ram_clip_open) ใช้กล่องสีแทน — ดู ASSET_NAMING.md

const RAM_TEX := "res://Assets/MiniGame/PartRam/ram_dirty.png"
const PULL_DISTANCE := 80.0 # ต้องลากขึ้นอย่างน้อยเท่านี้
const TILT_LIMIT := 40.0 # เมาส์เบี่ยงแกน x เกินนี้ = ดึงเอียง

var _built := false
var _left_open := false
var _right_open := false
var _dragging := false
var _drag_start := Vector2.ZERO
var _max_tilt := 0.0
var _warned_force := false
var _warned_tilt := false
var _done := false

@export var ram: TextureRect
var _ram_home := Vector2.ZERO
@export var clip_left: Button
@export var clip_right: Button
var _chk_left: Label
var _chk_right: Label
var _chk_pull: Label


func init():
	# if not _built:
	# _build()
	self.show()
	pib_toggle.emit(PibHint.Data.say(MinigameHeader.REMOVE))
	ram.mouse_filter = Control.MOUSE_FILTER_STOP
	ram.mouse_default_cursor_shape = Control.CURSOR_DRAG
	ram.gui_input.connect(_on_ram_input)

	var rail := PhaseUI.make_frame(self, "ทำความสะอาดแรม — ขั้นที่ 4/8 · ถอดแรม")
	PhaseUI.label(rail, "เป้าหมาย", 20, PhaseUI.COL_OK)
	PhaseUI.label(rail, "ปลดสลักทั้งสองข้าง แล้วลากแรมขึ้นตรง ๆ", 18)
	_chk_left = PhaseUI.check_item(rail, "สลักซ้าย")
	_chk_right = PhaseUI.check_item(rail, "สลักขวา")
	_chk_pull = PhaseUI.check_item(rail, "ดึงแรมขึ้น")
	clip_left.pressed.connect(self._on_clip_left)
	clip_right.pressed.connect(self._on_clip_right)

	_update_clips()
	_left_open = false
	_right_open = false
	_dragging = false
	_done = false
	_warned_force = false
	_warned_tilt = false
	_ram_home = ram.position
	ram.modulate = Color.WHITE


func _on_clip_left() -> void:
	_left_open = true
	_update_clips()


func _on_clip_right() -> void:
	_right_open = true
	_update_clips()


const LOCK_TEXT = "▮\nล็อก"
const OPEN_TEXT = "◣\nเปิด"


func _update_clips() -> void:
	clip_left.text = OPEN_TEXT if _left_open else LOCK_TEXT
	clip_right.text = OPEN_TEXT if _right_open else LOCK_TEXT
	PhaseUI.set_check(_chk_left, _left_open)
	PhaseUI.set_check(_chk_right, _right_open)
	PhaseUI.set_check(_chk_pull, _done)


func _on_ram_input(event: InputEvent) -> void:
	if not visible or _done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start = event.global_position
			_max_tilt = 0.0
		elif _dragging:
			_dragging = false
			_on_release(event.global_position)
	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = event.global_position - _drag_start
		_max_tilt = max(_max_tilt, abs(delta.x))
		var lift := clampf(-delta.y, 0.0, 160.0)
		# สลักยังปิด → ขยับได้นิดเดียว (รู้สึกว่าติด)
		if not (_left_open and _right_open):
			lift = min(lift, 12.0)
		ram.position = _ram_home + Vector2(clampf(delta.x, -20, 20), -lift)


func _on_release(mouse_pos: Vector2) -> void:
	var lifted := _ram_home.y - ram.position.y
	var raw_lift := _drag_start.y - mouse_pos.y
	if not (_left_open and _right_open):
		if raw_lift > 20.0:
			pib_toggle.emit(PibHint.Data.toast(MinigameHeader.REMOVE_FORCE))
			if not _warned_force:
				_warned_force = true
				mistake.emit(&"handling", 5)
			_shake()
		_snap_back()
		return
	if _max_tilt > TILT_LIMIT:
		pib_toggle.emit(PibHint.Data.toast(MinigameHeader.REMOVE_TILTED))
		if not _warned_tilt:
			_warned_tilt = true
			mistake.emit(&"handling", 5)
		_snap_back()
		return
	if lifted >= PULL_DISTANCE:
		_done = true
		_update_clips()
		var tw := create_tween()
		tw.tween_property(ram, "position:y", _ram_home.y - 220, 0.35)
		tw.tween_interval(0.3)
		tw.tween_callback(_finish)
	else:
		_snap_back()


func _snap_back() -> void:
	create_tween().tween_property(ram, "position", _ram_home, 0.2)


func _shake() -> void:
	var tw := create_tween()
	for i in 3:
		tw.tween_property(ram, "position:x", _ram_home.x + 8, 0.04)
		tw.tween_property(ram, "position:x", _ram_home.x - 8, 0.04)
	tw.tween_property(ram, "position:x", _ram_home.x, 0.04)


func _finish() -> void:
	hide()
	phase_completed.emit()
