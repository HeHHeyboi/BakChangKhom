class_name VersionLabel
extends Label
## ป้ายเลขเวอร์ชันมุมจอ (เมนูหลัก · เมนูพัก) — อ่านจาก Project Settings > Application > Config > Version
## จะออกเวอร์ชันใหม่ แก้ที่ project.godot (config/version) ที่เดียว ป้ายทุกอันเปลี่ยนตาม
## ไม่รับเมาส์ (mouse_filter = IGNORE) จึงไม่บังปุ่ม/ไม่กระทบเกมเพลย์


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	text = version_text()


static func version_text() -> String:
	var v := str(ProjectSettings.get_setting("application/config/version", "dev"))
	var tag := "Web" if OS.has_feature("web") else OS.get_name()
	return "v%s · %s" % [v, tag]
