# ขมOS แบบวางใน Editor — `desktop_window2.tscn` + `desktop_minigame2.gd`

อัปเดต 11 ต.ค. 2569 · commit `3b54da5` (เริ่มสร้างซีน) · `e3a0323` (ทางลัด + เมนูเริ่ม) · **งานอยู่ระหว่างทำ — ยังไม่ได้ผูกเข้าเกม**

## 1. ทำไมถึงสร้างซีนที่ 2

ซีนเดิม `desktop_window.tscn` + `desktop_minigame.gd` (`DesktopMinigame` extends `PartMinigame`) **สร้าง UI ทั้งหมดด้วยสคริปต์**:

- `desktop_window.tscn` มีแค่ 2 โหนด (`DesktopWindow` + `PibHint`) · โหลดเข้า Editor ไปก็เห็นหน้าจอว่าง
- `desktop_minigame.gd` ยาว 2,143 บรรทัด · เดสก์ท็อป แถบงาน หน้าต่าง ปุ่ม ป้าย สร้างด้วย `Control.new()` / `add_child()` ในฟังก์ชัน `_build_*`
- **ปัญหา: ไม่เห็นหน้าตา UI ก่อนกดรัน** — จะขยับปุ่ม เปลี่ยนขนาด ย้ายไอคอน ต้องแก้ตัวเลขในโค้ดแล้วกด Play ดูผลทุกครั้ง ปรับ layout ใน Inspector / Viewport ไม่ได้ และทดลองธีมได้ยาก

ซีนใหม่แก้โดย **วาง UI เป็นโหนดจริงในซีน** (`desktop_window2.tscn`) เห็นผลใน Editor ทันที · สคริปต์ `desktop_minigame2.gd` เหลือแต่ตรรกะ (ต่อสัญญาณ · เมนู · คำสั่ง) และหยิบโหนดด้วยชื่อ unique (`%Name`)

> หลักการ: **หน้าตา = ซีน (.tscn) · พฤติกรรม = สคริปต์** · ถ้าอยากเห็นก่อนรันให้วางเป็นโหนด อย่าสร้างด้วย `new()` ยกเว้นของที่เกิดตอนรัน (หน้าต่างที่เปิดทีหลัง · เมนู popup)

## 2. โครงซีน `desktop_window2.tscn`

```
DesktopWindow (Node2D)
├── PibHint                          ← ปิ๊บ (ซีนเดิม)
└── Os (CanvasLayer)
    ├── BG (TextureRect)             ← พื้นหลังเต็มจอ
    └── Screen (Control 984×563 กลางจอ · clip_contents)
        ├── Wallpaper (TextureRect)
        ├── Taskbar (Panel)  %Taskbar
        │   └── HBoxContainer
        │       ├── StartMenu · Explorer · Browser · Settings   (ปุ่ม 40×40 · %unique)
        │       ├── Spacer
        │       └── Wifi · Sound · Disk · Clock                 (%unique)
        └── Desktop (VFlowContainer)  %Desktop   ← ไอคอนทางลัดไล่ลงเป็นแถว
            └── Doc · Pic · Download · Trash      ← instance ของ shortcut.tscn
```

- `BG` · `Screen` · `Wallpaper` ตั้ง `_edit_lock_` ไว้ (คลิกใน Viewport แล้วไม่ติดโหนดพวกนี้ · เลือกจาก Scene dock ได้) · ปุ่มแถบงานใช้ธีม `Assets/Theme/task_icon.tres`
- สคริปต์อ้างโหนดผ่าน `%StartMenu` `%Explorer` `%Browser` `%Settings` `%Wifi` `%Sound` `%Disk` `%Clock` `%Desktop` — **อย่าเปลี่ยนชื่อโหนดเหล่านี้** ไม่งั้น `@onready` เป็น null ตอนรัน
- เพิ่มทางลัดใหม่ = ลาก `shortcut.tscn` ไปไว้ใต้ `Desktop` แล้วตั้ง `icon` / `shortcut_name` ใน Inspector (ไม่ต้องแตะโค้ด)
- `Screen` ขนาด 984×563 เล็กกว่าวิวพอร์ต 1152×648 (เว้นขอบให้ `BG`) · ถ้าจะใส่ในจอมอนิเตอร์บนโต๊ะ (`framed`) ต้องคิดสเกลใหม่

## 3. ทางลัด — `DesktopShortcut` (`Scripts/MiniGame/Desktop/shortcut.gd` + `Scene/MiniGame/Desktop/shortcut.tscn`)

`@tool` · `class_name DesktopShortcut extends Control` · ขนาด 90×90

| Export | ทำอะไร | โหนดปลายทาง |
|---|---|---|
| `icon: Texture2D` | รูปไอคอน | `HBoxContainer/Icon` (TextureRect) |
| `shortcut_name: String` | ชื่อใต้ไอคอน (ค่าเริ่ม "Shortcut") | `HBoxContainer/Name` (Label) |

- ตั้งค่าใน Inspector แล้วเห็นผลใน Editor ทันที (setter เรียก `_apply()`) · เรียกจากโค้ดได้ด้วย `set_text(String)` / `set_texture(Texture2D)`
- `_apply()` หาลูกด้วย path ตายตัว — **ห้ามเปลี่ยนชื่อ `HBoxContainer` / `Icon` / `Name`** (โหนดชื่อ `HBoxContainer` จริง ๆ เป็น `VBoxContainer` ค้างจากตอนแรก)
- สไตล์เดียวกับ `MapCard` (`@tool` + setter + `_apply()`)

## 4. เมนูเริ่ม (Start menu)

`PopupMenu` สร้างในโค้ด (`_ready`) จากรายการ `items` (ไอคอนย่อ 24×24 ด้วย `_small()`) + เส้นคั่น + "ปิดเครื่อง" (id 99) · กดแล้วเรียก `_on_start_menu(id)` (0–7 = เอกสาร · รูปภาพ · ดาวน์โหลด · เบราว์เซอร์ · ตั้งค่า · ถังขยะ · ตัวจัดการงาน · ขมการ์ด) — ตอนนี้ยัง `print()` อย่างเดียว

| เรื่อง | ทำไม / ทำอย่างไร |
|---|---|
| `start_menu.popup_window = false` | `PopupMenu` ปกติปิดเองเมื่อคลิกนอกเมนู · ตั้งเป็น false = ค้างไว้จนกว่าจะ `hide()` หรือเลือกรายการ (hide_on_item_selection ยังทำงาน) |
| ปุ่มเริ่มถูก `disabled` ตอนเมนูเปิด | `_process`: `start_button.disabled = start_menu.visible` — ปุ่มเริ่มปิดเมนูไม่ได้ · ปิดได้โดยเลือกรายการเท่านั้น (ถ้าอยากให้คลิกพื้นเดสก์ท็อปปิดด้วย ให้เรียก `start_menu.hide()` ใน `_on_wall_input`) |
| ตำแหน่ง | เมนูโตลงล่างจากมุมซ้ายบนเสมอ จึงต้องวางที่ `ปุ่ม.y − ความสูงเมนู`: `pos = start_button.get_screen_position(); pos.y -= start_menu.size.y; popup(Rect2i(Vector2i(pos), Vector2i.ZERO))` · ใช้ `get_screen_position()` (คิดสเกล stretch `canvas_items`) ไม่ใช้ `global_position` · ส่งขนาด 0 ให้ใช้ขนาดต่ำสุดของเมนู |
| บั๊กเดิมที่แก้แล้ว | สูตร `global_position.y / 2 − …` ใช้ได้เฉพาะเมื่อความสูงเมนูบังเอิญตรง · แก้เหมือนกันใน `desktop_minigame.gd` `_show_start_menu()` |

## 5. สถานะ — เทียบกับซีนเดิม

| ฟีเจอร์ | `desktop_window.tscn` (เดิม) | `desktop_window2.tscn` (ใหม่) |
|---|---|---|
| ผูกเข้าเกม (`part_desktop` · ร้าน · บทฝึก) | ✅ | ⬜ ยังไม่มีที่ไหนเรียก · เปิดจาก Editor (F6) เพื่อดู/แก้ |
| โครง UI แถบงาน · เดสก์ท็อป · นาฬิกา | ✅ สร้างด้วยโค้ด | ✅ โหนดในซีน |
| ทางลัดบนเดสก์ท็อป | ✅ ในโค้ด | ✅ `DesktopShortcut` |
| เมนูเริ่ม | ✅ | 🟡 ขึ้นเมนู · แต่รายการยังไม่เปิดอะไร (`print`) |
| หน้าต่าง (`OsWindow`) · ไฟล์ · ถังขยะ · เบราว์เซอร์ · ตั้งค่า | ✅ | ⬜ |
| `DesktopTask` · คะแนน · กับดัก · ขั้นตอนงาน · `PartMinigame` | ✅ | ⬜ (สคริปต์เป็น `extends Node` ธรรมดา) |
| `framed` (จอบนโต๊ะ) · `boot_screen` · `tour_mode` · `free_mode` | ✅ | ⬜ (`free_mode` เป็นแค่ตัวแปรเลือกข้อความปุ่มปิดเครื่อง) |
| `OsExtra` (งาน 1-4…Lv2) | ✅ | ⬜ |

`_ready()` ของซีนใหม่เรียก `EventManager.hideUI()` (ซ่อน HUD) และใช้ `EventManager.get_clock_text()` กับ `Clock` — ยังไม่มีจุดเรียก `showUI()` ตอนปิดซีน (ปกติ `EventManager.minigame_end()` เรียกให้ ซึ่งซีนนี้ยังไม่ได้ผูก)

### ลำดับที่ตั้งใจจะทำต่อ ⬜

1. ย้ายความสามารถทีละอย่างจาก `desktop_minigame.gd` มาเป็นโหนดในซีน (หน้าต่าง → ไฟล์/ถังขยะ → เบราว์เซอร์ → ตั้งค่า) เทียบกับซีนเดิมทีละฟังก์ชัน
2. ผูก `DesktopTask` · คะแนน · `OsExtra` กลับเข้า (ให้สคริปต์ใหม่ extends `PartMinigame` เมื่อพร้อม)
3. ใส่ `framed` / `boot_screen` / `tour_mode` / `free_mode`
4. สลับ `PART_SCENES["part_desktop"]` · `shop_pc.gd` · บทฝึกไปซีนใหม่ แล้วเก็บซีนเดิมไว้ใน `prototype_minigame/` หรือลบ

> ระหว่างนี้**แก้บั๊ก/ฟีเจอร์ขมOS ที่เล่นอยู่จริงที่ซีนเดิม** (`desktop_minigame.gd`) — ซีนใหม่เป็นแค่ต้นแบบหน้าตา

## 6. อ้างอิง

- สถานะโค้ดขมOS ทั้งหมด: `LEVEL_DESIGN.md` ข้อ 8.5
- ไอคอน/ภาพ: `Assets/MiniGame/Desktop/` (`os_icon_*` · `os_wallpaper.jpg` · `os_start.png`)
- เทสต์: `Test/desktop_test` · `Test/desktop_lv_test` โหลด `desktop_window.tscn` (ซีนเดิม) เท่านั้น — ยังไม่มีเทสต์ของซีนใหม่
