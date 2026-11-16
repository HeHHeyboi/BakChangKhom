class_name OfficeTicket
extends Resource
## [Claude 16 พ.ย. 2569 · 0.9.5 ขั้น C] ตั๋วแจ้งปัญหาที่ออฟฟิศในเมือง — งานไอทีซัพพอร์ต (ผู้ใช้ 16 พ.ย.: แก้ปัญหาให้คนในออฟฟิศ ไม่ลงโค้ดลึก)
## ไฟล์ใน Resources/City/Tickets/ · แก้ใน Inspector
## เล่น 2 ขั้น: 1) ตรวจ = กดปุ่มใน actions → จอดำพิมพ์คำสั่ง/สิ่งที่เห็นจาก results (ช่องเดียวกัน) 2) แก้ = เลือกจาก choices (ช่องแรก = ถูก · สลับตอนแสดง)
## ลองงาน 1 ครั้ง = 3 ใบคนละหมวด (CityBook.pick_tickets) · ไม่ซ้ำใบที่เคยทำ

enum Category { NETWORK, HARDWARE, ACCOUNT, SOFTWARE }
const CATEGORY_NAMES := ["เครือข่าย", "เครื่อง/อุปกรณ์", "บัญชี/ความปลอดภัย", "โปรแกรม"]

@export var id: StringName
@export var category: Category = Category.NETWORK
## หัวตั๋ว เช่น "เครื่องเข้าเน็ตไม่ได้"
@export var title: String
## ใครแจ้ง เช่น "ฝ่ายบัญชี"
@export var from: String
## ผู้แจ้งเล่าปัญหา
@export_multiline var ask: String
## ปุ่มตรวจ (สั้น ๆ) เช่น "ipconfig" · "ดูสายจอหลังเครื่อง"
@export var actions: PackedStringArray = []
## ผลของปุ่มแต่ละอัน (ช่องตรงกับ actions) · บรรทัดแรก = คำสั่ง/สิ่งที่ทำ ที่เหลือ = ผล
@export var results: PackedStringArray = []
## คำถามตอนแก้
@export var question: String = "จะแก้ยังไง"
@export var choices: PackedStringArray = []
## ปิ๊บอธิบายหลังตอบ (ทั้งถูกและผิด)
@export_multiline var explain: String
## เทคนิคที่ใช้ (ขึ้นใน playlog/city.csv)
@export var skill: String


func category_name() -> String:
	return CATEGORY_NAMES[clampi(category, 0, CATEGORY_NAMES.size() - 1)]
