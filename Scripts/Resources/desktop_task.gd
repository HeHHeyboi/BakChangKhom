@tool
class_name DesktopTask extends Resource
## งานบนจอ (Lv1) ในขมOS — ซีนเดียว (Scene/MiniGame/Desktop/desktop_window.tscn) ต่างกันที่ข้อมูลในไฟล์นี้
## สร้างใหม่: คลิกขวาใน Resources/Desktop/ → New Resource → DesktopTask · แล้วใส่ใน CustomerCase.desktop_task
## LEVEL_DESIGN ข้อ 3 (Lv1) · 7.3 · [Claude 9 ต.ค. 2569] ทำ 3 แบบแรก: ลงโปรแกรม · ลบไฟล์ซ้ำ · ถอนโปรแกรมโฆษณา

enum Goal {
	INSTALL, ## 1-1 ลงโปรแกรมจากเว็บทางการ (กับดัก: ปุ่มโฆษณา · ติ๊กโปรแกรมแถม)
	UNINSTALL, ## 1-3 ถอนโปรแกรมโฆษณาผ่านหน้าตั้งค่า (กับดัก: ลบแค่ไอคอน · กดโฆษณา)
	FREE_SPACE, ## 1-2 ลบไฟล์ซ้ำ + ล้างถังขยะ (กับดัก: ลบโฟลเดอร์ระบบ · ลบรูปลูกค้า)
	# [Claude 10 ต.ค. 2569] งาน Lv1 ที่เหลือ + Lv2 บนจอ — ตรรกะ/หน้าต่างอยู่ใน os_extra.gd (OsExtra)
	CLOSE_HANG, ## 1-4 ปิดโปรแกรมค้างด้วยตัวจัดการงาน (กับดัก: ปิดโปรแกรมระบบ · ปิดงานที่ลูกค้ายังไม่บันทึก)
	PRINTER, ## 1-5 เพิ่มเครื่องพิมพ์ + ตั้งค่าเริ่มต้น + พิมพ์ทดสอบ (กับดัก: เพิ่มเครื่องของห้องอื่น)
	SOUND, ## 1-6 เสียงไม่ออก: เลือกอุปกรณ์ · เปิดเสียง (กับดัก: ถอนไดรเวอร์เสียง)
	WIFI, ## 1-7 ต่อ Wi-Fi ด้วยรหัสที่ลูกค้าบอก (กับดัก: ต่อเน็ตฟรีไม่มีรหัส)
	BACKUP, ## 1-8 คัดลอกรูปลง USB + ถอดอย่างปลอดภัย (กับดัก: "ย้าย" แทน "คัดลอก")
	STARTUP, ## 1-9 ปิดโปรแกรมเปิดพร้อมเครื่อง (กับดัก: ปิดแอนตี้ไวรัส/ของระบบ)
	UPDATE, ## 1-10 อัปเดต + รีสตาร์ต (กับดัก: รีสตาร์ตทั้งที่งานยังไม่บันทึก · ปิดเครื่องกลางอัปเดต)
	VIRUS_SCAN, ## Lv2 เครื่องอืด: สแกนไวรัส + กักกัน + ล้างไฟล์ชั่วคราว (กับดัก: ปิดการป้องกัน · อนุญาตไวรัส)
	DISPLAY, ## Lv2 จอแตก/ตัวใหญ่: ตั้งความละเอียดที่แนะนำ + ขนาด 100% (กับดัก: เก็บความละเอียดที่จอไม่รองรับ)
}

## โฟลเดอร์ที่มีในเครื่อง (ใช้ในช่อง folder ของไฟล์)
const FOLDERS: PackedStringArray = ["เดสก์ท็อป", "เอกสาร", "รูปภาพ", "ดาวน์โหลด", "ระบบ (C:)", "USB (E:)"]
## โฟลเดอร์ USB (โชว์ในหน้าต่างไฟล์เมื่อ usb_drive = true)
const USB := "USB (E:)"

@export_group("งาน")
@export var goal: Goal = Goal.INSTALL
## ชื่องานบนกระดาษโน้ต เช่น "ลงแอปพูดคุยให้ยาย"
@export var title := ""
## ชื่อเครื่องบนหัวหน้าต่าง เช่น "คอมของยาย"
@export var pc_name := "คอมของลูกค้า"
## สิ่งที่ลูกค้าขอ (บรรทัดใต้ชื่องานบนกระดาษโน้ต)
@export_multiline var request := ""

@export_group("ไฟล์ในเครื่อง")
## {name, size_mb, folder, kind, note, dup_of}
## kind: "user" ของลูกค้า (ห้ามลบ) · "dup" ไฟล์ซ้ำ · "system" ไฟล์ระบบ (ห้ามลบ) · "junk" ขยะ
##       "installer" ตัวติดตั้งของจริง · "fake_installer" ตัวติดตั้งปลอม (ได้โปรแกรมโฆษณา)
## note = ข้อความตอนเปิดดู · dup_of = ชื่อไฟล์ต้นฉบับ (ของ dup)
@export var files: Array[Dictionary] = []
## {name, publisher, size_mb, adware, system, desktop_icon}
@export var programs: Array[Dictionary] = []
## พื้นที่ทั้งหมด / ที่เหลือตอนเริ่ม (MB)
@export var disk_total_mb := 64000
@export var disk_free_mb := 8000
## FREE_SPACE: ต้องเหลืออย่างน้อยกี่ MB ถึงผ่าน
@export var free_space_target_mb := 0

@export_group("ลงโปรแกรม (INSTALL)")
## ชื่อโปรแกรมที่ต้องลง (ชื่อในเกม ไม่ใช้ชื่อ/โลโก้ของจริง)
@export var install_name := "พูดคุย"
## เว็บทางการ (โชว์ในแถบที่อยู่ — สอนให้ดูที่อยู่เว็บ)
@export var install_site := "pudkui.co.th"
@export var install_size_mb := 350
## ชื่อโปรแกรมแถมในวิซาร์ด / จากปุ่มโฆษณา
@export var bundle_name := "ลดราคาเด้งไว"
## หน้าตั้งค่า/เบราว์เซอร์มีโฆษณาเด้ง (ปุ่ม DOWNLOAD NOW)
@export var browser_ad := true

@export_group("งานอื่น (Lv1 1-4 … 1-10 · Lv2)")
## บรรทัดที่ขึ้นบนกระดาษโน้ตหลังถามลูกค้าถูกข้อ เช่น "รหัส Wi-Fi: maikai2569"
@export var ask_note := ""
## CLOSE_HANG / STARTUP — โปรแกรมในเครื่อง {name, kind: "app"|"hang"|"system"|"unsaved", startup: bool, boot_s: int, cpu: int}
## hang = ค้าง (ต้องปิด) · unsaved = ลูกค้ายังเปิดใช้อยู่/ยังไม่บันทึก (อย่าปิด) · system = ของระบบ (อย่าปิด)
@export var processes: Array[Dictionary] = []
## STARTUP: เปิดเครื่องต้องเร็วกว่ากี่วินาที (8 วิ + boot_s ของตัวที่เปิดพร้อมเครื่อง)
@export var boot_target_s := 25
## PRINTER — เครื่องพิมพ์ที่ค้นเจอ {name, note, right: bool}
@export var printers: Array[Dictionary] = []
## SOUND — อุปกรณ์เสียง {name, works: bool} · เริ่มที่ sound_device · ปิดเสียงอยู่ไหม · ระดับเสียงเริ่ม
@export var sound_devices: Array[Dictionary] = []
@export var sound_device := 0
@export var sound_muted := true
@export var sound_volume := 0
## WIFI — เครือข่ายที่เห็น {name, locked: bool, password, right: bool, signal: 1–3}
@export var wifi: Array[Dictionary] = []
## BACKUP — มี USB เสียบอยู่ · ความจุ (MB) · โฟลเดอร์ที่ต้องสำรอง (ไฟล์ kind "user" ในนั้น)
@export var usb_drive := false
@export var usb_mb := 16000
@export var backup_folder := "รูปภาพ"
## UPDATE — ขนาดอัปเดต · งานที่ลูกค้าเปิดค้างไว้ยังไม่บันทึก ("" = ไม่มี)
@export var update_mb := 900
@export var unsaved_doc := ""
## VIRUS_SCAN — ไวรัสที่สแกนเจอ {name, where} · ไฟล์ชั่วคราว (MB)
@export var threats: Array[Dictionary] = []
@export var temp_mb := 0
## DISPLAY — ความละเอียด {name, ok: bool (จอรองรับ), best: bool} · เริ่มที่ display_res · ขนาดตัวหนังสือเริ่ม/ที่ถูก (%)
@export var resolutions: Array[Dictionary] = []
@export var display_res := 0
@export var display_scale := 100
@export var display_scale_best := 100

@export_group("กับดัก")
## &"fake_download" ปุ่มโฆษณา · &"bundle" ติ๊กโปรแกรมแถม · &"delete_system" ลบไฟล์ระบบ
## &"delete_user" ลบของลูกค้า · &"click_ad" คลิกในหน้าต่างโฆษณา · &"icon_only" ลบแค่ไอคอน
## ไม่อยู่ในรายการ = ไม่หักคะแนน (ยังมีผลในเกมอยู่)
@export var traps: Array[StringName] = [&"fake_download", &"bundle", &"delete_system", &"delete_user", &"click_ad"]

@export_group("ขั้น 1 ฟัง · ขั้น 5 บอก")
## คำถามให้เลือกถามลูกค้า 3 ข้อ · ask_best = ข้อที่ดีที่สุด (เริ่มนับ 0)
@export var ask_options: PackedStringArray = []
@export var ask_best := 0
## ลูกค้าตอบ (เมื่อถามข้อที่ดี) — มีคำใบ้งาน
@export_multiline var ask_answer := ""
## ลูกค้าตอบเมื่อถามข้อที่ไม่ตรง
@export_multiline var ask_answer_wrong := "เอ… ไม่แน่ใจเหมือนกันนะ ขอแค่ใช้ได้ก็พอ"
## คำอธิบายให้ลูกค้าตอนส่งงาน 3 ข้อ · explain_best = ข้อที่ดีที่สุด
@export var explain_options: PackedStringArray = []
@export var explain_best := 0

@export_group("ปิ๊บ")
## ปิ๊บพูดตอนเริ่ม (บรรทัดละประโยค)
@export var pib_intro: PackedStringArray = []
## ปิ๊บพูดตอนเช็กผ่าน (สรุปบทเรียน)
@export var pib_lesson: PackedStringArray = []


## ช่องที่ขาด — CustomerCase.problems() เรียกต่อ
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	if title.strip_edges() == "":
		out.append("DesktopTask ไม่มี title")
	if ask_options.size() < 2 or ask_best < 0 or ask_best >= ask_options.size():
		out.append("DesktopTask ask_options ต้องมี ≥2 ข้อ และ ask_best อยู่ในช่วง")
	if explain_options.size() < 2 or explain_best < 0 or explain_best >= explain_options.size():
		out.append("DesktopTask explain_options ต้องมี ≥2 ข้อ และ explain_best อยู่ในช่วง")
	for f in files:
		if not f.has("name") or not f.has("folder"):
			out.append("DesktopTask ไฟล์ต้องมี name และ folder: %s" % f)
		elif not FOLDERS.has(String(f.folder)):
			out.append("DesktopTask โฟลเดอร์ \"%s\" ไม่มี (ใช้ %s)" % [f.folder, ", ".join(FOLDERS)])
	match goal:
		Goal.UNINSTALL:
			if not programs.any(func(p): return p.get("adware", false)):
				out.append("DesktopTask UNINSTALL ต้องมีโปรแกรม adware อย่างน้อย 1")
		Goal.FREE_SPACE:
			if free_space_target_mb <= disk_free_mb:
				out.append("DesktopTask FREE_SPACE: free_space_target_mb ต้องมากกว่า disk_free_mb")
		Goal.CLOSE_HANG:
			if not processes.any(func(p): return p.get("kind", "") == "hang"):
				out.append("DesktopTask CLOSE_HANG ต้องมีโปรแกรม kind = hang")
		Goal.STARTUP:
			if not processes.any(func(p): return p.get("startup", false) and p.get("kind", "") != "system"):
				out.append("DesktopTask STARTUP ต้องมีโปรแกรมเปิดพร้อมเครื่องที่ปิดได้")
		Goal.PRINTER:
			if not printers.any(func(p): return p.get("right", false)):
				out.append("DesktopTask PRINTER ต้องมีเครื่องพิมพ์ right = true")
		Goal.SOUND:
			if not sound_devices.any(func(d): return d.get("works", false)):
				out.append("DesktopTask SOUND ต้องมีอุปกรณ์ works = true")
		Goal.WIFI:
			if not wifi.any(func(w): return w.get("right", false)):
				out.append("DesktopTask WIFI ต้องมีเครือข่าย right = true")
		Goal.BACKUP:
			if not usb_drive or not files.any(func(f): return f.get("folder", "") == backup_folder and f.get("kind", "") == "user"):
				out.append("DesktopTask BACKUP ต้องมี usb_drive และไฟล์ user ใน backup_folder")
		Goal.VIRUS_SCAN:
			if threats.is_empty():
				out.append("DesktopTask VIRUS_SCAN ต้องมี threats")
		Goal.DISPLAY:
			if not resolutions.any(func(r): return r.get("best", false)):
				out.append("DesktopTask DISPLAY ต้องมีความละเอียด best = true")
	return out
