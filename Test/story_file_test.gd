extends Node
## [0.8.0] ตรวจไฟล์บททุกไฟล์ที่เกมเปิด: บทต้นเดือน · บทปิดเดโม · ฉากจบ · เรื่องส่วนตัว NPC · ของขวัญ
var fails := 0


func _ready() -> void:
	var known := DialogUtil.known_speakers()
	var files: Array[String] = []
	for ch in GameState.CHAPTERS:
		files.append(ch["file"])
	files.append(GameState.EPILOGUE["file"])
	for d in ["res://Assets/Dialog/Ending/", "res://Assets/Dialog/NPC/", "res://Assets/Dialog/City/"]: # [0.9.5] + บทในเมือง
		var da := DirAccess.open(d)
		if da == null:
			continue
		for f in da.get_files():
			if f.ends_with(".txt"):
				files.append(d + f)
	for f in files:
		var p := DialogUtil.lint(f, known)
		_check(p.is_empty(), "%s %s" % [f.get_file(), "" if p.is_empty() else "→ " + " | ".join(p.slice(0, 4))])
	print("T DONE fails=%d" % fails)
	get_tree().quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
	else:
		print("ok   ", msg)
