@tool
class_name DesktopTask extends Resource
## งานบนจอ (Lv1) ในขมOS — ซีนเดียว (Scene/MiniGame/Desktop/desktop_window.tscn) ต่างกันที่ข้อมูลในไฟล์นี้
## สร้างใหม่: คลิกขวาใน Resources/Desktop/ → New Resource → DesktopTask · แล้วใส่ใน CustomerCase.desktop_task
## LEVEL_DESIGN ข้อ 3 (Lv1) · 7.3 · [Claude 9 ต.ค. 2569] ทำ 3 แบบแรก: ลงโปรแกรม · ลบไฟล์ซ้ำ · ถอนโปรแกรมโฆษณา

enum Goal {
	INSTALL, ## 1-1 ลงโปรแกรมจากเว็บทางการ (กับดัก: ปุ่มโฆษณา · ติ๊กโปรแกรมแถม)
	UNINSTALL, ## 1-3 ถอนโปรแกรมโฆษณาผ่านหน้าตั้งค่า (กับดัก: ลบแค่ไอคอน · กดโฆษณา)
	FREE_SPACE, ## 1-2 ลบไฟล์ซ้ำ + ล้างถังขยะ (กับดัก: ลบโฟลเดอร์ระบบ · ลบรูปลูกค้า)
}

## โฟลเดอร์ที่มีในเครื่อง (ใช้ในช่อง folder ของไฟล์)
const FOLDERS: PackedStringArray = ["เดสก์ท็อป", "เอกสาร", "รูปภาพ", "ดาวน์โหลด", "ระบบ (C:)"]

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
	return out
