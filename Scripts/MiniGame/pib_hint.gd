# Scripts/MiniGame/pib_hint.gd
class_name PibHint extends CanvasLayer
@onready var name_label = $DialogPanel/Container/VBoxContainer/Name
@onready var dialog_label = $DialogPanel/Container/VBoxContainer/Dialog

enum Mood {
	NORMAL,
	HAPPY,
	WORRY,
	POINT,
}

## connect from Godot's Editor
signal line_finished
## connect from Godot's Editor
signal all_lines_finished

const DEFAULT_SPEAKER := "ปิ๊บ"
var cur_dialog: Array[DialogToken] = []


func _create_dialog(lines: Array):
	for line in lines:
		var token: DialogToken
		if line is DialogToken:
			token = line
		elif line is String:
			token = DialogToken.new(DEFAULT_SPEAKER, line)
		else:
			push_error("PibHint.say: element of type %s cannot convert to DialogToken" % type_string(typeof(line)))
			return
		cur_dialog.append(token)


func _on_dialog_panel_pressed() -> void:
	if cur_dialog.is_empty():
		self.hide()
		all_lines_finished.emit()
		return
	var t = cur_dialog.pop_front()
	name_label.text = t.name
	dialog_label.text = t.dialog
	line_finished.emit()


## พูดต่อเนื่องหลายบรรทัด — ผู้เล่นคลิกเพื่อไปบรรทัดถัดไป
## รับ Array ของ String หรือ DialogToken ปนกันได้
func say(lines: Array, mood: Mood = Mood.NORMAL) -> void:
	_create_dialog(lines)
	self.show()
	var t = cur_dialog.pop_front()
	name_label.text = t.name
	dialog_label.text = t.dialog


## พูดบรรทัดเดียวแล้วหายไปเองใน N วินาที (ใช้ตอนเตือนระหว่างเล่น)
func toast(line: String, mood: Mood = Mood.WORRY, seconds: float = 3.0) -> void:
	pass


## ชี้ไปที่ node เป้าหมาย (วาดลูกศรจากปิ๊บไปยัง target)
func point_at(target: Node2D, line: String) -> void:
	pass


class Data extends RefCounted:
	enum Act {
		SAY,
		TOAST,
		POINT_AT,
	}

	var type: Act
	var header: String
	var mood: PibHint.Mood
	var seconds: float
	var target: Node2D


	static func say(p_header: String, p_mood: Mood = Mood.NORMAL) -> Data:
		var p = Data.new()
		p.type = Act.SAY
		p.header = p_header
		p.mood = p_mood
		return p
