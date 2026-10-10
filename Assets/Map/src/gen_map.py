"""แผนที่หมู่บ้าน + รูปการ์ดสถานที่ + ห้องเก็บของ (หายางลบ)
[Claude 10 ต.ค. 2569] วาดด้วย PIL · รูปการ์ดตัดจากฉากที่มีอยู่ (ตามที่มีอยู่)
ใช้:  python gen_map.py <โฟลเดอร์ Assets/Background> <โฟลเดอร์ผลลัพธ์ Assets/Map>
"""
import math, random, sys, os
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageChops

BG = sys.argv[1] if len(sys.argv) > 1 else "."
OUT = sys.argv[2] if len(sys.argv) > 2 else "out"
os.makedirs(OUT, exist_ok=True)
S = 2  # วาดใหญ่ 2 เท่าแล้วย่อ (เส้นเนียน)
W, H = 1152, 648
OUTLINE = (58, 40, 28)

# จุดกลางการ์ดบนแผนที่ (พิกัดจอ 1152x648) — ต้องตรงกับ Scene/map.tscn
SPOTS = {
    "home": (215, 355),
    "village": (435, 150),
    "shop": (545, 380),
    "market": (790, 140),
    "city": (880, 345),
}
FIELD_GRID = [(30, 440, 4, 2), (960, 190, 2, 2), (620, 470, 3, 1)]
FIELDS = [(x, y, c * 62, r * 46) for x, y, c, r in FIELD_GRID]
# แผงตลาด (x ซ้าย, y ฐาน, กว้าง) พิกัดจอ
MARKET_STALLS = [(70, 600, 250), (470, 430, 150), (800, 610, 260)]
ROADS = [("home", "village"), ("village", "shop"), ("village", "market"), ("shop", "city")]


def P(x, y):
    return (x * S, y * S)


def bez(p0, p1, p2, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    return pts


def road_pts(a, b, bend=40):
    (x0, y0), (x1, y1) = a, b
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    dx, dy = x1 - x0, y1 - y0
    ln = math.hypot(dx, dy) or 1
    c = (mx - dy / ln * bend, my + dx / ln * bend)
    return bez(a, c, b)


def thick_line(d, pts, w, col):
    pts2 = [P(*p) for p in pts]
    d.line(pts2, fill=col, width=int(w * S), joint="curve")
    r = w * S / 2
    for p in (pts2[0], pts2[-1]):
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col)


def tree(d, x, y, r, rnd):
    g = rnd.choice([(74, 140, 62), (86, 154, 70), (64, 126, 58)])
    dark = tuple(int(c * 0.7) for c in g)
    d.ellipse([P(x - r * 0.9, y + r * 0.55)[0], P(x, y + r * 0.55)[1], P(x + r * 0.9, y)[0], P(x, y + r * 0.95)[1]], fill=(60, 96, 50, 90))
    d.rectangle([P(x - r * 0.12, y)[0], P(x, y)[1], P(x + r * 0.12, y)[0], P(x, y + r * 0.7)[1]], fill=(110, 76, 48))
    d.ellipse([P(x - r, y - r)[0], P(x, y - r)[1], P(x + r, y)[0], P(x, y + r * 0.6)[1]], fill=dark, outline=OUTLINE, width=3)
    d.ellipse([P(x - r * 0.8, y - r * 0.95)[0], P(x, y - r * 0.95)[1], P(x + r * 0.6, y)[0], P(x, y + r * 0.25)[1]], fill=g)
    d.ellipse([P(x - r * 0.45, y - r * 0.8)[0], P(x, y - r * 0.8)[1], P(x - r * 0.05, y)[0], P(x, y - r * 0.4)[1]], fill=tuple(min(255, c + 30) for c in g))


def palm(d, x, y, s):
    d.line([P(x, y), P(x + 4, y - 26 * s)], fill=(120, 86, 52), width=int(5 * S * s))
    top = (x + 4, y - 26 * s)
    for a in range(0, 360, 60):
        ex = top[0] + math.cos(math.radians(a)) * 14 * s
        ey = top[1] + math.sin(math.radians(a)) * 7 * s + 3
        d.line([P(*top), P(ex, ey)], fill=(70, 140, 60), width=int(5 * S * s))


def hut(d, x, y, s, roof):
    w, h = 26 * s, 16 * s
    d.rectangle([P(x - w / 2, y - h)[0], P(x, y - h)[1], P(x + w / 2, y)[0], P(x, y)[1]], fill=(150, 104, 66), outline=OUTLINE, width=3)
    d.polygon([P(x - w / 2 - 5, y - h), P(x, y - h - 13 * s), P(x + w / 2 + 5, y - h)], fill=roof, outline=OUTLINE)
    d.rectangle([P(x - 3 * s, y - 9 * s)[0], P(x, y - 9 * s)[1], P(x + 3 * s, y)[0], P(x, y)[1]], fill=(90, 60, 40))


def map_bg():
    rnd = random.Random(7)
    im = Image.new("RGBA", (W * S, H * S), (150, 196, 110, 255))
    d = ImageDraw.Draw(im, "RGBA")
    # จุดสีหญ้า
    for _ in range(2600):
        x, y = rnd.uniform(0, W), rnd.uniform(96, H)
        r = rnd.uniform(4, 14)
        c = rnd.choice([(140, 188, 100, 45), (164, 206, 118, 45), (128, 176, 92, 40)])
        d.ellipse([P(x - r, y - r), P(x + r, y + r)], fill=c)
    # ท้องฟ้า + ภูเขาด้านบน
    for yy in range(0, 90):
        t = yy / 90
        d.line([P(0, yy), P(W, yy)], fill=(int(176 + 30 * t), int(214 + 10 * t), int(240 - 10 * t)), width=S + 1)
    for mx, mh, col in [(60, 70, (110, 152, 116)), (260, 55, (100, 144, 110)), (470, 40, (116, 158, 120)), (700, 62, (104, 148, 112)), (930, 75, (96, 140, 106)), (1130, 58, (110, 152, 116))]:
        d.polygon([P(mx - 170, 96), P(mx, 96 - mh), P(mx + 170, 96)], fill=col, outline=OUTLINE, width=3)
        d.polygon([P(mx - 16, 96 - mh + 12), P(mx, 96 - mh), P(mx + 18, 96 - mh + 14)], fill=(236, 240, 228))
    d.rectangle([P(0, 92), P(W, 100)], fill=(140, 188, 100))
    # ทุ่งนา (ล่างซ้าย / ขวาบน)
    for (x0, y0, cols, rows) in FIELD_GRID:
        for cx in range(cols):
            for cy in range(rows):
                px, py = x0 + cx * 62, y0 + cy * 46
                col = rnd.choice([(196, 214, 104), (176, 204, 96), (206, 220, 120)])
                d.rounded_rectangle([P(px, py), P(px + 56, py + 40)], radius=8, fill=col, outline=(120, 150, 70), width=4)
                for k in range(1, 5):
                    d.line([P(px + 6, py + k * 8), P(px + 50, py + k * 8)], fill=(150, 180, 80, 160), width=3)
    # แม่น้ำ
    river = bez((0, 210), (300, 300), (330, 520), 60) + bez((330, 520), (360, 600), (520, 660), 30)[1:]
    thick_line(d, river, 40, OUTLINE)
    thick_line(d, river, 34, (96, 170, 214))
    thick_line(d, river, 14, (150, 206, 236))
    # สะพาน (ถนนบ้าน→หน้าบ้าน ข้ามแม่น้ำ)
    # ถนน
    for a, b in ROADS:
        pts = road_pts(SPOTS[a], SPOTS[b], 30)
        thick_line(d, pts, 34, OUTLINE)
    for a, b in ROADS:
        pts = road_pts(SPOTS[a], SPOTS[b], 30)
        thick_line(d, pts, 28, (214, 172, 112))
        thick_line(d, pts, 10, (230, 196, 140))
    # ถนนออกเมือง (ทางไกลไปขวา) — เส้นประ
    far = bez(SPOTS["city"], (1020, 420), (1160, 400), 30)
    thick_line(d, far, 34, OUTLINE)
    thick_line(d, far, 28, (190, 186, 178))
    for i in range(0, len(far) - 1, 3):
        d.line([P(*far[i]), P(*far[i + 1])], fill=(250, 240, 200), width=4 * S)
    # สะพานไม้ตรงที่ถนนตัดแม่น้ำ
    bx, by = 300, 285
    d.rounded_rectangle([P(bx - 26, by - 16), P(bx + 26, by + 16)], radius=6, fill=(156, 106, 64), outline=OUTLINE, width=4)
    for k in range(-20, 24, 8):
        d.line([P(bx + k, by - 14), P(bx + k, by + 14)], fill=(120, 80, 48), width=3)
    # ต้นไม้ / บ้านเล็ก ๆ ตกแต่ง (เลี่ยงตำแหน่งการ์ด)
    def free(x, y, pad=125):
        for sx, sy in SPOTS.values():
            if abs(x - sx) < pad + 10 and abs(y - sy) < pad * 0.75:
                return False
        if x > 680 and y > 400:  # มุมคำพูด/ปิ๊บ
            return False
        for fx, fy, fw, fh in FIELDS:
            if fx - 20 < x < fx + fw + 20 and fy - 10 < y < fy + fh + 30:
                return False
        return True
    pts = []
    for _ in range(400):
        x, y = rnd.uniform(20, W - 20), rnd.uniform(95, 520)
        if free(x, y) and all(math.hypot(x - a, y - b) > 34 for a, b in pts):
            pts.append((x, y))
        if len(pts) > 42:
            break
    for x, y in sorted(pts, key=lambda p: p[1]):
        r = rnd.random()
        if r < 0.6:
            tree(d, x, y, rnd.uniform(14, 22), rnd)
        elif r < 0.85:
            palm(d, x, y, rnd.uniform(0.9, 1.2))
        else:
            hut(d, x, y, rnd.uniform(0.9, 1.1), rnd.choice([(180, 80, 60), (150, 90, 70), (120, 110, 100)]))
    # เข็มทิศ (มุมซ้ายบน)
    cx, cy = 60, 130
    d.ellipse([P(cx - 30, cy - 30), P(cx + 30, cy + 30)], fill=(246, 232, 200), outline=OUTLINE, width=4)
    d.polygon([P(cx, cy - 26), P(cx + 7, cy), P(cx - 7, cy)], fill=(200, 70, 60), outline=OUTLINE)
    d.polygon([P(cx, cy + 26), P(cx + 7, cy), P(cx - 7, cy)], fill=(240, 240, 240), outline=OUTLINE)
    im = im.resize((W, H), Image.LANCZOS)
    # กรอบไม้รอบแผนที่
    d = ImageDraw.Draw(im, "RGBA")
    d.rectangle([0, 0, W - 1, H - 1], outline=(92, 62, 38), width=14)
    d.rectangle([12, 12, W - 13, H - 13], outline=(150, 104, 62), width=4)
    d.rectangle([16, 16, W - 17, H - 17], outline=(58, 40, 28, 160), width=2)
    im.convert("RGB").save(f"{OUT}/map_bg.jpg", quality=92)


def crop_fit(src, box, size=(388, 220)):
    im = Image.open(f"{BG}/{src}").convert("RGB")
    sx = im.width / 1152
    box = tuple(int(v * sx) for v in box)
    return im.crop(box).resize(size, Image.LANCZOS)


def stall(d, x, y, w, col, goods, rnd, k=1):
    """แผงตลาด: เสา · ผ้าใบลายทาง · โต๊ะ · ของขาย (พิกัดภาพ 2x)"""
    h = w * 0.9
    top = y - h
    d.rectangle([x + 6 * k, top + 30 * k, x + 14 * k, y], fill=(110, 76, 48), outline=OUTLINE, width=int(2 * k + 1))
    d.rectangle([x + w - 14 * k, top + 30 * k, x + w - 6 * k, y], fill=(110, 76, 48), outline=OUTLINE, width=int(2 * k + 1))
    # ผ้าด้านหลังแผง (ทำให้ดูมีความลึก)
    d.rectangle([x + 14 * k, top + 34 * k, x + w - 14 * k, y - h * 0.42], fill=tuple(int(c * 0.45) for c in col) + (230,))
    d.rectangle([x + 14 * k, top + 34 * k, x + w - 14 * k, top + 52 * k], fill=(0, 0, 0, 70))
    # ผ้าใบ
    n = 6
    sw = (w + 20 * k) / n
    for i in range(n):
        c = col if i % 2 == 0 else (250, 244, 232)
        d.polygon([(x - 10 * k + i * sw, top), (x - 10 * k + (i + 1) * sw, top), (x - 10 * k + (i + 1) * sw, top + 34 * k), (x - 10 * k + i * sw, top + 34 * k)], fill=c)
        d.pieslice([x - 10 * k + i * sw, top + 20 * k, x - 10 * k + (i + 1) * sw, top + 48 * k], 0, 180, fill=c, outline=OUTLINE, width=int(2 * k + 1))
    d.rectangle([x - 10 * k, top, x + w + 10 * k, top + 34 * k], outline=OUTLINE, width=int(3 * k + 1))
    # โต๊ะ
    ty = y - h * 0.42
    d.rectangle([x - 4 * k, ty, x + w + 4 * k, ty + 16 * k], fill=(176, 124, 76), outline=OUTLINE, width=int(3 * k + 1))
    d.rectangle([x + 4 * k, ty + 16 * k, x + w - 4 * k, y], fill=(150, 100, 60), outline=OUTLINE, width=int(3 * k + 1))
    # ลายไม้หน้าโต๊ะ + เงาล่าง
    for i in range(1, 4):
        yy = ty + 16 * k + (y - ty - 16 * k) * i / 4
        d.line([x + 8 * k, yy, x + w - 8 * k, yy], fill=(110, 70, 40, 200), width=int(2 * k))
    d.rectangle([x + 4 * k, y - 12 * k, x + w - 4 * k, y], fill=(0, 0, 0, 60))
    d.rectangle([x - 4 * k, ty + 10 * k, x + w + 4 * k, ty + 16 * k], fill=(0, 0, 0, 50))
    # ของขาย
    gx = x + 10 * k
    while gx < x + w - 18 * k:
        g = rnd.choice(goods)
        r = rnd.uniform(8, 12) * k
        d.ellipse([gx, ty - r * 1.6, gx + r * 2, ty + 2 * k], fill=g, outline=OUTLINE, width=int(2 * k + 1))
        d.ellipse([gx + r * 0.5, ty - r * 1.3, gx + r * 0.9, ty - r * 0.9], fill=(255, 255, 255, 150))
        gx += r * 1.8


def market_full():
    """ตลาดในหมู่บ้าน — ถนนหน้าบ้าน (bg_village_day) + แผง 3 ร้าน สีตามภาพร่าง Market.jpg (ม่วง · ส้ม · แดง)
    ตำแหน่งแผง (จอ 1152x648) ต้องตรงกับจุดกดใน Scene/Location/Market.tscn: MARKET_STALLS"""
    rnd = random.Random(3)
    base = Image.open(f"{BG}/bg_village_day.jpg").convert("RGB").resize((W * S, H * S), Image.LANCZOS)
    d = ImageDraw.Draw(base, "RGBA")
    for (x, y, w), col, goods in zip(MARKET_STALLS, [(128, 82, 190), (236, 132, 40), (214, 52, 46)], [
            [(80, 160, 220), (240, 240, 240), (90, 90, 100), (60, 60, 70)],  # อะไหล่/ของไอที
            [(250, 210, 120), (200, 120, 60), (250, 240, 200), (240, 150, 160)],  # ขนม
            [(230, 60, 50), (250, 180, 40), (120, 190, 70), (240, 230, 210)]]):  # ของชำ/ผักผลไม้
        # เงาใต้แผง
        d.ellipse([(x - 10) * S, (y - 10) * S, (x + w + 10) * S, (y + 12) * S], fill=(60, 40, 20, 70))
        stall(d, x * S, y * S, w * S, col, goods, rnd, S)
    return base.resize((W, H), Image.LANCZOS)


def thumbs():
    global MARKET_IMG
    MARKET_IMG = market_full()
    MARKET_IMG.save(f"{OUT}/bg_market_day.jpg", quality=92)
    out = {
        "loc_home": crop_fit("bg_home_inside.jpg", (180, 130, 960, 572)),
        "loc_village": crop_fit("bg_village_day.jpg", (120, 60, 1000, 559)),
        "loc_shop": crop_fit("bg_shop_open.jpg", (0, 70, 900, 580)),
        "loc_city": crop_fit("bg_office_new.jpg", (430, 0, 1152, 409)),
        "loc_market": MARKET_IMG.crop((120, 160, 1000, 659)).resize((388, 220), Image.LANCZOS),
    }
    for k, im in out.items():
        im = ImageEnhance.Color(im).enhance(1.08)
        im.save(f"{OUT}/{k}.jpg", quality=92)


def storeroom():
    """ห้องเก็บของหลังบ้าน — ใช้ห้องไม้เดิม (bg_home_inside) ทำเป็นตอนเย็น ไฟหลอดเดียว ให้ดูเป็นคนละห้อง"""
    im = Image.open(f"{BG}/bg_home_inside.jpg").convert("RGB").resize((W, H))
    im = ImageEnhance.Brightness(im).enhance(0.62)
    im = ImageEnhance.Color(im).enhance(0.85)
    warm = Image.new("RGB", (W, H), (255, 170, 90))
    im = Image.blend(im, ImageChops.multiply(im, warm), 0.35)
    # แสงจากหลอดไฟกลางห้อง
    glow = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([330, -40, 830, 520], fill=200)
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    light = Image.new("RGB", (W, H), (255, 214, 150))
    im = Image.composite(ImageChops.screen(im, light), im, glow.point(lambda v: int(v * 0.3)))
    d = ImageDraw.Draw(im, "RGBA")
    # หลอดไฟ
    d.line([(592, 0), (592, 52)], fill=(40, 30, 24), width=3)
    d.ellipse([580, 50, 604, 76], fill=(255, 236, 170), outline=(90, 70, 40), width=2)
    for r, a in [(22, 60), (34, 30)]:
        d.ellipse([592 - r, 63 - r, 592 + r, 63 + r], fill=(255, 220, 140, a))
    # ชั้นวางไม้ + กล่องกระดาษ บนผนังหลัง (ช่วยให้ดูเป็นห้องเก็บของ)
    for sy in (215, 300):
        d.rectangle([340, sy, 720, sy + 12], fill=(120, 82, 50), outline=OUTLINE, width=2)
        d.rectangle([350, sy + 12, 360, sy + 40], fill=(100, 68, 42))
        d.rectangle([700, sy + 12, 710, sy + 40], fill=(100, 68, 42))
    rnd = random.Random(5)
    for sy in (215, 300):
        x = 352
        while x < 690:
            w = rnd.randint(44, 74)
            h = rnd.randint(30, 56)
            if x + w > 712:
                break
            col = rnd.choice([(176, 132, 84), (190, 146, 96), (160, 118, 74), (120, 128, 136)])
            d.rectangle([x, sy - h, x + w, sy], fill=col, outline=OUTLINE, width=2)
            d.line([(x + 4, sy - h + 8), (x + w - 4, sy - h + 8)], fill=(0, 0, 0, 40), width=3)
            x += w + rnd.randint(4, 14)
    # vignette
    vig = Image.new("L", (W, H), 0)
    ImageDraw.Draw(vig).ellipse([-200, -160, W + 200, H + 200], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(90))
    im = Image.composite(im, Image.new("RGB", (W, H), (20, 12, 8)), vig)
    im = ImageEnhance.Contrast(im).enhance(1.15)
    im = ImageEnhance.Color(im).enhance(1.15)
    im.save(f"{OUT}/bg_storeroom.jpg", quality=92)


if __name__ == "__main__":
    map_bg()
    thumbs()
    storeroom()
    print("ok")


def khom_room():
    """ห้องของขม (ห้องเดิมก่อนไปทำงานในเมือง) — ห้องไม้ในบ้าน (bg_home_inside) + โต๊ะคอมเก่า (จอ CRT · เคสสีครีม)
    ฟูกนอน · โปสเตอร์ · ปฏิทิน · พัดลม · ฝุ่นจาง ๆ  [Claude 10 ต.ค. 2569] ใช้ในบท "ห้องของขม" (Resources/main.tres) + ฉากหายางลบ"""
    k = S
    base = Image.open(f"{BG}/bg_home_inside.jpg").convert("RGB").resize((W * k, H * k), Image.LANCZOS)
    base = ImageEnhance.Color(base).enhance(0.92)
    d = ImageDraw.Draw(base, "RGBA")
    O = OUTLINE
    def R(x0, y0, x1, y1, fill, w=3, r=0):
        box = [x0 * k, y0 * k, x1 * k, y1 * k]
        if r:
            d.rounded_rectangle(box, radius=r * k, fill=fill, outline=O, width=w * k)
        else:
            d.rectangle(box, fill=fill, outline=O, width=w * k)
    def PG(pts, fill, w=3):
        d.polygon([(x * k, y * k) for x, y in pts], fill=fill, outline=O, width=w * k)
    def L(pts, col, w):
        d.line([(x * k, y * k) for x, y in pts], fill=col, width=int(w * k))

    # ---- โปสเตอร์ + ปฏิทิน บนผนังหลัง
    R(330, 175, 420, 300, (70, 110, 170), 3, 4)            # โปสเตอร์อวกาศ
    d.ellipse([350 * k, 200 * k, 395 * k, 245 * k], fill=(240, 200, 90), outline=O, width=2 * k)
    for sx, sy in [(345, 270), (400, 190), (385, 280), (360, 190)]:
        d.ellipse([(sx - 2) * k, (sy - 2) * k, (sx + 2) * k, (sy + 2) * k], fill=(255, 255, 230))
    R(760, 190, 830, 275, (245, 240, 228), 3, 3)            # ปฏิทิน
    R(760, 190, 830, 210, (200, 70, 60), 3, 3)
    for gy in range(220, 270, 12):
        for gx in range(768, 826, 12):
            d.rectangle([gx * k, gy * k, (gx + 7) * k, (gy + 6) * k], fill=(190, 180, 170))
    d.line([(772 * k, 222 * k), (781 * k, 230 * k)], fill=(200, 40, 40), width=3 * k)
    # ---- โต๊ะคอม (กลางผนังหลัง)
    shadow = (0, 0, 0, 60)
    d.polygon([(440 * k, 455 * k), (760 * k, 455 * k), (790 * k, 470 * k), (420 * k, 470 * k)], fill=shadow)
    R(450, 360, 462, 458, (110, 74, 44), 2)
    R(738, 360, 750, 458, (110, 74, 44), 2)
    R(640, 372, 742, 440, (140, 96, 58), 3)                 # ลิ้นชัก
    L([(650, 405), (732, 405)], O, 2)
    R(682, 386, 700, 392, (210, 180, 120), 2)
    R(682, 418, 700, 424, (210, 180, 120), 2)
    PG([(430, 350), (770, 350), (780, 364), (420, 364)], (170, 118, 72))
    R(420, 364, 780, 374, (140, 96, 58), 3)
    # จอ CRT สีครีม
    PG([(500, 352), (600, 352), (592, 336), (508, 336)], (200, 192, 170))   # ฐานจอ
    R(470, 250, 630, 340, (226, 218, 196), 3, 8)
    PG([(490, 340), (610, 340), (596, 352), (504, 352)], (206, 198, 176))
    R(486, 262, 614, 326, (52, 60, 66), 3, 10)              # จอดับ
    d.polygon([(494 * k, 268 * k), (530 * k, 268 * k), (500 * k, 300 * k)], fill=(255, 255, 255, 40))
    d.ellipse([600 * k, 329 * k, 606 * k, 335 * k], fill=(90, 90, 90))
    # คีย์บอร์ด + เมาส์
    PG([(480, 352), (612, 352), (618, 360), (474, 360)], (214, 206, 186), 2)
    for i in range(10):
        L([(486 + i * 12.5, 355), (494 + i * 12.5, 355)], (150, 144, 130), 2)
    d.ellipse([632 * k, 351 * k, 646 * k, 360 * k], fill=(214, 206, 186), outline=O, width=2 * k)
    # เคสเครื่องเก่า (ตั้งบนโต๊ะขวา)
    R(660, 262, 724, 350, (222, 214, 190), 3, 4)
    R(668, 272, 716, 284, (190, 182, 160), 2)               # ช่องซีดีรอม
    R(668, 290, 716, 298, (190, 182, 160), 2)               # ช่องฟลอปปี้
    d.ellipse([686 * k, 316 * k, 698 * k, 328 * k], fill=(180, 172, 150), outline=O, width=2 * k)
    d.ellipse([701 * k, 336 * k, 705 * k, 340 * k], fill=(120, 120, 110))  # ไฟดับ
    # ฝุ่นบนโต๊ะ/จอ
    rnd = random.Random(11)
    for _ in range(140):
        x, y = rnd.uniform(420, 780), rnd.uniform(248, 362)
        d.ellipse([x * k, y * k, (x + 1.6) * k, (y + 1.6) * k], fill=(255, 250, 235, 70))
    # เก้าอี้ไม้
    R(560, 395, 640, 405, (150, 100, 60), 3)
    R(566, 405, 574, 462, (120, 80, 48), 2)
    R(626, 405, 634, 462, (120, 80, 48), 2)
    R(566, 330, 574, 395, (120, 80, 48), 2)
    R(626, 330, 634, 395, (120, 80, 48), 2)
    R(562, 336, 638, 352, (150, 100, 60), 3)
    # ---- ฟูกนอน + หมอน + ผ้าห่ม (ซ้ายล่าง)
    d.polygon([(70 * k, 600 * k), (420 * k, 600 * k), (440 * k, 612 * k), (60 * k, 612 * k)], fill=shadow)
    PG([(110, 520), (390, 520), (420, 590), (80, 590)], (90, 140, 170))
    PG([(80, 590), (420, 590), (420, 604), (80, 604)], (70, 116, 146))
    for i in range(1, 6):
        x0 = 110 + i * 47
        L([(x0, 521), (x0 - 5 + i * 1, 589)], (70, 116, 146), 2)
    R(130, 500, 230, 530, (245, 240, 225), 3, 12)            # หมอน
    PG([(250, 528), (395, 528), (418, 588), (230, 588)], (220, 120, 90))  # ผ้าห่มลายสก็อต
    for i in range(1, 5):
        L([(245 + i * 35, 529), (238 + i * 40, 587)], (190, 90, 66), 3)
    L([(236, 555), (406, 555)], (190, 90, 66), 3)
    # ---- พัดลมตั้งพื้น (ขวาของโต๊ะ)
    fx, fy = 800, 470
    R(fx - 26, fy - 6, fx + 26, fy + 4, (90, 150, 180), 3, 4)
    R(fx - 4, fy - 70, fx + 4, fy - 6, (200, 200, 200), 2)
    d.ellipse([(fx - 34) * k, (fy - 130) * k, (fx + 34) * k, (fy - 62) * k], fill=(210, 230, 238), outline=O, width=3 * k)
    for a in range(0, 360, 120):
        ex = fx + math.cos(math.radians(a)) * 24
        ey = fy - 96 + math.sin(math.radians(a)) * 24
        d.ellipse([(ex - 11) * k, (ey - 11) * k, (ex + 11) * k, (ey + 11) * k], fill=(90, 150, 180, 200))
    d.ellipse([(fx - 6) * k, (fy - 102) * k, (fx + 6) * k, (fy - 90) * k], fill=(60, 100, 130), outline=O, width=2 * k)
    # ---- กองหนังสือการ์ตูนข้างฟูก
    for i, col in enumerate([(200, 70, 60), (70, 130, 190), (230, 190, 70), (110, 170, 90)]):
        R(440 + i * 3, 560 - i * 12, 500 + i * 2, 572 - i * 12, col, 2, 2)
    im = base.resize((W, H), Image.LANCZOS)
    # ฝุ่นในลำแสง (ห้องไม่ได้ใช้นาน)
    dust = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dust)
    for _ in range(90):
        x, y = rnd.uniform(80, 700), rnd.uniform(120, 520)
        r = rnd.uniform(0.8, 2.0)
        dd.ellipse([x - r, y - r, x + r, y + r], fill=(255, 245, 220, rnd.randint(60, 140)))
    im = Image.alpha_composite(im.convert("RGBA"), dust).convert("RGB")
    im.save(f"{OUT}/bg_khom_room.jpg", quality=92)


if __name__ == "__main__" and "room" in sys.argv[3:]:
    khom_room()
