extends Phase2D
## Phase 3 · POWER_TEST — กดปุ่มเปิดเครื่องหน้าเคส → ไฟ LED ติด → ซูมเข้าจอ → บูต + ทำความรู้จัก ขมOS (โหนดเดียว) → จบ
## [Claude 9 ต.ค. 2569] เดิมจบที่จอขึ้น "บูตผ่าน" · ตอนนี้เปิดขมOS (tour_mode) ให้ลองใช้ทีละขั้น (LEVEL_DESIGN: เลเวลแรกเป็นงานบนจอ)

enum Stage { WAIT_POWER, BOOT, OS, DONE }

var _built := false
var _stage: Stage = Stage.WAIT_POWER
var _rail_checks: Array = []


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ประกอบคอม — ขั้นที่ 3/4 · เปิดเครื่อง")
		_rail_checks.append(PhaseUI.check_item(rail, "กดปุ่มเปิดเครื่องหน้าเคส"))
		_rail_checks.append(PhaseUI.check_item(rail, "ทำความรู้จัก ขมOS"))
	_stage = Stage.WAIT_POWER
	for c in _rail_checks:
		PhaseUI.set_check(c, false)
	show()
	allow([node("PowerButton")])
	cam(&"Front")
	listen(stage().part_clicked, _on_clicked)
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("ASM_BUILD_DONE")
	hint(node("PowerButton"), "กดเปิดเครื่อง", 3.0)


func _on_clicked(p: Item2D) -> void:
	if p != node("PowerButton") or _stage != Stage.WAIT_POWER:
		return
	_stage = Stage.BOOT
	clear_hint()
	p.pivot_offset = p.size / 2.0
	var tw := create_tween()
	tw.tween_property(p, "scale", Vector2.ONE * 0.85, 0.08) # ปุ่มยุบลง
	tw.tween_property(p, "scale", Vector2.ONE, 0.08)
	(node("PowerLed") as Item2D).set_state("on")
	PhaseUI.set_check(_rail_checks[0], true)
	cam(&"Monitor")
	await wait(0.8)
	if not visible:
		return
	# [10 ต.ค.] จอบูต + ขมOS เป็นโหนดเดียวกัน (DesktopMinigame framed) — ซูมเข้าจอแล้วบูตในนั้นเลย
	# ไม่ใช้ภาพนิ่ง boot_ok / os ของ Monitor แล้ว · ปิ๊บของ OS ทักเอง (os_tour.pib_intro)
	_stage = Stage.OS
	await owner.open_os_tour()
	if not visible:
		return
	_stage = Stage.DONE
	PhaseUI.set_check(_rail_checks[1], true)
	say("ASM_OS_DONE", PibHint.Mood.HAPPY)


func _on_pib_done() -> void:
	if not visible:
		return
	if _stage == Stage.DONE:
		finish()


## ข้ามด้วย Debug ระหว่างเปิด OS → ปิด OS ด้วย
func abort() -> void:
	owner.close_os_tour()
	super.abort()
