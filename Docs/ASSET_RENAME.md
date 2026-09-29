# ASSET_RENAME.md — ไฟล์ที่ชื่อยังไม่ตรงกฎ และไฟล์ใหม่จากทีม
> ตรวจ 28 ก.ย. 2569 · commit `b504209` · คู่กับ `ASSET_NAMING.md`
> กฎตั้งชื่อ: ASCII `snake_case` ตัวพิมพ์เล็ก ขึ้นต้นด้วยคำนำหน้าโฟลเดอร์ (`ram_` `mb_` `gpu_` `fp_` `bios_` `tool_` `ui_` `wb_` `part_` `tut_` `bg_` `end_` `char_`)

## ⚠️ เปลี่ยนชื่อแล้วต้องแก้โค้ดด้วย — 22 ไฟล์

ไฟล์กลุ่มนี้ถูกอ้างใน `.gd` / `.tscn` อยู่ **ห้ามเปลี่ยนชื่อใน Explorer เฉย ๆ** ให้เปลี่ยนใน Godot (ลาก/rename ในหน้า FileSystem) Godot จะตามแก้ path กับ uid ให้เอง

| ไฟล์ปัจจุบัน | ขนาดจริง | ชื่อใหม่ | สเปก | อ้างอยู่ที่ | หมายเหตุ |
|---|---|---|---|---|---|
| `Background/HomeBG.jpg` | 1920×1080 | `Background/bg_home.jpg` | 1152×648 | `Scene/Location/Home.tscn` | ต้องย่อจาก 1920×1080 ด้วย |
| `Background/Market.jpg` | 1920×1080 | `Background/bg_market.jpg` | 1152×648 | `Scene/Location/Market.tscn` | ต้องย่อจาก 1920×1080 ด้วย |
| `Background/RoomBG.jpg` | 1920×1080 | `Background/bg_room.jpg` | 1152×648 | `Scene/Location/Room.tscn` · `Scene/MiniGame/find_item_minigame.tscn` | ต้องย่อจาก 1920×1080 ด้วย |
| `Background/settingBG.jpg` | 1152×648 | `Background/bg_setting.jpg` | 1152×648 | `Scene/Start_Scene.tscn` |  |
| `Background/stargBG2.jpg` | 1152×648 | `Background/bg_start_2.jpg` | 1152×648 | `Scene/Start_Scene.tscn` | สะกดผิด starg |
| `Background/tutorial.jpg` | 1152×648 | `Background/bg_tutorial.jpg` | 1152×648 | `Scene/Start_Scene.tscn` |  |
| `CharacterSprite/GradmaHighlight.png` | 235×421 | `CharacterSprite/char_grandma_highlight.png` | 400×500 | `Scene/Location/Home.tscn` | สะกดผิด Gradma ควรเป็น grandma |
| `CharacterSprite/GrandmaNormal.png` | 235×421 | `CharacterSprite/char_grandma_normal.png` | 400×500 | `Scene/Global.tscn` · `Scene/Location/Home.tscn` · `Scene/SimpleNPC.tscn` | ตัวใหม่มีอยู่แล้ว ชื่อ char_grandma_normal.png |
| `CharacterSprite/Idle.png` | 265×519 | `CharacterSprite/char_khom_idle.png` | — | `Scene/Global.tscn` | ตัวใหม่มีอยู่แล้ว ชื่อ char_khom_idle.png |
| `Home/door.png` | 594×880 | `Home/home_door.png` | — | `Scene/Location/Home.tscn` · `Scene/Location/Room.tscn` |  |
| `Home/doorHighlight.png` | 606×844 | `Home/home_door_highlight.png` | — | `Scene/Location/Home.tscn` · `Scene/Location/Room.tscn` |  |
| `Home/pc_down.png` | 814×514 | `Home/home_pc_down.png` | — | `Scene/Location/Home.tscn` |  |
| `Home/pc_up.png` | 814×514 | `Home/home_pc_up.png` | — | `Scene/Location/Home.tscn` |  |
| `MiniGame/PCCaseBG.jpg` | 1152×648 | `Background/bg_pc_case.jpg` | 1152×648 | `Scene/MiniGame/PartRam/part_ram.tscn` | เป็นพื้นหลังเต็มจอ ควรย้ายไปอยู่ `Background/` ให้เหมือนพื้นหลังอื่น |
| `MiniGame/PartRam/speaker.png` | 1024×1024 | `MiniGame/PartRam/ram_speaker_icon.png` | 120×120 | `Scene/MiniGame/PartRam/part_ram.tscn` | ไฟล์ใหม่ของเพื่อน · สเปกใน ASSET_NAMING คือ 120×120 แต่ไฟล์จริง 1024×1024 |
| `MiniGame/box.png` | 256×256 | `MiniGame/PartRam/ram_box_normal.png` | 256×256 | `Scene/MiniGame/find_item_minigame.tscn` | ตัวใหม่มีอยู่แล้วใน PartRam/ · เปลี่ยนโค้ดให้ชี้ตัวใหม่แล้วลบตัวเก่า |
| `MiniGame/box_on_hover.png` | 256×256 | `MiniGame/PartRam/ram_box_hover.png` | 256×256 | `Scene/MiniGame/find_item_minigame.tscn` | ตัวใหม่มีอยู่แล้วใน PartRam/ |
| `MiniGame/caution.png` | 250×250 | `UI/ui_marker_caution.png` | 250×250 | `Scene/caution_button.tscn` · `Scene/caution_marker.tscn` | ตัวใหม่มีอยู่แล้วใน UI/ |
| `MiniGame/cautionHover.png` | 250×250 | `UI/ui_marker_caution_hover.png` | 250×250 | `Scene/caution_button.tscn` | ตัวใหม่ยังไม่มี ต้องทำ |
| `MiniGame/cautionPress.png` | 350×350 | `UI/ui_marker_caution_press.png` | 250×250 | `Scene/caution_button.tscn` | ตัวใหม่ยังไม่มี ต้องทำ |
| `SpriteSheets/Idle.png` | 2500×2000 | `SpriteSheets/char_khom_idle_sheet.png` | — | `Scene/Player.tscn` · `Scripts/constant.gd` | sheet ท่ายืน |
| `SpriteSheets/Walk_Khom.png` | 3500×3500 | `—` | — | `Scene/Player.tscn` | ซ้ำกับ char_khom_walk_sheet.png ลบได้ |

## ไม่มีโค้ดอ้างถึง เปลี่ยนชื่อ/ลบได้เลย — 16 ไฟล์

| ไฟล์ปัจจุบัน | ขนาดจริง | ชื่อใหม่ | หมายเหตุ |
|---|---|---|---|
| `Background/Chapter2_bg.jpg` | 1920×1080 | `Background/bg_chapter2.jpg` | ต้องย่อจาก 1920×1080 ด้วย |
| `Background/Office.png` | 740×555 | `Background/bg_office.jpg` | เล็กกว่าจอ (740×555) ต้องทำใหม่ |
| `Background/PCCaseBG.jpg` | 1152×648 | `—` | ยังไม่ได้กำหนดชื่อใหม่ |
| `Background/placeholder.png` | 1152×648 | `Background/bg_placeholder.png` |  |
| `Background/stargBG.jpg` | 2048×1448 | `Background/bg_start.jpg` | สะกดผิด starg · ต้องย่อจาก 2048×1448 |
| `Ending/credits_bg.jpg` | 1152×648 | `—` | ยังไม่ได้กำหนดชื่อใหม่ |
| `MiniGame/eraser.png` | 359×367 | `—` | ของเก่า แทนด้วย PartRam/ram_eraser.png แล้ว |
| `MiniGame/ram.png` | 589×205 | `—` | ของเก่า ไม่ได้ใช้แล้ว ลบได้ |
| `MiniGame/ramDirty.png` | 597×213 | `—` | ของเก่า แทนด้วย PartRam/ram_dirty.png แล้ว |
| `MiniGame/ramSligtDirty.png` | 593×211 | `—` | ของเก่า สะกดผิด แทนด้วย PartRam/ram_better.png แล้ว |
| `TileMap/Tilemap_color1.png` | 1280×512 | `—` | ยังไม่ได้กำหนดชื่อใหม่ |
| `TileMap/Tilemap_color2.png` | 1280×512 | `—` | ยังไม่ได้กำหนดชื่อใหม่ |
| `TileMap/Tilemap_color3.png` | 1280×512 | `—` | ยังไม่ได้กำหนดชื่อใหม่ |
| `TileMap/Walk_Khom.png` | 3500×3500 | `—` | ยังไม่ได้กำหนดชื่อใหม่ |
| `Tutorial/BasicStart/Tutorial สอนเล่น.png` | 1312×816 | `—` | ยังไม่ได้กำหนดชื่อใหม่ |
| `Tutorial/RamCleaning/Tutorial ขัดแรม.png` | 1376×768 | `—` | ยังไม่ได้กำหนดชื่อใหม่ |

## ลำดับที่แนะนำ

1. **`speaker.png` ก่อน** — เป็นไฟล์ใหม่ที่เพิ่งเข้ามา ยังไม่มีใครอ้างมากนอกจาก `part_ram.tscn` เปลี่ยนตอนนี้เจ็บน้อยสุด และย่อจาก 1024×1024 เป็น 120×120 ไปในตัว
2. **ของเก่าที่มีตัวแทนอยู่แล้ว** — `box` · `box_on_hover` · `caution` · `GrandmaNormal` · `Idle` แค่แก้ให้โค้ดชี้ไฟล์ใหม่ที่มีอยู่แล้ว แล้วลบตัวเก่าทิ้ง ไม่ต้อง rename
3. **พื้นหลัง 6 ไฟล์** — ทำพร้อมกับตอนย่อขนาดเป็น 1152×648 จะได้แตะครั้งเดียว
4. **ที่เหลือ** ค่อยทยอยทำ ไม่เร่ง

## วิธีเปลี่ยนชื่อให้ปลอดภัย

เปลี่ยนใน **หน้าต่าง FileSystem ของ Godot** เท่านั้น (คลิกขวาที่ไฟล์ > Rename) Godot จะตามแก้ path ในทุก `.tscn`/`.tres` และรักษา `uid://` ให้อัตโนมัติ

ถ้าเปลี่ยนชื่อใน File Explorer ตรง ๆ ฉากจะหา texture ไม่เจอและขึ้นเป็นกรอบขาว ต้องไล่แก้เองทุกจุด

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 28 ก.ย. 2569 | สร้างเอกสาร — ตรวจไฟล์ asset ทั้งหมดเทียบกฎตั้งชื่อ พบ 38 ไฟล์ที่ยังไม่ตรง แยกเป็นกลุ่มที่ต้องแก้โค้ดด้วย 22 และเปลี่ยนได้เลย 16 · รวมไฟล์ใหม่ `speaker.png` จากทีม |
