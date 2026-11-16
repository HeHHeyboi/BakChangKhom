class_name OnlineSeller
extends Resource
## [Claude 16 พ.ย. 2569 · 0.7.0 ขั้น I] ร้านในแอปร้านออนไลน์ที่ขึ้นมาลดราคาบางวัน (PLAN_0_7_0 ข้อ 4)
## fake = ร้านปลอม (โอนแล้วของไม่มา เงินหาย → ขึ้นบัญชีดำ) · ไม่ fake = ร้านลดราคาจริง (ของมาวันถัดไป)
## ไฟล์ Resources/Shop/Sellers/*.tres · signs = สิ่งที่ผู้เล่นเห็นบนการ์ดร้าน (ร้านปลอม = สัญญาณเตือน · ร้านจริง = สิ่งที่น่าเชื่อถือ)

@export var id: StringName
@export var display_name: String
@export var fake := false
## ส่วนลดจากราคาออนไลน์ปกติ (0.6 = ถูกลง 60%)
@export_range(0.0, 0.9) var discount := 0.2
## คะแนน/รีวิวที่โชว์ เช่น "★ 4.8 · 2,315 รีวิว" หรือ "ยังไม่มีรีวิว"
@export var rating: String
@export var signs: PackedStringArray = []
## วิธีจ่าย เช่น "โอนเข้าบัญชีส่วนตัวเท่านั้น" · "เก็บเงินปลายทางได้"
@export var payment: String
