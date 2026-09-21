# BUG_LIST.md — รายการบั๊กทั้งหมดที่ตรวจพบ

> ตรวจจากโค้ดจริงที่ commit `1c9040a` · อัปเดต 21 ก.ย. 2569 · Godot 4.7
> เอกสารคู่กัน: `Docs/SYNC_REVIEW.md` (รายละเอียดวิธีแก้) · `Docs/ASSET_TODO.md` (asset ที่ต้องทำ)
> สถานะ: ✅ แก้แล้วในรีโป · 🔧 รอทำใน Godot · ⬜ ยังไม่แก้

---

## สรุป

| ระดับ | ✅ แก้แล้ว | 🔧 รอทำใน Godot | ⬜ ยังไม่แก้ | รวม |
|---|---|---|---|---|
| 🔴 Critical | 5 | 1 | 2 | 8 |
| 🟡 High | 6 | 1 | 4 | 11 |
| 🟢 Low | 2 | 0 | 6 | 8 |
| **รวม** | **13** | **2** | **12** | **27** |

---

## 🔴 Critical

### BUG-01 ✅ ปุ่ม `!` ในห้องของขมไม่ขึ้นเลย — เข้าห้องแล้วเหลือแต่ห้องเปล่า

| | |
|---|---|
| ไฟล์ | `Scene/Location/Room.tscn` บรรทัด 33 |
| อาการ | เดินเข้าห้อง ไม่มีปุ่ม `!` ให้กด ทำอะไรต่อไม่ได้ ไม่มี error แดงให้เห็น |
| สาเหตุ | `trackEvents` ถูกเซฟเป็น `Dictionary[Variant, PackedByteArray]` แต่สคริปต์ประกาศเป็น `Dictionary[EventManager.EventID, PackedByteArray]` — Godot 4 เข้มเรื่อง typed dictionary พอ key type ไม่ตรงค่าจะ **ไม่ถูก assign** property เลยว่าง → `trackEvents.has(id)` เป็น false ตลอด → `visible = false` ตลอด |
| แก้ | เปลี่ยนเป็น `Dictionary[int, PackedByteArray]` ให้เหมือน `Home.tscn` |
| ป้องกันซ้ำ | หลังแก้ dictionary ใน Inspector ทุกครั้ง ให้เปิดไฟล์ `.tscn` เช็กว่าเป็น `Dictionary[int, ...]` ไม่ใช่ `Variant` |

### BUG-02 ✅ กด CautionMarker ก่อนผูก event → crash

| | |
|---|---|
| ไฟล์ | `Scripts/caution_marker.gd::_on_pressed()` |
| สาเหตุ | `cur_id` เริ่มที่ `EventID.NONE` ซึ่งไม่มีใน `eventMap` → `eventMap[NONE]` = Invalid access |
| แก้ | เพิ่ม guard `if not EventManager.eventMap.has(cur_id): return` |

### BUG-03 ✅ กดประตูระหว่างบทสนทนา/มินิเกม → ฉากหลุด มินิเกมค้างลอย

| | |
|---|---|
| ไฟล์ | `Scripts/Home/door.gd` · `Scripts/Room/door.gd` |
| สาเหตุ | `change_scene_to_file()` ถูกเรียกทันทีโดยไม่เช็กสถานะ — ฉากเดิมถูกปล่อย แต่มินิเกมที่ `add_child` ไว้ที่ `root` ไม่ถูกลบ |
| แก้ | `if Global.isDialogShown() or Global.isInMinigame(): return` |

### BUG-04 ✅ `Global.in_minigame` ค้าง `true` หลังจบมินิเกมขัดแรม

| | |
|---|---|
| ไฟล์ | `Scripts/MiniGame/minigame1.gd::_on_return_pressed()` |
| ผล | ตัวละครขยับไม่ได้ / ระบบที่เช็ก `isInMinigame()` ทำงานผิดหลังเล่นจบ |
| แก้ | เพิ่ม `Global.in_minigame = false` (find-item ทำถูกอยู่แล้ว) |

### BUG-05 ✅ เรียก tutorial ของ state ที่ยังไม่มีสไลด์ → crash ทันที

| | |
|---|---|
| ไฟล์ | `Scripts/EventManager/tutorial.gd::show_tutorial()` |
| สาเหตุ | `_slides[tutor_index]` กับ dict ที่มีแค่ key 0 และ 2 จาก 7 state |
| แก้ | guard `_slides.has()` + `push_warning` + `on_tutorial_end.emit()` เพื่อให้เกมเดินต่อได้ |

### BUG-09 🔧 ไฟล์ `.import` ไม่ตรงกับชื่อรูป 39 คู่

| | |
|---|---|
| ที่ | `Assets/MiniGame/Part*/` |
| สาเหตุ | ตอน rename `Tier* → Part*` รูปเปลี่ยนชื่อแต่ `.import` ยังเป็นชื่อเก่า |
| ผล | ตอนนี้ยังหา texture เจอเพราะ cache ใน `.godot/` แต่พอ clone ใหม่หรือลบ cache **uid ตายทั้งชุด** |
| สถานะ | ลบ `.import` กำพร้าออกแล้ว — **เหลือเปิด Godot 1 รอบให้ import ใหม่ แล้ว `git add Assets/MiniGame/Part*/*.import`** |

### BUG-14 ⬜ `simple_npc.gd` เรียก `show_dialog()` ผิด signature

| | |
|---|---|
| ไฟล์ | `Scripts/simple_npc.gd` บรรทัด 20 |
| โค้ด | `DialogScene.show_dialog(Constant.CHAPTER1_RETURN_HOME_TEXT, player, ["ขม,ยาย"])` |
| ผิดตรงไหน | ส่ง `player` (Node) ในตำแหน่ง `bg_name: String` · `chars` เป็น string เดียวรวมกัน ควรเป็น `["ขม", "ยาย"]` |
| ผลจริง | ตอนนี้ยังไม่ระเบิดเพราะ `SimpleNPC` อยู่ใน `MainGame.tscn` ที่ไม่ถูกโหลด (ดู BUG-15) — พอเอา MainGame กลับมาใช้จะพังทันที |
| แก้ | `DialogScene.show_dialog(Constant.CHAPTER1_RETURN_HOME_TEXT, Constant.CHAPTER2_BG_IMAGE, ["ขม", "ยาย"])` |

### BUG-15 ⬜ `MainGame.tscn` ไม่เคยถูกโหลด — ทั้งเกมไม่มี Player

| | |
|---|---|
| หลักฐาน | `project.godot` → `run/main_scene = uid://d2rbfnaviwwmi` = **`Start_Scene.tscn`** · `MainGame.tscn` ไม่ถูกอ้างจากที่ไหนเลย · `Player.tscn` ถูก instance แค่ใน `MainGame.tscn` กับ `Market.tscn` |
| flow จริง | Start_Scene → tutorial → `change_scene_to_file(Home.tscn)` → Home/Room เป็น Control ล้วน ไม่มีตัวละคร |
| ผล | `player.gd`, `simple_npc.gd`, physics layer, `Market/exit.gd` ที่เช็ก `body is Player` เป็น dead code · `CLAUDE.md` ที่เขียนว่า main scene คือ MainGame **ไม่ตรงกับความจริง** |
| ต้องตัดสินใจ | (ก) เอาการเดินกลับมา — ให้ Home/Room เป็นลูกของ MainGame แทนการ `change_scene_to_file` หรือ (ข) เล่นแบบ point-and-click ทั้งเกม แล้วลบ Player/SimpleNPC ทิ้ง · **เลือกทางนี้ก่อนเริ่ม Repair Loop** เพราะ Scene S2 ออกแบบไว้แบบ point-and-click |

---

## 🟡 High

### BUG-06 ✅ `TutorialSlides.curIndex` ไม่รีเซ็ต — เปิด tutorial ซ้ำเริ่มที่สไลด์สุดท้าย

`Scripts/Resources/tutorial_slides.gd` — `TutorialSlides` เป็น Resource ที่แชร์กันทั้งเกม เพิ่ม `reset()` แล้วเรียกจาก `show_tutorial()`

### BUG-07 ✅ `print_rich(_slides)` ค้างใน `get_cur_slide()`

`Scripts/Resources/tutorial_slides.gd` — สแปม console ทุกครั้งที่เปิดสไลด์

### BUG-08 ✅ `match clikTime` เทียบค่าเป๊ะ

`Scripts/MiniGame/minigame1.gd` — เปลี่ยนภาพแรมเฉพาะตอนค่าเท่ากับ 0/10/15 พอดี · เปลี่ยนเป็น `if/elif >=` แล้ว

### BUG-10 ✅ ซีน find-item ชี้ texture พาธเก่า

`Scene/MiniGame/find_item_minigame.tscn` ชี้ `Assets/MiniGame/Tier1Ram/mg1_eraser.png` ที่ไม่มีแล้ว → เปลี่ยนเป็น `PartRam/ram_eraser.png` และตัด `uid` เก่าออกให้ Godot เขียนใหม่

### BUG-11 ✅ ข้อความมินิเกมหายางลบ — บรรทัดแรกไม่เคยถูกใช้ + สะกดผิด

`Scripts/MiniGame/find_item_minigame.gd` — `dialog_arr[-box_click_count]` ทำให้ index 0 ไม่เคยแสดง · "อยู่ใหนนะ?" สะกดผิด · แก้เป็นขึ้นข้อความเปิดเรื่องตั้งแต่เข้าฉาก

### BUG-19 🔧 `Scene/MiniGame/Minigame1.scn` เป็นไฟล์ binary

diff/merge ไม่ได้ review ไม่ได้ → Save As เป็น `Scene/MiniGame/PartRam.tscn` แล้วแก้ `Constant.MINIGAME1_SCENE`
*(ยังไม่แก้ค่าคงที่ให้ เพราะถ้าแก้ก่อนมีไฟล์จริงเกมจะโหลดซีนไม่เจอ)*

### BUG-16 ⬜ tutorial กับมินิเกมขึ้นพร้อมกัน — คลิกทะลุ

| | |
|---|---|
| ไฟล์ | `Scripts/EventManager/event_manager.gd::trigger_step()` case 3 |
| สาเหตุ | เรียก `show_tutorial()` แล้ว `add_child(minigame)` ในเฟรมเดียวกัน · tutorial เป็น CanvasLayer 120 อยู่บน แต่ `minigame1.gd::_input()` รับคลิกทุกคลิกโดยไม่เช็กว่าถูกใช้ไปแล้ว → กด "Next" บน tutorial ไปสตาร์ตมินิเกมข้างล่างด้วย |
| แก้ | รอ `EventManager.on_tutorial_finish` แล้วค่อย `add_child(minigame)` · หรือใน `minigame1.gd::_input()` เช็ก `if Global.isDialogShown(): return` + `get_viewport().set_input_as_handled()` |

### BUG-17 ⬜ มินิเกมถูก `add_child` ที่ `get_tree().root`

ไม่ได้อยู่ใต้ฉากปัจจุบัน → ไม่บล็อกอินพุตของฉากข้างล่าง (กดปุ่มในห้องทะลุผ่านมินิเกมได้) และไม่ถูกลบตอนเปลี่ยนฉาก
**แก้:** ใส่ `Control` เต็มจอที่ `mouse_filter = STOP` เป็นฉากหลังของมินิเกม หรือ add เข้า `get_tree().current_scene` แทน root

### BUG-18 ⬜ `parse_text()` พังถ้าบรรทัดบทไม่มี `,`

| | |
|---|---|
| ไฟล์ | `Scripts/DialogSystem/dialog_scene.gd::parse_text()` |
| สาเหตุ | `body = text.split(",")` แล้วใช้ `body[1]` ทันที — บรรทัดที่ไม่มี `,` จะ index out of range |
| แก้ | `if body.size() < 2: push_error("บรรทัดบทผิดรูปแบบ: %s" % text); return null` |

### BUG-26 ⬜ `Event` เก็บ state ไว้ใน Resource ที่แชร์กัน

| | |
|---|---|
| ไฟล์ | `Scripts/Resources/event.gd` |
| สาเหตุ | `currentTask` / `isDone` เป็นตัวแปรใน Resource `main.tres` ซึ่ง Godot cache ไว้ตัวเดียวทั้งเกม (ปัญหาชนิดเดียวกับ BUG-06) |
| ผล | เริ่มเกมใหม่ / `change_scene` แล้วความคืบหน้า quest ไม่รีเซ็ต จนกว่าจะปิดโปรแกรม · ตอนทำ Save/Load จะเจอปัญหานี้เต็ม ๆ |
| แก้ | เพิ่ม `func reset(): currentTask = 0; isDone = false` แล้วเรียกจาก `EventManager.init_manager()` หรือใช้ `event.duplicate()` ตอนเริ่มเกม |

---

## 🟢 Low

### BUG-12 ✅ ชื่อตัวละครสะกดผิดในไฟล์บท

`Assets/Dialog/MainQuest/GoToRoom.txt` บรรทัด 4 — `ชม,` → `ขม,` (ถ้าวันหลังส่ง `chars` เข้าไปจะ crash ที่ `_CharacterMap["ชม"]`)

### BUG-13 ✅ ข้อความ quest เป็นภาษาอังกฤษปนเกมภาษาไทย

`Resources/main.tres` — เปลี่ยนเป็นไทยทั้ง 4 ข้อแล้ว

### BUG-20 ⬜ `minigame_end()` อิงเลข task แบบ hardcode

`event_manager.gd` — `if [2, 3].has(task)` แทรก task ใหม่ตรงกลางเมื่อไรพังทันที → เปลี่ยนเป็น `minigame_end(success: bool = true, score: Dictionary = {})`

### BUG-21 ⬜ เดินทแยงมุมไม่ได้

`Scripts/player.gd::_physics_process()` ใช้ `if / elif` ไล่ทีละทิศ → กด W+D พร้อมกันจะได้แค่ขึ้น
**แก้:** ใช้ `Input.get_vector("left", "right", "up", "down")` แทนทั้งบล็อก

### BUG-22 ⬜ กด `E` ที่ไหนก็ toggle แผนที่ได้

`Scripts/Market/exit.gd::_input()` ดักคีย์ E แบบ global โดยไม่เช็กว่าผู้เล่นอยู่ในโซนหรือไม่ และไม่เช็ก `isDialogShown()` / `isInMinigame()`
**แก้:** ใช้ flag `playerEnter` แบบเดียวกับ `simple_npc.gd` + guard สถานะ

### BUG-23 ⬜ `Global.on_start` เขียนอย่างเดียว ไม่มีใครอ่าน

`global.gd` + `start_scene.gd` — dead field ลบทิ้งหรือเอาไปใช้จริง

### BUG-24 ⬜ `class_name QuesetBoard` สะกดผิด

`Scripts/EventManager/quest_board.gd` → `QuestBoard` (แก้พร้อมกับที่อ้างใน `event_manager.gd`)

### BUG-25 ⬜ ชื่อไฟล์สะกดผิดค้างจากของเดิม

`ramSligtDirty.png` · `GradmaHighlight.png` · `Prolouge.txt` — แก้ตอนล้าง asset ชุดเก่า

---

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 21 ก.ย. 2569 | สร้างเอกสาร — รวมบั๊ก 27 รายการจากการไล่โค้ดทั้งโปรเจกต์ที่ commit `1c9040a` · แก้แล้ว 13 · รอทำใน Godot 2 · ยังไม่แก้ 12 |
