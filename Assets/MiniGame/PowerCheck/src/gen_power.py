"""ภาพมินิเกม "ตรวจเครื่องเบื้องต้น" (คอมเก่าในห้องขม เปิดไม่ติด) — [Claude 10 ต.ค. 2569]
รัน:  python src/gen_power.py   (จากโฟลเดอร์ Assets/MiniGame/PowerCheck · ต้องมี Assets/Background/bg_khom_room.jpg)
ได้: power_bg.jpg · pc_back.png · fan.png · fan_grill.png · psu_sw_off/on.png · strip.png · strip_sw_off/on.png
     plug.png · pc_front.png · power_btn.png · power_btn_hover.png
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
S = 2
O = (58, 40, 28)
BEIGE = (226, 218, 196)
BEIGE_D = (196, 188, 164)
METAL = (150, 154, 160)
METAL_D = (110, 114, 120)


def canvas(w, h):
    im = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im, "RGBA")


def save(im, name, w, h):
    im.resize((w, h), Image.LANCZOS).save(os.path.join(HERE, name))


def R(d, x0, y0, x1, y1, fill, w=3, r=0, outline=O):
    box = [x0 * S, y0 * S, x1 * S, y1 * S]
    if r:
        d.rounded_rectangle(box, radius=r * S, fill=fill, outline=outline, width=w * S)
    else:
        d.rectangle(box, fill=fill, outline=outline, width=w * S)


def C(d, cx, cy, r, fill, w=3, outline=O):
    d.ellipse([(cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S], fill=fill, outline=outline, width=w * S)


def bg():
    im = Image.open(os.path.join(ROOT, "Assets/Background/bg_khom_room.jpg")).convert("RGB")
    im = im.crop((380, 250, 830, 503)).resize((1152, 648), Image.LANCZOS)
    im = im.filter(ImageFilter.GaussianBlur(7))
    im = ImageEnhance.Brightness(im).enhance(0.5)
    # พื้นไม้ใต้โต๊ะ
    d = ImageDraw.Draw(im, "RGBA")
    d.rectangle([0, 470, 1152, 648], fill=(70, 46, 28, 170))
    for y in range(490, 648, 38):
        d.line([(0, y), (1152, y)], fill=(40, 26, 16, 120), width=3)
    im.save(os.path.join(HERE, "power_bg.jpg"), quality=90)


def pc_back():
    """หลังเคส — [10 ต.ค.] PSU อยู่ล่าง (แบบเคสปัจจุบัน) · ฝาหลังด้านบน = IO เมนบอร์ด + ตะแกรงพัดลม · กลาง = ช่องการ์ดเสริม
    ตำแหน่งที่ฉากใช้ (Scene/MiniGame/PowerCheck/power_check.tscn → PcBack): พัดลม PSU ศูนย์ (100, 369) · ช่องไฟเข้า (186–246, 333–379)
    ช่องสวิตช์ (192–240, 384–436)"""
    W, H = 300, 460
    im, d = canvas(W, H)
    R(d, 4, 4, W - 4, H - 4, BEIGE, 4, 10)
    d.rectangle([(W - 22) * S, 8 * S, (W - 8) * S, (H - 8) * S], fill=(0, 0, 0, 30))
    # IO shield เมนบอร์ด (บนซ้าย)
    R(d, 30, 24, 130, 184, (172, 176, 182), 3, 2)
    for y, h, col in [(38, 18, (60, 100, 170)), (64, 18, (60, 100, 170)), (94, 26, (60, 60, 66)), (130, 14, (220, 120, 160)), (150, 14, (110, 190, 90))]:
        R(d, 50, y, 110, y + h, col, 2, 2)
    # ตะแกรงพัดลมระบายหลังเคส (บนขวา)
    for y in range(36, 176, 12):
        for x in range(160, 250, 14):
            C(d, x, y, 3, (90, 90, 90), 0, None)
    # ช่องการ์ดเสริม (กลาง)
    for i in range(5):
        y = 200 + i * 18
        R(d, 30, y, 240, y + 12, (170, 172, 178), 2, 2)
    # PSU (ล่าง)
    R(d, 22, 300, W - 22, 440, METAL, 3, 4)
    C(d, 100, 369, 54, (40, 42, 46), 3)
    R(d, 186, 333, 246, 379, (34, 34, 38), 3, 6)
    for x in (202, 216, 230):
        R(d, x - 3, 347, x + 3, 365, (150, 150, 150), 1)
    R(d, 192, 384, 240, 436, (60, 62, 66), 2, 4)
    for sx in (34, W - 34):
        C(d, sx, 312, 5, (120, 120, 120), 2)
        C(d, sx, 428, 5, (120, 120, 120), 2)
    # ฝุ่นบาง ๆ (คอมเก่า)
    import random
    rnd = random.Random(4)
    for _ in range(45):
        x, y = rnd.uniform(14, W - 24), rnd.uniform(14, H - 14)
        d.ellipse([x * S, y * S, (x + 1.5) * S, (y + 1.5) * S], fill=(120, 110, 90, 55))
    save(im, "pc_back.png", W, H)


def fan():
    W = 110
    im, d = canvas(W, W)
    c = W / 2
    C(d, c, c, 50, (52, 54, 58), 0, None)
    for k in range(7):
        a = k * 360 / 7
        pts = []
        for t in range(0, 11):
            ang = math.radians(a + t * 5)
            r = 12 + t * 3.6
            pts.append(((c + math.cos(ang) * r) * S, (c + math.sin(ang) * r) * S))
        for t in range(10, -1, -1):
            ang = math.radians(a + 26 + t * 3)
            r = 12 + t * 3.6
            pts.append(((c + math.cos(ang) * r) * S, (c + math.sin(ang) * r) * S))
        d.polygon(pts, fill=(96, 100, 108), outline=(30, 30, 34))
    C(d, c, c, 13, (70, 72, 78), 2, (30, 30, 34))
    save(im, "fan.png", W, W)


def fan_grill():
    W = 110
    im, d = canvas(W, W)
    c = W / 2
    for r in (50, 38, 26):
        d.ellipse([(c - r) * S, (c - r) * S, (c + r) * S, (c + r) * S], outline=(180, 182, 188), width=3 * S)
    d.line([(c - 50) * S, c * S, (c + 50) * S, c * S], fill=(180, 182, 188), width=3 * S)
    d.line([c * S, (c - 50) * S, c * S, (c + 50) * S], fill=(180, 182, 188), width=3 * S)
    C(d, c, c, 8, (180, 182, 188), 0, None)
    save(im, "fan_grill.png", W, W)


def rocker(name, on, red=False):
    W, H = 44, 56
    im, d = canvas(W, H)
    R(d, 3, 3, W - 3, H - 3, (30, 30, 34), 3, 6)
    if red:
        col = (240, 70, 50) if on else (150, 40, 34)
        R(d, 8, 8, W - 8, H - 8, col, 2, 4)
        if on:
            d.rounded_rectangle([10 * S, 10 * S, (W - 10) * S, 22 * S], radius=3 * S, fill=(255, 190, 170, 200))
        y = 14 if on else 34
        R(d, 10, y, W - 10, y + 8, tuple(min(255, c + 40) for c in col), 0, 2, None)
    else:
        # PSU: ฝั่งที่กดลงจะมืด · I (บน) / O (ล่าง)
        top = (40, 40, 44) if on else (80, 82, 88)
        bot = (80, 82, 88) if on else (40, 40, 44)
        R(d, 8, 8, W - 8, H / 2, top, 2, 3)
        R(d, 8, H / 2, W - 8, H - 8, bot, 2, 3)
        d.line([(W / 2) * S, 13 * S, (W / 2) * S, 23 * S], fill=(230, 230, 230), width=3 * S)
        d.ellipse([(W / 2 - 5) * S, 33 * S, (W / 2 + 5) * S, 43 * S], outline=(230, 230, 230), width=2 * S)
    save(im, name, W, H)


def strip():
    W, H = 440, 100
    im, d = canvas(W, H)
    d.ellipse([10 * S, (H - 20) * S, (W - 10) * S, (H - 2) * S], fill=(0, 0, 0, 70))
    R(d, 6, 10, W - 6, H - 14, (238, 236, 230), 4, 18)
    R(d, 14, 18, W - 14, H - 24, (226, 224, 216), 0, 14, None)
    # 4 ช่อง (ศูนย์กลาง x = 130, 210, 290, 370 · y = 46)
    for x in (130, 210, 290, 370):
        R(d, x - 30, 24, x + 30, 68, (250, 250, 246), 3, 10)
        for px in (x - 10, x + 10):
            R(d, px - 3, 36, px + 3, 52, (40, 40, 40), 1, 1)
        C(d, x, 60, 3, (40, 40, 40), 1)
    # ช่องสวิตช์ (โหนดแยก) x 34–78
    R(d, 30, 22, 82, 72, (200, 198, 190), 2, 6)
    save(im, "strip.png", W, H)


def plug():
    W, H = 90, 60
    im, d = canvas(W, H)
    # ขาเสียบชี้ขึ้น · ตัวปลั๊กดำ
    for x in (35, 55):
        R(d, x - 3, 4, x + 3, 22, (210, 190, 110), 2, 1)
    R(d, 18, 18, 72, 50, (40, 40, 44), 3, 10)
    R(d, 38, 46, 52, 58, (40, 40, 44), 2, 3)
    d.line([24 * S, 26 * S, 66 * S, 26 * S], fill=(80, 80, 86), width=2 * S)
    save(im, "plug.png", W, H)


def pc_front():
    W, H = 200, 300
    im, d = canvas(W, H)
    R(d, 4, 4, W - 4, H - 4, BEIGE, 4, 10)
    R(d, 20, 24, W - 20, 60, BEIGE_D, 2, 3)   # ซีดีรอม
    R(d, 60, 38, W - 60, 44, (120, 116, 100), 1, 1)
    R(d, 20, 72, W - 20, 96, BEIGE_D, 2, 3)   # ฟลอปปี้
    R(d, 70, 82, W - 70, 86, (60, 60, 60), 1, 1)
    # ช่องปุ่มเปิด (ปุ่มเป็นโหนด) ศูนย์ (100, 190)
    C(d, 100, 190, 36, BEIGE_D, 3)
    # ช่องไฟ LED ศูนย์ (100, 244)
    C(d, 100, 244, 8, (60, 60, 60), 2)
    for y in range(266, 290, 8):
        d.line([40 * S, y * S, (W - 40) * S, y * S], fill=(180, 172, 150), width=2 * S)
    save(im, "pc_front.png", W, H)


def power_btn(name, hover):
    W = 64
    im, d = canvas(W, W)
    C(d, 32, 32, 28, (236, 230, 212) if not hover else (250, 240, 200), 3)
    C(d, 32, 32, 22, (220, 212, 190) if not hover else (255, 236, 170), 0, None)
    d.arc([20 * S, 20 * S, 44 * S, 44 * S], -60, 240, fill=(90, 80, 60), width=3 * S)
    d.line([32 * S, 16 * S, 32 * S, 32 * S], fill=(90, 80, 60), width=3 * S)
    save(im, name, W, W)


if __name__ == "__main__":
    bg()
    pc_back()
    fan()
    fan_grill()
    rocker("psu_sw_off.png", False)
    rocker("psu_sw_on.png", True)
    rocker("strip_sw_off.png", False, True)
    rocker("strip_sw_on.png", True, True)
    strip()
    plug()
    pc_front()
    power_btn("power_btn.png", False)
    power_btn("power_btn_hover.png", True)
    print("ok")
