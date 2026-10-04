extends Phase2D
## Phase 6 · SEAT_CPU — คลิกคานล็อก (เปิด) → CPU ถูกยกขึ้นมาวางข้าง ๆ แบบหมุนสุ่ม → หมุนให้สามเหลี่ยมทองอยู่มุมซ้ายล่าง
## → คลิก CPU วางลงซ็อกเก็ต → คลิกคานล็อก (ปิด)
## หันผิดแล้ววาง = เอียงค้าง −5 cpu · กด "ออกแรงกดให้ลง" ตอนหันผิด = ขาพับ −25 → เปลี่ยนเมนบอร์ดสำรองแล้วเริ่มขั้นนี้ใหม่
## [Claude 2 ต.ค. 2569]

enum Step { OPEN, PLACE, CLOSE, DONE }

const PARK := Vector2(820, 115) # จุดวาง CPU ข้างซ็อกเก็ต (พิกัดในมุม Socket)

var step := Step.OPEN
var _built := false
var _chk: Array[Label] = []
var _rotate_btn: Button
var _force_btn: Button
var _tilted := false
var _restart := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเมนบอร์ด — ขั้นที่ 6/8 · วาง CPU")
		PhaseUI.label(rail, "ขั้นตอน", 20, PhaseUI.COL_OK)
		for t in ["เปิดคานล็อกซ็อกเก็ต", "หันสามเหลี่ยมให้ตรงแล้ววาง CPU", "ปิดคานล็อก"]:
			_chk.append(PhaseUI.check_item(rail, t))
		_rotate_btn = PhaseUI.rail_button(rail, "↻ หมุน CPU 90°", rotate_cpu)
		_force_btn = PhaseUI.rail_button(rail, "ออกแรงกดให้ลง", _on_force)
	step = Step.OPEN
	_tilted = false
	_restart = false
	for c in _chk:
		PhaseUI.set_check(c, false)
	_rotate_btn.hide()
	_force_btn.hide()
	var cpu := node("Cpu") as Item2D
	cpu.position = owner.cpu_home
	cpu.rotation_degrees = 0
	cpu.remove_meta("rot_target")
	cpu.clear_tint()
	(node("Retention") as Item2D).set_state("")
	show()
	allow([node("Retention")])
	cam(&"Socket")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("SEAT_CPU")
	hint(node("Retention"), "เปิดคานล็อก", 5.0)


func _on_clicked(p: Item2D) -> void:
	var cpu := node("Cpu") as Item2D
	match step:
		Step.OPEN:
			if p == node("Retention"):
				p.set_state("open")
				PhaseUI.set_check(_chk[0], true)
				step = Step.PLACE
				var tw := create_tween().set_parallel()
				tw.tween_property(cpu, "position", PARK, 0.35)
				var r0: float = [90.0, 180.0, 270.0].pick_random()
				cpu.set_meta("rot_target", r0)
				tw.tween_property(cpu, "rotation_degrees", r0, 0.35)
				allow([cpu])
				_rotate_btn.show()
				PhaseUI.refresh(self)
				say("SEAT_CPU_LIFTED")
				hint(cpu, "หมุนแล้วคลิกเพื่อวาง", 6.0)
		Step.PLACE:
			if p == cpu:
				if _tilted:
					_lift_back()
				else:
					_place()
		Step.CLOSE:
			if p == node("Retention"):
				p.set_state("")
				PhaseUI.set_check(_chk[2], true)
				step = Step.DONE
				allow([])
				clear_hint()
				say("SEAT_CPU_DONE", PibHint.Mood.HAPPY)


func rotate_cpu() -> void:
	if step != Step.PLACE or _tilted:
		return
	var cpu := node("Cpu") as Control
	var to: float = float(cpu.get_meta("rot_target", cpu.rotation_degrees)) + 90.0
	create_tween().tween_property(cpu, "rotation_degrees", to, 0.15)
	cpu.set_meta("rot_target", to)


func cpu_rotation() -> int:
	var cpu := node("Cpu") as Control
	var r: float = cpu.get_meta("rot_target", cpu.rotation_degrees)
	return int(round(fposmod(r, 360.0))) % 360


func _place() -> void:
	var cpu := node("Cpu") as Item2D
	var rot := cpu_rotation()
	var tw := create_tween()
	tw.tween_property(cpu, "position", owner.cpu_home, 0.3)
	await tw.finished
	if rot == PartMainboard.CPU_OK_ROTATION:
		cpu.rotation_degrees = 0
		cpu.remove_meta("rot_target")
		PhaseUI.set_check(_chk[1], true)
		step = Step.CLOSE
		_rotate_btn.hide()
		PhaseUI.refresh(self)
		allow([node("Retention")])
		say("SEAT_CPU_OK", PibHint.Mood.HAPPY)
		hint(node("Retention"), "ปิดคานล็อก", 5.0)
		return
	# หันผิด: วางไม่ลง เอียงค้าง
	_tilted = true
	mistake.emit(&"cpu", 5)
	cpu.tint(Color(1, 0.45, 0.45))
	create_tween().tween_property(cpu, "position", owner.cpu_home + Vector2(10, -8), 0.12)
	_force_btn.show()
	PhaseUI.refresh(self)
	say("SEAT_CPU_WRONG_ROTATION", PibHint.Mood.WORRY)
	hint(cpu, "คลิกยก CPU ขึ้นมาหมุนใหม่", 3.0)


func _lift_back() -> void:
	var cpu := node("Cpu") as Item2D
	_tilted = false
	cpu.clear_tint()
	_force_btn.hide()
	PhaseUI.refresh(self)
	create_tween().tween_property(cpu, "position", PARK, 0.3)


func _on_force() -> void:
	if not _tilted:
		return
	_force_btn.hide()
	owner.pins_bent = true
	mistake.emit(&"cpu", 25)
	var cpu := node("Cpu") as Item2D
	var tw := create_tween()
	for i in 3:
		tw.tween_property(cpu, "position:x", owner.cpu_home.x + 16, 0.04)
		tw.tween_property(cpu, "position:x", owner.cpu_home.x + 4, 0.04)
	_restart = true
	allow([])
	say("SEAT_CPU_FORCED", PibHint.Mood.WORRY)


func _on_pib_done() -> void:
	if not visible:
		return
	if _restart:
		# ของจริงคือเปลี่ยนเมนบอร์ด — ในเกมหยิบบอร์ดสำรองมาแล้วเริ่มขั้นนี้ใหม่
		_restart = false
		_unlisten_all()
		init()
		return
	if step == Step.DONE:
		finish()
