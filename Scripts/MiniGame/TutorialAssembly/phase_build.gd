extends Phase2D
## Phase 2 · BUILD — ลากชิ้นจากแผ่นรองลงเคส · ลำดับ = ลำดับลูกของ node Parts ในซีน (แก้ลำดับได้ใน Editor)
## กฎตรวจอยู่ที่ Socket2D.check(): socket_type ต้องตรง · requires ต้องติดตั้งก่อน
## ผิด → ชิ้นเด้งกลับ + ปิ๊บบอกเหตุผล (PcPart.pib_wrong_order / pib_wrong_socket) · Tutorial ไม่หักคะแนน
## [Claude 9 ต.ค. 2569] วางแล้วไม่ลงทันที — ชิ้นลอยค้างเหนือช่องแบบแรม แล้วผู้เล่นทำ "ท่าจริง" ของชิ้นนั้น 1 จังหวะ (SEAT)
##   น็อต = กดทีละตัวตามวงกะพริบ (ทแยงมุม) · คันล็อก CPU · กดค้าง QTE (แรม/การ์ดจอ แบบเดียวกับ Part RAM) · M.2 เสียบเอียงแล้วกดลง

const PRESS: QteSpec = preload("res://Resources/Qte/ram_press.tres")
## ลอยค้างเหนือช่องเท่านี้ (พิกเซล) + ขยายนิดหน่อย = ยังไม่ลงสุด
const RAISE := Vector2(-3, -10)
const LIFT_SCALE := 1.07
const MAX_TRIES := 3

## วิธีติดตั้งของแต่ละช่อง (socket_type) — pts = จุดน็อตเป็นสัดส่วนของกรอบชิ้น (0–1) เรียงตามลำดับที่ต้องขัน
## ต้องตรงกับ SEAT_PTS ใน Assets/MiniGame/TutorialAssembly/src/gen_asm.py (ภาพประกอบแล้ววาดน็อตไว้ที่จุดเดียวกัน)
const SEAT := {
	&"psu_bay": {
		"how": "screws", "from": Vector2(46, 0),
		"pts": [Vector2(0.06, 0.1), Vector2(0.94, 0.9), Vector2(0.94, 0.1), Vector2(0.06, 0.9)],
		"tip": "ดันพาวเวอร์เข้าช่องแล้วขันน็อต 4 ตัว ทแยงมุมกัน",
	},
	&"mb_standoff": {
		"how": "screws",
		"pts": [Vector2(0.0328, 0.0328), Vector2(0.9672, 0.9672), Vector2(0.9672, 0.0328), Vector2(0.0328, 0.9672)],
		"tip": "วางรูบอร์ดให้ตรงเสารอง แล้วขันน็อตทแยงมุมทีละตัว",
	},
	&"cpu_socket": {
		"how": "lever",
		"tip": "ซีพียูวางลงเบา ๆ เอง ห้ามกด แล้วกดคันล็อกข้างซ็อกเก็ตลง",
	},
	&"cooler_mount": {
		"how": "screws",
		"pts": [Vector2(0.0632, 0.0632), Vector2(0.9368, 0.9368), Vector2(0.9368, 0.0632), Vector2(0.0632, 0.9368)],
		"tip": "ขันน็อตฮีตซิงก์ทแยงมุมทีละตัว แรงกดบนซีพียูจะได้เท่ากัน",
	},
	&"ram_slot": {
		"how": "press",
		"tip": "กดค้างให้แรมลงสล็อต ปล่อยตอนสลักดีด",
		"pop": "คลิก! สลักล็อก",
	},
	&"pcie_x16": {
		"how": "press", "screw_after": [Vector2(0.0198, 0.1667)],
		"tip": "กดค้างให้การ์ดจอลงช่อง PCIe ปล่อยตอนสลักดีด แล้วขันน็อตแผ่นยึดหลังเคส",
		"pop": "คลิก!",
	},
	&"m2_slot": {
		"how": "m2",
		"tip": "เสียบ M.2 เอียง ๆ เข้าขั้วแล้ว กดปลายลง แล้วขันน็อตตัวเดียว",
	},
}

var _built := false
var _checks := { } # Item2D → Label
var _seating := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ประกอบคอม — ขั้นที่ 2/4 · ประกอบ")
		PhaseUI.label(rail, "ลำดับการประกอบ", 20, PhaseUI.COL_OK)
		for p in owner.parts():
			_checks[p] = PhaseUI.check_item(rail, "วาง" + p.data.display_name)
	for p in owner.parts():
		p.mode = Item2D.Mode.DRAGGABLE
		PhaseUI.set_check(_checks[p], p.socket != null and not p.socket.accept_any)
	show()
	allow(owner.parts())
	cam(&"Tray") # หยิบจากแผ่นรอง แล้วลากไปค้างที่ "→ เคส" เพื่อเข้าเคส
	listen(stage().part_installed, _on_installed)
	listen(stage().drop_rejected, _on_rejected)
	say("ASM_BUILD")
	_next_hint()


func _next_part() -> Item2D:
	for p in owner.parts():
		if not _checks[p].get_meta("done", false):
			return p
	return null


func _next_hint() -> void:
	var p := _next_part()
	if p == null:
		return
	var s := _socket_for(p)
	hint(p, "ลาก" + p.data.display_name.get_slice(" ", 0) + "ไปวางในเคส", 6.0)
	if s:
		s.highlight(Socket2D.HL.INVALID) # กรอบเรืองแสงตรงที่ต้องวาง


func _socket_for(p: Item2D) -> Socket2D:
	for s in stage().sockets:
		if s.socket_type == p.data.socket_type and s.occupant == null:
			return s
	return null


func _on_installed(p: Item2D, s: Socket2D) -> void:
	if not _checks.has(p) or s.accept_any or _seating:
		return
	s.highlight(Socket2D.HL.CLOSE)
	p.mode = Item2D.Mode.STATIC # วางแล้วล็อกไว้ ไม่ให้หลุดออกระหว่าง Tutorial
	_seating = true
	allow([]) # ระหว่างติดตั้งห้ามหยิบชิ้นอื่น
	await seat(p, s)
	_seating = false
	if not _alive():
		return
	allow(owner.parts())
	PhaseUI.set_check(_checks[p], true)
	var rect = PhaseUI.CARD_RECT
	rect.position = Vector2(16, 450)
	PhaseUI.part_card(self, p.data.display_name, "ติดตั้งแล้ว ✓", owner.core_name(p.data), rect)
	if _next_part() == null:
		clear_hint()
		await owner.show_cables() # ครบแล้ว → ต่อสายไฟให้เห็นภาพประกอบเสร็จ
		await wait(1.0)
		finish()
	else:
		await wait(0.9)
		if visible:
			cam(&"Tray") # กลับไปหยิบชิ้นถัดไป
		_next_hint()


func _on_rejected(p: Item2D, _s: Socket2D, reason: Socket2D.Result) -> void:
	var h := ""
	match reason:
		Socket2D.Result.WRONG_ORDER:
			h = p.data.pib_wrong_order
		Socket2D.Result.WRONG_SOCKET:
			h = p.data.pib_wrong_socket
	if h == "" or not owner.dialog_dict.has(h):
		h = "ASM_WRONG_SOCKET"
	toast(h)

# ================================================================ ติดตั้งให้แน่น (ท่าจริงของแต่ละชิ้น)


## ชิ้นลอยค้างเหนือช่อง → ผู้เล่นทำท่าของชิ้นนั้น → ลงสุด · ช่องที่ไม่มีใน SEAT = ลงเลย
func seat(p: Item2D, s: Socket2D) -> void:
	var cfg: Dictionary = SEAT.get(p.data.socket_type if p.data else &"", { })
	if cfg.is_empty():
		await owner.show_installed(p)
		return
	clear_hint()
	await wait(0.2) # ให้ stage.install เลื่อนชิ้นเข้าช่องเสร็จก่อน
	if not _alive():
		return
	var home := s.position
	p.size = s.size
	p.pivot_offset = p.size / 2.0
	p.position = home + RAISE + cfg.get("from", Vector2.ZERO)
	p.scale = Vector2.ONE * LIFT_SCALE
	p.modulate = Color(1.1, 1.1, 1.1)
	_tip(cfg.tip)
	match String(cfg.how):
		"screws":
			await _settle(p, home, 0.45)
			await _screws(p, cfg.pts)
		"lever":
			await _settle(p, home, 0.6) # วางเอง ไม่ต้องออกแรง
			await _lever(p)
		"press":
			await _press(p, home, String(cfg.get("pop", "คลิก!")))
			if cfg.has("screw_after"):
				await _screws(p, cfg.screw_after)
		"m2":
			await _m2(p, home)
	if not is_instance_valid(p):
		return
	p.position = home
	p.scale = Vector2.ONE
	p.rotation = 0.0
	p.pivot_offset = p.size / 2.0
	p.modulate = Color.WHITE
	clear_hint()
	await owner.show_installed(p) # ภาพลอย → ภาพประกอบแล้ว


func _settle(p: Item2D, home: Vector2, dur: float) -> void:
	if not _alive():
		return
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "position", home, dur)
	tw.tween_property(p, "scale", Vector2.ONE, dur)
	tw.tween_property(p, "modulate", Color.WHITE, dur)
	await tw.finished


## น็อตหลายตัว (ลูกของชิ้น → ชิ้นที่ใส่ทีหลังบังได้) · กดตามวงกะพริบ · กดผิดคิว = ปิ๊บเตือน (ไม่หักคะแนน)
func _screws(p: Item2D, pts: Array) -> void:
	if not _alive() or pts.is_empty():
		return
	var list: Array[SeatTarget] = []
	for pt in pts:
		var t := SeatTarget.make(SeatTarget.Kind.SCREW, Vector2(pt.x * p.size.x, pt.y * p.size.y), Vector2(14, 14))
		t.wrong_order.connect(func(_t): _tip("ขันทีละตัวตามวงที่กะพริบนะ ทแยงมุมกันแรงจะได้เท่ากัน"))
		p.add_child(t)
		list.append(t)
	for t in list:
		if not _alive():
			return
		t.next = true
		hint(t, "ขันน็อต", 0.0)
		while _alive() and is_instance_valid(t) and not t.finished:
			await get_tree().process_frame
		await wait(0.2)
	clear_hint()
	if _alive():
		_pop(p, p.size / 2.0, "แน่นแล้ว ✓")


## คันล็อกซีพียู (ข้างซ็อกเก็ต) — ยกค้างอยู่ กดแล้วพับลง
func _lever(p: Item2D) -> void:
	if not _alive():
		return
	var t := SeatTarget.make(SeatTarget.Kind.LEVER, Vector2(p.size.x + 7, p.size.y + 2), Vector2(8, 34))
	p.add_child(t)
	t.next = true
	hint(t, "กดคันล็อกลง", 0.0)
	while _alive() and is_instance_valid(t) and not t.finished:
		await get_tree().process_frame
	clear_hint()
	await wait(0.3)
	if _alive():
		_pop(p, p.size / 2.0, "ล็อกแล้ว ✓")


## กดค้างให้ลงช่อง (QTE แบบ Part RAM) — ค่าเกจ = ความลึก · พลาดได้ไม่จำกัดในบทฝึก (ครบ 3 ครั้งปิ๊บช่วย)
func _press(p: Item2D, home: Vector2, pop: String) -> void:
	var q = owner.get("qte") if is_instance_valid(owner) else null
	if not (q is QteRunner) or not q.is_inside_tree():
		await _settle(p, home, 0.3)
		return
	var top := p.position
	var zone_x := maxf(PRESS.zone.x, 0.01)
	var follow := func(v: float) -> void:
		if is_instance_valid(p):
			var k := minf(v / zone_x, 1.0)
			p.position = top.lerp(home, k)
			p.scale = Vector2.ONE * lerpf(LIFT_SCALE, 1.0, k)
	q.value_changed.connect(follow)
	for i in MAX_TRIES:
		await _wait_pib()
		if not _alive():
			break
		var r: QteRunner.Result = await q.run(PRESS, p, owner.qte_zone_scale())
		if not _alive() or r != QteRunner.Result.MISS:
			break
		if i == MAX_TRIES - 1:
			_tip("ไม่เป็นไร ปิ๊บช่วยกดให้ ครั้งหน้าปล่อยตอนเกจอยู่ในช่องเขียวนะ")
		else:
			var over: bool = q.last_value > maxf(PRESS.zone.x, PRESS.zone.y)
			_tip("แรงไปนิด! ค่อย ๆ กด" if over else "ยังไม่ลงสุด กดค้างอีกนิด")
			p.position = top
			p.scale = Vector2.ONE * LIFT_SCALE
			await wait(0.4)
	if q.value_changed.is_connected(follow):
		q.value_changed.disconnect(follow)
	await _settle(p, home, 0.1)
	if _alive():
		_pop(p, p.size / 2.0, pop)


## M.2: เสียบเอียงเข้าขั้วด้านซ้าย → กดปลายขวาลง → ขันน็อต
func _m2(p: Item2D, home: Vector2) -> void:
	if not _alive():
		return
	p.scale = Vector2.ONE
	p.modulate = Color.WHITE
	p.pivot_offset = Vector2(0, p.size.y / 2.0) # ขั้วอยู่ปลายซ้าย
	p.rotation = deg_to_rad(-22)
	p.position = home + Vector2(-12, 0)
	var tw := create_tween()
	tw.tween_property(p, "position", home, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not _alive():
		return
	var push := SeatTarget.make(SeatTarget.Kind.PUSH, Vector2(p.size.x - 6, p.size.y / 2.0), Vector2(26, 26))
	p.add_child(push)
	push.next = true
	hint(push, "กดปลายลง", 0.0)
	while _alive() and is_instance_valid(push) and not push.finished:
		await get_tree().process_frame
	clear_hint()
	if not _alive():
		return
	tw = create_tween()
	tw.tween_property(p, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tw.finished
	if is_instance_valid(push):
		push.queue_free()
	await _screws(p, [Vector2(0.975, 0.5)])


## ข้อความสั้นของปิ๊บ (ไม่ต้องกดปิด)
func _tip(text: String) -> void:
	var pib = owner.get("pib") if is_instance_valid(owner) else null
	if is_instance_valid(pib) and text != "":
		pib.toast(DialogToken.new(PibHint.DEFAULT_SPEAKER, text), 4.0, PibHint.Mood.POINT)


## ตัวหนังสือเด้งขึ้นแล้วจางหาย ("คลิก!" · "แน่นแล้ว ✓")
func _pop(parent: Control, at: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.top_level = true
	l.z_index = 50
	add_child(l)
	l.reset_size()
	var gp := parent.get_global_transform_with_canvas() * at
	l.global_position = gp - l.size / 2.0
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "global_position:y", l.global_position.y - 28, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


func _alive() -> bool:
	return is_inside_tree() and visible and is_instance_valid(owner)


## รอให้ผู้เล่นปิดกล่องคำพูดปิ๊บก่อน — ไม่งั้นคลิกปิดกล่องจะนับเป็นการกด QTE (เหมือน Part RAM)
func _wait_pib() -> void:
	if not _alive():
		return
	await get_tree().process_frame
	var t := 0.0
	while _alive() and t < 60.0:
		var pib = owner.get("pib")
		if not is_instance_valid(pib) or not pib.visible or not pib.dialog_panel.visible or pib._closing:
			break
		await wait(0.1)
		t += 0.1
	if _alive():
		await wait(0.2)
