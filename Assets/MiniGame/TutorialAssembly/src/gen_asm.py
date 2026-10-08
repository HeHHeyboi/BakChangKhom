# ภาพบทฝึกประกอบคอม แบบเวกเตอร์มองจากด้านบน (สไตล์ภาพประกอบเส้นขอบ) — ขนาดตามของจริงเป็นมิลลิเมตร
# [Claude 9 ต.ค. 2569] · ชิ้นส่วน 2 px/มม. · ฉาก (มุม Tray/Build 1152×420) วาด 2 เท่า = 1.5 px/มม. ในมุม Build
# ฉาก Build: ภาพ "ประกอบแล้ว" แยกเป็นชั้นละชิ้น (layer_*.png ขนาดเท่าฉาก) วางทับเป๊ะกับตำแหน่ง socket
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = sys.argv[1] if len(sys.argv) > 1 else "out"
os.makedirs(OUT_DIR, exist_ok=True)
SS = 3          # supersample
TEX_K = 2.0     # px/มม. ของรูปชิ้นส่วน
VIEW_K = 0.75   # px/มม. ในมุม Build (หน่วยของ socket)
BG_X = 2        # รูปฉากวาด 2 เท่า (bg_scale 0.5)

INK = (44, 56, 72, 255)
PCB = (118, 182, 96, 255)
PCB_L = (150, 205, 120, 255)
PCB_D = (88, 150, 74, 255)
METAL = (208, 217, 229, 255)
METAL_M = (178, 189, 204, 255)
METAL_D = (130, 142, 160, 255)
DARK = (62, 70, 84, 255)
DARK2 = (84, 94, 110, 255)
BLACK = (40, 45, 54, 255)
GOLD = (232, 186, 78, 255)
GOLD_D = (196, 150, 60, 255)
BLUE = (96, 146, 214, 255)
BLUE_L = (150, 190, 236, 255)
WHITE = (246, 248, 250, 255)
RED = (214, 92, 82, 255)
LW = 1.6   # เส้นขอบหลัก (มม.)
LW2 = 0.8  # เส้นรายละเอียด


class P:
    """ปากกาวาดหน่วยมิลลิเมตร: k = px/มม. (รวม SS แล้ว) · (ox, oy) = จุดเริ่มเป็น px"""

    def __init__(self, img, k, ox=0.0, oy=0.0):
        self.img = img
        self.d = ImageDraw.Draw(img)
        self.k = k
        self.ox = ox
        self.oy = oy

    def at(self, ox_mm, oy_mm):
        return P(self.img, self.k, self.ox + ox_mm * self.k, self.oy + oy_mm * self.k)

    def X(self, x):
        return self.ox + x * self.k

    def Y(self, y):
        return self.oy + y * self.k

    def w(self, lw):
        return max(1, int(round(lw * self.k)))

    def rect(self, x, y, w, h, fill=None, ol=INK, lw=LW, r=0.0):
        box = [self.X(x), self.Y(y), self.X(x + w), self.Y(y + h)]
        if r > 0:
            self.d.rounded_rectangle(box, radius=r * self.k, fill=fill, outline=ol, width=self.w(lw) if ol else 0)
        else:
            self.d.rectangle(box, fill=fill, outline=ol, width=self.w(lw) if ol else 0)

    def circle(self, cx, cy, r, fill=None, ol=INK, lw=LW):
        self.d.ellipse([self.X(cx - r), self.Y(cy - r), self.X(cx + r), self.Y(cy + r)], fill=fill, outline=ol,
                       width=self.w(lw) if ol else 0)

    def line(self, pts, col=INK, lw=LW):
        self.d.line([(self.X(x), self.Y(y)) for x, y in pts], fill=col, width=self.w(lw), joint="curve")

    def poly(self, pts, fill=None, ol=INK, lw=LW):
        P_ = [(self.X(x), self.Y(y)) for x, y in pts]
        self.d.polygon(P_, fill=fill)
        if ol:
            self.d.line(P_ + [P_[0]], fill=ol, width=self.w(lw), joint="curve")


def new_img(w_mm, h_mm, k_out, pad_mm=0.0):
    k = k_out * SS
    W = int(round((w_mm + 2 * pad_mm) * k))
    H = int(round((h_mm + 2 * pad_mm) * k))
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    return img, P(img, k, pad_mm * k, pad_mm * k)


def finish(img, name, k_out, w_mm, h_mm):
    W = int(round(w_mm * k_out))
    H = int(round(h_mm * k_out))
    img.resize((W, H), Image.LANCZOS).save(os.path.join(OUT_DIR, name))

# ================================================================ ชิ้นส่วน (มองจากด้านบน)

MB_HOLES = [(8, 8), (236, 236), (236, 8), (8, 236)]  # ลำดับขัน (ทแยง)
MB_CPU_C = (125, 75)
MB_RAM_X = (194, 208)          # ซ้ายของสล็อต 1 และ 2 (กว้าง 6)
MB_RAM_Y = (20, 153)
MB_PCIE_Y = 165
MB_M2 = (40, 129)              # มุมซ้ายบนของ SSD ตอนใส่ (80×22)


def draw_screw(p, x, y, r=3.2):
    p.circle(x, y, r, METAL, INK, LW2 * 1.2)
    k = r * 0.55
    p.line([(x - k, y), (x + k, y)], INK, LW2)
    p.line([(x, y - k), (x, y + k)], INK, LW2)


def draw_mainboard(p, lever_closed=False, latches_closed=(False, False)):
    p.rect(0, 0, 244, 244, PCB, INK, LW, r=3)
    # ลายวงจร
    for i in range(9):
        y = 30 + i * 22
        p.line([(30, y), (90, y), (100, y + 6), (180, y + 6)], PCB_L, 0.6)
    for (hx, hy) in MB_HOLES:
        p.circle(hx, hy, 4.2, GOLD, GOLD_D, LW2)
        p.circle(hx, hy, 2.0, DARK, None)
    # พอร์ตหลัง (I/O) ขอบซ้าย
    y = 14
    for h, col in [(14, METAL), (10, METAL_M), (16, METAL), (12, BLUE_L), (14, METAL), (18, METAL_M), (12, METAL)]:
        p.rect(-2, y, 26, h, col, INK, LW2 * 1.2, r=1)
        p.rect(4, y + h * 0.3, 12, h * 0.4, DARK2, None)
        y += h + 2
    # ฮีตซิงก์ VRM
    p.rect(30, 32, 26, 84, METAL_M, INK, LW2 * 1.3, r=2)
    for i in range(9):
        p.line([(32, 38 + i * 9), (54, 38 + i * 9)], METAL_D, 0.7)
    p.rect(72, 18, 100, 16, METAL_M, INK, LW2 * 1.3, r=2)
    for i in range(10):
        p.line([(78 + i * 9.5, 20), (78 + i * 9.5, 32)], METAL_D, 0.7)
    # คาปาซิเตอร์
    for i in range(5):
        p.circle(64, 46 + i * 12, 3.2, DARK2, INK, LW2)
    # ปลั๊ก CPU 8 พิน
    p.rect(28, 4, 22, 11, BLACK, INK, LW2, r=1)
    for i in range(4):
        for j in range(2):
            p.rect(30.5 + i * 5, 5.8 + j * 4.5, 3.4, 3, DARK2, None)
    # ซ็อกเก็ต CPU
    cx, cy = MB_CPU_C
    p.rect(cx - 26, cy - 26, 52, 52, METAL, INK, LW, r=2)
    p.rect(cx - 21, cy - 21, 42, 42, (190, 160, 90, 255), INK, LW2)
    for i in range(10):
        for j in range(10):
            p.circle(cx - 18 + i * 4, cy - 18 + j * 4, 0.7, GOLD_D, None)
    p.poly([(cx - 21, cy + 21), (cx - 21, cy + 15), (cx - 15, cy + 21)], GOLD, None)
    if lever_closed:
        pass
    # สล็อตแรม
    for n, sx in enumerate(MB_RAM_X):
        p.rect(sx, MB_RAM_Y[0], 6, MB_RAM_Y[1] - MB_RAM_Y[0], DARK if n == 0 else BLUE, INK, LW2 * 1.2)
        p.rect(sx + 2.2, MB_RAM_Y[0] + 3, 1.6, MB_RAM_Y[1] - MB_RAM_Y[0] - 6, BLACK, None)
        for yy, dy in [(MB_RAM_Y[0], -1), (MB_RAM_Y[1], 1)]:
            closed = latches_closed[n]
            if closed:
                p.rect(sx - 0.5, yy - (5 if dy < 0 else 0), 7, 5, METAL, INK, LW2)
            else:
                p.poly([(sx, yy), (sx + 6, yy), (sx + 9, yy + 6 * dy), (sx + 3, yy + 6 * dy)], METAL, INK, LW2)
    # ปลั๊ก 24 พิน
    p.rect(229, 110, 12, 54, BLACK, INK, LW2, r=1)
    for j in range(12):
        for i in range(2):
            p.rect(230.6 + i * 5, 112 + j * 4.3, 3.6, 3.3, DARK2, None)
    # M.2
    p.rect(MB_M2[0] - 5, MB_M2[1] + 6, 5, 10, BLACK, INK, LW2)
    p.circle(MB_M2[0] + 78, MB_M2[1] + 11, 2.6, GOLD, GOLD_D, LW2)
    p.line([(MB_M2[0] + 2, MB_M2[1] + 11), (MB_M2[0] + 70, MB_M2[1] + 11)], PCB_D, 0.6)
    # PCIe
    for y, length, col in [(MB_PCIE_Y, 89, DARK), (MB_PCIE_Y + 24, 25, DARK), (MB_PCIE_Y + 48, 89, DARK2)]:
        p.rect(36, y, length, 6, col, INK, LW2 * 1.2)
        p.rect(36 + 3, y + 2.2, length - 6, 1.6, BLACK, None)
        if length > 50:
            p.rect(36 + length, y - 1, 5, 8, METAL, INK, LW2)
    # ชิปเซ็ต
    p.rect(150, 176, 40, 40, METAL_M, INK, LW2 * 1.3, r=3)
    for i in range(6):
        p.line([(154, 181 + i * 6), (186, 181 + i * 6)], METAL_D, 0.7)
    # ถ่าน BIOS
    p.circle(168, 150, 10, METAL, INK, LW2 * 1.2)
    p.circle(168, 150, 7, METAL_M, None)
    # SATA
    for i in range(4):
        p.rect(230, 180 + i * 10, 11, 7, BLACK, INK, LW2)
    # ชิปเล็ก ๆ
    for (x, y, w, h) in [(134, 160, 12, 12), (110, 210, 18, 12), (70, 150, 10, 10), (180, 225, 14, 8)]:
        p.rect(x, y, w, h, BLACK, INK, LW2, r=1)


def draw_cpu(p):
    p.rect(0, 0, 37.5, 37.5, PCB_D, INK, LW, r=1.5)
    p.rect(0.8, 0.8, 35.9, 35.9, None, GOLD_D, 0.6, r=1.2)
    p.rect(4.5, 4.5, 28.5, 28.5, METAL, INK, LW2 * 1.3, r=2.2)
    p.line([(8, 12), (16, 12)], METAL_D, 0.7)
    p.line([(8, 16), (24, 16)], METAL_D, 0.7)
    p.line([(8, 20), (20, 20)], METAL_D, 0.7)
    p.poly([(1.2, 36.3), (1.2, 31.5), (6, 36.3)], GOLD, None)


def draw_cooler(p):
    """ซิงก์ + พัดลมแบบเป่าลง มองจากด้านบน — ขอบโลหะสว่าง + เส้นขอบหนา ให้แยกจากบอร์ด/แผ่นรองชัด"""
    s = 95.0
    c = s / 2
    # ขาจับ 4 มุม (ฐานโลหะสว่าง)
    for (fx, fy) in [(0, 0), (s - 13, 0), (0, s - 13), (s - 13, s - 13)]:
        p.rect(fx, fy, 13, 13, METAL, INK, LW, r=3)
        p.circle(fx + 6.5, fy + 6.5, 2.6, DARK, None)
    # แขนเชื่อมขาจับกับตัวซิงก์
    for a in (45, 135, 225, 315):
        r = math.radians(a)
        p.line([(c + 30 * math.cos(r), c + 30 * math.sin(r)), (c + 58 * math.cos(r), c + 58 * math.sin(r))], INK, 6.0)
        p.line([(c + 30 * math.cos(r), c + 30 * math.sin(r)), (c + 58 * math.cos(r), c + 58 * math.sin(r))], METAL, 3.6)
    # ขอบโลหะสว่างรอบตัว (แยกจากพื้นหลัง)
    p.circle(c, c, 46.5, METAL, INK, LW * 1.4)
    for i in range(36):
        a = i * 2 * math.pi / 36
        p.line([(c + 42.5 * math.cos(a), c + 42.5 * math.sin(a)), (c + 46 * math.cos(a), c + 46 * math.sin(a))], METAL_D, 0.6)
    # กรอบพัดลม + ใบพัด
    p.circle(c, c, 42, (72, 86, 108, 255), INK, LW)
    for i in range(9):
        a = i * 2 * math.pi / 9
        pts = []
        for t in range(9):
            r = 13 + t * 3.1
            aa = a + t * 0.11
            pts.append((c + r * math.cos(aa), c + r * math.sin(aa)))
        for t in range(8, -1, -1):
            r = 13 + t * 3.1
            aa = a + 0.42 + t * 0.07
            pts.append((c + r * math.cos(aa), c + r * math.sin(aa)))
        p.poly(pts, BLUE_L, INK, LW2 * 0.9)
    p.circle(c, c, 13, METAL, INK, LW2 * 1.4)
    p.circle(c, c, 8, BLUE, None)


def draw_ram_flat(p):
    p.rect(0, 0, 133, 31, PCB, INK, LW, r=1)
    p.rect(2, 2, 129, 20, (120, 132, 160, 255), INK, LW2 * 1.2, r=1.5)
    for i in range(12):
        p.line([(6 + i * 10.5, 4), (6 + i * 10.5, 20)], (100, 112, 140, 255), 0.6)
    p.rect(40, 7, 40, 9, WHITE, INK, LW2, r=1)
    for i in range(50):
        x = 4 + i * 2.5
        if 76 <= x <= 79:
            continue
        p.rect(x, 25, 1.6, 5, GOLD, None)
    p.rect(76.5, 26, 2.5, 6, (0, 0, 0, 0), None)
    p.d.rectangle([p.X(76.5), p.Y(25.5), p.X(79), p.Y(31.5)], fill=(0, 0, 0, 0))
    p.line([(0, 31), (76.5, 31)], INK, LW)
    p.line([(79, 31), (133, 31)], INK, LW)


def draw_ram_edge(p):
    """แรมเสียบอยู่ในสล็อต มองจากด้านบน = ขอบบนของฮีตสเปรดเดอร์ (9 × 133 มม. แนวตั้ง)"""
    p.rect(0, 0, 9, 133, (120, 132, 160, 255), INK, LW, r=1.5)
    p.rect(2.6, 3, 3.8, 127, (150, 162, 190, 255), None, r=1)
    for i in range(12):
        p.line([(1.5, 8 + i * 10.4), (7.5, 8 + i * 10.4)], (100, 112, 140, 255), 0.6)


def draw_ssd(p):
    p.rect(0, 0, 80, 22, PCB, INK, LW, r=1)
    for i in range(14):
        x = 0.8 + i * 0.85
        p.rect(0.5, 2 + i * 1.3, 3.2, 0.8, GOLD, None)
    p.rect(1, 9.5, 3, 2, (0, 0, 0, 0), None)
    p.rect(8, 4, 16, 14, BLACK, INK, LW2, r=1)
    p.rect(28, 3, 18, 16, BLACK, INK, LW2, r=1)
    p.rect(50, 3, 18, 16, BLACK, INK, LW2, r=1)
    p.rect(30, 6, 36, 10, WHITE, INK, LW2 * 0.8, r=1)
    p.d.ellipse([p.X(80 - 3.2), p.Y(11 - 3.2), p.X(80 + 3.2), p.Y(11 + 3.2)], fill=(0, 0, 0, 0))
    p.d.arc([p.X(80 - 3.2), p.Y(11 - 3.2), p.X(80 + 3.2), p.Y(11 + 3.2)], 90, 270, fill=INK, width=p.w(LW2))


def draw_gpu_flat(p):
    """การ์ดจอวางราบ (ด้านพัดลมขึ้น) 252×125 มม. รวมแผ่นยึดซ้าย"""
    # แผ่นยึด
    p.rect(0, 0, 10, 122, METAL, INK, LW, r=1)
    for y in (14, 34, 54, 74):
        p.rect(3, y, 4, 12, DARK, None, r=1)
    p.rect(-1, -2, 12, 6, METAL_M, INK, LW2)
    # PCB + หน้าสัมผัสทอง
    p.rect(10, 98, 236, 14, PCB, INK, LW)
    for i in range(46):
        x = 70 + i * 1.9
        if 92 <= x <= 95:
            continue
        p.rect(x, 108, 1.2, 4, GOLD, None)
    # ฝาครอบ
    p.rect(10, 4, 238, 98, (88, 98, 116, 255), INK, LW, r=6)
    p.rect(16, 10, 226, 86, (110, 122, 142, 255), INK, LW2, r=5)
    p.poly([(16, 40), (40, 10), (60, 10), (30, 50)], (130, 142, 162, 255), None)
    for fx in (78, 180):
        p.circle(fx, 53, 40, DARK, INK, LW)
        for i in range(9):
            a = i * 2 * math.pi / 9
            pts = []
            for t in range(9):
                r = 11 + t * 3.3
                aa = a + t * 0.1
                pts.append((fx + r * math.cos(aa), 53 + r * math.sin(aa)))
            for t in range(8, -1, -1):
                r = 11 + t * 3.3
                aa = a + 0.4 + t * 0.06
                pts.append((fx + r * math.cos(aa), 53 + r * math.sin(aa)))
            p.poly(pts, METAL_M, INK, LW2 * 0.7)
        p.circle(fx, 53, 11, DARK2, INK, LW2)
        p.circle(fx, 53, 6, RED, None)
    # ปลั๊กไฟเสริม
    p.rect(214, -1, 18, 8, BLACK, INK, LW2, r=1)


def draw_gpu_edge(p):
    """การ์ดจอเสียบแล้ว มองจากด้านบน = ขอบฝาครอบ 252×48 มม. (แผ่นยึดชิดผนังหลังเคส)"""
    p.rect(0, 0, 10, 48, METAL, INK, LW, r=1)
    p.rect(-1, 2, 12, 12, METAL_M, INK, LW2, r=1)       # แท็บขันน็อต
    p.rect(10, 6, 238, 38, (88, 98, 116, 255), INK, LW, r=5)
    p.rect(10, 26, 238, 14, (70, 80, 96, 255), None)    # ใต้ฝา = พัดลมหันลง
    p.line([(18, 13), (240, 13)], RED, 1.2)             # แถบไฟ
    for i in range(30):
        x = 22 + i * 7.6
        p.line([(x, 28), (x, 39)], (100, 110, 128, 255), 0.6)
    p.rect(214, 6, 18, 8, BLACK, INK, LW2, r=1)          # ปลั๊กไฟเสริม (ขอบบน)


def draw_psu_top(p):
    """PSU วางราบ ด้านพัดลมขึ้น 150×140"""
    p.rect(0, 0, 150, 140, DARK2, INK, LW, r=4)
    p.rect(4, 4, 142, 132, (96, 106, 122, 255), INK, LW2, r=3)
    p.circle(75, 70, 58, DARK, INK, LW)
    for r in range(10, 58, 8):
        p.circle(75, 70, r, None, (120, 130, 148, 255), 0.7)
    p.line([(17, 70), (133, 70)], (120, 130, 148, 255), 0.8)
    p.line([(75, 12), (75, 128)], (120, 130, 148, 255), 0.8)
    p.circle(75, 70, 10, METAL_M, INK, LW2)
    p.rect(110, 8, 34, 18, WHITE, INK, LW2, r=1)
    for i in range(3):
        p.line([(113, 13 + i * 4), (140, 13 + i * 4)], METAL_D, 0.6)


def draw_psu_side(p):
    """PSU ติดตั้งแล้ว มองจากด้านข้าง 150×86 (สติกเกอร์ฉลาก)"""
    p.rect(0, 0, 150, 86, DARK2, INK, LW, r=3)
    p.rect(14, 12, 92, 62, METAL, INK, LW2 * 1.2, r=2)
    for i in range(7):
        p.line([(20, 22 + i * 7), (98 if i % 2 else 80, 22 + i * 7)], METAL_D, 0.8)
    p.rect(20, 15, 30, 5, BLUE, None)
    for i in range(6):
        p.line([(116 + i * 5, 10), (116 + i * 5, 76)], (110, 120, 136, 255), 0.8)

# ================================================================ ตำแหน่งในมุม Build (px ของมุม = มม. × 0.75)

V = VIEW_K
BOARD_O = (448, 42)    # มุมซ้ายบนบอร์ดในมุม Build (px)


def board_px(x_mm, y_mm):
    return (BOARD_O[0] + x_mm * V, BOARD_O[1] + y_mm * V)


# socket (px ในมุม Build) — ต้องตรงกับ tutorial_assembly.tscn
SOCK = {
    "MbStandoff": (BOARD_O[0], BOARD_O[1], 244 * V, 244 * V),
    "CpuSocket": (*board_px(MB_CPU_C[0] - 18.75, MB_CPU_C[1] - 18.75), 37.5 * V, 37.5 * V),
    "CoolerMount": (*board_px(MB_CPU_C[0] - 47.5, MB_CPU_C[1] - 47.5), 95 * V, 95 * V),
    "RamSlot": (*board_px(MB_RAM_X[0] - 1.5, MB_RAM_Y[0]), 9 * V, 133 * V),
    "M2Slot": (*board_px(*MB_M2), 80 * V, 22 * V),
    "PcieSlot": (*board_px(-12, MB_PCIE_Y - 8), 252 * V, 48 * V),
    "PsuBay": (432, 266, 150 * V, 86 * V),
}

# ================================================================ ฉาก


def wood(p, w_mm, h_mm):
    p.rect(0, 0, w_mm, h_mm, (196, 152, 104, 255), None)
    for i in range(0, int(h_mm), 34):
        p.line([(0, i), (w_mm, i)], (176, 132, 88, 255), 1.6)
        for j in range(0, int(w_mm), 230):
            off = (i * 37) % 230
            p.line([(j + off, i), (j + off, i + 34)], (176, 132, 88, 255), 1.0)
    for i in range(40):
        y = (i * 53) % h_mm
        x = (i * 211) % w_mm
        p.line([(x, y + 10), (x + 60, y + 12)], (186, 142, 96, 255), 0.6)


def bg_tray():
    k = BG_X * SS  # 1 หน่วย = 1 px ของมุม
    img = Image.new("RGBA", (1152 * k, 420 * k), (0, 0, 0, 255))
    p = P(img, k)
    wood(p, 1152, 420)
    # เงา + แผ่นรอง ESD
    p.rect(214, 28, 742, 372, (0, 0, 0, 50), None, r=16)
    p.rect(206, 20, 742, 372, (92, 108, 124, 255), INK, 2.2, r=16)
    p.rect(216, 30, 722, 352, (104, 121, 138, 255), None, r=12)
    for x in range(236, 930, 36):
        p.line([(x, 34), (x, 378)], (114, 132, 150, 255), 0.8)
    for y in range(50, 380, 36):
        p.line([(220, y), (934, y)], (114, 132, 150, 255), 0.8)
    # ปุ่มกราวด์ + สาย
    p.circle(262, 352, 14, METAL, INK, 1.6)
    p.circle(262, 352, 6, METAL_M, INK, 1.0)
    p.line([(262, 366), (240, 400), (180, 410), (120, 395), (60, 405), (0, 398)], (40, 120, 70, 255), 3.0)
    for i in range(3):
        p.line([(244 + i * 6, 322 + i * 2), (280 - i * 6, 322 + i * 2)], (230, 230, 120, 255), 1.4)
    p.line([(262, 316), (262, 322)], (230, 230, 120, 255), 1.4)
    img.resize((1152 * BG_X, 420 * BG_X), Image.LANCZOS).convert("RGB").save(os.path.join(OUT_DIR, "asm_tray_bg.png"))


def bg_build():
    k = BG_X * SS
    img = Image.new("RGBA", (1152 * k, 420 * k), (0, 0, 0, 255))
    p = P(img, k)
    wood(p, 1152, 420)
    # เคสวางตะแคง (ถอดฝาข้างแล้ว)
    p.rect(418, 20, 356, 356, (0, 0, 0, 60), None, r=10)
    p.rect(408, 10, 356, 356, (70, 78, 92, 255), INK, 2.2, r=10)
    p.rect(420, 22, 332, 332, (186, 195, 208, 255), INK, 1.4, r=4)
    # ช่องหลังเคส: I/O + ฝาปิดช่อง PCIe
    p.rect(422, 50, 20, 92, (60, 66, 80, 255), INK, 1.0)
    for i in range(7):
        y = 158 + i * 17
        p.rect(422, y, 14, 13, METAL_M, INK, 0.8)
        p.line([(425, y + 6.5), (433, y + 6.5)], METAL_D, 0.8)
    # รูร้อยสาย
    for (y, h) in [(112, 58), (182, 48)]:
        p.rect(652, y, 14, h, (52, 58, 70, 255), INK, 1.0, r=7)
    p.rect(470, 248, 70, 12, (52, 58, 70, 255), INK, 1.0, r=6)
    # พัดลมหน้า (มองข้าง)
    for y in (40, 150):
        p.rect(734, y, 14, 96, DARK, INK, 1.0, r=2)
        for i in range(8):
            p.line([(736, y + 8 + i * 11), (746, y + 14 + i * 11)], METAL_D, 0.8)
    # ช่องใส่ไดรฟ์
    p.rect(640, 262, 92, 84, (168, 178, 192, 255), INK, 1.0, r=3)
    for i in range(3):
        p.rect(648, 270 + i * 25, 76, 18, METAL, INK, 0.8, r=2)
    # ฐานวาง PSU
    p.rect(426, 262, 124, 76, (168, 178, 192, 255), INK, 1.0, r=3)
    for (x, y) in [(434, 330), (540, 330), (434, 270), (540, 270)]:
        p.circle(x, y, 3, DARK, None)
    # เสารองบอร์ด (ทองเหลือง)
    for (hx, hy) in MB_HOLES:
        x, y = board_px(hx, hy)
        p.circle(x, y, 4.2, GOLD, GOLD_D, 1.0)
        p.circle(x, y, 1.8, DARK, None)
    # กรอบจาง ๆ ตรงที่วางบอร์ด
    bx, by = BOARD_O
    p.rect(bx, by, 244 * V, 244 * V, None, (160, 170, 186, 255), 0.8, r=2)
    img.resize((1152 * BG_X, 420 * BG_X), Image.LANCZOS).convert("RGB").save(os.path.join(OUT_DIR, "asm_case_bg.png"))


def layer(name, fn):
    k = BG_X * SS
    img = Image.new("RGBA", (1152 * k, 420 * k), (0, 0, 0, 0))
    fn(img, k)
    img.resize((1152 * BG_X, 420 * BG_X), Image.LANCZOS).save(os.path.join(OUT_DIR, "asm_layer_%s.png" % name))


def mm_pen(img, k, sock):
    """ปากกาหน่วย มม. วางที่มุมซ้ายบนของ socket (k = px ฉาก×SS ต่อ px มุม)"""
    x, y = SOCK[sock][0], SOCK[sock][1]
    return P(img, k * V, x * k, y * k)


def shadow(img, k, sock, pad=2):
    x, y, w, h = SOCK[sock]
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([(x + 2) * k, (y + 3) * k, (x + w + 2) * k, (y + h + 3) * k], radius=3 * k,
                                         fill=(0, 0, 0, 70))
    sh = sh.filter(ImageFilter.GaussianBlur(2.5 * k))
    img.alpha_composite(sh)


def screws_on(p, pts_frac, w_mm, h_mm):
    for fx, fy in pts_frac:
        draw_screw(p, fx * w_mm, fy * h_mm)


SEAT_PTS = {
    "PsuBay": [(0.06, 0.1), (0.94, 0.9), (0.94, 0.1), (0.06, 0.9)],
    "MbStandoff": [(hx / 244, hy / 244) for hx, hy in MB_HOLES],
    "CoolerMount": [(6 / 95, 6 / 95), (89 / 95, 89 / 95), (89 / 95, 6 / 95), (6 / 95, 89 / 95)],
    "PcieSlot": [(5 / 252, 8 / 48)],
    "M2Slot": [(78 / 80, 0.5)],
}


def L_psu(img, k):
    shadow(img, k, "PsuBay")
    p = mm_pen(img, k, "PsuBay")
    draw_psu_side(p)
    screws_on(p, SEAT_PTS["PsuBay"], 150, 86)


def L_mb(img, k):
    shadow(img, k, "MbStandoff")
    p = mm_pen(img, k, "MbStandoff")
    draw_mainboard(p)
    screws_on(p, SEAT_PTS["MbStandoff"], 244, 244)


def L_cpu(img, k):
    p = mm_pen(img, k, "CpuSocket")
    draw_cpu(p)
    # คันล็อกพับลง (ข้างขวาซ็อกเก็ต) — ตรงกับ SeatTarget LEVER ใน phase_build
    pl = P(img, k * V, (SOCK["CpuSocket"][0]) * k, (SOCK["CpuSocket"][1]) * k)
    lx = 37.5 + 7 / V
    ly = 37.5 + 2 / V
    pl.rect(lx - 2.2, ly - 45, 4.4, 45, METAL, INK, LW2 * 1.2, r=1)
    pl.circle(lx, ly - 45, 3.6, METAL, INK, LW2 * 1.2)
    pl.rect(-6, -6, 49.5, 49.5, None, METAL_M, 1.6, r=2)


def L_cooler(img, k):
    shadow(img, k, "CoolerMount")
    shadow(img, k, "CoolerMount")
    p = mm_pen(img, k, "CoolerMount")
    draw_cooler(p)
    screws_on(p, SEAT_PTS["CoolerMount"], 95, 95)


def L_ram(img, k):
    p = mm_pen(img, k, "RamSlot")
    draw_ram_edge(p)
    # สลักสองข้างปิด
    p.rect(0.5, -6, 8, 6, METAL, INK, LW2)
    p.rect(0.5, 133, 8, 6, METAL, INK, LW2)


def L_ssd(img, k):
    p = mm_pen(img, k, "M2Slot")
    draw_ssd(p)
    screws_on(p, SEAT_PTS["M2Slot"], 80, 22)


def L_gpu(img, k):
    shadow(img, k, "PcieSlot")
    p = mm_pen(img, k, "PcieSlot")
    draw_gpu_edge(p)
    screws_on(p, SEAT_PTS["PcieSlot"], 252, 48)


def L_cables(img, k):
    p = P(img, k, 0, 0)  # หน่วย = px ของมุม
    CBL = (36, 40, 48, 255)
    SLV = (70, 76, 90, 255)
    # 24 พิน: ออกจากรูร้อยสายขวา → เข้าปลั๊กบนบอร์ด
    x24, y24 = board_px(229, 110)
    for i in range(6):
        yy = y24 + 4 + i * 6.5
        p.line([(659, yy), (x24 + 10, yy)], SLV if i % 2 else CBL, 3.6)
    p.rect(x24 - 1, y24 - 1, 12 * V + 3, 54 * V + 2, BLACK, INK, 1.0, r=1)
    # 8 พิน CPU: ขึ้นไปทางขอบบน
    x8, y8 = board_px(28, 4)
    for i in range(3):
        p.line([(x8 + 4 + i * 5, y8 + 2), (x8 + 4 + i * 5, 24)], CBL, 3.0)
    p.rect(x8, y8, 22 * V, 11 * V, BLACK, INK, 1.0, r=1)
    # ไฟเสริมการ์ดจอ
    gx, gy, gw, gh = SOCK["PcieSlot"]
    px_, py_ = gx + 214 * V, gy + 6 * V
    for i in range(3):
        p.line([(px_ + 3 + i * 4, py_ + 3), (px_ + 3 + i * 4, py_ + 30 - i * 4), (659, 196 + i * 6)], CBL, 2.6)
    # PSU → รูล่าง
    x, y = SOCK["PsuBay"][0] + 150 * V, SOCK["PsuBay"][1] + 20
    p.line([(x - 6, y), (x + 8, y - 6), (530, 254)], CBL, 4.0)


def parts():
    jobs = [
        ("asm_mainboard.png", 244, 244, draw_mainboard),
        ("asm_cpu.png", 37.5, 37.5, draw_cpu),
        ("asm_cooler.png", 95, 95, draw_cooler),
        ("asm_ram.png", 133, 31, draw_ram_flat),
        ("asm_ram_edge.png", 9, 133, draw_ram_edge),
        ("asm_ssd.png", 80, 22, draw_ssd),
        ("asm_gpu.png", 252, 125, draw_gpu_flat),
        ("asm_gpu_edge.png", 252, 48, draw_gpu_edge),
        ("asm_psu.png", 150, 140, draw_psu_top),
        ("asm_psu_side.png", 150, 86, draw_psu_side),
    ]
    for name, w, h, fn in jobs:
        img, p = new_img(w, h, TEX_K)
        fn(p)
        finish(img, name, TEX_K, w, h)


if __name__ == "__main__":
    parts()
    bg_tray()
    bg_build()
    for n, f in [("psu", L_psu), ("mb", L_mb), ("cpu", L_cpu), ("cooler", L_cooler), ("ram", L_ram), ("ssd", L_ssd),
                 ("gpu", L_gpu), ("cables", L_cables)]:
        layer(n, f)
    for k, v in SOCK.items():
        print(k, [round(a, 1) for a in v])
    print("pts", SEAT_PTS)
