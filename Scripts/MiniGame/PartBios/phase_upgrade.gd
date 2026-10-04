extends Phase2D
## Phase 8 · UPGRADE — อ่านกราฟแท่ง CPU / การ์ดจอ / แรม / ดิสก์ แล้วแนะนำลูกค้า (ปุ่มใน rail)
##   ค่าแท่งคิดจากสิ่งที่ผู้เล่นทำ (เปิด XMP แรมสูงขึ้น · ลง SSD ดิสก์สูง) · ตอบแท่งต่ำสุด ✅ · ผิด −10 แล้วจบขั้น
## [Claude 2 ต.ค. 2569]

const OPTIONS := [["cpu", "อัป CPU"], ["gpu", "อัปการ์ดจอ (แพงสุด)"], ["ram", "เพิ่มแรม"], ["storage", "เปลี่ยนดิสก์"], ["none", "ยังไม่ต้องอัปอะไร"]]
const BAR_NODE := { "cpu": "BarCpu", "gpu": "BarGpu", "ram": "BarRam", "storage": "BarStorage" }
const BASE_Y := 330.0

var _built := false
var _btns: Array[Button] = []
var _done := false
var scores := {}


func init():
	if not _built:
		_built = true
		var rail := PhaseUI.make_frame(self, "ซ่อมเครื่องค้าง BIOS — ขั้นที่ 8/8 · แนะนำการอัปเกรด")
		PhaseUI.label(rail, "แนะนำลูกค้าว่า...", 18, PhaseUI.COL_OK)
		for o in OPTIONS:
			_btns.append(PhaseUI.rail_button(rail, o[1], choose.bind(o[0])))
	_done = false
	for b in _btns:
		b.disabled = false
	scores = {
		"cpu": 38,
		"gpu": 76,
		"ram": 72 if owner.saved_xmp > 0 else 55,
		"storage": 88 if owner.os_drive == "ssd" else 46,
	}
	show()
	allow([node("BarCpu")])
	cam(&"Chart")
	for k in BAR_NODE:
		_bar(k, scores[k])
	listen(owner.pib.all_lines_finished, _on_pib_done)
	say("UPGRADE")


func _bar(k: String, v: int) -> void:
	var b := node(BAR_NODE[k]) as Control
	var h := 2.4 * v
	var low := v == lowest_value()
	b.modulate = Color(0.95, 0.45, 0.35) if low else Color(0.45, 0.7, 0.95)
	b.size.y = 1.0
	b.position.y = BASE_Y
	create_tween().tween_property(b, "size:y", h, 0.5)
	create_tween().tween_property(b, "position:y", BASE_Y - h, 0.5)
	var val := node(BAR_NODE[k] + "Val") as Label
	val.text = str(v)
	val.position.y = BASE_Y - h - 32.0


func lowest_value() -> int:
	var m := 999
	for k in scores:
		m = mini(m, scores[k])
	return m


func best_choice() -> String:
	var hi := 0
	for k in scores:
		hi = maxi(hi, scores[k])
	if hi - lowest_value() < 15:
		return "none" # สมดุลแล้ว ไม่ต้องซื้อ
	for k in scores:
		if scores[k] == lowest_value():
			return k
	return "none"


func choose(id: String) -> void:
	if _done:
		return
	_done = true
	for b in _btns:
		b.disabled = true
	if id == best_choice():
		owner.set_meta("upgrade", id)
		say("UPGRADE_NONE_NEEDED" if id == "none" else "UPGRADE_RIGHT", PibHint.Mood.HAPPY)
	else:
		mistake.emit(&"upgrade", 10)
		owner.set_meta("upgrade", id)
		say("UPGRADE_NONE_WRONG" if id == "none" else "UPGRADE_WRONG", PibHint.Mood.WORRY)


func _on_pib_done() -> void:
	if visible and _done:
		finish()
