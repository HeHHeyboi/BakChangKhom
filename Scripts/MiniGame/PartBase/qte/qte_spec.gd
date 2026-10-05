@tool
class_name QteSpec extends Resource
## ค่าของ QTE 1 จุด — แก้ใน Inspector (ไฟล์ใน Resources/Qte/) · ดู Docs/CORE_PART_QTE.md
## ค่า 0..1 ทุกช่อง: TIMING = ตำแหน่งตัวชี้บนแถบ · HOLD = ระดับเกจตอนปล่อย
## [Claude 5 ต.ค. 2569]

## TIMING (A) · HOLD (B) ทำแล้ว · RING · SEQUENCE · STEADY · RUB ยังไม่ทำ (runner จะให้ผ่านเป็น GOOD + เตือน)
enum Kind { TIMING, HOLD, RING, SEQUENCE, STEADY, RUB }

@export var kind: Kind = Kind.TIMING
## วินาที — TIMING: ตัวชี้วิ่งไปสุดแถบ 1 เที่ยว · HOLD: กดค้างจากว่างจนเต็มเกจ
@export_range(0.2, 10.0, 0.05) var duration := 1.6
## ช่วงที่ถือว่าผ่าน (GOOD)
@export var zone := Vector2(0.40, 0.60)
## ช่วงที่ถือว่า PERFECT (ควรอยู่ใน zone)
@export var perfect := Vector2(0.47, 0.53)
## TIMING: วิ่งกี่เที่ยวแล้วยังไม่กด = MISS · HOLD: รอเริ่มกดได้กี่วินาที = duration × ค่านี้
@export_range(1, 20) var max_sweeps := 6
## SEQUENCE (ยังไม่ทำ): ลำดับปุ่ม เช่น ["left","right"]
@export var sequence: PackedStringArray = []
## ข้อความบนจอ เช่น "ปล่อยตอนได้ยินคลิก"
@export var hint := ""
## จุดที่ควรมีเสียง (ยังไม่มีระบบเสียง)
@export var sfx_cue := ""


## โซนหลังปรับ (ครั้งแรก/โหมดช่วยให้กว้างขึ้น) · scale 1 = เท่าเดิม
func scaled_zone(r: Vector2, scale: float) -> Vector2:
	var c := (r.x + r.y) * 0.5
	var h := (r.y - r.x) * 0.5 * scale
	return Vector2(clampf(c - h, 0.0, 1.0), clampf(c + h, 0.0, 1.0))
