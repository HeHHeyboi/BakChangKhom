# ไอคอนของในร้าน/คลัง 128×128 (แทนอีโมจิ) — วาดด้วย PIL 4× แล้วย่อ · ใช้: python3 gen_item_icons.py → ../Items/item_<id>.png
# [Claude 13 ต.ค. 2569] สไตล์เดียวกับ ui_icon_storage.png (เส้นขอบน้ำตาลเข้ม · สีอุ่น)
import os, math
from PIL import Image, ImageDraw

S = 512
INK = (59, 41, 28, 255)
W = 16
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Items")
os.makedirs(OUT, exist_ok=True)


def canvas():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def save(im, name):
    im.resize((128, 128), Image.LANCZOS).save(os.path.join(OUT, "item_%s.png" % name))


def poly(d, pts, fill, w=W):
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=INK, width=w, joint="curve")


def rrect(d, box, r, fill, w=W):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=INK, width=w)


def ram(name, pcb, notch_x):
    im, d = canvas()
    rrect(d, [40, 170, 472, 330], 14, pcb)
    for i in range(4):
        rrect(d, [80 + i * 92, 195, 150 + i * 92, 265], 6, (40, 40, 48, 255), 8)
    for k in range(16):
        x = 60 + k * 25
        if abs(x - notch_x) < 18:
            continue
        d.rectangle([x, 290, x + 14, 322], fill=(240, 196, 70, 255))
    d.rectangle([notch_x - 10, 300, notch_x + 10, 340], fill=(0, 0, 0, 0))
    d.line([(notch_x - 10, 330), (notch_x - 10, 300), (notch_x + 10, 300), (notch_x + 10, 330)], fill=INK, width=10)
    save(im, name)


def new_badge(d):
    d.ellipse([360, 40, 470, 150], fill=(90, 180, 90, 255), outline=INK, width=12)
    d.line([(388, 96), (410, 120), (446, 70)], fill=(255, 255, 255, 255), width=18)


# แรม DDR4 (เขียว) มือสอง/ใหม่ · DDR3 (น้ำเงิน · ร่องบากคนละที่)
ram("ram_ddr4_8gb_used", (70, 150, 80, 255), 230)
im = Image.open(os.path.join(OUT, "item_ram_ddr4_8gb_used.png"))
big, d = canvas()
ram("ram_ddr4_8gb_new", (70, 150, 80, 255), 230)
im = Image.open(os.path.join(OUT, "item_ram_ddr4_8gb_new.png")).resize((S, S))
d = ImageDraw.Draw(im)
new_badge(d)
save(im, "ram_ddr4_8gb_new")
ram("ram_ddr3_4gb_used", (60, 110, 190, 255), 300)

# สาย SATA (แดง แบน · หัวรูป L)
im, d = canvas()
d.line([(110, 380), (200, 260), (320, 250), (400, 140)], fill=INK, width=60, joint="curve")
d.line([(110, 380), (200, 260), (320, 250), (400, 140)], fill=(210, 60, 50, 255), width=36, joint="curve")
for (x, y) in [(70, 360), (360, 100)]:
    rrect(d, [x, y, x + 90, y + 70], 8, (30, 30, 34, 255))
    d.rectangle([x + 18, y + 22, x + 72, y + 34], fill=(240, 196, 70, 255))
save(im, "cable_sata")

# สาย HDMI (ดำ · หัวคางหมู)
im, d = canvas()
d.arc([90, 120, 420, 450], 200, 20, fill=INK, width=56)
d.arc([90, 120, 420, 450], 200, 20, fill=(60, 62, 70, 255), width=32)
for (cx, cy) in [(100, 300), (410, 270)]:
    poly(d, [(cx - 60, cy - 40), (cx + 60, cy - 40), (cx + 48, cy + 34), (cx - 48, cy + 34)], (170, 175, 185, 255))
    d.rectangle([cx - 36, cy - 20, cx + 36, cy - 4], fill=(40, 40, 46, 255))
save(im, "cable_hdmi")

# เมาส์
im, d = canvas()
d.line([(256, 110), (256, 60), (330, 40)], fill=INK, width=20)
rrect(d, [150, 100, 362, 440], 106, (225, 225, 232, 255))
d.line([(256, 100), (256, 230)], fill=INK, width=12)
d.line([(150, 230), (362, 230)], fill=INK, width=12)
rrect(d, [240, 140, 272, 200], 14, (90, 90, 100, 255), 8)
save(im, "mouse_basic")

# คีย์บอร์ด
im, d = canvas()
rrect(d, [30, 170, 482, 360], 20, (210, 210, 218, 255))
for r in range(3):
    for c in range(9):
        x = 58 + c * 46 + (r % 2) * 10
        rrect(d, [x, 194 + r * 44, x + 36, 226 + r * 44], 6, (250, 250, 252, 255), 6)
rrect(d, [140, 322, 372, 348], 8, (250, 250, 252, 255), 6)
save(im, "keyboard_basic")


def bottle(name, liquid, label, cap):
    im, d = canvas()
    rrect(d, [206, 50, 306, 120], 12, cap)
    poly(d, [(220, 120), (292, 120), (292, 160), (350, 210), (350, 460), (162, 460), (162, 210), (220, 160)], (235, 240, 245, 255))
    d.rectangle([174, 300, 338, 448], fill=liquid)
    rrect(d, [180, 240, 332, 330], 10, label, 10)
    d.line([(220, 120), (292, 120), (292, 160), (350, 210), (350, 460), (162, 460), (162, 210), (220, 160), (220, 120)], fill=INK, width=W, joint="curve")
    save(im, name)


bottle("ipa90", (140, 200, 240, 200), (80, 140, 220, 255), (40, 90, 170, 255))
bottle("alcohol70", (200, 230, 200, 200), (240, 240, 240, 255), (120, 170, 120, 255))

# ซิลิโคน (หลอดฉีดยา)
im, d = canvas()
poly(d, [(110, 380), (330, 160), (390, 220), (170, 440)], (200, 200, 208, 255))
poly(d, [(330, 160), (380, 110), (440, 170), (390, 220)], (230, 230, 236, 255))
d.line([(410, 140), (470, 80)], fill=INK, width=30)
poly(d, [(110, 380), (170, 440), (120, 470), (80, 430)], (150, 150, 160, 255))
d.line([(150, 345), (280, 215)], fill=(120, 120, 130, 255), width=40)
save(im, "paste_grey")

# ลมกระป๋อง (+ หลอดแดง)
im, d = canvas()
rrect(d, [170, 140, 342, 470], 30, (90, 160, 220, 255))
rrect(d, [210, 90, 302, 150], 12, (60, 60, 70, 255))
d.line([(302, 110), (450, 70)], fill=INK, width=26)
d.line([(302, 110), (450, 70)], fill=(220, 60, 50, 255), width=12)
rrect(d, [190, 250, 322, 360], 10, (240, 240, 245, 255), 10)
for k in range(3):
    d.arc([200 + k * 30, 270, 260 + k * 30, 340], 300, 60, fill=(90, 160, 220, 255), width=10)
save(im, "air_can")

# เคเบิลไท (ขดสีขาว + หัวล็อก)
im, d = canvas()
d.arc([100, 100, 412, 412], 0, 330, fill=INK, width=50)
d.arc([100, 100, 412, 412], 0, 330, fill=(245, 245, 240, 255), width=26)
rrect(d, [380, 190, 460, 270], 10, (245, 245, 240, 255))
d.line([(420, 270), (440, 420)], fill=INK, width=40)
d.line([(420, 270), (440, 420)], fill=(245, 245, 240, 255), width=18)
save(im, "cable_tie")

# ชั้นเหล็ก
im, d = canvas()
for x in (90, 410):
    d.line([(x, 60), (x, 470)], fill=INK, width=34)
    d.line([(x, 60), (x, 470)], fill=(150, 160, 170, 255), width=14)
for y in (140, 270, 400):
    rrect(d, [70, y, 442, y + 30], 6, (170, 180, 190, 255), 12)
rrect(d, [120, 80, 220, 140], 6, (201, 139, 78, 255), 10)
rrect(d, [250, 210, 380, 270], 6, (70, 150, 80, 255), 10)
rrect(d, [130, 330, 230, 400], 6, (201, 139, 78, 255), 10)
save(im, "storage_shelf")

# ตู้ลิ้นชัก
im, d = canvas()
rrect(d, [80, 70, 432, 470], 16, (190, 130, 70, 255))
for r in range(4):
    for c in range(2):
        x = 104 + c * 166
        y = 92 + r * 92
        rrect(d, [x, y, x + 142, y + 76], 8, (225, 170, 105, 255), 10)
        rrect(d, [x + 46, y + 32, x + 96, y + 46], 6, (90, 60, 30, 255), 6)
save(im, "storage_drawer")
print("ok", sorted(os.listdir(OUT)))
