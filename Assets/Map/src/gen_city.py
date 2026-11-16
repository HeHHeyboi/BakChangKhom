"""ฉากเมือง (ชั่วคราวรอทีมวาด) — ถนนในเมืองตอนกลางวัน: ตึกออฟฟิศ (ซ้าย) · ร้านอะไหล่คอม (กลาง) · ร้านกาแฟ coworking (ขวา) · รถตู้กลับบ้าน
[Claude 16 พ.ย. 2569 · 0.9.5] วาดด้วย PIL สไตล์เดียวกับ gen_map.py (เส้นขอบน้ำตาลเข้ม · สีแบน)
ใช้:  python gen_city.py <โฟลเดอร์ Assets/Background>   → bg_city_day.jpg (1152x648) + Assets/Map/loc_city_day.jpg ไม่ทำ (การ์ดแผนที่ใช้ loc_city.jpg เดิม)
ตำแหน่งตึก (พิกัดจอ) ต้องตรงกับจุดกดใน Scene/Location/City.tscn: SPOTS
"""
import random, sys, os
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
S = 2
W, H = 1152, 648
OL = (58, 40, 28)
# จุดกด (x0, y0, x1, y1) จอ 1152x648 — ตรงกับ City.tscn
SPOTS = {"office": (40, 70, 380, 520), "parts": (430, 230, 740, 520), "cafe": (790, 250, 1120, 520), "van": (470, 545, 690, 640)}


def R(d, box, fill, w=3, r=0):
    x0, y0, x1, y1 = [v * S for v in box]
    if r:
        d.rounded_rectangle([x0, y0, x1, y1], r * S, fill=fill, outline=OL, width=w * S)
    else:
        d.rectangle([x0, y0, x1, y1], fill=fill, outline=OL, width=w * S)


def city():
    rnd = random.Random(7)
    img = Image.new("RGB", (W * S, H * S))
    d = ImageDraw.Draw(img, "RGBA")
    # ฟ้า
    for y in range(H * S):
        t = y / (H * S * 0.6)
        c = tuple(int(a + (b - a) * min(t, 1)) for a, b in zip((120, 185, 240), (215, 236, 250)))
        d.line([(0, y), (W * S, y)], fill=c)
    for cx, cy, s in [(180, 70, 1.0), (620, 50, 1.3), (980, 90, 0.9)]:
        for dx, dy, r in [(-40, 6, 28), (-10, -8, 36), (25, 2, 30), (55, 10, 22)]:
            d.ellipse([(cx + dx * s - r * s) * S, (cy + dy * s - r * s) * S, (cx + dx * s + r * s) * S, (cy + dy * s + r * s) * S], fill=(255, 255, 255, 230))
    # ตึกไกล (เงาฟ้า)
    x = 0
    while x < W:
        w = rnd.randint(50, 110)
        h = rnd.randint(150, 330)
        d.rectangle([x * S, (430 - h) * S, (x + w) * S, 430 * S], fill=(150, 170, 200))
        for wy in range(430 - h + 14, 420, 22):
            for wx in range(x + 8, x + w - 8, 16):
                d.rectangle([wx * S, wy * S, (wx + 7) * S, (wy + 10) * S], fill=(185, 205, 228))
        x += w + rnd.randint(0, 14)
    # ทางเท้า + ถนน
    d.rectangle([0, 500 * S, W * S, 548 * S], fill=(200, 190, 175))
    for xx in range(0, W, 48):
        d.line([(xx * S, 500 * S), (xx * S, 548 * S)], fill=(170, 160, 145), width=2 * S)
    d.rectangle([0, 548 * S, W * S, H * S], fill=(92, 92, 100))
    for xx in range(20, W, 120):
        d.rectangle([xx * S, 596 * S, (xx + 60) * S, 602 * S], fill=(240, 230, 200))
    # ตึกออฟฟิศ (กระจกฟ้า)
    x0, y0, x1, y1 = SPOTS["office"]
    R(d, (x0 + 20, y0, x1 - 20, 505), (90, 140, 190))
    for wy in range(y0 + 18, 440, 34):
        for wx in range(x0 + 36, x1 - 40, 46):
            R(d, (wx, wy, wx + 34, wy + 24), (170, 215, 240), 2)
            d.line([((wx + 4) * S, (wy + 20) * S), ((wx + 14) * S, (wy + 4) * S)], fill=(230, 245, 255), width=2 * S)
    R(d, (x0 + 120, 440, x1 - 120, 505), (60, 80, 100), 3)  # ประตูกระจก
    d.line([((x0 + x1) // 2 * S, 440 * S), ((x0 + x1) // 2 * S, 505 * S)], fill=OL, width=3 * S)
    R(d, (x0 + 70, 405, x1 - 70, 432), (245, 245, 240), 3, 6)  # ป้ายตึก (ไม่มีชื่อแบรนด์)
    for i in range(5):
        d.rectangle([(x0 + 100 + i * 30) * S, 414 * S, (x0 + 120 + i * 30) * S, 423 * S], fill=(90, 140, 190))
    # ร้านอะไหล่คอม (ห้องแถว 2 ชั้น)
    x0, y0, x1, y1 = SPOTS["parts"]
    R(d, (x0, y0, x1, 505), (236, 222, 196))
    R(d, (x0 + 14, y0 + 14, x1 - 14, y0 + 70), (40, 90, 160), 3, 6)  # ป้ายร้าน
    for i, col in enumerate([(250, 200, 60), (230, 80, 70), (90, 200, 120), (250, 250, 250)]):
        d.rectangle([(x0 + 40 + i * 60) * S, (y0 + 30) * S, (x0 + 80 + i * 60) * S, (y0 + 54) * S], fill=col)
    # กันสาดลาย
    for i in range(10):
        col = (40, 90, 160) if i % 2 == 0 else (245, 245, 245)
        xa = x0 + i * (x1 - x0) / 10
        d.polygon([(xa * S, (y0 + 86) * S), ((xa + (x1 - x0) / 10) * S, (y0 + 86) * S), ((xa + (x1 - x0) / 10) * S, (y0 + 116) * S), (xa * S, (y0 + 116) * S)], fill=col, outline=OL)
    R(d, (x0 + 20, y0 + 128, x1 - 20, 505), (205, 225, 235), 3)  # หน้าร้านกระจก
    for k in range(3):  # ชั้นวางของ
        yy = y0 + 160 + k * 46
        d.line([((x0 + 30) * S, yy * S), ((x1 - 30) * S, yy * S)], fill=OL, width=3 * S)
        for j in range(7):
            col = rnd.choice([(60, 70, 80), (40, 120, 60), (180, 60, 50), (230, 230, 230), (40, 90, 160)])
            bx = x0 + 40 + j * 36
            d.rectangle([bx * S, (yy - 26) * S, (bx + 26) * S, (yy - 2) * S], fill=col, outline=OL, width=S)
    # ร้านกาแฟ
    x0, y0, x1, y1 = SPOTS["cafe"]
    R(d, (x0, y0, x1, 505), (250, 240, 225))
    R(d, (x0 + 40, y0 + 14, x1 - 40, y0 + 60), (60, 120, 90), 3, 20)
    d.ellipse([((x0 + x1) / 2 - 16) * S, (y0 + 20) * S, ((x0 + x1) / 2 + 16) * S, (y0 + 52) * S], fill=(250, 240, 225), outline=OL, width=2 * S)
    for i in range(8):
        col = (60, 120, 90) if i % 2 == 0 else (250, 240, 225)
        xa = x0 + i * (x1 - x0) / 8
        d.pieslice([xa * S, (y0 + 66) * S, (xa + (x1 - x0) / 8) * S, (y0 + 110) * S], 0, 180, fill=col, outline=OL)
        d.rectangle([xa * S, (y0 + 66) * S, (xa + (x1 - x0) / 8) * S, (y0 + 88) * S], fill=col)
    R(d, (x0 + 20, y0 + 110, x1 - 20, 470), (255, 225, 160), 3)  # หน้าต่างอุ่น ๆ
    for k in range(3):
        px = x0 + 50 + k * 95
        R(d, (px, 400, px + 60, 440), (80, 80, 90), 2, 3)  # โน้ตบุ๊ก
        R(d, (px + 6, 406, px + 54, 434), (140, 200, 230), 1)
        d.ellipse([(px + 18) * S, 350 * S, (px + 42) * S, 374 * S], fill=(120, 80, 60))
        d.rectangle([(px + 14) * S, 372 * S, (px + 46) * S, 400 * S], fill=(120, 80, 60))
    R(d, (x0 + 10, 470, x1 - 10, 505), (150, 110, 80), 3)
    for k in range(2):  # โต๊ะหน้าร้าน + ร่ม
        tx = x0 + 70 + k * 160
        d.polygon([((tx - 46) * S, 520 * S), ((tx + 46) * S, 520 * S), (tx * S, 482 * S)], fill=(230, 90, 70), outline=OL)
        d.line([(tx * S, 520 * S), (tx * S, 545 * S)], fill=OL, width=3 * S)
    # ต้นไม้ริมทาง
    for tx in [400, 760]:
        d.rectangle([(tx - 5) * S, 440 * S, (tx + 5) * S, 520 * S], fill=(110, 75, 45), outline=OL, width=S)
        d.ellipse([(tx - 34) * S, 380 * S, (tx + 34) * S, 450 * S], fill=(80, 160, 80), outline=OL, width=2 * S)
    # รถตู้กลับบ้าน
    x0, y0, x1, y1 = SPOTS["van"]
    R(d, (x0 + 10, y0 + 10, x1 - 10, y1 - 22), (245, 245, 245), 3, 16)
    for i in range(4):
        R(d, (x0 + 30 + i * 40, y0 + 20, x0 + 62 + i * 40, y0 + 44), (150, 200, 230), 2, 4)
    d.rectangle([(x0 + 10) * S, (y0 + 56) * S, (x1 - 10) * S, (y0 + 62) * S], fill=(60, 120, 90))
    for wx in [x0 + 50, x1 - 50]:
        d.ellipse([(wx - 18) * S, (y1 - 40) * S, (wx + 18) * S, (y1 - 4) * S], fill=(40, 40, 45), outline=OL, width=2 * S)
        d.ellipse([(wx - 7) * S, (y1 - 29) * S, (wx + 7) * S, (y1 - 15) * S], fill=(180, 180, 185))
    return img.resize((W, H), Image.LANCZOS)


if __name__ == "__main__":
    city().save(os.path.join(OUT, "bg_city_day.jpg"), quality=90)
    print("ok")
