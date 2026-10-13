# ไอคอนคลังของ (กล่องกระดาษเปิดฝา มีแรม/สายไฟโผล่) — วาดด้วย PIL แบบ 4× แล้วย่อให้ขอบเนียน
# ใช้: python3 gen_storage_icon.py  → ../ui_icon_storage.png (128×128) · [Claude 13 ต.ค. 2569]
import os
from PIL import Image, ImageDraw

S = 512
INK = (59, 41, 28, 255)
W = 16
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ui_icon_storage.png")

im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(im)


def poly(pts, fill):
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=INK, width=W, joint="curve")


# ด้านในกล่อง (มืด)
poly([(96, 210), (416, 210), (396, 250), (116, 250)], (120, 74, 38, 255))
# ของในกล่อง: แรม (เขียว + ขาทอง) เอียง
ram = [(150, 120), (300, 70), (330, 160), (180, 210)]
poly(ram, (70, 150, 80, 255))
for k in range(5):
    t = 0.12 + k * 0.17
    x0 = 180 + (330 - 180) * t
    y0 = 210 + (160 - 210) * t
    d.rectangle([x0 - 8, y0 - 22, x0 + 8, y0 - 6], fill=(240, 196, 70, 255))
for k in range(3):
    t = 0.2 + k * 0.28
    cx = 165 + (315 - 165) * t
    cy = 135 + (85 - 135) * t
    d.rectangle([cx - 16, cy + 8, cx + 16, cy + 36], fill=(40, 40, 46, 255))
# สายไฟขดสีฟ้า
d.arc([270, 120, 400, 240], 190, 360, fill=INK, width=W + 12)
d.arc([270, 120, 400, 240], 190, 360, fill=(80, 150, 220, 255), width=W - 2)
d.arc([300, 145, 380, 225], 200, 340, fill=INK, width=W + 8)
d.arc([300, 145, 380, 225], 200, 340, fill=(80, 150, 220, 255), width=W - 4)

# ฝาพับซ้าย/ขวา (เปิดออก)
poly([(96, 210), (30, 140), (180, 128), (214, 210)], (222, 165, 105, 255))
poly([(416, 210), (482, 140), (332, 128), (298, 210)], (210, 150, 92, 255))
# ตัวกล่องด้านหน้า
poly([(96, 210), (416, 210), (396, 470), (116, 470)], (201, 139, 78, 255))
# เงาด้านขวา
d.polygon([(330, 222), (404, 222), (386, 458), (318, 458)], fill=(176, 116, 60, 255))
d.line([(96, 210), (416, 210), (396, 470), (116, 470), (96, 210)], fill=INK, width=W, joint="curve")
# เทปกาวกลางกล่อง
d.rectangle([236, 212, 276, 300], fill=(236, 214, 160, 255))
d.line([(236, 212), (236, 300), (276, 300), (276, 212)], fill=INK, width=8)
# ช่องหูจับ
d.rounded_rectangle([196, 360, 316, 396], radius=18, fill=(95, 58, 30, 255), outline=INK, width=10)

im = im.resize((128, 128), Image.LANCZOS)
im.save(OUT)
print("ok", OUT)
