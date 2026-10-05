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
