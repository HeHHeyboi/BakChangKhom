# AUDIO.md — เพลงและเสียงประกอบ (เดโม)

> [Claude 10 ต.ค. 2569] เพลง/เสียงชุดแรก สังเคราะห์ด้วยโค้ดทั้งหมด (ไม่ใช้ไฟล์หรือเพลงของคนอื่น) ใช้เป็นตัวชั่วคราวจนกว่าทีมจะมีเพลงจริง

## ไฟล์

| ไฟล์ | ใช้ตอน | ความยาว | ลักษณะ |
|---|---|---|---|
| `Assets/Audio/Music/bgm_menu.ogg` | เมนูหลัก · หลังจบเดโม | 48 วิ (วน) | "เย็นที่ทุ่งนา" ช้า 80 BPM · แคนยืนเสียง + พิณทำนอง + ฉิ่ง · A ไมเนอร์เพนทาโทนิก |
| `Assets/Audio/Music/bgm_village.ogg` | ในบ้าน · หน้าบ้าน · ร้าน | 36 วิ (วน) | "เช้าวันเปิดร้าน" สดใส 108 BPM · โปงลาง/ระนาด + พิณเบส + กลอง + เกราะไม้ + ฉิ่ง · C เพนทาโทนิก |
| `Assets/Audio/Music/bgm_work.ogg` | มินิเกม · ขมOS · โต๊ะหลังเครื่อง | 53 วิ (วน) | ชิล 72 BPM · ระนาดเบา ๆ + แพด · ไม่กวนสมาธิ |
| `Assets/Audio/Music/jingle_demo_end.ogg` | หน้าจบเดโม (ครั้งเดียว) | 7 วิ | พิณไล่ขึ้น + แคน + ฉิ่ง แล้วต่อด้วยเพลงเมนู |
| `Assets/Audio/Sfx/click.wav` | กดปุ่มทุกปุ่ม | สั้น | ไม้เคาะ |
| `Assets/Audio/Sfx/success.wav` · `fail.wav` | ส่งงานลูกค้า ผ่าน / ไม่ผ่าน | สั้น | โปงลางไล่ขึ้น / ลง |
| `Assets/Audio/Sfx/coin.wav` | เงินเข้า | สั้น | เหรียญ |
| `Assets/Audio/Sfx/boot.wav` | ขมOS บูต | 1 วิ | ปี๊บ POST + พัดลม |
| `Assets/Audio/Sfx/pop.wav` | (สำรอง) หน้าต่างเด้ง | สั้น | ป๊อบ |

สร้างใหม่/แก้ทำนอง: `python3 Assets/Audio/src/gen_audio.py Assets/Audio` (ต้องมี numpy + ffmpeg) — ทำนองอยู่ในตัวแปร `mel` ของแต่ละเพลง (เลขโน้ต MIDI, ความยาวเป็นเขบ็ต 1 ชั้น)

## ระบบ

- autoload **`Audio`** (`Scripts/Core/audio_manager.gd`) — เลือกเพลงเองทุกเฟรมจากสถานการณ์ แล้ว crossfade 1.2 วิ
  - เมนูหลักเปิดอยู่ → `menu` · อยู่ในมินิเกม (`Global.in_minigame`) → `work` · จบเดโมแล้ว → `demo_end` แล้ว `menu` · อื่น ๆ → `village`
  - `Audio.play_music(&"village")` เปลี่ยนเอง · `Audio.music_enabled = false` ปิดการเลือกอัตโนมัติ · `Audio.sfx(&"coin")` เล่นเสียง
- เสียงคลิก: ทุก `BaseButton` ที่เกิดในเกมต่อเสียงให้อัตโนมัติ (ไม่เอา: `button.set_meta("no_click", true)` ก่อน add_child)
- บัสเสียง `default_bus_layout.tres`: **Master** → **Music** · **SFX**
- หน้าตั้งค่ามีสไลเดอร์ เสียงรวม · เพลง · เสียงประกอบ (เซฟใน `user://settings.cfg`)

## เปลี่ยนเป็นเพลงจริง

วางไฟล์ `.ogg` ทับชื่อเดิม (หรือแก้ path ใน `MUSIC` / `SFX` ของ `audio_manager.gd`) · เพลงวนให้ติ๊ก Loop ในแท็บ Import (โค้ดตั้ง loop ให้อยู่แล้วสำหรับไฟล์ที่ไม่ใช่ jingle)
แนะนำ: OGG 44.1 kHz · ดังเฉลี่ยราว −20 dB · ตัดหัว-ท้ายให้วนพอดีห้องเพลง
