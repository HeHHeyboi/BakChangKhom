extends Phase2D
## Phase 7 · POWER — จุดตัดสินของ Part นี้: เลือกหัวสายไฟจาก 4 แบบ (อ่านตัวหนังสือบนหัว) แล้วดันจนคลิก
##   PCI-E 6+2 ✅ · CPU 8-PIN ❌ ครั้งแรกปิ๊บห้าม −10 · ครั้งที่สอง = ฝืนเสียบ การ์ดไหม้ −25 → การ์ดใหม่แล้วเริ่มขั้นนี้ใหม่
##   SATA ❌ เสียบไม่เข้า −5 · MOLEX (หัวแปลง) 🟡 −5 ผ่านแบบเตือน
##   กด "ต่อไป" ทั้งที่ยังไม่คลิก → ตอนทดสอบเครื่องดับกลางคัน แล้วย้อนกลับมาขั้นนี้ · [Claude 2 ต.ค. 2569]

const HEADS := [
	["pcie", "res://Assets/MiniGame/PartGpu/gpu_head_pcie.png", "หัว PCI-E 6+2"],
	["cpu8", "res://Assets/MiniGame/PartGpu/gpu_head_cpu8.png", "หัว CPU 8-PIN"],
	["sata", "res://Assets/MiniGame/PartGpu/gpu_head_sata.png", "หัว SATA"],
	["molex", "res://Assets/MiniGame/PartGpu/gpu_head_molex.png", "หัว Molex + หัวแปลง"],
]

var _built := false
var _chk: Array[Label] = []
var _heads_box: VBoxContainer
var _click_btn: Button
var _next_btn: Button
var _plugged := false
var _cpu8_tries := 0
var _restart := false
var _done := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมการ์ดจอ — ขั้นที่ 7/8 · ต่อไฟเลี้ยงการ์ด")
		for t in ["เลือกหัวสายให้ถูก (อ่านตัวหนังสือบนหัว)", "ดันหัวสายจนได้ยินเสียงคลิก"]:
			_chk.append(PhaseUI.check_item(rail, t))
		_heads_box = VBoxContainer.new()
		_heads_box.add_theme_constant_override("separation", 4)
		rail.add_child(_heads_box)
		for h in HEADS:
			var b := Button.new()
			b.name = h[0]
			b.icon = load(h[1])
			b.expand_icon = true
			b.custom_minimum_size = Vector2(0, 52)
			b.text = h[2]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 15)
			b.pressed.connect(choose.bind(h[0]))
			_heads_box.add_child(b)
		_click_btn = PhaseUI.rail_button(rail, "ดันหัวสายจนคลิก", push_click)
		_next_btn = PhaseUI.rail_button(rail, "ต่อไป ►", _on_next)
	_plugged = false
	_restart = false
	_done = false
	owner.cable_locked = false
	owner.cable_molex = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	_heads_box.show()
	_click_btn.hide()
	_next_btn.hide()
	var side := node("GpuSide") as Item2D
	side.set_state("")
	side.position = owner.GPU_SLOT_POS
	side.clear_tint()
	(node("LooseCable") as Item2D).set_state("")
	(node("PluggedCable") as Item2D).set_state("off")
	show()
	allow([])
	cam(&"Case")
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("POWER_INTRO")


func choose(id: String) -> void:
	if _plugged or not visible:
		return
	match id:
		"pcie":
			_plug(false)
			say("POWER_CORRECT", PibHint.Mood.HAPPY)
		"molex":
			mistake.emit(&"power", 5)
			_plug(true)
			say("POWER_MOLEX")
		"sata":
			mistake.emit(&"power", 5)
			say("POWER_WRONG_SATA")
		"cpu8":
			_cpu8_tries += 1
			if _cpu8_tries == 1:
				mistake.emit(&"power", 10)
				say("POWER_WRONG_CPU8", PibHint.Mood.WORRY)
			else:
				_burn()


func _plug(molex: bool) -> void:
	_plugged = true
	owner.cable_molex = molex
	PhaseUI.set_check(_chk[0], true)
	_heads_box.hide()
	(node("LooseCable") as Item2D).set_state("off")
	var pc := node("PluggedCable") as Item2D
	pc.set_state("")
	pc.modulate = Color(1, 0.85, 0.85) if molex else Color.WHITE
	_click_btn.show()
	_next_btn.show()
	PhaseUI.refresh(self)


func push_click() -> void:
	if not _plugged or owner.cable_locked:
		return
	owner.cable_locked = true
	PhaseUI.set_check(_chk[1], true)
	_click_btn.hide()
	var pc := node("PluggedCable") as Control
	var tw := create_tween()
	tw.tween_property(pc, "position:y", pc.position.y + 4, 0.05)
	tw.tween_property(pc, "position:y", pc.position.y, 0.08)
	say("POWER_CLICKED", PibHint.Mood.HAPPY)


## ฝืนเสียบหัว CPU 8-pin ซ้ำ — การ์ดไหม้ ต้องใช้การ์ดใหม่
func _burn() -> void:
	mistake.emit(&"power", 25)
	owner.card_burnt = true
	_heads_box.hide()
	var side := node("GpuSide") as Item2D
	side.tint(Color(0.25, 0.22, 0.2))
	var tw := create_tween()
	for i in 3:
		tw.tween_property(side, "position:x", owner.GPU_SLOT_POS.x + 6, 0.04)
		tw.tween_property(side, "position:x", owner.GPU_SLOT_POS.x, 0.04)
	_restart = true
	say_text(["ไม่ทันแล้วขม... ไฟวิ่งผิดขา การ์ดไหม้ไปแล้ว ของจริงคือต้องซื้อการ์ดใหม่เลยนะ"], PibHint.Mood.WORRY)


func _on_next() -> void:
	if not _plugged or _done:
		return
	_done = true
	_next_btn.hide()
	_click_btn.hide()
	finish()


func _on_pib_done() -> void:
	if not visible:
		return
	if _restart:
		_restart = false
		_cpu8_tries = 0
		_unlisten_all()
		init() # ใส่การ์ดใบใหม่แล้วเลือกสายใหม่
