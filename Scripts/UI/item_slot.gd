class_name ItemSlot extends Button
## ช่องของ 1 ช่อง — ใช้ทั้งในร้านค้า (ShopPanel) และหน้าคลัง (StoragePanel)
## โหนดอยู่ใน Scene/UI/item_slot.tscn (ปรับขนาด/สี/ฟอนต์ใน Inspector) · [Claude 13 ต.ค. 2569]

@onready var icon_rect: TextureRect = %Icon
@onready var emoji_label: Label = %Emoji
@onready var name_label: Label = %ItemName
@onready var badge_label: Label = %Badge
@onready var bottom_label: Label = %Bottom
@onready var tag_label: Label = %Tag

## ข้อมูลที่ผูกกับช่อง (ItemDef ในร้าน · index ของคลัง)
var item: ItemDef
var index := -1


## top = บรรทัดใต้ชื่อ (สภาพ/จำนวน) · bottom = ราคา/สต็อก · tag = ป้ายมุม (เช่น 🔖 จอง · 🔒)
func set_item(p_item: ItemDef, top: String, bottom: String, tag := "") -> void:
	item = p_item
	icon_rect.texture = p_item.icon if p_item else null
	icon_rect.visible = icon_rect.texture != null
	emoji_label.text = p_item.emoji if p_item else ""
	emoji_label.visible = p_item != null and icon_rect.texture == null
	name_label.text = p_item.display_name if p_item else ""
	badge_label.text = top
	bottom_label.text = bottom
	tag_label.text = tag
	tag_label.visible = tag != ""
	tooltip_text = (p_item.display_name + ("\n" + p_item.description if p_item.description != "" else "")) if p_item else ""
	modulate = Color.WHITE
	disabled = false


## ช่องว่าง (คลัง)
func set_empty() -> void:
	item = null
	index = -1
	icon_rect.visible = false
	emoji_label.visible = false
	name_label.text = ""
	badge_label.text = "ว่าง"
	bottom_label.text = ""
	tag_label.visible = false
	tooltip_text = ""
	disabled = true
	modulate = Color(1, 1, 1, 0.55)
