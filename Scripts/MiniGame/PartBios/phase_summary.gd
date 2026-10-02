extends Phase2D
## Phase 9 · SUMMARY — การ์ดสรุป ดาว คะแนน 6 หมวด ผลงาน (ลำดับบูต · XMP · ไดรฟ์ที่ลง) ปุ่มกลับ
## ข้อมูลลูกค้าหาย = ได้สูงสุด 1 ดาว · [Claude 2 ต.ค. 2569]

const FULL := { &"read": 20, &"boot": 30, &"xmp": 10, &"save": 10, &"os": 20, &"upgrade": 10 }
const NAMES := {
	&"read": "อ่านหน้าจอ BIOS",
	&"boot": "แก้ลำดับบูตที่ต้นเหตุ",
	&"xmp": "เปิด XMP",
	&"save": "Save / Exit ถูกปุ่ม",
	&"os": "เลือกไดรฟ์ลง Windows",
	&"upgrade": "คำแนะนำอัปเกรด",
}
const STAR_AT := [60, 80, 95]
const LEARNED := [
	"จอฟ้า BIOS ≠ เครื่องพัง · อ่านค่าก่อน",
	"แก้ลำดับบูตที่ต้นเหตุ ไม่ใช่แค่ถอด USB",
	"XMP = ความเร็วเต็มของแรม (ล้มได้ → เคลียร์ CMOS)",
	"ก่อนลง Windows ดูให้ชัดว่าไดรฟ์ไหนมีข้อมูลลูกค้า",
	"อัปเกรดที่คอขวด (แท่งต่ำสุด)",
]

var _built := false
var _stars: Label
var _total: Label
var _note: Label
var _rows: VBoxContainer
var _back: Button
var total := 0


func init():
	if not _built:
		_build()
	total = 0
	for c in _rows.get_children():
		c.queue_free()
	for k in FULL:
		var got: int = maxi(FULL[k] - int(owner._mistakes.get(k, 0)), 0)
		total += got
		var l := PhaseUI.label(_rows, "%s   %d / %d" % [NAMES[k], got, FULL[k]], 18, Color(0.15, 0.12, 0.1))
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
	var stars := 0
	for s in STAR_AT:
		if total >= s:
			stars += 1
	if owner.data_lost:
		stars = mini(stars, 1)
	_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	_total.text = "คะแนน %d / 100  ·  %s" % [total, "ผ่าน" if total >= 60 else "ยังไม่ผ่าน"]
	var bits := ["บูต: %s" % ("ดิสก์อันดับ 1" if owner.saved_order[0] == "hdd" else "ยังไม่แก้ลำดับ"),
		"แรม %d MHz" % PartBios.XMP_MHZ[owner.saved_xmp],
		"Windows ลง %s" % ("SSD" if owner.os_drive == "ssd" else "HDD (ข้อมูลลูกค้าหาย!)")]
	_note.text = " · ".join(bits)
	_note.add_theme_color_override("font_color", Color(0.7, 0.15, 0.1) if owner.data_lost else Color(0.15, 0.4, 0.2))
	_back.disabled = false
	show()
	allow([])
	stage().user_camera = false
	nav_enabled = false
	cam(&"Overview")
	say("SUMMARY_BAD" if owner.data_lost else "SUMMARY", PibHint.Mood.WORRY if owner.data_lost else PibHint.Mood.HAPPY)


func _build() -> void:
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = PhaseUI.SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := PhaseUI.panel(self, Rect2(96, 24, 960, 440), "Card", Color(0.97, 0.95, 0.9, 0.96))
	var dark := Color(0.15, 0.12, 0.1)
	_stars = PhaseUI.label(card, "", 64, Color(0.95, 0.7, 0.1))
	_stars.position = Vector2(40, 16)
	_total = PhaseUI.label(card, "", 28, dark)
	_total.position = Vector2(300, 30)
	_note = PhaseUI.label(card, "", 17, Color(0.15, 0.4, 0.2))
	_note.position = Vector2(300, 76)
	var learned := PhaseUI.label(card, "สิ่งที่เรียนรู้\n• " + "\n• ".join(LEARNED), 17, dark)
	learned.position = Vector2(40, 130)
	learned.autowrap_mode = TextServer.AUTOWRAP_OFF
	var head := PhaseUI.label(card, "ตารางคะแนน", 18, dark)
	head.position = Vector2(520, 130)
	_rows = VBoxContainer.new()
	_rows.position = Vector2(520, 165)
	_rows.size = Vector2(400, 200)
	card.add_child(_rows)
	_back = PhaseUI.button(card, "กลับ ►", Rect2(760, 370, 170, 52), _on_back)


func _on_back() -> void:
	if not visible:
		return
	_back.disabled = true
	finish()
