# หน้าจอ ขมOS บนจอมอนิเตอร์ในบทฝึก (512×320) — ใช้แทนจอ "BIOS POST OK" หลังบูต · [Claude 10 ต.ค. 2569]
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

O = sys.argv[1]      # โฟลเดอร์ภาพ ขมOS (Assets/MiniGame/Desktop)
F = sys.argv[2]      # ฟอนต์ Sarabun
OUT = sys.argv[3]
W, H = 1024, 640
INK = (58, 40, 28, 255)
img = Image.open(O + "os_wallpaper.jpg").convert("RGBA").resize((W, H), Image.LANCZOS)
d = ImageDraw.Draw(img)


def font(s):
    return ImageFont.truetype(F, s, layout_engine=ImageFont.Layout.RAQM)


def shadow_text(x, y, t, f):
    for dx, dy in [(-1, -1), (1, -1), (-1, 1), (1, 1), (0, 2)]:
        d.text((x + dx, y + dy), t, font=f, fill=(0, 0, 0, 200))
    d.text((x, y), t, font=f, fill=(255, 255, 255, 255))


icons = [("os_icon_folder.png", "เอกสาร"), ("os_icon_pictures.png", "รูปภาพ"), ("os_icon_downloads.png", "ดาวน์โหลด"),
         ("os_icon_trash_empty.png", "ถังขยะ"), ("os_icon_browser.png", "เบราว์เซอร์")]
for i, (f, l) in enumerate(icons):
    ic = Image.open(O + f).convert("RGBA").resize((64, 64), Image.LANCZOS)
    x, y = 24, 20 + i * 108
    img.alpha_composite(ic, (x + 10, y))
    tw = d.textlength(l, font=font(17))
    shadow_text(x + 42 - tw / 2, y + 68, l, font(17))

note = Image.open(O + "os_sticky_note.png").convert("RGBA").resize((250, 196), Image.LANCZOS)
img.alpha_composite(note, (752, 18))
d.text((780, 48), "ทำความรู้จัก ขมOS", font=font(21), fill=INK)
for i, t in enumerate(["เปิดโฟลเดอร์เอกสาร", "เปิดเบราว์เซอร์", "ดูพื้นที่ในตั้งค่า", "ลบไฟล์ทดสอบ"]):
    y = 88 + i * 26
    d.rectangle([782, y + 3, 795, y + 16], outline=INK, width=2)
    d.text((802, y - 2), t, font=font(16), fill=INK)

x0, y0, x1, y1 = 270, 170, 690, 420
sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(sh).rounded_rectangle([x0 + 6, y0 + 10, x1 + 6, y1 + 10], 16, fill=(0, 0, 0, 90))
img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
d = ImageDraw.Draw(img)
d.rounded_rectangle([x0, y0, x1, y1], 14, fill=(247, 245, 238, 255), outline=INK, width=4)
d.rounded_rectangle([x0 + 2, y0 + 2, x1 - 2, y0 + 46], 12, fill=(74, 115, 158, 255))
d.rectangle([x0 + 2, y0 + 30, x1 - 2, y0 + 46], fill=(74, 115, 158, 255))
d.text((x0 + 18, y0 + 8), "ขมOS", font=font(24), fill=(255, 255, 255, 255))
d.text((x1 - 40, y0 + 6), "×", font=font(28), fill=(255, 255, 255, 255))
start = Image.open(O + "os_start.png").convert("RGBA").resize((76, 76), Image.LANCZOS)
img.alpha_composite(start, (x0 + 30, y0 + 80))
d.text((x0 + 126, y0 + 82), "ยินดีต้อนรับ", font=font(34), fill=INK)
d.text((x0 + 128, y0 + 130), "เครื่องนี้ขมประกอบเองกับมือ", font=font(20), fill=(110, 90, 70, 255))
d.rounded_rectangle([x0 + 250, y1 - 62, x1 - 24, y1 - 20], 10, fill=(232, 228, 218, 255), outline=(58, 40, 28, 160), width=2)
d.text((x0 + 282, y1 - 58), "เริ่มใช้งาน", font=font(20), fill=INK)

d.rectangle([0, H - 56, W, H], fill=(43, 51, 66, 245))
d.line([(0, H - 56), (W, H - 56)], fill=INK, width=3)
img.alpha_composite(start.resize((44, 44), Image.LANCZOS), (10, H - 50))
for i, f in enumerate(["os_icon_folder.png", "os_icon_browser.png", "os_icon_settings.png"]):
    img.alpha_composite(Image.open(O + f).convert("RGBA").resize((40, 40), Image.LANCZOS), (70 + i * 52, H - 48))
d.text((W - 210, H - 44), "เหลือ 200 GB", font=font(18), fill=(255, 255, 255, 255))
d.text((W - 66, H - 44), "09:00", font=font(18), fill=(255, 255, 255, 255))
img.resize((512, 320), Image.LANCZOS).convert("RGB").save(OUT)
img.convert("RGB").save(OUT.replace(".png", "_preview.png"))
