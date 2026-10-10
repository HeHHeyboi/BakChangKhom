extends Control
## ตลาดในหมู่บ้าน — [Claude 10 ต.ค. 2569] เลิกเดิน (เดิม Node2D + Player + กำแพง) → ฉากกด: แผง 3 ร้าน (MarketStall) + ปุ่มแผนที่
## ข้อความล่างจอ: Say/Text · ซ่อนเองหลัง say_seconds วินาที

## ข้อความขึ้นนานกี่วินาที
@export var say_seconds := 3.0

@onready var _say: Control = $Say
@onready var _say_text: Label = $Say/Text
var _tw: Tween


func _ready() -> void:
	_say.hide()


func say(text: String) -> void:
	_say_text.text = text
	_say.show()
	_say.modulate.a = 1.0
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_interval(say_seconds)
	_tw.tween_property(_say, "modulate:a", 0.0, 0.4)
	_tw.tween_callback(_say.hide)
