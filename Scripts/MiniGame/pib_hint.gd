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


## พูดต่อเนื่องหลายบรรทัด — ผู้เล่นคลิกเพื่อไปบรรทัดถัดไป
func say(lines: Array[String], mood: Mood = Mood.NORMAL) -> void:
	pass


## พูดบรรทัดเดียวแล้วหายไปเองใน N วินาที (ใช้ตอนเตือนระหว่างเล่น)
func toast(line: String, mood: Mood = Mood.WORRY, seconds: float = 3.0) -> void:
	pass


## ชี้ไปที่ node เป้าหมาย (วาดลูกศรจากปิ๊บไปยัง target)
func point_at(target: Node2D, line: String) -> void:
	pass
