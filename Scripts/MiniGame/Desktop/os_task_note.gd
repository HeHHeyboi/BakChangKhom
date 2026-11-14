extends Control
## [Claude 15 พ.ย. 2569] โน้ตงานในขมOS (os_task_note.tscn) — ย่อ/กางได้ ไม่ให้บังหน้าต่าง
## ข้อความ/ปุ่มในโน้ตยังตั้งโดย DesktopMinigameV2._setup_note เหมือนเดิม (%Title %Request %AskNote %Checklist %CheckButton %GiveUpButton)
## ย่อ = ซ่อน %Details (คำขอ · เช็กลิสต์) เหลือชื่องาน + ปุ่ม · จำค่าไว้ทั้งเกม (งานถัดไปเปิดมาแบบเดิม)

static var folded_pref := false

@onready var _note: Control = $StickyNote


func _ready() -> void:
	%FoldButton.pressed.connect(func() -> void: set_folded(not is_folded()))
	set_folded(folded_pref)


func is_folded() -> bool:
	return not %Details.visible


func set_folded(on: bool) -> void:
	folded_pref = on
	%Details.visible = not on
	%FoldButton.text = "กาง ▾" if on else "ย่อ ▴"
	%FoldButton.tooltip_text = "กางโน้ตงาน (ดูคำขอ + ขั้นตอน)" if on else "ย่อโน้ตงาน (เหลือชื่องาน + ปุ่ม)"
	_fit.call_deferred()


func _process(_d: float) -> void:
	# ข้อความเปลี่ยน (เช็กลิสต์/AskNote) → ให้โน้ตสูงเท่าเนื้อหา (Container ไม่หดเอง)
	if _note.size.y > _note.get_combined_minimum_size().y + 1.0:
		_fit()


func _fit() -> void:
	_note.reset_size()
