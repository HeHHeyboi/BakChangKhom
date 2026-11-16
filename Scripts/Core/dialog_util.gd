class_name DialogUtil
## ตัวช่วยอ่านไฟล์บท (Assets/Dialog/*.txt) ก่อนส่งให้ DialogScene — กันบทว่าง/ไฟล์หายทำเกมค้าง
## [Claude 5 ต.ค. 2569]


## ไฟล์มีอยู่ และมีบรรทัดพูดอย่างน้อย 1 บรรทัด (DialogScene เปิดบทว่างแล้ว error index 0)
static func has_lines(path: String) -> bool:
	return count_lines(path) > 0


## จำนวนบรรทัดพูด (ไม่นับบรรทัดว่าง · คอมเมนต์ # · บรรทัดที่ไม่มี ",")
static func count_lines(path: String) -> int:
	if path == "" or not FileAccess.file_exists(path):
		return 0
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0
	var n := 0
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		if line.find(",") > 0:
			n += 1
	return n


## ชื่อคนพูดทุกคนในไฟล์ (ช่องแรกก่อน ",") · "ขม (ยิ้ม)" → "ขม" · DialogScene ข้ามชื่อที่ไม่มีใน _CharacterMap ให้เอง
static func speakers_in(path: String) -> Array[String]:
	var out: Array[String] = []
	if path == "" or not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "" or line.begins_with("#") or line.begins_with("Choice:") or line.ends_with(":"):
			continue
		var comma := line.find(",")
		if comma <= 0:
			continue
		var who := line.substr(0, comma).split("(")[0].split(":")[0].strip_edges()
		if who != "" and not out.has(who):
			out.append(who)
	return out


## บรรทัดที่มี ":" นอก Choice (DialogScene อ่านเป็นหัว branch → บทที่เหลือหาย) · คืนเลขบรรทัด
static func colon_lines(path: String) -> PackedInt32Array:
	var out := PackedInt32Array()
	if path == "" or not FileAccess.file_exists(path):
		return out
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var n := 0
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		n += 1
		if line != "" and not line.begins_with("#") and line.find(":") > -1 and not line.begins_with("Choice:"):
			out.append(n)
	return out


## [0.6.0] บทของงานกลาง: แทน {npc} (ชื่อคนพูด = char_key) {name} {device} แล้วเขียนเป็นไฟล์ชั่วคราวใน user:// · ไม่มี "{" = คืน path เดิม
static func filled_copy(path: String, vars: Dictionary) -> String:
	if path == "" or not FileAccess.file_exists(path):
		return path
	var text := FileAccess.get_file_as_string(path)
	if not text.contains("{"):
		return path
	for k in vars:
		text = text.replace("{%s}" % k, String(vars[k]))
	var out := "user://dialog_tmp_%s" % path.get_file()
	var f := FileAccess.open(out, FileAccess.WRITE)
	if f == null:
		return path
	f.store_string(text)
	f.close()
	return out


## [0.8.0] ตรวจไฟล์บทก่อนเข้าเกม → รายการปัญหา (ว่าง = ผ่าน)
## known = ชื่อคนพูดที่ใช้ได้ (ปกติ = คีย์ของ Global._CharacterMap) · ผู้พูดว่าง (",ข้อความ") = คำบรรยาย ไม่มีรูป
## กติกาตาม DialogScene.read_file/parse_text: ห้ามขึ้นต้นด้วยแท็บ · ห้ามมี ":" นอก Choice/หัวทางเลือก (ทำบทหาย)
## ห้ามมี "," เกิน 1 ตัว (ข้อความหลัง "," ตัวที่ 2 หาย) · ทุกตัวเลือกต้องมีหัว "ตัวเลือก:" และมีบรรทัดอย่างน้อย 1 บรรทัด
static func lint(path: String, known: Array) -> PackedStringArray:
	var out := PackedStringArray()
	if path == "" or not FileAccess.file_exists(path):
		out.append("ไม่พบไฟล์ %s" % path)
		return out
	var lines := FileAccess.get_file_as_string(path).split("\n")
	var choices: Array[String] = []
	var heads := { } # หัวทางเลือก → จำนวนบรรทัด
	var cur_head := ""
	var n := 0
	var said := 0
	for raw in lines:
		n += 1
		var line := String(raw).replace("\r", "")
		if line.begins_with("\t"):
			out.append("บรรทัด %d ขึ้นต้นด้วยแท็บ" % n)
		line = line.strip_edges()
		if line == "":
			cur_head = ""
			continue
		if line.begins_with("#"):
			continue
		if line.begins_with("Choice:"):
			for c in line.substr(7).split(","):
				choices.append(c.strip_edges())
			continue
		if line.ends_with(":") and line.find(",") < 0:
			cur_head = line.substr(0, line.length() - 1).strip_edges()
			if not choices.has(cur_head):
				out.append("บรรทัด %d หัวทางเลือก \"%s\" ไม่มีใน Choice" % [n, cur_head])
			heads[cur_head] = 0
			continue
		if line.find(":") > -1:
			out.append("บรรทัด %d มี \":\" (บทหลังจากนี้จะหาย)" % n)
			continue
		var parts := line.split(",")
		if parts.size() < 2:
			out.append("บรรทัด %d ไม่มีชื่อคนพูด (ไม่มี \",\")" % n)
			continue
		if parts.size() > 2:
			out.append("บรรทัด %d มี \",\" เกิน 1 ตัว (ข้อความหลังจุลภาคหาย)" % n)
		var who := parts[0].split("(")[0].strip_edges()
		if who != "" and not known.has(who):
			out.append("บรรทัด %d คนพูด \"%s\" ไม่มีรูปใน _CharacterMap" % [n, who])
		if parts[1].strip_edges() == "":
			out.append("บรรทัด %d ข้อความว่าง" % n)
		said += 1
		if cur_head != "":
			heads[cur_head] = int(heads[cur_head]) + 1
	for c in choices:
		if not heads.has(c):
			out.append("ตัวเลือก \"%s\" ไม่มีบท" % c)
		elif int(heads[c]) == 0:
			out.append("ตัวเลือก \"%s\" ว่าง" % c)
	if said == 0:
		out.append("ไม่มีบรรทัดพูด")
	return out


## [0.8.0] ชื่อคนพูดที่มีรูป (คีย์ _CharacterMap ตัด ":อารมณ์")
## "คำบรรยาย" = ผู้บรรยาย (ไม่มีรูป ใช้มาตั้งแต่บท 1–2)
const NARRATOR := "คำบรรยาย"


static func known_speakers() -> Array:
	var out := [NARRATOR]
	for k in Global._CharacterMap.keys():
		var b := String(k).split(":")[0]
		if not out.has(b):
			out.append(b)
	return out
