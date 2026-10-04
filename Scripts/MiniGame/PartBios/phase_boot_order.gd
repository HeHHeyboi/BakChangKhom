extends Phase2D
## Phase 4 · BOOT_ORDER — คลิกแถวลำดับบูต 2 แถวเพื่อสลับกัน · เอาดิสก์ที่มี Windows ขึ้นอันดับ 1
##   ถอดแฟลชไดรฟ์ลูกค้าที่ท้ายเคสได้ (ช่วยได้แต่เป็นการแก้ปลายเหตุ) · ผลจริงไปเห็นตอนบูตในขั้น SAVE_EXIT
## [Claude 2 ต.ค. 2569]

var _built := false
var _chk: Label
var _done_btn: Button
var _sel := -1
var _done := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเครื่องค้าง BIOS — ขั้นที่ 4/8 · ลำดับการบูต")
		_chk = PhaseUI.check_item(rail, "ดิสก์ที่มี Windows อยู่อันดับ 1")
		PhaseUI.label(rail, "คลิกสองแถวเพื่อสลับตำแหน่ง", 16, PhaseUI.COL_TEXT)
		_done_btn = PhaseUI.rail_button(rail, "ตั้งเสร็จแล้ว ►", _on_done)
	_sel = -1
	_done = false
	_refresh()
	show()
	var a: Array = [node("UsbStick")]
	for i in 4:
		a.append(_row(i))
	allow(a)
	cam(&"Bios")
	listen(stage().part_clicked, _on_clicked)
	say("BOOT_ORDER")
	hint(_row(1), "คลิกแถวที่จะย้าย", 5.0)


func _row(i: int) -> Item2D:
	return node("BootRow%d" % (i + 1)) as Item2D


func _on_clicked(p: Item2D) -> void:
	if _done:
		return
	if p == node("UsbStick"):
		if owner.usb_plugged:
			owner.usb_plugged = false
			p.set_state("out")
			toast("BOOT_USB_PULLED")
		return
	var i := -1
	for k in 4:
		if _row(k) == p:
			i = k
	if i < 0:
		return
	clear_hint()
	if _sel < 0:
		_sel = i
		p.tint(Color(1, 0.9, 0.3))
		return
	_row(_sel).clear_tint()
	if _sel != i:
		swap(_sel, i)
	_sel = -1


func swap(a: int, b: int) -> void:
	var t: String = owner.order[a]
	owner.order[a] = owner.order[b]
	owner.order[b] = t
	owner.refresh_bios()
	_refresh()


func _refresh() -> void:
	PhaseUI.set_check(_chk, owner.order[0] == "hdd")
	PhaseUI.refresh(self)


func _on_done() -> void:
	if _done:
		return
	_done = true
	if _sel >= 0:
		_row(_sel).clear_tint()
	finish()
