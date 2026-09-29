class_name PcPart extends Resource
## ข้อมูลชิ้นส่วนคอม 1 ชิ้น — ใช้สร้างโมเดล "กล่องแปะรูป" ในฉาก 3D (Docs/ART_25D_PLAN.md ข้อ 2–3)
## ชิ้นใหม่ = ไฟล์ .tres ใหม่ 1 ไฟล์ ไม่ต้องมีไฟล์โมเดล
## หน่วย: 1 = 10 ซม.

enum Face { NONE, TOP, SIDE_X, SIDE_Z }

@export var id: StringName # &"ram_stick"
@export var display_name: String # "แรม (RAM)"
@export_multiline var role: String # "ที่พักงานชั่วคราวของคอม"
@export var icon: Texture2D # รูปบนถาด/การ์ด (2D)

@export_group("Model")
@export_enum("box", "cylinder") var shape: String = "box"
@export var size := Vector3(1, 0.1, 1)
@export var color := Color(0.25, 0.45, 0.25)
@export var texture: Texture2D # แปะบนหน้าที่เลือกใน texture_face (PNG 2D ที่มีอยู่)
@export var texture_face: Face = Face.TOP
## ร่องบาก/สัญลักษณ์บอกทิศ — ตำแหน่งเป็นสัดส่วนตามแกนยาว 0–1 · < 0 = ไม่มี
@export_range(-1.0, 1.0) var notch_pos := -1.0
## รายละเอียดที่สร้างจากโค้ดแทนรูป (ดู PartBody3D._build_procedural)
##   dimm = แรมแท่ง (PCB + ชิป 8 ตัวต่อด้าน + ขาทอง + ร่องบาก) · dimm_slot = สล็อตแรม (+ สันกันเสียบกลับด้าน)
@export_enum("none", "dimm", "dimm_slot") var procedural: String = "none"

@export_group("Install")
@export var socket_type: StringName # &"ram_slot"
@export var requires: Array[StringName] = [] # ต้องติดตั้งชิ้นไหนก่อน
@export var needs_orientation := false # ต้องหันให้ถูกทิศก่อนวาง
@export var core_part: StringName # &"ram" → การ์ด "จะได้ซ่อมใน Part ___"

@export_group("Pib")
@export var pib_before: String # header ใน Assets/Dialog/MiniGame/*_Pib.txt
@export var pib_wrong_socket: String
@export var pib_wrong_order: String
@export var pib_wrong_orientation: String
