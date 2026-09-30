class_name DialogToken extends RefCounted

var name: String # ชื่อสะอาด ไม่มีวงเล็บ
var dialog: String
var mood: String # "" | "happy" | "worry"
var note: String # คำในวงเล็บดิบ เช่น "(น้ำเสียงอ่อนโยน)" · ไม่มี = ""


func _init(p_name: String, p_dialog: String, p_mood := "", p_note := ""):
	name = p_name
	dialog = p_dialog
	mood = p_mood
	note = p_note
