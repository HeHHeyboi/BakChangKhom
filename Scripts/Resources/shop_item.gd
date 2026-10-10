class_name ShopItem extends Resource
## สินค้า 1 ชิ้นในแผงตลาด (MarketStall.items) — สร้างไฟล์ .tres ใน Resources/Shop/ แล้วลากใส่แผงใน Inspector
## [Claude 10 ต.ค. 2569] ตอนนี้ยังไม่มีของขาย · ซื้อแล้วหักเงิน (GameState.add_money) + ยิง ShopPanel.bought

## ชื่อสินค้า
@export var display_name := "สินค้า"
## ราคา (บาท)
@export var price := 0
## รูป (ไม่ใส่ก็ได้)
@export var icon: Texture2D
## คำอธิบายสั้น ๆ
@export_multiline var description := ""
## รหัสไว้ให้ระบบอื่นเช็ค (เช่น &"tool_brush")
@export var id: StringName
