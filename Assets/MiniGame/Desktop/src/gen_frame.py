# กรอบ "จอมอนิเตอร์บนโต๊ะ" มุมใกล้หน้าจอ สำหรับ ขมOS (framed) · 1152×648 วาดที่ 2× (2304×1296)
# จอ (พื้นที่ OS) = Rect2(86, 14, 979.2, 550.8) (สเกล 0.85) ต้องตรงกับ DesktopMinigame.FRAME_SCREEN
# ใช้: python3 gen_frame.py <bg_shop_open.jpg> <ฟอนต์> <out.png>   · [Claude 10 ต.ค. 2569]
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../TutorialAssembly/src"))
from mouse_art import bezier, make_mouse  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter, ImageFont

BG, FONT, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
S = 2
W, H = 1152 * S, 648 * S
INK = (32, 22, 16, 255)


def r(*v):
    return [int(x * S) for x in v]


img = Image.open(BG).convert("RGB").resize((W, H), Image.LANCZOS)
img = img.filter(ImageFilter.GaussianBlur(14 * S)).convert("RGBA")
img.alpha_composite(Image.new("RGBA", (W, H), (40, 26, 16, 110)))  # ผนังร้านเบลอ+มืดลง ให้จอเด่น

# ---- โต๊ะไม้ (ขอบหลังโต๊ะ y=520)
d = ImageDraw.Draw(img)
d.rectangle(r(0, 520, 1152, 648), fill=(148, 92, 52, 255))
for i, y in enumerate([548, 584, 626]):
    d.line(r(0, y, 1152, y + (2 if i % 2 else -2)), fill=(120, 72, 40, 255), width=2 * S)
for x0, y0, x1 in [(20, 536, 60), (1000, 600, 1140), (150, 612, 290)]:
    d.line(r(x0, y0, x1, y0 + 1), fill=(170, 112, 66, 255), width=S)
d.line(r(0, 520, 1152, 520), fill=(196, 140, 88, 255), width=3 * S)
d.line(r(0, 523, 1152, 523), fill=(92, 56, 30, 255), width=S)

# ---- เงาใต้ของบนโต๊ะ + เงาจอบนผนัง
sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(sh)
sd.rounded_rectangle(r(84, 10, 1094, 592), 18 * S, fill=(0, 0, 0, 120))
sd.ellipse(r(310, 650, 860, 680), fill=(0, 0, 0, 120))
sd.ellipse(r(900, 612, 1010, 652), fill=(0, 0, 0, 120))
sd.ellipse(r(440, 600, 720, 622), fill=(0, 0, 0, 110))
img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8 * S)))
d = ImageDraw.Draw(img)

# ---- สายเมาส์ → เคส (วาดก่อนเคส/ขาตั้ง/คีย์บอร์ด ให้มุดหลังของ)
m, tip = make_mouse(104 * S, -28.0, 3 * S)
mx, my = 952 * S - m.width // 2, 624 * S - m.height // 2
tx, ty = (mx + tip[0]) / S, (my + tip[1]) / S
cable = bezier((tx, ty), (tx - 24, ty - 2), (880, 606), (840, 606))
cable += [(130, 606)]
cable += bezier((130, 606), (90, 606), (70, 596), (56, 572))
d.line([(x * S, y * S) for x, y in cable], fill=(40, 40, 46, 255), width=3 * S, joint="curve")

# ---- เคสคอม (โผล่ซ้าย)
d.rounded_rectangle(r(-20, 214, 76, 580), 6 * S, fill=(38, 38, 44, 255), outline=INK, width=3 * S)
d.line(r(8, 250, 54, 250), fill=(70, 70, 78, 255), width=3 * S)
d.line(r(8, 268, 54, 268), fill=(70, 70, 78, 255), width=3 * S)
d.ellipse(r(24, 298, 34, 308), fill=(120, 230, 120, 255), outline=INK, width=S)

# ---- แก้วกาแฟ (โผล่ขวา)
d.arc(r(1116, 520, 1148, 556), 270, 90, fill=INK, width=5 * S)
d.rounded_rectangle(r(1090, 506, 1134, 572), 8 * S, fill=(214, 122, 72, 255), outline=INK, width=3 * S)
d.line(r(1098, 518, 1098, 562), fill=(236, 160, 110, 255), width=3 * S)
d.ellipse(r(1092, 504, 1132, 514), fill=(90, 52, 30, 255), outline=INK, width=2 * S)

# ---- ขาตั้งจอ
d.polygon(r(548, 580, 604, 580, 614, 604, 538, 604), fill=(50, 50, 56, 255), outline=INK)
d.rounded_rectangle(r(462, 598, 690, 616), 8 * S, fill=(58, 58, 64, 255), outline=INK, width=3 * S)

# ---- ตัวจอ (ขอบจอ) · จอ = 86,14 → 1065.2,564.8 (สเกล 0.85)
d.rounded_rectangle(r(72, 2, 1080, 586), 16 * S, fill=(30, 30, 35, 255), outline=INK, width=4 * S)
d.rounded_rectangle(r(77, 6, 1075, 581), 13 * S, outline=(66, 66, 74, 255), width=2 * S)
d.rectangle(r(84, 12, 1067, 567), fill=(12, 12, 14, 255), outline=(8, 8, 8, 255), width=2 * S)
d.rectangle(r(86, 14, 1065, 565), fill=(6, 6, 8, 255))
f = ImageFont.truetype(FONT, 13 * S, layout_engine=ImageFont.Layout.RAQM)
tw = d.textlength("ขม", font=f)
d.text((576 * S - tw / 2, 564 * S), "ขม", font=f, fill=(140, 140, 150, 255))
d.ellipse(r(1052, 572, 1060, 580), fill=(110, 220, 120, 255))

# ---- คีย์บอร์ด
d.rounded_rectangle(r(318, 616, 834, 690), 10 * S, fill=(168, 170, 176, 255), outline=INK, width=3 * S)
for row, y in enumerate([624, 640]):
    x = 332 + row * 8
    while x < 816:
        d.rounded_rectangle(r(x, y, x + 30, y + 12), 3 * S, fill=(246, 246, 248, 255), outline=(80, 80, 86, 255), width=S)
        x += 35

# ---- เมาส์มีสาย (TutorialAssembly/src/mouse_art.py) · สายวาดไว้ก่อนเคสแล้ว
img.alpha_composite(m, (mx, my))

img.save(OUT)
print("ok", img.size)
