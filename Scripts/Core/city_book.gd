class_name CityBook
## [Claude 16 พ.ย. 2569 · 0.9.5] เมือง — ข้อมูลกับบทที่ใช้ร่วมกัน (กฎการไป/เวลา/เงินอยู่ที่ DayLoop ส่วน "[0.9.5] เมือง")
## ตั๋วไอทีซัพพอร์ต (OfficeTicket · Resources/City/Tickets/) · บทในเมือง (Assets/Dialog/City/) · บรรทัดที่บท 12/ฉากจบอ้างถึงการไปเมือง
## สถานะการไปเมืองเก็บใน GameState.city (เซฟ v11) — keys ดู GameState.CITY_DEFAULT

const TICKET_DIR := "res://Resources/City/Tickets/"
const DIALOG_DIR := "res://Assets/Dialog/City/"
## ตัวเลือกแรกในบทออฟฟิศ = ลองงาน (ต้องตรงกับไฟล์ office_*.txt)
const TRY_OFFICE := "ลองทำงานกับทีมสักครึ่งวัน"
## ลองงาน 1 ครั้ง = กี่ใบ (คนละหมวดถ้าทำได้)
const PER_TRIP := 3
const CH12_FILE := "res://Assets/Dialog/Chapter12Year.txt"
const CH12_OUT := "user://dialog_tmp_ch12_city.txt"
## บรรทัดในบท 12 ที่จะแทรกเรื่องเมืองไว้ก่อนหน้า
const CH12_MARK := "แล้วเรื่องที่บริษัทชวน"

static var _tickets: Array[OfficeTicket] = []


static func tickets() -> Array[OfficeTicket]:
	if _tickets.is_empty():
		var d := DirAccess.open(TICKET_DIR)
		if d:
			var names := Array(d.get_files())
			names.sort()
			for f in names:
				var fn := String(f).trim_suffix(".remap")
				if fn.ends_with(".tres"):
					var t := load(TICKET_DIR + fn) as OfficeTicket
					if t:
						_tickets.append(t)
	return _tickets


## สุ่มตั๋วสำหรับลองงาน 1 ครั้ง: PER_TRIP ใบ คนละหมวด · ไม่ซ้ำใบที่เคยทำ (ถ้าไม่พอค่อยใช้ซ้ำ/หมวดซ้ำ)
static func pick_tickets(seen: Array, rng: RandomNumberGenerator) -> Array[OfficeTicket]:
	var out: Array[OfficeTicket] = []
	var fresh: Array[OfficeTicket] = []
	var old: Array[OfficeTicket] = []
	for t in tickets():
		(old if seen.has(String(t.id)) else fresh).append(t)
	for pass_no in 4: # 0 = ใหม่ หมวดไม่ซ้ำ · 1 = เก่า หมวดไม่ซ้ำ · 2 = ใหม่ · 3 = เก่า
		var pool: Array[OfficeTicket] = (fresh if pass_no % 2 == 0 else old).duplicate()
		while not pool.is_empty() and out.size() < PER_TRIP:
			var t: OfficeTicket = pool.pop_at(rng.randi_range(0, pool.size() - 1))
			if out.has(t) or (pass_no < 2 and out.any(func(x: OfficeTicket) -> bool: return x.category == t.category)):
				continue
			out.append(t)
	return out


## ทางที่ผู้เล่นเอนอยู่ตอนนี้ (stay ถ้ายังไม่เลือก)
static func lean() -> String:
	return String(GameState.story_flags.get("ch11_choice", "stay"))


static func arrive_dialog(visits: int) -> String:
	return DIALOG_DIR + ("arrive_first.txt" if visits <= 1 else "arrive_again.txt")


static func office_dialog() -> String:
	var p := DIALOG_DIR + "office_%s.txt" % lean()
	return p if FileAccess.file_exists(p) else DIALOG_DIR + "office_stay.txt"


static func cafe_dialog() -> String:
	return DIALOG_DIR + ("cafe_again.txt" if bool(GameState.city.get("met_cowork", false)) else "cafe_first.txt")


## บทหลังลองงาน + ปิ๊บสรุป (ตัวเลขจริง) → ไฟล์ชั่วคราว
static func office_done_file(right: int, total: int, pay: int) -> String:
	var lines := PackedStringArray()
	EndingBook._file(lines, DIALOG_DIR + "office_done.txt")
	lines.append("ปิ๊บ,วันนี้พี่ขมปิดตั๋วได้ %d จาก %d ใบ ได้ค่าแรง %d บาทค่ะ" % [right, total, pay])
	if right >= total:
		lines.append("หัวหน้า,ถ้านายอยากกลับมาเมื่อไร โต๊ะนี้เป็นของนายเลย")
	elif right * 2 >= total:
		lines.append("ขม,บางใบยังช้าอยู่ แต่พอไล่ทีละขั้นก็เจอสาเหตุ")
	else:
		lines.append("ขม,ห่างไปนานมือตกเหมือนกันแฮะ ต้องทบทวนอีกเยอะ")
	return _write("user://dialog_tmp_office_done.txt", lines)


## บรรทัดเรื่องเมืองที่แทรกในบท 12 (ว่าง = ยังไม่เคยไป)
static func chapter12_lines() -> PackedStringArray:
	var c: Dictionary = GameState.city
	var out := PackedStringArray()
	var visits := int(c.get("visits", 0))
	if visits <= 0:
		return out
	if bool(c.get("tried_office", false)):
		out.append("ขม,ตอนไปลองงานที่ออฟฟิศ ผมปิดตั๋วได้ %d จาก %d ใบ ได้ช่วยแก้ปัญหาให้คนในออฟฟิศอีกครั้งก็สนุกดีครับ" % [int(c.get("office_right", 0)), int(c.get("office_total", 0))])
	if bool(c.get("met_cowork", false)):
		out.append("ขม,พี่แนนที่ร้านกาแฟในเมืองบอกว่าทำงานออนไลน์ต้องแบ่งเวลาให้ชัด ผมจำไว้แล้ว")
	if out.is_empty():
		out.append("ขม,ไปเมืองมาแล้วครับยาย รถติดกว่าเดิมอีก")
	out.append("ปิ๊บ,ปีนี้พี่ขมเข้าเมืองไป %d ครั้ง ได้เห็นของจริงแล้วคงตัดสินใจง่ายขึ้นนะคะ" % visits)
	return out


## บท 12 ที่มีเรื่องเมืองแทรก (ไม่เคยไป = ไฟล์เดิม)
static func chapter12_file() -> String:
	var add := chapter12_lines()
	if add.is_empty() or not FileAccess.file_exists(CH12_FILE):
		return CH12_FILE
	var out := PackedStringArray()
	var done := false
	for l in FileAccess.get_file_as_string(CH12_FILE).split("\n"):
		if not done and String(l).contains(CH12_MARK):
			out.append_array(add)
			done = true
		out.append(String(l).replace("\r", ""))
	if not done:
		return CH12_FILE
	return _write(CH12_OUT, out)


## บรรทัดในฉากจบที่อ้างถึงการไปเมือง (ต่อจากบทเปิดของฉากจบ)
static func ending_lines(e: StringName) -> PackedStringArray:
	var c: Dictionary = GameState.city
	var out := PackedStringArray()
	if int(c.get("visits", 0)) <= 0:
		return out
	match e:
		&"city":
			if bool(c.get("tried_office", false)):
				out.append("ปิ๊บ,วันแรกที่ออฟฟิศ พี่ขมไม่ตื่นเต้นเลย เพราะเคยมาลองปิดตั๋วกับทีมแล้ว")
			else:
				out.append("ปิ๊บ,ถนนในเมืองที่พี่ขมเคยมาดูตอนปลายปี ตอนนี้กลายเป็นทางไปทำงานทุกวัน")
		&"coworking":
			if bool(c.get("met_cowork", false)):
				out.append("ปิ๊บ,พี่ขมแบ่งเวลาแบบที่พี่แนนแนะนำ เช้าตอบตั๋วไอทีของบริษัทแบบออนไลน์ บ่ายเปิดร้าน")
			else:
				out.append("ปิ๊บ,พี่ขมเข้าเมืองเดือนละครั้งไปเจอทีม ที่เหลือทำงานจากร้านที่บ้าน")
		&"stay":
			out.append("ปิ๊บ,พี่ขมไปดูเมืองมาแล้วก็ยังเลือกบ้าน แปลว่าเลือกเพราะรู้จริง ๆ ว่าอยากอยู่ที่ไหน")
	return out


static func _write(path: String, lines: PackedStringArray) -> String:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string("\n".join(lines) + "\n")
	f.close()
	return path
