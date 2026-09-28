extends Phase
## Phase 6 · VERIFY — เสียบปลั๊ก กดเปิดเครื่อง รอ 2 วิ ดูผล
## [Claude 29 ก.ย. 2569] โค้ด + UI เบื้องต้นตาม Docs/STORYBOARD.md R6 และ MINIGAME1_DESIGN.md หัวข้อ 7
## อ่านผลจาก owner.ram_damaged (CLEAN) และ owner.ram_seated (INSTALL)
## หมายเหตุ: VERIFY_NO_POWER_CUT ไม่ถูกใช้ เพราะ Power Off บังคับลำดับไว้ ลืมถอดปลั๊กไม่ได้

const BOOT_TIME := 2.0

var _built := false
var _plugged := false
var _booting := false
var _result_shown := false

var _screen: ColorRect
var _screen_label: Label
var _plug_btn: Button
var _power_btn: Button
var _chk_plug: Label
var _chk_boot: Label
var _result: Label


func init():
	if not _built:
		_build()
	if not owner.pib.all_lines_finished.is_connected(_on_pib_done):
		owner.pib.all_lines_finished.connect(_on_pib_done)
	_plugged = false
	_booting = false
	_result_shown = false
	_screen.color = Color(0.05, 0.05, 0.05)
	_screen_label.text = ""
	_plug_btn.text = "เสียบปลั๊ก"
	_plug_btn.disabled = false
	_power_btn.disabled = false
	_result.text = ""
	PhaseUI.set_check(_chk_plug, false)
	PhaseUI.set_check(_chk_boot, false)
	show()
	PhaseUI.pib_say_text(["ใส่กลับเรียบร้อยแล้ว เสียบปลั๊กแล้วลองเปิดเครื่องดูกัน"])


func _build() -> void:
	_built = true
	var rail := PhaseUI.make_frame(self, "ทำความสะอาดแรม — ขั้นที่ 7/8 · ตรวจผล")
	PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
	_chk_plug = PhaseUI.check_item(rail, "เสียบปลั๊ก")
	_chk_boot = PhaseUI.check_item(rail, "เปิดเครื่อง")
	_power_btn = Button.new()
	_power_btn.text = "เปิดเครื่อง"
	_power_btn.add_theme_font_size_override("font_size", 22)
	_power_btn.custom_minimum_size = Vector2(0, 64)
	_power_btn.pressed.connect(_on_power)
	rail.add_child(_power_btn)
	_result = PhaseUI.label(rail, "", 20)

	# จอ (placeholder ของ ram_screen_normal / ram_screen_glitch 520×340)
	PhaseUI.placeholder(self, Rect2(160, 80, 540, 330), Color(0.2, 0.2, 0.22)) # กรอบจอ
	_screen = PhaseUI.placeholder(self, Rect2(180, 100, 500, 290), Color(0.05, 0.05, 0.05))
	_screen_label = PhaseUI.label(_screen, "", 56)
	_screen_label.size = _screen.size
	_screen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_screen_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_plug_btn = PhaseUI.button(self, "", Rect2(30, 410, 200, 56), _on_plug)


func _on_plug() -> void:
	if _plugged:
		return
	_plugged = true
	_plug_btn.text = "เสียบแล้ว"
	_plug_btn.disabled = true
	PhaseUI.set_check(_chk_plug, true)


func _on_power() -> void:
	if not visible or _booting or _result_shown:
		return
	if not _plugged:
		PhaseUI.pib_say_text(["ยังไม่ได้เสียบปลั๊กเลยนะขม"], PibHint.Mood.WORRY)
		return
	_booting = true
	_power_btn.disabled = true
	PhaseUI.set_check(_chk_boot, true)
	_screen.color = Color(0.1, 0.1, 0.3)
	_screen_label.text = "..."
	await get_tree().create_timer(BOOT_TIME).timeout
	if not visible:
		return
	_show_result()


func _show_result() -> void:
	_result_shown = true
	var ok: bool = not owner.ram_damaged and owner.ram_seated
	if ok:
		_screen.color = Color(0.15, 0.45, 0.2)
		_screen_label.text = "✓"
		_result.text = "ไม่มีเสียงบี๊บ\n✓ ผ่าน"
		_result.add_theme_color_override("font_color", PhaseUI.COL_OK)
		pib_toggle.emit(PibHint.Data.say(MinigameHeader.VERIFY, PibHint.Mood.HAPPY))
		return
	_screen.color = Color(0.45, 0.1, 0.1)
	_screen_label.text = "▓▒░ ค้าง"
	_result.text = "ยังมีเสียงบี๊บ\n✗ ไม่ผ่าน"
	_result.add_theme_color_override("font_color", PhaseUI.COL_BAD)
	var lines: Array = []
	if not owner.ram_seated:
		mistake.emit(&"tidiness", 10)
		lines.append("สลักยังไม่ดีดเลย แรมเลยลงไม่สุด ขาทองไม่แตะหน้าสัมผัสครบ")
	if owner.ram_damaged:
		lines.append("ขาทองเป็นรอยจากตอนทำความสะอาด สัญญาณเลยยังวิ่งไม่ครบ")
	lines.append("ครั้งหน้าลองแก้ตรงนี้ดูนะ งานซ่อมจริงต้องย้อนกลับไปทำใหม่จนผ่าน")
	PhaseUI.pib_say_text(lines, PibHint.Mood.WORRY)


func _on_pib_done() -> void:
	if not visible or not _result_shown:
		return
	hide()
	phase_completed.emit()
