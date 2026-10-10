# สไลด์สอนเล่นตอนเริ่มเกม (BASIC_START) ชุดใหม่ — ใช้ภาพฉากจริงในเกม (บ้าน · หน้าบ้าน · ร้าน) · [Claude 10 ต.ค. 2569]
# ผลลัพธ์: tut_new_01…04.png (ไฟล์ใหม่ ไม่ทับ tut_start_0x เดิม)
# ใช้: python3 gen_start_slides.py <โฟลเดอร์ภาพแคป cap_home/cap_village/cap_shop.png> <โฟลเดอร์ Assets/Tutorial/BasicStart>
# กรอบ (กระดาษ + แถบหัว) ยกมาจากสไลด์เดิม · ข้อความอยู่ใน Captions ของ Resources/tutorial1.tres (ไม่ฝังในรูป)
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../MiniGame/TutorialAssembly/src"))
from mouse_art import make_mouse  # noqa: E402

CAP, OUT = sys.argv[1], sys.argv[2]
INK = (44, 24, 16, 255)
CREAM = (245, 230, 200, 255)
ORANGE = (240, 150, 60, 255)
YELLOW = (255, 214, 80, 255)
W, H = 1152, 648


def frame():
    base = Image.open(os.path.join(OUT, "tut_start_01.png")).convert("RGBA")  # ใช้กรอบจากสไลด์เดิม (ไม่เขียนทับไฟล์เดิม · เป็น LFS)
    d = ImageDraw.Draw(base)
    d.rectangle([40, 128, 1112, 608], fill=CREAM)
    return base


def shot(name, box, crop=None):
    im = Image.open(os.path.join(CAP, name)).convert("RGBA")
    if crop:
        im = im.crop(crop)
    im = im.resize((box[2] - box[0], box[3] - box[1]), Image.LANCZOS)
    return im


def paste_shot(base, im, at):
    x, y = at
    sh = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([x + 6, y + 8, x + im.width + 6, y + im.height + 8], 14, fill=(0, 0, 0, 90))
    base.alpha_composite(sh.filter(ImageFilter.GaussianBlur(6)))
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.width - 1, im.height - 1], 12, fill=255)
    base.paste(im, (x, y), mask)
    ImageDraw.Draw(base).rounded_rectangle([x, y, x + im.width, y + im.height], 12, outline=INK, width=5)


def ring(d, c, r, col=YELLOW, w=6):
    for k, a in [(0, 255), (14, 150), (28, 70)]:
        d.ellipse([c[0] - r - k, c[1] - r - k, c[0] + r + k, c[1] + r + k], outline=col[:3] + (a,), width=w)


def cursor(base, tip, scale=1.6):
    pts = [(0, 0), (0, 34), (9, 26), (15, 40), (21, 37), (15, 24), (27, 24)]
    pts = [(tip[0] + x * scale, tip[1] + y * scale) for x, y in pts]
    d = ImageDraw.Draw(base)
    d.polygon([(x + 3, y + 4) for x, y in pts], fill=(0, 0, 0, 80))
    d.polygon(pts, fill=(255, 255, 255, 255), outline=INK)
    d.line(pts + [pts[0]], fill=INK, width=4, joint="curve")


def arrow(d, a, b, col=ORANGE):
    d.line([a, b], fill=INK, width=18)
    d.line([a, b], fill=col, width=10)
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    p = [b, (b[0] - 34 * math.cos(ang - 0.5), b[1] - 34 * math.sin(ang - 0.5)), (b[0] - 34 * math.cos(ang + 0.5), b[1] - 34 * math.sin(ang + 0.5))]
    d.polygon(p, fill=col, outline=INK)
    d.line(p + [p[0]], fill=INK, width=4)


def dashed_box(d, box, col=ORANGE, w=6, dash=16):
    x0, y0, x1, y1 = box
    for (ax, ay, bx, by) in [(x0, y0, x1, y0), (x1, y0, x1, y1), (x1, y1, x0, y1), (x0, y1, x0, y0)]:
        n = int(max(abs(bx - ax), abs(by - ay)) // dash)
        for i in range(0, n, 2):
            t0, t1 = i / n, min((i + 1) / n, 1)
            d.line([(ax + (bx - ax) * t0, ay + (by - ay) * t0), (ax + (bx - ax) * t1, ay + (by - ay) * t1)], fill=col, width=w)


def badge(d, c, n):
    d.ellipse([c[0] - 24, c[1] - 24, c[0] + 24, c[1] + 24], fill=ORANGE, outline=INK, width=4)
    from PIL import ImageFont
    f = ImageFont.truetype(FONT, 30)
    tw = d.textlength(str(n), font=f)
    d.text((c[0] - tw / 2, c[1] - 20), str(n), font=f, fill=(255, 255, 255, 255))


FONT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../Fonts/Sarabun-Regular.ttf")

# ---- 1 คลิกโต้ตอบ (ในบ้าน · ยาย)
b = frame()
m, _ = make_mouse(150, -20.0, 5)
b.alpha_composite(m, (70, 270))
d = ImageDraw.Draw(b)
for ang in (-60, -20, 20):
    a = math.radians(ang)
    d.line([(150 + 70 * math.cos(a) - 30, 260 + 70 * math.sin(a)), (150 + 100 * math.cos(a) - 30, 260 + 100 * math.sin(a))], fill=ORANGE, width=8)
s = shot("cap_home.png", (0, 0, 780, 439))
paste_shot(b, s, (300, 150))
d = ImageDraw.Draw(b)
gx, gy = 300 + int(545 * 780 / 1152), 150 + int(450 * 439 / 648)
ring(d, (gx, gy), 70)
cursor(b, (gx + 10, gy + 10))
b.convert("RGB").save(os.path.join(OUT, "tut_new_01.png"))

# ---- 2 เครื่องหมาย !
b = frame()
d = ImageDraw.Draw(b)
d.ellipse([70, 270, 270, 470], fill=(150, 85, 30, 255), outline=INK, width=12)   # เครื่องหมาย ! แบบในเกม
d.ellipse([92, 292, 248, 448], outline=(110, 60, 20, 255), width=4)
d.rounded_rectangle([156, 305, 184, 405], 12, fill=(255, 240, 210, 255), outline=INK, width=3)
d.ellipse([154, 414, 186, 446], fill=(255, 240, 210, 255), outline=INK, width=3)
s = shot("cap_village.png", (0, 0, 760, 428))
paste_shot(b, s, (340, 160))
d = ImageDraw.Draw(b)
arrow(d, (282, 375), (380, 375))
ex, ey = 340 + int(884 * 760 / 1152), 160 + int(360 * 428 / 648)
ring(d, (ex, ey), 34)
cursor(b, (ex + 8, ey + 14))
b.convert("RGB").save(os.path.join(OUT, "tut_new_02.png"))

# ---- 3 แถบบน: วัน/เวลา/เงิน (ซ้าย) · เควสต์ (ขวา)
b = frame()
s = shot("cap_home.png", (0, 0, 800, 450))
paste_shot(b, s, (176, 145))
d = ImageDraw.Draw(b)
k = 800 / 1152
X0, Y0 = 176, 145
dashed_box(d, [X0, Y0, X0 + 250 * k, Y0 + 52 * k])
dashed_box(d, [X0 + 828 * k, Y0, X0 + 1152 * k - 4, Y0 + 40 * k])
badge(d, (X0 + 125 * k, Y0 + 52 * k + 36), 1)
badge(d, (X0 + 990 * k, Y0 + 40 * k + 36), 2)
# ไอคอนช่วงเวลา (ซ้าย) · ปุ่มซ่อน (ขวา)
for i, col in enumerate([(255, 210, 80, 255), (240, 150, 60, 255), (120, 100, 200, 255)]):
    c = (100, 260 + i * 90)
    d.ellipse([c[0] - 24, c[1] - 24, c[0] + 24, c[1] + 24], fill=col, outline=INK, width=3)
b.convert("RGB").save(os.path.join(OUT, "tut_new_03.png"))

# ---- 4 กระดานงานในร้าน + ปุ่มย่อ
b = frame()
s = shot("cap_shop.png", (0, 0, 800, 450))
paste_shot(b, s, (176, 145))
d = ImageDraw.Draw(b)
X0, Y0 = 176, 145
dashed_box(d, [X0 + 590 * k, Y0 + 96 * k, X0 + 1140 * k, Y0 + 590 * k])
ring(d, (X0 + int(1104 * k), Y0 + int(128 * k)), 20, w=5)
badge(d, (X0 + 560 * k, Y0 + 300 * k), 1)
badge(d, (X0 + 1104 * k, Y0 + 128 * k - 50), 2)
b.convert("RGB").save(os.path.join(OUT, "tut_new_04.png"))
print("ok")
