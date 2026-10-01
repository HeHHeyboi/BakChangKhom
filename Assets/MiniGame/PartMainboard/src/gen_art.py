# วาดภาพ Part Mainboard + CPU — SVG ต้นฉบับ + PNG (ใช้ครั้งเดียว · ผลลัพธ์อยู่ใน out/)
import base64, os, random, io, re
import cairosvg
from PIL import Image, ImageDraw, ImageFilter

SRC = '/mnt/user-data/uploads/BakChangKhom/Assets/'
OUT = '/home/claude/mb/out/'
os.makedirs(OUT + 'src', exist_ok=True)
INK = '#2C1810'
random.seed(7)


def save_svg(name, svg, w, h):
    open(OUT + 'src/' + name + '.svg', 'w').write(svg)
    cairosvg.svg2png(bytestring=svg.encode(), write_to=OUT + name + '.png', output_width=w, output_height=h)


def pcb_bg():
    s = open(SRC + 'MiniGame/Scene2D/src/slots_zoom.svg').read()
    s = re.sub(r'<metadata>.*?</metadata>', '', s, flags=re.S)
    i = s.index('<rect width="1152" height="420" fill="url(#pcb)"/>')
    # เอา defs + พื้น PCB + ลายวงจร + จุดบัดกรี (ก่อนส่วนสล็อตแรม)
    j = s.index('</g>', s.index('fill="#c9a24a"')) + 4
    return s[s.index('<defs>'):j]


# ---------------------------------------------------------------- มุมซ็อกเก็ต (ซูม)
SX, SY, SS = 446, 80, 260          # ฐานซ็อกเก็ต
PX, PY, PS = 476, 110, 200         # ช่องขา
HOLES = [(376, 70), (776, 70), (376, 350), (776, 350)]


def socket_view():
    pins = []
    for gy in range(14):
        for gx in range(14):
            pins.append(f'<rect x="{PX + 8 + gx * 13.4:.1f}" y="{PY + 8 + gy * 13.4:.1f}" width="5" height="5" rx="1" fill="#d9b04a"/>')
    holes = ''.join(
        f'<circle cx="{x}" cy="{y}" r="26" fill="#c8c2b4" stroke="{INK}" stroke-width="4"/>'
        f'<circle cx="{x}" cy="{y}" r="12" fill="#3a3530" stroke="{INK}" stroke-width="3"/>' for x, y in HOLES)
    vrm = ''.join(
        f'<rect x="{150 + i * 46}" y="18" width="36" height="34" rx="5" fill="#2e2e33" stroke="{INK}" stroke-width="3"/>'
        f'<rect x="{156 + i * 46}" y="26" width="24" height="18" rx="2" fill="#55555c"/>' for i in range(4))
    vrm2 = ''.join(
        f'<rect x="{150 + i * 46}" y="368" width="36" height="34" rx="5" fill="#2e2e33" stroke="{INK}" stroke-width="3"/>' for i in range(4))
    caps = ''.join(
        f'<circle cx="{cx}" cy="{cy}" r="17" fill="#3a3a40" stroke="{INK}" stroke-width="3"/>'
        f'<path d="M{cx - 9} {cy} h18 M{cx} {cy - 9} v18" stroke="#9a9aa2" stroke-width="3"/>'
        for cx, cy in [(900, 300), (940, 300), (980, 300), (900, 345), (940, 345)])
    dimm = (f'<rect x="1040" y="0" width="34" height="420" fill="#2b2b30" stroke="{INK}" stroke-width="4"/>'
            f'<rect x="1088" y="0" width="34" height="420" fill="#3a4fa8" stroke="{INK}" stroke-width="4"/>')
    heat = (f'<rect x="40" y="70" width="96" height="280" rx="10" fill="#8b8f96" stroke="{INK}" stroke-width="5"/>'
            + ''.join(f'<rect x="52" y="{82 + k * 22}" width="72" height="12" rx="3" fill="#5f636a"/>' for k in range(12)))
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1152" height="420" viewBox="0 0 1152 420">
{pcb_bg()}
{heat}{vrm}{vrm2}{caps}{dimm}{holes}
<rect x="{SX + 8}" y="{SY + 10}" width="{SS}" height="{SS}" rx="14" fill="#000" opacity=".3"/>
<rect x="{SX}" y="{SY}" width="{SS}" height="{SS}" rx="14" fill="#2a2a2e" stroke="{INK}" stroke-width="6"/>
<rect x="{PX}" y="{PY}" width="{PS}" height="{PS}" rx="6" fill="#4a3f2a" stroke="#1a140c" stroke-width="3"/>
{''.join(pins)}
<path d="M{PX + 6} {PY + PS - 6} l26 0 l-26 -26 z" fill="#f2c94c" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>
<text x="576" y="404" font-family="DejaVu Sans" font-size="15" fill="#cfe8d4" opacity=".55" text-anchor="middle">LGA 1700 · CPU SOCKET</text>
<rect width="1152" height="420" fill="url(#light)"/>
</svg>'''
    save_svg('mb_socket_view', svg, 1152, 420)


def retention():
    # คานล็อก + กรอบโลหะ มองจากบน · ขนาด 260×260 ตรงกับฐานซ็อกเก็ต
    win = 52
    closed = f'''<svg xmlns="http://www.w3.org/2000/svg" width="300" height="260" viewBox="0 0 300 260">
<path fill-rule="evenodd" d="M8 8 h244 v244 h-244 z M{win} {win + 8} h{260 - 2 * win} v{244 - 2 * win} h-{260 - 2 * win} z"
 fill="#c9ccd2" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M20 20 h220 M20 240 h220" stroke="#e9ebef" stroke-width="5" opacity=".8"/>
<circle cx="30" cy="30" r="9" fill="#8d9097" stroke="{INK}" stroke-width="3"/>
<circle cx="230" cy="30" r="9" fill="#8d9097" stroke="{INK}" stroke-width="3"/>
<path d="M272 20 v230" stroke="{INK}" stroke-width="16" stroke-linecap="round"/>
<path d="M272 20 v230" stroke="#b9bcc3" stroke-width="9" stroke-linecap="round"/>
<path d="M252 236 h22" stroke="{INK}" stroke-width="10" stroke-linecap="round"/>
<path d="M252 236 h22" stroke="#b9bcc3" stroke-width="5" stroke-linecap="round"/>
</svg>'''
    opened = f'''<svg xmlns="http://www.w3.org/2000/svg" width="300" height="260" viewBox="0 0 300 260">
<path d="M8 8 h244 v40 h-244 z" fill="#c9ccd2" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M20 22 h220" stroke="#e9ebef" stroke-width="5" opacity=".8"/>
<path d="M30 48 l-10 14 M230 48 l10 14" stroke="#8d9097" stroke-width="6" stroke-linecap="round"/>
<path d="M272 250 L292 18" stroke="{INK}" stroke-width="16" stroke-linecap="round"/>
<path d="M272 250 L292 18" stroke="#b9bcc3" stroke-width="9" stroke-linecap="round"/>
<circle cx="292" cy="18" r="7" fill="#f2c94c" stroke="{INK}" stroke-width="3"/>
</svg>'''
    save_svg('mb_retention_closed', closed, 300, 260)
    save_svg('mb_retention_open', opened, 300, 260)


def cpu_states():
    cpu = Image.open(SRC + 'MiniGame/PartMainboard/mb_cpu.png').convert('RGBA')
    W, H = cpu.size
    cx, cy = W / 2, H / 2 - 4
    # ซิลิโคนเก่า: คราบเทาแห้งแตกเป็นขุยเต็มผิว
    old = cpu.copy()
    lay = Image.new('RGBA', cpu.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for _ in range(26):
        x, y = random.uniform(40, 140), random.uniform(38, 132)
        r = random.uniform(8, 18)
        d.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=(150, 146, 140, 235), outline=(70, 66, 62, 255), width=2)
    for _ in range(18):
        x, y = random.uniform(45, 135), random.uniform(42, 128)
        d.line([x, y, x + random.uniform(-14, 14), y + random.uniform(-14, 14)], fill=(60, 56, 52, 255), width=2)
    old.alpha_composite(lay)
    old.save(OUT + 'mb_cpu_old.png')
    cpu.save(OUT + 'mb_cpu_clean.png')
    for name, r in [('small', 9), ('ok', 17), ('large', 34)]:
        im = cpu.copy()
        lay = Image.new('RGBA', cpu.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(lay)
        if name == 'large':
            d.ellipse([cx - r - 18, cy - r, cx + r + 22, cy + r + 8], fill=(205, 207, 212, 255), outline=(70, 70, 76, 255), width=3)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(214, 216, 222, 255), outline=(70, 70, 76, 255), width=3)
        d.ellipse([cx - r * 0.45, cy - r * 0.6, cx - r * 0.05, cy - r * 0.2], fill=(250, 250, 252, 255))
        im.alpha_composite(lay)
        im.save(OUT + f'mb_cpu_paste_{name}.png')


def cooler_dusty():
    c = Image.open(SRC + 'MiniGame/PartMainboard/mb_cooler.png').convert('RGBA')
    a = c.getchannel('A')
    lay = Image.new('RGBA', c.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for _ in range(900):
        x, y = random.uniform(0, c.width), random.uniform(0, c.height)
        r = random.uniform(1.5, 5)
        g = random.randint(120, 175)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(g, g - 8, g - 22, random.randint(140, 230)))
    lay = lay.filter(ImageFilter.GaussianBlur(0.8))
    lay.putalpha(Image.fromarray(__import__('numpy').minimum(__import__('numpy').array(lay.getchannel('A')), __import__('numpy').array(a))))
    out = c.copy()
    out.alpha_composite(lay)
    out.save(OUT + 'mb_cooler_dusty.png')


def heatsink_base():
    for st in ['dirty', 'clean']:
        crust = ''
        if st == 'dirty':
            blobs = []
            for _ in range(22):
                x, y = random.uniform(105, 195), random.uniform(105, 195)
                r = random.uniform(8, 16)
                blobs.append(f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{r:.0f}" ry="{r * 0.8:.0f}" fill="#9a958d" stroke="#4a4540" stroke-width="2"/>')
            crust = ''.join(blobs) + ''.join(
                f'<path d="M{random.uniform(110, 190):.0f} {random.uniform(110, 190):.0f} l{random.uniform(-14, 14):.0f} {random.uniform(-14, 14):.0f}" stroke="#3c3834" stroke-width="2"/>' for _ in range(14))
        shine = '' if st == 'dirty' else '<path d="M100 120 L180 100 M110 180 L200 150" stroke="#ffe3b8" stroke-width="10" opacity=".55" stroke-linecap="round"/>'
        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">
<ellipse cx="156" cy="282" rx="128" ry="14" fill="#000" opacity=".25"/>
<rect x="22" y="22" width="256" height="256" rx="18" fill="#8d9097" stroke="{INK}" stroke-width="6"/>
{''.join(f'<path d="M40 {44 + k * 20} h220" stroke="#6c7077" stroke-width="7" stroke-linecap="round"/>' for k in range(11))}
<path d="M70 30 v-14 M150 30 v-14 M230 30 v-14" stroke="#c87a2e" stroke-width="12" stroke-linecap="round"/>
<rect x="90" y="90" width="120" height="120" rx="10" fill="#d58a45" stroke="{INK}" stroke-width="6"/>
<rect x="98" y="98" width="104" height="104" rx="6" fill="#e9a55f"/>
{shine}{crust}
</svg>'''
        save_svg('mb_heatsink_base_' + st, svg, 300, 300)


def screw():
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
<circle cx="33" cy="35" r="26" fill="#000" opacity=".25"/>
<circle cx="32" cy="32" r="26" fill="#c9ccd2" stroke="{INK}" stroke-width="4"/>
<circle cx="32" cy="32" r="18" fill="#e3e5e9"/>
<path d="M20 32 h24 M32 20 v24" stroke="{INK}" stroke-width="6" stroke-linecap="round"/>
</svg>'''
    save_svg('mb_screw', svg, 64, 64)


def screen_temp():
    grid = ''.join(f'<path d="M60 {120 + k * 34} h392" stroke="#2f5a46" stroke-width="2"/>' for k in range(5))
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="320" viewBox="0 0 512 320">
<rect width="512" height="320" fill="#0e1a15"/>
<rect x="16" y="14" width="480" height="40" rx="6" fill="#16352a"/>
<text x="32" y="42" font-family="DejaVu Sans Mono" font-size="20" fill="#7cf0a8">HW MONITOR · CPU PACKAGE</text>
{grid}
<rect x="60" y="112" width="392" height="170" fill="none" stroke="#3f7a5e" stroke-width="3"/>
<text x="60" y="306" font-family="DejaVu Sans Mono" font-size="16" fill="#5fae86">0s                     LOAD 100%                  60s</text>
</svg>'''
    save_svg('mb_screen_temp', svg, 512, 320)


def tools():
    tissue = f'''<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
<path d="M30 110 h140 v60 a8 8 0 0 1 -8 8 h-124 a8 8 0 0 1 -8 -8 z" fill="#7fb7e6" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M30 110 h140" stroke="{INK}" stroke-width="6"/>
<ellipse cx="100" cy="112" rx="34" ry="8" fill="#2a5f8f" stroke="{INK}" stroke-width="4"/>
<path d="M78 112 C70 70 92 60 100 34 C108 60 132 70 122 112 Z" fill="#fbfaf6" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>
<path d="M44 140 h40 M44 156 h26" stroke="#e8f2fb" stroke-width="6" stroke-linecap="round"/>
</svg>'''
    thinner = f'''<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
<path d="M60 60 h80 v110 a10 10 0 0 1 -10 10 h-60 a10 10 0 0 1 -10 -10 z" fill="#d9483b" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>
<rect x="84" y="28" width="32" height="34" rx="4" fill="#e3e5e9" stroke="{INK}" stroke-width="6"/>
<rect x="70" y="92" width="60" height="54" rx="6" fill="#f6e7c8" stroke="{INK}" stroke-width="4"/>
<path d="M100 104 l14 26 h-28 z" fill="#2C1810"/>
<circle cx="100" cy="124" r="3" fill="#f6e7c8"/>
</svg>'''
    wire = f'''<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
<g transform="rotate(-30 100 100)">
<rect x="30" y="86" width="96" height="30" rx="8" fill="#a8693a" stroke="{INK}" stroke-width="6"/>
<rect x="124" y="80" width="50" height="42" rx="6" fill="#7d7f86" stroke="{INK}" stroke-width="6"/>
{''.join(f'<path d="M{130 + k * 6} 122 v26" stroke="#b9bcc3" stroke-width="3"/>' for k in range(7))}
{''.join(f'<path d="M{130 + k * 6} 122 v26" stroke="{INK}" stroke-width="1" opacity=".5"/>' for k in range(7))}
</g>
</svg>'''
    save_svg('tool_tissue', tissue, 200, 200)
    save_svg('tool_thinner', thinner, 200, 200)
    save_svg('tool_wire_brush', wire, 200, 200)


socket_view(); retention(); cpu_states(); cooler_dusty(); heatsink_base(); screw(); screen_temp(); tools()
print(sorted(os.listdir(OUT)))
