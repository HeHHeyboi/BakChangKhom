@tool
class_name CameraPoint3D extends Marker3D
## มุมกล้องสำเร็จรูป 1 มุม — วางเป็น node ใน World ตรงจุดที่อยากให้กล้องหมุนรอบ (ตำแหน่ง node = จุดโฟกัส)
## phase เรียก stage.go_to(&"ชื่อ node") แล้วกล้องเลื่อนไปเองแบบนุ่ม ๆ

@export_range(-360, 360) var yaw := 0.0 ## 0 = มองจากฝั่ง +Z · 90 = มองจากฝั่ง +X
@export_range(5, 89) var pitch := 40.0 ## มุมก้ม
@export_range(0.3, 20) var distance := 2.0
## ชื่อบนปุ่มสลับมุม (แถบบนซ้าย) · ว่าง = ไม่มีปุ่ม (มุมซูมย่อย กด "◀ กลับ" ออกได้)
@export var label := ""
