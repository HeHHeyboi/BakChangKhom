class_name TesterConfig
extends Resource
## [Claude 16 พ.ย. 2569 · 0.9.0 ขั้น B] ตั้งค่าการทดสอบกับผู้เล่นจริง (ใช้ในบิลด์ผู้ทดสอบ) — ข้อมูล Resources/tester_config.tres แก้ใน Inspector
## ลิงก์ฟอร์ม: ใน Google Form กด ⋮ → "รับลิงก์ที่กรอกข้อมูลไว้ล่วงหน้า" → ใส่ช่องรหัสผู้ทดสอบเป็น T00 → คัดลอกลิงก์ → แทน T00 ด้วย {id}
## ตัวอย่าง https://docs.google.com/forms/d/e/XXXX/viewform?usp=pp_url&entry.123456789={id}
## ว่าง = ข้ามหน้าเปิดฟอร์ม (ป๊อปอัปหลังเล่นยังให้ส่งออกไฟล์ข้อมูล)

## แบบทดสอบก่อนเล่น (ทำก่อนเริ่มเกมใหม่)
@export var pre_form_url := ""
## แบบทดสอบหลังเล่น + แบบสอบถามความคิดเห็น
@export var post_form_url := ""
## เล่นครบกี่เดือน (หน้าสรุปเดือน) ถึงขึ้นป๊อปอัปหลังเล่น · 3 = ม.ค.–มี.ค. (ครบทุก Part + ยศ 2)
@export_range(1, 12) var post_after_months := 3
## เวลาโดยประมาณของแบบทดสอบ (ข้อความบนหน้า)
@export var pre_minutes := 15
@export var post_minutes := 20


## ลิงก์พร้อมรหัส · ว่าง = ไม่มีลิงก์
static func fill(url: String, id: String) -> String:
	return url.strip_edges().replace("{id}", id.uri_encode())
