extends Phase2D
## Phase 1 · INSPECT — ดู 3 จุด: ไฟบนเมนบอร์ด (ในเคส) · กดปุ่มหน้าเคส (เงียบ) · โน้ตลูกค้า ครบแล้วกด "เริ่มซ่อม"
## [Claude 2 ต.ค. 2569]

const SPOTS := {
	"MbLed": ["led", "INSPECT_MB_LED"],
	"PowerButton": ["button", "INSPECT_BUTTON"],
	"NoteCard": ["note", "INSPECT_RECENT"],
}

var _built := false
var _checks := {}
var _seen := {}
var _start_btn: Button


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมปุ่มหน้าเคส — ขั้นที่ 1/8 · ตรวจอาการ")
		PhaseUI.label(rail, "จุดที่ต้องดู", 20, PhaseUI.COL_OK)
		_checks["led"] = PhaseUI.check_item(rail, "ไฟบนเมนบอร์ด (ในเคส)")
		_checks["button"] = PhaseUI.check_item(rail, "ลองกดปุ่มหน้าเคส")
		_checks["note"] = PhaseUI.check_item(rail, "โน้ตจากลูกค้า")
		_start_btn = rail_button(rail, "เริ่มซ่อม ►", _on_start)
	_seen.clear()
	for k in _checks:
		PhaseUI.set_check(_checks[k], false)
	_start_btn.hide()
	show()
	allow([node("MbLed"), node("PowerButton"), node("NoteCard")])
	cam(&"Overview")
	listen(stage().part_clicked, _on_clicked)
	say("INSPECT_INTRO")
	_next_hint()


func _on_clicked(p: Item2D) -> void:
	var key := String(p.name)
	if not SPOTS.has(key):
		return
	var spot: Array = SPOTS[key]
	if not _seen.has(spot[0]):
		_seen[spot[0]] = true
		PhaseUI.set_check(_checks[spot[0]], true)
		p.tint(Color(1, 0.85, 0.4))
		get_tree().create_timer(0.6).timeout.connect(p.clear_tint)
	say(spot[1])
	_next_hint()
	if _seen.size() >= SPOTS.size() and not _start_btn.visible:
		_start_btn.show()
		PhaseUI.refresh(self)


func _next_hint() -> void:
	if not _seen.has("button"):
		hint(node("PowerButton"), "ลองกดปุ่มเปิดเครื่อง", 5.0)
	elif not _seen.has("note"):
		hint(node("NoteCard"), "โน้ตจากลูกค้า", 4.0)
	elif not _seen.has("led"):
		hint(node("MbLed"), "ไฟบนเมนบอร์ด", 4.0)
	else:
		clear_hint()


func _on_start() -> void:
	if not visible:
		return
	_start_btn.hide()
	finish()
