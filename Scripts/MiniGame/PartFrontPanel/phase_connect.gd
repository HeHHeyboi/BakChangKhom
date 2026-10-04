extends Phase2D
## Phase 5 · CONNECT — เสียบหัวต่อหน้าเคส 4 หัวลงคู่พิน F_PANEL
##   คลิกหัวในถาด (เลือก) → คลิกคู่พิน (วาง · ถ้ามีหัวอื่นอยู่จะเด้งกลับถาด) · คลิกหัวที่เสียบแล้ว = เลือกเพื่อย้าย
##   ปุ่ม "สลับขั้ว" กลับหัวที่เลือกซ้าย-ขวา (LED มีขั้ว: สายสี/ลูกศร = +) · เสียบครบ 4 หัวแล้วกด "ทดสอบ"
##   ไม่หักคะแนนตอนวาง — ผิดตำแหน่ง/ขั้วจะไปเห็นตอนทดสอบ (ขั้น TEST_BUTTON) · [Claude 2 ต.ค. 2569]

var _built := false
var _chk := {}
var _flip_btn: Button
var _test_btn: Button
var _sel := ""
var _done := false


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมปุ่มหน้าเคส — ขั้นที่ 5/8 · เสียบหัวต่อ")
		for c in PartFrontPanel.CONNS:
			_chk[c] = PhaseUI.check_item(rail, "เสียบหัว " + PartFrontPanel.CONN_NAME[c])
		_flip_btn = PhaseUI.rail_button(rail, "สลับขั้วหัวที่เลือก ⇄", _on_flip)
		_test_btn = PhaseUI.rail_button(rail, "เสียบครบแล้ว ทดสอบ ►", _on_test)
	_sel = ""
	_done = false
	_refresh()
	show()
	var a: Array = []
	for c in PartFrontPanel.CONNS:
		a.append(owner.conn_node(c))
	for pr in PartFrontPanel.PAIR_NODE.values():
		a.append(node(pr))
	allow(a)
	cam(&"Pins")
	listen(stage().part_clicked, _on_clicked)
	say("CONNECT")
	hint(owner.conn_node("power_sw"), "เลือกหัวสาย", 5.0)


func _pair_of_node(p: Item2D) -> String:
	for k in PartFrontPanel.PAIR_NODE:
		if node(PartFrontPanel.PAIR_NODE[k]) == p:
			return k
	return ""


func _conn_of_node(p: Item2D) -> String:
	for c in PartFrontPanel.CONNS:
		if owner.conn_node(c) == p:
			return c
	return ""


func _on_clicked(p: Item2D) -> void:
	if _done:
		return
	var c := _conn_of_node(p)
	var pair := _pair_of_node(p)
	if c != "":
		if _sel != "" and _sel != c and owner.placement[c] != "":
			pair = owner.placement[c] # มีหัวเลือกอยู่แล้วคลิกหัวที่เสียบ = จะวางทับคู่นั้น
		elif _sel == c:
			_select("")
			return
		else:
			_select(c)
			hint(node("PairPled"), "คลิกคู่พินที่จะเสียบ", 4.0)
			return
	if pair == "":
		return
	if _sel == "":
		toast("CONNECT_PICK_FIRST")
		return
	var other: String = owner.conn_at(pair)
	if other != "" and other != _sel:
		owner.place_conn(other, "")
	owner.place_conn(_sel, pair)
	if owner.map_revealed and PartFrontPanel.CORRECT_PAIR[_sel] != pair:
		toast("CONNECT_WRONG_SLOT") # อ่านผังมาแล้ว ปิ๊บทักได้ทันที
	_select("")
	clear_hint()
	_refresh()


func _select(c: String) -> void:
	if _sel != "":
		owner.conn_node(_sel).clear_tint()
	_sel = c
	if c != "":
		owner.conn_node(c).tint(Color(1, 0.9, 0.3))
	_refresh()


func _on_flip() -> void:
	if _done or _sel == "":
		toast("CONNECT_PICK_FIRST")
		return
	owner.flip_conn(_sel)


func _refresh() -> void:
	var all := true
	for c in PartFrontPanel.CONNS:
		var placed: bool = owner.placement[c] != ""
		PhaseUI.set_check(_chk[c], placed)
		all = all and placed
	_flip_btn.disabled = _sel == ""
	_test_btn.visible = all
	PhaseUI.refresh(self)


func _on_test() -> void:
	if _done:
		return
	_done = true
	_select("")
	_test_btn.hide()
	finish()
