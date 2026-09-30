extends Phase2D
## Phase 2 · BUILD — ลากชิ้นจากแผ่นรองลงเคส · ลำดับ = ลำดับลูกของ node Parts ในซีน (แก้ลำดับได้ใน Editor)
## กฎตรวจอยู่ที่ Socket2D.check(): socket_type ต้องตรง · requires ต้องติดตั้งก่อน
## ผิด → ชิ้นเด้งกลับ + ปิ๊บบอกเหตุผล (PcPart.pib_wrong_order / pib_wrong_socket) · Tutorial ไม่หักคะแนน

var _built := false
var _checks := { } # Item2D → Label


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
	if not _checks.has(p) or s.accept_any:
		return
	s.highlight(Socket2D.HL.CLOSE)
	p.mode = Item2D.Mode.STATIC # วางแล้วล็อกไว้ ไม่ให้หลุดออกระหว่าง Tutorial
	PhaseUI.set_check(_checks[p], true)
	PhaseUI.part_card(self, p.data.display_name, "ติดตั้งแล้ว ✓", owner.core_name(p.data))
	if _next_part() == null:
		clear_hint()
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
