# Scripts/MiniGame/pib_hint.gd
class_name PibHint extends CanvasLayer

enum Mood {
	NORMAL,
	HAPPY,
	WORRY,
	POINT,
}

signal line_finished
signal all_lines_finished

const DEFAULT_SPEAKER := "ปิ๊บ"


## พูดต่อเนื่องหลายบรรทัด — ผู้เล่นคลิกเพื่อไปบรรทัดถัดไป
## รับ Array ของ String หรือ DialogToken ปนกันได้
func say(lines: Array, mood: Mood = Mood.NORMAL) -> void:
	for line in lines:
		var token: DialogToken
		if line is DialogToken:
			token = line
		elif line is String:
			token = DialogToken.new(DEFAULT_SPEAKER, line)
		else:
			push_error("PibHint.say: element of type %s cannot convert to DialogToken" % type_string(typeof(line)))
			return
		print(token.name, token.dialog)


## พูดบรรทัดเดียวแล้วหายไปเองใน N วินาที (ใช้ตอนเตือนระหว่างเล่น)
func toast(line: String, mood: Mood = Mood.WORRY, seconds: float = 3.0) -> void:
	pass


## ชี้ไปที่ node เป้าหมาย (วาดลูกศรจากปิ๊บไปยัง target)
func point_at(target: Node2D, line: String) -> void:
	pass
