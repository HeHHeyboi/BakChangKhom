# วาดภาพ Part Front Panel (ป้ายแถวบนอยู่ y84–112 ให้พ้นแถบหัวขั้นตอน) — SVG ต้นฉบับ + PNG (ใช้ครั้งเดียว · ผลลัพธ์ใน out/) · ห้ามมีตัวอักษรไทยในภาพ
import os, re
import cairosvg

SRC = '/mnt/user-data/uploads/BakChangKhom/Assets/'
OUT = '/home/claude/fp/out/'
os.makedirs(OUT + 'src', exist_ok=True)
INK = '#2C1810'

# ตำแหน่งพิน F_PANEL 2×5 ในมุม Pins (ใช้ร่วมกับ gen_scene.py)
COLS = [456, 516, 576, 636, 696]
ROW_TOP, ROW_BOT = 150, 250


def save_svg(name, svg, w, h):
    open(OUT + 'src/' + name + '.svg', 'w').write(svg)
    cairosvg.svg2png(bytestring=svg.encode(), write_to=OUT + name + '.png', output_width=w, output_height=h)


def pcb_bg():
    s = open(SRC + 'MiniGame/Scene2D/src/slots_zoom.svg').read()
    s = re.sub(r'<metadata>.*?</metadata>', '', s, flags=re.S)
    j = s.index('</g>', s.index('fill="#c9a24a"')) + 4
    return s[s.index('<defs>'):j]


def pins_view():
    pins = ''
    for row in (ROW_TOP, ROW_BOT):
        for i, x in enumerate(COLS):
            if row == ROW_TOP and i == 4:
                pins += f'<circle cx="{x}" cy="{row}" r="7" fill="#1a1a1e"/>'  # ช่องกันเสียบผิด (ไม่มีพิน)
                continue
            pins += (f'<rect x="{x - 9}" y="{row - 9}" width="18" height="18" fill="#2a2a2e" stroke="{INK}" stroke-width="2"/>'
                     f'<rect x="{x - 5}" y="{row - 22}" width="10" height="30" rx="2" fill="#e8c35a" stroke="#6b5220" stroke-width="2"/>')
    caps = ''.join(f'<rect x="{x}" y="{y}" width="30" height="16" rx="3" fill="#b8a27a" stroke="{INK}" stroke-width="2"/>'
                   for x, y in [(790, 90), (830, 90), (790, 330), (830, 330), (790, 260)])
    chips = (f'<rect x="900" y="40" width="130" height="130" rx="8" fill="#2a2a2e" stroke="{INK}" stroke-width="4"/>'
             f'<rect x="918" y="58" width="94" height="94" rx="4" fill="#3a3a40"/>'
             + ''.join(f'<rect x="{906 + k * 12}" y="34" width="6" height="8" fill="#b9bcc3"/>' for k in range(10))
             + f'<rect x="40" y="40" width="330" height="340" rx="16" fill="#000" opacity=".16"/>')
    usb = (f'<rect x="900" y="250" width="150" height="70" rx="6" fill="#2a2a2e" stroke="{INK}" stroke-width="4"/>'
           + ''.join(f'<rect x="{916 + k * 26}" y="266" width="14" height="14" fill="#e8c35a"/><rect x="{916 + k * 26}" y="290" width="14" height="14" fill="#e8c35a"/>' for k in range(5)))
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1152" height="420" viewBox="0 0 1152 420">
{pcb_bg()}
{chips}{usb}{caps}
<rect x="410" y="110" width="332" height="180" rx="10" fill="#000" opacity=".18"/>
<rect x="420" y="118" width="312" height="164" rx="8" fill="none" stroke="#f6f0dc" stroke-width="3" stroke-dasharray="10 6" opacity=".6"/>
{pins}
<rect width="1152" height="420" fill="url(#light)"/>
</svg>'''
    save_svg('fp_pins_view', svg, 1152, 420)


def pin_labels():
    # ผังชื่อพินบนบอร์ด (ตัวอังกฤษเหมือนบอร์ดจริง) โปร่งใส วางทับมุม Pins · ชื่อคู่ + เครื่องหมาย +/− เหนือ/ใต้ขาแต่ละขา
    def t(x, y, s, c='#f6f0dc', fs=18):
        w = len(s) * fs * 0.68 + 12
        return (f'<rect x="{x - w / 2}" y="{y - fs - 2}" width="{w}" height="{fs + 10}" rx="6" fill="#0d2a18" opacity=".72"/>'
                f'<text x="{x}" y="{y}" font-family="DejaVu Sans" font-weight="bold" font-size="{fs}" fill="{c}" text-anchor="middle">{s}</text>')
    mid = lambda i: (COLS[i] + COLS[i + 1]) / 2
    s = t(mid(0), 84, 'PLED', '#9ff09f') + t(COLS[0], 112, '+', '#9ff09f', 20) + t(COLS[1], 112, '−', '#f6f0dc', 20)
    s += t(mid(2), 84, 'PWR SW', '#ffd36b') + t(COLS[4], 112, 'KEY', '#9a9aa2', 13)
    s += t(mid(0), 404, 'HDD', '#9fd8ff') + t(COLS[0], 362, '+', '#9fd8ff', 22) + t(COLS[1], 362, '−', '#f6f0dc', 22)
    s += t(mid(2), 404, 'RESET', '#ff9f9f') + t(COLS[4], 362, 'NC', '#9a9aa2', 13)
    s += t(800, 200, 'F_PANEL', '#f6f0dc', 15)
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="1152" height="420" viewBox="0 0 1152 420">{s}</svg>'
    save_svg('fp_pin_labels', svg, 1152, 420)


def connectors():
    # หัวต่อ 2 พิน 120×100 · ตัวหัวอยู่ด้านล่าง (y 60–96) สายพุ่งขึ้น · สายซ้ายคือขั้ว + (สีเข้ม) ขวาคือ − (ขาว)
    for name, plus, minus, mark in [('power_sw', '#e8a854', '#e8a854', False), ('reset_sw', '#c0453b', '#c0453b', False),
                                    ('power_led', '#6baf52', '#f6f6f2', True), ('hdd_led', '#4a90d9', '#f6f6f2', True)]:
        tri = (f'<path d="M30 56 l-9 -12 h18 z" fill="#ffd36b" stroke="{INK}" stroke-width="2"/>' if mark else '')
        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="120" height="100" viewBox="0 0 120 100">
<path d="M30 62 C30 30 50 20 60 0" stroke="{INK}" stroke-width="12" fill="none"/>
<path d="M30 62 C30 30 50 20 60 0" stroke="{plus}" stroke-width="7" fill="none"/>
<path d="M90 62 C90 30 70 20 64 0" stroke="{INK}" stroke-width="12" fill="none"/>
<path d="M90 62 C90 30 70 20 64 0" stroke="{minus}" stroke-width="7" fill="none"/>
<rect x="6" y="60" width="108" height="36" rx="5" fill="#1d1e22" stroke="{INK}" stroke-width="4"/>
<rect x="22" y="70" width="16" height="16" rx="2" fill="#3a3c42"/><rect x="82" y="70" width="16" height="16" rx="2" fill="#3a3c42"/>
<rect x="6" y="60" width="108" height="8" fill="{plus}" opacity=".85"/>
{tri}</svg>'''
        save_svg('fp_conn_' + name, svg, 120, 100)


def bios_screen():
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="320" viewBox="0 0 512 320">
<rect width="512" height="320" fill="#1d3f8f"/>
<rect x="0" y="0" width="512" height="40" fill="#c9ccd2"/>
<text x="256" y="28" font-family="DejaVu Sans Mono" font-size="20" fill="#1d3f8f" text-anchor="middle" font-weight="bold">BIOS SETUP UTILITY</text>
<text x="30" y="80" font-family="DejaVu Sans Mono" font-size="18" fill="#e8f0ff">CPU     : 3.60 GHz  6-Core</text>
<text x="30" y="112" font-family="DejaVu Sans Mono" font-size="18" fill="#e8f0ff">Storage : SSD 512GB</text>
<rect x="20" y="150" width="472" height="44" fill="#16316f" stroke="#7fa4ff" stroke-width="2"/>
<text x="30" y="290" font-family="DejaVu Sans Mono" font-size="15" fill="#9fb8ff">F10 Save &amp; Exit   ESC Back</text>
</svg>'''
    save_svg('fp_bios_screen', svg, 512, 320)


def misc():
    note = f'''<svg xmlns="http://www.w3.org/2000/svg" width="90" height="90" viewBox="0 0 90 90">
<path d="M8 10 h70 v58 l-14 14 h-56 z" fill="#ffe27a" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
<path d="M64 82 v-14 h14" fill="#e8c35a" stroke="{INK}" stroke-width="3"/>
<path d="M18 28 h48 M18 42 h40 M18 56 h30" stroke="#b08a2a" stroke-width="5" stroke-linecap="round"/>
<circle cx="44" cy="10" r="7" fill="#c0453b" stroke="{INK}" stroke-width="3"/>
</svg>'''
    save_svg('fp_note', note, 90, 90)
    beam = '''<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">
<defs><radialGradient id="b" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#fff6c8" stop-opacity=".75"/><stop offset=".7" stop-color="#ffe27a" stop-opacity=".35"/><stop offset="1" stop-color="#ffe27a" stop-opacity="0"/></radialGradient></defs>
<circle cx="200" cy="200" r="200" fill="url(#b)"/></svg>'''
    save_svg('fp_beam', beam, 400, 400)


pins_view(); pin_labels(); connectors(); bios_screen(); misc()
print(sorted(f for f in os.listdir(OUT) if f.endswith('.png')))
