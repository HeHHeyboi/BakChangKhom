# BUG_LIST.md — รายการบั๊กทั้งหมดที่ตรวจพบ

> ตรวจจากโค้ดจริงที่ commit `1c9040a` · อัปเดต 23 ก.ย. 2569 (audit หลัง commit `cd053b4`, ปิด BUG-18/BUG-24 จาก working-tree changes ที่ยังไม่ commit) · Godot 4.7
> เอกสารคู่กัน: `Docs/SYNC_REVIEW.md` (รายละเอียดวิธีแก้) · `Docs/ASSET_TODO.md` (asset ที่ต้องทำ)
> สถานะ: ✅ แก้แล้วในรีโป · 🔧 รอทำใน Godot · ⬜ ยังไม่แก้

---

## สรุป

| ระดับ | ✅ แก้แล้ว | 🔧 รอทำใน Godot | ⬜ ยังไม่แก้ | รวม |
|---|---|---|---|---|
| 🔴 Critical | 10 | 0 | 2 | 12 |
| 🟡 High | 9 | 0 | 2 | 11 |
| 🟢 Low | 4 | 0 | 4 | 8 |
| **รวม** | **23** | **0** | **8** | **31** |

---

## 🆕 ตรวจเพิ่ม 22 ก.ย. 2569 — หลัง refactor `QuestStep` (commit `a48aa67`)

ทีมทำ QuestStep resource ตามข้อเสนอ 4.1 แล้ว 👍 แต่ระหว่างทาง refactor ยังค้างอยู่ 4 จุดที่ทำให้เกมเดินไม่ได้ — **ทั้ง 4 จุดแก้แล้วใน commit `7c291e5` (23 ก.ย. 2569)** ดูรายละเอียดที่แก้จริงในแต่ละข้อด้านล่าง

### BUG-28 ✅ `load()` ไม่ได้ `.instantiate()` — มินิเกมเปิดไม่ขึ้น

`Scripts/EventManager/event_manager.gd::_process_data()` ตอนนี้:

```gdscript
QuestStep.Action.MINIGAME, QuestStep.Action.SCENE_CHANGE:
    var scene = load(data.scene_path) as PackedScene
    get_tree().root.add_child(scene.instantiate())
    Global.in_minigame = true
```

### BUG-29 ✅ ส่ง `QuestStep` เข้าไปในช่องที่รับ `String`

`update_event()` และ `jump_event()` ทั้งคู่ส่ง `quest_step.quest_text_th` เข้า `questboard.update_task()` แล้ว แทนที่จะส่ง `QuestStep` ทั้งตัว

### BUG-30 ✅ `main.tres` เหลือ QuestStep เดียวและว่างเปล่า

`Resources/main.tres` มี 5 `QuestStep` ครบแล้ว: คุยกับยาย (DIALOG) → เข้าห้อง (DIALOG) → หายางลบ (MINIGAME, find-item) → ขัดแรม (TUTORIAL) → SCENE_CHANGE ปิดท้าย แต่ละอันมี `action`/`dialog_file`/`scene_path`/`quest_text_th` ครบ ยังฝังรวมในไฟล์เดียว (ไม่ได้แยกเป็น `Resources/MainQuest/*.tres` ตามที่เสนอไว้ — ไม่ใช่บั๊ก แค่ diff จะอ่านยากขึ้นถ้าแก้บ่อย)

### BUG-31 ✅ `minigame_end()` และ `_on_dialog_finish()` เป็น `pass`

แก้ด้วยสถาปัตยกรรมใหม่ทั้งชุด แทนการเช็กเลข task หรือ flag `updateEvent` เดี่ยว ๆ:

- `QuestStep` มี `isDone` + `set_done()`/`reset()` เอง แทนที่จะพึ่ง index
- `QuestStep.EmitType` (`TRIGGER` / `DIALOG_END` / `MINIGAME_END` / `TUTORIAL_END`) บอกว่า step นี้ต้องรอ action ของตัวเองจบก่อนถึงจะ trigger step ถัดไปได้ (กันปัญหาเดิมที่ quest วิ่งไปข้างหน้าตั้งแต่ action เพิ่งเริ่ม ไม่ใช่ตอนจบจริง)
- `EventManager` ต่อสัญญาณ `on_dialog_end` / `on_minigame_end` / `on_tutorial_finish` เข้ากับ `data.set_done` แบบ `CONNECT_ONE_SHOT` ใน `_process_data()`
- `_on_dialog_finish()` / `minigame_end()` / `_on_tutorial_end()` เช็ก `data.isDone` ก่อนเรียก `update_event()` แล้วค่อย `_process_data()` ต่อให้ step ใหม่ถ้า `emitType` ของมันไม่ใช่ `TRIGGER`

### ✅ ที่แก้ไปแล้วในรอบนี้ (จากฝั่งทีม)

| บั๊ก | สถานะใหม่ |
|---|---|
| BUG-19 `.scn` binary | ✅ มี `Scene/MiniGame/part_ram.tscn` แล้ว และ `Constant.MINIGAME1_SCENE` ชี้ถูก (ตรวจซ้ำ 23 ก.ย. — ยืนยันแล้ว ปิดสถานะเป็น ✅ เต็มตัว) |
| BUG-20 `minigame_end` อิงเลข task | ✅ เปลี่ยนเป็น data-driven เต็มรูปแบบแล้ว (ดู BUG-31) — ไม่มี hardcode เลข task เหลืออยู่ |
| BUG-26 `Event` ไม่มี `reset()` | ✅ เพิ่ม `Event.reset()` (รีเซ็ต `currentTask`/`isDone`/`isDone` ของทุก task) แล้วเรียกจาก `EventManager._ready()` ทุกครั้งที่โปรเซสเริ่มใหม่ |
| ข้อเสนอ 4.1 QuestStep resource | ✅ ทำแล้ว |

### ⬜ ที่ยังค้างเหมือนเดิม

BUG-14 (`simple_npc.gd` signature ผิด) · BUG-15 (ไม่มี Player / MainGame.tscn ไม่ถูกโหลด) · BUG-16 · BUG-17 · BUG-21 ถึง BUG-23 · BUG-25

### 🔎 พบระหว่างตรวจซ้ำ 23 ก.ย. 2569 — ยังไม่ฟันธงว่าเป็นบั๊ก

ใน `Resources/main.tres` task ลำดับที่ 3 (หายางลบ, `Action.MINIGAME`) ตั้ง `emitType = 1` (`DIALOG_END`) แทนที่จะเป็น `MINIGAME_END` — ไล่ flow ดูแล้วไม่กระทบพฤติกรรมจริงตอนนี้ เพราะตัวที่คุม auto-chain คือ `emitType` ของ step *ใหม่* หลัง `update_event()` ไม่ใช่ของ step เดิม แต่ดู semantically ผิดที่ (น่าจะพิมพ์/ตั้งค่าไว้ผิดตอนสร้าง resource) — ฝากทีมที่ดูแล `main.tres` ช่วยยืนยันว่าตั้งใจหรือไม่ ยังไม่ตั้งเป็น BUG-XX จนกว่าจะยืนยัน

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

### BUG-09 ✅ ไฟล์ `.import` ไม่ตรงกับชื่อรูป 39 คู่

| | |
|---|---|
| ที่ | `Assets/MiniGame/Part*/` |
| สาเหตุ | ตอน rename `Tier* → Part*` รูปเปลี่ยนชื่อแต่ `.import` ยังเป็นชื่อเก่า |
| ผล (ก่อนแก้) | ตอนนั้นยังหา texture เจอเพราะ cache ใน `.godot/` แต่พอ clone ใหม่หรือลบ cache uid ตายทั้งชุด |
| ตรวจซ้ำ 23 ก.ย. 2569 | เช็กทั้ง 69 ไฟล์ `.import` ใต้ `Assets/MiniGame/Part*/` แล้ว — ทุกไฟล์มี `source_file` ตรงกับชื่อรูปที่อยู่จริง ไม่มีไฟล์กำพร้าเหลือ ปิดเป็น ✅ |

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

### BUG-19 ✅ `Scene/MiniGame/Minigame1.scn` เป็นไฟล์ binary

diff/merge ไม่ได้ review ไม่ได้ → Save As เป็น `Scene/MiniGame/part_ram.tscn` แล้วแก้ `Constant.MINIGAME1_SCENE`
ตรวจซ้ำ 23 ก.ย. 2569: `Scripts/constant.gd:17` ชี้ `res://Scene/MiniGame/part_ram.tscn` แล้ว และไฟล์นั้นมีอยู่จริง ปิดเป็น ✅
*(หมายเหตุ: ไฟล์ binary เก่า `Scene/MiniGame/Minigame1.scn` ยังค้างอยู่ในดิสก์แบบไม่มีใครอ้างถึง — ไม่ใช่บั๊ก แค่ dead file รอลบตอนล้าง asset)*

### BUG-16 ⬜ tutorial กับมินิเกมขึ้นพร้อมกัน — คลิกทะลุ

| | |
|---|---|
| ไฟล์ | `Scripts/EventManager/event_manager.gd::_on_tutorial_end()` (บรรทัด 123–140) + `Scripts/MiniGame/minigame1.gd::_input()` (บรรทัด 41–50) |
| สาเหตุ (ตรวจซ้ำ 23 ก.ย. 2569 — จุดโค้ดเปลี่ยนหลัง refactor `trigger_step()` ไม่มี "case 3" แล้ว แต่บั๊กยังจริงอยู่) | `_on_tutorial_end()` เรียก `_process_data()` → `get_tree().root.add_child(minigame)` แบบ synchronous ในสัญญาณเดียวกับที่ tutorial จบ · `minigame1.gd::_input()` ยังไม่เช็ก `Global.isDialogShown()`/`isInMinigame()` และไม่เคยเรียก `set_input_as_handled()` เลย → คลิกที่ตั้งใจกดบน UI ชั้นบนทะลุไปโดนมินิเกมข้างล่างได้ |
| แก้ | รอ `EventManager.on_tutorial_finish` ให้ processing เสร็จเป็นเฟรมถัดไปก่อนค่อย `add_child(minigame)` · หรือใน `minigame1.gd::_input()` เช็ก `if Global.isDialogShown(): return` + `get_viewport().set_input_as_handled()` |

### BUG-17 ⬜ มินิเกมถูก `add_child` ที่ `get_tree().root`

ไม่ได้อยู่ใต้ฉากปัจจุบัน → ไม่บล็อกอินพุตของฉากข้างล่าง (กดปุ่มในห้องทะลุผ่านมินิเกมได้) และไม่ถูกลบตอนเปลี่ยนฉาก
**แก้:** ใส่ `Control` เต็มจอที่ `mouse_filter = STOP` เป็นฉากหลังของมินิเกม หรือ add เข้า `get_tree().current_scene` แทน root

### BUG-18 ✅ `parse_text()` พังถ้าบรรทัดบทไม่มี `,`

| | |
|---|---|
| ไฟล์ | `Scripts/DialogSystem/dialog_scene.gd::parse_text()` |
| สาเหตุ | `body = text.split(",")` แล้วใช้ `body[1]` ทันที — บรรทัดที่ไม่มี `,` จะ index out of range |
| แก้ | เพิ่ม guard ก่อนอ่าน `body[1]`: `if body.size() < 2: push_error("บรรทัดบทผิดรูปแบบ: %s" % text); return null` — บรรทัดผิดรูปแบบตอนนี้แค่ log error แล้วข้าม ไม่ทำเกม crash แล้ว |

### BUG-26 ✅ `Event` เก็บ state ไว้ใน Resource ที่แชร์กัน

| | |
|---|---|
| ไฟล์ | `Scripts/Resources/event.gd` |
| สาเหตุ | `currentTask` / `isDone` เป็นตัวแปรใน Resource `main.tres` ซึ่ง Godot cache ไว้ตัวเดียวทั้งเกม (ปัญหาชนิดเดียวกับ BUG-06) |
| ผล (ก่อนแก้) | เริ่มเกมใหม่ / `change_scene` แล้วความคืบหน้า quest ไม่รีเซ็ต จนกว่าจะปิดโปรแกรม |
| แก้ (commit `7c291e5`) | เพิ่ม `Event.reset()` (รีเซ็ต `currentTask`, `isDone`, และวนรีเซ็ต `isDone` ของทุก `QuestStep` ใน `_tasks`) แล้วเรียกจาก `EventManager._ready()` ทุกครั้งที่โปรเซสเริ่มใหม่ · `set_step()` (debug jump) ก็ปรับ `isDone` ของแต่ละ task ให้ตรงกับ index ที่กระโดดไปด้วย |
| ยังไม่ครอบคลุม | ยังไม่รองรับ Save/Load กลางเกม (reset เกิดที่ `_ready()` ของ autoload เท่านั้น ไม่ใช่ทุกครั้งที่ `change_scene`) — ยกไว้เป็นงานของระบบ Save/Load ในอนาคต |

---

## 🟢 Low

### BUG-12 ✅ ชื่อตัวละครสะกดผิดในไฟล์บท

`Assets/Dialog/MainQuest/GoToRoom.txt` บรรทัด 4 — `ชม,` → `ขม,` (ถ้าวันหลังส่ง `chars` เข้าไปจะ crash ที่ `_CharacterMap["ชม"]`)

### BUG-13 ✅ ข้อความ quest เป็นภาษาอังกฤษปนเกมภาษาไทย

`Resources/main.tres` — เปลี่ยนเป็นไทยทั้ง 4 ข้อแล้ว

### BUG-20 ✅ `minigame_end()` อิงเลข task แบบ hardcode

เดิม `event_manager.gd` เช็ก `if [2, 3].has(task)` — แทรก task ใหม่ตรงกลางเมื่อไรพังทันที
แก้ใน commit `7c291e5`: `minigame_end()` เช็ก `data.isDone && data.action == QuestStep.Action.MINIGAME || ...` (data-driven จาก task ปัจจุบันเอง ไม่ใช่เลข index ที่ hardcode) ก่อนเรียก `update_event()`

### BUG-21 ⬜ เดินทแยงมุมไม่ได้

`Scripts/player.gd::_physics_process()` ใช้ `if / elif` ไล่ทีละทิศ → กด W+D พร้อมกันจะได้แค่ขึ้น
**แก้:** ใช้ `Input.get_vector("left", "right", "up", "down")` แทนทั้งบล็อก

### BUG-22 ⬜ กด `E` ที่ไหนก็ toggle แผนที่ได้

`Scripts/Market/exit.gd::_input()` ดักคีย์ E แบบ global โดยไม่เช็กว่าผู้เล่นอยู่ในโซนหรือไม่ และไม่เช็ก `isDialogShown()` / `isInMinigame()`
**แก้:** ใช้ flag `playerEnter` แบบเดียวกับ `simple_npc.gd` + guard สถานะ

### BUG-23 ⬜ `Global.on_start` เขียนอย่างเดียว ไม่มีใครอ่าน

`global.gd` + `start_scene.gd` — dead field ลบทิ้งหรือเอาไปใช้จริง

### BUG-24 ✅ `class_name QuesetBoard` สะกดผิด

`Scripts/EventManager/quest_board.gd` → `class_name QuestBoard` แล้ว พร้อมแก้จุดที่อ้างใน `event_manager.gd::questboard` (`as QuesetBoard` → `as QuestBoard`)

### BUG-25 ⬜ ชื่อไฟล์สะกดผิดค้างจากของเดิม

`ramSligtDirty.png` · `GradmaHighlight.png` · `Prolouge.txt` — แก้ตอนล้าง asset ชุดเก่า

---

## ประวัติเอกสาร

| วันที่ | การเปลี่ยนแปลง |
|---|---|
| 23 ก.ย. 2569 (ตรวจซ้ำ 2) | ปิด BUG-18 (`parse_text()` guard `body.size() < 2` ก่อน `push_error`+`return null`) และ BUG-24 (`QuesetBoard` → `QuestBoard` ทั้ง `quest_board.gd` และ `event_manager.gd`) จาก working-tree changes ที่ยังไม่ commit — ดู `git diff` ตอนตรวจ |
| 23 ก.ย. 2569 (ตรวจซ้ำ) | Audit เต็มไฟล์เทียบกับโค้ดจริงที่ HEAD `cd053b4` (ไม่มี commit โค้ดใหม่ตั้งแต่ `7c291e5`) — ปิด BUG-09 (`.import` ครบ 69 คู่ ไม่มีไฟล์กำพร้าแล้ว) และ BUG-19 (`Constant.MINIGAME1_SCENE` ชี้ `part_ram.tscn` แล้วจริง) เป็น ✅ ทั้งคู่ · อัปเดตเลขบรรทัด/จุดอ้างอิงโค้ดของ BUG-16 (ย้ายจาก `trigger_step()` case 3 ไปที่ `_on_tutorial_end()` + `minigame1.gd::_input()`) และ BUG-18 (เลขบรรทัดขยับ) ให้ตรงโค้ดปัจจุบัน · พบจุดน่าสงสัยใหม่ใน `main.tres` (emitType ของ task หายางลบ) แต่ยังไม่ฟันธงเป็นบั๊ก |
| 23 ก.ย. 2569 | commit `7c291e5` — ปิด BUG-28 ถึง BUG-31 (load/instantiate, QuestStep→String, main.tres 5 task, minigame_end/dialog_finish logic) ด้วยระบบ `isDone`/`EmitType` ต่อสัญญาณ `on_dialog_end`/`on_minigame_end`/`on_tutorial_finish` แบบ one-shot · ปิด BUG-20 (data-driven เต็มรูปแบบ) และ BUG-26 (`Event.reset()` + เรียกจาก `_ready()`) ไปด้วย |
| 22 ก.ย. 2569 | ตรวจเพิ่มหลัง refactor QuestStep — พบบั๊กใหม่ 4 ข้อ (BUG-28 ถึง BUG-31) ที่ทำให้เกมเดินไม่ได้ · ปิด BUG-19 และ BUG-20 |
| 21 ก.ย. 2569 | สร้างเอกสาร — รวมบั๊ก 27 รายการจากการไล่โค้ดทั้งโปรเจกต์ที่ commit `1c9040a` · แก้แล้ว 13 · รอทำใน Godot 2 · ยังไม่แก้ 12 |
